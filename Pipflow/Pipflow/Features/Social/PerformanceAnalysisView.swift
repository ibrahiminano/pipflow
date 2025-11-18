//
//  PerformanceAnalysisView.swift
//  Pipflow
//
//  Detailed performance analysis view for traders
//

import SwiftUI
import Charts

struct PerformanceAnalysisView: View {
    let trader: Trader
    let analysis: TraderPerformanceAnalysis
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTimeframe: TimeFrame = .month
    
    enum TimeFrame: String, CaseIterable {
        case week = "1W"
        case month = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case year = "1Y"
        case all = "All"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Performance Overview
                    TraderPerformanceOverviewCard(
                        trader: trader,
                        analysis: analysis
                    )
                    
                    // Equity Curve Chart
                    EquityCurveChart(
                        trader: trader,
                        selectedTimeframe: $selectedTimeframe
                    )
                    
                    // Trading Statistics
                    TradingStatisticsCard(
                        trader: trader,
                        analysis: analysis
                    )
                    
                    // Symbol Distribution
                    SymbolDistributionCard(analysis: analysis)
                    
                    // Monthly Performance Heat Map
                    MonthlyPerformanceHeatMap(trader: trader)
                    
                    // Projected Performance
                    ProjectedPerformanceCard(analysis: analysis)
                }
                .padding()
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("\(trader.displayName) - Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Performance Overview Card

struct TraderPerformanceOverviewCard: View {
    let trader: Trader
    let analysis: TraderPerformanceAnalysis
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance Overview")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Real-time analysis based on current positions")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                // Live Indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.Theme.success)
                        .frame(width: 8, height: 8)
                    
                    Text("Live")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.Theme.success)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.Theme.success.opacity(0.2))
                .cornerRadius(12)
            }
            
            // Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                PerformanceMetricCard(
                    title: "Current P&L",
                    value: formatCurrency(analysis.currentPL),
                    subtitle: "Open positions",
                    color: analysis.currentPL >= 0 ? Color.Theme.success : Color.Theme.error
                )
                
                PerformanceMetricCard(
                    title: "Monthly Return",
                    value: formatPercentage(trader.monthlyReturn),
                    subtitle: "Average",
                    color: trader.monthlyReturn >= 0 ? Color.Theme.success : Color.Theme.error
                )
                
                PerformanceMetricCard(
                    title: "Win Rate",
                    value: formatPercentage(trader.winRate),
                    subtitle: "All time",
                    color: Color.Theme.accent
                )
                
                PerformanceMetricCard(
                    title: "Profit Factor",
                    value: String(format: "%.2f", trader.profitFactor),
                    subtitle: "Risk/Reward",
                    color: Color.blue
                )
            }
            
            // Consistency Score
            VStack(spacing: 8) {
                HStack {
                    Text("Consistency Score")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
                    
                    Text(formatPercentage(analysis.consistencyScore))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.Theme.accent)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeManager.currentTheme.backgroundColor)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * analysis.consistencyScore, height: 8)
                    }
                }
                .frame(height: 8)
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
    
    private func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", value * 100)
    }
}

// MARK: - Performance Metric Card

struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Equity Curve Chart

struct EquityCurveChart: View {
    let trader: Trader
    @Binding var selectedTimeframe: PerformanceAnalysisView.TimeFrame
    @EnvironmentObject var themeManager: ThemeManager
    
