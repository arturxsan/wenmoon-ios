//
//  PortfolioViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 11.01.25.
//

import XCTest
@testable import WenMoon

final class PortfolioViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: PortfolioViewModel!
    
    var portfolioService: PortfolioServiceMock!
    var coinScannerService: CoinScannerServiceMock!
    var authStateProvider: AuthStateProviderMock!
    var swiftDataManager: SwiftDataManagerMock!
    
    let authToken = "test-auth-token"
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        portfolioService = PortfolioServiceMock()
        coinScannerService = CoinScannerServiceMock()
        authStateProvider = AuthStateProviderMock()
        swiftDataManager = SwiftDataManagerMock()
        
        viewModel = PortfolioViewModel(
            portfolioService: portfolioService,
            coinScannerService: coinScannerService,
            authStateProvider: authStateProvider,
            swiftDataManager: swiftDataManager
        )
    }
    
    override func tearDown() {
        viewModel = nil
        portfolioService = nil
        coinScannerService = nil
        authStateProvider = nil
        swiftDataManager = nil
        super.tearDown()
    }
    
    // MARK: - Fetch/Sync Portfolio Tests
    func testFetchPortfolio_remote_success() async {
        // Setup
        swiftDataManager.fetchResult = []
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let portfolio = Portfolio()
        portfolioService.getPortfolioResult = .success(portfolio)
        
        // Action
        await viewModel.fetchPortfolio()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.portfolio, portfolio)
        XCTAssertTrue(swiftDataManager.insertMethodCalled)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
    }
    
    func testFetchPortfolio_remote_emptyResult() async {
        // Setup
        swiftDataManager.fetchResult = []
        let portfolio = PortfolioFactoryMock.portfolio(transactions: [])
        portfolioService.getPortfolioResult = .success(portfolio)
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        // Action
        await viewModel.fetchPortfolio()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.portfolio.transactions.isEmpty)
    }
    
    func testFetchPortfolio_remote_failure() async {
        // Setup
        swiftDataManager.fetchResult = []
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let error = ErrorFactoryMock.apiError()
        portfolioService.getPortfolioResult = .failure(error)
        
        // Action
        await viewModel.fetchPortfolio()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertNil(viewModel.portfolio)
    }
    
    func testFetchPortfolio_local() async {
        // Setup
        coinScannerService.getCoinDetailsResult = .success(CoinDetailsFactoryMock.coinDetails())
        let portfolio = PortfolioFactoryMock.portfolio()
        swiftDataManager.fetchResult = [portfolio]
        
        // Action
        await viewModel.fetchPortfolio()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.portfolio, portfolio)
        XCTAssertTrue(swiftDataManager.fetchMethodCalled)
    }
    
    func testFetchPortfolio_local_failure() async {
        // Setup
        let error: SwiftDataError = .failedToFetchModels
        swiftDataManager.swiftDataError = error
        
        // Action
        await viewModel.fetchPortfolio()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertTrue(swiftDataManager.fetchMethodCalled)
    }
    
    func testSyncPortfolio_success() async {
        // Setup
        viewModel.portfolio = PortfolioFactoryMock.portfolio()
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        portfolioService.syncPortfolioResult = .success(true)
        
        // Action
        let isPortfolioSynced = await viewModel.syncPortfolio()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(isPortfolioSynced)
    }
    
    func testSyncPortfolio_tokenFailure() async {
        // Setup
        viewModel.portfolio = PortfolioFactoryMock.portfolio()
        
        let error: AuthError = .failedToFetchFirebaseToken
        authStateProvider.fetchAuthTokenResult = .failure(error)
        portfolioService.syncPortfolioResult = .success(true)
        
        // Action
        let isPortfolioSynced = await viewModel.syncPortfolio()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertFalse(isPortfolioSynced)
    }
    
    func testSyncPortfolio_failure() async {
        // Setup
        viewModel.portfolio = PortfolioFactoryMock.portfolio()
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        
        let error = ErrorFactoryMock.apiError()
        portfolioService.syncPortfolioResult = .failure(error)
        
        // Action
        let isPortfolioSynced = await viewModel.syncPortfolio()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertFalse(isPortfolioSynced)
    }
    
    // MARK: - Add Transaction Tests
    func testAddTransaction_isPro_newCoin() async {
        // Setup
        let account = AccountFactoryMock.account(isPro: true)
        viewModel.account = account
        authStateProvider.authState = .authenticated(account)
        
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        portfolioService.syncPortfolioResult = .success(true)
        
        let coin1 = CoinFactoryMock.coin(id: "coin-1")
        let coin2 = CoinFactoryMock.coin(id: "coin-2")
        let coin3 = CoinFactoryMock.coin(id: "coin-3")
        swiftDataManager.fetchResult = [coin1, coin2, coin3]
        
        let existingTransactions = [
            PortfolioFactoryMock.transactions(coinID: coin1.id, count: 5),
            PortfolioFactoryMock.transactions(coinID: coin2.id, count: 5),
            PortfolioFactoryMock.transactions(coinID: coin3.id, count: 5)
        ].flatMap { $0 }
        viewModel.portfolio = PortfolioFactoryMock.portfolio(transactions: existingTransactions)
        
        let coin4 = CoinFactoryMock.coin(id: "coin-4")
        coinScannerService.getCoinDetailsResult = .success(CoinDetailsFactoryMock.coinDetails(id: coin4.id))
        
        let newTransaction = PortfolioFactoryMock.transaction(coinID: coin4.id)
        swiftDataManager.insertedModel = coin4
        
        // Action
        await viewModel.addTransaction(newTransaction, coin4)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        let transactions = viewModel.portfolio.transactions
        XCTAssertEqual(transactions.count, 16)
        XCTAssertTrue(transactions.contains(newTransaction))
        XCTAssertTrue(swiftDataManager.insertMethodCalled)
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
    }
    
    func testAddTransaction_isPro_existingCoin() async {
        // Setup
        let account = AccountFactoryMock.account(isPro: true)
        viewModel.account = account
        authStateProvider.authState = .authenticated(account)
        
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        portfolioService.syncPortfolioResult = .success(true)
        
        let coin1 = CoinFactoryMock.coin(id: "coin-1")
        let coin2 = CoinFactoryMock.coin(id: "coin-2")
        let coin3 = CoinFactoryMock.coin(id: "coin-3")
        
        let existingTransactions = [
            PortfolioFactoryMock.transactions(coinID: coin1.id, count: 5),
            PortfolioFactoryMock.transactions(coinID: coin2.id, count: 5),
            PortfolioFactoryMock.transactions(coinID: coin3.id, count: 5)
        ].flatMap { $0 }
        viewModel.portfolio = PortfolioFactoryMock.portfolio(transactions: existingTransactions)
        
        let coin4 = CoinFactoryMock.coin(id: "coin-4")
        let newTransaction = PortfolioFactoryMock.transaction(coinID: coin4.id)
        swiftDataManager.fetchResult = [coin1, coin2, coin3, coin4]
        
        // Action
        await viewModel.addTransaction(newTransaction, coin4)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        let transactions = viewModel.portfolio.transactions
        XCTAssertEqual(transactions.count, 16)
        XCTAssertTrue(transactions.contains(newTransaction))
        XCTAssertTrue(swiftDataManager.saveMethodCalled)
    }
    
    func testAddTransaction_isNonPro_limitReached() async {
        // Setup
        let account = AccountFactoryMock.account()
        viewModel.account = account
        authStateProvider.authState = .authenticated(account)
        
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        portfolioService.syncPortfolioResult = .success(true)
        
        let coin1 = CoinFactoryMock.coin(id: "coin-1")
        let coin2 = CoinFactoryMock.coin(id: "coin-2")
        let coin3 = CoinFactoryMock.coin(id: "coin-3")
        swiftDataManager.fetchResult = [coin1, coin2, coin3]
        
        let existingTransactions = [
            PortfolioFactoryMock.transactions(coinID: coin1.id, count: 5),
            PortfolioFactoryMock.transactions(coinID: coin2.id, count: 5),
            PortfolioFactoryMock.transactions(coinID: coin3.id, count: 5)
        ].flatMap { $0 }
        viewModel.portfolio = PortfolioFactoryMock.portfolio(transactions: existingTransactions)
        
        let coin4 = CoinFactoryMock.coin(id: "coin-4")
        coinScannerService.getCoinDetailsResult = .success(CoinDetailsFactoryMock.coinDetails(id: coin4.id))
        
        let newTransaction = PortfolioFactoryMock.transaction(coinID: coin4.id)
        swiftDataManager.insertedModel = coin4
        
        // Action
        await viewModel.addTransaction(newTransaction, coin4)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        let transactions = viewModel.portfolio.transactions
        XCTAssertEqual(transactions.count, 15)
        XCTAssertFalse(transactions.contains(newTransaction))
        XCTAssertFalse(swiftDataManager.insertMethodCalled)
        XCTAssertFalse(swiftDataManager.saveMethodCalled)
    }
    
    // MARK: - Delete Transaction Tests
    func testDeleteTransaction() async {
        // Setup
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        portfolioService.syncPortfolioResult = .success(true)
        
        let transactionID = UUID().uuidString
        let transaction1 = PortfolioFactoryMock.transaction(id: transactionID, coinID: "coin-1")
        let transaction2 = PortfolioFactoryMock.transaction(coinID: "coin-2")
        viewModel.portfolio = PortfolioFactoryMock.portfolio(transactions: [transaction1, transaction2])
        swiftDataManager.fetchResult = [
            CoinFactoryMock.coin(id: "coin-1"),
            CoinFactoryMock.coin(id: "coin-2")
        ]
        
        // Action
        await viewModel.deleteTransaction(transactionID)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.portfolio.transactions.count, 1)
        XCTAssertEqual(viewModel.portfolio.transactions.first, transaction2)
        
        func testDeleteTransactions() async {
            // Setup
            let transactions = PortfolioFactoryMock.transactions()
            viewModel.portfolio = PortfolioFactoryMock.portfolio(transactions: transactions)
            swiftDataManager.fetchResult = transactions.compactMap { $0.coinID }.map { CoinFactoryMock.coin(id: $0) }
            
            // Action
            await viewModel.deleteTransactions(for: "coin-1")
            
            // Assertions
            XCTAssertNil(viewModel.errorMessage)
            XCTAssertTrue(viewModel.portfolio.transactions.isEmpty)
            XCTAssertTrue(swiftDataManager.saveMethodCalled)
        }
    }
    
    // MARK: - Edit Transaction Tests
    func testEditTransaction() async {
        // Setup
        authStateProvider.fetchAuthTokenResult = .success(authToken)
        portfolioService.syncPortfolioResult = .success(true)
        
        let transactionID = UUID().uuidString
        let coinID = "coin-1"
        let originalTransaction = PortfolioFactoryMock.transaction(id: transactionID, coinID: coinID)
        viewModel.portfolio = PortfolioFactoryMock.portfolio(transactions: [originalTransaction])
        swiftDataManager.fetchResult = [CoinFactoryMock.coin(id: coinID)]
        
        // Action
        let editedTransaction = PortfolioFactoryMock.transaction(id: transactionID, coinID: coinID)
        await viewModel.editTransaction(editedTransaction)
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        let transaction = viewModel.portfolio.transactions.first!
        XCTAssertEqual(transaction.quantity, editedTransaction.quantity)
        XCTAssertEqual(transaction.pricePerCoin, editedTransaction.pricePerCoin)
        XCTAssertEqual(transaction.date, editedTransaction.date)
        XCTAssertEqual(transaction.type, editedTransaction.type)
    }
    
    // MARK: - Update Portfolio Tests
    func testPortfolioCalculations() async {
        // Setup
        let coinData1 = CoinFactoryMock.coin(id: "coin-1", currentPrice: 100, priceChangePercentage24H: 10)
        let coinData2 = CoinFactoryMock.coin(id: "coin-2", currentPrice: 200, priceChangePercentage24H: -5)
        let transaction1 = PortfolioFactoryMock.transaction(coinID: coinData1.id, quantity: 10, pricePerCoin: 150, type: .buy)
        let transaction2 = PortfolioFactoryMock.transaction(coinID: coinData2.id, quantity: 5, pricePerCoin: 300, type: .buy)
        viewModel.portfolio = PortfolioFactoryMock.portfolio(transactions: [transaction1, transaction2])
        swiftDataManager.fetchResult = [coinData1, coinData2]
        
        // Action
        await viewModel.updatePortfolio()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.totalValue, 2_000)
        XCTAssertEqual(viewModel.portfolioChange24HValue, 50)
        XCTAssertEqual(viewModel.portfolioChange24HPercentage, 2.55, accuracy: 0.01)
        XCTAssertEqual(viewModel.portfolioChangeAllTimeValue, -1_000)
        XCTAssertEqual(viewModel.portfolioChangeAllTimePercentage, -33.33, accuracy: 0.01)
    }
    
    // MARK: - Misc
    func testIsDeductiveTransaction() {
        // Assertions
        XCTAssertTrue(viewModel.isDeductiveTransaction(.sell))
        XCTAssertTrue(viewModel.isDeductiveTransaction(.transferOut))
        XCTAssertFalse(viewModel.isDeductiveTransaction(.buy))
        XCTAssertFalse(viewModel.isDeductiveTransaction(.transferIn))
    }
    
    func testToggleSelectedTimeline() {
        // Setup
        XCTAssertEqual(viewModel.selectedTimeline, .twentyFourHours)
        
        // Action & Assertions
        viewModel.toggleSelectedTimeline()
        XCTAssertEqual(viewModel.selectedTimeline, .allTime)
        
        viewModel.toggleSelectedTimeline()
        XCTAssertEqual(viewModel.selectedTimeline, .twentyFourHours)
    }
}
