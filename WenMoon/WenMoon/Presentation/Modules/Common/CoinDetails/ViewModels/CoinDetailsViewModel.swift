//
//  CoinDetailsViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 07.11.24.
//

import Foundation
import SwiftUI
import Combine

final class CoinDetailsViewModel: BaseViewModel {
    // MARK: - Properties
    private let service: CoinScannerService
    
    @Published private(set) var coin: Coin
    @Published private(set) var coinDetails = CoinDetails()
    @Published private(set) var chartData: [ChartData] = []
    @Published private(set) var priceChangePercentage: Double = .zero
    @Published var selectedTimeframe: Timeframe = .oneDay {
        didSet { updatePriceChangePercentage() }
    }
    
    var chartDataCache: [Timeframe: [ChartData]] = [:]
    
    var priceChangeFormatted: String {
        priceChangePercentage.formattedAsPercentage()
    }
    
    var priceChangeColor: Color {
        priceChangePercentage.isNegative ? .neonPink : .neonGreen
    }
    
    // MARK: - Initializers
    convenience init(coin: Coin) {
        self.init(coin: coin, service: CoinScannerServiceImpl())
    }
    
    init(coin: Coin, service: CoinScannerService) {
        self.coin = coin
        self.service = service
        super.init()
    }
    
    // MARK: - Methods
    @MainActor
    func fetchCoinDetails() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let coinDetails = try await service.getCoinDetails(coin.id)
            self.coinDetails = coinDetails
            updatePriceChangePercentage()
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func fetchChartData(currency: SettingType.Currency = .usd) async {
        isLoading = true
        defer { isLoading = false }
        
        if let cachedChartData = chartDataCache[selectedTimeframe], !cachedChartData.isEmpty {
            chartData = cachedChartData
            return
        }
        
        do {
            chartData = try await service.getChartData(
                coin.id,
                timeframe: selectedTimeframe.value,
                currency: currency.value
            )
            chartDataCache[selectedTimeframe] = chartData
        } catch {
            setError(error)
        }
    }
    
    // MARK: - Private
    private func updatePriceChangePercentage() {
        priceChangePercentage = selectedTimeframe.priceChangePercentage(from: coinDetails.marketData) ?? .zero
    }
}

// MARK: - Timeframe
enum Timeframe: CaseIterable {
    case oneDay, oneWeek, oneMonth, oneYear
    
    var value: String {
        switch self {
        case .oneDay: return "1"
        case .oneWeek: return "7"
        case .oneMonth: return "31"
        case .oneYear: return "365"
        }
    }
    
    var displayValue: String {
        switch self {
        case .oneDay: return "1D"
        case .oneWeek: return "1W"
        case .oneMonth: return "1M"
        case .oneYear: return "1Y"
        }
    }
    
    func priceChangePercentage(from marketData: CoinDetails.MarketData) -> Double? {
        switch self {
        case .oneDay:
            return marketData.priceChangePercentage24H
        case .oneWeek:
            return marketData.priceChangePercentage7D
        case .oneMonth:
            return marketData.priceChangePercentage30D
        case .oneYear:
            return marketData.priceChangePercentage1Y
        }
    }
}
