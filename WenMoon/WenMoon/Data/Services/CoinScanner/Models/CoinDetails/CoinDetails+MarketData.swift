//
//  CoinDetails+MarketData.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 14.02.25.
//

import Foundation

extension CoinDetails {
    struct MarketData: Codable, Equatable {
        // MARK: - Properties
        let currentPrice: Double?
        let marketCap: Double?
        let fullyDilutedValuation: Double?
        let totalVolume: Double?
        let high24H: Double?
        let low24H: Double?
        let ath: Double?
        let athChangePercentage: Double?
        let athDate: String?
        let atl: Double?
        let atlChangePercentage: Double?
        let atlDate: String?
        let marketCapRank: Int64?
        let marketCapChange24H: Double?
        let marketCapChangePercentage24H: Double?
        let priceChange24H: Double?
        let priceChangePercentage24H: Double?
        let priceChangePercentage7D: Double?
        let priceChangePercentage30D: Double?
        let priceChangePercentage1Y: Double?
        let circulatingSupply: Double?
        let totalSupply: Double?
        let maxSupply: Double?
        
        // MARK: - Coding Keys
        private enum CodingKeys: String, CodingKey {
            case currentPrice
            case marketCap
            case fullyDilutedValuation
            case totalVolume
            case high24H
            case low24H
            case ath
            case athChangePercentage
            case athDate
            case atl
            case atlChangePercentage
            case atlDate
            case marketCapRank
            case marketCapChange24H
            case marketCapChangePercentage24H
            case priceChange24H
            case priceChangePercentage24H
            case priceChangePercentage7D
            case priceChangePercentage30D
            case priceChangePercentage1Y
            case circulatingSupply
            case totalSupply
            case maxSupply
        }
        
