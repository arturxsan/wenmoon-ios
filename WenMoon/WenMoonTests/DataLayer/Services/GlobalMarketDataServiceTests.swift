//
//  GlobalMarketDataServiceTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 19.03.25.
//

import XCTest
@testable import WenMoon

class GlobalMarketDataServiceTests: XCTestCase {
    // MARK: - Properties
    var service: GlobalMarketDataService!
    var httpClient: HTTPClientMock!
    
    let encoder = JSONEncoder()
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        httpClient = HTTPClientMock()
        service = GlobalMarketDataServiceImpl(httpClient: httpClient)
    }
    
    override func tearDown() {
        service = nil
        httpClient = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testGetFearAndGreedIndex_success() async throws {
        // Setup
        let response = FearAndGreedIndex(data: [.init(value: "23", valueClassification: "Fear")])
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let receivedResponse = try await service.getFearAndGreedIndex()
        
        // Assertions
        XCTAssertEqual(receivedResponse, response)
    }

    func testGetFearAndGreedIndex_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getFearAndGreedIndex()
            },
            expectedError: error
        )
    }
    
    func testGetCryptoGlobalMarketData_success() async throws {
        // Setup
        let response = CryptoGlobalMarketData(
            data: .init(
                totalMarketCap: ["usd": 3031436119298.6084],
                marketCapPercentage: ["btc": 56.5, "eth": 12.8]
            )
        )
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let receivedResponse = try await service.getCryptoGlobalMarketData()
        
        // Assertions
        XCTAssertEqual(receivedResponse, response)
    }

    func testGetGlobalCryptoMarketData_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getCryptoGlobalMarketData()
            },
            expectedError: error
        )
    }

    // Get Global Market Data
    func testGetGlobalMarketData_success() async throws {
        // Setup
        let dateFormatter = ISO8601DateFormatter()
        let response = GlobalMarketData(
            cpiPercentage: 2.7,
            nextCPIDate: dateFormatter.date(from: "2025-01-01T00:00:00Z")!,
            interestRatePercentage: 4.5,
            nextFOMCMeetingDate: dateFormatter.date(from: "2025-02-01T00:00:00Z")!
        )
        httpClient.response = .success(try! encoder.encode(response))
        
        // Action
        let data = try await service.getGlobalMarketData()
        
        // Assertions
        XCTAssertEqual(data.cpiPercentage, response.cpiPercentage)
        XCTAssertEqual(data.nextCPIDate, response.nextCPIDate)
        XCTAssertEqual(data.interestRatePercentage, response.interestRatePercentage)
        XCTAssertEqual(data.nextFOMCMeetingDate, response.nextFOMCMeetingDate)
    }

    func testGetGlobalMarketData_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getGlobalMarketData()
            },
            expectedError: error
        )
    }
}
