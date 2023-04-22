//
//  UserDefaultsError.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 23.05.23.
//

import Foundation

enum UserDefaultsError: DescriptiveError {
    case failedToEncodeObject, failedToDecodeObject
    
    var errorDescription: String {
        switch self {
        case .failedToEncodeObject:
            return "Couldn't prepare object."
        case .failedToDecodeObject:
            return "Couldn't understand the object."
        }
    }
}
