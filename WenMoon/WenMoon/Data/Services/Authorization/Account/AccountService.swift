//
//  UserAuthorizationService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 21.02.25.
//

import Foundation

protocol AccountService {
    func getAccount(authToken: String, isAnonymous: Bool) async throws -> Account
    func deleteAccount(authToken: String) async throws -> Bool
    func setActiveAccount(authToken: String, deviceToken: String, localeIdentifier: String) async throws -> Bool
    func deleteActiveAccount(authToken: String, deviceToken: String) async throws -> Bool
}

final class AccountServiceImpl: BaseBackendService, AccountService {
    // MARK: - AccountService
    func getAccount(authToken: String, isAnonymous: Bool) async throws -> Account {
        let request = HTTPRequest(
            method: .get,
            path: "account",
            parameters: ["is_anonymous": String(isAnonymous)],
            headers: ["Authorization": "Bearer \(authToken)"]
        )
        
        do {
            let data = try await httpClient.execute(request: request)
            return try decoder.decode(Account.self, from: data)
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func deleteAccount(authToken: String) async throws -> Bool {
        let request = HTTPRequest(
            method: .delete,
            path: "account",
            headers: ["Authorization": "Bearer \(authToken)"]
        )
        
        do {
            try await httpClient.execute(request: request)
            return true
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func setActiveAccount(authToken: String, deviceToken: String, localeIdentifier: String) async throws -> Bool {
        let headers = [
            "Authorization": "Bearer \(authToken)",
            "X-Device-ID": deviceToken,
            "X-Locale": localeIdentifier
        ]
        
        let request = HTTPRequest(
            method: .post,
            path: "active-account",
            headers: headers
        )
        
        do {
            try await httpClient.execute(request: request)
            return true
        } catch {
            throw mapToAPIError(error)
        }
    }
    
    func deleteActiveAccount(authToken: String, deviceToken: String) async throws -> Bool {
        let headers = [
            "Authorization": "Bearer \(authToken)",
            "X-Device-ID": deviceToken
        ]
        
        let request = HTTPRequest(
            method: .delete,
            path: "active-account",
            headers: headers
        )
        
        do {
            try await httpClient.execute(request: request)
            return true
        } catch {
            throw mapToAPIError(error)
        }
    }
}
