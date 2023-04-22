//
//  CoinDetails.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.02.25.
//

import Foundation

struct CoinDetails: Codable, Equatable {
    // MARK: - Properties
    let id: String
    let symbol: String
    let name: String
    let image: URL?
    let marketData: MarketData
    let categories: [String]
    let publicNotice: String?
    let description: String?
    let links: Links
    let countryOrigin: String?
    let genesisDate: String?
    let sentimentVotesUpPercentage: Double?
    let sentimentVotesDownPercentage: Double?
    let watchlistPortfolioUsers: Int?
    let tickers: [Ticker]
    
    // MARK: - Coding Keys
    private enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case marketData
        case categories
        case publicNotice
        case description
        case links
        case countryOrigin
        case genesisDate
        case sentimentVotesUpPercentage
        case sentimentVotesDownPercentage
        case watchlistPortfolioUsers
        case tickers
    }
    
    // MARK: - Initializers
    init(
        id: String = "",
        symbol: String = "",
        name: String = "",
        image: URL? = nil,
        marketData: MarketData = .init(),
        categories: [String] = [],
        publicNotice: String? = nil,
        description: String? = nil,
        links: Links = .init(),
        countryOrigin: String? = nil,
        genesisDate: String? = nil,
        sentimentVotesUpPercentage: Double? = nil,
        sentimentVotesDownPercentage: Double? = nil,
        watchlistPortfolioUsers: Int? = nil,
        tickers: [Ticker] = []
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.image = image
        self.marketData = marketData
        self.categories = categories
        self.publicNotice = publicNotice
        self.description = description
        self.links = links
        self.countryOrigin = countryOrigin
        self.genesisDate = genesisDate
        self.sentimentVotesUpPercentage = sentimentVotesUpPercentage
        self.sentimentVotesDownPercentage = sentimentVotesDownPercentage
        self.watchlistPortfolioUsers = watchlistPortfolioUsers
        self.tickers = tickers
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol).uppercased()
        name = try container.decode(String.self, forKey: .name)
        marketData = try container.decode(MarketData.self, forKey: .marketData)
        categories = try container.decode([String].self, forKey: .categories)
        publicNotice = try? container.decode(String?.self, forKey: .publicNotice)
        links = try container.decode(Links.self, forKey: .links)
        countryOrigin = try? container.decode(String?.self, forKey: .countryOrigin)
        genesisDate = try? container.decode(String?.self, forKey: .genesisDate)
        sentimentVotesUpPercentage = try? container.decode(Double?.self, forKey: .sentimentVotesUpPercentage)
        sentimentVotesDownPercentage = try? container.decode(Double?.self, forKey: .sentimentVotesDownPercentage)
        watchlistPortfolioUsers = try? container.decode(Int?.self, forKey: .watchlistPortfolioUsers)
        tickers = try container.decode([Ticker].self, forKey: .tickers)
        
        struct ImageContainer: Decodable {
            let large: SafeURL?
        }
        let imageContainer = try container.decodeIfPresent(ImageContainer.self, forKey: .image)
        image = imageContainer?.large?.url
        
        struct DescriptionContainer: Decodable {
            let en: String?
        }
        let descriptionContainer = try container.decodeIfPresent(DescriptionContainer.self, forKey: .description)
        description = descriptionContainer?.en
    }
    
    // MARK: - Methods
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(symbol.lowercased(), forKey: .symbol)
        try container.encode(name, forKey: .name)
        try container.encode(marketData, forKey: .marketData)
        try container.encode(categories, forKey: .categories)
        try container.encode(publicNotice, forKey: .publicNotice)
        try container.encode(links, forKey: .links)
        try container.encode(countryOrigin, forKey: .countryOrigin)
        try container.encode(genesisDate, forKey: .genesisDate)
        try container.encode(sentimentVotesUpPercentage, forKey: .sentimentVotesUpPercentage)
        try container.encode(sentimentVotesDownPercentage, forKey: .sentimentVotesDownPercentage)
        try container.encode(watchlistPortfolioUsers, forKey: .watchlistPortfolioUsers)
        try container.encode(tickers, forKey: .tickers)
        
        if let image {
            let imageContainer = ["large": image]
            try container.encode(imageContainer, forKey: .image)
        }
        
        if let description {
            let descriptionContainer = ["en": description]
            try container.encode(descriptionContainer, forKey: .description)
        }
    }
}
