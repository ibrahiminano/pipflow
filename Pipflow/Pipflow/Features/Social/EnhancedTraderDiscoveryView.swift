//
//  EnhancedTraderDiscoveryView.swift
//  Pipflow
//
//  Enhanced trader discovery with real-time performance metrics
//

import SwiftUI
import Combine

struct EnhancedTraderDiscoveryView: View {
    @StateObject private var socialService = EnhancedSocialTradingService.shared
    @StateObject private var mirroringService = TradeMirroringService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedFilter = TraderFilter.all
    @State private var searchText = ""
    @State private var showingTraderDetail = false
    @State private var selectedTrader: Trader?
    @State private var showingRiskAnalysis = false
    @State private var showingPerformanceAnalysis = false
    @State private var sortOption = SortOption.performance
    
    enum SortOption: String, CaseIterable {
        case performance = "Performance"
        case risk = "Risk Score"
        case followers = "Followers"
        case winRate = "Win Rate"
        case recent = "Recent Activity"
    }
    
    var filteredAndSortedTraders: [Trader] {
        let filtered = selectedFilter.apply(to: socialService.topTraders)
            .filter { trader in
                searchText.isEmpty ||
                trader.displayName.localizedCaseInsensitiveContains(searchText) ||
                trader.username.localizedCaseInsensitiveContains(searchText)
            }
        
        return sortTraders(filtered, by: sortOption)
    }
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with real-time stats
                EnhancedDiscoveryHeader(mirroringService: mirroringService)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    TextField("Search traders...", text: $searchText)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                .padding()
                .background(themeManager.currentTheme.secondaryBackgroundColor)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)
                
                // Filters and Sort
                VStack(spacing: 12) {
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TraderFilter.allCases, id: \.self) { filter in
                                DiscoveryFilterPill(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter,
                                    theme: themeManager.currentTheme
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Sort Options
                    HStack {
                        Text("Sort by:")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(themeManager.currentTheme.accentColor)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Traders List with Real-time Updates
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredAndSortedTraders) { trader in
                            EnhancedTraderCard(
                                trader: trader,
                                performanceUpdate: socialService.traderPerformanceUpdates[trader.id],
                                onTap: {
                                    selectedTrader = trader
                                    showingTraderDetail = true
                                },
                                onViewRisk: {
                                    selectedTrader = trader
                                    showingRiskAnalysis = true
                                },
                                onViewPerformance: {
                                    selectedTrader = trader
                                    showingPerformanceAnalysis = true
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await socialService.loadTopTraders(filter: selectedFilter)
                }
            }
        }
        .navigationTitle("Discover Traders")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedTrader) { trader in
            if showingRiskAnalysis {
                RiskAnalysisView(
                    trader: trader,
                    riskAnalysis: socialService.getRiskAnalysis(for: trader)
                )
            } else if showingPerformanceAnalysis {
                PerformanceAnalysisView(
                    trader: trader,
                    analysis: socialService.getTraderPerformanceAnalysis(trader: trader)
                )
            } else {
                TraderDetailView(trader: trader)
            }
        }
        .onChange(of: selectedTrader) { _ in
            if selectedTrader == nil {
                showingRiskAnalysis = false
                showingPerformanceAnalysis = false
            }
        }
    }
    
    private func sortTraders(_ traders: [Trader], by option: SortOption) -> [Trader] {
        switch option {
        case .performance:
            return traders.sorted { $0.monthlyReturn > $1.monthlyReturn }
        case .risk:
            return traders.sorted { $0.riskScore < $1.riskScore }
        case .followers:
            return traders.sorted { $0.followers > $1.followers }
        case .winRate:
            return traders.sorted { $0.winRate > $1.winRate }
        case .recent:
            return traders.sorted { $0.lastActiveDate > $1.lastActiveDate }
        }
    }
}

// MARK: - Enhanced Discovery Header

