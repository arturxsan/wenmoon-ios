//
//  ProPaywallViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 24.03.25.
//

import Foundation
import RevenueCat

final class ProPaywallViewModel: BaseViewModel {
    // MARK: - Properties
    @Published var offerings: Offerings?
    @Published var selectedPackage: Package?
    @Published var isPurchasing = false
    @Published var isFetchingOfferings = false
    @Published var purchaseResultMessage: String?
    
    // MARK: - Methods
    func getPackage(from packages: [Package], ofType type: PackageType) -> Package? {
        packages.first(where: { $0.identifier == type.rawValue })
    }
    
    @MainActor
    func fetchOfferings() async {
        isFetchingOfferings = true
        defer { isFetchingOfferings = false }
        
        do {
            let offerings = try await purchasesProvider.offerings()
            self.offerings = offerings
            selectPackage(from: offerings.current, ofType: .weekly)
        } catch {
            setError(error)
        }
    }
    
    func selectPackage(_ package: Package?) {
        selectedPackage = package
        triggerImpactFeedback()
    }
    
    func isPackage(_ package: Package?, ofType type: PackageType) -> Bool {
        package?.identifier == type.rawValue
    }
    
    func isSelectedPackage(ofType type: PackageType) -> Bool {
        selectedPackage?.identifier == type.rawValue
    }
    
    @MainActor
    func purchasePackage() async -> Bool {
        guard let package = selectedPackage else { return false }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        triggerImpactFeedback()
        
        do {
            let (_, customerInfo, _) = try await purchasesProvider.purchase(package: package)
            let isPro = customerInfo.entitlements["Pro"]?.isActive ?? false
            authStateProvider.toggleProAccount(isPro)
            return isPro
        } catch {
            setError(error)
            return false
        }
    }
    
    @MainActor
    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let customerInfo = try await purchasesProvider.restorePurchases()
            let isPro = customerInfo.entitlements["Pro"]?.isActive ?? false
            authStateProvider.toggleProAccount(isPro)
            if !isPro { setErrorMessage("No previous purchases were found.") }
            return isPro
        } catch {
            setError(error)
            return false
        }
    }
    
    func calculateDiscount(from weeklyPackage: Package?, _ annualPackage: Package?) -> String? {
        guard let weeklyPackage,
              let annualPackage,
              let weeklyPricePerYear = weeklyPackage.storeProduct.pricePerYear?.doubleValue,
              let annualPricePerYear = annualPackage.storeProduct.pricePerYear?.doubleValue else {
            return nil
        }
        
        let difference = weeklyPricePerYear - annualPricePerYear
        guard difference > .zero else { return nil }
        let discount = (difference / weeklyPricePerYear) * 100
        let roundedDiscount = discount.rounded(.toNearestOrAwayFromZero)
        
        return roundedDiscount.formattedAsPercentage(includePlusPrefix: false, suffix: "%")
    }
    
    // MARK: - Private
    private func selectPackage(from offering: Offering?, ofType type: PackageType) {
        selectedPackage = offering?.package(identifier: type.rawValue)
    }
}
