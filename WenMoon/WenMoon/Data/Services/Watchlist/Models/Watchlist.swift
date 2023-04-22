//
//  Watchlist.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 18.03.25.
//

import Foundation

struct Watchlist: Codable, Equatable {
    // MARK: - Properties
    let coins: [Coin]
    let pinnedCoinIDs: [String]
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case coins
        case pinnedCoinIDs = "pinnedCoinIds"
    }
    
    // MARK: - Initializers
    init(coins: [Coin] = [], pinnedCoinIDs: [String] = []) {
        self.coins = coins
        self.pinnedCoinIDs = pinnedCoinIDs
    }
}
