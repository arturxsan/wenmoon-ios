//
//  HTTPRequest.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
}

struct HTTPRequest {
    let httpMethod: HTTPMethod
    let path: String
    let parameters: [String: String]?
}
