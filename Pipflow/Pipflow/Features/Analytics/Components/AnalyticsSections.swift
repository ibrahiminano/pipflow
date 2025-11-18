//
//  AnalyticsSections.swift
//  Pipflow
//
//  Supporting sections for analytics views
//

import SwiftUI

// MARK: - Trade Statistics Section

struct TradeStatisticsSection: View {
    let metrics: AnalyticsPerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trade Statistics")
                .font(.headline)
            
            VStack(spacing: 8) {
                DetailedMetricRow(title: "Total Trades", value: "\(metrics.totalTrades)")
                DetailedMetricRow(title: "Winning Trades", value: "\(metrics.winningTrades)")
                DetailedMetricRow(title: "Losing Trades", value: "\(metrics.losingTrades)")
                DetailedMetricRow(title: "Avg Trades/Day", value: String(format: "%.1f", metrics.averageTradesPerDay))
                DetailedMetricRow(title: "Avg Hold Time", value: formatDuration(metrics.averageHoldingPeriod))
            }
            .padding()
            .background(Color.Theme.secondary.opacity(0.3))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        if hours > 24 {
            return "\(hours / 24)d \(hours % 24)h"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(Int(interval) / 60)m"
        }
    }
}

// MARK: - Win/Loss Analysis Section

struct WinLossAnalysisSection: View {
    let metrics: AnalyticsPerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Win/Loss Analysis")
                .font(.headline)
            
            VStack(spacing: 8) {
                DetailedMetricRow(title: "Win Rate", value: "\(Int(metrics.winRate * 100))%")
                DetailedMetricRow(title: "Average Win", value: formatCurrency(metrics.averageWin))
                DetailedMetricRow(title: "Average Loss", value: formatCurrency(metrics.averageLoss))
                DetailedMetricRow(title: "Win/Loss Ratio", value: String(format: "%.2f", metrics.winLossRatio))
                DetailedMetricRow(title: "Expectancy", value: formatCurrency(metrics.expectancy))
            }
            .padding()
            .background(Color.Theme.secondary.opacity(0.3))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Risk Metrics Section

struct RiskMetricsSection: View {
    let metrics: AnalyticsPerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Metrics")
                .font(.headline)
            
            VStack(spacing: 8) {
                DetailedMetricRow(title: "Sharpe Ratio", value: String(format: "%.2f", metrics.sharpeRatio))
                DetailedMetricRow(title: "Sortino Ratio", value: String(format: "%.2f", metrics.sortinoRatio))
                DetailedMetricRow(title: "Calmar Ratio", value: String(format: "%.2f", metrics.calmarRatio))
                DetailedMetricRow(title: "Value at Risk", value: formatCurrency(metrics.valueAtRisk))
                DetailedMetricRow(title: "CVaR", value: formatCurrency(metrics.conditionalValueAtRisk))
            }
            .padding()
            .background(Color.Theme.secondary.opacity(0.3))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.Theme.cardBackground)
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

// MARK: - Exposure Breakdown Section

struct ExposureBreakdownSection: View {
    let exposure: ExposureAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exposure Breakdown")
                .font(.headline)
            
            // By Symbol
            VStack(alignment: .leading, spacing: 8) {
                Text("By Symbol")
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.secondaryText)
                
                ForEach(exposure.bySymbol.prefix(5)) { item in
                    HStack {
                        Text(item.symbol)
                            .font(.caption)
                        Spacer()
                        Text("\(item.percentage, specifier: "%.1f")%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
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

// MARK: - Correlation Matrix Section

struct CorrelationMatrixSection: View {
    let correlations: [SymbolCorrelation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symbol Correlations")
                .font(.headline)
            
            ForEach(correlations) { correlation in
                HStack {
                    Text("\(correlation.symbol1) / \(correlation.symbol2)")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.2f", correlation.correlation))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(colorForCorrelation(correlation.correlation))
                }
            }
            .padding()
            .background(Color.Theme.secondary.opacity(0.3))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private func colorForCorrelation(_ value: Double) -> Color {
        if value > 0.7 {
            return Color.Theme.error
        } else if value > 0.5 {
            return Color.Theme.warning
        } else if value < -0.5 {
            return Color.Theme.info
        } else {
            return Color.Theme.text
        }
    }
}

// MARK: - Distribution Sections

struct ProfitDistributionSection: View {
    let distribution: [ProfitBucket]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profit Distribution")
                .font(.headline)
            
            ForEach(distribution) { bucket in
                HStack {
                    Text(bucket.range)
                        .font(.caption)
                    Spacer()
                    Text("\(bucket.count) (\(bucket.percentage, specifier: "%.1f")%)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
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

struct TimeDistributionSection: View {
    let timeDistribution: [TimeDistribution]
    let dayDistribution: [DayPerformance]
    let hourDistribution: [HourPerformance]
    @State private var selectedView = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Time Distribution")
                    .font(.headline)
                Spacer()
                Picker("View", selection: $selectedView) {
                    Text("Duration").tag(0)
                    Text("Day").tag(1)
                    Text("Hour").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 180)
            }
            
            switch selectedView {
            case 0:
                ForEach(timeDistribution) { item in
                    HStack {
                        Text(item.duration)
                            .font(.caption)
                        Spacer()
                        Text("\(item.count) trades")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            case 1:
                ForEach(dayDistribution) { item in
                    HStack {
                        Text(item.dayOfWeek)
                            .font(.caption)
                        Spacer()
                        Text("\(item.tradeCount) trades")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            default:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(hourDistribution) { item in
                            VStack {
                                Text("\(item.hour)")
                                    .font(.caption2)
                                Rectangle()
                                    .fill(item.totalProfit > 0 ? Color.Theme.success : Color.Theme.error)
                                    .frame(width: 20, height: CGFloat(abs(item.totalProfit) / 10))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct SymbolPerformanceSection: View {
    let symbols: [SymbolPerformance]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symbol Performance")
                .font(.headline)
            
            ForEach(symbols) { symbol in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(symbol.symbol)
                            .font(.subheadline)
                        Text("\(symbol.tradeCount) trades")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(symbol.totalProfit))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(symbol.totalProfit >= 0 ? Color.Theme.success : Color.Theme.error)
                        Text("Win: \(Int(symbol.winRate * 100))%")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                }
                if symbol.id != symbols.last?.id {
                    Divider()
                }
            }
            .padding()
            .background(Color.Theme.secondary.opacity(0.3))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.Theme.cardBackground)
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