//
//  RiskAnalysisView.swift
//  Pipflow
//
//  Detailed risk analysis view for traders
//

import SwiftUI
import Charts

struct RiskAnalysisView: View {
    let trader: Trader
    let riskAnalysis: TraderRiskAnalysis
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Risk Score
                    RiskScoreCard(
                        score: riskAnalysis.overallScore,
                        level: riskAnalysis.riskLevel,
                        description: riskAnalysis.riskDescription
                    )
                    
                    // Risk Factors Breakdown
                    RiskFactorsCard(factors: riskAnalysis.factors)
                    
                    // Risk Metrics Chart
                    RiskMetricsChart(metrics: riskAnalysis.metrics)
                    
                    // Strengths & Weaknesses
                    if !riskAnalysis.strengths.isEmpty || !riskAnalysis.weaknesses.isEmpty {
                        StrengthsWeaknessesCard(
                            strengths: riskAnalysis.strengths,
                            weaknesses: riskAnalysis.weaknesses
                        )
                    }
                    
                    // Recommendations
                    if !riskAnalysis.recommendations.isEmpty {
                        RiskRecommendationsCard(recommendations: riskAnalysis.recommendations)
                    }
                    
                    // Historical Risk Trend
                    HistoricalRiskTrend(trader: trader)
                }
                .padding()
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("\(trader.displayName) - Risk Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Risk Score Card

struct RiskScoreCard: View {
    let score: Int
    let level: TraderRiskLevel
    let description: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var scoreColor: Color {
        switch score {
        case 1...3:
            return Color.Theme.success
        case 4...6:
            return Color.orange
        default:
            return Color.Theme.error
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.3), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 10)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: score)
                
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)
                    
                    Text("out of 10")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            // Risk Level
            HStack(spacing: 8) {
                Circle()
                    .fill(level.color)
                    .frame(width: 12, height: 12)
                
                Text(level.rawValue)
                    .font(.headline)
                    .foregroundColor(level.color)
                
                Text("Risk")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            // Description
            Text(description)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Risk Factors Card

struct RiskFactorsCard: View {
    let factors: RiskScoreCalculator.RiskFactors
    @EnvironmentObject var themeManager: ThemeManager
    
    var factorItems: [(name: String, value: Double, icon: String)] {
        [
            ("Drawdown Risk", factors.drawdownRisk, "chart.line.downtrend.xyaxis"),
            ("Volatility Risk", factors.volatilityRisk, "waveform.path.ecg"),
            ("Concentration Risk", factors.concentrationRisk, "circle.grid.cross"),
            ("Leverage Risk", factors.leverageRisk, "gauge.badge.plus"),
            ("Frequency Risk", factors.frequencyRisk, "timer"),
            ("Consistency Risk", factors.consistencyRisk, "chart.bar.doc.horizontal")
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Factors Breakdown")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            VStack(spacing: 12) {
                ForEach(factorItems, id: \.name) { item in
                    RiskFactorRow(
                        name: item.name,
                        value: item.value,
                        icon: item.icon
                    )
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Risk Factor Row

struct RiskFactorRow: View {
    let name: String
    let value: Double
    let icon: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var riskColor: Color {
        switch value {
        case 0...3:
            return Color.Theme.success
        case 3.1...6:
            return Color.orange
        default:
            return Color.Theme.error
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(riskColor)
                .frame(width: 24)
            
            Text(name)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Spacer()
            
            // Risk Bar
            HStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeManager.currentTheme.backgroundColor)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(riskColor)
                            .frame(width: geometry.size.width * (value / 10), height: 8)
                    }
                }
                .frame(width: 80, height: 8)
                
                Text(String(format: "%.1f", value))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(riskColor)
                    .frame(width: 30, alignment: .trailing)
            }
        }
    }
}

// MARK: - Risk Metrics Chart

struct RiskMetricsChart: View {
    let metrics: RiskScoreCalculator.RiskMetrics
    @EnvironmentObject var themeManager: ThemeManager
    
    var chartData: [(name: String, value: Double)] {
        [
            ("Max DD", metrics.maxDrawdown * 100),
            ("Volatility", metrics.volatility * 100),
            ("Sharpe", min(metrics.sharpeRatio, 3) * 33.33),
            ("Calmar", min(metrics.calmarRatio, 3) * 33.33),
            ("Consistency", metrics.returnConsistency * 100)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Metrics")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Chart(chartData, id: \.name) { item in
                BarMark(
                    x: .value("Metric", item.name),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            
            // Metrics Legend
            VStack(alignment: .leading, spacing: 8) {
                RiskMetricRow(title: "Max Drawdown", value: String(format: "%.1f%%", metrics.maxDrawdown * 100))
                RiskMetricRow(title: "Daily Volatility", value: String(format: "%.2f%%", metrics.volatility * 100))
                RiskMetricRow(title: "Sharpe Ratio", value: String(format: "%.2f", metrics.sharpeRatio))
                RiskMetricRow(title: "Calmar Ratio", value: String(format: "%.2f", metrics.calmarRatio))
                RiskMetricRow(title: "Win Consistency", value: String(format: "%.0f%%", metrics.winRateConsistency * 100))
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Metric Row

struct RiskMetricRow: View {
    let title: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.textColor)
        }
    }
}

// MARK: - Strengths & Weaknesses Card

struct StrengthsWeaknessesCard: View {
    let strengths: [String]
    let weaknesses: [String]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            if !strengths.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Strengths", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.Theme.success)
                    
                    ForEach(strengths, id: \.self) { strength in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.Theme.success)
                                .frame(width: 6, height: 6)
                                .offset(y: 6)
                            
                            Text(strength)
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textColor)
                        }
                    }
                }
            }
            
            if !weaknesses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Areas of Concern", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.orange)
                    
                    ForEach(weaknesses, id: \.self) { weakness in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                                .offset(y: 6)
                            
                            Text(weakness)
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textColor)
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Recommendations Card

struct RiskRecommendationsCard: View {
    let recommendations: [String]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Recommendations", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color.blue)
                            .offset(y: 2)
                        
                        Text(recommendation)
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

// MARK: - Historical Risk Trend

struct HistoricalRiskTrend: View {
    let trader: Trader
    @EnvironmentObject var themeManager: ThemeManager
    
    // Mock historical risk data
    var riskTrendData: [(date: Date, score: Int)] {
        (0..<12).map { month in
            let date = Calendar.current.date(byAdding: .month, value: -month, to: Date()) ?? Date()
            let baseScore = trader.riskScore
            let variation = Int.random(in: -2...2)
            let score = max(1, min(10, baseScore + variation))
            return (date, score)
        }.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Score Trend (12 Months)")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Chart(riskTrendData, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Score", item.score)
                )
                .foregroundStyle(Color.Theme.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Score", item.score)
                )
                .foregroundStyle(Color.Theme.accent)
            }
            .frame(height: 150)
            .chartYScale(domain: 0...10)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}