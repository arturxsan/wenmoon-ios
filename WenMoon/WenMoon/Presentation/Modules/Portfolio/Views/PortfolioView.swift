//
//  PortfolioView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.12.24.
//

import SwiftUI

struct PortfolioView: View {
    // MARK: - Properties
    @StateObject private var viewModel = PortfolioViewModel()
    @State private var expandedRows: Set<String> = []
    @State private var swipedTransaction: Transaction?
    @State private var showAddTransactionView = false
    
    private var groupedTransactions: [CoinTransactions] {
        viewModel.groupedTransactions
    }
    
    // MARK: - Body
    var body: some View {
        BaseView(isLoading: $viewModel.isLoading, errorMessage: $viewModel.errorMessage) {
            NavigationView {
                ZStack {
                    VStack {
                        portfolioHeader()
                        portfolioContent()
                    }
                    
                    if viewModel.isLoading {
                        CustomProgressView()
                    } else if groupedTransactions.isEmpty {
                        PlaceholderView(text: "No transactions yet")
                    }
                }
                .animation(.easeInOut, value: groupedTransactions)
                .animation(.easeInOut, value: viewModel.selectedTimeline)
                .navigationTitle("Portfolio")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddTransactionView = true
                        } label: {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddTransactionView) {
            AddTransactionView(didAddTransaction: { newTransaction, coin in
                Task {
                    await viewModel.addTransaction(newTransaction, coin)
                }
            })
            .presentationDetents([UIDevice.current.isSmallScreen ? .fraction(0.7) : .medium])
            .presentationCornerRadius(36)
        }
        .sheet(item: $swipedTransaction, onDismiss: {
            swipedTransaction = nil
        }) { transaction in
            if let coinID = transaction.coinID,
               let coin = viewModel.fetchCoin(by: coinID) {
                AddTransactionView(
                    transaction: transaction,
                    mode: .edit,
                    selectedCoin: coin,
                    didEditTransaction: { updatedTransaction in
                        Task { await viewModel.editTransaction(updatedTransaction) }
                    }
                )
                .presentationDetents([UIDevice.current.isSmallScreen ? .fraction(0.7) : .medium])
                .presentationCornerRadius(36)
            }
        }
        .task {
            await viewModel.fetchPortfolio()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func portfolioHeader() -> some View {
        VStack(spacing: 4) {
            Text(viewModel.totalValue.formattedAsCurrency())
                .font(.largeTitle).bold()
                .foregroundStyle(.white)
            
            HStack {
                HStack {
                    Text(viewModel.portfolioChangePercentage.formattedAsPercentage())
                    Text(viewModel.portfolioChangeValue.formattedAsCurrency(includePlusPrefix: true))
                }
                .font(.footnote).bold()
                .foregroundStyle(viewModel.portfolioChangeColor)
                
                Text(viewModel.selectedTimeline.rawValue)
                    .font(.caption)
                    .foregroundStyle(.softGray)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }
            .onTapGesture {
                viewModel.toggleSelectedTimeline()
            }
        }
        .padding(.vertical, 32)
    }
    
    @ViewBuilder
    private func portfolioContent() -> some View {
        List {
            ForEach(groupedTransactions, id: \.coin.id) { group in
                transactionsSummary(for: group, isExpanded: expandedRows.contains(group.coin.id))
                    .listRowInsets(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8))
                    .onTapGesture {
                        withAnimation {
                            toggleRowExpansion(for: group.coin.id)
                        }
                        viewModel.triggerImpactFeedback()
                    }
                
                if expandedRows.contains(group.coin.id) {
                    expandedTransactions(for: group)
                }
            }
        }
        .listStyle(.plain)
        .tint(.accent)
        .refreshable {
            Task {
                await viewModel.fetchMarketData()
            }
        }
    }
    
    @ViewBuilder
    private func transactionsSummary(for group: CoinTransactions, isExpanded: Bool) -> some View {
        HStack(spacing: 16) {
            CoinImageView(
                imageURL: group.coin.image,
                placeholderText: group.coin.symbol,
                size: 36
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.coin.symbol)
                    .font(.subheadline).bold()
                
                Text(group.totalQuantity.formattedAsQuantity())
                    .font(.caption).bold()
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Text(group.totalValue.formattedAsCurrency())
                .font(.footnote).bold()
            
            Image(systemName: "chevron.up")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(.gray)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .listRowSeparator(.hidden)
        .swipeActions {
            Button(role: .destructive) {
                Task { await viewModel.deleteTransactions(for: group.coin.id) }
            } label: {
                Image("trash.fill")
            }
            .tint(.clear)
        }
        .padding(.vertical)
        .padding(.horizontal, 20)
        .background(Color(.systemGray6))
        .cornerRadius(36)
    }
    
    @ViewBuilder
    private func expandedTransactions(for group: CoinTransactions) -> some View {
        Group {
            ForEach(group.transactions.keys.sorted(by: { $0 > $1 }), id: \.self) { date in
                Text(date.formatted(as: .dateOnly))
                    .font(.subheadline).bold()
                    .foregroundStyle(.gray)
                
                Group {
                    ForEach(group.transactions[date] ?? [], id: \.self) { transaction in
                        transactionRow(group.coin, transaction)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteTransaction(transaction.id) }
                                } label: {
                                    Image("trash")
                                }
                                .tint(.neonPink)
                                
                                Button {
                                    swipedTransaction = transaction.copy()
                                } label: {
                                    Image("pencil")
                                }
                                .tint(.accent)
                            }
                        
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
    }
    
    @ViewBuilder
    private func transactionRow(_ coin: Coin, _ transaction: Transaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.title)
                    .font(.subheadline).bold()
                
                Text(transaction.pricePerCoin.formattedAsCurrency())
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                let isDeductiveTransaction = viewModel.isDeductiveTransaction(transaction.type)
                HStack(spacing: 4) {
                    Text(transaction.quantity.formattedAsQuantity(includeMinusSign: isDeductiveTransaction))
                    Text(coin.symbol)
                }
                .font(.footnote).bold()
                .foregroundStyle(isDeductiveTransaction ? .neonPink : .neonGreen)
                
                Text(transaction.totalCost.formattedAsCurrency())
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Private
    private func toggleRowExpansion(for key: String) {
        if expandedRows.contains(key) {
            expandedRows.remove(key)
        } else {
            expandedRows.insert(key)
        }
    }
}

// MARK: - Preview
#Preview {
    PortfolioView()
        .preferredColorScheme(.dark)
}
