//
//  CoinListViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 22.04.23.
//

import XCTest
@testable import WenMoon

@MainActor
class CoinListViewModelTests: XCTestCase {

    // MARK: - Properties

    var viewModel: CoinListViewModel!
    var coinScannerService: CoinScannerServiceMock!
    var priceAlertService: PriceAlertService!
    var swiftDataManager: SwiftDataManagerMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        coinScannerService = CoinScannerServiceMock()
        priceAlertService = PriceAlertServiceImpl()
        swiftDataManager = SwiftDataManagerMock()
        viewModel = CoinListViewModel(
            coinScannerService: coinScannerService,
            priceAlertService: priceAlertService,
            swiftDataManager: swiftDataManager
        )
    }

    override func tearDown() {
        viewModel = nil
        coinScannerService = nil
        priceAlertService = nil
        swiftDataManager = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testFetchCoinsSuccess() async throws {
        let coins = mockCoins
        let marketData = MarketData.mock
        coinScannerService.getMarketDataForCoinsResult = .success(marketData)

        for coin in coins {
            let newCoin = CoinData()
            newCoin.id = coin.id
            newCoin.name = coin.name
            newCoin.imageURL = coin.imageURL
            newCoin.rank = coin.marketCapRank!
            newCoin.currentPrice = marketData[coin.id]!.currentPrice!
            newCoin.priceChange = marketData[coin.id]!.priceChange!
            swiftDataManager.fetchResult.append(newCoin)
        }

        await viewModel.fetchCoins()
        
        XCTAssert(swiftDataManager.fetchMethodCalled)

        XCTAssertFalse(viewModel.coins.isEmpty)
        XCTAssertEqual(viewModel.coins.count, coins.count)

        XCTAssertEqual(viewModel.coins.first?.id, coins.first?.id)
        XCTAssertEqual(viewModel.coins.first?.name, coins.first?.name)
        XCTAssertEqual(viewModel.coins.first?.imageURL, coins.first?.imageURL)
        XCTAssertEqual(viewModel.coins.first?.rank, coins.first?.marketCapRank)
        XCTAssertEqual(viewModel.coins.first?.currentPrice, marketData[coins.first!.id]?.currentPrice)
        XCTAssertEqual(viewModel.coins.first?.priceChange, marketData[coins.first!.id]?.priceChange)

        XCTAssertEqual(viewModel.coins.last?.id, coins.last?.id)
        XCTAssertEqual(viewModel.coins.last?.name, coins.last?.name)
        XCTAssertEqual(viewModel.coins.last?.imageURL, coins.last?.imageURL)
        XCTAssertEqual(viewModel.coins.last?.rank, coins.last?.marketCapRank)
        XCTAssertEqual(viewModel.coins.last?.currentPrice, marketData[coins.last!.id]?.currentPrice)
        XCTAssertEqual(viewModel.coins.last?.priceChange, marketData[coins.last!.id]?.priceChange)
    }

    func testFetchCoinsEmptyResult() async throws {
        let coins: [Coin] = []
        let marketData = MarketData.mock
        coinScannerService.getMarketDataForCoinsResult = .success(marketData)

        for coin in coins {
            let newCoin = CoinData()
            newCoin.id = coin.id
            newCoin.name = coin.name
            newCoin.imageURL = coin.imageURL
            newCoin.rank = coin.marketCapRank!
            newCoin.currentPrice = marketData[coin.id]!.currentPrice!
            newCoin.priceChange = marketData[coin.id]!.priceChange!
            swiftDataManager.fetchResult.append(newCoin)
        }

        await viewModel.fetchCoins()

        XCTAssertTrue(viewModel.coins.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testConstructCoin() async throws {
        let coin: Coin = .btc

        await viewModel.createCoin(coin)

        XCTAssertFalse(viewModel.coins.isEmpty)
        XCTAssertEqual(viewModel.coins.count, 1)

        XCTAssertEqual(viewModel.coins.first?.id, coin.id)
        XCTAssertEqual(viewModel.coins.first?.name, coin.name)
        XCTAssertEqual(viewModel.coins.first?.imageURL, coin.imageURL)
        XCTAssertNotNil(viewModel.coins.first?.imageData)
        XCTAssertEqual(viewModel.coins.first?.rank, coin.marketCapRank)
        XCTAssertEqual(viewModel.coins.first?.currentPrice, coin.currentPrice)
        XCTAssertEqual(viewModel.coins.first?.priceChange, coin.priceChangePercentage24H)

        XCTAssert(swiftDataManager.saveMethodCalled)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSetPriceAlert() async throws {
        let coin: Coin = .btc

        let newCoin = CoinData()
        newCoin.id = coin.id
        newCoin.name = coin.name
        newCoin.imageURL = coin.imageURL
        newCoin.rank = coin.marketCapRank!
        newCoin.currentPrice = coin.currentPrice!
        newCoin.priceChange = coin.priceChangePercentage24H!

        viewModel.coins.append(newCoin)

        await viewModel.setPriceAlert(for: newCoin, targetPrice: 30000)

        XCTAssertTrue(newCoin.isActive)
        XCTAssertEqual(newCoin.targetPrice, 30000)

        await viewModel.setPriceAlert(for: newCoin, targetPrice: nil)

        XCTAssertFalse(newCoin.isActive)
        XCTAssertNil(newCoin.targetPrice)
    }

    func testDeleteCoin() async throws {
        let coin = Coin.btc
        let marketData = MarketData.mock

        let newCoin = CoinData()
        newCoin.id = coin.id
        newCoin.name = coin.name
        newCoin.imageURL = coin.imageURL
        newCoin.currentPrice = marketData[coin.id]!.currentPrice!
        newCoin.priceChange = marketData[coin.id]!.priceChange!

        try swiftDataManager.save()

        XCTAssert(swiftDataManager.saveMethodCalled)

        await viewModel.deleteCoin(newCoin)

        XCTAssert(swiftDataManager.deleteMethodCalled)
        XCTAssertEqual(swiftDataManager.deletedModel as? CoinData, newCoin)

        XCTAssertNil(viewModel.errorMessage)
    }
}
