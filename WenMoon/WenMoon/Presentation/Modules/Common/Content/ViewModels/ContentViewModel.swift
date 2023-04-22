//
//  ContentViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 15.01.25.
//

import Foundation

final class ContentViewModel: BaseViewModel {
    // MARK: - Properties
    private let service: GlobalMarketDataService
    
    @Published private(set) var globalMarketDataItems: [GlobalMarketDataItem] = []
    @Published var startScreenIndex = 0
    
    var isAllMarketDataItemsFetched: Bool {
        globalMarketDataItems.count == 7
    }
    
    // MARK: - Initializers
    convenience init() {
        self.init(service: GlobalMarketDataServiceImpl())
    }
    
    init(service: GlobalMarketDataService, userDefaultsManager: UserDefaultsManager? = nil) {
        self.service = service
        super.init(userDefaultsManager: userDefaultsManager)
        fetchStartScreen()
    }
    
    // MARK: - Methods
    @MainActor
    func fetchAllGlobalMarketData() async {
        do {
            globalMarketDataItems.removeAll()
            
            async let fearAndGreedTask = service.getFearAndGreedIndex()
            async let cryptoMarketTask = service.getCryptoGlobalMarketData()
            async let globalMarketTask = service.getGlobalMarketData()
            
            let (fearAndGreedIndex, cryptoGlobalMarketData, globalMarketData) = try await (
                fearAndGreedTask,
                cryptoMarketTask,
                globalMarketTask
            )
            
            // Fear/Greed
            guard let fearAndGreedData = fearAndGreedIndex.data.first else { return }
            let fearAndGreedItem = GlobalMarketDataItem(
                type: .fearAndGreedIndex,
                value: "\(fearAndGreedData.value) \(fearAndGreedData.valueClassification)"
            )
            
            // BTC Dom
            guard let btcDominance = cryptoGlobalMarketData.data.marketCapPercentage["btc"] else { return }
            let btcDominanceItem = GlobalMarketDataItem(
                type: .btcDominance,
                value: btcDominance.formattedAsPercentage(includePlusPrefix: false)
            )
            
            // Market Cap
            let usdMarketCap = cryptoGlobalMarketData.data.totalMarketCap["usd"] ?? .zero
            let totalMarketCapItem = GlobalMarketDataItem(
                type: .totalMarketCap,
                value: usdMarketCap.formattedWithAbbreviation()
            )
            
            // Macro
            let marketItems = [
                GlobalMarketDataItem(
                    type: .cpi,
                    value: globalMarketData.cpiPercentage.formattedAsPercentage(includePlusPrefix: false)
                ),
                GlobalMarketDataItem(
                    type: .nextCPI,
                    value: globalMarketData.nextCPIDate.formattedAsUpcomingDay()
                ),
                GlobalMarketDataItem(
                    type: .interestRate,
                    value: globalMarketData.interestRatePercentage.formattedAsPercentage(includePlusPrefix: false)
                ),
                GlobalMarketDataItem(
                    type: .nextFOMCMeeting,
                    value: globalMarketData.nextFOMCMeetingDate.formattedAsUpcomingDay()
                )
            ]
            
            let allItems = [fearAndGreedItem, btcDominanceItem, totalMarketCapItem] + marketItems
            let newItems = allItems.filter { !globalMarketDataItems.contains($0) }
            globalMarketDataItems.append(contentsOf: newItems)
        } catch {
            setError(error)
            globalMarketDataItems.removeAll()
        }
    }
    
    func fetchStartScreen() {
        startScreenIndex = (
            try? self.userDefaultsManager.getObject(
                forKey: .setting(ofType: .startScreen),
                objectType: Int.self
            )
        ) ?? .zero
    }
}

struct GlobalMarketDataItem: Hashable {
    // MARK: - Nested Types
    enum ItemType: CaseIterable {
        case fearAndGreedIndex
        case btcDominance
        case totalMarketCap
        case cpi
        case nextCPI
        case interestRate
        case nextFOMCMeeting
        
        var title: String {
            switch self {
            case .fearAndGreedIndex: return "Fear/Greed:"
            case .btcDominance: return "BTC Dom:"
            case .totalMarketCap: return "M Cap:"
            case .cpi: return "CPI:"
            case .nextCPI: return "Next CPI:"
            case .interestRate: return "Int. Rate:"
            case .nextFOMCMeeting: return "Next FOMC:"
            }
        }
    }
    
    // MARK: - Properties
    let type: ItemType
    let value: String
}
