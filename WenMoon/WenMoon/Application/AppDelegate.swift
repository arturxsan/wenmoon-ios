//
//  AppDelegate.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 23.05.23.
//

import UIKit
import Firebase
import GoogleSignIn
import RevenueCat

class AppDelegate: NSObject, UIApplicationDelegate {
    // MARK: - Properties
    private let notificationProvider = DefaultNotificationManager()
    
    // MARK: - Methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        FirebaseApp.configure()
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: RevenueCat.apiKey)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: - Private
    private func sendTargetPriceNotification(for id: String) {
        let userInfo: [String: Any] = ["id": id]
        NotificationCenter.default.post(name: .targetPriceReached, object: nil, userInfo: userInfo)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.hexString
        print("Device Token: \(token)")
        notificationProvider.setDeviceToken(token)
        NotificationCenter.default.post(name: .userDidRegisterForRemoteNotifications, object: nil)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications with error: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions
        ) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let id = userInfo["id"] as? String {
            sendTargetPriceNotification(for: id)
            notificationProvider.resetBadgeNumber()
        }
        completionHandler([.banner, .badge, .sound])
    }
}
