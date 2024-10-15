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

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        httpClient = HTTPClientMock()
        service = CoinScannerServiceImpl(httpClient: httpClient, baseURL: URL(string: "https://example.com/")!)
    }

    override func tearDown() {
        service = nil
        httpClient = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testGetCoinsSuccess() async throws {
        let response = mockCoins
        httpClient.getResponse = .success(try! httpClient.encoder.encode(response))

        let result = try await service.getCoins(at: 1)
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, response.count)

        XCTAssertEqual(result.first?.id, response.first?.id)
        XCTAssertEqual(result.first?.name, response.first?.name)
        XCTAssertEqual(result.first?.imageURL, response.first?.imageURL)

        XCTAssertEqual(result.last?.id, response.last?.id)
        XCTAssertEqual(result.last?.name, response.last?.name)
        XCTAssertEqual(result.last?.imageURL, response.last?.imageURL)
    }

    func testGetCoinsFailure() async throws {
        let apiError: APIError = .apiError(description: "Mocked API error description")
        httpClient.getResponse = .failure(apiError)

        do {
            _ = try await service.getCoins(at: 1)
            XCTFail("Expected failure but got success")
        } catch let error as APIError {
            XCTAssertEqual(error, apiError)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSearchCoinsByQuerySuccess() async throws {
        let response = mockCoins
        httpClient.getResponse = .success(try! httpClient.encoder.encode(response))

        let result = try await service.searchCoins(by: "bit")
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, response.count)

        XCTAssertEqual(result.first?.id, response.first?.id)
        XCTAssertEqual(result.first?.name, response.first?.name)
        XCTAssertEqual(result.first?.imageURL, response.first?.imageURL)

        XCTAssertEqual(result.last?.id, response.last?.id)
        XCTAssertEqual(result.last?.name, response.last?.name)
        XCTAssertEqual(result.last?.imageURL, response.last?.imageURL)
    }

    func testSearchCoinsByQueryEmptyResult() async throws {
        let response = [Coin]()
        httpClient.getResponse = .success(try! httpClient.encoder.encode(response))

        let coins = try await service.searchCoins(by: "sdfghjkl")
        XCTAssertTrue(coins.isEmpty)
    }

    func testGetMarketDataForCoins() async throws {
        let coinIDs = [Coin.btc.id, Coin.eth.id]
        let response = MarketData.mock
        httpClient.getResponse = .success(try! httpClient.encoder.encode(response))

        let result = try await service.getMarketData(for: coinIDs)

        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, response.count)

        XCTAssertEqual(result[coinIDs.first!]?.currentPrice, response[coinIDs.first!]?.currentPrice)
        XCTAssertEqual(result[coinIDs.first!]?.priceChange, response[coinIDs.first!]?.priceChange)

        XCTAssertEqual(result[coinIDs.last!]?.currentPrice, response[coinIDs.last!]?.currentPrice)
        XCTAssertEqual(result[coinIDs.last!]?.priceChange, response[coinIDs.last!]?.priceChange)
    }
}
