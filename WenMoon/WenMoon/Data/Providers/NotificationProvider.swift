//
//  NotificationProvider.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 12.03.25.
//

import UIKit

// MARK: - NotificationProvider
protocol NotificationProvider {
    func setupNotificationsIfNeeded() async
    func isNotificationsEnabled() async -> Bool
    func requestPermission() async throws -> Bool
    func registerForPushNotifications() async
    func resetBadgeNumber()
    func getDeviceToken() -> String?
    func setDeviceToken(_ token: String?)
}

// MARK: - DefaultNotificationManager
final class DefaultNotificationManager: NotificationProvider {
    private let provider: NotificationProvider
    
    init(provider: NotificationProvider = NotificationStore.shared) {
        self.provider = provider
    }
    
    func setupNotificationsIfNeeded() async {
        await provider.setupNotificationsIfNeeded()
    }
    
    func isNotificationsEnabled() async -> Bool {
        await provider.isNotificationsEnabled()
    }
    
    func registerForPushNotifications() async {
        await provider.registerForPushNotifications()
    }
    
    func resetBadgeNumber() {
        provider.resetBadgeNumber()
    }
    
    func requestPermission() async throws -> Bool {
        try await provider.requestPermission()
    }
    
    func getDeviceToken() -> String? {
        provider.getDeviceToken()
    }
    
    func setDeviceToken(_ token: String?) {
        provider.setDeviceToken(token)
    }
}

// MARK: - NotificationStore (Singleton)
final class NotificationStore: NotificationProvider {
    static let shared = NotificationStore()
    private let userDefaultsManager = UserDefaultsManagerImpl()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    func setupNotificationsIfNeeded() async {
        let settings = await notificationCenter.notificationSettings()
        
        if settings.authorizationStatus == .notDetermined {
            do {
                let isPermissionGranted = try await requestPermission()
                guard isPermissionGranted else { return }
                await registerForPushNotifications()
            } catch {
                print("Failed to request notification authorization: \(error)")
            }
        }
    }
    
    func isNotificationsEnabled() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        let isEnabled = settings.authorizationStatus == .authorized
        return isEnabled
    }
    
    func requestPermission() async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    func registerForPushNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func resetBadgeNumber() {
        notificationCenter.setBadgeCount(.zero)
    }
    
    func getDeviceToken() -> String? {
        try? userDefaultsManager.getObject(forKey: .deviceToken, objectType: String.self)
    }
    
    func setDeviceToken(_ token: String?) {
        try? userDefaultsManager.setObject(token, forKey: .deviceToken)
    }
}
