//
//  ChartDataFactoryMock.swift
//  WenMoonTests
//
//  Created by Artur Tkachenko on 11.11.24.
//

import Foundation
@testable import WenMoon

struct ChartDataFactoryMock {
    static func chartDataForTimeframes(_ timeframes: [Timeframe] = Timeframe.allCases) -> [Timeframe: [ChartData]] {
        var data: [Timeframe: [ChartData]] = [:]
        for timeframe in timeframes {
            data[timeframe] = chartData()
        }
        return data
    }
    
    static func chartData(_ count: Int = 10) -> [ChartData] {
        (0..<count).map { index in
            ChartData(
                date: .now.addingTimeInterval(-Double(index) * 86400),
                price: .random(in: 0.01...100_000)
            )
        }
    }
}
