//
//  GlobalMarketDataService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 18.03.25.
//

import Foundation

protocol GlobalMarketDataService {
    func getFearAndGreedIndex() async throws -> FearAndGreedIndex
    func getCryptoGlobalMarketData() async throws -> CryptoGlobalMarketData
    func getGlobalMarketData() async throws -> GlobalMarketData
}

final class GlobalMarketDataServiceImpl: BaseBackendService, GlobalMarketDataService {
    // MARK: - GlobalMarketDataService
    func getFearAndGreedIndex() async throws -> FearAndGreedIndex {
        let request = HTTPRequest(method: .get, path: "fear-and-greed")
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode(FearAndGreedIndex.self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func getCryptoGlobalMarketData() async throws -> CryptoGlobalMarketData {
        let request = HTTPRequest(method: .get, path: "crypto-global-market-data")
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode(CryptoGlobalMarketData.self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func getGlobalMarketData() async throws -> GlobalMarketData {
        let request = HTTPRequest(method: .get, path: "global-market-data")
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode(GlobalMarketData.self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
}
