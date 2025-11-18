//
//  ProfitDistributionChart.swift
//  Pipflow
//
//  Profit distribution histogram
//

import SwiftUI
import Charts

struct ProfitDistributionChart: View {
    let distribution: [ProfitBucket]
    @State private var selectedBucket: ProfitBucket?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profit Distribution")
                .font(.headline)
            
            Chart(distribution) { bucket in
                BarMark(
                    x: .value("Range", bucket.range),
                    y: .value("Count", bucket.count)
                )
                .foregroundStyle(colorForBucket(bucket))
                .cornerRadius(4)
                .opacity(selectedBucket == nil || selectedBucket?.id == bucket.id ? 1.0 : 0.5)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel(orientation: .verticalReversed)
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.Theme.divider.opacity(0.5))
                    AxisValueLabel()
                        .font(.caption)
                        .foregroundStyle(Color.Theme.secondaryText)
                }
            }
            .onTapGesture { location in
                // Simple tap detection - in production would calculate exact bucket
                selectedBucket = selectedBucket == nil ? distribution.first : nil
            }
            
            // Summary Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Win Rate")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Text("\(calculateWinRate(), specifier: "%.1f")%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.Theme.success)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Avg Profit")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Text("$125")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.Theme.text)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Skewness")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Text("0.42")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.Theme.accent)
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
    }
    
    private func colorForBucket(_ bucket: ProfitBucket) -> Color {
        if bucket.range.contains("-") && !bucket.range.contains("$0") {
            return Color.Theme.error
        } else if bucket.range.contains("$0") {
            return Color.Theme.warning
        } else {
            return Color.Theme.success
        }
    }
    
    private func calculateWinRate() -> Double {
        let totalCount = distribution.reduce(0) { $0 + $1.count }
        let winCount = distribution
            .filter { !$0.range.contains("-") || $0.range.contains("$0") }
            .reduce(0) { $0 + $1.count }
        return Double(winCount) / Double(totalCount) * 100
    }
}