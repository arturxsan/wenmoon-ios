//
//  PortfolioViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.12.24.
//

import SwiftUI
import SwiftData

final class PortfolioViewModel: BaseViewModel {
    // MARK: - Nested Types
    enum Timeline: String {
        case twentyFourHours = "24h"
        case allTime = "All Time"
    }
    
    // MARK: - Properties
    private let portfolioService: PortfolioService
    private let coinScannerService: CoinScannerService
    
    @Published var portfolio: Portfolio!
    @Published private(set) var groupedTransactions: [CoinTransactions] = []
    
    @Published private(set) var totalValue: Double = .zero
    @Published private(set) var portfolioChange24HValue: Double = .zero
    @Published private(set) var portfolioChange24HPercentage: Double = .zero
    @Published private(set) var portfolioChangeAllTimeValue: Double = .zero
    @Published private(set) var portfolioChangeAllTimePercentage: Double = .zero
    
    @Published private(set) var selectedTimeline: Timeline = .twentyFourHours
    
    var portfolioChangePercentage: Double {
        switch selectedTimeline {
        case .twentyFourHours:
            return portfolioChange24HPercentage
        case .allTime:
            return portfolioChangeAllTimePercentage
        }
    }
    
    var portfolioChangeValue: Double {
        switch selectedTimeline {
        case .twentyFourHours:
            return portfolioChange24HValue
        case .allTime:
            return portfolioChangeAllTimeValue
        }
    }
    
    var portfolioChangeColor: Color {
        guard portfolioChangeValue != .zero else { return .gray }
        return portfolioChangeValue.isNegative ? .neonPink : .neonGreen
    }
    
    // MARK: - Initializers
    convenience init() {
        self.init(portfolioService: PortfolioServiceImpl(), coinScannerService: CoinScannerServiceImpl())
    }
    
    init(
        portfolioService: PortfolioService,
        coinScannerService: CoinScannerService,
        authStateProvider: AuthStateProvider? = nil,
        swiftDataManager: SwiftDataManager? = nil
    ) {
        self.portfolioService = portfolioService
        self.coinScannerService = coinScannerService
        super.init(authStateProvider: authStateProvider, swiftDataManager: swiftDataManager)
    }
    
