//
//  ContentView.swift
//  Pipflow
//
//  Created by inano on 18/07/2025.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var uiStyleManager = UIStyleManager.shared
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var chartManager = ChartPresentationManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            AIDashboard()
                .tabItem {
                    Label("AI", systemImage: "brain")
                }
                .tag(1)
            
            TradingView()
                .tabItem {
                    Label("Trade", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            MarketView()
                .tabItem {
                    Label("Market", systemImage: "chart.bar.xaxis")
                }
                .tag(3)
            
            ModernSocialHub()
                .tabItem {
                    Label("Social", systemImage: "person.3.fill")
                }
                .tag(4)
        }
        .preferredColorScheme(.dark)
        .environmentObject(themeManager)
        .environmentObject(uiStyleManager)
        .environment(\.uiStyle, uiStyleManager.currentStyle)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(AuthService())
}