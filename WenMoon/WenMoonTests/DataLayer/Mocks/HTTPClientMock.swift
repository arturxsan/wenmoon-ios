//
//  HTTPClientMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation
@testable import WenMoon

class HTTPClientMock: HTTPClient {
    // MARK: - Properties
    var response: Result<Data, APIError>!
    
    // MARK: - HTTPClient
    func execute(request: HTTPRequest) async throws -> Data {
        switch response {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        case .none:
            throw APIError.unknown
        }
    }
}
