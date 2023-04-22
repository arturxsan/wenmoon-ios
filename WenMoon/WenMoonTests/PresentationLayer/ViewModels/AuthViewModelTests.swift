//
//  AuthViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 19.03.25.
//

import XCTest
import FirebaseAuth
@testable import WenMoon

class AuthViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: AuthViewModel!
    
    var appleSignInService: AppleSignInServiceMock!
    var googleSignInService: GoogleSignInServiceMock!
    var anonymousSignInService: AnonymousSignInServiceMock!
    var authStateProvider: AuthStateProviderMock!
    var notificationProvider: NotificationProviderMock!
    var swiftDataManager: SwiftDataManagerMock!
    var userDefaultsManager: UserDefaultsManagerMock!
    
    let account = AccountFactoryMock.account()
    let deviceToken = "test-device-token"
    let authToken = "test-auth-token"
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        appleSignInService = AppleSignInServiceMock()
        googleSignInService = GoogleSignInServiceMock()
        anonymousSignInService = AnonymousSignInServiceMock()
        authStateProvider = AuthStateProviderMock()
        notificationProvider = NotificationProviderMock()
        swiftDataManager = SwiftDataManagerMock()
        userDefaultsManager = UserDefaultsManagerMock()
        
        viewModel = AuthViewModel(
            appleSignInService: appleSignInService,
            googleSignInService: googleSignInService,
            anonymousSignInService: anonymousSignInService,
            authStateProvider: authStateProvider,
            notificationProvider: notificationProvider,
            swiftDataManager: swiftDataManager,
            userDefaultsManager: userDefaultsManager
        )
    }
    
    override func tearDown() {
        viewModel = nil
        appleSignInService = nil
        googleSignInService = nil
        anonymousSignInService = nil
        authStateProvider = nil
        notificationProvider = nil
        swiftDataManager = nil
        userDefaultsManager = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Account Tests
    func testFetchAccount_success_withToken() async {
        // Setup
        authStateProvider.fetchAccountResult = .success(account)
        
        // Action
        await viewModel.fetchAccount(authToken: authToken)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.account, account)
    }
    
    func testFetchAccount_success_withoutToken() async {
        // Setup
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        authStateProvider.fetchAccountResult = .success(account)
        
        // Action
        await viewModel.fetchAccount()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.account, account)
    }
    
    func testFetchAccount_failure() async {
        // Setup
        let error: AuthError = .failedToFetchAccount
        authStateProvider.fetchAccountResult = .failure(error)
        
        // Action
        await viewModel.fetchAccount(authToken: authToken)
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertNil(viewModel.account)
    }
    
    // MARK: - Delete Account Tests
    func testDeleteAccount_success() async {
        // Setup
        notificationProvider.deviceToken = deviceToken
        authStateProvider.authState = .authenticated(account)
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        authStateProvider.deleteAccountResult = .success(true)
        authStateProvider.deleteActiveAccountResult = .success(true)
        viewModel.shouldSkipDeleteActiveAccountInDebug = false
        
        // Action
        await viewModel.deleteAccount()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.account)
        XCTAssertEqual(authStateProvider.authState, .unauthenticated)
        XCTAssertTrue(userDefaultsManager.removeObjectCalled)
    }
    
    func testDeleteAccount_failure() async {
        // Setup
        notificationProvider.deviceToken = deviceToken
        authStateProvider.authState = .authenticated(account)
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        authStateProvider.deleteActiveAccountResult = .success(true)
        viewModel.shouldSkipDeleteActiveAccountInDebug = false
        
        let error: AuthError = .failedToDeleteAccount
        authStateProvider.deleteAccountResult = .failure(error)
        
        // Action
        await viewModel.deleteAccount()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertNotNil(viewModel.account)
        XCTAssertEqual(viewModel.account, account)
    }
    
    // MARK: - Set Active Account Tests
    func testSetActiveAccount_success() async {
        // Setup
        notificationProvider.deviceToken = deviceToken
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        authStateProvider.setActiveAccountResult = .success(true)
        
        // Action
        let accountIsSet = await viewModel.setActiveAccount()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(accountIsSet)
    }
    
    func testSetActiveAccount_failure() async {
        // Setup
        notificationProvider.deviceToken = deviceToken
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        viewModel.shouldSkipSetActiveAccountInDebug = false
        
        let error: AuthError = .failedToSetActiveAccount
        authStateProvider.setActiveAccountResult = .failure(error)
        
        // Action
        let accountIsSet = await viewModel.setActiveAccount()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertFalse(accountIsSet)
    }
    
    // MARK: - Sign Out Tests
    func testSignOut_success() async {
        // Setup
        notificationProvider.deviceToken = deviceToken
        authStateProvider.authState = .authenticated(account)
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        authStateProvider.signOutResult = .success(())
        authStateProvider.deleteActiveAccountResult = .success(true)
        viewModel.shouldSkipDeleteActiveAccountInDebug = false
        
        // Action
        await viewModel.signOut()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.account)
        XCTAssertEqual(authStateProvider.authState, .unauthenticated)
        XCTAssertTrue(userDefaultsManager.removeObjectCalled)
    }
    
    func testSignOut_failure() async {
        // Setup
        authStateProvider.authState = .authenticated(account)
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        authStateProvider.deleteActiveAccountResult = .success(true)
        viewModel.shouldSkipDeleteActiveAccountInDebug = false
        
        let error: AuthError = .failedToSignOut
        authStateProvider.signOutResult = .failure(error)
        
        // Action
        await viewModel.signOut()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertNotNil(viewModel.account)
        XCTAssertEqual(viewModel.account, account)
        XCTAssertEqual(authStateProvider.authState, .authenticated(account))
    }
}