        // MARK: - Initializers
        init(
            currentPrice: Double? = nil,
            marketCap: Double? = nil,
            fullyDilutedValuation: Double? = nil,
            totalVolume: Double? = nil,
            high24H: Double? = nil,
            low24H: Double? = nil,
            ath: Double? = nil,
            athChangePercentage: Double? = nil,
            athDate: String? = nil,
            atl: Double? = nil,
            atlChangePercentage: Double? = nil,
            atlDate: String? = nil,
            marketCapRank: Int64? = nil,
            marketCapChange24H: Double? = nil,
            marketCapChangePercentage24H: Double? = nil,
            priceChange24H: Double? = nil,
            priceChangePercentage24H: Double? = nil,
            priceChangePercentage7D: Double? = nil,
            priceChangePercentage30D: Double? = nil,
            priceChangePercentage1Y: Double? = nil,
            circulatingSupply: Double? = nil,
            totalSupply: Double? = nil,
            maxSupply: Double? = nil
        ) {
            self.currentPrice = currentPrice
            self.marketCap = marketCap
            self.fullyDilutedValuation = fullyDilutedValuation
            self.totalVolume = totalVolume
            self.high24H = high24H
            self.low24H = low24H
            self.ath = ath
            self.athChangePercentage = athChangePercentage
            self.athDate = athDate
            self.atl = atl
            self.atlChangePercentage = atlChangePercentage
            self.atlDate = atlDate
            self.marketCapRank = marketCapRank
            self.marketCapChange24H = marketCapChange24H
            self.marketCapChangePercentage24H = marketCapChangePercentage24H
            self.priceChange24H = priceChange24H
            self.priceChangePercentage24H = priceChangePercentage24H
            self.priceChangePercentage7D = priceChangePercentage7D
            self.priceChangePercentage30D = priceChangePercentage30D
            self.priceChangePercentage1Y = priceChangePercentage1Y
            self.circulatingSupply = circulatingSupply
            self.totalSupply = totalSupply
            self.maxSupply = maxSupply
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            func extractDouble(_ key: CodingKeys) -> Double? {
                struct CurrencyContainer: Decodable { let usd: Double? }
                return (try? container.decodeIfPresent(CurrencyContainer.self, forKey: key))?.usd
            }
            
            func extractString(_ key: CodingKeys) -> String? {
                struct CurrencyContainer: Decodable { let usd: String? }
                return (try? container.decodeIfPresent(CurrencyContainer.self, forKey: key))?.usd
            }
            
            currentPrice = extractDouble(.currentPrice)
            marketCap = extractDouble(.marketCap)
            fullyDilutedValuation = extractDouble(.fullyDilutedValuation)
            totalVolume = extractDouble(.totalVolume)
            high24H = extractDouble(.high24H)
            low24H = extractDouble(.low24H)
            ath = extractDouble(.ath)
            athChangePercentage = extractDouble(.athChangePercentage)
            athDate = extractString(.athDate)
            atl = extractDouble(.atl)
            atlChangePercentage = extractDouble(.atlChangePercentage)
            atlDate = extractString(.atlDate)
            marketCapRank = try container.decodeIfPresent(Int64.self, forKey: .marketCapRank)
            marketCapChange24H = try container.decodeIfPresent(Double.self, forKey: .marketCapChange24H)
            marketCapChangePercentage24H = try container.decodeIfPresent(Double.self, forKey: .marketCapChangePercentage24H)
            priceChange24H = try container.decodeIfPresent(Double.self, forKey: .priceChange24H)
            priceChangePercentage24H = try container.decodeIfPresent(Double.self, forKey: .priceChangePercentage24H)
            priceChangePercentage7D = try container.decodeIfPresent(Double.self, forKey: .priceChangePercentage7D)
            priceChangePercentage30D = try container.decodeIfPresent(Double.self, forKey: .priceChangePercentage30D)
            priceChangePercentage1Y = try container.decodeIfPresent(Double.self, forKey: .priceChangePercentage1Y)
            circulatingSupply = try container.decodeIfPresent(Double.self, forKey: .circulatingSupply)
            totalSupply = try container.decodeIfPresent(Double.self, forKey: .totalSupply)
            maxSupply = try container.decodeIfPresent(Double.self, forKey: .maxSupply)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encodeIfPresent(marketCapRank, forKey: .marketCapRank)
            try container.encodeIfPresent(marketCapChange24H, forKey: .marketCapChange24H)
            try container.encodeIfPresent(marketCapChangePercentage24H, forKey: .marketCapChangePercentage24H)
            try container.encodeIfPresent(priceChange24H, forKey: .priceChange24H)
            try container.encodeIfPresent(priceChangePercentage24H, forKey: .priceChangePercentage24H)
            try container.encodeIfPresent(priceChangePercentage7D, forKey: .priceChangePercentage7D)
            try container.encodeIfPresent(priceChangePercentage30D, forKey: .priceChangePercentage30D)
            try container.encodeIfPresent(priceChangePercentage1Y, forKey: .priceChangePercentage1Y)
            try container.encodeIfPresent(circulatingSupply, forKey: .circulatingSupply)
            try container.encodeIfPresent(totalSupply, forKey: .totalSupply)
            try container.encodeIfPresent(maxSupply, forKey: .maxSupply)
            
            if let currentPrice {
                try container.encode(["usd": currentPrice], forKey: .currentPrice)
            }
            
            if let marketCap {
                try container.encode(["usd": marketCap], forKey: .marketCap)
            }
            
            if let fullyDilutedValuation {
                try container.encode(["usd": fullyDilutedValuation], forKey: .fullyDilutedValuation)
            }
            
            if let totalVolume {
                try container.encode(["usd": totalVolume], forKey: .totalVolume)
            }
            
            if let high24H {
                try container.encode(["usd": high24H], forKey: .high24H)
            }
            
            if let low24H {
                try container.encode(["usd": low24H], forKey: .low24H)
            }
            
            if let ath {
                try container.encode(["usd": ath], forKey: .ath)
            }
            
            if let athChangePercentage {
                try container.encode(["usd": athChangePercentage], forKey: .athChangePercentage)
            }
            
            if let athDate {
                try container.encode(["usd": athDate], forKey: .athDate)
            }
            
            if let atl {
                try container.encode(["usd": atl], forKey: .atl)
            }
            
            if let atlChangePercentage {
                try container.encode(["usd": atlChangePercentage], forKey: .atlChangePercentage)
            }
            
            if let atlDate {
                try container.encode(["usd": atlDate], forKey: .atlDate)
            }
        }
    }
}
