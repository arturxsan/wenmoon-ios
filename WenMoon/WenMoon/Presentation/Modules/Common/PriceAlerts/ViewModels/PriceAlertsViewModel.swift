//
//  PriceAlertsViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 28.11.24.
//

import Foundation

final class PriceAlertsViewModel: BaseViewModel {
    // MARK: - Properties
    private let service: PriceAlertService
    
    @Published private(set) var isCreatingPriceAlert = false
    
    // MARK: - Initializers
    convenience init() {
        self.init(service: PriceAlertServiceImpl())
    }
    
    init(
        service: PriceAlertService,
        authStateProvider: AuthStateProvider? = nil,
        notificationProvider: NotificationProvider? = nil
    ) {
        self.service = service
        super.init(authStateProvider: authStateProvider, notificationProvider: notificationProvider)
    }
    
    // MARK: - Methods
    @MainActor
    func fetchPriceAlerts() async -> [PriceAlert] {
        do {
            guard let authToken = try await authStateProvider.fetchAuthToken() else { return [] }
            let priceAlerts = try await service.getPriceAlerts(authToken: authToken, deviceToken: deviceToken)
            return priceAlerts
        } catch {
            setError(error)
            return []
        }
    }
    
    @MainActor
    func createPriceAlert(for coin: Coin, targetPrice: Double) async {
        guard let deviceToken else {
            print("Device token is missing")
            return
        }
        
        isCreatingPriceAlert = true
        defer { isCreatingPriceAlert = false }
        
        triggerImpactFeedback()
        
//        let fetchedPriceAlerts = await fetchPriceAlerts()
//        if fetchedPriceAlerts.count >= 5 {
//            guard checkProStatus() else { return }
//        }
        
        let currentPrice = coin.currentPrice ?? .zero
        
        do {
            let priceAlert = PriceAlert(
                id: UUID().uuidString,
                coinID: coin.id,
                symbol: coin.symbol,
                targetPrice: targetPrice,
                targetDirection: targetPrice >= currentPrice ? .above : .below,
                isActive: true
            )
            
            guard let authToken = try await authStateProvider.fetchAuthToken() else { return }
            let createdPriceAlert = try await service.createPriceAlert(
                priceAlert,
                authToken: authToken,
                deviceToken: deviceToken
            )
            
            coin.priceAlerts.append(createdPriceAlert)
            coin.priceAlerts.sort { $0.targetPrice > $1.targetPrice }
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func updatePriceAlert(_ id: String, isActive: Bool, for coin: Coin) async {
        do {
            guard let authToken = try await authStateProvider.fetchAuthToken() else { return }
            let updatedPriceAlert = try await service.updatePriceAlert(
                id,
                isActive: isActive,
                authToken: authToken
            )
            
            if let index = coin.priceAlerts.firstIndex(where: { $0.id == updatedPriceAlert.id }) {
                coin.priceAlerts[index].isActive = updatedPriceAlert.isActive
            }
        } catch {
            setError(error)
        }
    }
    
    @MainActor
    func deletePriceAlert(_ id: String, for coin: Coin) async {
        do {
            guard let authToken = try await authStateProvider.fetchAuthToken() else { return }
            let deletedPriceAlert = try await service.deletePriceAlert(id, authToken: authToken)
            
            if let index = coin.priceAlerts.firstIndex(where: { $0.id == deletedPriceAlert.id }) {
                coin.priceAlerts.remove(at: index)
            }
        } catch {
            setError(error)
        }
    }
    
    func shouldDisableCreateButton(
        priceAlerts: [PriceAlert],
        targetPrice: Double?,
        targetDirection: PriceAlert.TargetDirection
    ) -> Bool {
        guard let targetPrice, !targetPrice.isZero else { return true }

        return priceAlerts.contains { alert in
            alert.targetPrice == targetPrice && alert.targetDirection == targetDirection
        }
    }
    
    func getTargetDirection(for targetPrice: Double, currentPrice: Double?) -> PriceAlert.TargetDirection {
        targetPrice >= (currentPrice ?? .zero) ? .above : .below
    }
}
