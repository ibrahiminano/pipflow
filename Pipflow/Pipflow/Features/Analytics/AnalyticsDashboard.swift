//
//  AnalyticsDashboard.swift
//  Pipflow
//
//  Main analytics dashboard showing trading performance metrics
//

import SwiftUI
import Charts

struct AnalyticsDashboard: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @StateObject private var tradingService = TradingService.shared
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var showingDetailedMetrics = false
    @State private var selectedMetricCategory: MetricCategory = .overview
    
    enum MetricCategory: String, CaseIterable {
        case overview = "Overview"
        case performance = "Performance"
        case risk = "Risk"
        case distribution = "Distribution"
        
        var icon: String {
            switch self {
            case .overview: return "chart.line.uptrend.xyaxis"
            case .performance: return "chart.bar"
            case .risk: return "exclamationmark.shield"
            case .distribution: return "chart.pie"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Selector
                    periodSelector
                    
                    // Summary Cards
                    if let summary = analyticsService.currentSummary {
                        summaryCards(summary)
                    }
                    
                    // Category Tabs
                    categoryTabs
                    
                    // Content based on selected category
                    switch selectedMetricCategory {
                    case .overview:
                        overviewContent
                    case .performance:
                        performanceContent
                    case .risk:
                        riskContent
                    case .distribution:
                        distributionContent
                    }
                }
                .padding()
            }
            .background(Color.Theme.background)
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDetailedMetrics.toggle() }) {
                        Image(systemName: "chart.bar.doc.horizontal")
                    }
                }
            }
            .sheet(isPresented: $showingDetailedMetrics) {
                DetailedMetricsView(period: selectedPeriod)
            }
        }
        .task {
            if let account = tradingService.activeAccount {
                // Convert String ID to UUID for analytics service
                if let accountUUID = UUID(uuidString: account.id) {
                    await analyticsService.loadAnalytics(for: accountUUID, period: selectedPeriod)
                } else {
                    // Use a default UUID if conversion fails
                    await analyticsService.loadAnalytics(for: UUID(), period: selectedPeriod)
                }
            }
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                    PeriodButton(
                        period: period,
                        isSelected: selectedPeriod == period
                    ) {
                        selectedPeriod = period
                        Task {
                            if let account = tradingService.activeAccount {
                                // Convert String ID to UUID for analytics service
                                if let accountUUID = UUID(uuidString: account.id) {
                                    await analyticsService.loadAnalytics(for: accountUUID, period: period)
                                } else {
                                    // Use a default UUID if conversion fails
                                    await analyticsService.loadAnalytics(for: UUID(), period: period)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Summary Cards
    
    private func summaryCards(_ summary: AnalyticsSummary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(
                title: "Balance",
                value: formatCurrency(summary.currentBalance),
                change: summary.dayChangePercent,
                icon: "dollarsign.circle.fill",
                color: Color.Theme.accent
            )
            
            SummaryCard(
                title: "Today's P&L",
                value: formatCurrency(summary.todayPnL),
                change: nil,
                icon: "chart.line.uptrend.xyaxis",
                color: summary.todayPnL >= 0 ? Color.Theme.success : Color.Theme.error
            )
            
            SummaryCard(
                title: "Open Positions",
                value: "\(summary.openPositions)",
                subtitle: formatCurrency(summary.unrealizedPnL),
                icon: "list.bullet.circle.fill",
                color: Color.Theme.info
            )
            
            SummaryCard(
                title: "Today's Trades",
                value: "\(summary.todayTrades)",
                change: nil,
                icon: "arrow.left.arrow.right.circle.fill",
                color: Color.Theme.warning
            )
        }
    }
    
    // MARK: - Category Tabs
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(MetricCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedMetricCategory == category
                    ) {
                        withAnimation {
                            selectedMetricCategory = category
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Overview Content
    
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Equity Curve
            if let equityCurve = analyticsService.equityCurve {
                AnalyticsEquityCurveChart(equityCurve: equityCurve)
                    .frame(height: 250)
                    .padding()
                    .background(Color.Theme.cardBackground)
                    .cornerRadius(16)
            }
            
            // Key Metrics
            if let metrics = analyticsService.performanceMetrics[selectedPeriod] {
                KeyMetricsGrid(metrics: metrics)
            }
        }
    }
    
    // MARK: - Performance Content
    
    private var performanceContent: some View {
        VStack(spacing: 20) {
            if let metrics = analyticsService.performanceMetrics[selectedPeriod] {
                // Win/Loss Stats
                WinLossStatistics(metrics: metrics)
                
                // Trade Statistics
                TradeStatisticsCard(metrics: metrics)
                
                // Return Metrics
                ReturnMetricsCard(metrics: metrics)
            }
        }
    }
    
    // MARK: - Risk Content
    
    private var riskContent: some View {
        VStack(spacing: 20) {
            if let riskAnalysis = analyticsService.riskAnalysis {
                // Current Risk
                CurrentRiskCard(risk: riskAnalysis.currentRisk)
                
                // Historical Risk
                HistoricalRiskCard(risk: riskAnalysis.historicalRisk)
                
                // Exposure Analysis
                ExposureAnalysisView(exposure: riskAnalysis.exposureAnalysis)
            }
        }
    }
    
    // MARK: - Distribution Content
    
    private var distributionContent: some View {
        VStack(spacing: 20) {
            if let distribution = analyticsService.tradeDistribution {
                // Profit Distribution
                ProfitDistributionChart(distribution: distribution.profitDistribution)
                    .frame(height: 250)
                    .padding()
                    .background(Color.Theme.cardBackground)
                    .cornerRadius(16)
                
                // Symbol Performance
                SymbolPerformanceList(symbols: distribution.symbolDistribution)
                
                // Time Analysis
                TimeAnalysisView(
                    dayDistribution: distribution.dayOfWeekDistribution,
                    hourDistribution: distribution.hourDistribution
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Supporting Views

struct PeriodButton: View {
    let period: AnalyticsPeriod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(period.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.Theme.accent : Color.Theme.cardBackground)
                .foregroundColor(isSelected ? .white : Color.Theme.text)
                .cornerRadius(20)
        }
    }
}

struct CategoryTab: View {
    let category: AnalyticsDashboard.MetricCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title3)
                Text(category.rawValue)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? Color.Theme.accent : Color.Theme.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.Theme.accent.opacity(0.1) : Color.clear)
            .cornerRadius(12)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var change: Double? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
                if let change = change {
                    ChangeIndicator(value: change)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.Theme.text)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.Theme.secondaryText)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
    }
}

struct ChangeIndicator: View {
    let value: Double
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: value >= 0 ? "arrow.up" : "arrow.down")
                .font(.caption2)
            Text("\(abs(value), specifier: "%.1f")%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(value >= 0 ? Color.Theme.success : Color.Theme.error)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((value >= 0 ? Color.Theme.success : Color.Theme.error).opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    AnalyticsDashboard()
}