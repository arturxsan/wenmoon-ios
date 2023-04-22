//
//  ContentView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.11.24.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var coinSelectionViewModel = CoinSelectionViewModel()
    @State private var scrollMarqueeText = false
    @State private var showPaywallView = false
    
    // MARK: - Body
    var body: some View {
        VStack {
            if authViewModel.firebaseUser.isNil {
                AuthView(animateOnAppear: true)
            } else {
                HStack {
                    ForEach(viewModel.globalMarketDataItems, id: \.self) { item in
                        globalMarketItem(item)
                    }
                }
                .frame(width: 850, height: 20)
                .offset(x: scrollMarqueeText ? -650 : 650)
                .animation(
                    .linear(duration: 20).repeatForever(autoreverses: false),
                    value: scrollMarqueeText
                )
                
                TabView(selection: $viewModel.startScreenIndex) {
                    WatchlistView()
                        .tabItem { Image("coins") }
                        .tag(0)
                    PortfolioView()
                        .tabItem { Image("bag") }
                        .tag(1)
                    CryptoCompareView()
                        .tabItem { Image("arrows.swap") }
                        .tag(2)
                    NewsView()
                        .tabItem { Image("news") }
                        .tag(3)
                    SettingsView()
                        .tabItem { Image("person") }
                        .tag(4)
                }
                .onDisappear {
                    viewModel.fetchStartScreen()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidRegisterForRemoteNotifications)) { _ in
            if authViewModel.account.isNotNil {
                Task { await authViewModel.setActiveAccount() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidTriggerPaywall)) { _ in
            showPaywallView = true
        }
        .fullScreenCover(isPresented: $showPaywallView) {
            ProPaywallView()
                .presentationCornerRadius(36)
        }
        .onChange(of: viewModel.account?.id) { _, id in
            guard id.isNotNil else { return }
            
            Task {
//                try? await Task.sleep(for: .seconds(1))
//                viewModel.checkProStatus()
                fetchGlobalMarketDataItems()
                await viewModel.setupNotificationsIfNeeded()
            }
        }
        .task {
            await authViewModel.fetchAccount()
            
            try? await Task.sleep(for: .seconds(3))
            viewModel.showReviewPromptIfNeeded()
        }
        .tint(.accent)
        .animation(.easeInOut, value: authViewModel.firebaseUser)
        .environmentObject(authViewModel)
        .environmentObject(settingsViewModel)
        .environmentObject(coinSelectionViewModel)
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func globalMarketItem(_ item: GlobalMarketDataItem) -> some View {
        HStack(spacing: 4) {
            Text(item.type.title)
                .font(.footnote)
                .foregroundStyle(.softGray)
            Text(item.value)
                .font(.footnote).bold()
        }
    }
    
    // MARK: - Private
    private func fetchGlobalMarketDataItems() {
        scrollMarqueeText = false
        Task {
            await viewModel.fetchAllGlobalMarketData()
            await MainActor.run {
                scrollMarqueeText = viewModel.isAllMarketDataItemsFetched
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
