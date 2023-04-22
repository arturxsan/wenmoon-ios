//
//  CryptoCompareViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.12.24.
//

import Foundation

final class CryptoCompareViewModel: BaseViewModel {
    // MARK: - Properties
    private let service: CoinScannerService
    
    @Published var selectedPriceOption: PriceOption = .now
    
    // MARK: - Initializers
    convenience init() {
        self.init(service: CoinScannerServiceImpl())
    }
    
    init(service: CoinScannerService) {
        self.service = service
        super.init()
    }
    
    // MARK: - Methods
    @MainActor
    func updateCoinIfNeeded(_ coin: Coin) async -> Coin? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updatedCoin = coin
            if coin.ath.isNil || coin.circulatingSupply.isNil {
                let coinDetails = try await service.getCoinDetails(coin.id)
                updatedCoin.ath = coinDetails.marketData.ath
                updatedCoin.circulatingSupply = coinDetails.marketData.circulatingSupply
            }
            return updatedCoin
        } catch {
            setError(error)
            return nil
        }
    }
    
    func calculatePrice(for coinA: Coin?, coinB: Coin?, option: PriceOption) -> Double? {
        guard let coinA, let coinB else { return nil }
        
        switch option {
        case .now:
            guard let marketCap = coinB.marketCap, let supply = coinA.circulatingSupply else { return nil }
            return marketCap / supply
        case .ath:
            guard
                let bATH = coinB.ath,
                let bSupply = coinB.circulatingSupply,
                let aSupply = coinA.circulatingSupply
            else {
                return nil
            }
            
            return (bATH * bSupply) / aSupply
        }
    }
    
    func calculateMultiplier(for coinA: Coin?, coinB: Coin?, option: PriceOption) -> Double? {
        let hypotheticalPrice = calculatePrice(
            for: coinA,
            coinB: coinB,
            option: option
        )
        
        guard
            let coinA,
            let hypotheticalPrice,
            let currentPrice = coinA.currentPrice
        else {
            return nil
        }
        
        return hypotheticalPrice / currentPrice
    }
    
    func isPositiveMultiplier(_ multiplier: Double) -> Bool? {
        guard multiplier.isFinite, multiplier >= 0 else { return nil }
        
        let tolerance = 0.01
        let isCloseToZero = multiplier < tolerance
        let isCloseToOne = abs(multiplier - 1) < tolerance

        guard !isCloseToZero, !isCloseToOne else { return nil }

        return multiplier > 1
    }
}

enum PriceOption: String, CaseIterable {
    case now = "NOW"
    case ath = "ATH"
}
