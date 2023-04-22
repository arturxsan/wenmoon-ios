//
//  NewsViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 01.03.25.
//

import XCTest
@testable import WenMoon

class NewsViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: NewsViewModel!
    var service: NewsServiceMock!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        service = NewsServiceMock()
        viewModel = NewsViewModel(service: service)
    }
    
    override func tearDown() {
        viewModel = nil
        service = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testFetchAllNews_success() async {
        // Setup
        let allNews = NewsFactoryMock.allNews()
        service.getNewsResult = .success(allNews)
        
        // Action
        await viewModel.fetchAllNews()
        
        // Assertions
        XCTAssertNil(viewModel.errorMessage)
        
        let mappedNews = [
            allNews.coindesk,
            allNews.cointelegraph,
            allNews.cryptopotato,
            allNews.bitcoinmagazine,
            allNews.bitcoinist
        ]
            .compactMap { $0 }
            .flatMap { $0 }
            .sorted(by: { $0.date > $1.date })
        XCTAssertEqual(viewModel.news, mappedNews)
    }
    
    func testFetchAllNews_failure() async {
        // Setup
        let error = ErrorFactoryMock.apiError()
        service.getNewsResult = .failure(error)
        
        // Action
        await viewModel.fetchAllNews()
        
        // Assertions
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, error.errorDescription)
        XCTAssertTrue(viewModel.news.isEmpty)
    }
    
    func testExtractSource_validURL() {
        // Setup
        let url = URL(string: "https://coindesk.com/article")!
        let expectedSource = "Coindesk"
        
        // Action
        let source = viewModel.extractSource(from: url)
        
        // Assertions
        XCTAssertEqual(source, expectedSource)
    }
    
    func testExtractSource_invalidURL() {
        // Setup
        let unknownURL = URL(string: "https://unknown.com/article")!
        let malformedURL = URL(string: "https://com")!
        
        // Action
        let unknownSource = viewModel.extractSource(from: unknownURL)
        let malformedSource = viewModel.extractSource(from: malformedURL)
        
        // Assertions
        XCTAssertNil(unknownSource)
        XCTAssertNil(malformedSource)
    }
}
