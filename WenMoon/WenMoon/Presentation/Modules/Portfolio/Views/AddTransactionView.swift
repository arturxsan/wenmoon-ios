//
//  AddTransactionView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 27.12.24.
//

import SwiftUI

struct AddTransactionView: View {
    // MARK: - Nested Types
    enum Mode {
        case add, edit
    }
    
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = AddTransactionViewModel()
    @FocusState private var isTextFieldFocused: Bool
    @State private var transaction: Transaction
    @State private var selectedCoin: Coin?
    @State private var showCoinSelectionView = false
    
    private let mode: Mode
    private let didAddTransaction: ((Transaction, Coin?) -> Void)?
    private let didEditTransaction: ((Transaction) -> Void)?
    
    private var isAddMode: Bool { mode == .add }
    private var isEditMode: Bool { mode == .edit }
    
    // MARK: - Initializers
    init(
        transaction: Transaction = Transaction(),
        mode: Mode = .add,
        selectedCoin: Coin? = nil,
        didAddTransaction: ((Transaction, Coin?) -> Void)? = nil,
        didEditTransaction: ((Transaction) -> Void)? = nil
    ) {
        self.transaction = transaction
        self.mode = mode
        self.selectedCoin = selectedCoin
        self.didAddTransaction = didAddTransaction
        self.didEditTransaction = didEditTransaction
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: .zero) {
            ZStack {
                Text(isAddMode ? "Add Transaction" : "Edit Transaction")
                    .font(.headline)
                
                HStack {
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundStyle(.white, Color(.systemGray5))
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
            }
            
            Spacer()
            
            VStack {
                transactionForm($transaction)
                Spacer()
                
                let isAddTransactionButtonDisabled = viewModel.shouldDisableAddTransactionsButton(for: transaction)
                PrimaryButton(
                    title: isAddMode ? "Add Transaction" : "Edit Transaction",
                    isDisabled: isAddTransactionButtonDisabled
                ) {
                    switch mode {
                    case .add:
                        didAddTransaction?(transaction, selectedCoin)
                    case .edit:
                        didEditTransaction?(transaction)
                    }
                    viewModel.triggerImpactFeedback()
                    dismiss()
                }
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
            )
        }
        .padding(.bottom, UIDevice.current.isSmallScreen ? 24 : 16)
        .background(Color.obsidian)
        .sheet(isPresented: $showCoinSelectionView) {
            CoinSelectionView(mode: .selection, didSelectCoin: { selectedCoin in
                transaction.coinID = selectedCoin.id
                transaction.pricePerCoin = selectedCoin.currentPrice
                self.selectedCoin = selectedCoin
            })
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func transactionForm(_ transactionBinding: Binding<Transaction>) -> some View {
        VStack(spacing: 16) {
            Button {
                showCoinSelectionView = true
            } label: {
                HStack {
                    if let coin = selectedCoin {
                        HStack(spacing: 12) {
                            CoinImageView(
                                imageURL: coin.image,
                                placeholderText: coin.symbol,
                                size: 36
                            )
                            
                            Text(coin.symbol)
                                .font(.headline)
                                .foregroundStyle(isEditMode ? .accent : .white)
                        }
                    } else {
                        Text("Select Coin")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                }
                .frame(height: 36)
            }
            .tint(.accent)
            .font(.headline)
            .disabled(isEditMode)
            
            HStack(spacing: .zero) {
                TextField("Quantity", value: transactionBinding.quantity, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($isTextFieldFocused)
                    .textFieldStyle(UnderlinedTextFieldStyle())
                    .font(.headline)
                
                Text("×")
                    .bold()
                    .foregroundStyle(.gray)
            }
            
            if viewModel.isPriceFieldRequired(for: transactionBinding.wrappedValue.type) {
                HStack(spacing: .zero) {
                    TextField("Price per Coin", value: transactionBinding.pricePerCoin, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(UnderlinedTextFieldStyle())
                        .font(.headline)
                    
                    Text("$")
                        .foregroundStyle(.gray)
                }
            }
            
            DatePicker(
                "Date",
                selection: transactionBinding.date,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(.headline)
            
            HStack {
                Text("Type")
                    .font(.headline)
                
                Spacer()
                
                Picker("", selection: transactionBinding.type) {
                    ForEach(Transaction.TransactionType.allCases, id: \.self) { type in
                        Text(type.title).tag(type)
                    }
                }
                .tint(.white)
            }
        }
        .padding(.horizontal)
        .onChange(of: transactionBinding.wrappedValue.type) { _, type in
            if !viewModel.isPriceFieldRequired(for: type) {
                transactionBinding.pricePerCoin.wrappedValue = nil
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AddTransactionView()
        .preferredColorScheme(.dark)
}
