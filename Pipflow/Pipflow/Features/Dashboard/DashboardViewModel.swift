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
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDashboardData()
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
}