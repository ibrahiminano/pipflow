//
//  KeyMetricsGrid.swift
//  Pipflow
//
//  Grid displaying key performance metrics
//

import SwiftUI

struct KeyMetricsGrid: View {
    let metrics: AnalyticsPerformanceMetrics
    @State private var expandedSection: MetricSection? = nil
    
    enum MetricSection: String, CaseIterable {
        case returns = "Returns"
        case trading = "Trading"
        case risk = "Risk"
        
        var icon: String {
            switch self {
            case .returns: return "chart.line.uptrend.xyaxis"
            case .trading: return "arrow.left.arrow.right"
            case .risk: return "exclamationmark.shield"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(MetricSection.allCases, id: \.self) { section in
                MetricSectionView(
                    section: section,
                    metrics: metricsForSection(section),
                    isExpanded: expandedSection == section,
                    onTap: {
                        withAnimation(.spring()) {
                            expandedSection = expandedSection == section ? nil : section
                        }
                    }
                )
            }
        }
    }
    
    private func metricsForSection(_ section: MetricSection) -> [(String, String, Color?)] {
        switch section {
        case .returns:
            return [
                ("Total Return", formatPercent(metrics.totalReturn), metrics.totalReturn >= 0 ? Color.Theme.success : Color.Theme.error),
                ("Monthly Return", formatPercent(metrics.monthlyReturn), metrics.monthlyReturn >= 0 ? Color.Theme.success : Color.Theme.error),
                ("Max Drawdown", formatPercent(metrics.maxDrawdown), Color.Theme.error),
                ("Profit Factor", String(format: "%.2f", metrics.profitFactor), metrics.profitFactor >= 1 ? Color.Theme.success : Color.Theme.error)
            ]
        case .trading:
            return [
                ("Total Trades", "\(metrics.totalTrades)", nil),
                ("Win Rate", formatPercent(metrics.winRate * 100), metrics.winRate >= 0.5 ? Color.Theme.success : Color.Theme.error),
                ("Avg Win/Loss", String(format: "%.2f", metrics.winLossRatio), metrics.winLossRatio >= 1 ? Color.Theme.success : Color.Theme.error),
                ("Expectancy", formatCurrency(metrics.expectancy), metrics.expectancy >= 0 ? Color.Theme.success : Color.Theme.error)
            ]
        case .risk:
            return [
                ("Sharpe Ratio", String(format: "%.2f", metrics.sharpeRatio), metrics.sharpeRatio >= 1 ? Color.Theme.success : Color.Theme.warning),
                ("Sortino Ratio", String(format: "%.2f", metrics.sortinoRatio), metrics.sortinoRatio >= 1 ? Color.Theme.success : Color.Theme.warning),
                ("Value at Risk", formatCurrency(metrics.valueAtRisk), Color.Theme.error),
                ("Avg Exposure", formatPercent(metrics.exposure), nil)
            ]
        }
    }
    
    private func formatPercent(_ value: Double) -> String {
        return String(format: "%.1f%%", value)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct MetricSectionView: View {
    let section: KeyMetricsGrid.MetricSection
    let metrics: [(String, String, Color?)]
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack {
                    Label(section.rawValue, systemImage: section.icon)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.Theme.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(Color.Theme.cardBackground)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Metrics
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                        MetricRow(
                            title: metric.0,
                            value: metric.1,
                            valueColor: metric.2
                        )
                        
                        if index < metrics.count - 1 {
                            Divider()
                                .background(Color.Theme.divider)
                        }
                    }
                }
                .background(Color.Theme.cardBackground.opacity(0.5))
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.Theme.shadow, radius: 2, x: 0, y: 1)
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let valueColor: Color?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(valueColor ?? Color.Theme.text)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}