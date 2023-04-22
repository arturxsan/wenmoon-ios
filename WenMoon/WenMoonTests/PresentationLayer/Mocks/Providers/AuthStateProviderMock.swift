//
//  AuthStateProviderMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 19.03.25.
//

import Foundation
import Combine
import FirebaseAuth
import XCTest
@testable import WenMoon

class AuthStateProviderMock: AuthStateProvider {
    // MARK: - Properties
    @Published var authState: AuthState = .unauthenticated
    var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }
    var clientID: String? = "test-client-id"
    var firebaseUser: User? = nil
    
    var fetchAccountResult: Result<Account, Error>!
    var deleteAccountResult: Result<Bool, Error>!
    var setActiveAccountResult: Result<Bool, Error>!
    var deleteActiveAccountResult: Result<Bool, Error>!
    
    var fetchAuthTokenResult: Result<String, Error>!
    var fetchAuthDataResult: Result<AuthDataResult, Error>!
    var signOutResult: Result<Void, Error>!
    
    var isPro = false
    
    // MARK: - Methods
    // Account
    func fetchAccount(authToken: String?) async throws -> Account? {
        switch fetchAccountResult {
        case .success(let account):
            authState = .authenticated(account)
            return account
        case .failure(let error):
            throw error
        case .none:
            XCTFail("fetchAccountResult not set")
            return nil
        }
    }
    
    func deleteAccount() async throws -> Bool {
        switch deleteAccountResult {
        case .success(let result):
            authState = .unauthenticated
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("deleteAccountResult not set")
            return false
        }
    }
    
    func setActiveAccount(deviceToken: String, localeIdentifier: String) async throws -> Bool {
        switch setActiveAccountResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("setActiveAccountResult not set")
            return false
        }
    }
    
    func deleteActiveAccount(deviceToken: String) async throws -> Bool {
        switch deleteActiveAccountResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("deleteActiveAccountResult not set")
            return false
        }
    }
    
    func toggleProAccount(_ isPro: Bool) {
        self.isPro = isPro
    }
    
    // Firebase
    func fetchAuthToken() async throws -> String? {
        switch fetchAuthTokenResult {
        case .success(let token):
            return token
        case .failure(let error):
            throw error
        case .none:
            XCTFail("fetchAuthTokenResult not set")
            return nil
        }
    }
    
    func signIn(with credential: AuthCredential) async throws -> AuthDataResult {
        switch fetchAuthDataResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            XCTFail("fetchAuthDataResult not set")
            throw AuthError.unknownError
        }
    }
    
    func signOut() throws {
        switch signOutResult {
        case .success:
            authState = .unauthenticated
        case .failure(let error):
            throw error
        case .none:
            XCTFail("signOutResult not set")
        }
    }
}