struct EnhancedDiscoveryHeader: View {
    @ObservedObject var mirroringService: TradeMirroringService
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Copy Trading Overview")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                if !mirroringService.activeSessions.isEmpty {
                    Label("\(mirroringService.activeSessions.count) Active", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(Color.Theme.success)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.Theme.success.opacity(0.2))
                        .cornerRadius(20)
                }
            }
            
            if !mirroringService.activeSessions.isEmpty {
                HStack(spacing: 20) {
                    DiscoveryMetricCard(
                        title: "Total P&L",
                        value: formatCurrency(mirroringService.totalProfitLoss),
                        color: mirroringService.totalProfitLoss >= 0 ? Color.Theme.success : Color.Theme.error,
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    
                    DiscoveryMetricCard(
                        title: "Copied Trades",
                        value: "\(mirroringService.totalCopiedTrades)",
                        color: themeManager.currentTheme.accentColor,
                        icon: "arrow.triangle.2.circlepath"
                    )
                    
                    DiscoveryMetricCard(
                        title: "Active Positions",
                        value: "\(mirroringService.activePositions.count)",
                        color: Color.orange,
                        icon: "chart.bar.fill"
                    )
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Metric Card

struct DiscoveryMetricCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Trader Card

struct EnhancedTraderCard: View {
    let trader: Trader
    let performanceUpdate: TraderPerformanceUpdate?
    let onTap: () -> Void
    let onViewRisk: () -> Void
    let onViewPerformance: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var socialService = SocialTradingService.shared
    @State private var showingCopySettings = false
    
    var isFollowing: Bool {
        socialService.followedTraders.contains { $0.id == trader.id }
    }
    
    var isCopying: Bool {
        TradeMirroringService.shared.activeSessions.keys.contains(trader.id)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main Content
                HStack(spacing: 12) {
                    // Profile Image with Live Indicator
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(trader.displayName.prefix(2))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        // Live indicator
                        if isTraderActive(trader) {
                            Circle()
                                .fill(Color.Theme.success)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(themeManager.currentTheme.backgroundColor, lineWidth: 2)
                                )
                        }
                    }
                    
                    // Trader Info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(trader.displayName)
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            if trader.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            if trader.isPro {
                                Text("PRO")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Label("\(trader.followers)", systemImage: "person.2.fill")
                            Label(trader.formattedWinRate, systemImage: "chart.line.uptrend.xyaxis")
                            Label(trader.tradingStyle.rawValue, systemImage: "waveform.path.ecg")
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        // Real-time Performance Update
                        if let update = performanceUpdate {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.Theme.success)
                                    .frame(width: 6, height: 6)
                                
                                Text("Live")
                                    .font(.caption2)
                                    .foregroundColor(Color.Theme.success)
                                
                                Text("•")
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                
                                Text("\(update.openPositions) positions")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                
                                Text("•")
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                
                                Text(update.dailyPL >= 0 ? "+$\(Int(update.dailyPL))" : "-$\(Int(abs(update.dailyPL)))")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(update.dailyPL >= 0 ? Color.Theme.success : Color.Theme.error)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Performance & Actions
                    VStack(alignment: .trailing, spacing: 8) {
                        // Monthly Return
                        VStack(spacing: 2) {
                            Text(trader.formattedMonthlyReturn)
                                .font(.headline)
                                .foregroundColor(trader.monthlyReturn >= 0 ? Color.Theme.success : Color.Theme.error)
                            Text("Monthly")
                                .font(.caption2)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 8) {
                            if isCopying {
                                Button(action: {}) {
                                    Label("Copying", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(Color.Theme.success)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: { showingCopySettings = true }) {
                                    Text("Copy")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.Theme.accent)
                                        .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                
                Divider()
                    .background(themeManager.currentTheme.separatorColor)
                
                // Performance Metrics Bar
                HStack(spacing: 0) {
                    PerformanceMetricButton(
                        title: "Win Rate",
                        value: trader.formattedWinRate,
                        color: Color.Theme.success,
                        action: {}
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(themeManager.currentTheme.separatorColor)
                    
                    PerformanceMetricButton(
                        title: "Risk Score",
                        value: "\(trader.riskScore)/10",
                        color: riskScoreColor(trader.riskScore),
                        action: onViewRisk
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(themeManager.currentTheme.separatorColor)
                    
                    PerformanceMetricButton(
                        title: "Profit Factor",
                        value: String(format: "%.2f", trader.profitFactor),
                        color: themeManager.currentTheme.accentColor,
                        action: {}
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(themeManager.currentTheme.separatorColor)
                    
                    PerformanceMetricButton(
                        title: "Analysis",
                        value: "View",
                        color: Color.blue,
                        action: onViewPerformance
                    )
                }
            }
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(16)
            .shadow(color: themeManager.currentTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingCopySettings) {
            CopySettingsView(trader: trader) { settings in
                EnhancedSocialTradingService.shared.startCopyTrading(trader: trader, settings: settings)
            }
        }
    }
    
    private func isTraderActive(_ trader: Trader) -> Bool {
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        return trader.lastActiveDate > fiveMinutesAgo
    }
    
    private func riskScoreColor(_ score: Int) -> Color {
        switch score {
        case 1...3:
            return Color.Theme.success
        case 4...6:
            return Color.orange
        default:
            return Color.Theme.error
        }
    }
}

// MARK: - Performance Metric Button

struct PerformanceMetricButton: View {
    let title: String
    let value: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Pill

struct DiscoveryFilterPill: View {
    let title: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            theme.secondaryBackgroundColor
                        }
                    }
                )
                .cornerRadius(20)
        }
    }
}