//
//  PriceAlertListView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 22.04.23.
//

import SwiftUI
import CoreData

struct PriceAlertListView: View {

    @StateObject private var priceAlertListViewModel = PriceAlertListViewModel()
    @StateObject private var addPriceAlertViewModel = AddPriceAlertViewModel()

    @State private var showAddPriceAlertView = false
    @State private var showErrorAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                List(priceAlertListViewModel.priceAlerts, id: \.self) { priceAlert in
                    HStack(spacing: 16) {
                        if let uiImage = UIImage(data: priceAlert.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(priceAlert.name).font(.headline)

                            HStack(spacing: 4) {
                                Text("\(priceAlert.currentPrice.formatValue()) $")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                Text("\(priceAlert.priceChange.formatValue(shouldShowPrefix: true))%")
                                    .foregroundColor(priceAlert.priceChange.isNegative ? .red : .green)
                                    .font(.caption2)
                            }
                        }

                        Spacer()
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            priceAlertListViewModel.delete(priceAlert)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
                .navigationTitle("Price Alerts")
                .refreshable {
                    priceAlertListViewModel.fetchPriceAlerts()
                }

                if priceAlertListViewModel.isLoading {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddPriceAlertView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onChange(of: priceAlertListViewModel.errorMessage) { errorMessage in
                showErrorAlert = errorMessage != nil
            }
            .alert(priceAlertListViewModel.errorMessage ?? "", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            }
            .sheet(isPresented: $showAddPriceAlertView) {
                AddPriceAlertView { selectedCoin in
                    priceAlertListViewModel.fetchMarketData(for: [selectedCoin])
                }
                .environmentObject(addPriceAlertViewModel)
            }
            .onAppear {
                priceAlertListViewModel.fetchPriceAlerts()
            }
        }
    }
}
