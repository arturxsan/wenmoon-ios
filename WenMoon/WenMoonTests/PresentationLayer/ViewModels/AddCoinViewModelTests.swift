//
//  AddCoinViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 22.04.23.
//

import XCTest
@testable import WenMoon

@MainActor
class AddCoinViewModelTests: XCTestCase {

    // MARK: - Properties

    var viewModel: AddCoinViewModel!
    var service: CoinScannerServiceMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        service = CoinScannerServiceMock()
        viewModel = AddCoinViewModel(coinScannerService: service)
    }

    override func tearDown() {
        viewModel = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testFetchCoinsSuccess() async throws {
        let response = mockCoins
        service.getCoinsAtPageResult = .success(response)

        await viewModel.fetchCoins()

        let result = viewModel.coins
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, response.count)

        XCTAssertEqual(result.first?.id, response.first?.id)
        XCTAssertEqual(result.first?.name, response.first?.name)
        XCTAssertEqual(result.first?.imageURL, response.first?.imageURL)

        XCTAssertEqual(result.last?.id, response.last?.id)
        XCTAssertEqual(result.last?.name, response.last?.name)
        XCTAssertEqual(result.last?.imageURL, response.last?.imageURL)

        XCTAssertNil(viewModel.errorMessage)
    }

    func testFetchCoinsFailure() async throws {
        let apiError: APIError = .apiError(description: "Mocked server error")
        service.getCoinsAtPageResult = .failure(apiError)

        await viewModel.fetchCoins()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, apiError.errorDescription)
    }

    func testSearchCoinsByQuerySuccess() async throws {
        let searchResult = mockCoins
        service.searchCoinsByQueryResult = .success(searchResult)

        await viewModel.searchCoins(for: "bit")

        let result = viewModel.coins
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.count, searchResult.count)

        XCTAssertEqual(result.first?.id, searchResult.first?.id)
        XCTAssertEqual(result.first?.name, searchResult.first?.name)
        XCTAssertEqual(result.first?.imageURL, searchResult.first?.imageURL)
        XCTAssertEqual(result.first?.marketCapRank, searchResult.first?.marketCapRank)
        XCTAssertEqual(result.first?.currentPrice, searchResult.first?.currentPrice)
        XCTAssertEqual(result.first?.priceChangePercentage24H, searchResult.first?.priceChangePercentage24H)

        XCTAssertEqual(result.last?.id, searchResult.last?.id)
        XCTAssertEqual(result.last?.name, searchResult.last?.name)
        XCTAssertEqual(result.last?.imageURL, searchResult.last?.imageURL)
        XCTAssertEqual(result.last?.marketCapRank, searchResult.last?.marketCapRank)
        XCTAssertEqual(result.last?.currentPrice, searchResult.last?.currentPrice)
        XCTAssertEqual(result.last?.priceChangePercentage24H, searchResult.last?.priceChangePercentage24H)

        XCTAssertNil(viewModel.errorMessage)
    }

    func testSearchCoinsByQueryEmptyResult() async throws {
        let response = [Coin]()
        service.searchCoinsByQueryResult = .success(response)

        await viewModel.searchCoins(for: "sdfghjkl")

        XCTAssertTrue(viewModel.coins.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
}
