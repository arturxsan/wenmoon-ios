//
//  PriceAlertServiceTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 21.10.24.
//

import XCTest
@testable import WenMoon

class PriceAlertServiceTests: XCTestCase {
    // MARK: - Properties
    var service: PriceAlertService!
    var httpClient: HTTPClientMock!
    
    let encoder = JSONEncoder()
    
    let deviceToken = "test-device-token"
    let authToken = "test-auth-token"
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        httpClient = HTTPClientMock()
        service = PriceAlertServiceImpl(httpClient: httpClient)
    }
    
    override func tearDown() {
        service = nil
        httpClient = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    // Get Price Alerts
    func testGetPriceAlerts_success() async throws {
        // Setup
        let response = PriceAlertFactoryMock.priceAlerts()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let priceAlerts = try await service.getPriceAlerts(authToken: authToken, deviceToken: deviceToken)
        
        // Assertions
        assertPriceAlertsEqual(priceAlerts, response)
    }
    
    func testGetPriceAlerts_emptyResponse() async throws {
        // Setup
        let response = [PriceAlert]()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let priceAlerts = try await service.getPriceAlerts(authToken: authToken, deviceToken: deviceToken)
        
        // Assertions
        XCTAssertTrue(priceAlerts.isEmpty)
    }
    
    func testGetPriceAlerts_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getPriceAlerts(authToken: self!.authToken, deviceToken: self!.deviceToken)
            },
            expectedError: error
        )
    }
    
    // Set Price Alert
    func testSetPriceAlert_success() async throws {
        // Setup
        let response = PriceAlertFactoryMock.priceAlert()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let priceAlert = try await service.createPriceAlert(
            PriceAlertFactoryMock.priceAlert(),
            authToken: authToken,
            deviceToken: deviceToken
        )
        
        // Assertions
        assertPriceAlertsEqual([priceAlert], [response])
    }
    
    func testSetPriceAlert_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.createPriceAlert(
                    PriceAlertFactoryMock.priceAlert(),
                    authToken: self!.authToken,
                    deviceToken: self!.deviceToken
                )
            },
            expectedError: error
        )
    }
    
    // Update Price Alert
    func testUpdatePriceAlert_success() async throws {
        // Setup
        let response = PriceAlertFactoryMock.priceAlert()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let priceAlert = try await service.updatePriceAlert(
            PriceAlertFactoryMock.priceAlert().id,
            isActive: false,
            authToken: authToken
        )
        
        // Assertions
        assertPriceAlertsEqual([priceAlert], [response])
    }
    
    func testUpdatePriceAlert_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.updatePriceAlert(
                    PriceAlertFactoryMock.priceAlert().id,
                    isActive: false,
                    authToken: self!.authToken
                )
            },
            expectedError: error
        )
    }
    
    // Delete Price Alert
    func testDeletePriceAlert_success() async throws {
        // Setup
        let response = PriceAlertFactoryMock.priceAlert()
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let priceAlert = try await service.deletePriceAlert(
            PriceAlertFactoryMock.priceAlert().id,
            authToken: authToken
        )
        
        // Assertions
        assertPriceAlertsEqual([priceAlert], [response])
    }
    
    func testDeletePriceAlert_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.deletePriceAlert(
                    PriceAlertFactoryMock.priceAlert().id,
                    authToken: self!.authToken
                )
            },
            expectedError: error
        )
    }
}
