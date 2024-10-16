//
//  CoinListViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation
import SwiftData

final class CoinListViewModel: BaseViewModel {
    
    // MARK: - Properties
    
    @Published var coins: [CoinData] = []
    @Published private(set) var marketData: [String: MarketData] = [:]
    
    private let coinScannerService: CoinScannerService
    private let priceAlertService: PriceAlertService
    private var timer: Timer?
    
    // MARK: - Initializers
    
    convenience init() {
        if let modelContainer = try? ModelContainer(for: CoinData.self) {
            let swiftDataManager = SwiftDataManagerImpl(modelContainer: modelContainer)
            self.init(coinScannerService: CoinScannerServiceImpl(), priceAlertService: PriceAlertServiceImpl(), swiftDataManager: swiftDataManager)
        }
        self.init(coinScannerService: CoinScannerServiceImpl(), priceAlertService: PriceAlertServiceImpl())
    }
    
    init(coinScannerService: CoinScannerService, priceAlertService: PriceAlertService, swiftDataManager: SwiftDataManager? = nil) {
        self.coinScannerService = coinScannerService
        self.priceAlertService = priceAlertService
        super.init(swiftDataManager: swiftDataManager, userDefaultsManager: UserDefaultsManagerImpl())
    }
    
    // MARK: - Methods
    
    func fetchCoins() async {
        if isFirstLaunch {
            await insertPredefinedCoins()
        } else {
            let descriptor = FetchDescriptor<CoinData>(sortBy: [SortDescriptor(\.rank)])
            coins = fetch(descriptor)
        }
        
        if !coins.isEmpty {
            await fetchMarketData()
            await fetchPriceAlerts()
        }
    }
    
    func createCoin(_ coin: Coin, _ marketData: MarketData? = nil) async {
        if !coins.contains(where: { $0.id == coin.id }) {
            let newCoin = CoinData()
            newCoin.id = coin.id
            newCoin.name = coin.name
            newCoin.imageURL = coin.imageURL
            newCoin.rank = coin.marketCapRank ?? .max
            newCoin.targetPrice = nil
            newCoin.isActive = false
            
            if let marketData {
                newCoin.currentPrice = marketData.currentPrice ?? .zero
                newCoin.priceChange = marketData.priceChange ?? .zero
            } else {
                newCoin.currentPrice = coin.currentPrice ?? .zero
                newCoin.priceChange = coin.priceChangePercentage24H ?? .zero
            }
            
            await insertNewCoin(newCoin)
        }
    }
    
    func deleteCoin(_ coin: CoinData) async {
        if coin.targetPrice != nil {
            await deletePriceAlert(for: coin.id)
        }
        deleteAndSave(coin)
        if let index = coins.firstIndex(of: coin) {
            coins.remove(at: index)
        }
    }
    
    func setPriceAlert(for coin: CoinData, targetPrice: Double?) async {
        if let targetPrice {
            coin.targetPrice = targetPrice
            coin.isActive = true
            await setPriceAlert(for: coin)
        } else {
            coin.targetPrice = nil
            coin.isActive = false
            await deletePriceAlert(for: coin.id)
        }
        save()
    }
    
    func toggleOffPriceAlert(for id: String) {
        if let index = coins.firstIndex(where: { $0.id == id }) {
            coins[index].targetPrice = nil
            coins[index].isActive = false
        }
        save()
    }
    
    // MARK: - Private
    
    private func insertPredefinedCoins() async {
        let predefinedCoins = CoinData.predefinedCoins
        
        for coin in predefinedCoins {
            await insertNewCoin(coin)
        }
        
        self.coins = predefinedCoins
    }
    
    private func insertNewCoin(_ coin: CoinData) async {
        if let url = coin.imageURL {
            coin.imageData = await loadImage(from: url)
        }
        coins.append(coin)
        sortCoins()
        insertAndSave(coin)
    }
    
    private func fetchPriceAlerts() async {
        guard let deviceToken else { return }
        do {
            let priceAlerts = try await priceAlertService.getPriceAlerts(deviceToken: deviceToken)
            for (index, coin) in coins.enumerated() {
                if let matchingPriceAlert = priceAlerts.first(where: { $0.coinId == coin.id }) {
                    coins[index].targetPrice = matchingPriceAlert.targetPrice
                    coins[index].isActive = true
                } else {
                    coins[index].targetPrice = nil
                    coins[index].isActive = false
                }
            }
            save()
        } catch {
            setErrorMessage(error)
        }
    }
    
    private func setPriceAlert(for coin: CoinData) async {
        guard let deviceToken else { return }
        do {
            let priceAlert = try await priceAlertService.setPriceAlert(for: coin, deviceToken: deviceToken)
            print("Successfully set price alert for \(priceAlert.coinName) with target price \(priceAlert.targetPrice)")
        } catch {
            setErrorMessage(error)
        }
    }
    
    private func deletePriceAlert(for id: String) async {
        guard let deviceToken else { return }
        do {
            let priceAlert = try await priceAlertService.deletePriceAlert(for: id, deviceToken: deviceToken)
            print("Successfully deleted price alert for \(priceAlert.coinName)")
        } catch {
            setErrorMessage(error)
        }
    }
    
    private func fetchMarketData() async {
        let coinIDs = coins.map { $0.id }
        let existingMarketData = coinIDs.compactMap { marketData[$0] }
        
        guard existingMarketData.count != coins.count else { return }
        
        do {
            let fetchedMarketData = try await coinScannerService.getMarketData(for: coinIDs)
            for (index, coinID) in coinIDs.enumerated() {
                if let coinMarketData = fetchedMarketData[coinID] {
                    marketData[coinID] = coinMarketData
                    coins[index].currentPrice = coinMarketData.currentPrice ?? .zero
                    coins[index].priceChange = coinMarketData.priceChange ?? .zero
                }
            }
            save()
        } catch {
            setErrorMessage(error)
        }
    }
    
    private func sortCoins() {
        coins.sort { $0.rank < $1.rank }
    }
}
