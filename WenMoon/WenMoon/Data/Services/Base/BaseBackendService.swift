//
//  BaseBackendService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation

class BaseBackendService {
    // MARK: - Properties
    private(set) var httpClient: HTTPClient
    
    var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
    
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: - Initializers
    convenience init() {
        self.init(httpClient: HTTPClientImpl())
    }
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    // MARK: - Methods
    func mapToAPIError(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }
        
        switch error {
        case let nsError as NSError where nsError.domain == NSURLErrorDomain:
            return .noNetworkConnection
        case is EncodingError:
            return .failedToEncodeBody
        case is DecodingError:
            return .failedToDecodeResponse
        default:
            return .apiError(description: error.localizedDescription)
        }
    }
}
