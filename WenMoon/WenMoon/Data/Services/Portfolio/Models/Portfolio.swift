//
//  Portfolio.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 26.12.24.
//

import Foundation
import SwiftData

@Model
final class Portfolio: Codable, Sendable {
    // MARK: - Properties
    @Attribute(.unique)
    var id: String
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Transaction.portfolio)
    var transactions: [Transaction]
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case transactions
    }
    
    // MARK: - Initializers
    init(
        id: String = UUID().uuidString,
        name: String = "Main",
        transactions: [Transaction] = []
    ) {
        self.id = id
        self.name = name
        self.transactions = transactions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        transactions = try container.decode([Transaction].self, forKey: .transactions)
    }
    
    // MARK: - Methods
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(transactions, forKey: .transactions)
    }
}
