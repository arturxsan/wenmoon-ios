//
//  SwiftDataError.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 11.10.24.
//

import Foundation

enum SwiftDataError: DescriptiveError {
    case failedToFetchModels, failedToSaveModel
    
    var errorDescription: String {
        switch self {
        case .failedToFetchModels:
            return "Couldn't load available models."
        case .failedToSaveModel:
            return "Couldn't save your model."
        }
    }
}
