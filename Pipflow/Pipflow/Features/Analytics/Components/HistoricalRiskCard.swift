//
//  HistoricalRiskCard.swift
//  Pipflow
//
//  Historical risk metrics display
//

import SwiftUI

struct HistoricalRiskCard: View {
    let risk: HistoricalRiskMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historical Risk")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                RiskMetricItem(
                    title: "Avg Leverage",
                    value: String(format: "%.1fx", risk.averageLeverage),
                    subtitle: "Max: \(String(format: "%.1fx", risk.maxLeverage))",
                    icon: "gauge"
                )
                
                RiskMetricItem(
                    title: "Avg Exposure",
                    value: String(format: "%.1f%%", risk.averageExposure),
                    subtitle: "Max: \(String(format: "%.1f%%", risk.maxExposure))",
                    icon: "percent"
                )
                
                RiskMetricItem(
                    title: "Risk-Adj Return",
                    value: String(format: "%.2f", risk.riskAdjustedReturn),
                    subtitle: nil,
                    icon: "chart.line.uptrend.xyaxis",
                    valueColor: risk.riskAdjustedReturn >= 1 ? Color.Theme.success : Color.Theme.warning
                )
                
                RiskMetricItem(
                    title: "Max Losses",
                    value: "\(risk.maxConsecutiveLosses)",
                    subtitle: "consecutive",
                    icon: "arrow.down.to.line",
                    valueColor: Color.Theme.error
                )
                
                RiskMetricItem(
                    title: "Largest Loss",
                    value: formatCurrency(risk.largestDailyLoss),
                    subtitle: "daily",
                    icon: "exclamationmark.circle",
                    valueColor: Color.Theme.error
                )
                
                RiskMetricItem(
                    title: "Recovery Time",
                    value: "\(risk.recoveryTime)d",
                    subtitle: "from drawdown",
                    icon: "clock.arrow.circlepath"
                )
            }
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

struct RiskMetricItem: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    var valueColor: Color = Color.Theme.text
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color.Theme.accent)
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.Theme.secondaryText)
            }
            
            Text(value)
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Color.Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}