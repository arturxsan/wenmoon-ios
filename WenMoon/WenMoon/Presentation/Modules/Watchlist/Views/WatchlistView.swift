//
//  WatchlistView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import SwiftUI

struct WatchlistView: View {
    // MARK: - Properties
    @StateObject private var viewModel = WatchlistViewModel()
    @State private var selectedCoin: Coin?
    @State private var swipedCoin: Coin?
    @State private var viewDidLoad = false
    @State private var showCoinSelectionView = false
    
    private var coins: [Coin] { viewModel.coins }
    
    // MARK: - Body
    var body: some View {
        BaseView(isLoading: $viewModel.isLoading, errorMessage: $viewModel.errorMessage) {
            NavigationStack {
                VStack {
                    if viewModel.isLoading {
                        CustomProgressView()
                    } else if coins.isEmpty {
                        PlaceholderView(text: "No coins added yet")
                    } else {
                        List {
                            let pinnedCoins = viewModel.pinnedCoins
                            let unpinnedCoins = viewModel.unpinnedCoins
                            
                            if !pinnedCoins.isEmpty {
                                Section(header: Text("Pinned")) {
                                    ForEach(pinnedCoins, id: \.id) { coin in
                                        coinRow(coin)
                                    }
                                    .onMove(perform: movePinnedCoin)
                                }
                            }
                            
                            if !unpinnedCoins.isEmpty {
                                Section(header: Text("All")) {
                                    ForEach(unpinnedCoins, id: \.id) { coin in
                                        coinRow(coin)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            Task {
                                await viewModel.fetchMarketData(isRefreshing: true)
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: coins)
                .navigationTitle("Coins")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCoinSelectionView = true
                        } label: {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCoinSelectionView, onDismiss: {
            Task {
                await viewModel.fetchPriceAlerts()
                await viewModel.syncWatchlist()
            }
        }) {
            CoinSelectionView(didToggleCoin: handleCoinSelection)
        }
        .sheet(item: $selectedCoin, onDismiss: {
            selectedCoin = nil
        }) { coin in
            CoinDetailsView(coin: coin)
                .presentationCornerRadius(36)
        }
        .sheet(item: $swipedCoin, onDismiss: {
            swipedCoin = nil
        }) { coin in
            PriceAlertsView(coin: coin)
                .presentationCornerRadius(36)
        }
        .onReceive(NotificationCenter.default.publisher(for: .targetPriceReached)) { notification in
            if let id = notification.userInfo?["id"] as? String {
                viewModel.deactivatePriceAlert(id)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidUpdateWatchlist)) { notification in
            fetchWatchlistAndAlerts(shouldSync: true, isRefreshing: true)
        }
        .onChange(of: viewModel.account?.id) { _, accountID in
            guard viewDidLoad, accountID.isNotNil else { return }
            fetchWatchlistAndAlerts()
        }
        .onLoad {
            fetchWatchlistAndAlerts()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func coinRow(_ coin: Coin) -> some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: .zero) {
                ZStack(alignment: .topTrailing) {
                    CoinImageView(
                        imageURL: coin.image,
                        placeholderText: coin.symbol,
                        size: 48
                    )
                    
                    if !coin.priceAlerts.filter(\.isActive).isEmpty, viewModel.isNotificationsEnabled {
                        Image("bell.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.softGray)
                            .padding(4)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .padding(.trailing, -8)
                            .padding(.top, -8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(coin.symbol)
                        .font(.headline)
                    
                    Text(coin.marketCap.formattedWithAbbreviation(suffix: "$"))
                        .font(.caption2).bold()
                        .foregroundStyle(.gray)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                let priceChange = coin.priceChangePercentage24H
                let isPriceChangeNegative = priceChange?.isNegative ?? false
                let priceChangeColor: Color = (priceChange?.isZero ?? true) ? .gray : (isPriceChangeNegative ? .neonPink : .neonGreen)
                HStack {
                    Image(isPriceChangeNegative ? "arrow.decrease" : "arrow.increase")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    
                    Text(coin.priceChangePercentage24H.formattedAsPercentage())
                        .font(.caption2).bold()
                }
                .foregroundStyle(priceChangeColor)
            }
            
            Text(coin.currentPrice.formattedAsCurrency())
                .font(.footnote).bold()
                .padding(.trailing, 100)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCoin = coin
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task {
                    try await Task.sleep(for: .milliseconds(200))
                    viewModel.deleteCoin(coin.id)
                    await viewModel.syncWatchlist()
                }
            } label: {
                Image("trash")
            }
            .tint(.neonPink)
            
            Button {
                coin.isPinned ? viewModel.unpinCoin(coin) : viewModel.pinCoin(coin)
                Task { await viewModel.syncWatchlist() }
            } label: {
                Image(systemName: coin.isPinned ? "pin.slash.fill" : "pin.fill")
            }
            .tint(.neonCyan)
        }
        .swipeActions(edge: .leading) {
            Button {
                swipedCoin = coin
            } label: {
                Image("bell.add.fill")
            }
            .tint(.neonYellow)
        }
    }
    
    // MARK: - Private
    private func fetchWatchlistAndAlerts(shouldSync: Bool = false, isRefreshing: Bool = false) {
        Task {
            await viewModel.fetchWatchlist()
            await viewModel.fetchMarketData(isRefreshing: isRefreshing)
            await viewModel.fetchPriceAlerts()
            
            if shouldSync { await viewModel.syncWatchlist() }
            
            viewModel.sortCoinsAndSaveOrder()
            viewDidLoad = true
        }
    }
    
    private func movePinnedCoin(from source: IndexSet, to destination: Int) {
        viewModel.movePinnedCoin(from: source, to: destination)
        Task { await viewModel.syncWatchlist() }
    }
    
    private func handleCoinSelection(coin: Coin, shouldAdd: Bool) {
        shouldAdd ? viewModel.saveCoin(coin) : viewModel.deleteCoin(coin.id)
    }
}

// MARK: - Preview
#Preview {
    WatchlistView()
        .preferredColorScheme(.dark)
}
