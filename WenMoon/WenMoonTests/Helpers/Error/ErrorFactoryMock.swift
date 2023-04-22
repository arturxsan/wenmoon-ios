//
//  ErrorFactoryMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 24.10.24.
//

import Foundation
@testable import WenMoon

struct ErrorFactoryMock {
    static func apiError(description: String = "Mocked API error description") -> APIError {
        .apiError(description: description)
    }
}
