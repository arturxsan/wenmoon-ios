//
//  Configuration.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 18.11.24.
//

import Foundation

enum AppConfig {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }
    
    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }
        
        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}

enum API {
    static var baseURL: URL {
        try! URL(string: "https://" + AppConfig.value(for: "BASE_URL"))!
    }
    
    static var key: String {
        try! AppConfig.value(for: "API_KEY")
    }
}

enum RevenueCat {
    static var apiKey: String {
        try! AppConfig.value(for: "RC_API_KEY")
    }
}

enum Constants {
    enum Links {
        static let privacyURL = URL(string: "https://arturxsan.github.io/legal-docs/WenMoon/privacy.html")!
        static let termsURL = URL(string: "https://arturxsan.github.io/legal-docs/WenMoon/terms.html")!
        static let feedbackURL = URL(string: "https://apps.apple.com/app/id6740096683?action=write-review")!
    }
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
}
