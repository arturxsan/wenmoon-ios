//
//  CoinScannerServiceTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 22.04.23.
//

import XCTest
@testable import WenMoon

class CoinScannerServiceTests: XCTestCase {
    // MARK: - Properties
    var service: CoinScannerService!
    var httpClient: HTTPClientMock!
    
    let encoder = JSONEncoder()
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        httpClient = HTTPClientMock()
        service = CoinScannerServiceImpl(httpClient: httpClient)
    }
    
    override func tearDown() {
        service = nil
        httpClient = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    // Get Coins
    func testGetCoinsAtPage_success() async throws {
        // Setup
        let response = CoinFactoryMock.coins()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let coins = try await service.getCoins(at: 1)
        
        // Assertions
        assertCoinsEqual(coins, response)
    }
    
    func testGetCoinsAtPage_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getCoins(at: 1)
            },
            expectedError: error
        )
    }
    
    func testGetCoinDetails_success() async throws {
        // Setup
        let response = CoinDetailsFactoryMock.coinDetails()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let coinDetails = try await service.getCoinDetails("coin-1")
        
        // Assertions
        XCTAssertEqual(coinDetails, response)
    }
    
    func testGetCoinDetails_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getCoinDetails("coin-1")
            },
            expectedError: error
        )
    }
    
    // Search Coins
    func testSearchCoinsByQuery_success() async throws {
        // Setup
        let response = CoinFactoryMock.coins()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let coins = try await service.searchCoins(by: "")
        
        // Assertions
        assertCoinsEqual(coins, response)
    }
    
    func testSearchCoinsByQuery_emptyResult() async throws {
        // Setup
        let response = [Coin]()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let coins = try await service.searchCoins(by: "")
        
        // Assertions
        XCTAssertTrue(coins.isEmpty)
    }
    
    func testSearchCoinsByQuery_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.searchCoins(by: "")
            },
            expectedError: error
        )
    }
    
    // Get Market Data
    func testGetMarketDataForCoins_success() async throws {
        // Setup
        let ids = CoinFactoryMock.coins().map { $0.id }
        let response = MarketDataFactoryMock.marketData()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let marketData = try await service.getMarketData(ids)
        
        // Assertions
        assertMarketDataEqual(marketData, response, for: ids)
    }
    
    func testGetMarketDataForCoins_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getMarketData([])
            },
            expectedError: error
        )
    }
    
    // Get Chart Data
    func testGetChartData_success() async throws {
        // Setup
        let response = ChartDataFactoryMock.chartData()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let chartData = try await service.getChartData("coin-1", timeframe: "1", currency: "usd")
        
        // Assertions
        assertChartDataEqual(chartData, response)
    }
    
    func testGetChartData_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getChartData("coin-1", timeframe: "1", currency: "usd")
            },
            expectedError: error
        )
    }
}
