//
//  WatchlistViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation
import SwiftData
import SwiftUI

final class WatchlistViewModel: BaseViewModel {
    // MARK: - Properties
    private let watchlistService: WatchlistService
    private let coinScannerService: CoinScannerService
    private let priceAlertsViewModel: PriceAlertsViewModel
    
    @Published var coins: [Coin] = []
    
    var pinnedCoins: [Coin] { coins.filter { $0.isPinned } }
    var unpinnedCoins: [Coin] { coins.filter { !$0.isPinned } }
    
    // MARK: - Initializers
    convenience init() {
        self.init(
            watchlistService: WatchlistServiceImpl(),
            coinScannerService: CoinScannerServiceImpl(),
            priceAlertsViewModel: PriceAlertsViewModel()
        )
    }
    
    init(
        watchlistService: WatchlistService,
        coinScannerService: CoinScannerService,
        priceAlertsViewModel: PriceAlertsViewModel,
        authStateProvider: AuthStateProvider? = nil,
        swiftDataManager: SwiftDataManager? = nil,
        userDefaultsManager: UserDefaultsManager? = nil
    ) {
        self.watchlistService = watchlistService
        self.coinScannerService = coinScannerService
        self.priceAlertsViewModel = priceAlertsViewModel
        super.init(
            authStateProvider: authStateProvider,
            swiftDataManager: swiftDataManager,
            userDefaultsManager: userDefaultsManager
        )
    }
    
