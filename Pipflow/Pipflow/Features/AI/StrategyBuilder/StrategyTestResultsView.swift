//
//  StrategyTestResultsView.swift
//  Pipflow
//
//  Strategy test results visualization
//

import SwiftUI
import Charts

struct StrategyTestResultsView: View {
    let results: StrategyTestResults?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            if let results = results {
                TabView(selection: $selectedTab) {
                    // Overview
                    overviewTab(results)
                        .tabItem {
                            Label("Overview", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(0)
                    
                    // Performance
                    performanceTab(results)
                        .tabItem {
                            Label("Performance", systemImage: "chart.bar")
                        }
                        .tag(1)
                    
                    // Validation
                    validationTab(results)
                        .tabItem {
                            Label("Validation", systemImage: "checkmark.shield")
                        }
                        .tag(2)
                }
                .navigationTitle("Strategy Test Results")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            } else {
                Text("No results available")
                    .foregroundColor(Color.Theme.secondaryText)
            }
        }
    }
    
    // MARK: - Overview Tab
    
    private func overviewTab(_ results: StrategyTestResults) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Key Metrics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Key Metrics")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricCard(
                            title: "Total Return",
                            value: String(format: "%.2f%%", results.totalReturn),
                            color: results.totalReturn >= 0 ? Color.Theme.success : Color.Theme.error
                        )
                        
                        MetricCard(
                            title: "Win Rate",
                            value: String(format: "%.1f%%", results.winRate),
                            color: results.winRate >= 50 ? Color.Theme.success : Color.Theme.error
                        )
                        
                        MetricCard(
                            title: "Profit Factor",
                            value: String(format: "%.2f", results.profitFactor),
                            color: results.profitFactor >= 1 ? Color.Theme.success : Color.Theme.error
                        )
                        
                        MetricCard(
                            title: "Max Drawdown",
                            value: String(format: "%.2f%%", abs(results.maxDrawdown)),
                            color: Color.Theme.warning
                        )
                    }
                }
                .padding()
                .background(Color.Theme.cardBackground)
                .cornerRadius(16)
                
                // Trade Statistics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Trade Statistics")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        StrategyStatRow(label: "Total Trades", value: "\(results.totalTrades)")
                        StrategyStatRow(label: "Winning Trades", value: "\(results.profitableTrades)", color: Color.Theme.success)
                        StrategyStatRow(label: "Losing Trades", value: "\(results.losingTrades)", color: Color.Theme.error)
                        Divider()
                        StrategyStatRow(label: "Average Win", value: formatCurrency(results.averageWin))
                        StrategyStatRow(label: "Average Loss", value: formatCurrency(results.averageLoss))
                        StrategyStatRow(label: "Win/Loss Ratio", value: String(format: "%.2f", results.averageWin / abs(results.averageLoss)))
                    }
                }
                .padding()
                .background(Color.Theme.cardBackground)
                .cornerRadius(16)
                
                // Risk Metrics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Risk Metrics")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        StrategyStatRow(label: "Sharpe Ratio", value: String(format: "%.2f", results.sharpeRatio))
                        StrategyStatRow(label: "Max Drawdown", value: String(format: "%.2f%%", abs(results.maxDrawdown)))
                        StrategyStatRow(label: "Risk/Reward", value: String(format: "%.2f", results.profitFactor))
                    }
                }
                .padding()
                .background(Color.Theme.cardBackground)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(Color.Theme.background)
    }
    
    // MARK: - Performance Tab
    
    private func performanceTab(_ results: StrategyTestResults) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Win/Loss Distribution
                VStack(alignment: .leading, spacing: 16) {
                    Text("Win/Loss Distribution")
                        .font(.headline)
                    
                    Chart {
                        BarMark(
                            x: .value("Type", "Wins"),
                            y: .value("Count", results.profitableTrades)
                        )
                        .foregroundStyle(Color.Theme.success)
                        
                        BarMark(
                            x: .value("Type", "Losses"),
                            y: .value("Count", results.losingTrades)
                        )
                        .foregroundStyle(Color.Theme.error)
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Color.Theme.text)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                                .foregroundStyle(Color.Theme.divider.opacity(0.3))
                            AxisValueLabel()
                                .foregroundStyle(Color.Theme.secondaryText)
                        }
                    }
                }
                .padding()
                .background(Color.Theme.cardBackground)
                .cornerRadius(16)
                
                // Monthly Returns (Mock)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Monthly Returns")
                        .font(.headline)
                    
                    Chart(mockMonthlyReturns()) { item in
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Return", item.returnValue)
                        )
                        .foregroundStyle(item.returnValue >= 0 ? Color.Theme.success : Color.Theme.error)
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Color.Theme.text)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                                .foregroundStyle(Color.Theme.divider.opacity(0.3))
                            AxisValueLabel()
                                .foregroundStyle(Color.Theme.secondaryText)
                        }
                    }
                }
                .padding()
                .background(Color.Theme.cardBackground)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(Color.Theme.background)
    }
    
    // MARK: - Validation Tab
    
    private func validationTab(_ results: StrategyTestResults) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Errors
                if !results.errors.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.Theme.error)
                            Text("Errors")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(results.errors, id: \.self) { error in
                                HStack(alignment: .top) {
                                    Image(systemName: "circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(Color.Theme.error)
                                        .padding(.top, 4)
                                    
                                    Text(error)
                                        .font(.subheadline)
                                        .foregroundColor(Color.Theme.text)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.Theme.error.opacity(0.1))
                    .cornerRadius(16)
                }
                
                // Warnings
                if !results.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color.Theme.warning)
                            Text("Warnings")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(results.warnings, id: \.self) { warning in
                                HStack(alignment: .top) {
                                    Image(systemName: "circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(Color.Theme.warning)
                                        .padding(.top, 4)
                                    
                                    Text(warning)
                                        .font(.subheadline)
                                        .foregroundColor(Color.Theme.text)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.Theme.warning.opacity(0.1))
                    .cornerRadius(16)
                }
                
                // Success Message
                if results.errors.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.Theme.success)
                            Text("Validation Passed")
                                .font(.headline)
                        }
                        
                        Text("Your strategy passed all validation checks and is ready for deployment.")
                            .font(.subheadline)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                    .padding()
                    .background(Color.Theme.success.opacity(0.1))
                    .cornerRadius(16)
                }
                
                // Recommendations
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recommendations")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        StrategyRecommendationRow(
                            icon: "lightbulb",
                            text: "Consider adding a trailing stop to protect profits",
                            type: .suggestion
                        )
                        
                        StrategyRecommendationRow(
                            icon: "chart.line.uptrend.xyaxis",
                            text: "Test strategy on different timeframes for robustness",
                            type: .suggestion
                        )
                        
                        StrategyRecommendationRow(
                            icon: "calendar",
                            text: "Backtest over a longer period (at least 2 years)",
                            type: .suggestion
                        )
                        
                        if results.sharpeRatio < 1 {
                            StrategyRecommendationRow(
                                icon: "exclamationmark.triangle",
                                text: "Low Sharpe ratio indicates poor risk-adjusted returns",
                                type: .warning
                            )
                        }
                    }
                }
                .padding()
                .background(Color.Theme.cardBackground)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(Color.Theme.background)
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    private func mockMonthlyReturns() -> [StrategyMonthlyReturn] {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        return months.map { month in
            StrategyMonthlyReturn(month: month, returnValue: Double.random(in: -5...10))
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.Theme.secondary.opacity(0.3))
        .cornerRadius(12)
    }
}

struct StrategyStatRow: View {
    let label: String
    let value: String
    var color: Color = Color.Theme.text
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.Theme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct StrategyRecommendationRow: View {
    let icon: String
    let text: String
    let type: RecommendationType
    
    enum RecommendationType {
        case suggestion
        case warning
        
        var color: Color {
            switch self {
            case .suggestion: return Color.Theme.info
            case .warning: return Color.Theme.warning
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(type.color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.Theme.text)
            
            Spacer()
        }
    }
}

struct StrategyMonthlyReturn: Identifiable {
    let id = UUID()
    let month: String
    let returnValue: Double
}

#Preview {
    StrategyTestResultsView(
        results: StrategyTestResults(
            totalReturn: 25.5,
            winRate: 65.0,
            profitFactor: 1.8,
            maxDrawdown: -12.5,
            sharpeRatio: 1.5,
            totalTrades: 100,
            profitableTrades: 65,
            losingTrades: 35,
            averageWin: 150,
            averageLoss: -75,
            errors: [],
            warnings: ["High risk per trade: 3%"]
        )
    )
}