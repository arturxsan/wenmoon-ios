//
//  Transaction.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 26.12.24.
//

import Foundation
import SwiftData

@Model
final class Transaction: Identifiable, Codable {
    // MARK: - Nested Types
    enum TransactionType: String, Codable, CaseIterable {
        case buy = "BUY"
        case sell = "SELL"
        case transferIn = "TRANSFER_IN"
        case transferOut = "TRANSFER_OUT"
        
        var title: String {
            switch self {
            case .buy:
                return "Buy"
            case .sell:
                return "Sell"
            case .transferIn:
                return "Transfer In"
            case .transferOut:
                return "Transfer Out"
            }
        }
    }
    
    // MARK: - Properties
    @Attribute(.unique)
    var id: String
    var coinID: String?
    var quantity: Double?
    var pricePerCoin: Double?
    var date: Date
    var type: TransactionType
    var portfolio: Portfolio?
    
    var totalCost: Double {
        guard
            let quantity,
            let pricePerCoin,
            (type == .buy) || (type == .sell)
        else {
            return .zero
        }
        return quantity * pricePerCoin
    }
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id
        case coinID = "coinId"
        case quantity
        case pricePerCoin
        case date
        case type
    }
    
    // MARK: - Initializers
    init(
        id: String = UUID().uuidString,
        coinID: String? = nil,
        quantity: Double? = nil,
        pricePerCoin: Double? = nil,
        date: Date = .now,
        type: TransactionType = .buy
    ) {
        self.id = id
        self.coinID = coinID
        self.quantity = quantity
        self.pricePerCoin = pricePerCoin
        self.date = date
        self.type = type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        coinID = try container.decode(String.self, forKey: .coinID)
        quantity = try container.decodeIfPresent(Double.self, forKey: .quantity)
        pricePerCoin = try container.decodeIfPresent(Double.self, forKey: .pricePerCoin)
        type = try container.decode(TransactionType.self, forKey: .type)
        
        if let dateString = try container.decodeIfPresent(String.self, forKey: .date) {
            self.date = ISO8601DateFormatter().date(from: dateString) ?? .now
        } else {
            self.date = .now
        }
    }
    
    // MARK: - Methods
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coinID, forKey: .coinID)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encodeIfPresent(pricePerCoin, forKey: .pricePerCoin)
        try container.encode(type, forKey: .type)
        
        let dateString = ISO8601DateFormatter().string(from: date)
        try container.encode(dateString, forKey: .date)
    }
    
    func update(from transaction: Transaction) {
        quantity = transaction.quantity
        pricePerCoin = transaction.pricePerCoin
        date = transaction.date
        type = transaction.type
    }
}

extension Transaction {
    func copy() -> Transaction {
        Transaction(
            id: id,
            coinID: coinID,
            quantity: quantity,
            pricePerCoin: pricePerCoin,
            date: date,
            type: type
        )
    }
}
