//
//  AccountFactoryMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 22.02.25.
//

import Foundation
@testable import WenMoon

struct AccountFactoryMock {
    static func account(
        id: String = "test-id",
        username: String = "test-username",
        isAnonymous: Bool = false,
        isPro: Bool = false
    ) -> Account {
        Account(id: id, username: username, isAnonymous: isAnonymous, isPro: isPro)
    }
}
