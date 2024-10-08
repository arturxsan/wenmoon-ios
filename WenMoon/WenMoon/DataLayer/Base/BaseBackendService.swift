//
//  BaseBackendService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation

class BaseBackendService {

    private let baseURL: URL
    private(set) var httpClient: HTTPClient

    var encoder: JSONEncoder {
        httpClient.encoder.keyEncodingStrategy = .convertToSnakeCase
        return httpClient.encoder
    }

    var decoder: JSONDecoder {
        httpClient.decoder.keyDecodingStrategy = .convertFromSnakeCase
        return httpClient.decoder
    }

    convenience init(baseURL: URL) {
        let httpClient = HTTPClientImpl(baseURL: baseURL)
        self.init(httpClient: httpClient, baseURL: baseURL)
    }

    init(httpClient: HTTPClient, baseURL: URL) {
        self.httpClient = httpClient
        self.baseURL = baseURL
    }

    func mapToAPIError(_ error: Error) -> APIError {
        guard let error = error as? APIError else {
            return .apiError(description: error.localizedDescription)
        }
        return error
    }
}
