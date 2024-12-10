//
//  GlobalCryptoMarketData.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 12.12.24.
//

import Foundation

struct GlobalCryptoMarketData: Decodable {
    let marketCapPercentage: [String: Double]
}
