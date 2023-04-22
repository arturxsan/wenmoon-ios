//
//  CryptoCompareView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.12.24.
//

import SwiftUI

struct CryptoCompareView: View {
    // MARK: - Properties
    @StateObject private var viewModel = CryptoCompareViewModel()
    @State private var coinA: Coin?
    @State private var coinB: Coin?
    @State private var cachedImage1: Image?
    @State private var cachedImage2: Image?
    @State private var isSelectingFirstCoin = true
    @State private var showCoinSelectionView = false
    
    private var selectedPriceOption: PriceOption { viewModel.selectedPriceOption }
    
    // MARK: - Body
    var body: some View {
        BaseView(isLoading: $viewModel.isLoading, errorMessage: $viewModel.errorMessage) {
            NavigationView {
                ZStack {
                    VStack(spacing: 16) {
                        coinSelection(
                            coin: $coinA,
                            cachedImage: $cachedImage1,
                            placeholder: "Select Coin A",
                            isFirstCoin: true
                        )
                        
                        Button {
                            swap(&coinA, &coinB)
                            swap(&cachedImage1, &cachedImage2)
                            viewModel.triggerImpactFeedback()
                        } label: {
                            Image("arrows.swap")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.gray)
                                .rotationEffect(.degrees(90))
                        }
                        .disabled(coinA.isNil || coinB.isNil)
                        
                        coinSelection(
                            coin: $coinB,
                            cachedImage: $cachedImage2,
                            placeholder: "Select Coin B",
                            isFirstCoin: false
                        )
                        
                        VStack(spacing: 16) {
                            let symbolA = coinA?.symbol ?? "A"
                            let symbolB = coinB?.symbol ?? "B"
                            
                            let isPickerDisabled = coinA.isNil || coinB.isNil
                            
                            Picker("Price Option", selection: Binding<PriceOption>(
                                get: { viewModel.selectedPriceOption },
                                set: { newValue in
                                    //guard newValue != .ath || viewModel.checkProStatus() else { return }
                                    viewModel.selectedPriceOption = newValue
                                }
                            )) {
                                ForEach(PriceOption.allCases, id: \.self) { option in
//                                    let isLocked = option == .ath && !(viewModel.account?.isPro ?? false)
//                                    let title = "\(symbolB) \(option.rawValue)\(isLocked ? " 🔒" : "")"
                                    let title = "\(symbolB) \(option.rawValue)"
                                    Text(title).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .disabled(isPickerDisabled)
                            .onChange(of: isPickerDisabled) { _, isDisabled in
                                if isDisabled && viewModel.selectedPriceOption != .now {
                                    viewModel.selectedPriceOption = .now
                                }
                            }
                            
                            VStack {
                                HStack(spacing: .zero) {
                                    Text(symbolA)
                                        .bold()
                                        .foregroundStyle(.white)
                                    
                                    Text(" WITH THE MARKET CAP OF ")
                                    
                                    Text(symbolB)
                                        .foregroundStyle(.white)
                                        .bold()
                                    
                                    Text(" \(selectedPriceOption.rawValue)")
                                }
                                .font(.footnote)
                                .foregroundStyle(.gray)
                                
                                let price = viewModel.calculatePrice(
                                    for: coinA,
                                    coinB: coinB,
                                    option: selectedPriceOption
                                ) ?? .zero
                                
                                let multiplier = viewModel.calculateMultiplier(
                                    for: coinA,
                                    coinB: coinB,
                                    option: selectedPriceOption
                                ) ?? .zero
                                
                                HStack {
                                    Text(price.formattedAsCurrency())
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                    
                                    let multiplierColor: Color = viewModel.isPositiveMultiplier(multiplier).map { $0 ? .neonGreen : .neonPink } ?? .gray
                                    Text(multiplier.formattedAsMultiplier())
                                        .font(.title2)
                                        .foregroundStyle(multiplierColor)
                                }
                            }
                        }
                        .padding(.top, 16)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            HStack(spacing: .zero) {
                                Text("Powered by ")
                                
                                Link(destination: URL(string: "https://www.coingecko.com/en/api")!) {
                                    Text("CoinGecko API")
                                        .underline()
                                }
                            }
                            .font(.footnote)
                            
                            Image("gecko")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                        }
                        .foregroundStyle(.gray)
                    }
                    .padding()
                    
                    if viewModel.isLoading {
                        CustomProgressView()
                    }
                }
                .sheet(isPresented: $showCoinSelectionView) {
                    CoinSelectionView(mode: .selection, didSelectCoin: { selectedCoin in
                        loadAndCacheCoinImage(for: selectedCoin)
                        
                        Task {
                            let updatedCoin = await viewModel.updateCoinIfNeeded(selectedCoin)
                            await MainActor.run {
                                if isSelectingFirstCoin {
                                    coinA = updatedCoin
                                } else {
                                    coinB = updatedCoin
                                }
                            }
                        }
                    })
                }
                .navigationTitle("Compare")
            }
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func coinSelection(
        coin: Binding<Coin?>,
        cachedImage: Binding<Image?>,
        placeholder: String,
        isFirstCoin: Bool
    ) -> some View {
        HStack {
            Button {
                isSelectingFirstCoin = isFirstCoin
                showCoinSelectionView = true
            } label: {
                coinRow(
                    coin: coin.wrappedValue,
                    cachedImage: cachedImage.wrappedValue,
                    placeholderText: placeholder
                )
            }
            
            if coin.wrappedValue.isNotNil {
                Button {
                    coin.wrappedValue = nil
                    cachedImage.wrappedValue = nil
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(.gray)
                }
                .padding(.leading, 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: coin.wrappedValue.isNotNil)
    }
    
    @ViewBuilder
    private func coinRow(coin: Coin?, cachedImage: Image?, placeholderText: String) -> some View {
        HStack(spacing: 12) {
            if let coin {
                CoinImageView(
                    image: cachedImage,
                    placeholderText: coin.symbol,
                    size: 36
                )
                
                Text(coin.symbol)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text(coin.currentPrice.formattedAsCurrency())
                    .font(.subheadline).bold()
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .stroke(Color.gray, lineWidth: 1)
                    .frame(width: 36, height: 36)
                
                Text(placeholderText)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                Spacer()
            }
        }
        .padding(.vertical)
        .padding(.horizontal, 20)
        .background(Color(.systemGray6))
        .cornerRadius(36)
    }
    
    // MARK: - Private
    private func loadAndCacheCoinImage(for coin: Coin) {
        if let url = coin.image {
            Task {
                if let data = await viewModel.loadImage(from: url),
                   let uiImage = UIImage(data: data) {
                    if isSelectingFirstCoin {
                        cachedImage1 = Image(uiImage: uiImage)
                    } else {
                        cachedImage2 = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CryptoCompareView()
        .preferredColorScheme(.dark)
}
