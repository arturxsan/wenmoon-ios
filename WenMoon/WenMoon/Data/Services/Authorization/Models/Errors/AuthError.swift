//
//  AuthError.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 21.02.25.
//

import Foundation

enum AuthError: DescriptiveError, Equatable {
    case failedToFetchAccount
    case failedToDeleteAccount
    case failedToSetActiveAccount
    case failedToDeleteActiveAccount
    case failedToFetchFirebaseToken
    case failedToSignIn(provider: AuthProvider? = nil)
    case failedToSignOut
    case unknownError
    
    var errorDescription: String {
        switch self {
        case .failedToFetchAccount:
            return "Failed to fetch account."
        case .failedToDeleteAccount:
            return "Failed to delete account."
        case .failedToSetActiveAccount:
            return "Failed to set active account."
        case .failedToDeleteActiveAccount:
            return "Failed to delete active account."
        case .failedToSignIn(let provider):
            guard let provider else { return "Failed to sign in." }
            return "Failed to sign in with \(provider.name)."
        case .failedToSignOut:
            return "Failed to sign out."
        case .failedToFetchFirebaseToken:
            return "Failed to fetch Firebase token."
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}
