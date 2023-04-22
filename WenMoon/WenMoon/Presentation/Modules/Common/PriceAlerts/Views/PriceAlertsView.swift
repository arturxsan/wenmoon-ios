//
//  PriceAlertsView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 28.11.24.
//

import SwiftUI

struct PriceAlertsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var viewModel = PriceAlertsViewModel()
    @FocusState private var isTextFieldFocused: Bool
    @State private var targetPrice: Double?
    @State private var coin: Coin
    @State private var showNotificationPermissionsAlert = false
    
    private var priceAlerts: [PriceAlert] { coin.priceAlerts }
    
    // MARK: - Initializers
    init(coin: Coin) {
        self._coin = State(initialValue: coin)
    }
    
    // MARK: - Body
    var body: some View {
        BaseView(isLoading: $viewModel.isLoading, errorMessage: $viewModel.errorMessage) {
            VStack(spacing: .zero) {
                header()
                priceInput()
                Spacer()
                
                if priceAlerts.isEmpty {
                    PlaceholderView(text: "No price alerts yet")
                } else {
                    priceAlertList()
                }
            }
            .background(Color.obsidian)
            .animation(.easeInOut, value: priceAlerts)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                isTextFieldFocused = false
            }
        )
        .alert(isPresented: $showNotificationPermissionsAlert) {
            Alert(
                title: Text("Notifications Disabled"),
                message: Text("To get price alerts, head to Settings and turn on notifications. Hit Enable to start?"),
                primaryButton: .default(Text("Enable")) {
                    Task {
                        await viewModel.promptForNotificationPermission()
                    }
                },
                secondaryButton: .cancel(Text("Not Now"))
            )
        }
        .onAppear {
            targetPrice = coin.currentPrice
        }
    }
    
    @ViewBuilder
    private func header() -> some View {
        ZStack {
            Text("Price Alerts")
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
    }
    
    @ViewBuilder
    private func priceInput() -> some View {
        VStack(spacing: .zero) {
            let targetDirection = viewModel.getTargetDirection(
                for: targetPrice ?? .zero,
                currentPrice: coin.currentPrice
            )
            let isDisabled = viewModel.shouldDisableCreateButton(
                priceAlerts: coin.priceAlerts,
                targetPrice: targetPrice,
                targetDirection: targetDirection
            )
            
            HStack(spacing: .zero) {
                let targetDirection = viewModel.getTargetDirection(
                    for: targetPrice ?? .zero,
                    currentPrice: coin.currentPrice
                )
                Image(targetDirection.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(targetDirection.color)
                
                TextField("Enter Target Price", value: $targetPrice, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($isTextFieldFocused)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(UnderlinedTextFieldStyle())
                    .font(.headline)
                
                Text("$")
                    .foregroundStyle(.gray)
            }
            .padding(.bottom, isDisabled ? .zero : 32)
            
            if isDisabled {
                Text("Alert already exists for this price")
                    .font(.caption)
                    .foregroundStyle(.neonPink)
                    .frame(height: 16)
                    .padding(8)
            }
            
            createAlertButton(isDisabled)
        }
        .padding(.horizontal, 48)
        .padding(.bottom, priceAlerts.isEmpty ? .zero : 16)
    }
    
    @ViewBuilder
    private func createAlertButton(_ isDisabled: Bool) -> some View {
        VStack {
            if viewModel.isCreatingPriceAlert {
                ProgressView()
            } else {
                PrimaryButton(title: "Create Alert", isDisabled: isDisabled) {
                    guard viewModel.isNotificationsEnabled else {
                        showNotificationPermissionsAlert = true
                        return
                    }
                    
                    if let targetPrice {
                        Task {
                            await viewModel.createPriceAlert(for: coin, targetPrice: targetPrice)
                        }
                    }
                }
            }
        }
        .frame(height: 44)
        .animation(.easeInOut, value: isDisabled)
    }
    
    @ViewBuilder
    private func priceAlertList() -> some View {
        List {
            ForEach(priceAlerts, id: \.id) { priceAlert in
                priceAlertRow(priceAlert)
            }
        }
        .listStyle(.plain)
        .scrollBounceBehavior(.basedOnSize)
    }
    
    @ViewBuilder
    private func priceAlertRow(_ priceAlert: PriceAlert) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(priceAlert.symbol)
                
                HStack {
                    let targetDirection = priceAlert.targetDirection
                    Image(targetDirection.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(targetDirection.color)
                    
                    Text(priceAlert.targetPrice.formattedAsCurrency())
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding<Bool>(
                get: { priceAlert.isActive && viewModel.isNotificationsEnabled },
                set: { isActive in
                    guard !isActive || viewModel.isNotificationsEnabled else {
                        showNotificationPermissionsAlert = true
                        return
                    }
                    
                    Task {
                        await viewModel.updatePriceAlert(priceAlert.id, isActive: isActive, for: coin)
                    }
                }
            ))
            .tint(.neonGreen)
            .scaleEffect(0.9)
            .padding(.trailing, -16)
        }
        .listRowBackground(Color.obsidian)
        .swipeActions {
            Button(role: .destructive) {
                Task {
                    await viewModel.deletePriceAlert(priceAlert.id, for: coin)
                }
            } label: {
                Image("trash")
            }
            .tint(.neonPink)
        }
    }
}

// MARK: - Preview
#Preview {
    PriceAlertsView(coin: Coin())
        .preferredColorScheme(.dark)
}
