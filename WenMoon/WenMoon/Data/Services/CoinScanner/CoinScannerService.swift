//
//  CoinScannerService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation

protocol CoinScannerService {
    func getCoins(at page: Int) async throws -> [Coin]
    func getCoinDetails(_ coinID: String) async throws -> CoinDetails
    func getChartData(_ coinID: String, timeframe: String, currency: String) async throws -> [ChartData]
    func searchCoins(by query: String) async throws -> [Coin]
    func getMarketData(_ coinIDs: [String]) async throws -> [String: MarketData]
}

final class CoinScannerServiceImpl: BaseBackendService, CoinScannerService {
    // MARK: - CoinScannerService
    func getCoins(at page: Int) async throws -> [Coin] {
        let request = HTTPRequest(
            method: .get,
            path: "coins",
            parameters: ["page": String(page)]
        )
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode([Coin].self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func getCoinDetails(_ coinID: String) async throws -> CoinDetails {
        let request = HTTPRequest(
            method: .get,
            path: "coin-details",
            parameters: ["id": coinID]
        )
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode(CoinDetails.self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func getChartData(_ coinID: String, timeframe: String, currency: String) async throws -> [ChartData] {
        let parameters = [
            "id": coinID,
            "timeframe": timeframe,
            "currency": currency
        ]
        
        let request = HTTPRequest(
            method: .get,
            path: "chart-data",
            parameters: parameters
        )
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode([ChartData].self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func searchCoins(by query: String) async throws -> [Coin] {
        let request = HTTPRequest(
            method: .get,
            path: "search",
            parameters: ["query": query]
        )
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode([Coin].self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func getMarketData(_ coinIDs: [String]) async throws -> [String: MarketData] {
        let request = HTTPRequest(
            method: .get,
            path: "market-data",
            parameters: ["ids": coinIDs.joined(separator: ",")]
        )
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode([String: MarketData].self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
}
