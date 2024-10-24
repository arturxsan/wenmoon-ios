//
//  CoinListView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import SwiftUI

struct CoinListView: View {
    // MARK: - Properties
    @ObservedObject private var coinListViewModel = CoinListViewModel()
    @ObservedObject private var addCoinViewModel = AddCoinViewModel()
    
    @State private var showAddCoinView = false
    @State private var showErrorAlert = false
    @State private var showSetPriceAlertConfirmation = false
    
    @State private var capturedCoin: CoinData?
    @State private var targetPrice: Double?
    
    @State private var toggleOffCoinID: String?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List(coinListViewModel.coins, id: \.self) { coin in
                HStack(spacing: .zero) {
                    if let data = coin.imageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .cornerRadius(24)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(coin.name)
                            .font(.headline)
                        
                        // TODO: - Move the formatting of values to the CoinListViewModel
                        HStack(spacing: 4) {
                            Text("\(coin.currentPrice.formatValue()) $")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text("\(coin.priceChange.formatValue(shouldShowPrefix: true))%")
                                .foregroundColor(coin.priceChange.isNegative ? .red : .green)
                                .font(.caption2)
                        }
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Toggle("", isOn: Binding<Bool>(
                            get: { coin.isActive },
                            set: { isActive in
                                if isActive {
                                    capturedCoin = coin
                                    showSetPriceAlertConfirmation = true
                                } else {
                                    Task {
                                        await coinListViewModel.setPriceAlert(for: coin, targetPrice: nil)
                                    }
                                }
                            }
                        ))
                        
                        if let targetPrice = coin.targetPrice {
                            Text("\(targetPrice.formatValue()) $")
                                .font(.caption)
                        } else {
                            Text("Not set")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        Task {
                            await coinListViewModel.deleteCoin(coin)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .animation(.default, value: coinListViewModel.coins)
            .navigationTitle("Coins")
            .refreshable {
                Task {
                    await coinListViewModel.fetchCoins()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddCoinView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                //.onReceive(NotificationCenter.default.publisher(for: .appDidBecomeActive)) { _ in
                Task {
                    await coinListViewModel.fetchCoins()
                    await coinListViewModel.fetchMarketData()
                    await coinListViewModel.fetchPriceAlerts()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .targetPriceReached)) { notification in
                if let coinID = notification.userInfo?["coinID"] as? String {
                    coinListViewModel.toggleOffPriceAlert(for: coinID)
                }
            }
            .onChange(of: coinListViewModel.errorMessage) { _, errorMessage in
                showErrorAlert = errorMessage != nil
            }
            .alert(coinListViewModel.errorMessage ?? "", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            }
            .alert("Set Price Alert", isPresented: $showSetPriceAlertConfirmation, actions: {
                TextField("Target Price", value: $targetPrice, format: .number)
                    .keyboardType(.decimalPad)
                
                Button("Confirm") {
                    if let coin = capturedCoin {
                        Task {
                            await coinListViewModel.setPriceAlert(for: coin, targetPrice: targetPrice)
                            capturedCoin = nil
                            targetPrice = nil
                        }
                    }
                }
                
                Button("Cancel", role: .cancel) {
                    capturedCoin = nil
                    targetPrice = nil
                }
            }) {
                Text("Please enter your target price in USD, and our system will notify you when it is reached")
            }
            .sheet(isPresented: $showAddCoinView) {
                AddCoinView(didSelectCoin: didSelectCoin)
                    .environmentObject(addCoinViewModel)
            }
        }
    }
    
    // MARK: - Private
    private func didSelectCoin(coin: Coin) {
        Task {
            await coinListViewModel.saveCoin(coin)
        }
    }
}
