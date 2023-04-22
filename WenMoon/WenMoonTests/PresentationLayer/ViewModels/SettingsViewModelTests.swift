//
//  SettingsViewModelTests.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 02.12.24.
//

import XCTest
import FirebaseAuth
@testable import WenMoon

class SettingsViewModelTests: XCTestCase {
    // MARK: - Properties
    var viewModel: SettingsViewModel!
    var authStateProvider: AuthStateProviderMock!
    var userDefaultsManager: UserDefaultsManagerMock!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        authStateProvider = AuthStateProviderMock()
        userDefaultsManager = UserDefaultsManagerMock()
        viewModel = SettingsViewModel(
            authStateProvider: authStateProvider,
            userDefaultsManager: userDefaultsManager
        )
    }
    
    override func tearDown() {
        viewModel = nil
        authStateProvider = nil
        userDefaultsManager = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testFetchSettings() {
        // Setup
        let selectedStartScreenOption = 0
        //let selectedCurrencyOption = 1
        userDefaultsManager.getObjectReturnValue = [
            .setting(ofType: .startScreen): selectedStartScreenOption
            //.setting(ofType: .currency): selectedCurrencyOption
        ]
        let expectedSettings: [Setting] = [
            Setting(type: .startScreen, selectedOption: selectedStartScreenOption),
            //Setting(type: .currency, selectedOption: selectedCurrencyOption),
            Setting(type: .feedback),
            Setting(type: .privacy),
            Setting(type: .terms),
            Setting(type: .support),
            Setting(type: .version)
        ]
        
        // Action
        viewModel.fetchSettings()
        
        // Assertions
        XCTAssertEqual(viewModel.settings.count, expectedSettings.count)
        for (index, setting) in viewModel.settings.enumerated() {
            XCTAssertEqual(setting.type, expectedSettings[index].type)
            XCTAssertEqual(setting.selectedOption, expectedSettings[index].selectedOption)
        }
    }
    
    func testUpdateSetting() {
        // Setup
        let setting = Setting(type: .startScreen, selectedOption: 0)
        viewModel.settings = [setting]
        
        // Action
        let newSettingValue = 1
        viewModel.updateSetting(of: .startScreen, with: newSettingValue)
        
        // Assertions
        let updatedSetting = viewModel.getSetting(of: .startScreen)!
        XCTAssertEqual(updatedSetting.selectedOption, newSettingValue)
        XCTAssertTrue(userDefaultsManager.setObjectCalled)
        XCTAssertEqual(userDefaultsManager.setObjectValue[.setting(ofType: setting.type)] as! Int, newSettingValue)
    }
    
    func testGetSetting() {
        // Setup
        let startScreen = Setting(type: .startScreen, selectedOption: 0)
//        let currency = Setting(type: .currency, selectedOption: 1)
        let feedback = Setting(type: .feedback, selectedOption: 1)
        let privacy = Setting(type: .privacy, selectedOption: 2)
        let terms = Setting(type: .terms, selectedOption: 3)
        let support = Setting(type: .support, selectedOption: 4)
        let version = Setting(type: .version, selectedOption: 5)
        viewModel.settings = [
            startScreen,
//            currency,
            feedback,
            privacy,
            terms,
            support,
            version
        ]
        
        // Assertions
        let fetchedStartScreen = viewModel.getSetting(of: .startScreen)
        XCTAssertEqual(fetchedStartScreen, startScreen)
        
//        let fetchedCurrency = viewModel.getSetting(of: .currency)
//        XCTAssertEqual(fetchedCurrency, currency)
        
        let fetchedFeedback = viewModel.getSetting(of: .feedback)
        XCTAssertEqual(fetchedFeedback, feedback)
        
        let fetchedPrivacy = viewModel.getSetting(of: .privacy)
        XCTAssertEqual(fetchedPrivacy, privacy)
        
        let fetchedTerms = viewModel.getSetting(of: .terms)
        XCTAssertEqual(fetchedTerms, terms)
        
        let fetchedSupport = viewModel.getSetting(of: .support)
        XCTAssertEqual(fetchedSupport, support)
        
        let fetchedVersion = viewModel.getSetting(of: .version)
        XCTAssertEqual(fetchedVersion, version)
        
        let nonExistent = viewModel.getSetting(of: .deleteAccount)
        XCTAssertNil(nonExistent)
    }
    
    func testGetSettingOptionTitle() {
        // Setup
        let settingType: SettingType = .startScreen
        let selectedOption = 0
        let expectedTitle = settingType.options[selectedOption].title
        
        // Action
        let title = viewModel.getSettingOptionTitle(for: settingType, with: selectedOption)
        
        // Assert
        XCTAssertEqual(title, expectedTitle)
    }
}
