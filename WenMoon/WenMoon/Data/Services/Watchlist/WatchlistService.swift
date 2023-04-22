//
//  WatchlistService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 14.03.25.
//

import Foundation

protocol WatchlistService {
    func getWatchlist(authToken: String) async throws -> Watchlist
    func syncWatchlist(_ request: Watchlist, authToken: String) async throws -> Bool
}

final class WatchlistServiceImpl: BaseBackendService, WatchlistService {
    // MARK: - WatchlistService
    func getWatchlist(authToken: String) async throws -> Watchlist {
        let request = HTTPRequest(
            method: .get,
            path: "watchlist",
            headers: ["Authorization": "Bearer \(authToken)"]
        )
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode(Watchlist.self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func syncWatchlist(_ request: Watchlist, authToken: String) async throws -> Bool {
        do {
            let body = try encoder.encode(request)
            let request = HTTPRequest(
                method: .post,
                path: "watchlist",
                headers: ["Authorization": "Bearer \(authToken)"],
                body: body
            )
            try await httpClient.execute(request: request)
            return true
        } catch {
            throw mapToAPIError(error)
        }
    }
}