    // MARK: - Methods
    @MainActor
    func fetchPortfolio() async {
        do {
            let descriptor = FetchDescriptor<Portfolio>()
            let fetchedPortfolios = try fetch(descriptor)
            
            guard !fetchedPortfolios.isEmpty else {
                self.portfolio = nil
                
                guard let portfolio = try await fetchRemotePortfolio() else { return }
                self.portfolio = portfolio
                try insert(portfolio)
                await updatePortfolio()
                
                return
            }
            
            portfolio = fetchedPortfolios.first
            await updatePortfolio()
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func fetchMarketData() async {
        let coinIDs = portfolio.transactions.compactMap(\.coinID)
        
        do {
            let fetchedMarketData = try await coinScannerService.getMarketData(coinIDs)
            for id in coinIDs {
                if let data = fetchedMarketData[id] {
                    let coin = fetchCoin(by: id)
                    coin?.updateMarketData(from: data)
                }
            }
            try save()
            NotificationCenter.default.post(name: .userDidUpdateWatchlist, object: nil)
            
            await updatePortfolio()
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func syncPortfolio() async -> Bool {
        do {
            guard let portfolio, let authToken = try await authStateProvider.fetchAuthToken() else {
                return false
            }
            let isPortfolioSynced = try await portfolioService.syncPortfolio(portfolio, authToken: authToken)
            return isPortfolioSynced
        } catch {
            setError(error)
            return false
        }
    }
    
    @MainActor
    func addTransaction(_ transaction: Transaction, _ coin: Coin?) async {
//        let coinID = transaction.coinID
//        let grouped = Dictionary(grouping: portfolio.transactions, by: { $0.coinID })
//        let transactionsForCoin = grouped[coinID] ?? []
//        
//        let uniqueCoinIDs = grouped.keys
//        
//        if uniqueCoinIDs.count >= 3 && !uniqueCoinIDs.contains(coinID) {
//            guard checkProStatus() else { return }
//        }
//        
//        if transactionsForCoin.count >= 5 {
//            guard checkProStatus() else { return }
//        }
        
        transaction.portfolio = portfolio
        portfolio.transactions.append(transaction)
        await updateAndSyncPortfolio()
    }
    
    func editTransaction(_ transaction: Transaction) async {
        guard let index = portfolio.transactions.firstIndex(where: { $0.id == transaction.id }) else {
            return
        }
        portfolio.transactions[index].update(from: transaction)
        await updateAndSyncPortfolio()
    }
    
    func deleteTransactions(for coinID: String) async {
        portfolio.transactions.removeAll { $0.coinID == coinID }
        await updateAndSyncPortfolio()
    }
    
    func deleteTransaction(_ transactionID: String) async {
        portfolio.transactions.removeAll { $0.id == transactionID }
        await updateAndSyncPortfolio()
    }
    
    @MainActor
    func updatePortfolio() async {
        groupedTransactions = await groupTransactionsByCoin()
        totalValue = calculateTotalValue()
        calculatePortfolio24HChanges()
        calculatePortfolioChanges()
    }
    
    func fetchCoin(by id: String) -> Coin? {
        let descriptor = FetchDescriptor<Coin>()
        let fetchedCoins = safeFetch(descriptor)
        return fetchedCoins.first(where: { $0.id == id })
    }
    
    func isDeductiveTransaction(_ transactionType: Transaction.TransactionType) -> Bool {
        (transactionType == .sell) || (transactionType == .transferOut)
    }
    
    func toggleSelectedTimeline() {
        selectedTimeline = (selectedTimeline == .twentyFourHours) ? .allTime : .twentyFourHours
    }
    
    // MARK: - Private
    @MainActor
    private func fetchRemotePortfolio() async throws -> Portfolio? {
        isLoading = true
        defer { isLoading = false }
        
        guard let authToken = try await authStateProvider.fetchAuthToken() else { return nil }
        let portfolio = try await portfolioService.getPortfolio(authToken: authToken)
        return portfolio
    }
    
    private func updateAndSyncPortfolio() async {
        await updatePortfolio()
        await syncPortfolio()
        safeSave()
    }
    
    @MainActor
    private func groupTransactionsByCoin() async -> [CoinTransactions] {
        let groupedTransactions = Dictionary(grouping: portfolio.transactions) { $0.coinID }
        var result: [CoinTransactions] = []
        
        for (coinID, transactions) in groupedTransactions {
            guard let coinID else { continue }
            
            if let coin = fetchCoin(by: coinID) {
                result.append(CoinTransactions(coin: coin, transactions: transactions))
            } else if let remoteCoin = await fetchRemoteCoin(coinID) {
                insertCoin(remoteCoin)
                result.append(CoinTransactions(coin: remoteCoin, transactions: transactions))
            }
        }
        
        return result.sorted { $0.totalValue > $1.totalValue }
    }
    
    @MainActor
    private func fetchRemoteCoin(_ coinID: String) async -> Coin? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let coinDetails = try await coinScannerService.getCoinDetails(coinID)
            let coin = Coin(from: coinDetails, isArchived: true)
            return coin
        } catch {
            setError(error)
            return nil
        }
    }
    
    @MainActor
    private func insertCoin(_ coin: Coin) {
        safeInsert(coin)
        
        if let image = coin.image {
            Task { @MainActor in
                let imageData = await loadImage(from: image)
                coin.imageData = imageData
                safeSave()
            }
        }
        
        NotificationCenter.default.post(name: .userDidUpdateWatchlist, object: nil)
    }
    
    private func calculateTotalValue() -> Double {
        groupedTransactions.reduce(0) { total, group in
            total + group.totalValue
        }
    }
    
    private func calculatePortfolio24HChanges() {
        var total24HChange: Double = .zero
        var previousTotalValue: Double = .zero
        
        groupedTransactions.forEach { coinTransaction in
            guard let currentPrice = coinTransaction.coin.currentPrice,
                  let priceChangePercentage24H = coinTransaction.coin.priceChangePercentage24H else {
                return
            }
            
            let totalQuantity = coinTransaction.totalQuantity
            let coinValue24HChange = totalQuantity * currentPrice * (priceChangePercentage24H / 100)
            total24HChange += coinValue24HChange
            
            let previousCoinValue = totalQuantity * currentPrice / (1 + priceChangePercentage24H / 100)
            previousTotalValue += previousCoinValue
        }
        
        let isPreviousTotalValuePositive = previousTotalValue > .zero
        portfolioChange24HValue = isPreviousTotalValuePositive ? total24HChange : .zero
        portfolioChange24HPercentage = isPreviousTotalValuePositive ? (total24HChange / previousTotalValue) * 100 : .zero
    }
    
    private func calculatePortfolioChanges() {
        var initialInvestment: Double = .zero
        var realizedValue: Double = .zero
        var remainingQuantity: Double = .zero
        
        let sortedTransactions = portfolio.transactions.sorted { $0.date < $1.date }
        sortedTransactions.forEach { transaction in
            let quantity = transaction.quantity ?? .zero
            let pricePerCoin = transaction.pricePerCoin ?? .zero
            
            switch transaction.type {
            case .buy:
                initialInvestment += quantity * pricePerCoin
                remainingQuantity += quantity
            case .sell:
                if remainingQuantity > .zero {
                    realizedValue += quantity * pricePerCoin
                    remainingQuantity -= quantity
                }
            case .transferIn:
                remainingQuantity += quantity
            case .transferOut:
                if remainingQuantity > .zero {
                    remainingQuantity -= quantity
                }
            }
        }
        
        let isInitialInvestmentPositive = (initialInvestment > .zero)
        portfolioChangeAllTimeValue = isInitialInvestmentPositive ? ((totalValue + realizedValue) - initialInvestment) : .zero
        portfolioChangeAllTimePercentage = isInitialInvestmentPositive ? ((portfolioChangeAllTimeValue / initialInvestment) * 100) : .zero
    }
}

// MARK: - CoinTransactions
struct CoinTransactions: Equatable {
    let coin: Coin
    let transactions: [Date: [Transaction]]
    
    var totalQuantity: Double {
        transactions.values.flatMap { $0 }.reduce(0) { total, transaction in
            guard let quantity = transaction.quantity else { return total }
            switch transaction.type {
            case .buy, .transferIn:
                return total + quantity
            case .sell, .transferOut:
                return total - quantity
            }
        }
    }
    
    var totalValue: Double {
        guard let currentPrice = coin.currentPrice else { return .zero }
        return totalQuantity * currentPrice
    }
    
    init(coin: Coin, transactions: [Transaction]) {
        self.coin = coin
        let groupedByDate = Dictionary(grouping: transactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        self.transactions = groupedByDate.mapValues { transactions in
            transactions.sorted { $0.date > $1.date }
        }
    }
}
