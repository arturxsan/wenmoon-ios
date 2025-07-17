//
//  NewsServiceTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 01.03.25.
//

import XCTest
@testable import WenMoon

class NewsServiceTests: XCTestCase {
    // MARK: - Properties
    var service: NewsService!
    var httpClient: HTTPClientMock!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        httpClient = HTTPClientMock()
        service = NewsServiceImpl(httpClient: httpClient)
    }
    
    override func tearDown() {
        service = nil
        httpClient = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testGetAllNews_success() async throws {
        // Setup
        let response = NewsFactoryMock.allNews()
        httpClient.response = .success(try! JSONEncoder().encode(response))
        
        // Action
        let news = try await service.getAllNews()
        
        // Assertions
        XCTAssertEqual(news, response)
    }
    
    func testGetAllNews_failure() async throws {
        // Setup
        let error = ErrorFactoryMock.apiError()
        httpClient.response = .failure(error)
        
        // Action & Assertions
        await assertFailure(
            for: { [weak self] in
                try await self!.service.getAllNews()
            },
            expectedError: error
        )
    }
}
