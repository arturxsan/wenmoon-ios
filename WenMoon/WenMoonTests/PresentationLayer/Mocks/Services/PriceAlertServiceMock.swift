//
//  PriceAlertServiceMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 21.10.24.
//

import XCTest
@testable import WenMoon

class PriceAlertServiceMock: PriceAlertService {
    // MARK: - Properties
    var getPriceAlertsResult: Result<[PriceAlert], APIError>!
    var createPriceAlertResult: Result<PriceAlert, APIError>!
    var updatePriceAlertResult: Result<PriceAlert, APIError>!
    var deletePriceAlertResult: Result<PriceAlert, APIError>!
    
    // MARK: - PriceAlertService
    func getPriceAlerts(authToken: String, deviceToken: String?) async throws -> [PriceAlert] {
        switch getPriceAlertsResult {
        case .success(let priceAlerts):
            return priceAlerts
        case .failure(let error):
            throw error
        case .none:
            XCTFail("getPriceAlertsResult not set")
            throw APIError.unknown
        }
    }
    
    func createPriceAlert(_ priceAlert: PriceAlert, authToken: String, deviceToken: String) async throws -> PriceAlert {
        switch createPriceAlertResult {
        case .success(let priceAlert):
            return priceAlert
        case .failure(let error):
            throw error
        case .none:
            XCTFail("createPriceAlertResult not set")
            throw APIError.unknown
        }
    }
    
    func updatePriceAlert(_ id: String, isActive: Bool, authToken: String) async throws -> PriceAlert {
        switch updatePriceAlertResult {
        case .success(let priceAlert):
            return priceAlert
        case .failure(let error):
            throw error
        case .none:
            XCTFail("updatePriceAlertResult not set")
            throw APIError.unknown
        }
    }
    
    func deletePriceAlert(_ id: String, authToken: String) async throws -> PriceAlert {
        switch deletePriceAlertResult {
        case .success(let priceAlert):
            return priceAlert
        case .failure(let error):
            throw error
        case .none:
            XCTFail("deletePriceAlertResult not set")
            throw APIError.unknown
        }
    }
}