    // MARK: - Methods
    @MainActor
    func fetchWatchlist() async {
        do {
            let descriptor = FetchDescriptor<Coin>(
                predicate: #Predicate { !$0.isArchived },
                sortBy: [SortDescriptor(\.marketCap)]
            )
            let fetchedCoins = try fetch(descriptor)
            
            guard !fetchedCoins.isEmpty else {
                coins = []
                guard let watchlist = try await fetchRemoteWatchlist() else { return }
                for coin in watchlist.coins {
                    let isPinned = watchlist.pinnedCoinIDs.contains(coin.id)
                    insertCoin(coin, isPinned: isPinned)
                }
                return
            }
            
            if let savedOrder = try userDefaultsManager.getObject(forKey: .coinsOrder, objectType: [String].self) {
                coins = fetchedCoins.sorted { coin1, coin2 in
                    let index1 = savedOrder.firstIndex(of: coin1.id) ?? .max
                    let index2 = savedOrder.firstIndex(of: coin2.id) ?? .max
                    return index1 < index2
                }
            } else {
                coins = fetchedCoins
            }
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func syncWatchlist() async -> Bool {
        do {
            guard let authToken = try await authStateProvider.fetchAuthToken() else { return false }
            let pinnedCoinIDs = coins.filter(\.isPinned).map(\.id)
            let request = Watchlist(coins: coins, pinnedCoinIDs: pinnedCoinIDs)
            let isWatchlistSynced = try await watchlistService.syncWatchlist(request, authToken: authToken)
            return isWatchlistSynced
        } catch {
            setError(error)
            return false
        }
    }
    
    @MainActor
    func fetchMarketData(isRefreshing: Bool = false) async {
        let coinIDs = coins.map { $0.id }
        
        do {
            let fetchedMarketData = try await coinScannerService.getMarketData(coinIDs)
            for coin in coins {
                let id = coin.id
                if let data = fetchedMarketData[id] {
                    coin.updateMarketData(from: data)
                }
            }
            try save()
            
            if !isRefreshing { triggerImpactFeedback() }
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func fetchPriceAlerts() async {
        guard !coins.isEmpty else { return }
        let priceAlerts = await priceAlertsViewModel.fetchPriceAlerts()
        
        for coin in coins {
            let matchingAlerts = priceAlerts.filter { $0.coinID == coin.id }
            coin.priceAlerts = matchingAlerts
        }
    }
    
    func saveCoin(_ coin: Coin) {
        let descriptor = FetchDescriptor<Coin>()
        let fetchedCoins = safeFetch(descriptor)
        
//        if fetchedCoins.count >= 20 {
//            guard checkProStatus() else { return }
//        }
        
        if let existingCoin = fetchedCoins.first(where: { $0.id == coin.id }) {
            if existingCoin.isArchived {
                unarchiveCoin(existingCoin)
            }
            return
        }
        
        insertCoin(coin)
    }
    
    func deleteCoin(_ coinID: String) {
        guard let coin = coins.first(where: { $0.id == coinID }) else { return }
        
        let descriptor = FetchDescriptor<Portfolio>()
        let portfolios = safeFetch(descriptor)
        
        var isCoinReferenced = false
        for portfolio in portfolios {
            if portfolio.transactions.contains(where: { $0.coinID == coin.id }) {
                isCoinReferenced = true
                break
            }
        }
        
        if isCoinReferenced {
            archiveCoin(coin)
        } else {
            removeCoin(coin)
        }
    }
    
    func deactivatePriceAlert(_ id: String) {
        coins.forEach { coin in
            if let alertIndex = coin.priceAlerts.firstIndex(where: { $0.id == id }) {
                coin.priceAlerts[alertIndex].isActive = false
                safeSave()
                return
            }
        }
    }
    
    func pinCoin(_ coin: Coin) {
//        let pinnedCount = coins.filter { $0.isPinned }.count
//        if pinnedCount >= 3 {
//            guard checkProStatus() else { return }
//        }
        
        if let index = coins.firstIndex(where: { $0.id == coin.id }) {
            withAnimation {
                coins[index].isPinned = true
                let pinnedCoin = coins.remove(at: index)
                coins.insert(pinnedCoin, at: .zero)
                sortCoinsAndSaveOrder()
            }
            safeSave()
        }
    }
    
    func unpinCoin(_ coin: Coin) {
        if let index = coins.firstIndex(where: { $0.id == coin.id }) {
            withAnimation {
                coins[index].isPinned = false
                sortCoinsAndSaveOrder()
            }
            safeSave()
        }
    }
    
    
    func sortCoinsAndSaveOrder() {
        sortCoins()
        saveOrder()
    }
    
    func movePinnedCoin(from source: IndexSet, to destination: Int) {
        var pinnedCoins = coins.filter { $0.isPinned }
        pinnedCoins.move(fromOffsets: source, toOffset: destination)
        
        let otherCoins = coins.filter { !$0.isPinned }
        coins = (pinnedCoins + otherCoins)
        saveOrder()
    }
    
    // MARK: - Private
    @MainActor
    private func fetchRemoteWatchlist() async throws -> Watchlist? {
        isLoading = true
        defer { isLoading = false }
        
        guard let authToken = try await authStateProvider.fetchAuthToken() else { return nil }
        let watchlist = try await watchlistService.getWatchlist(authToken: authToken)
        return watchlist
    }
    
    private func insertCoin(_ coin: Coin, isPinned: Bool = false) {
        guard !coins.map(\.id).contains(coin.id) else { return }
        
        coin.isPinned = isPinned
        coins.append(coin)
        safeInsert(coin)
        sortCoinsAndSaveOrder()
        
        if let image = coin.image {
            Task { @MainActor in
                let imageData = await loadImage(from: image)
                coin.imageData = imageData
                safeSave()
            }
        }
    }
    
    private func removeCoin(_ coin: Coin) {
        if let index = coins.firstIndex(of: coin) {
            coins.remove(at: index)
        }
        safeDelete(coin)
        saveOrder()
    }
    
    private func archiveCoin(_ coin: Coin) {
        coin.isArchived = true
        coin.isPinned = false
        if let index = coins.firstIndex(of: coin) {
            coins.remove(at: index)
        }
        saveOrder()
        safeSave()
    }
    
    private func unarchiveCoin(_ coin: Coin) {
        coin.isArchived = false
        coins.append(coin)
        sortCoinsAndSaveOrder()
        safeSave()
    }
    
    private func sortCoins() {
        let pinnedCoins = coins.filter { $0.isPinned }
        var unpinnedCoins = coins.filter { !$0.isPinned }
        unpinnedCoins.sort { ($0.marketCap ?? .zero) > ($1.marketCap ?? .zero) }
        withAnimation {
            coins = pinnedCoins + unpinnedCoins
        }
    }
    
    private func saveOrder() {
        let coinIDs = coins.map { $0.id }
        try? userDefaultsManager.setObject(coinIDs, forKey: .coinsOrder)
    }
}
