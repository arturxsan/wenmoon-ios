//
//  AuthView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 18.03.25.
//

import SwiftUI

struct AuthView: View {
    // MARK: - Properties
    @EnvironmentObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State var title = "Sign Into Your Account"
    @State var subtitle = "Sign in with Apple or Google to sync your watchlist and portfolio\u{FEFF}—or continue anonymously."
    @State var showAnonymousAuthOption = true
    @State var animateOnAppear = false
    @State private var showContentHeight = false
    @State private var showContentOpacity = false
    @State private var showAppleReauthAlert = false
    @State private var appleReauthContinuation: CheckedContinuation<Bool, Never>?
    @State private var showGoogleReauthAlert = false
    @State private var googleReauthContinuation: CheckedContinuation<Bool, Never>?
    
    private var isSmallScreen: Bool {
        UIDevice.current.isSmallScreen
    }
    
    // MARK: - Body
    var body: some View {
        BaseView(isLoading: $viewModel.isLoading, errorMessage: $viewModel.errorMessage) {
            ZStack {
                if animateOnAppear { NeonWavesBackgroundView() }
                
                VStack {
                    let logoSize: CGFloat = showContentHeight ? 48 : 72
                    Image("wenmoon.logo")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: logoSize, height: logoSize)
                    
                    VStack(spacing: 24) {
                        VStack {
                            Text(title)
                                .font(.title3).bold()
                                .padding(.top, 8)
                            
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .frame(height: isSmallScreen ? 40 : nil)
                                .if(isSmallScreen) { view in
                                    view.minimumScaleFactor(0.85)
                                }
                        }
                        
                        authOptions()
                        
                        if showAnonymousAuthOption {
                            HStack(spacing: 16) {
                                VStack { Divider() }
                                Text("or")
                                VStack { Divider() }
                            }
                            
                            VStack {
                                if viewModel.isAnonymousAuthInProgress {
                                    ProgressView()
                                } else {
                                    PrimaryButton(title: "Continue Anonymously", isFullWidth: true) {
                                        Task { await viewModel.signInAnonymously() }
                                    }
                                }
                            }
                            .frame(height: 44)
                        }
                    }
                    .opacity(showContentOpacity ? 1 : .zero)
                    .frame(height: showContentHeight ? nil : .zero)
                    .clipped()
                }
                .padding(.horizontal, 24)
            }
        }
        .alert("Apple ID Already Linked", isPresented: $showAppleReauthAlert) {
            Button("Continue", role: .none) {
                appleReauthContinuation?.resume(returning: true)
                appleReauthContinuation = nil
            }
            Button("Cancel", role: .cancel) {
                appleReauthContinuation?.resume(returning: false)
                appleReauthContinuation = nil
            }
        } message: {
            Text("This Apple ID is already linked to an existing user. To continue, you’ll need to reauthenticate—your anonymous data won’t be saved.")
        }

        .alert("Google Account Already Linked", isPresented: $showGoogleReauthAlert) {
            Button("Continue", role: .none) {
                googleReauthContinuation?.resume(returning: true)
                googleReauthContinuation = nil
            }
            Button("Cancel", role: .cancel) {
                googleReauthContinuation?.resume(returning: false)
                googleReauthContinuation = nil
            }
        } message: {
            Text("This Google account is already linked to an existing user. Please confirm to continue signing in—your anonymous data won’t be saved.")
        }
        .onAppear {
            if animateOnAppear {
                Task {
                    try? await Task.sleep(for: .seconds(0.8))
                    withAnimation { showContentHeight = true }
                    
                    try? await Task.sleep(for: .seconds(0.4))
                    withAnimation { showContentOpacity = true }
                }
            } else {
                showContentHeight = true
                showContentOpacity = true
            }
        }
    }
    
    @ViewBuilder
    private func authOptions() -> some View {
        let authOptions: [AuthOptionsView.AuthOption] = [
            .init(
                imageName: "apple.logo",
                isInProgress: viewModel.isAppleAuthInProgress,
                action: {
                    Task {
                        let isSignedIn = await viewModel.signInWithApple {
                            await withCheckedContinuation { continuation in
                                appleReauthContinuation = continuation
                                showAppleReauthAlert = true
                            }
                        }
                        if isSignedIn { dismiss() }
                    }
                }
            ),
            .init(
                imageName: "google.logo",
                isInProgress: viewModel.isGoogleAuthInProgress,
                action: {
                    Task {
                        let isSignedIn = await viewModel.signInWithGoogle {
                            await withCheckedContinuation { continuation in
                                googleReauthContinuation = continuation
                                showGoogleReauthAlert = true
                            }
                        }
                        if isSignedIn { dismiss() }
                    }
                }
            )
        ]
        AuthOptionsView(options: authOptions)
    }
}

// MARK: - Preview
#Preview {
    AuthView(animateOnAppear: true)
        .preferredColorScheme(.dark)
        .environmentObject(AuthViewModel())
}
