//
//  CoinDetailsView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 07.11.24.
//

import SwiftUI
import Charts

struct CoinDetailsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: CoinDetailsViewModel
    @State private var selectedPrice: String
    @State private var priceChange = ""
    @State private var selectedDate = ""
    @State private var selectedXPosition: CGFloat?
    @State private var showMarketsView = false
    @State private var showPriceAlertsView = false
    
    private var coin: Coin { viewModel.coin }
    private var coinDetails: CoinDetails { viewModel.coinDetails }
    private var marketData: CoinDetails.MarketData { viewModel.coinDetails.marketData }
    private var chartData: [ChartData] { viewModel.chartData }
    private var isLoading: Bool { viewModel.isLoading }
    
    // MARK: - Initializers
    init(coin: Coin) {
        _viewModel = StateObject(wrappedValue: CoinDetailsViewModel(coin: coin))
        selectedPrice = coin.currentPrice.formattedAsCurrency()
    }
    
    // MARK: - Body
    var body: some View {
        BaseView(isLoading: $viewModel.isLoading, errorMessage: $viewModel.errorMessage) {
            VStack {
                HStack(alignment: .top, spacing: 12) {
                    CoinImageView(
                        imageURL: coin.image,
                        placeholderText: coin.symbol,
                        size: 36
                    )
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(coin.symbol)
                                .font(.headline).bold()
                            
                            Text("#\(marketData.marketCapRank.formattedOrNone())")
                                .font(.caption).bold()
                        }
                        
                        HStack {
                            Text(selectedPrice)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            
                            if !selectedDate.isEmpty {
                                Text(selectedDate)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            } else {
                                Text(priceChange)
                                    .font(.caption)
                                    .foregroundStyle(viewModel.priceChangeColor)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 28) {
                        Button {
                            showPriceAlertsView = true
                        } label: {
                            let isPriceAlertsActive = !coin.priceAlerts.filter(\.isActive).isEmpty && viewModel.isNotificationsEnabled
                            Image("bell.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(isPriceAlertsActive ? .white : .gray)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundStyle(.white, Color(.systemGray5))
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        ZStack {
                            if !chartData.isEmpty, !isLoading {
                                ZStack(alignment: .bottomLeading) {
                                    chartView(chartData)
                                    wenMoonLogo()
                                }
                            }
                            
                            if chartData.isEmpty, !isLoading {
                                PlaceholderView(text: "No data available", style: .small)
                            }
                            
                            if isLoading {
                                ProgressView()
                            }
                        }
                        .frame(height: 300)
                        .padding(.top, 24)
                        
                        Picker("Select Timeframe", selection: $viewModel.selectedTimeframe) {
                            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                                Text(timeframe.displayValue).tag(timeframe)
                            }
                        }
                        .pickerStyle(.segmented)
                        .scaleEffect(0.85)
                        .disabled(isLoading)
                        
                        VStack(spacing: 24) {
                            PrimaryButton(title: "See Markets", isFullWidth: true) {
                                showMarketsView = true
                                viewModel.triggerImpactFeedback()
                            }
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    detailsRow(label: "Market Cap", value: coin.marketCap.formattedWithAbbreviation(suffix: "$"))
                                    detailsRow(label: "24h Volume", value: marketData.totalVolume.formattedWithAbbreviation(suffix: "$"))
                                    detailsRow(label: "Max Supply", value: marketData.maxSupply.formattedWithAbbreviation(placeholder: "∞"))
                                    detailsRow(label: "All-Time High", value: marketData.ath.formattedAsCurrency())
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading) {
                                    detailsRow(label: "Fully Diluted Market Cap", value: marketData.fullyDilutedValuation.formattedWithAbbreviation(suffix: "$"))
                                    detailsRow(label: "Circulating Supply", value: marketData.circulatingSupply.formattedWithAbbreviation())
                                    detailsRow(label: "Total Supply", value: marketData.totalSupply.formattedWithAbbreviation())
                                    detailsRow(label: "All-Time Low", value: marketData.atl.formattedAsCurrency())
                                }
                            }
                            .padding()
                            .background(Color.obsidianGray)
                            .cornerRadius(12)
                            
                            if let description = coinDetails.description?.htmlStripped, !description.isEmpty {
                                section(title: "Description") {
                                    ExpandableTextView(text: description)
                                }
                            }
                            
                            if !coinDetails.links.isEmpty {
                                section(title: "Links") {
                                    LinksView(links: coinDetails.links)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, UIDevice.current.isSmallScreen ? 24 : 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(.top, 24)
            .background(Color.obsidian)
        }
        .onChange(of: viewModel.selectedTimeframe) {
            Task { await fetchChartData() }
        }
        .onChange(of: selectedPrice) {
            viewModel.triggerSelectionFeedback()
        }
        .sheet(isPresented: $showMarketsView) {
            let tickers = coinDetails.tickers
            let detents: Set<PresentationDetent> = tickers.count > 5 ? [.large] : [.medium, .large]
            CoinMarketsView(tickers: tickers)
                .presentationDetents(detents)
        }
        .sheet(isPresented: $showPriceAlertsView) {
            PriceAlertsView(coin: coin)
                .presentationCornerRadius(36)
        }
        .task {
            await viewModel.fetchCoinDetails()
            await fetchChartData()
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func chartView(_ data: [ChartData]) -> some View {
        let prices = data.map { $0.price }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 1
        let priceRange = minPrice...maxPrice
        
        Chart {
            let chartColor = viewModel.priceChangeColor
            ForEach(data, id: \.date) { dataPoint in
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    yStart: .value("Min Price", minPrice),
                    yEnd: .value("Price", dataPoint.price)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            chartColor.opacity(0.25),
                            chartColor.opacity(.zero)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            ForEach(data, id: \.date) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Price", dataPoint.price)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(chartColor)
            }
        }
        .chartYScale(domain: priceRange)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
        .chartOverlay { proxy in
            chartOverlay(proxy: proxy, data: data)
        }
    }
    
    @ViewBuilder
    private func chartOverlay(proxy: ChartProxy, data: [ChartData]) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    LongPressGesture(minimumDuration: .zero)
                        .sequenced(before: DragGesture(minimumDistance: .zero))
                        .onChanged { value in
                            switch value {
                            case .first(true):
                                updateSelectedData(
                                    location: geometry.frame(in: .local).origin,
                                    proxy: proxy,
                                    data: data,
                                    geometry: geometry
                                )
                            case .second(true, let drag):
                                if let location = drag?.location {
                                    updateSelectedData(
                                        location: location,
                                        proxy: proxy,
                                        data: data,
                                        geometry: geometry
                                    )
                                }
                            default:
                                break
                            }
                        }
                        .onEnded { _ in
                            selectedPrice = coin.currentPrice.formattedAsCurrency()
                            selectedDate = ""
                            selectedXPosition = nil
                        }
                )
            
            if let selectedXPosition {
                ZStack {
                    let separatorWidth: CGFloat = 1
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: separatorWidth, height: geometry.size.height + 20)
                        .position(x: selectedXPosition, y: geometry.size.height / 2)
                    
                    Rectangle()
                        .fill(Color.obsidian.opacity(0.6))
                        .frame(width: geometry.size.width - selectedXPosition + separatorWidth, height: geometry.size.height + 20)
                        .position(x: selectedXPosition + separatorWidth + (geometry.size.width - selectedXPosition) / 2, y: geometry.size.height / 2)
                }
            }
        }
    }
    
    @ViewBuilder
    private func detailsRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
            
            Text(value)
                .font(.caption)
        }
    }
    
    @ViewBuilder
    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            content()
        }
    }
    
    @ViewBuilder
    private func wenMoonLogo() -> some View {
        HStack(spacing: 4) {
            Image("moon")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            Text("WenMoon")
        }
        .foregroundStyle(.gray.opacity(0.3))
        .padding(.leading, 16)
        .padding(.bottom, -8)
    }
    
    // MARK: - Private
    private func updateSelectedData(
        location: CGPoint,
        proxy: ChartProxy,
        data: [ChartData],
        geometry: GeometryProxy
    ) {
        guard location.x >= .zero, location.x <= geometry.size.width else {
            selectedXPosition = nil
            return
        }
        
        if let date: Date = proxy.value(atX: location.x) {
            if let closestDataPoint = data.min(by: {
                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
            }) {
                selectedPrice = closestDataPoint.price.formattedAsCurrency()
                selectedXPosition = location.x
                
                let formatType: Date.FormatType
                switch viewModel.selectedTimeframe {
                case .oneDay:
                    formatType = .timeOnly
                case .oneWeek:
                    formatType = .dateAndTime
                default:
                    formatType = .dateOnly
                }
                selectedDate = closestDataPoint.date.formatted(as: formatType)
            }
        }
    }
    
    private func fetchChartData() async {
        await viewModel.fetchChartData()
        priceChange = viewModel.priceChangeFormatted
    }
}

// MARK: - Preview
#Preview {
    CoinDetailsView(coin: Coin())
        .preferredColorScheme(.dark)
}
