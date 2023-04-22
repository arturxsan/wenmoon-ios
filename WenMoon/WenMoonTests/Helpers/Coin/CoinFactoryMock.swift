//
//  CoinFactoryMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 18.10.24.
//

import Foundation
@testable import WenMoon

struct CoinFactoryMock {
    // MARK: - Coin
    static func coin(
        id: String = "coin-1",
        symbol: String = "SYM-1",
        name: String = "Coin 1",
        image: URL? = nil,
        imageData: Data? = nil,
        currentPrice: Double? = .random(in: 0.01...100_000),
        marketCap: Double? = .random(in: 1_000...1_000_000_000),
        marketCapRank: Int64? = .random(in: 1...1_000),
        priceChangePercentage24H: Double? = .random(in: -50...50),
        circulatingSupply: Double? = .random(in: 1_000_000...1_000_000_000),
        ath: Double? = .random(in: 10...100_000),
        isPinned: Bool = false,
        isArchived: Bool = false,
        priceAlerts: [PriceAlert] = []
    ) -> Coin {
        .init(
            id: id,
            symbol: symbol,
            name: name,
            image: image,
            imageData: imageData,
            currentPrice: currentPrice,
            marketCap: marketCap,
            marketCapRank: marketCapRank,
            priceChangePercentage24H: priceChangePercentage24H,
            circulatingSupply: circulatingSupply,
            ath: ath,
            isPinned: isPinned,
            isArchived: isArchived,
            priceAlerts: priceAlerts
        )
    }
    
    static func coins(count: Int = 10, at page: Int = 1) -> [Coin] {
        let startIndex = (page - 1) * count + 1
        return (startIndex..<startIndex + count).map { index in
            coin(
                id: "coin-\(index)",
                symbol: "SYM-\(index)",
                name: "Coin \(index)",
                marketCap: Double(1_000_000_000 - index * 100_000)
            )
        }
    }
}
