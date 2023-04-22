//
//  NewsViewModel.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.12.24.
//

import Foundation

final class NewsViewModel: BaseViewModel {
    // MARK: - Properties
    private let service: NewsService
    
    @Published private(set) var news: [News] = []
    
    private let sourceMapping: [String: String] = [
        "coindesk.com": "Coindesk",
        "cointelegraph.com": "Cointelegraph",
        "coincu.com": "Coincu",
        "cryptopotato.com": "Cryptopotato",
        "bitcoinmagazine.com": "Bitcoin Magazine",
        "bitcoinist.com": "Bitcoinist"
    ]
    
    // MARK: - Initializers
    convenience init() {
        self.init(service: NewsServiceImpl())
    }
    
    init(service: NewsService) {
        self.service = service
        super.init()
    }
    
    // MARK: - Interface
    @MainActor
    func fetchAllNews() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allNews = try await service.getAllNews()
            let mappedNews = [
                allNews.bitcoinmagazine,
                allNews.bitcoinist,
                allNews.cryptopotato,
                allNews.coindesk,
                allNews.cointelegraph
            ]
                .compactMap { $0 }
                .flatMap { $0 }
                .sorted(by: { $0.date > $1.date })
            
            self.news = mappedNews
        } catch {
            setError(error)
        }
    }
    
    func extractSource(from url: URL) -> String? {
        guard let host = url.host else { return nil }
        let hostParts = host.split(separator: ".")
        if hostParts.count >= 2 {
            let domain = hostParts.suffix(2).joined(separator: ".")
            return sourceMapping[domain]
        }
        return nil
    }
}
