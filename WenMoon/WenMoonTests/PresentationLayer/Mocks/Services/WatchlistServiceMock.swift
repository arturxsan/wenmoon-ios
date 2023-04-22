//
//  WatchlistServiceMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 19.03.25.
//

import XCTest
@testable import WenMoon

class WatchlistServiceMock: WatchlistService {
    // MARK: - Properties
    var getWatchlistResult: Result<Watchlist, APIError>!
    var syncWatchlistResult: Result<Bool, APIError>!
    
    // MARK: - CoinScannerService
    func getWatchlist(authToken: String) async throws -> Watchlist {
        switch getWatchlistResult {
        case .success(let watchlist):
            return watchlist
        case .failure(let error):
            throw error
        case .none:
            XCTFail("getWatchlistResult not set")
            throw APIError.unknown
        }
    }
    
    func syncWatchlist(_ request: Watchlist, authToken: String) async throws -> Bool {
        switch syncWatchlistResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("syncWatchlistResult not set")
            return false
        }
    }
}
