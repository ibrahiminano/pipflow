//
//  TradeStatisticsCard.swift
//  Pipflow
//
//  Trade statistics display card
//

import SwiftUI

struct TradeStatisticsCard: View {
    let metrics: AnalyticsPerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trade Statistics")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatisticItem(
                    icon: "calendar",
                    title: "Trading Days",
                    value: "\(metrics.tradingDays)",
                    subtitle: "\(metrics.activeDays) active"
                )
                
                StatisticItem(
                    icon: "chart.bar",
                    title: "Avg Trades/Day",
                    value: String(format: "%.1f", metrics.averageTradesPerDay),
                    subtitle: nil
                )
                
                StatisticItem(
                    icon: "clock",
                    title: "Avg Hold Time",
                    value: formatDuration(metrics.averageHoldingPeriod),
                    subtitle: nil
                )
                
                StatisticItem(
                    icon: "square.stack",
                    title: "Max Positions",
                    value: "\(metrics.maxConcurrentPositions)",
                    subtitle: "concurrent"
                )
                
                StatisticItem(
                    icon: "dollarsign.circle",
                    title: "Expectancy",
                    value: formatCurrency(metrics.expectancy),
                    subtitle: "per trade",
                    valueColor: metrics.expectancy >= 0 ? Color.Theme.success : Color.Theme.error
                )
                
                StatisticItem(
                    icon: "scalemass",
                    title: "Avg Position",
                    value: String(format: "%.2f", metrics.averagePositionSize),
                    subtitle: "lots"
                )
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        
        if hours > 24 {
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct StatisticItem: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    var valueColor: Color = Color.Theme.text
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.Theme.accent)
                .frame(width: 32, height: 32)
                .background(Color.Theme.accent.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.Theme.secondaryText)
                
                HStack(spacing: 4) {
                    Text(value)
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(valueColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                }
            }
            
            Spacer()
        }
    }
}