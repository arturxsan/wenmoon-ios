//
//  Coin+Assertions.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 18.10.24.
//

import Foundation
import XCTest
@testable import WenMoon

func assertCoinsEqual(_ coins: [Coin], _ expectedCoins: [Coin]) {
    XCTAssertEqual(coins.count, expectedCoins.count)
    for (index, _) in coins.enumerated() {
        let coin = coins[index]
        let expectedCoin = expectedCoins[index]
        XCTAssertEqual(coin.id, expectedCoin.id)
        XCTAssertEqual(coin.symbol, expectedCoin.symbol)
        XCTAssertEqual(coin.name, expectedCoin.name)
        XCTAssertEqual(coin.image, expectedCoin.image)
        XCTAssertEqual(coin.currentPrice, expectedCoin.currentPrice)
        XCTAssertEqual(coin.marketCap, expectedCoin.marketCap)
        XCTAssertEqual(coin.marketCapRank, expectedCoin.marketCapRank)
        XCTAssertEqual(coin.priceChangePercentage24H, expectedCoin.priceChangePercentage24H)
        XCTAssertEqual(coin.circulatingSupply, expectedCoin.circulatingSupply)
        XCTAssertEqual(coin.ath, expectedCoin.ath)
    }
}
