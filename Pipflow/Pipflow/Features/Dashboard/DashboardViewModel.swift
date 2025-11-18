//
//  DashboardViewModel.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var balance: Decimal = 10000
    @Published var todayPnL: Decimal = 250
    @Published var winRate: Double = 0.68
    @Published var activePositions: [Trade] = []
    @Published var recentSignals: [Signal] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var chartData: [DashboardChartDataPoint] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDashboardData()
        generateChartData()
    }
    
    func loadDashboardData() {
        isLoading = true
        
        // Simulate loading data
        // In real implementation, this would call various services
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
        }
    }
    
    func refreshData() {
        loadDashboardData()
    }
    
    private func generateChartData() {
        // Generate sample chart data
        let now = Date()
        chartData = (0..<50).map { index in
            let time = now.addingTimeInterval(Double(index) * -3600) // Hourly data
            let baseValue = 10000.0
            let variation = Double.random(in: -200...300)
            let value = baseValue + variation + (Double(index) * 50)
            return DashboardChartDataPoint(id: UUID(), time: time, value: value)
        }.reversed()
    }
}

struct DashboardChartDataPoint: Identifiable {
    let id: UUID
    let time: Date
    let value: Double
}