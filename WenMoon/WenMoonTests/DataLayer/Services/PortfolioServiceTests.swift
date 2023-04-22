//
//  PortfolioServiceTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 21.03.25.
//

import XCTest
@testable import WenMoon

class PortfolioServiceTests: XCTestCase {
    // MARK: - Properties
    var service: PortfolioService!
    var httpClient: HTTPClientMock!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        httpClient = HTTPClientMock()
        service = PortfolioServiceImpl(httpClient: httpClient)
    }
    
    override func tearDown() {
        service = nil
        httpClient = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testGetPortfolio_success() async throws {
        // Setup
        let response = Portfolio(transactions: PortfolioFactoryMock.transactions())
        httpClient.response = .success(try! JSONEncoder().encode(response))
        
        // Action
        let portfolio = try await service.getPortfolio(authToken: "")
        
        // Assertions
        XCTAssertEqual(portfolio, portfolio)
    }
    
    func testGetPortfolio_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getPortfolio(authToken: "")
            },
            expectedError: error
        )
    }
    
    func testSyncPortfolio_success() async throws {
        // Setup
        httpClient.response = .success(Data())
        
        // Action
        let isPortfolioSynced = try await service.syncPortfolio(Portfolio(), authToken: "")
        
        // Assertions
        XCTAssertTrue(isPortfolioSynced)
    }
    
    func testSyncWatchlist_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.syncPortfolio(Portfolio(), authToken: "")
            },
            expectedError: error
        )
    }
}
