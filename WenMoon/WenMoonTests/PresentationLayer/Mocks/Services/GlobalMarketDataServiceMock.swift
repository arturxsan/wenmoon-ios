//
//  GlobalMarketDataServiceMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 19.03.25.
//

import XCTest
@testable import WenMoon

class GlobalMarketDataServiceMock: GlobalMarketDataService {
    // MARK: - Properties
    var getFearAndGreedIndexResult: Result<FearAndGreedIndex, APIError>!
    var getCryptoGlobalMarketDataResult: Result<CryptoGlobalMarketData, APIError>!
    var getGlobalMarketDataResult: Result<GlobalMarketData, APIError>!
    
    // MARK: - GlobalMarketDataService
    func getFearAndGreedIndex() async throws -> FearAndGreedIndex {
        switch getFearAndGreedIndexResult {
        case .success(let index):
            return index
        case .failure(let error):
            throw error
        case .none:
            XCTFail("getFearAndGreedIndexResult not set")
            throw APIError.unknown
        }
    }
    
    func getCryptoGlobalMarketData() async throws -> CryptoGlobalMarketData {
        switch getCryptoGlobalMarketDataResult {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        case .none:
            XCTFail("getCryptoGlobalMarketDataResult not set")
            throw APIError.unknown
        }
    }
    
    func getGlobalMarketData() async throws -> GlobalMarketData {
        switch getGlobalMarketDataResult {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        case .none:
            XCTFail("getGlobalMarketDataResult not set")
            throw APIError.unknown
        }
    }
}
