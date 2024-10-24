//
//  Coin+Assertations.swift
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
        XCTAssertEqual(coin.name, expectedCoin.name)
        XCTAssertEqual(coin.imageURL, expectedCoin.imageURL)
        XCTAssertEqual(coin.marketCapRank, expectedCoin.marketCapRank)
        XCTAssertEqual(coin.currentPrice, expectedCoin.currentPrice)
        XCTAssertEqual(coin.priceChangePercentage24H, expectedCoin.priceChangePercentage24H)
    }
}

func assertCoinsEqual(_ coins: [CoinData], _ expectedCoins: [CoinData]) {
    XCTAssertEqual(coins.count, expectedCoins.count)
    for (index, _) in coins.enumerated() {
        let coin = coins[index]
        let expectedCoin = expectedCoins[index]
        XCTAssertEqual(coin.id, expectedCoin.id)
        XCTAssertEqual(coin.name, expectedCoin.name)
        XCTAssertEqual(coin.imageURL, expectedCoin.imageURL)
        XCTAssertEqual(coin.rank, expectedCoin.rank)
        XCTAssertEqual(coin.currentPrice, expectedCoin.currentPrice)
        XCTAssertEqual(coin.priceChange, expectedCoin.priceChange)
    }
}

func assertCoinsEqual(_ coins: [CoinData], _ expectedCoins: [Coin]) {
    XCTAssertEqual(coins.count, expectedCoins.count)
    for (index, _) in coins.enumerated() {
        let coin = coins[index]
        let expectedCoin = expectedCoins[index]
        XCTAssertEqual(coin.id, expectedCoin.id)
        XCTAssertEqual(coin.name, expectedCoin.name)
        XCTAssertEqual(coin.imageURL, expectedCoin.imageURL)
        XCTAssertEqual(coin.rank, expectedCoin.marketCapRank)
        XCTAssertEqual(coin.currentPrice, expectedCoin.currentPrice)
        XCTAssertEqual(coin.priceChange, expectedCoin.priceChangePercentage24H)
    }
}
