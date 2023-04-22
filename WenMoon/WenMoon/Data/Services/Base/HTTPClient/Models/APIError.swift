//
//  APIError.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation

protocol DescriptiveError: Error {
    var errorDescription: String { get }
}

enum APIError: DescriptiveError, Equatable {
    case apiError(description: String)
    case invalidEndpoint(endpoint: String)
    case invalidParameter(parameter: String)
    case noNetworkConnection
    case failedToEncodeBody
    case failedToDecodeResponse
    case unknown
    
    var errorDescription: String {
        switch self {
        case let .apiError(description):
            return description
        case let .invalidEndpoint(endpoint):
            return "Invalid endpoint: \(endpoint)"
        case let .invalidParameter(parameter):
            return "Invalid parameter: \(parameter)"
        case .noNetworkConnection:
            return "No network connection."
        case .failedToEncodeBody:
            return "Couldn't prepare your request."
        case .failedToDecodeResponse:
            return "Couldn't understand the response."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
