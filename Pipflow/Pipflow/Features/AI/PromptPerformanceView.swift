//
//  PromptPerformanceView.swift
//  Pipflow
//
//  Analytics dashboard for AI prompt trading performance
//

import SwiftUI
import Charts

struct PromptPerformanceView: View {
    @StateObject private var promptEngine = PromptTradingEngine.shared
    @StateObject private var contextManager = ContextManager.shared
    @State private var selectedPromptId: String?
    @State private var timeRange: TimeRange = .week
    @State private var showingPromptDetail = false
    @State private var selectedMetric: MetricType = .profitLoss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    OverallStatsSection()
                    
                    // Performance Chart
                    PerformanceChartSection(
                        timeRange: $timeRange,
                        selectedMetric: $selectedMetric
                    )
                    
                    // Active Prompts List
                    ActivePromptsSection(
                        selectedPromptId: $selectedPromptId,
                        onPromptSelected: { promptId in
                            selectedPromptId = promptId
                            showingPromptDetail = true
                        }
                    )
                    
                    // Top Performing Strategies
                    TopStrategiesSection()
                    
                    // Risk Analysis
                    RiskAnalysisSection()
                }
                .padding()
            }
            .background(Color.Theme.background)
            .navigationTitle("Performance Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: { timeRange = range }) {
                                Label(range.displayName, systemImage: range.icon)
                            }
                        }
                    } label: {
                        Label(timeRange.displayName, systemImage: "calendar")
                    }
                }
            }
        }
        .sheet(isPresented: $showingPromptDetail) {
            if let promptId = selectedPromptId,
               let prompt = promptEngine.activePrompts.first(where: { $0.id == promptId }) {
                PromptDetailView(prompt: prompt)
            }
        }
    }
}

// MARK: - Overall Stats Section

struct OverallStatsSection: View {
    @StateObject private var engine = PromptTradingEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Performance")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                PerformanceStatCard(
                    title: "Total P&L",
                    value: formatCurrency(calculateTotalPL()),
                    change: calculatePLChange(),
                    icon: "dollarsign.circle",
                    color: calculateTotalPL() >= 0 ? .green : .red
                )
                
                PerformanceStatCard(
                    title: "Win Rate",
                    value: formatPercentage(calculateWinRate()),
                    change: nil,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                PerformanceStatCard(
                    title: "Active Prompts",
                    value: "\(engine.activePrompts.count)",
                    change: nil,
                    icon: "doc.text",
                    color: .purple
                )
                
                PerformanceStatCard(
                    title: "Total Trades",
                    value: "\(calculateTotalTrades())",
                    change: nil,
                    icon: "arrow.left.arrow.right",
                    color: .orange
                )
            }
        }
    }
    
    private func calculateTotalPL() -> Double {
        // Mock calculation - would come from actual trading data
        return 2456.78
    }
    
    private func calculatePLChange() -> Double {
        // Mock calculation
        return 0.125
    }
    
    private func calculateWinRate() -> Double {
        // Mock calculation
        return 0.68
    }
    
    private func calculateTotalTrades() -> Int {
        // Mock calculation
        return 234
    }
}

// MARK: - Performance Chart Section

struct PerformanceChartSection: View {
    @Binding var timeRange: TimeRange
    @Binding var selectedMetric: MetricType
    @State private var chartData: [ChartDataPoint] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance Chart")
                    .font(.headline)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(MetricType.allCases, id: \.self) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            Chart(chartData) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value(selectedMetric.displayName, dataPoint.value)
                )
                .foregroundStyle(Color.Theme.accent)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value(selectedMetric.displayName, dataPoint.value)
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
            .padding()
            .background(Color.Theme.cardBackground)
            .cornerRadius(12)
            .onAppear {
                loadChartData()
            }
            .onChange(of: timeRange) { _ in
                loadChartData()
            }
            .onChange(of: selectedMetric) { _ in
                loadChartData()
            }
        }
    }
    
    private func loadChartData() {
        // Generate mock data based on time range and metric
        let days = timeRange.days
        var data: [ChartDataPoint] = []
        
        for i in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let value: Double
            
            switch selectedMetric {
            case .profitLoss:
                value = Double.random(in: -500...1000) + Double(days - i) * 10
            case .winRate:
                value = Double.random(in: 0.5...0.8) * 100
            case .trades:
                value = Double.random(in: 5...20)
            case .sharpeRatio:
                value = Double.random(in: 0.5...2.5)
            }
            
            data.append(ChartDataPoint(date: date, value: value))
        }
        
        chartData = data.reversed()
    }
}

