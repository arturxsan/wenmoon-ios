//
//  Notification+Name.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 24.05.23.
//

import Foundation

extension Notification.Name {
    static let appDidBecomeActive = NSNotification.Name("appDidBecomeActive")
    static let userDidRegisterForRemoteNotifications = NSNotification.Name("userDidRegisterForRemoteNotifications")
    static let userDidTriggerPaywall = NSNotification.Name("userDidTriggerPaywall")
    static let userDidUpdateWatchlist = NSNotification.Name("userDidUpdateWatchlist")
    static let targetPriceReached = NSNotification.Name("targetPriceReached")
}
