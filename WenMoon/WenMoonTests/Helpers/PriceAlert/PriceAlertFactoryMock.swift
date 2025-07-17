//
//  PriceAlertFactoryMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 21.10.24.
//

import Foundation
@testable import WenMoon

struct PriceAlertFactoryMock {
    static func priceAlert(
        id: String = UUID().uuidString,
        coinID: String = "coin-1",
        symbol: String = "SYM-1",
        targetPrice: Double = .random(in: 0.01...100_000),
        targetDirection: PriceAlert.TargetDirection = Bool.random() ? .above : .below,
        isActive: Bool = true
    ) -> PriceAlert {
        .init(
            id: id,
            coinID: coinID,
            symbol: symbol,
            targetPrice: targetPrice,
            targetDirection: targetDirection,
            isActive: isActive
        )
    }
    
    static func priceAlerts(count: Int = 10) -> [PriceAlert] {
        (1...count).map { index in
            priceAlert(
                id: "coin-\(index)",
                symbol: "SYM-\(index)"
            )
        }
    }
}
