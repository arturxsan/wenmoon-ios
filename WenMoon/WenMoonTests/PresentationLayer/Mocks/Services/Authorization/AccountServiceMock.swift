//
//  AccountServiceMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 22.02.25.
//

import XCTest
@testable import WenMoon

class AccountServiceMock: AccountService {
    var getAccountResult: Result<Account, AuthError>!
    var deleteAccountResult: Result<Bool, AuthError>!
    var setActiveAccountResult: Result<Bool, AuthError>!
    var deleteActiveAccountResult: Result<Bool, AuthError>!
    
    func getAccount(authToken: String, isAnonymous: Bool) async throws -> Account {
        switch getAccountResult {
        case .success(let account):
            return account
        case .failure(let error):
            throw error
        case .none:
            XCTFail("getAccountResult not set")
            throw AuthError.failedToFetchAccount
        }
    }
    
    func deleteAccount(authToken: String) async throws -> Bool {
        switch deleteAccountResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("deleteAccountResult not set")
            throw AuthError.failedToDeleteAccount
        }
    }
    
    func setActiveAccount(authToken: String, deviceToken: String, localeIdentifier: String) async throws -> Bool {
        switch setActiveAccountResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("setActiveAccountResult not set")
            throw AuthError.failedToSetActiveAccount
        }
    }
    
    func deleteActiveAccount(authToken: String, deviceToken: String) async throws -> Bool {
        switch deleteActiveAccountResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("deleteActiveAccountResult not set")
            throw AuthError.failedToDeleteActiveAccount
        }
    }
}
