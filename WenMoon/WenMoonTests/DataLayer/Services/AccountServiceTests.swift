//
//  AccountServiceTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 22.02.25.
//

import XCTest
@testable import WenMoon

class AccountServiceTests: XCTestCase {
    // MARK: - Properties
    var service: AccountService!
    var httpClient: HTTPClientMock!
    
    let authToken = "test-auth-token"
    let deviceToken = "test-device-token"
    let localeIdentifier = "en_US"
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        httpClient = HTTPClientMock()
        service = AccountServiceImpl(httpClient: httpClient)
    }
    
    override func tearDown() {
        service = nil
        httpClient = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testGetAccount_success() async throws {
        // Setup
        let response = AccountFactoryMock.account()
        httpClient.response = .success(try! JSONEncoder().encode(response))
        
        // Action
        let account = try await service.getAccount(authToken: authToken, isAnonymous: false)
        
        // Assertions
        XCTAssertEqual(account, response)
    }
    
    func testGetAccount_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                guard let self else { XCTFail(); return }
                try await service.getAccount(authToken: authToken, isAnonymous: false)
            },
            expectedError: error
        )
    }
    
    func testDeleteAccount_success() async throws {
        // Setup
        httpClient.response = .success(Data())
        
        // Action
        let accountIsDeleted = try await service.deleteAccount(authToken: authToken)
        
        // Assertions
        XCTAssertTrue(accountIsDeleted)
    }
    
    func testDeleteAccount_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                guard let self else { XCTFail(); return }
                try await service.deleteAccount(authToken: authToken)
            },
            expectedError: error
        )
    }
    
    func testSetActiveAccount_success() async throws {
        // Setup
        httpClient.response = .success(Data())
        
        // Action
        let accountIsDeleted = try await service.setActiveAccount(
            authToken: authToken,
            deviceToken: deviceToken,
            localeIdentifier: localeIdentifier
        )
        
        // Assertions
        XCTAssertTrue(accountIsDeleted)
    }
    
    func testSetActiveAccount_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                guard let self else { XCTFail(); return }
                try await service.setActiveAccount(
                    authToken: authToken,
                    deviceToken: deviceToken,
                    localeIdentifier: localeIdentifier
                )
            },
            expectedError: error
        )
    }
    
    func testDeleteActiveAccount_success() async throws {
        // Setup
        httpClient.response = .success(Data())
        
        // Action
        let accountIsDeleted = try await service.deleteActiveAccount(authToken: authToken, deviceToken: deviceToken)
        
        // Assertions
        XCTAssertTrue(accountIsDeleted)
    }
    
    func testDeleteActiveAccount_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                guard let self else { XCTFail(); return }
                try await service.deleteActiveAccount(authToken: authToken, deviceToken: deviceToken)
            },
            expectedError: error
        )
    }
}
