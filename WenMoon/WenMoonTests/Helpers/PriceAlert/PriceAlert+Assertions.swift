//
//  PriceAlert+Assertions.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 21.10.24.
//

import Foundation
import XCTest
@testable import WenMoon

func assertPriceAlertsEqual(_ alerts: [PriceAlert], _ expectedAlerts: [PriceAlert]) {
    XCTAssertEqual(alerts.count, expectedAlerts.count)
    for (index, _) in alerts.enumerated() {
        let alert = alerts[index]
        let expectedAlert = expectedAlerts[index]
        
        XCTAssertEqual(alert.id, expectedAlert.id)
        XCTAssertEqual(alert.coinID, expectedAlert.coinID)
        XCTAssertEqual(alert.symbol, expectedAlert.symbol)
        XCTAssertEqual(alert.targetPrice, expectedAlert.targetPrice)
        XCTAssertEqual(alert.targetDirection, expectedAlert.targetDirection)
        XCTAssertEqual(alert.isActive, expectedAlert.isActive)
    }
}

func assertCoinHasActiveAlert(_ coin: Coin, _ priceAlert: PriceAlert) {
    XCTAssertFalse(coin.priceAlerts.isEmpty)
    XCTAssertTrue(coin.priceAlerts.contains(priceAlert))
}

func assertCoinHasNoActiveAlert(_ coin: Coin) {
    XCTAssertTrue(coin.priceAlerts.filter(\.isActive).isEmpty)
}

func assertCoinHasNoAlert(_ coin: Coin) {
    XCTAssertTrue(coin.priceAlerts.isEmpty)
}
