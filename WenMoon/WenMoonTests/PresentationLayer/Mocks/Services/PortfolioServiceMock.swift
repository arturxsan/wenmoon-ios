//
//  PortfolioServiceMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 21.03.25.
//

import XCTest
@testable import WenMoon

class PortfolioServiceMock: PortfolioService {
    // MARK: - Properties
    var getPortfolioResult: Result<Portfolio, APIError>!
    var syncPortfolioResult: Result<Bool, APIError>!
    
    // MARK: - CoinScannerService
    func getPortfolio(authToken: String) async throws -> Portfolio {
        switch getPortfolioResult {
        case .success(let portfolio):
            return portfolio
        case .failure(let error):
            throw error
        case .none:
            XCTFail("getPortfolioResult not set")
            throw APIError.unknown
        }
    }
    
    func syncPortfolio(_ request: Portfolio, authToken: String) async throws -> Bool {
        switch syncPortfolioResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("syncPortfolioResult not set")
            return false
        }
    }
}
