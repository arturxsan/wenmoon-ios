//
//  PortfolioService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 20.03.25.
//

import Foundation

protocol PortfolioService {
    func getPortfolio(authToken: String) async throws -> Portfolio
    func syncPortfolio(_ request: Portfolio, authToken: String) async throws -> Bool
}

final class PortfolioServiceImpl: BaseBackendService, PortfolioService {
    // MARK: - PortfolioService
    func getPortfolio(authToken: String) async throws -> Portfolio {
        let request = HTTPRequest(
            method: .get,
            path: "portfolio",
            headers: ["Authorization": "Bearer \(authToken)"]
        )
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode(Portfolio.self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func syncPortfolio(_ request: Portfolio, authToken: String) async throws -> Bool {
        do {
            let body = try encoder.encode(request)
            let request = HTTPRequest(
                method: .post,
                path: "portfolio",
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
