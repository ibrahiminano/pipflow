//
//  BacktestingComponents.swift
//  Pipflow
//
//  Supporting components for backtesting interface
//

import SwiftUI
import Charts

// MARK: - Key Metrics Grid

struct BacktestKeyMetricsGrid: View {
    let performance: BacktestPerformanceMetrics
    let statistics: BacktestStatistics
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Key Metrics")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                BacktestMetricCard(
                    title: "Max Drawdown",
                    value: String(format: "%.2f%%", performance.maxDrawdown),
                    icon: "arrow.down.to.line",
                    color: performance.maxDrawdown < 20 ? .green : .red,
                    theme: theme
                )
                
                BacktestMetricCard(
                    title: "Profit Factor",
                    value: String(format: "%.2f", performance.profitFactor),
                    icon: "chart.line.uptrend.xyaxis",
                    color: performance.profitFactor > 1.5 ? .green : .orange,
                    theme: theme
                )
                
                BacktestMetricCard(
                    title: "Total Trades",
                    value: "\(performance.numberOfTrades)",
                    icon: "arrow.left.arrow.right",
                    color: theme.accentColor,
                    theme: theme
                )
                
                BacktestMetricCard(
                    title: "Avg Win/Loss",
                    value: String(format: "%.2f", statistics.payoffRatio),
                    icon: "divide",
                    color: statistics.payoffRatio > 1.5 ? .green : .orange,
                    theme: theme
                )
                
                BacktestMetricCard(
                    title: "Calmar Ratio",
                    value: String(format: "%.2f", statistics.calmarRatio),
                    icon: "percent",
                    color: statistics.calmarRatio > 1 ? .green : .orange,
                    theme: theme
                )
                
                BacktestMetricCard(
                    title: "Expectancy",
                    value: String(format: "$%.2f", performance.expectancy),
                    icon: "dollarsign.circle",
                    color: performance.expectancy > 0 ? .green : .red,
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct BacktestMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.textColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding()
        .background(theme.backgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Monthly Returns Heatmap

struct MonthlyReturnsHeatmap: View {
    let monthlyReturns: [BacktestMonthlyReturn]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Returns")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            // Group returns by year
            let groupedReturns = Dictionary(grouping: monthlyReturns) { $0.year }
            let years = groupedReturns.keys.sorted()
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    // Month headers
                    HStack(spacing: 4) {
                        Text("Year")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                            .frame(width: 50)
                        
                        ForEach(["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"], id: \.self) { month in
                            Text(month)
                                .font(.caption2)
                                .foregroundColor(theme.secondaryTextColor)
                                .frame(width: 40)
                        }
                    }
                    
                    // Year rows
                    ForEach(years, id: \.self) { year in
                        HStack(spacing: 4) {
                            Text("\(year)")
                                .font(.caption)
                                .foregroundColor(theme.textColor)
                                .frame(width: 50)
                            
                            ForEach(1...12, id: \.self) { monthNum in
                                if let monthReturn = groupedReturns[year]?.first(where: { getMonthNumber($0.month) == monthNum }) {
                                    ReturnCell(
                                        value: monthReturn.returnValue,
                                        theme: theme
                                    )
                                } else {
                                    Rectangle()
                                        .fill(theme.separatorColor)
                                        .frame(width: 40, height: 30)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private func getMonthNumber(_ monthName: String) -> Int {
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return (monthNames.firstIndex(of: monthName) ?? 0) + 1
    }
}

struct ReturnCell: View {
    let value: Double
    let theme: Theme
    
    var backgroundColor: Color {
        if value > 5 {
            return Color.green.opacity(0.8)
        } else if value > 2 {
            return Color.green.opacity(0.5)
        } else if value > 0 {
            return Color.green.opacity(0.3)
        } else if value > -2 {
            return Color.red.opacity(0.3)
        } else if value > -5 {
            return Color.red.opacity(0.5)
        } else {
            return Color.red.opacity(0.8)
        }
    }
    
    var body: some View {
        Text(String(format: "%.1f", value))
            .font(.caption2)
            .foregroundColor(.white)
            .frame(width: 40, height: 30)
            .background(backgroundColor)
            .cornerRadius(4)
    }
}

// MARK: - Trades Tab

struct BacktestTradesTab: View {
    let trades: [BacktestTrade]
    let theme: Theme
    
    @State private var sortOrder = SortOrder.date
    @State private var filterType = FilterType.all
    
    enum SortOrder {
        case date, pnl, duration
    }
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case wins = "Wins"
        case losses = "Losses"
    }
    
    var filteredTrades: [BacktestTrade] {
        let filtered = trades.filter { trade in
            switch filterType {
            case .all: return true
            case .wins: return trade.pnl > 0
            case .losses: return trade.pnl <= 0
            }
        }
        
        return filtered.sorted { t1, t2 in
            switch sortOrder {
            case .date: return t1.exitDate > t2.exitDate
            case .pnl: return t1.pnl > t2.pnl
            case .duration: return t1.holdingPeriod > t2.holdingPeriod
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Bar
            HStack {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    Button(action: { filterType = filter }) {
                        Text(filter.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(filterType == filter ? .white : theme.textColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(filterType == filter ? theme.accentColor : theme.secondaryBackgroundColor)
                            )
                    }
                }
                
                Spacer()
                
                Menu {
                    Button("Sort by Date") { sortOrder = .date }
                    Button("Sort by P&L") { sortOrder = .pnl }
                    Button("Sort by Duration") { sortOrder = .duration }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding()
            
            // Trades List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTrades) { trade in
                        TradeCard(trade: trade, theme: theme)
                    }
                }
                .padding()
            }
        }
    }
}

struct TradeCard: View {
    let trade: BacktestTrade
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trade.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    Text(trade.direction == .long ? "Long" : "Short")
                        .font(.caption)
                        .foregroundColor(trade.direction == .long ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", trade.pnl))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(trade.pnl >= 0 ? .green : .red)
                    
                    Text(String(format: "%.2f%%", trade.pnlPercentage))
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            Divider()
                .background(theme.separatorColor)
            
            // Details
            HStack(spacing: 20) {
                BacktestTradeDetail(
                    label: "Entry",
                    value: String(format: "%.5f", trade.entryPrice),
                    theme: theme
                )
                
                BacktestTradeDetail(
                    label: "Exit",
                    value: String(format: "%.5f", trade.exitPrice),
                    theme: theme
                )
                
                BacktestTradeDetail(
                    label: "Duration",
                    value: formatDuration(trade.holdingPeriod),
                    theme: theme
                )
            }
            
            // Dates
            HStack {
                Text(formatDate(trade.entryDate))
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                
                Text(formatDate(trade.exitDate))
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                
                Spacer()
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let days = hours / 24
        
        if days > 0 {
            return "\(days)d \(hours % 24)h"
        } else {
            return "\(hours)h"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

struct BacktestTradeDetail: View {
    let label: String
    let value: String
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
            
            Text(value)
                .font(.caption)
                .foregroundColor(theme.textColor)
        }
    }
}

// MARK: - Charts Tab

@available(iOS 16.0, *)
struct BacktestChartsTab: View {
    let result: BacktestResult
    let theme: Theme
    
    @State private var selectedChart = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Chart Selector
            Picker("Chart Type", selection: $selectedChart) {
                Text("Equity Curve").tag(0)
                Text("Drawdown").tag(1)
                Text("P&L Distribution").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Chart View
            switch selectedChart {
            case 0:
                BacktestEquityCurveChart(
                    equityCurve: result.equityCurve,
                    theme: theme
                )
            case 1:
                DrawdownChart(
                    drawdownCurve: result.drawdownCurve,
                    theme: theme
                )
            case 2:
                PnLDistributionChart(
                    trades: result.trades,
                    theme: theme
                )
            default:
                EmptyView()
            }
        }
        .padding(.vertical)
    }
}

@available(iOS 16.0, *)
struct BacktestEquityCurveChart: View {
    let equityCurve: [BacktestEquityPoint]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Equity Curve")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .padding(.horizontal)
            
            Chart(equityCurve) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Equity", point.value)
                )
                .foregroundStyle(theme.accentColor)
                
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Equity", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentColor.opacity(0.3), theme.accentColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 250)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

@available(iOS 16.0, *)
struct DrawdownChart: View {
    let drawdownCurve: [DrawdownPoint]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drawdown")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .padding(.horizontal)
            
            Chart(drawdownCurve) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Drawdown", -point.drawdown)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.red.opacity(0.5), Color.red.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Drawdown", -point.drawdown)
                )
                .foregroundStyle(Color.red)
            }
            .frame(height: 250)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

@available(iOS 16.0, *)
struct PnLDistributionChart: View {
    let trades: [BacktestTrade]
    let theme: Theme
    
    var distributionData: [(range: String, count: Int)] {
        let bins = stride(from: -500, to: 500, by: 100).map { Double($0) }
        var distribution: [(String, Int)] = []
        
        for i in 0..<bins.count-1 {
            let count = trades.filter { trade in
                trade.pnl >= bins[i] && trade.pnl < bins[i+1]
            }.count
            
            let label = String(format: "$%.0f-%.0f", bins[i], bins[i+1])
            distribution.append((label, count))
        }
        
        return distribution
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("P&L Distribution")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .padding(.horizontal)
            
            Chart(distributionData, id: \.range) { item in
                BarMark(
                    x: .value("Range", item.range),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(theme.accentColor)
            }
            .frame(height: 250)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Statistics Tab

struct BacktestStatisticsTab: View {
    let result: BacktestResult
    let theme: Theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Trade Statistics
                StatisticsSection(
                    title: "Trade Statistics",
                    statistics: [
                        ("Total Trades", "\(result.performance.numberOfTrades)"),
                        ("Win Rate", String(format: "%.1f%%", result.performance.winRate)),
                        ("Average Win", String(format: "$%.2f", result.performance.averageWin)),
                        ("Average Loss", String(format: "$%.2f", result.performance.averageLoss)),
                        ("Largest Win", String(format: "$%.2f", result.statistics.largestWin)),
                        ("Largest Loss", String(format: "$%.2f", result.statistics.largestLoss)),
                        ("Consecutive Wins", "\(result.statistics.consecutiveWins)"),
                        ("Consecutive Losses", "\(result.statistics.consecutiveLosses)")
                    ],
                    theme: theme
                )
                
                // Performance Metrics
                StatisticsSection(
                    title: "Performance Metrics",
                    statistics: [
                        ("Total Return", String(format: "%.2f%%", result.performance.totalReturn)),
                        ("Annualized Return", String(format: "%.2f%%", result.performance.annualizedReturn)),
                        ("Sharpe Ratio", String(format: "%.2f", result.performance.sharpeRatio)),
                        ("Sortino Ratio", String(format: "%.2f", result.performance.sortinoRatio)),
                        ("Calmar Ratio", String(format: "%.2f", result.statistics.calmarRatio)),
                        ("Profit Factor", String(format: "%.2f", result.performance.profitFactor)),
                        ("Recovery Factor", String(format: "%.2f", result.statistics.recoveryFactor)),
                        ("Payoff Ratio", String(format: "%.2f", result.statistics.payoffRatio))
                    ],
                    theme: theme
                )
                
                // Risk Metrics
                StatisticsSection(
                    title: "Risk Metrics",
                    statistics: [
                        ("Max Drawdown", String(format: "%.2f%%", result.performance.maxDrawdown)),
                        ("Average Holding Period", formatDuration(result.statistics.averageHoldingPeriod)),
                        ("Exposure Time", String(format: "%.1f%%", result.statistics.exposureTime)),
                        ("Market Correlation", String(format: "%.2f", result.statistics.marketCorrelation)),
                        ("Expectancy", String(format: "$%.2f", result.performance.expectancy)),
                        ("Trades per Month", String(format: "%.1f", result.performance.averageTradesPerMonth))
                    ],
                    theme: theme
                )
            }
            .padding()
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let days = hours / 24
        
        if days > 0 {
            return "\(days)d \(hours % 24)h"
        } else {
            return "\(hours)h"
        }
    }
}

struct StatisticsSection: View {
    let title: String
    let statistics: [(String, String)]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            VStack(spacing: 8) {
                ForEach(statistics, id: \.0) { stat in
                    HStack {
                        Text(stat.0)
                            .font(.system(size: 14))
                            .foregroundColor(theme.secondaryTextColor)
                        
                        Spacer()
                        
                        Text(stat.1)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textColor)
                    }
                    
                    if stat.0 != statistics.last?.0 {
                        Divider()
                            .background(theme.separatorColor.opacity(0.5))
                    }
                }
            }
            .padding()
            .background(theme.backgroundColor)
            .cornerRadius(12)
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Strategy Comparison View

struct StrategyComparisonView: View {
    let strategies: [TradingStrategy]
    let symbol: String
    let startDate: Date
    let endDate: Date
    let theme: Theme
    
    @State private var comparisonResults: [BacktestResult] = []
    @State private var isComparing = false
    @StateObject private var backtestingEngine = BacktestingEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            if isComparing {
                VStack(spacing: 30) {
                    Spacer()
                    
                    ProgressView("Comparing Strategies...")
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
                        .scaleEffect(1.5)
                    
                    Text("Running backtests for \(strategies.count) strategies")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.backgroundColor)
            } else if !comparisonResults.isEmpty {
                ComparisonResultsView(
                    results: comparisonResults,
                    theme: theme
                )
            } else {
                Text("No results yet")
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .navigationTitle("Strategy Comparison")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            runComparison()
        }
    }
    
    private func runComparison() {
        isComparing = true
        
        Task {
            do {
                let results = try await backtestingEngine.compareStrategies(
                    strategies,
                    on: symbol,
                    from: startDate,
                    to: endDate
                )
                
                await MainActor.run {
                    comparisonResults = results
                    isComparing = false
                }
            } catch {
                print("Comparison error: \(error)")
                isComparing = false
            }
        }
    }
}

struct ComparisonResultsView: View {
    let results: [BacktestResult]
    let theme: Theme
    
    var sortedResults: [BacktestResult] {
        results.sorted { $0.performance.totalReturn > $1.performance.totalReturn }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Comparison Chart
                if #available(iOS 16.0, *) {
                    ComparisonChart(results: results, theme: theme)
                }
                
                // Strategy Rankings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Strategy Rankings")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    ForEach(Array(sortedResults.enumerated()), id: \.element.id) { index, result in
                        StrategyRankingCard(
                            rank: index + 1,
                            result: result,
                            theme: theme
                        )
                    }
                }
                .padding()
            }
        }
    }
}

@available(iOS 16.0, *)
struct ComparisonChart: View {
    let results: [BacktestResult]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Comparison")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            Chart(results) { result in
                BarMark(
                    x: .value("Strategy", result.strategy.name),
                    y: .value("Return", result.performance.totalReturn)
                )
                .foregroundStyle(result.performance.totalReturn >= 0 ? Color.green : Color.red)
            }
            .frame(height: 200)
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct StrategyRankingCard: View {
    let rank: Int
    let result: BacktestResult
    let theme: Theme
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return theme.secondaryTextColor
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("#\(rank)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 40)
            
            // Strategy Info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.strategy.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                
                Text(result.strategy.description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Key Metrics
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f%%", result.performance.totalReturn))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(result.performance.totalReturn >= 0 ? .green : .red)
                
                HStack(spacing: 8) {
                    Label(String(format: "%.1f%%", result.performance.winRate), systemImage: "checkmark")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Label(String(format: "%.2f", result.performance.sharpeRatio), systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(theme.backgroundColor)
        .cornerRadius(12)
    }
}