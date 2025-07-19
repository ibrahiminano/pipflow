//
//  ContentView.swift
//  Pipflow
//
//  Created by inano on 18/07/2025.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var selectedTab = 0 // Default to Dashboard tab
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var chartManager = ChartPresentationManager.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)
            
            MarketTabView()
                .tabItem {
                    Label("Market", systemImage: "chart.bar.xaxis")
                }
                .tag(1)
            
            TradingTabView()
                .tabItem {
                    Label("Trade", systemImage: "arrow.up.arrow.down")
                }
                .tag(2)
            
            SocialTabView()
                .tabItem {
                    Label("Social", systemImage: "person.3.fill")
                }
                .tag(3)
            
            SignalsTabView()
                .tabItem {
                    Label("Signals", systemImage: "sparkles")
                }
                .tag(4)
            
            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(5)
        }
        .accentColor(themeManager.currentTheme.accentColor)
        .fullScreenCover(isPresented: $chartManager.showChart) {
            ChartView(symbol: chartManager.selectedSymbol)
                .environmentObject(themeManager)
        }
    }
}

// Placeholder views for tabs
struct MarketTabView: View {
    var body: some View {
        MarketWatchView()
    }
}

struct TradingTabView: View {
    var body: some View {
        TradingView()
    }
}

struct SocialTabView: View {
    var body: some View {
        SocialFeedView()
    }
}

struct SignalsTabView: View {
    var body: some View {
        SignalsView()
    }
}

struct ProfileTabView: View {
    var body: some View {
        SettingsView()
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
