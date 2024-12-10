//
//  GlobalMarketData.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 12.12.24.
//

import Foundation

struct GlobalMarketData: Decodable {
    let currentCPIPercentage: Double
    let nextCPIDate: Date
    let currentInterestRatePercentage: Double
    let nextFOMCMeetingDate: Date
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case currentCPIPercentage
        case nextCPITimestamp
        case currentInterestRatePercentage
        case nextFOMCMeetingTimestamp
    }
    
    // MARK: - Initializers
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nextCPITimestamp = try container.decode(Int.self, forKey: .nextCPITimestamp)
        let nextFOMCMeetingTimestamp = try container.decode(Int.self, forKey: .nextFOMCMeetingTimestamp)
        currentCPIPercentage = try container.decode(Double.self, forKey: .currentCPIPercentage)
        nextCPIDate = Date(timeIntervalSince1970: TimeInterval(nextCPITimestamp))
        currentInterestRatePercentage = try container.decode(Double.self, forKey: .currentInterestRatePercentage)
        nextFOMCMeetingDate = Date(timeIntervalSince1970: TimeInterval(nextFOMCMeetingTimestamp))
    }
}
