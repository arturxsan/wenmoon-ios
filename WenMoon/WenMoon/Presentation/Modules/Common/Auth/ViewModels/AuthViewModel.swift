//
//  AuthViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 18.03.25.
//

import UIKit
import FirebaseAuth

final class AuthViewModel: BaseViewModel {
    // MARK: - Properties
    @Published private(set) var isAppleAuthInProgress = false
    @Published private(set) var isGoogleAuthInProgress = false
    @Published private(set) var isAnonymousAuthInProgress = false
    
    private let appleSignInService: AppleSignInService
    private let googleSignInService: GoogleSignInService
    private let anonymousSignInService: AnonymousSignInService
    
    #if DEBUG
    var shouldSkipSetActiveAccountInDebug = true
    var shouldSkipDeleteActiveAccountInDebug = true
    #endif
    
    // MARK: - Initializers
    convenience init() {
        self.init(
            appleSignInService: AppleSignInServiceImpl(),
            googleSignInService: GoogleSignInServiceImpl(),
            anonymousSignInService: AnonymousSignInServiceImpl()
        )
    }
    
    init(
        appleSignInService: AppleSignInService,
        googleSignInService: GoogleSignInService,
        anonymousSignInService: AnonymousSignInService,
        authStateProvider: AuthStateProvider? = nil,
        notificationProvider: NotificationProvider? = nil,
        swiftDataManager: SwiftDataManager? = nil,
        userDefaultsManager: UserDefaultsManager? = nil
    ) {
        self.googleSignInService = googleSignInService
        self.appleSignInService = appleSignInService
        self.anonymousSignInService = anonymousSignInService
        super.init(
            authStateProvider: authStateProvider,
            notificationProvider: notificationProvider,
            swiftDataManager: swiftDataManager,
            userDefaultsManager: userDefaultsManager
        )
    }
    
    // MARK: - Methods
    // Account
    @MainActor
    func fetchAccount(authToken: String? = nil) async {
        do {
            guard let account = try await authStateProvider.fetchAccount(authToken: authToken) else {
                return
            }
            try await loginPurchases(account.id)
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func deleteAccount(showLoading: Bool = true) async {
        if showLoading { isLoading = true }
        defer {
            if showLoading { isLoading = false }
        }
        
        do {
            try await deleteActiveAccount()
            try await authStateProvider.deleteAccount()
            purgeLocalStorage()
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func setActiveAccount() async -> Bool {
        #if DEBUG
        if shouldSkipSetActiveAccountInDebug {
            print("Skipping setActiveAccount in DEBUG mode")
            return true
        }
        #endif

        guard let deviceToken else {
            print("Device token is missing")
            return false
        }

        do {
            let isActiveAccountSet = try await authStateProvider.setActiveAccount(
                deviceToken: deviceToken,
                localeIdentifier: Locale.current.identifier
            )
            return isActiveAccountSet
        } catch {
            setError(error)
            return false
        }
    }
    
    @MainActor
    func signInWithApple(confirmReauthentication: @escaping () async -> Bool) async -> Bool {
        isAppleAuthInProgress = true
        defer { isAppleAuthInProgress = false }
        
        return await handleSignIn(
            provider: .apple,
            credentialProvider: { [weak self] in
                guard let self else { throw AuthError.unknownError }
                return try await appleSignInService.singIn()
            },
            confirmReauthentication: confirmReauthentication
        )
    }
    
    @MainActor
    func signInWithGoogle(confirmReauthentication: @escaping () async -> Bool) async -> Bool {
        isGoogleAuthInProgress = true
        defer { isGoogleAuthInProgress = false }
        
        return await handleSignIn(
            provider: .google,
            credentialProvider: { [weak self] in
                guard let self else { throw AuthError.unknownError }
                return try await getGoogleCredential()
            },
            confirmReauthentication: confirmReauthentication
        )
    }
    
    @MainActor
    func signInAnonymously() async {
        isAnonymousAuthInProgress = true
        defer { isAnonymousAuthInProgress = false }
        
        triggerImpactFeedback()
        
        do {
            let user = try await anonymousSignInService.signIn()
            let authToken = try await user.getIDToken()
            await fetchAccount(authToken: authToken)
            await setActiveAccount()
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await deleteActiveAccount()
            try authStateProvider.signOut()
            purgeLocalStorage()
        } catch {
            setError(error)
        }
    }
    
    // MARK: - Private
    @MainActor
    private func loginPurchases(_ accountID: String) async throws {
        let (customerInfo, _) = try await purchasesProvider.logIn(accountID)
        let isPro = customerInfo.entitlements.all["Pro"]?.isActive ?? false
        authStateProvider.toggleProAccount(isPro)
    }
    
    @MainActor
    private func deleteActiveAccount() async throws -> Bool {
        #if DEBUG
        if shouldSkipDeleteActiveAccountInDebug {
            print("Skipping deleteActiveAccount in DEBUG mode")
            return true
        }
        #endif

        guard let deviceToken else {
            print("Device token is missing")
            return false
        }

        let isActiveAccountDeleted = try await authStateProvider.deleteActiveAccount(deviceToken: deviceToken)
        return isActiveAccountDeleted
    }
    
    @MainActor
    private func handleSignIn(
        provider: AuthProvider,
        credentialProvider: @escaping () async throws -> AuthCredential,
        confirmReauthentication: (() async -> Bool)
    ) async -> Bool {
        triggerImpactFeedback()
        
        guard let credential = try? await credentialProvider() else { return false }
        
        do {
            if let firebaseUser, firebaseUser.isAnonymous {
                let linkResult = try await firebaseUser.link(with: credential)
                let authToken = try await linkResult.user.getIDToken()
                await fetchAccount(authToken: authToken)
                await setActiveAccount()
            } else {
                await signIn(with: credential)
            }
            return true
        } catch let error as NSError where error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
            let isConfirmed = await confirmReauthentication()
            guard isConfirmed else { return false }
            
            if provider == .apple {
                guard let newCredential = try? await credentialProvider() else { return false }
                await deleteAccount(showLoading: false)
                await signIn(with: newCredential)
            } else {
                await deleteAccount(showLoading: false)
                await signIn(with: credential)
            }
            
            return true
        } catch {
            setError(error)
            return false
        }
    }
    
    @MainActor
    private func signIn(with credential: AuthCredential) async {
        do {
            let result = try await authStateProvider.signIn(with: credential)
            let authToken = try await result.user.getIDToken()
            await fetchAccount(authToken: authToken)
            await setActiveAccount()
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    private func getGoogleCredential() async throws -> AuthCredential {
        guard let clientID = authStateProvider.clientID,
              let rootViewController = UIApplication.rootViewController else {
            throw AuthError.unknownError
        }
        
        googleSignInService.configure(clientID: clientID)
        let signInResult = try await googleSignInService.signIn(withPresenting: rootViewController)
        
        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw AuthError.failedToSignIn(provider: .google)
        }
        
        return googleSignInService.credential(
            withIDToken: idToken,
            accessToken: signInResult.user.accessToken.tokenString
        )
    }
}

// MARK: - AuthProvider
enum AuthProvider {
    case apple
    case google
    case anonymous
    
    var name: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .anonymous: return "Anonymous"
        }
    }
}
