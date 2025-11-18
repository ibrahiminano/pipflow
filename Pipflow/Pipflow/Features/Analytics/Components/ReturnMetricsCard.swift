//
//  ReturnMetricsCard.swift
//  Pipflow
//
//  Return metrics display card
//

import SwiftUI
import Charts

struct ReturnMetricsCard: View {
    let metrics: AnalyticsPerformanceMetrics
    
    private var returnData: [(String, Double, Color)] {
        [
            ("Daily", metrics.dailyReturn, metrics.dailyReturn >= 0 ? Color.Theme.success : Color.Theme.error),
            ("Monthly", metrics.monthlyReturn, metrics.monthlyReturn >= 0 ? Color.Theme.success : Color.Theme.error),
            ("Total", metrics.totalReturn, metrics.totalReturn >= 0 ? Color.Theme.success : Color.Theme.error)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Return Metrics")
                .font(.headline)
            
            // Return Chart
            Chart(returnData, id: \.0) { item in
                BarMark(
                    x: .value("Period", item.0),
                    y: .value("Return", item.1)
                )
                .foregroundStyle(item.2)
                .cornerRadius(4)
                .annotation(position: .top) {
                    Text("\(item.1, specifier: "%.1f")%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(item.2)
                }
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(Color.Theme.divider.opacity(0.5))
                    AxisValueLabel {
                        if let intValue = value.as(Double.self) {
                            Text("\(intValue, specifier: "%.0f")%")
                                .font(.caption)
                                .foregroundColor(Color.Theme.secondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption)
                        .foregroundStyle(Color.Theme.secondaryText)
                }
            }
            
            // Drawdown Metrics
            VStack(spacing: 12) {
                HStack {
                    Label("Max Drawdown", systemImage: "arrow.down.to.line")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Spacer()
                    Text("\(metrics.maxDrawdown, specifier: "%.1f")%")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.Theme.error)
                }
                
                HStack {
                    Label("Recovery Time", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Spacer()
                    Text("\(metrics.maxDrawdownDuration) days")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.Theme.warning)
                }
                
                HStack {
                    Label("Return/DD Ratio", systemImage: "percent")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Spacer()
                    Text(String(format: "%.2f", metrics.returnToDrawdownRatio))
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(metrics.returnToDrawdownRatio >= 1 ? Color.Theme.success : Color.Theme.warning)
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