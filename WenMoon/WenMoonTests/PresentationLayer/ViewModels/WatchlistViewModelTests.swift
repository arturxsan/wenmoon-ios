//
//  WatchlistViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 22.04.23.
//

import XCTest
@testable import WenMoon

class WatchlistViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: WatchlistViewModel!
    var priceAlertsViewModel: PriceAlertsViewModel!
    
    var watchlistService: WatchlistServiceMock!
    var coinScannerService: CoinScannerServiceMock!
    var priceAlertService: PriceAlertServiceMock!
    var authStateProvider: AuthStateProviderMock!
    var notificationProvider: NotificationProviderMock!
    var swiftDataManager: SwiftDataManagerMock!
    var userDefaultsManager: UserDefaultsManagerMock!
    
    let deviceToken = "test-device-token"
    let authToken = "test-auth-token"
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        priceAlertService = PriceAlertServiceMock()
        authStateProvider = AuthStateProviderMock()
        notificationProvider = NotificationProviderMock()
        
        priceAlertsViewModel = PriceAlertsViewModel(
            service: priceAlertService,
            authStateProvider: authStateProvider,
            notificationProvider: notificationProvider
        )
        
        watchlistService = WatchlistServiceMock()
        coinScannerService = CoinScannerServiceMock()
        swiftDataManager = SwiftDataManagerMock()
        userDefaultsManager = UserDefaultsManagerMock()
        
        viewModel = WatchlistViewModel(
            watchlistService: watchlistService,
            coinScannerService: coinScannerService,
            priceAlertsViewModel: priceAlertsViewModel,
            authStateProvider: authStateProvider,
            swiftDataManager: swiftDataManager,
            userDefaultsManager: userDefaultsManager
        )
    }
    
    override func tearDown() {
        viewModel = nil
        priceAlertsViewModel = nil
        watchlistService = nil
        coinScannerService = nil
        priceAlertService = nil
        authStateProvider = nil
        notificationProvider = nil
        swiftDataManager = nil
        userDefaultsManager = nil
        super.tearDown()
    }
    
    // MARK: - Fetch/Sync Watchlist Tests
    func testFetchWatchlist_remote_success() async {
        // Setup
        swiftDataManager.fetchResult = []
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let coins = CoinFactoryMock.coins()
        let watchlist = Watchlist(coins: coins, pinnedCoinIDs: [])
        watchlistService.getWatchlistResult = .success(watchlist)
        
        // Action
        await viewModel.fetchWatchlist()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        assertCoinsEqual(viewModel.coins, coins)
        XCTAssertTrue(swiftDataManager.insertMethodCalled)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
    }
    
    func testFetchWatchlist_remote_emptyResult() async {
        // Setup
        swiftDataManager.fetchResult = []
        let watchlist = Watchlist(coins: [], pinnedCoinIDs: [])
        watchlistService.getWatchlistResult = .success(watchlist)
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        // Action
        await viewModel.fetchWatchlist()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.coins.isEmpty)
    }
    
    func testFetchWatchlist_remote_failure() async {
        // Setup
        swiftDataManager.fetchResult = []
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let error = ErrorFactoryMock.apiError()
        watchlistService.getWatchlistResult = .failure(error)
        
        // Action
        await viewModel.fetchWatchlist()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertTrue(viewModel.coins.isEmpty)
    }
    
    func testFetchWatchlist_local() async {
        // Setup
        let coins = CoinFactoryMock.coins()
        swiftDataManager.fetchResult = coins
        
        // Action
        await viewModel.fetchWatchlist()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        assertCoinsEqual(viewModel.coins, coins)
        XCTAssertTrue(swiftDataManager.fetchMethodCalled)
    }
    
    func testFetchWatchlist_local_savedOrder() async {
        // Setup
        let coins = CoinFactoryMock.coins().shuffled()
        let savedOrder = coins.map(\.id)
        userDefaultsManager.getObjectReturnValue = [.coinsOrder: savedOrder]
        swiftDataManager.fetchResult = coins
        
        // Action
        await viewModel.fetchWatchlist()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        assertCoinsEqual(viewModel.coins, coins)
        XCTAssertEqual(viewModel.coins.map(\.id), savedOrder)
        XCTAssertTrue(swiftDataManager.fetchMethodCalled)
    }
    
    func testFetchWatchlist_local_failure() async {
        // Setup
        let error: SwiftDataError = .failedToFetchModels
        swiftDataManager.swiftDataError = error
        
        // Action
        await viewModel.fetchWatchlist()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertTrue(swiftDataManager.fetchMethodCalled)
    }
    
    func testSyncWatchlist_success() async {
        // Setup
        viewModel.coins = CoinFactoryMock.coins()
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        watchlistService.syncWatchlistResult = .success(true)
        
        // Action
        let isWatchlistSynced = await viewModel.syncWatchlist()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(isWatchlistSynced)
    }
    
    func testSyncWatchlist_tokenFailure() async {
        // Setup
        viewModel.coins = CoinFactoryMock.coins()
        
        let error: AuthError = .failedToFetchFirebaseToken
        authStateProvider.fetchAuthTokenResult = .failure(error)
        watchlistService.syncWatchlistResult = .success(true)
        
        // Action
        let isWatchlistSynced = await viewModel.syncWatchlist()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertFalse(isWatchlistSynced)
    }
    
    func testSyncWatchlist_failure() async {
        // Setup
        viewModel.coins = CoinFactoryMock.coins()
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let error = ErrorFactoryMock.apiError()
        watchlistService.syncWatchlistResult = .failure(error)
        
        // Action
        let isWatchlistSynced = await viewModel.syncWatchlist()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertFalse(isWatchlistSynced)
    }
    
    // MARK: - Save Coin/Order Tests
    func testSaveCoin_isPro_success() {
        // Setup
        let account = AccountFactoryMock.account(isPro: true)
        viewModel.account = account
        authStateProvider.authState = .authenticated(account)
        
        swiftDataManager.fetchResult = CoinFactoryMock.coins(count: 20)
        let coin = CoinFactoryMock.coin(id: "coin-21")
        
        // Action
        viewModel.saveCoin(coin)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.coins.count, 1)
        assertCoinsEqual(viewModel.coins, [coin])
        assertInsertAndSaveMethodsCalled()
    }
    
    func testSaveCoin_isNonPro_limitReached() {
        // Setup
        let account = AccountFactoryMock.account()
        viewModel.account = account
        authStateProvider.authState = .authenticated(account)
        
        swiftDataManager.fetchResult = CoinFactoryMock.coins(count: 20)
        
        // Action
        viewModel.saveCoin(CoinFactoryMock.coin(id: "coin-21"))
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.coins.isEmpty)
        XCTAssertFalse(swiftDataManager.insertMethodCalled)
        XCTAssertFalse(swiftDataManager.saveMethodCalled)
    }
    
    func testUnarchiveCoin() {
        // Setup
        let coin = CoinFactoryMock.coin(isArchived: true)
        swiftDataManager.fetchResult = [coin]
        
        // Action
        viewModel.saveCoin(coin)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.coins.count, 1)
        assertCoinsEqual(viewModel.coins, [coin])
        XCTAssertFalse(coin.isArchived)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
    }
    
    // MARK: - Delete/Archive Coin Tests
    func testDeleteCoin() {
        // Setup
        let coin = CoinFactoryMock.coin()
        viewModel.saveCoin(coin)
        
        // Action
        viewModel.deleteCoin(coin.id)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        assertDeleteAndSaveMethodsCalled()
    }
    
    func testArchiveCoin() {
        // Setup
        let coin = CoinFactoryMock.coin()
        viewModel.saveCoin(coin)
        
        let portfolio = PortfolioFactoryMock.portfolio(
            transactions: [
                PortfolioFactoryMock.transaction(coinID: coin.id)
            ]
        )
        
        swiftDataManager.fetchResult = [portfolio]
        
        // Action
        viewModel.deleteCoin(coin.id)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(coin.isArchived)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
    }
    
    // MARK: - Market Data Tests
    func testFetchMarketData_success() async {
        // Setup
        let marketData = MarketDataFactoryMock.marketData()
        coinScannerService.getMarketDataResult = .success(marketData)
        viewModel.coins.append(contentsOf: CoinFactoryMock.coins())
        
        // Action
        await viewModel.fetchMarketData()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        assertMarketDataEqual(for: viewModel.coins, with: marketData)
    }
    
    func testFetchMarketData_apiError() async {
        // Setup
        let error = ErrorFactoryMock.apiError()
        coinScannerService.getMarketDataResult = .failure(error)
        
        let coin = CoinFactoryMock.coin()
        viewModel.coins.append(coin)
        
        // Action
        await viewModel.fetchMarketData()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
    
    // MARK: - Price Alerts Tests
    func testFetchPriceAlerts_success() async {
        // Setup
        authStateProvider.fetchAuthTokenResult = .success("test-id-token")
        
        let coin = CoinFactoryMock.coin()
        viewModel.coins.append(coin)
        
        let priceAlerts = PriceAlertFactoryMock.priceAlerts()
        priceAlertService.getPriceAlertsResult = .success(priceAlerts)
        
        // Action
        await viewModel.fetchPriceAlerts()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        
        let priceAlert = priceAlerts.first(where: { $0.id == coin.id })!
        assertCoinHasActiveAlert(viewModel.coins.first!, priceAlert)
        
        // Test after alerts are cleared
        priceAlertService.getPriceAlertsResult = .success([])
        await viewModel.fetchPriceAlerts()
        
        assertCoinHasNoAlert(viewModel.coins.first!)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testDeactivatePriceAlert() {
        // Setup
        let coin = CoinFactoryMock.coin()
        let priceAlert = PriceAlertFactoryMock.priceAlert()
        coin.priceAlerts.append(priceAlert)
        viewModel.coins.append(coin)
        
        // Assertions after setting the price alert
        assertCoinHasActiveAlert(coin, priceAlert)
        
        // Action
        viewModel.deactivatePriceAlert(priceAlert.id)
        
        // Assertions after deleting the price alert
        assertCoinHasNoActiveAlert(coin)
    }
    
    // MARK: - Pin/Unpin Coin Tests
    func testPinCoin_isPro_success() {
        // Setup
        let account = AccountFactoryMock.account(isPro: true)
        viewModel.account = account
        authStateProvider.authState = .authenticated(account)
        
        let coin1 = CoinFactoryMock.coin(id: "coin-1", isPinned: true)
        let coin2 = CoinFactoryMock.coin(id: "coin-2", isPinned: true)
        let coin3 = CoinFactoryMock.coin(id: "coin-3", isPinned: true)
        let coin4 = CoinFactoryMock.coin(id: "coin-4", isPinned: false)
        viewModel.coins = [coin1, coin2, coin3, coin4]
        
        // Action
        viewModel.pinCoin(coin4)
        
        // Assertions
        XCTAssertTrue(coin4.isPinned)
        XCTAssertTrue(viewModel.pinnedCoins.contains(coin4))
    }
    
    func testPinCoin_isNonPro_limitReached() {
        // Setup
        let account = AccountFactoryMock.account()
        viewModel.account = account
        authStateProvider.authState = .authenticated(account)
        
        let coin1 = CoinFactoryMock.coin(id: "coin-1", isPinned: true)
        let coin2 = CoinFactoryMock.coin(id: "coin-2", isPinned: true)
        let coin3 = CoinFactoryMock.coin(id: "coin-3", isPinned: true)
        let coin4 = CoinFactoryMock.coin(id: "coin-4", isPinned: false)
        viewModel.coins = [coin1, coin2, coin3, coin4]
        
        // Action
        viewModel.pinCoin(coin4)
        
        // Assertions
        XCTAssertFalse(coin4.isPinned)
        XCTAssertFalse(viewModel.pinnedCoins.contains(coin4))
    }
    
    func testUnpinCoin() {
        // Setup
        let coin1 = CoinFactoryMock.coin(id: "coin-1", isPinned: true)
        let coin2 = CoinFactoryMock.coin(id: "coin-2", isPinned: true)
        viewModel.coins = [coin1, coin2]
        
        // Action
        viewModel.unpinCoin(coin1)
        
        // Assertions
        XCTAssertFalse(coin1.isPinned)
        XCTAssertTrue(coin2.isPinned)
        
        let pinnedCoins = viewModel.coins.filter { $0.isPinned }
        XCTAssertFalse(pinnedCoins.contains(where: { $0.id == coin1.id }))
    }
    
    // MARK: - Misc
    func testMovePinnedCoin() {
        // Setup
        let coin1 = CoinFactoryMock.coin(id: "coin-1", isPinned: true)
        let coin2 = CoinFactoryMock.coin(id: "coin-2", isPinned: true)
        let coin3 = CoinFactoryMock.coin(id: "coin-3", isPinned: true)
        viewModel.coins = [coin1, coin2, coin3]
        
        // Action
        let source = IndexSet(integer: 2)
        viewModel.movePinnedCoin(from: source, to: .zero)
        
        // Assertions
        let pinnedCoins = viewModel.coins.filter { $0.isPinned }
        XCTAssertEqual(pinnedCoins.map { $0.id }, ["coin-3", "coin-1", "coin-2"])
    }
    
    // MARK: - Private
    private func assertInsertAndSaveMethodsCalled() {
        XCTAssertTrue(swiftDataManager.insertMethodCalled)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
    }
    
    private func assertDeleteAndSaveMethodsCalled() {
        XCTAssertTrue(swiftDataManager.deleteMethodCalled)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
    }
}
