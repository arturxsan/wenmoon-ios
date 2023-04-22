//
//  AuthStateProvider.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 15.03.25.
//

import Combine
import FirebaseAuth

// MARK: - AuthState
enum AuthState: Equatable {
    case authenticated(_ account: Account?)
    case unauthenticated
}

// MARK: - AuthStateProvider
protocol AuthStateProvider {
    var authState: AuthState { get }
    var authStatePublisher: AnyPublisher<AuthState, Never> { get }
    var clientID: String? { get }
    var firebaseUser: User? { get }
    // Account
    func fetchAccount(authToken: String?) async throws -> Account?
    func deleteAccount() async throws -> Bool
    func setActiveAccount(deviceToken: String, localeIdentifier: String) async throws -> Bool
    func deleteActiveAccount(deviceToken: String) async throws -> Bool
    func toggleProAccount(_ isPro: Bool)
    // Firebase
    func fetchAuthToken() async throws -> String?
    func signIn(with credential: AuthCredential) async throws -> AuthDataResult
    func signOut() throws
}

// MARK: - DefaultAuthStateManager
final class DefaultAuthStateManager: AuthStateProvider, ObservableObject {
    private let provider: AuthStateProvider
    
    @Published private(set) var authState: AuthState
    var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
        
    }
    
    var clientID: String? { provider.clientID }
    var firebaseUser: User? { provider.firebaseUser }
    
    init(provider: AuthStateProvider = AuthStateStore.shared) {
        self.provider = provider
        self.authState = provider.authState
        
        provider.authStatePublisher
            .receive(on: RunLoop.main)
            .assign(to: &$authState)
    }
    
    // Account
    func fetchAccount(authToken: String?) async throws -> Account? {
        try await provider.fetchAccount(authToken: authToken)
    }
    
    func deleteAccount() async throws -> Bool {
        try await provider.deleteAccount()
    }
    
    func setActiveAccount(deviceToken: String, localeIdentifier: String) async throws -> Bool {
        try await provider.setActiveAccount(deviceToken: deviceToken, localeIdentifier: localeIdentifier)
    }
    
    func deleteActiveAccount(deviceToken: String) async throws -> Bool {
        try await provider.deleteActiveAccount(deviceToken: deviceToken)
    }
    
    func toggleProAccount(_ isPro: Bool) {
        provider.toggleProAccount(isPro)
    }
    
    // Firebase
    func fetchAuthToken() async throws -> String? {
        try await provider.fetchAuthToken()
    }
    
    func signIn(with credential: AuthCredential) async throws -> AuthDataResult {
        try await provider.signIn(with: credential)
    }
    
    func signOut() throws {
        try provider.signOut()
    }
}

// MARK: - AuthStateStore (Singleton)
final class AuthStateStore: AuthStateProvider {
    static let shared = AuthStateStore()
    private let firebaseAuthService = FirebaseAuthServiceImpl()
    private let accountService = AccountServiceImpl()
    
    @Published private(set) var authState: AuthState = .unauthenticated
    var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }
    
    var clientID: String? { firebaseAuthService.clientID }
    var firebaseUser: User? { firebaseAuthService.user }
    
    private init() {}
    
    // Account
    @MainActor
    func fetchAccount(authToken: String?) async throws -> Account? {
        let token: String
        if let authToken {
            token = authToken
        } else {
            guard let fetchedToken = try await fetchAuthToken() else { return nil }
            token = fetchedToken
        }
        let isAnonymous = firebaseAuthService.user?.isAnonymous ?? false
        let account = try await accountService.getAccount(authToken: token, isAnonymous: isAnonymous)
        authState = .authenticated(account)
        return account
    }
    
    func deleteAccount() async throws -> Bool {
        guard let authToken = try await fetchAuthToken() else {
            throw AuthError.failedToFetchFirebaseToken
        }
        let isAccountDeleted = try await accountService.deleteAccount(authToken: authToken)
        if isAccountDeleted {
            try await firebaseUser?.delete()
        }
        return isAccountDeleted
    }
    
    func setActiveAccount(deviceToken: String, localeIdentifier: String) async throws -> Bool {
        guard let authToken = try await fetchAuthToken() else {
            throw AuthError.failedToFetchFirebaseToken
        }
        let isActiveAccountSet = try await accountService.setActiveAccount(
            authToken: authToken,
            deviceToken: deviceToken,
            localeIdentifier: localeIdentifier
        )
        return isActiveAccountSet
    }
    
    func deleteActiveAccount(deviceToken: String) async throws -> Bool {
        guard let authToken = try await fetchAuthToken() else {
            throw AuthError.failedToFetchFirebaseToken
        }
        let isActiveAccountDeleted = try await accountService.deleteActiveAccount(authToken: authToken, deviceToken: deviceToken)
        return isActiveAccountDeleted
    }
    
    func toggleProAccount(_ isPro: Bool) {
        if case .authenticated(let account) = authState, let account {
            let updatedAccount = Account(from: account, isPro: isPro)
            authState = .authenticated(updatedAccount)
        }
    }
    
    // Firebase
    func fetchAuthToken() async throws -> String? {
        try await firebaseAuthService.getIDToken()
    }
    
    func signIn(with credential: AuthCredential) async throws -> AuthDataResult {
        try await firebaseAuthService.signIn(with: credential)
    }
    
    func signOut() throws {
        try firebaseAuthService.signOut()
        authState = .unauthenticated
    }
}
