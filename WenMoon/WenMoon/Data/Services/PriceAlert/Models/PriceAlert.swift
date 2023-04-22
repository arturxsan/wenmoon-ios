//
//  PriceAlert.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 23.05.23.
//

import SwiftUI

struct PriceAlert: Codable, Hashable {
    // MARK: - Nested Types
    enum TargetDirection: String, Codable {
        case above = "ABOVE"
        case below = "BELOW"
        
        var iconName: String {
            switch self {
            case .above: return "arrow.increase"
            case .below: return "arrow.decrease"
            }
        }
        
        var color: Color {
            switch self {
            case .above: return .neonGreen
            case .below: return .neonPink
            }
        }
    }
    
    // MARK: - Properties
    let id: String
    let coinID: String
    let symbol: String
    let targetPrice: Double
    let targetDirection: TargetDirection
    var isActive: Bool
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id
        case coinID = "coinId"
        case symbol
        case targetPrice
        case targetDirection
        case isActive
    }
    
    // MARK: - Initializers
    init(
        id: String,
        coinID: String,
        symbol: String,
        targetPrice: Double,
        targetDirection: TargetDirection,
        isActive: Bool
    ) {
        self.id = id
        self.coinID = coinID
        self.symbol = symbol
        self.targetPrice = targetPrice
        self.targetDirection = targetDirection
        self.isActive = isActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        coinID = try container.decode(String.self, forKey: .coinID)
        symbol = try container.decode(String.self, forKey: .symbol)
        targetPrice = try container.decode(Double.self, forKey: .targetPrice)
        targetDirection = try container.decode(TargetDirection.self, forKey: .targetDirection)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
    
    // MARK: - Methods
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coinID, forKey: .coinID)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(targetPrice, forKey: .targetPrice)
        try container.encode(targetDirection, forKey: .targetDirection)
        try container.encode(isActive, forKey: .isActive)
    }
}
