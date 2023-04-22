//
//  SettingsView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.11.24.
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    // MARK: - Properties
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var selectedSetting: Setting!
    @State private var selectedLink: IdentifiableLink?
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showAppResetConfirmation = false
    @State private var showMailView = false
    @State private var showMailUnavailableAlert = false
    
    private var isLoading: Binding<Bool> {
        Binding(
            get: { viewModel.isLoading || authViewModel.isLoading },
            set: { _ in }
        )
    }
    
    private var isSmallScreen: Bool {
        UIDevice.current.isSmallScreen
    }
    
    // MARK: - Body
    var body: some View {
        BaseView(isLoading: isLoading, errorMessage: $viewModel.errorMessage) {
            NavigationView {
                ZStack {
                    VStack(spacing: 24) {
                        authView()
                        
                        List {
                            ForEach(SettingType.Section.allCases, id: \.self) { section in
                                if let sectionSettings = viewModel.groupedSettings[section] {
                                    Section(header: Text(section.rawValue)) {
                                        ForEach(sectionSettings) { setting in
                                            settingsRow(setting)
                                        }
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                    .padding(.bottom, isSmallScreen ? 24 : 16)
                    
                    if authViewModel.isLoading {
                        CustomProgressView()
                    }
                }
                .toolbar {
                    if let account = viewModel.account, !account.isAnonymous {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showSignOutConfirmation = true
                                viewModel.triggerImpactFeedback()
                            } label: {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedSetting, onDismiss: {
            selectedSetting = nil
        }) { setting in
            SelectionView(
                selectedOption: setupSettingsBinding(setting),
                title: setting.type.title,
                options: setting.type.options
            )
            .presentationDetents([isSmallScreen ? .fraction(0.55) : .fraction(0.45)])
            .presentationCornerRadius(36)
        }
        .sheet(isPresented: $showMailView) {
            MailView(
                subject: "WenMoon Support Request",
                body: """
                Hi WenMoon Team,

                I’d like to report an issue or ask a question:

                [Please describe your issue here]

                ---
                🛠 App Version: \(Constants.appVersion)
                🍏 iOS Version: \(UIDevice.current.systemVersion)
                """,
                recipient: "contact@climbthatapp.com"
            )
        }
        .sheet(item: $selectedLink, onDismiss: {
            selectedLink = nil
        }) { link in
            SafariView(url: link.url)
        }
        .alert("Mail not available", isPresented: $showMailUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please set up a mail account in your iOS settings")
        }
        .alert(isPresented: $showSignOutConfirmation) {
            Alert(
                title: Text("Logging off?"),
                message: Text("Take your time! Everything will be here when you return."),
                primaryButton: .destructive(Text("Sign Out")) {
                    Task { await authViewModel.signOut() }
                },
                secondaryButton: .cancel(Text("Stay Logged In"))
            )
        }
        .confirmationDialog(
            "Deleting your account is permanent and will remove all your data, such as your watchlist, transactions, and price alerts.",
            isPresented: $showDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task { await authViewModel.deleteAccount() }
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Resetting the app will clear any saved watchlist, portfolio, or price alerts, if you have them.",
            isPresented: $showAppResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Start Fresh", role: .destructive) {
                Task { await authViewModel.deleteAccount() }
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: viewModel.account) { _, account in
            guard account.isNotNil else { return }
            viewModel.fetchSettings()
        }
        .onAppear {
            viewModel.fetchSettings()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func authView() -> some View {
        VStack {
            if let account = viewModel.account, !account.isAnonymous {
                VStack {
                    Image("wenmoon.logo")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                    
                    HStack {
                        Text(account.username)
                            .font(.title3).bold()
                        
//                        if account.isPro {
//                            Image(systemName: "checkmark.seal.fill")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 20, height: 20)
//                                .foregroundStyle(.accent)
//                        }
                    }
                    .padding(.leading, account.isPro ? 20 : .zero)
                }
            } else {
                AuthView(
                    title: "Sign Into a Real Account",
                    subtitle: "Your anonymous portfolio, alerts, and watchlist stay local\u{FEFF}—sign in to sync them!",
                    showAnonymousAuthOption: false
                )
            }
        }
        .padding(.top, isSmallScreen ? 8 : 24)
    }
    
    @ViewBuilder
    private func settingsRow(_ setting: Setting) -> some View {
        let settingType = setting.type
        HStack(spacing: 12) {
            image(forType: settingType)
            Text(settingType.title)
            
            Spacer()
            
            if settingType == .version {
                Text(Constants.appVersion)
                    .font(.callout)
                    .foregroundStyle(.gray)
            } else {
                if let selectedOption = setting.selectedOption {
                    let selectedOptionTitle = viewModel.getSettingOptionTitle(for: settingType, with: selectedOption)
                    Text(selectedOptionTitle)
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
                
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            switch settingType {
//            case .pro:
//                NotificationCenter.default.post(name: .userDidTriggerPaywall, object: nil)
            case .feedback:
                openURL(Constants.Links.feedbackURL)
            case .deleteAccount:
                showDeleteAccountConfirmation = true
                viewModel.triggerImpactFeedback()
            case .resetAppData:
                showAppResetConfirmation = true
                viewModel.triggerImpactFeedback()
            case .privacy:
                selectedLink = IdentifiableLink(url: Constants.Links.privacyURL)
            case .terms:
                selectedLink = IdentifiableLink(url: Constants.Links.termsURL)
            case .support:
                if MFMailComposeViewController.canSendMail() {
                    showMailView = true
                } else {
                    showMailUnavailableAlert = true
                }
            default:
                selectedSetting = setting
            }
        }
        .disabled(settingType == .version)
    }
    
    // MARK: - Private
    private func setupSettingsBinding(_ setting: Setting) -> Binding<Int> {
        Binding(
            get: {
                viewModel.getSetting(of: setting.type)?.selectedOption ?? .zero
            },
            set: { newValue in
                viewModel.updateSetting(of: setting.type, with: newValue)
            }
        )
    }
    
    @ViewBuilder
    private func image(
        forType type: SettingType,
        isSystem: Bool = true,
        size: CGFloat = 20
    ) -> some View {
        let imageName = type.imageName
        let color = type.color
        (isSystem ? Image(systemName: imageName) : Image(imageName))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color)
            .shadow(color: color, radius: 2)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
        .environmentObject(SettingsViewModel())
        .environmentObject(AuthViewModel())
}
