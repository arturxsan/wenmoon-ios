//
//  FearAndGreedIndex.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.02.25.
//

import Foundation

struct FearAndGreedIndex: Codable, Equatable {
    struct FearAndGreedData: Codable, Equatable {
        let value: String
        let valueClassification: String
    }
    
    let data: [FearAndGreedData]
}
