//
//  PriceAlertService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 23.05.23.
//

import Foundation

protocol PriceAlertService {
    func getPriceAlerts(authToken: String, deviceToken: String?) async throws -> [PriceAlert]
    func createPriceAlert(_ priceAlert: PriceAlert, authToken: String, deviceToken: String) async throws -> PriceAlert
    func updatePriceAlert(_ id: String, isActive: Bool, authToken: String) async throws -> PriceAlert
    func deletePriceAlert(_ id: String, authToken: String) async throws -> PriceAlert
}

final class PriceAlertServiceImpl: BaseBackendService, PriceAlertService {
    // MARK: - PriceAlertService
    func getPriceAlerts(authToken: String, deviceToken: String?) async throws -> [PriceAlert] {
        var headers = ["Authorization": "Bearer \(authToken)"]
        if let deviceToken { headers["X-Device-ID"] = deviceToken }
        
        let request = HTTPRequest(
            method: .get,
            path: "price-alerts",
            headers: headers
        )
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode([PriceAlert].self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func createPriceAlert(_ priceAlert: PriceAlert, authToken: String, deviceToken: String) async throws -> PriceAlert {
        let headers = [
            "Authorization": "Bearer \(authToken)",
            "X-Device-ID": deviceToken
        ]
        
        do {
            let body = try encoder.encode(priceAlert)
            let request = HTTPRequest(
                method: .post,
                path: "price-alerts",
                headers: headers,
                body: body
            )
            let data = try await httpClient.execute(request: request)
            return try decoder.decode(PriceAlert.self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func updatePriceAlert(_ id: String, isActive: Bool, authToken: String) async throws -> PriceAlert {
        do {
            let body = try encoder.encode(PriceAlertStateRequest(isActive: isActive))
            let request = HTTPRequest(
                method: .put,
                path: "price-alerts/\(id)/state",
                headers: ["Authorization": "Bearer \(authToken)"],
                body: body
            )
            let data = try await httpClient.execute(request: request)
            return try decoder.decode(PriceAlert.self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func deletePriceAlert(_ id: String, authToken: String) async throws -> PriceAlert {
        let request = HTTPRequest(
            method: .delete,
            path: "price-alerts/\(id)",
            headers: ["Authorization": "Bearer \(authToken)"]
        )
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode(PriceAlert.self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
}
