//
//  SettingsViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.11.24.
//

import SwiftUI

final class SettingsViewModel: BaseViewModel {
    // MARK: - Properties
    @Published var settings: [Setting] = []
    
    var groupedSettings: [SettingType.Section: [Setting]] {
        Dictionary(grouping: settings, by: { $0.type.section })
    }
    
    // MARK: - Initializers
    init(authStateProvider: AuthStateProvider? = nil, userDefaultsManager: UserDefaultsManager? = nil) {
        super.init(authStateProvider: authStateProvider, userDefaultsManager: userDefaultsManager)
    }
    
    // MARK: - Methods
    func fetchSettings() {
        settings = [
            // App
            Setting(type: .startScreen, selectedOption: getSavedSetting(of: .startScreen)),
            //Setting(type: .currency, selectedOption: getSavedSetting(of: .currency)),
            Setting(type: .feedback),
            // Legal
            Setting(type: .privacy),
            Setting(type: .terms),
            // About
            Setting(type: .support),
            Setting(type: .version)
        ]
        
        if let account {
            let type: SettingType = account.isAnonymous ? .resetAppData : .deleteAccount
            settings.append(Setting(type: type))
            
//            if !account.isPro {
//                settings.insert(.init(type: .pro), at: .zero)
//            }
        }
    }
    
    func updateSetting(of type: SettingType, with value: Int) {
        if let index = settings.firstIndex(where: { $0.type == type }) {
            settings[index].selectedOption = value
            setSetting(value, of: settings[index].type)
        }
    }
    
    func getSetting(of type: SettingType) -> Setting? {
        settings.first(where: { $0.type == type })
    }
    
    func getSettingOptionTitle(for settingType: SettingType, with selectedOption: Int) -> String {
        settingType.options[selectedOption].title
    }
    
    // MARK: - Private
    private func getSavedSetting(of type: SettingType) -> Int {
        (try? userDefaultsManager.getObject(forKey: .setting(ofType: type), objectType: Int.self)) ?? .zero
    }
    
    private func setSetting(_ setting: Int, of type: SettingType) {
        try? userDefaultsManager.setObject(setting, forKey: .setting(ofType: type))
    }
}

struct Setting: Identifiable, Hashable {
    var id = UUID().uuidString
    let type: SettingType
    var selectedOption: Int? = nil
}

enum SettingType: Int, CaseIterable {
    // App
//    case pro
//    case currency
    case startScreen, feedback, resetAppData
    // Legal
    case privacy, terms
    // About
    case support, version
    // Account
    case deleteAccount
    
    var section: Section {
        switch self {
        case .startScreen, .feedback, .resetAppData:
            return .app
        case .privacy, .terms:
            return .legal
        case .support, .version:
            return .about
        case .deleteAccount:
            return .account
        }
    }
    
    var title: String {
        switch self {
//        case .pro: return "Get Pro"
        case .startScreen: return "Start Screen"
//        case .currency: return "Currency"
        case .feedback: return "Leave Feedback"
        case .resetAppData: return "Reset the App"
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms of Use"
        case .support: return "Support Request"
        case .version: return "Version"
        case .deleteAccount: return "Delete Account"
        }
    }
    
    var imageName: String {
        switch self {
//        case .pro: return "checkmark.seal.fill"
        case .startScreen: return "house"
//        case .currency: return "dollarsign.circle"
        case .feedback: return "star"
        case .deleteAccount: return "person.slash.fill"
        case .resetAppData: return "arrow.clockwise"
        case .privacy: return "hand.raised"
        case .terms: return "text.book.closed"
        case .support: return "bubble.left.and.text.bubble.right"
        case .version: return "tag"
        }
    }
    
    var color: Color {
        switch self {
//        case .pro: return .accent
        case .startScreen: return .accent
//        case .currency: return .gray
        case .feedback: return .neonYellow
        case .privacy, .terms: return .secondary
        case .support: return .neonCyan
        case .version: return .neonGreen
        case .deleteAccount, .resetAppData: return .neonPink
        }
    }
    
    var options: [SettingOption] {
        switch self {
        case .startScreen:
            return StartScreen.allCases.map { SettingOption(title: $0.title, imageName: $0.imageName, value: $0.rawValue) }
//        case .currency:
//            return Currency.allCases.map { SettingOption(title: $0.title, value: $0.rawValue) }
        default:
            return []
        }
    }
    
    var defaultOption: SettingOption? {
        switch self {
        case .startScreen:
            let startScreen = StartScreen.coins
            return SettingOption(title: startScreen.title, value: startScreen.rawValue)
//        case .currency:
//            let currency = Currency.usd
//            return SettingOption(title: currency.title, value: currency.rawValue)
        default:
            return nil
        }
    }
}

extension SettingType {
    enum Section: String, CaseIterable {
        case app = "App"
        case legal = "Legal"
        case about = "About"
        case account = "Account"
    }
}

extension SettingType {
    enum StartScreen: Int, CaseIterable {
        case coins, portfolio, compare, news
        
        var title: String {
            switch self {
            case .coins: return "Coins"
            case .portfolio: return "Portfolio"
            case .compare: return "Compare"
            case .news: return "News"
            }
        }
        
        var imageName: String {
            switch self {
            case .coins: return "coins"
            case .portfolio: return "bag"
            case .compare: return "arrows.swap"
            case .news: return "news"
            }
        }
    }
    
    enum Currency: Int, CaseIterable {
        case usd
        
        var value: String {
            switch self {
            case .usd: return "usd"
            }
        }
        
        var title: String {
            switch self {
            case .usd: return "USD"
            }
        }
    }
}

struct SettingOption: Hashable {
    let title: String
    let imageName: String?
    let value: Int
    
    init(title: String, imageName: String? = nil, value: Int) {
        self.title = title
        self.imageName = imageName
        self.value = value
    }
}
