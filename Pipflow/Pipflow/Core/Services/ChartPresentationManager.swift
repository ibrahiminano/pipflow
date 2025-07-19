//
//  ChartPresentationManager.swift
//  Pipflow
//
//  Created by Claude on 19/07/2025.
//

import SwiftUI
import Combine

class ChartPresentationManager: ObservableObject {
    static let shared = ChartPresentationManager()
    
    @Published var showChart = false
    @Published var selectedSymbol = "EURUSD"
    
    private init() {}
    
    func presentChart(for symbol: String) {
        selectedSymbol = symbol
        showChart = true
    }
    
    func dismissChart() {
        showChart = false
    }
}