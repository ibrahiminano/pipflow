//
//  ChartView.swift
//  Pipflow
//
//  Clean TradingView Chart Implementation
//

import SwiftUI

struct ChartView: View {
    let symbol: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Clean TradingView Chart
            CleanTradingViewChart(symbol: symbol)
                .ignoresSafeArea()
            
            // Back button overlay
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
    }
}

// MARK: - Chart Timeframe Model
enum ChartTimeframe: String, CaseIterable {
    case m1 = "1M"
    case m5 = "5M"
    case m15 = "15M"
    case m30 = "30M"
    case h1 = "1H"
    case h4 = "4H"
    case d1 = "1D"
    case w1 = "1W"
    case mn = "1MN"
    
    var interval: TimeInterval {
        switch self {
        case .m1: return 60
        case .m5: return 300
        case .m15: return 900
        case .m30: return 1800
        case .h1: return 3600
        case .h4: return 14400
        case .d1: return 86400
        case .w1: return 604800
        case .mn: return 2592000
        }
    }
    
    var tradingViewInterval: String {
        switch self {
        case .m1: return "1"
        case .m5: return "5"
        case .m15: return "15"
        case .m30: return "30"
        case .h1: return "60"
        case .h4: return "240"
        case .d1: return "D"
        case .w1: return "W"
        case .mn: return "M"
        }
    }
}

#Preview {
    ChartView(symbol: "EURUSD")
        .environmentObject(ThemeManager.shared)
}