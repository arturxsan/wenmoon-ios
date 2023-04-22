//
//  ProPaywallView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 24.03.25.
//

import SwiftUI
import RevenueCat

struct ProPaywallView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = ProPaywallViewModel()
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false
    @State private var showCloseButton = false
    @State private var closeProgress: CGFloat = .zero
    
    private let closeDelay: CGFloat = 5
    
    private var isSmallScreen: Bool {
        let device = UIDevice.current
        return device.isSmallScreen || device.isSemiSmallScreen
    }
    
    // MARK: - Body
    var body: some View {
        BaseView(isLoading: $viewModel.isLoading, errorMessage: $viewModel.errorMessage) {
            ZStack {
                ZStack(alignment: .top) {
                    let size: CGFloat = isSmallScreen ? 250 : 300
                    LottieView(animationName: "paywallAnimation", loopMode: .loop)
                        .frame(width: size, height: size)
                        .padding(.top, -24)
                    
                    VStack(spacing: .zero) {
                        HStack {
                            Spacer()
                            
                            ZStack {
                                if showCloseButton {
                                    Button {
                                        dismiss()
                                    } label: {
                                        Image(systemName: "xmark")
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundStyle(Color(.systemGray4))
                                    }
                                } else {
                                    Circle()
                                        .trim(from: .zero, to: closeProgress)
                                        .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                        .frame(width: 20, height: 20)
                                        .animation(.linear(duration: 0.05), value: closeProgress)
                                }
                            }
                            .padding(.top)
                        }
                        
                        let ratio = isSmallScreen ? 1.5 : 1.25
                        Spacer(minLength: size / ratio)
                        
                        Text("Get WenMoon Pro")
                            .font(.title)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            featureItem(title: "Unlimited coin tracking & alerts", systemImageName: "infinity")
                            featureItem(title: "Access all market comparison tools", systemImageName: "chart.bar")
                            featureItem(title: "Remove annoying paywalls", systemImageName: "lock.rectangle.stack")
                        }
                        .padding(.vertical)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: .zero)
                        
                        Group {
                            if viewModel.isFetchingOfferings {
                                Spacer()
                                ProgressView()
                                Spacer()
                                
                            } else if let currentOffering = viewModel.offerings?.current,
                                      !currentOffering.availablePackages.isEmpty {
                                subscriptionOptions(packages: currentOffering.availablePackages)
                            }
                        }
                        .padding(.top, isSmallScreen ? 16 : 24)
                    }
                    .padding(.horizontal)
                }
                
                if viewModel.isLoading {
                    CustomProgressView()
                }
            }
            .animation(.easeInOut, value: viewModel.selectedPackage)
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            SafariView(url: Constants.Links.privacyURL)
        }
        .sheet(isPresented: $showTermsOfUse) {
            SafariView(url: Constants.Links.termsURL)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
                if closeProgress < 1 {
                    closeProgress += 0.05 / closeDelay
                } else {
                    timer.invalidate()
                    showCloseButton = true
                }
            }
        }
        .task {
            await viewModel.fetchOfferings()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func subscriptionOptions(packages: [Package]) -> some View {
        let weeklyPackage = viewModel.getPackage(from: packages, ofType: .weekly)
        let annualPackage = viewModel.getPackage(from: packages, ofType: .annual)
        
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                subscriptionOption(
                    ofType: .weekly,
                    weeklyPackage: weeklyPackage,
                    annualPackage: annualPackage,
                    isSelected: viewModel.isSelectedPackage(ofType: .weekly),
                    isFreeTrialAvailable: true
                )
                .onTapGesture {
                    viewModel.selectPackage(weeklyPackage)
                }
                
                subscriptionOption(
                    ofType: .annual,
                    weeklyPackage: weeklyPackage,
                    annualPackage: annualPackage,
                    isSelected: viewModel.isSelectedPackage(ofType: .annual)
                )
                .onTapGesture {
                    viewModel.selectPackage(annualPackage)
                }
            }
            
            HStack {
                Text("Free Trial Enabled")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Toggle("", isOn: Binding<Bool>(
                    get: { viewModel.isSelectedPackage(ofType: .weekly) },
                    set: { isOn in
                        viewModel.selectedPackage = isOn ? weeklyPackage : annualPackage
                    }
                ))
                .tint(.neonGreen)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            VStack {
                if viewModel.isPurchasing {
                    ProgressView()
                } else {
                    PrimaryButton(title: "Continue", isFullWidth: true) {
                        Task {
                            let isPurchaseSuccessful = await viewModel.purchasePackage()
                            if isPurchaseSuccessful { dismiss() }
                        }
                    }
                }
            }
            .frame(height: 44)
            
            HStack(spacing: 20) {
                Button {
                    Task {
                        let isRestoreSuccessful = await viewModel.restorePurchases()
                        if isRestoreSuccessful { dismiss() }
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.footnote)
                        .foregroundStyle(.primary)
                }
                
                HStack(spacing: 20) {
                    Button("Privacy") { showPrivacyPolicy = true }
                    Button("Terms") { showTermsOfUse = true }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .frame(height: 20)
            .padding(.bottom, isSmallScreen ? 24 : 16)
        }
    }
    
    @ViewBuilder
    private func subscriptionOption(
        ofType type: PackageType,
        weeklyPackage: Package?,
        annualPackage: Package?,
        isSelected: Bool,
        isFreeTrialAvailable: Bool = false
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: .zero) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let weekly = weeklyPackage,
                       let annual = annualPackage,
                       let code = weekly.storeProduct.currencyCode?.lowercased(),
                       let symbol = viewModel.getCurrencySymbol(from: code) {
                        
                        switch type {
                        case .weekly:
                            if let price = weekly.storeProduct.pricePerWeek {
                                priceLabel("\(symbol)\(price)")
                            }
                        case .annual:
                            if let price = annual.storeProduct.pricePerYear {
                                priceLabel("\(symbol)\(price)")
                            }
                            
                            HStack(spacing: 4) {
                                if let originalPrice = weekly.storeProduct.pricePerYear {
                                    strikethroughLabel("\(symbol)\(originalPrice)")
                                    
                                    if let discount = viewModel.calculateDiscount(from: weekly, annual) {
                                        discountLabel("SAVE \(discount)")
                                    }
                                }
                            }
                            .if(isSmallScreen) { view in
                                view.minimumScaleFactor(0.85)
                            }
                        }
                    }
                }
                
                Spacer(minLength: .zero)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .fill((isSelected ? Color.accent : .clear).opacity(0.1))
                    .stroke(isSelected ? .accent : .secondary, lineWidth: 1)
            }
            
            VStack {
                if isSelected {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.accent)
                } else {
                    Image(systemName: "circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(.gray)
                }
            }
            .padding(12)
        }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func featureItem(
        title: String,
        imageName: String? = nil,
        systemImageName: String? = nil,
        imageSize: CGFloat = 24,
        imageColor: Color = .accent
    ) -> some View {
        HStack {
            VStack {
                if let imageName {
                    image(
                        named: imageName,
                        isSystem: false,
                        size: imageSize,
                        color: imageColor
                    )
                } else if let systemImageName {
                    image(
                        named: systemImageName,
                        isSystem: true,
                        size: imageSize,
                        color: imageColor
                    )
                }
            }
            .frame(width: 24, height: 24)
            
            Text(title)
        }
    }
    
    @ViewBuilder
    private func image(
        named name: String,
        isSystem: Bool,
        size: CGFloat,
        color: Color
    ) -> some View {
        (isSystem ? Image(systemName: name) : Image(name))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color)
    }
    
    @ViewBuilder
    private func priceLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.primary)
        Spacer()
    }
    
    @ViewBuilder
    private func strikethroughLabel(_ text: String) -> some View {
        Text(text)
            .strikethrough()
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private func discountLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.black)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.neonGreen)
            .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    ProPaywallView()
        .preferredColorScheme(.dark)
}
