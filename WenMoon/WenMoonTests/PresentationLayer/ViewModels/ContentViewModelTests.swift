//
//  ContentViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 15.01.25.
//

import XCTest
@testable import WenMoon

class ContentViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: ContentViewModel!
    var service: GlobalMarketDataServiceMock!
    var userDefaultsManager: UserDefaultsManagerMock!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        service = GlobalMarketDataServiceMock()
        userDefaultsManager = UserDefaultsManagerMock()
        viewModel = ContentViewModel(service: service, userDefaultsManager: userDefaultsManager)
    }
    
    override func tearDown() {
        viewModel = nil
        service = nil
        userDefaultsManager = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testFetchAllGlobalMarketData_success() async {
        // Setup
        let fearAndGreedIndex = FearAndGreedIndex(data: [.init(value: "75", valueClassification: "Greed")])
        let cryptoGlobalMarketData = CryptoGlobalMarketData(
            data: .init(
                totalMarketCap: ["usd": 3031436119298.6084],
                marketCapPercentage: ["btc": 56.5, "eth": 12.8]
            )
        )
        let dateFormatter = ISO8601DateFormatter()
        let globalMarketData = GlobalMarketData(
            cpiPercentage: 2.7,
            nextCPIDate: .now,
            interestRatePercentage: 4.5,
            nextFOMCMeetingDate: .now
        )
        service.getFearAndGreedIndexResult = .success(fearAndGreedIndex)
        service.getCryptoGlobalMarketDataResult = .success(cryptoGlobalMarketData)
        service.getGlobalMarketDataResult = .success(globalMarketData)
        
        // Action
        await viewModel.fetchAllGlobalMarketData()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        
        let expectedItems = [
            GlobalMarketDataItem(type: .fearAndGreedIndex, value: "75 Greed"),
            GlobalMarketDataItem(type: .btcDominance, value: "56,5 %"),
            GlobalMarketDataItem(type: .cpi, value: "2,7 %"),
            GlobalMarketDataItem(type: .nextCPI, value: "Today"),
            GlobalMarketDataItem(type: .interestRate, value: "4,5 %"),
            GlobalMarketDataItem(type: .nextFOMCMeeting, value: "Today")
        ]
        assertItemsEqual(viewModel.globalMarketDataItems, expectedItems)
    }
    
    func testFetchAllGlobalMarketData_failure() async {
        // Setup
        let error = ErrorFactoryMock.apiError()
        let fearAndGreedIndex = FearAndGreedIndex(data: [.init(value: "75", valueClassification: "Greed")])
        let globalMarketData = GlobalMarketData(
            cpiPercentage: 2.7,
            nextCPIDate: .now,
            interestRatePercentage: 4.5,
            nextFOMCMeetingDate: .now
        )
        service.getFearAndGreedIndexResult = .success(fearAndGreedIndex)
        service.getCryptoGlobalMarketDataResult = .failure(error)
        service.getGlobalMarketDataResult = .success(globalMarketData)
        
        // Action
        await viewModel.fetchAllGlobalMarketData()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertTrue(viewModel.globalMarketDataItems.isEmpty)
    }
    
    func testFetchAllGlobalMarketData_missingFearAndGreedData() async {
        // Setup
        let fearAndGreedIndex = FearAndGreedIndex(data: [])
        let cryptoGlobalMarketData = CryptoGlobalMarketData(
            data: .init(
                totalMarketCap: ["usd": 3031436119298.6084],
                marketCapPercentage: ["btc": 56.5, "eth": 12.8]
            )
        )
        let globalMarketData = GlobalMarketData(
            cpiPercentage: 2.7,
            nextCPIDate: .now,
            interestRatePercentage: 4.5,
            nextFOMCMeetingDate: .now
        )
        service.getFearAndGreedIndexResult = .success(fearAndGreedIndex)
        service.getCryptoGlobalMarketDataResult = .success(cryptoGlobalMarketData)
        service.getGlobalMarketDataResult = .success(globalMarketData)
        
        // Action
        await viewModel.fetchAllGlobalMarketData()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.globalMarketDataItems.isEmpty)
    }
    
    func testFetchAllGlobalMarketData_missingBTCDominance() async {
        // Setup
        let fearAndGreedIndex = FearAndGreedIndex(data: [.init(value: "75", valueClassification: "Greed")])
        let cryptoGlobalMarketData = CryptoGlobalMarketData(
            data: .init(
                totalMarketCap: ["usd": 3031436119298.6084],
                marketCapPercentage: ["btc": 56.5, "eth": 12.8]
            )
        )
        let globalMarketData = GlobalMarketData(
            cpiPercentage: 2.7,
            nextCPIDate: .now,
            interestRatePercentage: 4.5,
            nextFOMCMeetingDate: .now
        )
        service.getFearAndGreedIndexResult = .success(fearAndGreedIndex)
        service.getCryptoGlobalMarketDataResult = .success(cryptoGlobalMarketData)
        service.getGlobalMarketDataResult = .success(globalMarketData)
        
        // Action
        await viewModel.fetchAllGlobalMarketData()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.globalMarketDataItems.isEmpty)
    }
    
    func testFetchStartScreen() {
        // Setup
        let expectedIndex = 2
        userDefaultsManager.getObjectReturnValue = [.setting(ofType: .startScreen): expectedIndex]
        
        // Action
        viewModel.fetchStartScreen()
        
        // Assert
        XCTAssertEqual(viewModel.startScreenIndex, expectedIndex)
    }
    
    // MARK: - Private
    private func assertItemsEqual(_ actual: [GlobalMarketDataItem], _ expected: [GlobalMarketDataItem]) {
        XCTAssertEqual(actual.count, expected.count)
        for (index, expectedItem) in expected.enumerated() {
            let item = actual[index]
            XCTAssertEqual(item.type, expectedItem.type)
            XCTAssertEqual(item.value, expectedItem.value)
        }
    }
}
