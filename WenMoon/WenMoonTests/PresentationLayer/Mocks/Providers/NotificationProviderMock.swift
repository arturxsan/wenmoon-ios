//
//  NotificationProviderMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 21.03.25.
//

import Foundation
@testable import WenMoon

class NotificationProviderMock: NotificationProvider {
    // MARK: - Properties
    var deviceToken: String?
    var isNotificationsEnabled = false
    
    // MARK: - NotificationProvider
    func setupNotificationsIfNeeded() async {}
    
    func isNotificationsEnabled() async -> Bool { isNotificationsEnabled }
    
    func requestPermission() async throws -> Bool {
        isNotificationsEnabled = true
        return true
    }
    
    func registerForPushNotifications() async {
        deviceToken = "test-device-token"
    }
    
    func resetBadgeNumber() {}
    
    func getDeviceToken() -> String? { deviceToken }
    
    func setDeviceToken(_ token: String?) {
        deviceToken = token
    }
}
