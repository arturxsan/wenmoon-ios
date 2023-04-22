//
//  BaseViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 20.06.23.
//

import SwiftUI
import SwiftData
import Combine
import FirebaseAuth
import StoreKit

class BaseViewModel: ObservableObject {
    // MARK: - Properties
    @Environment(\.openURL) var openURL
    
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isNotificationsEnabled = false
    @Published var account: Account?
    
    private(set) var authStateProvider: AuthStateProvider
    private(set) var purchasesProvider: PurchasesProvider
    private(set) var notificationProvider: NotificationProvider
    private(set) var swiftDataManager: SwiftDataManager?
    private(set) var userDefaultsManager: UserDefaultsManager
    
    private var cancellables = Set<AnyCancellable>()
    
    var firebaseUser: User? {
        authStateProvider.firebaseUser
    }
    
    var deviceToken: String? {
        notificationProvider.getDeviceToken()
    }
    
    // MARK: - Initializers
    init(
        authStateProvider: AuthStateProvider? = nil,
        purchasesProvider: PurchasesProvider? = nil,
        notificationProvider: NotificationProvider? = nil,
        swiftDataManager: SwiftDataManager? = nil,
        userDefaultsManager: UserDefaultsManager? = nil
    ) {
        let authStateProvider = authStateProvider ?? DefaultAuthStateManager()
        self.authStateProvider = authStateProvider
        self.purchasesProvider = purchasesProvider ?? DefaultPurchasesManager()
        self.notificationProvider = notificationProvider ?? DefaultNotificationManager()
        self.userDefaultsManager = userDefaultsManager ?? UserDefaultsManagerImpl()
        
        if let swiftDataManager {
            self.swiftDataManager = swiftDataManager
        } else {
            if let modelContainer = try? ModelContainer(for: Coin.self, Portfolio.self, Transaction.self) {
                self.swiftDataManager = SwiftDataManagerImpl(modelContainer: modelContainer)
            }
        }
        
        if case .authenticated(let account) = authStateProvider.authState {
            self.account = account
        } else {
            account = nil
        }
        
        setupObservers()
        Task { await checkNotificationStatus() }
    }
    
    // MARK: - Push Notifications
    func setupNotificationsIfNeeded() async {
        await notificationProvider.setupNotificationsIfNeeded()
    }
    
    @MainActor
    func checkNotificationStatus() async {
        isNotificationsEnabled = await notificationProvider.isNotificationsEnabled()
        if isNotificationsEnabled {
            let application = UIApplication.shared
            guard application.isRegisteredForRemoteNotifications else {
                await notificationProvider.registerForPushNotifications()
                return
            }
        }
    }
    
    @MainActor
    func promptForNotificationPermission() async {
        do {
            let granted = try await requestNotificationPermission()
            if !granted, let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        } catch {
            setError(error)
        }
    }
    
    func requestNotificationPermission() async throws -> Bool {
        let granted = try await notificationProvider.requestPermission()
        await MainActor.run { isNotificationsEnabled = granted }
        return granted
    }
    
    // MARK: - Observers
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: .appDidBecomeActive,
            object: nil
        )
        
        authStateProvider.authStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] newAuthState in
                if case .authenticated(let account) = newAuthState {
                    self?.account = account
                } else {
                    self?.account = nil
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func appDidBecomeActive(_ notification: Notification) {
        Task { await checkNotificationStatus() }
        notificationProvider.resetBadgeNumber()
    }
    
    // MARK: - SwiftData
    func safeFetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        do {
            return try fetch(descriptor)
        } catch {
            setError(error)
            return []
        }
    }
    
    func safeInsert<T: PersistentModel>(_ model: T) {
        do {
            try insert(model)
        } catch {
            setError(error)
        }
    }
    
    func safeDelete<T: PersistentModel>(_ model: T) {
        do {
            try delete(model)
        } catch {
            setError(error)
        }
    }
    
    func safeSave() {
        do {
            try save()
        } catch {
            setError(error)
        }
    }
    
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        try swiftDataManager?.fetch(descriptor) ?? []
    }
    
    func insert<T: PersistentModel>(_ model: T) throws {
        try swiftDataManager?.insert(model)
    }
    
    func delete<T: PersistentModel>(_ model: T) throws {
        try swiftDataManager?.delete(model)
    }
    
    func save() throws {
        try swiftDataManager?.save()
    }
    
    func purgeLocalStorage() {
        userDefaultsManager.removeObject(forKey: .coinsOrder)
        
        let coinDescriptor = FetchDescriptor<Coin>()
        let coins = safeFetch(coinDescriptor)
        for coin in coins {
            safeDelete(coin)
        }
        
        let portfolioDescriptor = FetchDescriptor<Portfolio>()
        let portfolios = safeFetch(portfolioDescriptor)
        for portfolio in portfolios {
            safeDelete(portfolio)
        }
    }
    
    // MARK: - Misc
    func checkProStatus() -> Bool {
        guard let account, account.isPro else {
            NotificationCenter.default.post(name: .userDidTriggerPaywall, object: nil)
            return false
        }
        return true
    }
    
    @MainActor
    func showReviewPromptIfNeeded() {
        let lastPromptDate = (try? userDefaultsManager.getObject(forKey: .lastReviewPromptDate, objectType: Date.self)) ?? .distantPast
        let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPromptDate, to: .now).day ?? .zero
        
        if daysSinceLastPrompt >= 7 {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                AppStore.requestReview(in: scene)
                try? userDefaultsManager.setObject(Date(), forKey: .lastReviewPromptDate)
            }
        }
    }
    
    @MainActor
    func loadImage(from url: URL) async -> Data? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            setErrorMessage("Error downloading image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func setError(_ error: Error) {
        if let descriptiveError = error as? DescriptiveError {
            errorMessage = descriptiveError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    func setErrorMessage(_ message: String) {
        errorMessage = message
    }
    
    func getCurrencySymbol(from currencyCode: String) -> String? {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currencyCode]))
        return locale.currencySymbol
    }
    
    func triggerImpactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func triggerSelectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
