//
//  HTTPRequest.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct HTTPRequest {
    let method: HTTPMethod
    let path: String
    let parameters: [String: String]?
    let headers: [String: String]?
    let body: Data?
    
    init(
        method: HTTPMethod,
        path: String,
        parameters: [String : String]? = nil,
        headers: [String : String]? = nil,
        body: Data? = nil
    ) {
        self.method = method
        self.path = path
        self.parameters = parameters
        self.headers = headers
        self.body = body
    }
}