    var filteredData: [EquityPoint] {
        let allData = trader.performance.equityCurve
        let now = Date()
        
        switch selectedTimeframe {
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            return allData.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
            return allData.filter { $0.date >= monthAgo }
        case .threeMonths:
            let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
            return allData.filter { $0.date >= threeMonthsAgo }
        case .sixMonths:
            let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
            return allData.filter { $0.date >= sixMonthsAgo }
        case .year:
            let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
            return allData.filter { $0.date >= yearAgo }
        case .all:
            return allData
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Equity Curve")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                // Timeframe Selector
                HStack(spacing: 8) {
                    ForEach(PerformanceAnalysisView.TimeFrame.allCases, id: \.self) { timeframe in
                        Button(action: {
                            selectedTimeframe = timeframe
                        }) {
                            Text(timeframe.rawValue)
                                .font(.caption)
                                .fontWeight(selectedTimeframe == timeframe ? .semibold : .regular)
                                .foregroundColor(selectedTimeframe == timeframe ? .white : themeManager.currentTheme.textColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedTimeframe == timeframe ?
                                    Color.Theme.accent : themeManager.currentTheme.backgroundColor
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            if !filteredData.isEmpty {
                Chart(filteredData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Equity", point.equity)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Equity", point.equity)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.Theme.gradientStart.opacity(0.3), Color.Theme.gradientEnd.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let equity = value.as(Double.self) {
                                Text("$\(Int(equity/1000))k")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
            } else {
                Text("No data available for selected timeframe")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Trading Statistics Card

struct TradingStatisticsCard: View {
    let trader: Trader
    let analysis: TraderPerformanceAnalysis
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trading Statistics")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            VStack(spacing: 12) {
                TraderStatRow(title: "Total Trades", value: "\(trader.totalTrades)")
                TraderStatRow(title: "Open Positions", value: "\(analysis.currentOpenPositions)")
                TraderStatRow(title: "Avg Daily Trades", value: String(format: "%.1f", analysis.averageDailyTrades))
                TraderStatRow(title: "Avg Position Size", value: String(format: "%.2f lots", analysis.averagePositionSize))
                TraderStatRow(title: "Best Month", value: String(format: "+%.1f%%", analysis.bestMonthReturn * 100))
                TraderStatRow(title: "Worst Month", value: String(format: "%.1f%%", analysis.worstMonthReturn * 100))
                TraderStatRow(title: "Current Month", value: String(format: "%+.1f%%", analysis.currentMonthReturn * 100))
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Stat Row

struct TraderStatRow: View {
    let title: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.textColor)
        }
    }
}

// MARK: - Symbol Distribution Card

struct SymbolDistributionCard: View {
    let analysis: TraderPerformanceAnalysis
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Symbol Distribution")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Text("Diversification: \(Int(analysis.diversificationScore * 100))%")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            if !analysis.topTradedSymbols.isEmpty {
                VStack(spacing: 12) {
                    ForEach(analysis.topTradedSymbols, id: \.symbol) { item in
                        HStack {
                            Text(item.symbol)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Spacer()
                            
                            Text("\(item.count) trades")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(themeManager.currentTheme.backgroundColor)
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.Theme.accent)
                                        .frame(
                                            width: geometry.size.width * (Double(item.count) / Double(analysis.symbolDistribution.values.reduce(0, +))),
                                            height: 8
                                        )
                                }
                            }
                            .frame(width: 100, height: 8)
                        }
                    }
                }
            } else {
                Text("No active positions")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Monthly Performance Heat Map

struct MonthlyPerformanceHeatMap: View {
    let trader: Trader
    @EnvironmentObject var themeManager: ThemeManager
    
    var monthlyData: [(month: String, return: Double)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        return trader.performance.monthlyReturns.suffix(12).map { monthlyReturn in
            (formatter.string(from: monthlyReturn.month), monthlyReturn.returnPercentage)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Performance (Last 12 Months)")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(monthlyData, id: \.month) { data in
                    VStack(spacing: 4) {
                        Text(data.month)
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Text(String(format: "%+.1f%%", data.return * 100))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(heatMapColor(for: data.return))
                            )
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private func heatMapColor(for return: Double) -> Color {
        if `return` > 0.1 {
            return Color.Theme.success
        } else if `return` > 0.05 {
            return Color.Theme.success.opacity(0.8)
        } else if `return` > 0 {
            return Color.Theme.success.opacity(0.6)
        } else if `return` > -0.05 {
            return Color.orange
        } else {
            return Color.Theme.error
        }
    }
}

// MARK: - Projected Performance Card

struct ProjectedPerformanceCard: View {
    let analysis: TraderPerformanceAnalysis
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Projected Performance", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected Monthly")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Text(formatCurrency(analysis.projectedMonthlyReturn))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(analysis.projectedMonthlyReturn >= 0 ? Color.Theme.success : Color.Theme.error)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Current Month")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Text(String(format: "%+.1f%%", analysis.currentMonthReturn * 100))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(analysis.currentMonthReturn >= 0 ? Color.Theme.success : Color.Theme.error)
                }
            }
            
            Text("Based on current trading performance and historical patterns")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .italic()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
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