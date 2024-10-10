//
//  HTTPClient.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation

protocol HTTPClient {
    var encoder: JSONEncoder { get }
    var decoder: JSONDecoder { get }

    func get(path: String,
             parameters: [String: String]?,
             headers: [String: String]?) async throws -> Data

    func post(path: String,
              parameters: [String: String]?,
              headers: [String: String]?,
              body: Data?) async throws -> Data

    func delete(path: String,
                parameters: [String: String]?,
                headers: [String: String]?) async throws -> Data
}

extension HTTPClient {
    func get(path: String,
             parameters: [String: String]? = nil,
             headers: [String: String]? = nil) async throws -> Data {
        try await get(path: path, parameters: parameters, headers: headers)
    }

    func post(path: String,
              parameters: [String: String]? = nil,
              headers: [String: String]? = nil,
              body: Data? = nil) async throws -> Data {
        try await post(path: path, parameters: parameters, headers: headers, body: body)
    }

    func delete(path: String,
                parameters: [String: String]? = nil,
                headers: [String: String]? = nil) async throws -> Data {
        try await delete(path: path, parameters: parameters, headers: headers)
    }
}

final class HTTPClientImpl: HTTPClient {

    // MARK: - Properties

    let baseURL: URL
    let session: URLSession
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    // MARK: - Initializers

    convenience init(baseURL: URL) {
        self.init(baseURL: baseURL,
                  session: .shared,
                  encoder: .init(),
                  decoder: .init())
    }

    init(baseURL: URL, session: URLSession, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.baseURL = baseURL
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - HTTPClient

    func get(path: String,
             parameters: [String: String]?,
             headers: [String: String]?) async throws -> Data {
        let httpRequest = HTTPRequest(httpMethod: .get,
                                      path: path,
                                      parameters: parameters,
                                      headers: headers,
                                      body: nil)
        return try await execute(httpRequest)
    }

    func post(path: String,
              parameters: [String: String]?,
              headers: [String: String]?,
              body: Data?) async throws -> Data {
        let httpRequest = HTTPRequest(httpMethod: .post,
                                      path: path,
                                      parameters: parameters,
                                      headers: headers,
                                      body: body)
        return try await execute(httpRequest)
    }

    func delete(path: String,
                parameters: [String: String]?,
                headers: [String: String]?) async throws -> Data {
        let httpRequest = HTTPRequest(httpMethod: .delete,
                                      path: path,
                                      parameters: parameters,
                                      headers: headers,
                                      body: nil)
        return try await execute(httpRequest)
    }

    // MARK: - Private

    private func execute(_ httpRequest: HTTPRequest) async throws -> Data {
        guard var urlComponents = URLComponents(url: absolutePath(httpRequest.path),
                                                resolvingAgainstBaseURL: false) else {
            throw APIError.invalidEndpoint(endpoint: httpRequest.path)
        }
        urlComponents.queryItems = queryitems(from: httpRequest.parameters)

        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = httpRequest.httpMethod.rawValue
        urlRequest.httpBody = httpRequest.body

        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.headers?.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unknown(response: response)
        }

        return data
    }

    private func absolutePath(_ relativePath: String) -> URL {
        guard !relativePath.isEmpty else { return baseURL }
        assert(relativePath.first != "/", "'/' symbol at the beginning of url relativePath will cause 'RestrictedIP' error")

        guard let url = URL(string: relativePath, relativeTo: baseURL) else {
            assertionFailure("Failed to construct url for path \(relativePath)")
            return baseURL
        }

        return url.absoluteURL
    }

    private func queryitems(from parameters: [String: String]?) -> [URLQueryItem]? {
        parameters?.compactMap { URLQueryItem(name: $0.key, value: $0.value) }
    }
}
