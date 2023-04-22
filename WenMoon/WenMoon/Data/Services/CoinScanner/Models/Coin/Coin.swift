//
//  Coin.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 11.10.24.
//

import UIKit
import SwiftData

@Model
final class Coin: Codable {
    // MARK: - Properties
    @Attribute(.unique)
    var id: String
    var symbol: String
    var name: String
    var image: URL?
    var imageData: Data?
    var currentPrice: Double?
    var marketCap: Double?
    var marketCapRank: Int64?
    var priceChangePercentage24H: Double?
    var circulatingSupply: Double?
    var ath: Double?
    var isPinned = false
    var isArchived = false
    var priceAlerts: [PriceAlert] = []
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case currentPrice
        case marketCap
        case marketCapRank
        case priceChangePercentage24H
        case circulatingSupply
        case ath
    }
    
    // MARK: - Initializers
    init(
        id: String = "",
        symbol: String = "",
        name: String = "",
        image: URL? = nil,
        imageData: Data? = nil,
        currentPrice: Double? = nil,
        marketCap: Double? = nil,
        marketCapRank: Int64? = nil,
        priceChangePercentage24H: Double? = nil,
        circulatingSupply: Double? = nil,
        ath: Double? = nil,
        isPinned: Bool = false,
        isArchived: Bool = false,
        priceAlerts: [PriceAlert] = []
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.image = image
        self.imageData = imageData
        self.currentPrice = currentPrice
        self.marketCap = marketCap
        self.marketCapRank = marketCapRank
        self.priceChangePercentage24H = priceChangePercentage24H
        self.circulatingSupply = circulatingSupply
        self.ath = ath
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.priceAlerts = priceAlerts
    }
    
    init(
        from coinDetails: CoinDetails,
        isPinned: Bool = false,
        isArchived: Bool = false,
        priceAlerts: [PriceAlert] = []
    ) {
        id = coinDetails.id
        symbol = coinDetails.symbol
        name = coinDetails.name
        image = coinDetails.image
        currentPrice = coinDetails.marketData.currentPrice
        marketCap = coinDetails.marketData.marketCap
        marketCapRank = coinDetails.marketData.marketCapRank
        priceChangePercentage24H = coinDetails.marketData.priceChangePercentage24H
        circulatingSupply = coinDetails.marketData.circulatingSupply
        ath = coinDetails.marketData.ath
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.priceAlerts = priceAlerts
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol).uppercased()
        name = try container.decode(String.self, forKey: .name)
        image = try container.decodeIfPresent(SafeURL.self, forKey: .image)?.url
        currentPrice = try container.decodeIfPresent(Double.self, forKey: .currentPrice)
        marketCap = try container.decodeIfPresent(Double.self, forKey: .marketCap)
        marketCapRank = try container.decodeIfPresent(Int64.self, forKey: .marketCapRank)
        priceChangePercentage24H = try container.decodeIfPresent(Double.self, forKey: .priceChangePercentage24H)
        circulatingSupply = try container.decodeIfPresent(Double.self, forKey: .circulatingSupply)
        ath = try container.decodeIfPresent(Double.self, forKey: .ath)
    }
    
    // MARK: - Methods
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(symbol.lowercased(), forKey: .symbol)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(currentPrice, forKey: .currentPrice)
        try container.encodeIfPresent(marketCap, forKey: .marketCap)
        try container.encodeIfPresent(marketCapRank, forKey: .marketCapRank)
        try container.encodeIfPresent(priceChangePercentage24H, forKey: .priceChangePercentage24H)
        try container.encodeIfPresent(circulatingSupply, forKey: .circulatingSupply)
        try container.encodeIfPresent(ath, forKey: .ath)
    }
    
    func updateMarketData(from marketData: MarketData) {
        currentPrice = marketData.currentPrice
        marketCap = marketData.marketCap
        priceChangePercentage24H = marketData.priceChangePercentage24H
    }
}
