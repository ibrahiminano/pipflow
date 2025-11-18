//
//  ProfileTradingView.swift
//  Pipflow
//
//  Trading performance tab for user profile
//

import SwiftUI
import Charts

struct ProfileTradingView: View {
    let profile: UserProfile?
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTimeframe = "1M"
    
    let timeframes = ["1W", "1M", "3M", "6M", "1Y", "All"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Equity Curve Chart
                ProfileEquityCurveChart(timeframe: selectedTimeframe)
                    .frame(height: 200)
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                
                // Timeframe Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(timeframes, id: \.self) { timeframe in
                            ProfileTimeframeButton(
                                title: timeframe,
                                isSelected: selectedTimeframe == timeframe,
                                action: { selectedTimeframe = timeframe }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Trading Style & Risk
                HStack(spacing: 16) {
                    TradingInfoCard(
                        title: "Trading Style",
                        value: profile?.tradingStyle.rawValue ?? "Unknown",
                        description: profile?.tradingStyle.description ?? "",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    
                    TradingInfoCard(
                        title: "Risk Level",
                        value: profile?.riskLevel.rawValue ?? "Unknown",
                        description: nil,
                        icon: profile?.riskLevel.icon ?? "gauge",
                        iconColor: profile?.riskLevel.color
                    )
                }
                .padding(.horizontal)
                
                // Performance Metrics
                PerformanceMetricsGrid(stats: profile?.stats)
                    .padding(.horizontal)
                
                // Trade Distribution
                TradeDistributionView(stats: profile?.stats)
                    .padding(.horizontal)
                
                // Monthly Performance
                MonthlyPerformanceChart()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Equity Curve Chart
struct ProfileEquityCurveChart: View {
    let timeframe: String
    @EnvironmentObject var themeManager: ThemeManager
    
    // Mock data for equity curve
    let data: [ProfileEquityPoint] = {
        var points: [ProfileEquityPoint] = []
        let startDate = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        var balance = 10000.0
        
        for i in 0..<30 {
            let date = startDate.addingTimeInterval(Double(i) * 24 * 60 * 60)
            let change = Double.random(in: -200...300)
            balance += change
            points.append(ProfileEquityPoint(date: date, balance: balance))
        }
        
        return points
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Equity Curve")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Chart(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(themeManager.currentTheme.accentColor)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            themeManager.currentTheme.accentColor.opacity(0.3),
                            themeManager.currentTheme.accentColor.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: (data.map { $0.balance }.min() ?? 0) * 0.95...(data.map { $0.balance }.max() ?? 0) * 1.05)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel()
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel()
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                }
            }
        }
    }
}

struct ProfileEquityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
}

// MARK: - Trading Info Card
struct TradingInfoCard: View {
    let title: String
    let value: String
    let description: String?
    let icon: String
    var iconColor: Color?
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor ?? themeManager.currentTheme.accentColor)
                
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text(value)
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Performance Metrics Grid
struct PerformanceMetricsGrid: View {
    let stats: UserStats?
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricItem(
                    label: "Total Return",
                    value: String(format: "%.1f%%", (stats?.totalReturn ?? 0) * 100),
                    isPositive: (stats?.totalReturn ?? 0) >= 0
                )
                
                MetricItem(
                    label: "Best Trade",
                    value: String(format: "$%.0f", stats?.bestTrade ?? 0),
                    isPositive: true
                )
                
                MetricItem(
                    label: "Worst Trade",
                    value: String(format: "$%.0f", stats?.worstTrade ?? 0),
                    isPositive: false
                )
                
                MetricItem(
                    label: "Win Streak",
                    value: "\(stats?.longestWinStreak ?? 0)",
                    isPositive: true
                )
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    let isPositive: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text(value)
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(isPositive ? Color.green : Color.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Trade Distribution
struct TradeDistributionView: View {
    let stats: UserStats?
    @EnvironmentObject var themeManager: ThemeManager
    
    var wins: Int {
        Int(Double(stats?.totalTrades ?? 0) * (stats?.winRate ?? 0))
    }
    
    var losses: Int {
        (stats?.totalTrades ?? 0) - wins
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trade Distribution")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            HStack(spacing: 20) {
                // Win/Loss Pie
                ZStack {
                    Circle()
                        .stroke(Color.red, lineWidth: 20)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(stats?.winRate ?? 0))
                        .stroke(Color.green, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("\(Int((stats?.winRate ?? 0) * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text("Win Rate")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                .frame(width: 100, height: 100)
                
                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        
                        Text("Wins: \(wins)")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text("Losses: \(losses)")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                    
                    HStack {
                        Circle()
                            .fill(themeManager.currentTheme.accentColor)
                            .frame(width: 12, height: 12)
                        
                        Text("Total: \(stats?.totalTrades ?? 0)")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Monthly Performance Chart
struct MonthlyPerformanceChart: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    // Mock monthly data
    let monthlyData: [ProfileMonthlyPerformance] = {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        return months.map { month in
            ProfileMonthlyPerformance(
                month: month,
                return: Double.random(in: -0.1...0.2)
            )
        }
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Performance")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Chart(monthlyData) { data in
                BarMark(
                    x: .value("Month", data.month),
                    y: .value("Return", data.return)
                )
                .foregroundStyle(data.return >= 0 ? Color.green : Color.red)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel()
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct ProfileMonthlyPerformance: Identifiable {
    let id = UUID()
    let month: String
    let `return`: Double
}

// MARK: - Timeframe Button
struct ProfileTimeframeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(
                    isSelected
                        ? .white
                        : themeManager.currentTheme.secondaryTextColor
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? themeManager.currentTheme.accentColor
                        : themeManager.currentTheme.backgroundColor
                )
                .cornerRadius(20)
        }
    }
}