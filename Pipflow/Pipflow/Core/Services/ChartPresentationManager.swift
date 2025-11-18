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
        print("ChartPresentationManager: presentChart called for symbol: \(symbol)")
        selectedSymbol = symbol
        showChart = true
        print("ChartPresentationManager: showChart set to \(showChart)")
    }
    
    func dismissChart() {
        showChart = false
    }
}