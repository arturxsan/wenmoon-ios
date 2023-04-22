//
//  AnonymousSignInService.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 17.03.25.
//

import FirebaseAuth

protocol AnonymousSignInService {
    func signIn() async throws -> User
}

final class AnonymousSignInServiceImpl: AnonymousSignInService {
    // MARK: - AnonymousSignInService
    func signIn() async throws -> User {
        try await Auth.auth().signInAnonymously().user
    }
}
