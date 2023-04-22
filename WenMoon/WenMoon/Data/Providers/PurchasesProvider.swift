//
//  PurchasesProvider.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 23.03.25.
//

import Foundation
import RevenueCat

// MARK: - PackageType
enum PackageType: String {
    case weekly = "$rc_weekly"
    case annual = "$rc_annual"
    
    var title: String {
        switch self {
        case .weekly: return "Weekly"
        case .annual: return "Yearly"
        }
    }
}

// MARK: - PurchasesProvider
protocol PurchasesProvider {
    func customerInfo() async throws -> CustomerInfo
    func logIn(_ appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool)
    func logOut() async throws -> CustomerInfo
    func offerings() async throws -> Offerings
    func purchase(package: Package) async throws -> PurchaseResultData
    func restorePurchases() async throws -> CustomerInfo
}

// MARK: - DefaultPurchasesManager
final class DefaultPurchasesManager: PurchasesProvider {
    private let provider: PurchasesProvider
    
    init(provider: PurchasesProvider = Purchases.shared) {
        self.provider = provider
    }
    
    func customerInfo() async throws -> CustomerInfo {
        try await provider.customerInfo()
    }
    
    func logIn(_ appUserID: String) async throws -> (customerInfo: CustomerInfo, created: Bool) {
        try await provider.logIn(appUserID)
    }

    func logOut() async throws -> CustomerInfo {
        try await provider.logOut()
    }
    
    func offerings() async throws -> Offerings {
        try await provider.offerings()
    }
    
    func purchase(package: Package) async throws -> PurchaseResultData {
        try await provider.purchase(package: package)
    }
    
    func restorePurchases() async throws -> CustomerInfo {
        try await provider.restorePurchases()
    }
}

// MARK: - RevenueCat Purchases (Singleton)
extension Purchases: PurchasesProvider {}
