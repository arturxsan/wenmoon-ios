//
//  NewsView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 05.12.24.
//

import SwiftUI

struct NewsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = NewsViewModel()
    @State private var selectedNews: News?
    
    private var news: [News] { viewModel.news }
    
    // MARK: - Body
    var body: some View {
        BaseView(isLoading: $viewModel.isLoading, errorMessage: $viewModel.errorMessage) {
            NavigationView {
                VStack {
                    if viewModel.isLoading {
                        CustomProgressView()
                    } else {
                        ZStack {
                            List {
                                if !news.isEmpty {
                                    ForEach(news, id: \.self) { news in
                                        newsRow(news)
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .refreshable {
                                Task {
                                    await viewModel.fetchAllNews()
                                }
                            }
                            
                            if news.isEmpty {
                                PlaceholderView(text: "No news available yet")
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: news)
                .navigationTitle("News")
            }
        }
        .sheet(item: $selectedNews) { news in
            if let url = news.url {
                SafariView(url: url)
            }
        }
        .onLoad {
            Task { await viewModel.fetchAllNews() }
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func newsRow(_ news: News) -> some View {
        HStack(spacing: 16) {
            if let imageURL = news.thumbnail {
                AsyncImage(url: imageURL, content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                }, placeholder: {
                    ProgressView()
                })
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading) {
                if let title = news.title {
                    Text(title)
                        .font(.subheadline).bold()
                        .lineLimit(2)
                }
                
                if let url = news.url,
                   let source = viewModel.extractSource(from: url) {
                    HStack {
                        Text(source)
                        
                        Circle()
                            .frame(width: 4, height: 4)
                        
                        Text(news.date.formatted(as: .relative))
                    }
                    .font(.footnote)
                    .foregroundStyle(.gray)
                }
            }
        }
        .onTapGesture {
            selectedNews = news
        }
    }
}

// MARK: - Preview
#Preview {
    NewsView()
        .preferredColorScheme(.dark)
}
