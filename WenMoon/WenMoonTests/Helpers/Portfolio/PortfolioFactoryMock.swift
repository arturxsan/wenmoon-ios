//
//  PortfolioFactoryMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 11.01.25.
//

import Foundation
@testable import WenMoon

struct PortfolioFactoryMock {
    // MARK: - Transaction
    static func transaction(
        id: String = UUID().uuidString,
        coinID: String? = "coin-1",
        quantity: Double? = .random(in: 1...1_000),
        pricePerCoin: Double? = .random(in: 0.01...1_000),
        date: Date = .now,
        type: Transaction.TransactionType = .buy
    ) -> Transaction {
        Transaction(
            id: id,
            coinID: coinID,
            quantity: quantity,
            pricePerCoin: pricePerCoin,
            date: date,
            type: type
        )
    }

    static func transactions(coinID: String = "coin-1", count: Int = 10) -> [Transaction] {
        (1...count).map { index in
            transaction(coinID: coinID)
        }
    }

    // MARK: - Portfolio
    static func portfolio(
        id: String = UUID().uuidString,
        name: String = "Portfolio \(UUID().uuidString.prefix(5))",
        transactions: [Transaction] = transactions()
    ) -> Portfolio {
        Portfolio(
            id: id,
            name: name,
            transactions: transactions
        )
    }

    static func portfolios(
        count: Int = 5,
        transactionsPerPortfolio: Int = 10
    ) -> [Portfolio] {
        (1...count).map { _ in
            portfolio(transactions: transactions(count: transactionsPerPortfolio))
        }
    }
}
