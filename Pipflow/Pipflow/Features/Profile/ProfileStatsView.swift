//
//  ProfileStatsView.swift
//  Pipflow
//
//  Profile statistics overview component
//

import SwiftUI

struct ProfileStatsView: View {
    let stats: UserStats
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Primary Stats
            HStack(spacing: 20) {
                StatCard(
                    title: "Win Rate",
                    value: "\(Int(stats.winRate * 100))%",
                    icon: "chart.pie",
                    color: Color.green
                )
                
                StatCard(
                    title: "Monthly",
                    value: stats.monthlyReturn >= 0 ? "+\(Int(stats.monthlyReturn * 100))%" : "\(Int(stats.monthlyReturn * 100))%",
                    icon: "calendar",
                    color: stats.monthlyReturn >= 0 ? Color.green : Color.red
                )
                
                StatCard(
                    title: "Profit Factor",
                    value: String(format: "%.2f", stats.profitFactor),
                    icon: "arrow.up.arrow.down",
                    color: themeManager.currentTheme.accentColor
                )
                
                StatCard(
                    title: "Sharpe",
                    value: String(format: "%.2f", stats.sharpeRatio),
                    icon: "waveform.path",
                    color: Color.purple
                )
            }
            
            // Secondary Stats
            HStack(spacing: 12) {
                SecondaryStatItem(
                    label: "Max Drawdown",
                    value: "\(Int(stats.maxDrawdown * 100))%",
                    isNegative: true
                )
                
                SecondaryStatItem(
                    label: "Current Streak",
                    value: "\(abs(stats.currentStreak)) \(stats.currentStreak >= 0 ? "W" : "L")",
                    isNegative: stats.currentStreak < 0
                )
                
                SecondaryStatItem(
                    label: "Avg Win",
                    value: "$\(Int(stats.averageWin))",
                    isNegative: false
                )
                
                SecondaryStatItem(
                    label: "Avg Loss",
                    value: "$\(Int(stats.averageLoss))",
                    isNegative: true
                )
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(themeManager.currentTheme.backgroundColor)
        .cornerRadius(8)
    }
}

struct SecondaryStatItem: View {
    let label: String
    let value: String
    let isNegative: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isNegative ? Color.red : Color.green)
        }
        .frame(maxWidth: .infinity)
    }
}