// MARK: - Active Prompts Section

struct ActivePromptsSection: View {
    @StateObject private var engine = PromptTradingEngine.shared
    @Binding var selectedPromptId: String?
    let onPromptSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Strategies")
                    .font(.headline)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
                
                Text("\(engine.activePrompts.count) Active")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
            
            LazyVStack(spacing: 12) {
                ForEach(engine.activePrompts.prefix(5), id: \.id) { prompt in
                    PromptPerformanceCard(
                        prompt: prompt,
                        isSelected: selectedPromptId == prompt.id,
                        onTap: { onPromptSelected(prompt.id) }
                    )
                }
            }
            
            if engine.activePrompts.count > 5 {
                Button(action: {}) {
                    Text("View All Strategies")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.accent)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Top Strategies Section

struct TopStrategiesSection: View {
    @State private var topStrategies: [StrategyPerformanceData] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Performing Strategies")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            ForEach(topStrategies.prefix(3), id: \.id) { strategy in
                TopStrategyCard(strategy: strategy)
            }
        }
        .onAppear {
            loadTopStrategies()
        }
    }
    
    private func loadTopStrategies() {
        // Mock data
        topStrategies = [
            StrategyPerformanceData(
                id: UUID().uuidString,
                name: "Conservative Forex",
                profitLoss: 1234.56,
                winRate: 0.72,
                totalTrades: 45,
                avgWin: 45.67,
                avgLoss: -23.45,
                maxDrawdown: -5.2
            ),
            StrategyPerformanceData(
                id: UUID().uuidString,
                name: "Gold Scalper",
                profitLoss: 890.12,
                winRate: 0.65,
                totalTrades: 123,
                avgWin: 12.34,
                avgLoss: -8.90,
                maxDrawdown: -3.8
            ),
            StrategyPerformanceData(
                id: UUID().uuidString,
                name: "Trend Follower",
                profitLoss: 567.89,
                winRate: 0.58,
                totalTrades: 28,
                avgWin: 89.12,
                avgLoss: -34.56,
                maxDrawdown: -7.1
            )
        ]
    }
}

// MARK: - Risk Analysis Section

struct RiskAnalysisSection: View {
    @State private var riskMetrics = RiskMetrics()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Analysis")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            VStack(spacing: 12) {
                PromptRiskMetricRow(
                    title: "Max Drawdown",
                    value: formatPercentage(riskMetrics.maxDrawdown),
                    color: riskColor(for: riskMetrics.maxDrawdown)
                )
                
                PromptRiskMetricRow(
                    title: "Sharpe Ratio",
                    value: String(format: "%.2f", riskMetrics.sharpeRatio),
                    color: sharpeColor(for: riskMetrics.sharpeRatio)
                )
                
                PromptRiskMetricRow(
                    title: "Risk per Trade",
                    value: formatPercentage(riskMetrics.avgRiskPerTrade),
                    color: .blue
                )
                
                PromptRiskMetricRow(
                    title: "Portfolio Heat",
                    value: formatPercentage(riskMetrics.portfolioHeat),
                    color: heatColor(for: riskMetrics.portfolioHeat)
                )
            }
            .padding()
            .background(Color.Theme.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private func riskColor(for drawdown: Double) -> Color {
        if drawdown < -0.1 { return .red }
        else if drawdown < -0.05 { return .orange }
        else { return .green }
    }
    
    private func sharpeColor(for ratio: Double) -> Color {
        if ratio > 2 { return .green }
        else if ratio > 1 { return .blue }
        else if ratio > 0 { return .orange }
        else { return .red }
    }
    
    private func heatColor(for heat: Double) -> Color {
        if heat > 0.1 { return .red }
        else if heat > 0.05 { return .orange }
        else { return .green }
    }
}

// MARK: - Supporting Views

struct PerformanceStatCard: View {
    let title: String
    let value: String
    let change: Double?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if let change = change {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(formatPercentage(abs(change)))
                            .font(.caption)
                    }
                    .foregroundColor(change >= 0 ? .green : .red)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.Theme.text)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.text.opacity(0.6))
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
    }
}

struct PromptPerformanceCard: View {
    let prompt: TradingPrompt
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var performance = PromptPerformanceData()
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Status Indicator
                Circle()
                    .fill(prompt.isActive ? Color.Theme.success : Color.gray)
                    .frame(width: 10, height: 10)
                
                // Prompt Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.Theme.text)
                    
