//
//  GlobalCryptoMarketData.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 12.12.24.
//

import Foundation

struct CryptoGlobalMarketData: Codable, Equatable {
    struct MarketData: Codable, Equatable {
        let totalMarketCap: [String: Double]
        let marketCapPercentage: [String: Double]
    }
    
    let data: MarketData
}
