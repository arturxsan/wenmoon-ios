//
//  CoinSelectionView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import SwiftUI

struct CoinSelectionView: View {
    // MARK: - Nested Types
    enum Mode {
        case toggle, selection
    }
    
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: CoinSelectionViewModel
    
    @FocusState private var isTextFieldFocused: Bool
    
    private let mode: Mode
    private let didToggleCoin: ((Coin, Bool) -> Void)?
    private let didSelectCoin: ((Coin) -> Void)?
    
    private var coins: [Coin] { viewModel.coins }
    
    // MARK: - Initializers
    init(
        mode: Mode = .toggle,
        didToggleCoin: ((Coin, Bool) -> Void)? = nil,
        didSelectCoin: ((Coin) -> Void)? = nil
    ) {
        self.mode = mode
        self.didToggleCoin = didToggleCoin
        self.didSelectCoin = didSelectCoin
    }
    
    // MARK: - Body
    var body: some View {
        BaseView(isLoading: $viewModel.isLoading, errorMessage: $viewModel.errorMessage) {
            NavigationView {
                ZStack {
                    ScrollView {
                        LazyVStack {
                            ForEach(coins, id: \.self) { coin in
                                Divider()
                                coinRow(coin)
                                    .task {
                                        await viewModel.fetchCoinsOnNextPageIfNeeded(coin)
                                    }
                            }
                            
                            if viewModel.isLoadingMoreItems {
                                ProgressView()
                            }
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                    
                    if viewModel.isLoading, !viewModel.isLoadingMoreItems {
                        CustomProgressView()
                    }
                    
                    if coins.isEmpty, !viewModel.isLoading {
                        PlaceholderView(text: "No coins found")
                    }
                }
                .background(Color.obsidian)
                .animation(.easeInOut, value: coins)
                .navigationTitle(mode == .toggle ? "Select Coins" : "Select Coin")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { dismiss() }
                    }
                }
                .searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "e.g. Bitcoin"
                )
                .searchFocused($isTextFieldFocused)
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                isTextFieldFocused = false
            }
        )
        .task {
            await viewModel.fetchCoins()
        }
        .onAppear {
            viewModel.fetchSavedCoins()
        }
        .onDisappear {
            viewModel.clearInputFields()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func coinRow(_ coin: Coin) -> some View {
        ZStack(alignment: .leading) {
            Text(coin.marketCapRank.formattedOrNone())
                .font(.caption2)
                .foregroundStyle(.gray)
            
            ZStack(alignment: .trailing) {
                HStack(spacing: 12) {
                    CoinImageView(
                        imageURL: coin.image,
                        placeholderText: coin.symbol,
                        size: 36
                    )
                    
                    Text(coin.symbol)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                if mode == .toggle {
                    Toggle("", isOn: Binding<Bool>(
                        get: { viewModel.isCoinSaved(coin) },
                        set: { isSaved in
                            didToggleCoin?(coin, isSaved)
                            viewModel.toggleSaveState(for: coin)
                        }
                    ))
                    .tint(.neonGreen)
                    .scaleEffect(0.9)
                    .padding(.trailing, -16)
                } else if mode == .selection {
                    Image(systemName: "chevron.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                }
            }
            .padding([.top, .bottom], 4)
            .padding(.leading, 36)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            if mode == .selection {
                didSelectCoin?(coin)
                dismiss()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CoinSelectionView(
        didToggleCoin: { coin, isSaved in
            print("Toggled \(coin.name): \(isSaved)")
        },
        didSelectCoin: { coin in
            print("Selected coin: \(coin.name)")
        }
    )
    .preferredColorScheme(.dark)
    .environmentObject(CoinSelectionViewModel())
    .environmentObject(AuthViewModel())
}
