//
//  WatchlistServiceTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 19.03.25.
//

import XCTest
@testable import WenMoon

class WatchlistServiceTests: XCTestCase {
    // MARK: - Properties
    var service: WatchlistService!
    var httpClient: HTTPClientMock!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        httpClient = HTTPClientMock()
        service = WatchlistServiceImpl(httpClient: httpClient)
    }
    
    override func tearDown() {
        service = nil
        httpClient = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testGetWatchlist_success() async throws {
        // Setup
        let response = Watchlist(coins: CoinFactoryMock.coins(), pinnedCoinIDs: [])
        httpClient.response = .success(try! JSONEncoder().encode(response))
        
        // Action
        let watchlist = try await service.getWatchlist(authToken: "")
        
        // Assertions
        assertCoinsEqual(watchlist.coins, response.coins)
        XCTAssertEqual(watchlist.pinnedCoinIDs, response.pinnedCoinIDs)
    }
    
    func testGetWatchlist_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getWatchlist(authToken: "")
            },
            expectedError: error
        )
    }
    
    func testSyncWatchlist_success() async throws {
        // Setup
        httpClient.response = .success(Data())
        
        // Action
        let isWatchlistSynced = try await service.syncWatchlist(Watchlist(), authToken: "")
        
        // Assertions
        XCTAssertTrue(isWatchlistSynced)
    }
    
    func testSyncWatchlist_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.syncWatchlist(Watchlist(), authToken: "")
            },
            expectedError: error
        )
    }
}
