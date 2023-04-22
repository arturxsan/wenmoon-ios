//
//  PriceAlertsViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 02.12.24.
//

import XCTest
@testable import WenMoon

class PriceAlertsViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: PriceAlertsViewModel!
    
    var service: PriceAlertServiceMock!
    var authStateProvider: AuthStateProviderMock!
    var notificationProvider: NotificationProviderMock!
    
    let deviceToken = "test-device-token"
    let authToken = "test-auth-token"
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        service = PriceAlertServiceMock()
        authStateProvider = AuthStateProviderMock()
        notificationProvider = NotificationProviderMock()
        
        viewModel = PriceAlertsViewModel(
            service: service,
            authStateProvider: authStateProvider,
            notificationProvider: notificationProvider
        )
    }
    
    override func tearDown() {
        viewModel = nil
        service = nil
        authStateProvider = nil
        notificationProvider = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Price Alerts Tests
    func testFetchPriceAlerts_success() async {
        // Setup
        let priceAlerts = PriceAlertFactoryMock.priceAlerts()
        service.getPriceAlertsResult = .success(priceAlerts)
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        // Action
        let receivedPriceAlerts = await viewModel.fetchPriceAlerts()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(receivedPriceAlerts, priceAlerts)
    }
    
    func testFetchPriceAlerts_emptyResult() async {
        // Setup
        service.getPriceAlertsResult = .success([])
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        // Action
        let receivedPriceAlerts = await viewModel.fetchPriceAlerts()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(receivedPriceAlerts.isEmpty)
    }
    
    func testFetchPriceAlerts_tokenFailure() async {
        // Setup
        let error: AuthError = .failedToFetchFirebaseToken
        authStateProvider.fetchAuthTokenResult = .failure(error)
        
        // Action
        await viewModel.fetchPriceAlerts()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
    
    func testFetchPriceAlerts_failure() async {
        // Setup
        let error = ErrorFactoryMock.apiError()
        service.getPriceAlertsResult = .failure(error)
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        // Action
        await viewModel.fetchPriceAlerts()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
    
    // MARK: - Create Price Alert Tests
    func testCreatePriceAlert_isPro_success() async {
        // Setup
        let account = AccountFactoryMock.account(isPro: true)
        viewModel.account = account
        authStateProvider.authState = .authenticated(account)
        
        notificationProvider.deviceToken = deviceToken
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let existingPriceAlerts = PriceAlertFactoryMock.priceAlerts(count: 5)
        service.getPriceAlertsResult = .success(existingPriceAlerts)
        
        let priceAlert = PriceAlertFactoryMock.priceAlert()
        service.createPriceAlertResult = .success(priceAlert)
        
        let coin = CoinFactoryMock.coin()
        
        // Action
        await viewModel.createPriceAlert(for: coin, targetPrice: 70_000)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        assertCoinHasActiveAlert(coin, priceAlert)
    }
    
    func testCreatePriceAlert_isNonPro_limitReached() async {
        // Setup
        let account = AccountFactoryMock.account()
        viewModel.account = account
        authStateProvider.authState = .authenticated(account)
        
        notificationProvider.deviceToken = deviceToken
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let existingPriceAlerts = PriceAlertFactoryMock.priceAlerts(count: 5)
        service.getPriceAlertsResult = .success(existingPriceAlerts)
        
        let priceAlert = PriceAlertFactoryMock.priceAlert()
        service.createPriceAlertResult = .success(priceAlert)
        
        let coin = CoinFactoryMock.coin()
        
        // Action
        await viewModel.createPriceAlert(for: coin, targetPrice: 70_000)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        assertCoinHasNoAlert(coin)
    }
    
    func testCreatePriceAlert_failure() async {
        // Setup
        notificationProvider.deviceToken = deviceToken
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let existingPriceAlerts = PriceAlertFactoryMock.priceAlerts(count: 2)
        service.getPriceAlertsResult = .success(existingPriceAlerts)
        
        let error = ErrorFactoryMock.apiError()
        service.createPriceAlertResult = .failure(error)
        
        let coin = CoinFactoryMock.coin()
        
        // Action
        await viewModel.createPriceAlert(for: coin, targetPrice: 70_000)
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        assertCoinHasNoAlert(coin)
    }
    
    // MARK: - Update Price Alert Tests
    func testUpdatePriceAlert_success() async {
        // Setup
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let coin = CoinFactoryMock.coin()
        
        let priceAlert = PriceAlertFactoryMock.priceAlert()
        coin.priceAlerts.append(priceAlert)
        
        var updatedPriceAlert = priceAlert
        updatedPriceAlert.isActive = false
        service.updatePriceAlertResult = .success(updatedPriceAlert)
        
        // Action
        await viewModel.updatePriceAlert(priceAlert.id, isActive: false, for: coin)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        assertCoinHasNoActiveAlert(coin)
    }
    
    func testUpdatePriceAlert_failure() async {
        // Setup
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let coin = CoinFactoryMock.coin()
        
        let priceAlert = PriceAlertFactoryMock.priceAlert()
        coin.priceAlerts.append(priceAlert)
        
        let error = ErrorFactoryMock.apiError()
        service.updatePriceAlertResult = .failure(error)
        
        // Action
        await viewModel.updatePriceAlert(priceAlert.id, isActive: false, for: coin)
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        assertCoinHasActiveAlert(coin, priceAlert)
    }
    
    // MARK: - Delete Price Alert Tests
    func testDeletePriceAlert_success() async {
        // Setup
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let coin = CoinFactoryMock.coin()
        
        let priceAlert = PriceAlertFactoryMock.priceAlert()
        coin.priceAlerts.append(priceAlert)
        
        service.deletePriceAlertResult = .success(priceAlert)
        
        // Action
        await viewModel.deletePriceAlert(priceAlert.id, for: coin)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        assertCoinHasNoAlert(coin)
    }
    
    func testDeletePriceAlert_apiError() async {
        // Setup
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let coin = CoinFactoryMock.coin()
        
        let priceAlert = PriceAlertFactoryMock.priceAlert()
        coin.priceAlerts.append(priceAlert)
        
        let error = ErrorFactoryMock.apiError()
        service.deletePriceAlertResult = .failure(error)
        
        // Action
        await viewModel.deletePriceAlert(priceAlert.id, for: coin)
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        assertCoinHasActiveAlert(coin, priceAlert)
    }
    
    // MARK: - Misc
    func testShouldDisableCreateButton() {
        // Setup
        let existingPriceAlert = PriceAlertFactoryMock.priceAlerts().first!
        let priceAlerts = [existingPriceAlert]

        // Assertions
        XCTAssertTrue(viewModel.shouldDisableCreateButton(
            priceAlerts: priceAlerts,
            targetPrice: nil,
            targetDirection: .above
        ))

        XCTAssertTrue(viewModel.shouldDisableCreateButton(
            priceAlerts: priceAlerts,
            targetPrice: .zero,
            targetDirection: .above
        ))

        XCTAssertTrue(viewModel.shouldDisableCreateButton(
            priceAlerts: priceAlerts,
            targetPrice: existingPriceAlert.targetPrice,
            targetDirection: existingPriceAlert.targetDirection
        ))

        XCTAssertFalse(viewModel.shouldDisableCreateButton(
            priceAlerts: priceAlerts,
            targetPrice: existingPriceAlert.targetPrice,
            targetDirection: existingPriceAlert.targetDirection == .above ? .below : .above
        ))

        XCTAssertFalse(viewModel.shouldDisableCreateButton(
            priceAlerts: priceAlerts,
            targetPrice: 150_000,
            targetDirection: .above
        ))
    }
    
    func testGetTargetDirection() {
        // Setup
        let currentPrice: Double = 60_000
        
        // Assertions
        XCTAssertEqual(viewModel.getTargetDirection(for: 65_000, currentPrice: currentPrice), .above)
        XCTAssertEqual(viewModel.getTargetDirection(for: 55_000, currentPrice: currentPrice), .below)
        XCTAssertEqual(viewModel.getTargetDirection(for: 60_000, currentPrice: currentPrice), .above)
    }
}