                    Text("\(performance.totalTrades) trades • \(formatPercentage(performance.winRate)) win rate")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
                
                Spacer()
                
                // Performance
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(performance.profitLoss))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(performance.profitLoss >= 0 ? .green : .red)
                    
                    Text("Last 7 days")
                        .font(.caption2)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
            }
            .padding()
            .background(isSelected ? Color.Theme.accent.opacity(0.1) : Color.Theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.Theme.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadPerformance()
        }
    }
    
    private func loadPerformance() {
        // Mock performance data
        performance = PromptPerformanceData(
            profitLoss: Double.random(in: -500...1500),
            winRate: Double.random(in: 0.4...0.8),
            totalTrades: Int.random(in: 10...100)
        )
    }
}

struct TopStrategyCard: View {
    let strategy: StrategyPerformanceData
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(strategy.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
                
                Text(formatCurrency(strategy.profitLoss))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(strategy.profitLoss >= 0 ? .green : .red)
            }
            
            HStack(spacing: 20) {
                PromptMetricLabel(title: "Win Rate", value: formatPercentage(strategy.winRate))
                PromptMetricLabel(title: "Trades", value: "\(strategy.totalTrades)")
                PromptMetricLabel(title: "Avg Win", value: formatCurrency(strategy.avgWin))
                PromptMetricLabel(title: "Max DD", value: formatPercentage(strategy.maxDrawdown))
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
    }
}

struct PromptMetricLabel: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(Color.Theme.text.opacity(0.6))
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.Theme.text)
        }
    }
}

struct PromptRiskMetricRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.Theme.text)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Prompt Detail View

struct PromptDetailView: View {
    let prompt: TradingPrompt
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Performance Tab
                PromptPerformanceTab(prompt: prompt)
                    .tabItem {
                        Label("Performance", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(0)
                
                // Trades Tab
                PromptTradesTab(prompt: prompt)
                    .tabItem {
                        Label("Trades", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                // Settings Tab
                PromptSettingsTab(prompt: prompt)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(2)
            }
            .navigationTitle(prompt.title)
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

struct PromptPerformanceTab: View {
    let prompt: TradingPrompt
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance metrics
                Text("Detailed performance analysis coming soon")
                    .foregroundColor(Color.Theme.text.opacity(0.6))
                    .padding()
            }
        }
        .background(Color.Theme.background)
    }
}

struct PromptTradesTab: View {
    let prompt: TradingPrompt
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Trade history
                Text("Trade history coming soon")
                    .foregroundColor(Color.Theme.text.opacity(0.6))
                    .padding()
            }
        }
        .background(Color.Theme.background)
    }
}

struct PromptSettingsTab: View {
    let prompt: TradingPrompt
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Prompt settings
                Text("Settings and configuration coming soon")
                    .foregroundColor(Color.Theme.text.opacity(0.6))
                    .padding()
            }
        }
        .background(Color.Theme.background)
    }
}

// MARK: - Data Models

enum TimeRange: String, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case quarter = "3M"
    case year = "1Y"
    case all = "All"
    
    var displayName: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        case .all: return "All Time"
        }
    }
    
    var icon: String {
        switch self {
        case .day: return "sun.max"
        case .week: return "calendar"
        case .month: return "calendar.badge.clock"
        case .quarter: return "calendar.circle"
        case .year: return "calendar.badge.plus"
        case .all: return "infinity"
        }
    }
    
    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        case .all: return 1000
        }
    }
}

enum MetricType: String, CaseIterable {
    case profitLoss = "P&L"
    case winRate = "Win Rate"
    case trades = "Trades"
    case sharpeRatio = "Sharpe"
    
    var displayName: String { rawValue }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct PromptPerformanceData {
    var profitLoss: Double = 0
    var winRate: Double = 0
    var totalTrades: Int = 0
}

struct StrategyPerformanceData: Identifiable {
    let id: String
    let name: String
    let profitLoss: Double
    let winRate: Double
    let totalTrades: Int
    let avgWin: Double
    let avgLoss: Double
    let maxDrawdown: Double
}

struct RiskMetrics {
    var maxDrawdown: Double = -0.052
    var sharpeRatio: Double = 1.85
    var avgRiskPerTrade: Double = 0.018
    var portfolioHeat: Double = 0.045
}

// MARK: - Helper Functions

private func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
}

private func formatPercentage(_ value: Double) -> String {
    return String(format: "%.1f%%", value * 100)
}

#Preview {
    PromptPerformanceView()
}