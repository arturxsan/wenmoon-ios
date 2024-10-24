//
//  CoinScannerService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation

protocol CoinScannerService {
    func getCoins(at page: Int) async throws -> [Coin]
    func searchCoins(by query: String) async throws -> [Coin]
    func getMarketData(for coinIDs: [String]) async throws -> [String: MarketData]
}

final class CoinScannerServiceImpl: BaseBackendService, CoinScannerService {
    // MARK: - CoinScannerService
    func getCoins(at page: Int) async throws -> [Coin] {
        let path = "coins"
        let data = try await httpClient.get(path: path, parameters: ["page": String(page)])
        do {
            let coins = try decoder.decode([Coin].self, from: data)
            print("Fetched coins: \(coins)")
            return coins
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func searchCoins(by query: String) async throws -> [Coin] {
        let path = "search"
        let data = try await httpClient.get(path: path, parameters: ["query": query])
        do {
            let searchedCoins = try decoder.decode([Coin].self, from: data)
            print("Searched coins: \(searchedCoins)")
            return searchedCoins
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func getMarketData(for coinIDs: [String]) async throws -> [String: MarketData] {
        let path = "market-data"
        let data = try await httpClient.get(path: path, parameters: ["ids": coinIDs.joined(separator: ",")])
        do {
            let marketData = try decoder.decode([String: MarketData].self, from: data)
            print("Market Data: \(marketData)")
            return marketData
        } catch {
            throw mapToAPIError(error)
        }
    }
}
