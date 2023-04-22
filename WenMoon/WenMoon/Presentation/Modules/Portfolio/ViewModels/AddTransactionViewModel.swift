//
//  AddTransactionViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 27.12.24.
//

import Foundation

final class AddTransactionViewModel: BaseViewModel {
    // MARK: - Methods
    func shouldDisableAddTransactionsButton(for transaction: Transaction) -> Bool {
        switch transaction.type {
        case .buy, .sell:
            return transaction.coinID.isNil || transaction.quantity.isNil || transaction.pricePerCoin.isNil
        default:
            return transaction.coinID.isNil || transaction.quantity.isNil
        }
    }
    
    func isPriceFieldRequired(for transactionType: Transaction.TransactionType) -> Bool {
        (transactionType == .buy) || (transactionType == .sell)
    }
}
