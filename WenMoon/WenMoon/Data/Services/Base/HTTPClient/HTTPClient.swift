//
//  HTTPClient.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation

protocol HTTPClient {
    func execute(request: HTTPRequest) async throws -> Data
}

final class HTTPClientImpl: HTTPClient {
    // MARK: - Properties
    private let baseURL: URL
    private let apiKey: String?
    private let session: URLSession
    
    // MARK: - Initializers
    convenience init(baseURL: URL = API.baseURL, apiKey: String = API.key) {
        self.init(baseURL: baseURL, apiKey: apiKey, session: .shared)
    }
    
    init(baseURL: URL, apiKey: String, session: URLSession) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }
    
    // MARK: - HTTPClient
    func execute(request: HTTPRequest) async throws -> Data {
        guard var urlComponents = URLComponents(url: absolutePath(request.path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidEndpoint(endpoint: request.path)
        }
        urlComponents.queryItems = queryitems(from: request.parameters)
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        request.headers?.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        printPrettyRequest(urlRequest)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            printPrettyResponse(httpResponse, data: data)
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            print(response.debugDescription)
            throw APIError.unknown
        }
        
        return data
    }
    
    // MARK: - Private
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
    
    private func printPrettyRequest(_ request: URLRequest) {
        print("\n──────────────────────────────────")
        print("HTTP REQUEST")
        print("URL: \(request.url?.absoluteString ?? "N/A")")
        print("Method: \(request.httpMethod ?? "N/A")")
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("Headers:")
            for (key, value) in headers {
                print("   \(key): \(value)")
            }
        }
        
        if let body = request.httpBody, let jsonString = prettyPrintedJSON(from: body) {
            print("Body:")
            print(jsonString)
        } else {
            print("Body: None")
        }
        print("──────────────────────────────────\n")
    }
    
    private func printPrettyResponse(_ response: HTTPURLResponse, data: Data) {
        print("\n──────────────────────────────────")
        print("HTTP RESPONSE")
        print("Status Code: \(response.statusCode) (\(HTTPURLResponse.localizedString(forStatusCode: response.statusCode)))")
        
        print("Headers:")
        for (key, value) in response.allHeaderFields {
            print("   \(key): \(value)")
        }
        
        if let jsonString = prettyPrintedJSON(from: data) {
            print("Response Body:")
            print(jsonString)
        } else {
            print("Response Body: Unable to decode")
        }
        print("──────────────────────────────────\n")
    }
    
    private func prettyPrintedJSON(from data: Data) -> String? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(decoding: prettyData, as: UTF8.self)
        } catch {
            return nil
        }
    }
}
