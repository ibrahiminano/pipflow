//
//  WinLossStatistics.swift
//  Pipflow
//
//  Win/Loss statistics visualization
//

import SwiftUI

struct WinLossStatistics: View {
    let metrics: AnalyticsPerformanceMetrics
    
    private var winPercentage: Double {
        metrics.winRate * 100
    }
    
    private var lossPercentage: Double {
        (1 - metrics.winRate) * 100
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Win/Loss Analysis")
                    .font(.headline)
                Spacer()
                Text("\(metrics.totalTrades) trades")
                    .font(.caption)
                    .foregroundColor(Color.Theme.secondaryText)
            }
            
            // Visual Win/Loss Bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    // Win section
                    Rectangle()
                        .fill(Color.Theme.success)
                        .frame(width: geometry.size.width * metrics.winRate)
                        .overlay(
                            Text("\(metrics.winningTrades)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                    
                    // Loss section
                    Rectangle()
                        .fill(Color.Theme.error)
                        .overlay(
                            Text("\(metrics.losingTrades)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                }
                .cornerRadius(8)
            }
            .frame(height: 40)
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                WinLossStatCard(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", winPercentage),
                    subtitle: "\(metrics.winningTrades) wins",
                    color: Color.Theme.success
                )
                
                WinLossStatCard(
                    title: "Loss Rate",
                    value: String(format: "%.1f%%", lossPercentage),
                    subtitle: "\(metrics.losingTrades) losses",
                    color: Color.Theme.error
                )
                
                WinLossStatCard(
                    title: "Average Win",
                    value: formatCurrency(metrics.averageWin),
                    subtitle: "Largest: \(formatCurrency(metrics.largestWin))",
                    color: Color.Theme.success
                )
                
                WinLossStatCard(
                    title: "Average Loss",
                    value: formatCurrency(metrics.averageLoss),
                    subtitle: "Largest: \(formatCurrency(metrics.largestLoss))",
                    color: Color.Theme.error
                )
            }
            
            // Win/Loss Ratio
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Win/Loss Ratio")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Text(String(format: "%.2f", metrics.winLossRatio))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(metrics.winLossRatio >= 1 ? Color.Theme.success : Color.Theme.error)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Profit Factor")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Text(String(format: "%.2f", metrics.profitFactor))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(metrics.profitFactor >= 1 ? Color.Theme.success : Color.Theme.error)
                }
            }
            .padding()
            .background(Color.Theme.secondary.opacity(0.5))
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

struct WinLossStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Text(value)
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(Color.Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}