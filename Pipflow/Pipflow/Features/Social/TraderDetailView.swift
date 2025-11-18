//
//  TraderDetailView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI
import Charts

struct TraderDetailView: View {
    let trader: Trader
    @StateObject private var socialService = SocialTradingService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab = 0
    @State private var showingCopySettings = false
    
    var isFollowing: Bool {
        socialService.followedTraders.contains { $0.id == trader.id }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        TraderProfileHeaderView(trader: trader)
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                if isFollowing {
                                    socialService.unfollowTrader(trader)
                                } else {
                                    socialService.followTrader(trader)
                                }
                            }) {
                                HStack {
                                    Image(systemName: isFollowing ? "person.fill.checkmark" : "person.badge.plus")
                                    Text(isFollowing ? "Following" : "Follow")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(isFollowing ? themeManager.currentTheme.textColor : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Group {
                                        if isFollowing {
                                            themeManager.currentTheme.secondaryBackgroundColor
                                        } else {
                                            LinearGradient(
                                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        }
                                    }
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isFollowing ? themeManager.currentTheme.separatorColor : Color.clear, lineWidth: 1)
                                )
                            }
                            
                            Button(action: {
                                showingCopySettings = true
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                    Text("Copy Trades")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.Theme.accent)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Stats Overview
                        StatsOverviewView(trader: trader)
                            .padding(.horizontal)
                        
                        // Tab Selection
                        Picker("", selection: $selectedTab) {
                            Text("Performance").tag(0)
                            Text("Statistics").tag(1)
                            Text("Recent Trades").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // Tab Content
                        switch selectedTab {
                        case 0:
                            PerformanceTabView(trader: trader)
                        case 1:
                            StatisticsTabView(trader: trader)
                        case 2:
                            RecentTradesTabView(trader: trader)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .navigationTitle("Trader Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            .sheet(isPresented: $showingCopySettings) {
                CopyTradingSettingsView(trader: trader)
            }
        }
    }
}

// MARK: - Profile Header

struct TraderProfileHeaderView: View {
    let trader: Trader
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            Circle()
                .fill(LinearGradient(
                    colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(trader.displayName.prefix(2))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(trader.isVerified ? Color.blue : Color.clear, lineWidth: 3)
                )
            
            // Name and Username
            VStack(spacing: 4) {
                HStack {
                    Text(trader.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    if trader.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                    }
                    
                    if trader.isPro {
                        Text("PRO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Text("@\(trader.username)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            // Bio
            Text(trader.bio)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Follower Stats
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("\(trader.followers)")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                VStack(spacing: 4) {
                    Text("\(trader.following)")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                VStack(spacing: 4) {
                    Text("\(trader.totalTrades)")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    Text("Trades")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Stats Overview

struct StatsOverviewView: View {
    let trader: Trader
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                TraderStatCard(
                    title: "Monthly Return",
                    value: trader.formattedMonthlyReturn,
                    color: trader.monthlyReturn >= 0 ? Color.Theme.success : Color.Theme.error,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                TraderStatCard(
                    title: "Win Rate",
                    value: trader.formattedWinRate,
                    color: Color.Theme.success,
                    icon: "checkmark.circle.fill"
                )
            }
            
            HStack(spacing: 12) {
                TraderStatCard(
                    title: "Risk Level",
                    value: trader.riskLevel.rawValue,
                    color: trader.riskLevel.color,
                    icon: "gauge"
                )
                
                TraderStatCard(
                    title: "Trading Style",
                    value: trader.tradingStyle.rawValue,
                    color: trader.tradingStyle.color,
                    icon: "waveform.path.ecg"
                )
            }
        }
    }
}

struct TraderStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            Spacer()
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Performance Tab

struct PerformanceTabView: View {
    let trader: Trader
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Equity Curve Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Equity Curve")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .padding(.horizontal)
                
                Chart(trader.performance.equityCurve) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Equity", point.equity)
                    )
                    .foregroundStyle(Color.Theme.accent)
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Equity", point.equity)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.Theme.accent.opacity(0.3), Color.Theme.accent.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .padding(.horizontal)
            }
            
            // Key Metrics
            VStack(spacing: 16) {
                TraderMetricRow(
                    title: "Sharpe Ratio",
                    value: String(format: "%.2f", trader.performance.sharpeRatio),
                    description: "Risk-adjusted returns"
                )
                
                TraderMetricRow(
                    title: "Max Drawdown",
                    value: String(format: "%.1f%%", trader.performance.maxDrawdown * 100),
                    description: "Largest peak-to-trough decline"
                )
                
                TraderMetricRow(
                    title: "Profit Factor",
                    value: String(format: "%.2f", trader.profitFactor),
                    description: "Gross profit / Gross loss"
                )
                
                TraderMetricRow(
                    title: "Average Trade",
                    value: String(format: "$%.2f", trader.averageReturn * 1000),
                    description: "Average profit per trade"
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// MARK: - Statistics Tab

struct StatisticsTabView: View {
    let trader: Trader
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Trading Statistics
            VStack(alignment: .leading, spacing: 16) {
                Text("Trading Statistics")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                TraderDetailStatRow(label: "Total Profit", value: String(format: "$%.2f", trader.stats.totalProfit))
                TraderDetailStatRow(label: "Total Loss", value: String(format: "$%.2f", trader.stats.totalLoss))
                TraderDetailStatRow(label: "Largest Win", value: String(format: "$%.2f", trader.stats.largestWin))
                TraderDetailStatRow(label: "Largest Loss", value: String(format: "$%.2f", trader.stats.largestLoss))
                TraderDetailStatRow(label: "Average Win", value: String(format: "$%.2f", trader.stats.averageWin))
                TraderDetailStatRow(label: "Average Loss", value: String(format: "$%.2f", trader.stats.averageLoss))
                TraderDetailStatRow(label: "Profit/Loss Ratio", value: String(format: "%.2f", trader.stats.profitLossRatio))
                TraderDetailStatRow(label: "Expectancy", value: String(format: "$%.2f", trader.stats.expectancy))
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
            
            // Favorite Symbols
            VStack(alignment: .leading, spacing: 12) {
                Text("Top Trading Symbols")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                ForEach(trader.stats.favoriteSymbols.prefix(5), id: \.self) { symbol in
                    HStack {
                        Text(symbol)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Spacer()
                        
                        if let successRate = trader.stats.successRateBySymbol[symbol] {
                            Text("\(String(format: "%.1f", successRate * 100))% win rate")
                                .font(.caption)
                                .foregroundColor(Color.Theme.success)
                        }
                    }
                }
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - Recent Trades Tab

struct RecentTradesTabView: View {
    let trader: Trader
    @EnvironmentObject var themeManager: ThemeManager
    
    // Mock recent trades
    var recentTrades: [RecentTrade] {
        [
            RecentTrade(symbol: "EURUSD", side: .buy, volume: 0.5, profit: 245.50, duration: "2h 15m", date: Date()),
            RecentTrade(symbol: "XAUUSD", side: .sell, volume: 0.1, profit: -125.00, duration: "45m", date: Date().addingTimeInterval(-3600)),
            RecentTrade(symbol: "GBPUSD", side: .buy, volume: 0.3, profit: 189.75, duration: "1h 30m", date: Date().addingTimeInterval(-7200)),
            RecentTrade(symbol: "BTCUSD", side: .sell, volume: 0.01, profit: 567.80, duration: "4h 20m", date: Date().addingTimeInterval(-10800))
        ]
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(recentTrades) { trade in
                RecentTradeRow(trade: trade)
            }
        }
        .padding()
    }
}

struct RecentTrade: Identifiable {
    let id = UUID()
    let symbol: String
    let side: TradeSide
    let volume: Double
    let profit: Double
    let duration: String
    let date: Date
}

struct RecentTradeRow: View {
    let trade: RecentTrade
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trade.symbol)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text(trade.side.rawValue.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(trade.side == .buy ? Color.Theme.buy : Color.Theme.sell)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Text(String(format: "%.2f lots • %@", trade.volume, trade.duration))
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(trade.profit >= 0 ? String(format: "+$%.2f", trade.profit) : String(format: "-$%.2f", abs(trade.profit)))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(trade.profit >= 0 ? Color.Theme.success : Color.Theme.error)
                
                Text(timeAgo(from: trade.date))
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Helper Views

struct TraderMetricRow: View {
    let title: String
    let value: String
    let description: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(Color.Theme.accent)
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct TraderDetailStatRow: View {
    let label: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
        }
    }
}

#Preview {
    TraderDetailView(trader: SocialTradingService.shared.topTraders.first!)
        .environmentObject(ThemeManager.shared)
}