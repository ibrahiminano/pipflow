//
//  AIStrategyDashboard.swift
//  Pipflow
//
//  Quick AI strategy monitoring dashboard
//

import SwiftUI
import Charts

struct AIStrategyDashboard: View {
    @StateObject private var viewModel = AIStrategyDashboardViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance Overview
                PerformanceOverviewCard(
                    totalStrategies: viewModel.totalStrategies,
                    activeStrategies: viewModel.activeStrategies,
                    todayPnL: viewModel.todayPnL,
                    winRate: viewModel.overallWinRate,
                    theme: themeManager.currentTheme
                )
                
                // Active Strategies List
                ActiveStrategiesSection(
                    strategies: viewModel.activeStrategiesList,
                    theme: themeManager.currentTheme
                )
                
                // Performance Chart
                if #available(iOS 16.0, *) {
                    AIStrategyPerformanceChartCard(
                        data: viewModel.performanceData,
                        theme: themeManager.currentTheme
                    )
                }
                
                // Risk Metrics
                AIStrategyRiskMetricsCard(
                    currentDrawdown: viewModel.currentDrawdown,
                    maxDrawdown: viewModel.maxDrawdown,
                    riskScore: viewModel.riskScore,
                    theme: themeManager.currentTheme
                )
                
                // Quick Actions
                QuickActionsCard(
                    theme: themeManager.currentTheme,
                    onPauseAll: viewModel.pauseAllStrategies,
                    onOptimize: viewModel.optimizeStrategies,
                    onBacktest: viewModel.runBacktest
                )
            }
            .padding()
        }
        .navigationTitle("AI Dashboard")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Performance Overview Card

struct PerformanceOverviewCard: View {
    let totalStrategies: Int
    let activeStrategies: Int
    let todayPnL: Double
    let winRate: Double
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Performance Overview")
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Text("Today")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            HStack(spacing: 20) {
                AIStrategyMetricItem(
                    title: "Active",
                    value: "\(activeStrategies)/\(totalStrategies)",
                    icon: "brain",
                    color: .blue,
                    theme: theme
                )
                
                AIStrategyMetricItem(
                    title: "P&L",
                    value: String(format: "$%.2f", todayPnL),
                    icon: "chart.line.uptrend.xyaxis",
                    color: todayPnL >= 0 ? .green : .red,
                    theme: theme
                )
                
                AIStrategyMetricItem(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", winRate),
                    icon: "target",
                    color: .orange,
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct AIStrategyMetricItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active Strategies Section

struct ActiveStrategiesSection: View {
    let strategies: [ActiveStrategy]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Strategies")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            ForEach(strategies) { strategy in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(strategy.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textColor)
                        
                        Text("\(strategy.tradestoday) trades today")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "$%.2f", strategy.todayPnL))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(strategy.todayPnL >= 0 ? .green : .red)
                    
                    Circle()
                        .fill(strategy.isActive ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                }
                .padding(12)
                .background(theme.backgroundColor)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Performance Chart

@available(iOS 16.0, *)
struct AIStrategyPerformanceChartCard: View {
    let data: [PerformanceDataPoint]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Performance")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("P&L", point.pnl)
                )
                .foregroundStyle(theme.accentColor)
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("P&L", point.pnl)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentColor.opacity(0.3), theme.accentColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 200)
            .chartYScale(domain: .automatic(includesZero: true))
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Risk Metrics

struct AIStrategyRiskMetricsCard: View {
    let currentDrawdown: Double
    let maxDrawdown: Double
    let riskScore: Int
    let theme: Theme
    
    var riskColor: Color {
        if riskScore < 4 { return .green }
        else if riskScore < 7 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Risk Analysis")
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Risk Score:")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text("\(riskScore)/10")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(riskColor)
                }
            }
            
            VStack(spacing: 12) {
                DashboardRiskMetricRow(
                    label: "Current Drawdown",
                    value: String(format: "%.2f%%", currentDrawdown),
                    progress: abs(currentDrawdown) / 20,
                    color: currentDrawdown > -5 ? .green : (currentDrawdown > -10 ? .orange : .red),
                    theme: theme
                )
                
                DashboardRiskMetricRow(
                    label: "Max Drawdown",
                    value: String(format: "%.2f%%", maxDrawdown),
                    progress: abs(maxDrawdown) / 20,
                    color: .gray,
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct DashboardRiskMetricRow: View {
    let label: String
    let value: String
    let progress: Double
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                Spacer()
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.separatorColor)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Quick Actions

struct QuickActionsCard: View {
    let theme: Theme
    let onPauseAll: () -> Void
    let onOptimize: () -> Void
    let onBacktest: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                AIStrategyActionButton(
                    title: "Pause All",
                    icon: "pause.circle",
                    color: .orange,
                    theme: theme,
                    action: onPauseAll
                )
                
                AIStrategyActionButton(
                    title: "Optimize",
                    icon: "sparkles",
                    color: .blue,
                    theme: theme,
                    action: onOptimize
                )
                
                AIStrategyActionButton(
                    title: "Backtest",
                    icon: "clock.arrow.circlepath",
                    color: .purple,
                    theme: theme,
                    action: onBacktest
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct AIStrategyActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - View Model

class AIStrategyDashboardViewModel: ObservableObject {
    @Published var totalStrategies = 5
    @Published var activeStrategies = 3
    @Published var todayPnL = 245.67
    @Published var overallWinRate = 68.5
    @Published var currentDrawdown = -3.2
    @Published var maxDrawdown = -8.5
    @Published var riskScore = 4
    @Published var performanceData: [PerformanceDataPoint] = []
    @Published var activeStrategiesList: [ActiveStrategy] = []
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        // Mock performance data
        let calendar = Calendar.current
        performanceData = (0..<7).map { days in
            PerformanceDataPoint(
                date: calendar.date(byAdding: .day, value: -days, to: Date())!,
                pnl: Double.random(in: -200...400)
            )
        }.reversed()
        
        // Mock active strategies
        activeStrategiesList = [
            ActiveStrategy(name: "EUR/USD Scalper", tradestoday: 12, todayPnL: 125.50, isActive: true),
            ActiveStrategy(name: "Trend Follower", tradestoday: 3, todayPnL: 180.00, isActive: true),
            ActiveStrategy(name: "News Trader", tradestoday: 0, todayPnL: -60.00, isActive: false)
        ]
    }
    
    func pauseAllStrategies() {
        // Implement pause all
    }
    
    func optimizeStrategies() {
        // Implement optimization
    }
    
    func runBacktest() {
        // Implement backtest
    }
}

struct PerformanceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let pnl: Double
}

struct ActiveStrategy: Identifiable {
    let id = UUID()
    let name: String
    let tradestoday: Int
    let todayPnL: Double
    let isActive: Bool
}