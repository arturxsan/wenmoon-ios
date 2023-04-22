//
//  Account.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.02.25.
//

import Foundation

struct Account: Codable, Equatable {
    let id: String
    let username: String
    let isAnonymous: Bool
    var isPro = false
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id, username, isAnonymous
    }
    
    // MARK: - Initializers
    init(
        id: String,
        username: String,
        isAnonymous: Bool,
        isPro: Bool = false
    ) {
        self.id = id
        self.username = username
        self.isAnonymous = isAnonymous
        self.isPro = isPro
    }
    
    init(from account: Account, isPro: Bool = false) {
        id = account.id
        username = account.username
        isAnonymous = account.isAnonymous
        self.isPro = isPro
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        isAnonymous = try container.decode(Bool.self, forKey: .isAnonymous)
    }
    
    // MARK: - Methods
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(isAnonymous, forKey: .isAnonymous)
    }
}
