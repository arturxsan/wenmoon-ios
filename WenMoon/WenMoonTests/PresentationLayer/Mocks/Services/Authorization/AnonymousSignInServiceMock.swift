//
//  AnonymousSignInServiceMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 19.03.25.
//

import XCTest
import FirebaseAuth
@testable import WenMoon

class AnonymousSignInServiceMock: AnonymousSignInService {
    // MARK: - Properties
    var signInResult: Result<User, Error>!
    
    // MARK: - AnonymousSignInService
    func signIn() async throws -> User {
        switch signInResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        case .none:
            XCTFail("signInResult not set")
            throw AuthError.failedToSignIn(provider: .anonymous)
        }
    }
}
