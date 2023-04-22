//
//  PurchasesProviderMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 30.03.25.
//

import XCTest
import RevenueCat
@testable import WenMoon

class PurchasesProviderMock: PurchasesProvider {
    // MARK: - Nested Types
    enum TestError: Error {
        case resultNotConfigured
    }
    
    // MARK: - Properties
    var customerInfoResult: Result<CustomerInfo, Error>!
    var logInResult: Result<(customerInfo: CustomerInfo, created: Bool), Error>!
    var logOutResult: Result<CustomerInfo, Error>!
    var offeringsResult: Result<Offerings, Error>!
    var purchaseResult: Result<PurchaseResultData, Error>!
    var restorePurchasesResult: Result<CustomerInfo, Error>!

    var logInCalled = false
    var logOutCalled = false
    var purchaseCalled = false
    var restoreCalled = false

    // MARK: - PurchasesProvider
    func customerInfo() async throws -> CustomerInfo {
        switch customerInfoResult {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        case .none:
            XCTFail("customerInfoResult not set")
            throw TestError.resultNotConfigured
        }
    }

    func logIn(_ appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        logInCalled = true
        switch logInResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("logInResult not set")
            throw TestError.resultNotConfigured
        }
    }

    func logOut() async throws -> CustomerInfo {
        logOutCalled = true
        switch logOutResult {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        case .none:
            XCTFail("logOutResult not set")
            throw TestError.resultNotConfigured
        }
    }

    func offerings() async throws -> Offerings {
        switch offeringsResult {
        case .success(let offerings):
            return offerings
        case .failure(let error):
            throw error
        case .none:
            XCTFail("offeringsResult not set")
            throw TestError.resultNotConfigured
        }
    }

    func purchase(package: Package) async throws -> PurchaseResultData {
        purchaseCalled = true
        switch purchaseResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("purchaseResult not set")
            throw TestError.resultNotConfigured
        }
    }

    func restorePurchases() async throws -> CustomerInfo {
        restoreCalled = true
        switch restorePurchasesResult {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        case .none:
            XCTFail("restorePurchasesResult not set")
            throw TestError.resultNotConfigured
        }
    }
}
