//
//  CoinDetailsViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 11.11.24.
//

import XCTest
@testable import WenMoon

class CoinDetailsViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: CoinDetailsViewModel!
    var service: CoinScannerServiceMock!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        service = CoinScannerServiceMock()
        viewModel = CoinDetailsViewModel(coin: Coin(), service: service)
    }
    
    override func tearDown() {
        viewModel = nil
        service = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    // Coin Details
    func testFetchCoinDetails_success() async {
        // Setup
        let coinDetails = CoinDetailsFactoryMock.coinDetails()
        service.getCoinDetailsResult = .success(coinDetails)
        
        // Action
        await viewModel.fetchCoinDetails()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.coinDetails, coinDetails)
    }

    func testFetchCoinDetails_failure() async {
        // Setup
        let error = ErrorFactoryMock.apiError()
        service.getCoinDetailsResult = .failure(error)
        
        // Action
        await viewModel.fetchCoinDetails()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
    
    // Chart Data
    func testFetchChartData_success() async {
        // Setup
        let chartData = ChartDataFactoryMock.chartData()
        service.getChartDataResult = .success(chartData)
        
        // Action
        await viewModel.fetchChartData()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        assertChartDataEqual(viewModel.chartData, chartData)
    }
    
    func testFetchChartData_usesCache() async {
        // Setup
        let cachedChartData = ChartDataFactoryMock.chartDataForTimeframes()
        viewModel.chartDataCache = cachedChartData
        
        // Actions & Assertions
        viewModel.selectedTimeframe = .oneDay
        await viewModel.fetchChartData()
        assertChartDataEqual(viewModel.chartData, cachedChartData[.oneDay]!)
        
        viewModel.selectedTimeframe = .oneWeek
        await viewModel.fetchChartData()
        assertChartDataEqual(viewModel.chartData, cachedChartData[.oneWeek]!)
        
        viewModel.selectedTimeframe = .oneMonth
        await viewModel.fetchChartData()
        assertChartDataEqual(viewModel.chartData, cachedChartData[.oneMonth]!)
        
        viewModel.selectedTimeframe = .oneYear
        await viewModel.fetchChartData()
        assertChartDataEqual(viewModel.chartData, cachedChartData[.oneYear]!)
    }
    
    func testFetchChartData_emptyResponse() async {
        // Setup
        service.getChartDataResult = .success([])
        
        // Action
        await viewModel.fetchChartData()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.chartData.isEmpty)
    }
    
    func testFetchChartData_failure() async {
        // Setup
        let error = ErrorFactoryMock.apiError()
        service.getChartDataResult = .failure(error)
        
        // Action
        await viewModel.fetchChartData()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
    }
}
