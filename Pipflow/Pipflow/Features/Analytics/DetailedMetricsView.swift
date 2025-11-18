//
//  DetailedMetricsView.swift
//  Pipflow
//
//  Detailed metrics view with comprehensive analytics
//

import SwiftUI

struct DetailedMetricsView: View {
    let period: AnalyticsPeriod
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Performance Metrics
                performanceMetricsTab
                    .tag(0)
                    .tabItem {
                        Label("Performance", systemImage: "chart.line.uptrend.xyaxis")
                    }
                
                // Risk Analysis
                riskAnalysisTab
                    .tag(1)
                    .tabItem {
                        Label("Risk", systemImage: "exclamationmark.shield")
                    }
                
                // Trade Distribution
                tradeDistributionTab
                    .tag(2)
                    .tabItem {
                        Label("Distribution", systemImage: "chart.pie")
                    }
                
                // Trade Journal
                tradeJournalTab
                    .tag(3)
                    .tabItem {
                        Label("Journal", systemImage: "book")
                    }
            }
            .navigationTitle("Detailed Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Performance Metrics Tab
    
    private var performanceMetricsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let metrics = analyticsService.performanceMetrics[period] {
                    // Summary Card
                    DetailedPerformanceSummaryCard(metrics: metrics)
                    
                    // Return Analysis
                    ReturnAnalysisSection(metrics: metrics)
                    
                    // Trade Statistics
                    TradeStatisticsSection(metrics: metrics)
                    
                    // Win/Loss Analysis
                    WinLossAnalysisSection(metrics: metrics)
                }
            }
            .padding()
        }
        .background(Color.Theme.background)
    }
    
    // MARK: - Risk Analysis Tab
    
    private var riskAnalysisTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let riskAnalysis = analyticsService.riskAnalysis,
                   let metrics = analyticsService.performanceMetrics[period] {
                    // Risk Metrics
                    RiskMetricsSection(metrics: metrics)
                    
                    // Exposure Analysis
                    ExposureBreakdownSection(exposure: riskAnalysis.exposureAnalysis)
                    
                    // Correlation Matrix
                    CorrelationMatrixSection(correlations: riskAnalysis.correlations)
                }
            }
            .padding()
        }
        .background(Color.Theme.background)
    }
    
    // MARK: - Trade Distribution Tab
    
    private var tradeDistributionTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let distribution = analyticsService.tradeDistribution {
                    // Profit Distribution
                    ProfitDistributionSection(distribution: distribution.profitDistribution)
                    
                    // Time Distribution
                    TimeDistributionSection(
                        timeDistribution: distribution.timeDistribution,
                        dayDistribution: distribution.dayOfWeekDistribution,
                        hourDistribution: distribution.hourDistribution
                    )
                    
                    // Symbol Performance
                    SymbolPerformanceSection(symbols: distribution.symbolDistribution)
                }
            }
            .padding()
        }
        .background(Color.Theme.background)
    }
    
    // MARK: - Trade Journal Tab
    
    private var tradeJournalTab: some View {
        TradeJournalView()
    }
}

// MARK: - Supporting Sections

struct DetailedPerformanceSummaryCard: View {
    let metrics: AnalyticsPerformanceMetrics
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Performance Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DetailedSummaryMetric(
                    title: "Total Return",
                    value: String(format: "%.2f%%", metrics.totalReturn),
                    color: metrics.totalReturn >= 0 ? Color.Theme.success : Color.Theme.error
                )
                
                DetailedSummaryMetric(
                    title: "Sharpe Ratio",
                    value: String(format: "%.2f", metrics.sharpeRatio),
                    color: metrics.sharpeRatio >= 1 ? Color.Theme.success : Color.Theme.warning
                )
                
                DetailedSummaryMetric(
                    title: "Win Rate",
                    value: "\(Int(metrics.winRate * 100))%",
                    color: metrics.winRate >= 0.5 ? Color.Theme.success : Color.Theme.error
                )
                
                DetailedSummaryMetric(
                    title: "Profit Factor",
                    value: String(format: "%.2f", metrics.profitFactor),
                    color: metrics.profitFactor >= 1 ? Color.Theme.success : Color.Theme.error
                )
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct DetailedSummaryMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReturnAnalysisSection: View {
    let metrics: AnalyticsPerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Return Analysis")
                .font(.headline)
            
            VStack(spacing: 8) {
                DetailedMetricRow(title: "Daily Return", value: String(format: "%.2f%%", metrics.dailyReturn))
                DetailedMetricRow(title: "Monthly Return", value: String(format: "%.2f%%", metrics.monthlyReturn))
                DetailedMetricRow(title: "Max Drawdown", value: String(format: "%.2f%%", metrics.maxDrawdown))
                DetailedMetricRow(title: "DD Duration", value: "\(metrics.maxDrawdownDuration) days")
                DetailedMetricRow(title: "Return/DD Ratio", value: String(format: "%.2f", metrics.returnToDrawdownRatio))
            }
            .padding()
            .background(Color.Theme.secondary.opacity(0.3))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct DetailedMetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.Theme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.Theme.text)
        }
    }
}

#Preview {
    DetailedMetricsView(period: .month)
}