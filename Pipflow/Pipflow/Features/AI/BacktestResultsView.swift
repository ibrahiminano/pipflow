//
//  BacktestResultsView.swift
//  Pipflow
//
//  Detailed backtest results visualization
//

import SwiftUI
import Charts

struct OptimizationBacktestResultsView: View {
    let result: OptimizationResult
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Overview Tab
                ScrollView {
                    VStack(spacing: 20) {
                        PerformanceComparisonCard(result: result)
                        ImprovementsGrid(improvements: result.improvements)
                        RecommendationsView(recommendations: result.recommendations)
                    }
                    .padding()
                }
                .tabItem {
                    Label("Overview", systemImage: "chart.bar")
                }
                .tag(0)
                
                // Metrics Tab
                ScrollView {
                    VStack(spacing: 20) {
                        MetricsComparisonView(comparison: result.backtestResults)
                        ConfidenceAnalysisView(confidence: result.confidence)
                    }
                    .padding()
                }
                .tabItem {
                    Label("Metrics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
                
                // Strategy Tab
                ScrollView {
                    VStack(spacing: 20) {
                        StrategyParametersView(
                            original: result.originalStrategy,
                            optimized: result.optimizedStrategy
                        )
                    }
                    .padding()
                }
                .tabItem {
                    Label("Strategy", systemImage: "brain")
                }
                .tag(2)
            }
            .navigationTitle("Optimization Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: applyOptimization) {
                            Label("Apply Changes", systemImage: "checkmark.circle")
                        }
                        
                        Button(action: exportResults) {
                            Label("Export Results", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: startABTest) {
                            Label("Start A/B Test", systemImage: "arrow.left.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                    }
                }
            }
        }
    }
    
    private func applyOptimization() {
        // Apply the optimized strategy
    }
    
    private func exportResults() {
        // Export results as PDF or CSV
    }
    
    private func startABTest() {
        // Start A/B test with original vs optimized
    }
}

// MARK: - Performance Comparison Card
struct PerformanceComparisonCard: View {
    let result: OptimizationResult
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Performance Comparison")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption)
                    Text("\(Int(result.backtestResults.improvementPercentage))% Better")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.green)
            }
            
            HStack(spacing: 20) {
                // Original Performance
                VStack(spacing: 8) {
                    Text("Original")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    CircularProgressView(
                        progress: result.backtestResults.originalMetrics.sharpeRatio / 3,
                        color: themeManager.currentTheme.secondaryTextColor
                    ) {
                        VStack(spacing: 2) {
                            Text(String(format: "%.2f", result.backtestResults.originalMetrics.sharpeRatio))
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Sharpe")
                                .font(.caption2)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
                
                Image(systemName: "arrow.right")
                    .font(.title)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                
                // Optimized Performance
                VStack(spacing: 8) {
                    Text("Optimized")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    CircularProgressView(
                        progress: result.backtestResults.optimizedMetrics.sharpeRatio / 3,
                        color: .green
                    ) {
                        VStack(spacing: 2) {
                            Text(String(format: "%.2f", result.backtestResults.optimizedMetrics.sharpeRatio))
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Sharpe")
                                .font(.caption2)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Improvements Grid
struct ImprovementsGrid: View {
    let improvements: StrategyImprovements
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Improvements")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ImprovementCard(
                    title: "Profit",
                    value: improvements.profitImprovement,
                    icon: "dollarsign.circle",
                    color: .green
                )
                
                ImprovementCard(
                    title: "Drawdown",
                    value: -improvements.drawdownReduction,
                    icon: "arrow.down.circle",
                    color: .blue
                )
                
                ImprovementCard(
                    title: "Sharpe Ratio",
                    value: improvements.sharpeRatioImprovement,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                
                ImprovementCard(
                    title: "Win Rate",
                    value: improvements.winRateImprovement,
                    icon: "percent",
                    color: .purple
                )
            }
            
            // Consistency Score
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Consistency Score", systemImage: "checkmark.seal")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(improvements.consistencyScore * 100))%")
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                ProgressView(value: improvements.consistencyScore)
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.accentColor))
            }
            .padding()
            .background(themeManager.currentTheme.backgroundColor)
            .cornerRadius(8)
        }
    }
}

struct ImprovementCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    private var formattedValue: String {
        let prefix = value >= 0 ? "+" : ""
        if abs(value) >= 100 {
            return "\(prefix)\(Int(value))%"
        } else {
            return "\(prefix)\(String(format: "%.1f", value))%"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text(formattedValue)
                .font(.bodyLarge)
                .fontWeight(.bold)
                .foregroundColor(value >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
        .cornerRadius(8)
    }
}

// MARK: - Recommendations View
struct RecommendationsView: View {
    let recommendations: [OptimizationRecommendation]
    @EnvironmentObject var themeManager: ThemeManager
    @State private var expandedRecommendations = Set<String>()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommendations")
                    .font(.headline)
                
                Spacer()
                
                Text("\(recommendations.count) changes")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            ForEach(recommendations, id: \.parameter) { recommendation in
                OptimizationRecommendationCard(
                    recommendation: recommendation,
                    isExpanded: expandedRecommendations.contains(recommendation.parameter),
                    onTap: {
                        withAnimation {
                            if expandedRecommendations.contains(recommendation.parameter) {
                                expandedRecommendations.remove(recommendation.parameter)
                            } else {
                                expandedRecommendations.insert(recommendation.parameter)
                            }
                        }
                    }
                )
            }
        }
    }
}

struct OptimizationRecommendationCard: View {
    let recommendation: OptimizationRecommendation
    let isExpanded: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.parameter)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        Text(String(format: "%.2f", recommendation.originalValue))
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Text(String(format: "%.2f", recommendation.recommendedValue))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    OptimizationConfidenceBadge(confidence: recommendation.confidence)
                    
                    Button(action: onTap) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
            
            if isExpanded {
                Text(recommendation.impact)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
        .cornerRadius(8)
    }
}

struct OptimizationConfidenceBadge: View {
    let confidence: Double
    
    private var color: Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.shield")
                .font(.caption2)
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.2))
        .cornerRadius(4)
    }
}

// MARK: - Metrics Comparison View
struct MetricsComparisonView: View {
    let comparison: BacktestComparison
    @EnvironmentObject var themeManager: ThemeManager
    
    private let metrics = [
        ("Total Return", "percent"),
        ("Sharpe Ratio", "number"),
        ("Max Drawdown", "percent"),
        ("Win Rate", "percent"),
        ("Profit Factor", "number")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Metrics")
                .font(.headline)
            
            ForEach(metrics, id: \.0) { metric, format in
                MetricComparisonRow(
                    name: metric,
                    originalValue: getMetricValue(comparison.originalMetrics, metric: metric),
                    optimizedValue: getMetricValue(comparison.optimizedMetrics, metric: metric),
                    format: format
                )
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    private func getMetricValue(_ metrics: PerformanceMetrics, metric: String) -> Double {
        switch metric {
        case "Total Return":
            return metrics.totalReturn
        case "Sharpe Ratio":
            return metrics.sharpeRatio
        case "Max Drawdown":
            return metrics.maxDrawdown * 100
        case "Win Rate":
            return metrics.winRate * 100
        case "Profit Factor":
            return metrics.profitFactor
        default:
            return 0
        }
    }
}

struct MetricComparisonRow: View {
    let name: String
    let originalValue: Double
    let optimizedValue: Double
    let format: String
    @EnvironmentObject var themeManager: ThemeManager
    
    private var improvement: Double {
        guard originalValue != 0 else { return 0 }
        return ((optimizedValue - originalValue) / abs(originalValue)) * 100
    }
    
    private func formatValue(_ value: Double) -> String {
        switch format {
        case "percent":
            return "\(Int(value))%"
        case "number":
            return String(format: "%.2f", value)
        default:
            return String(format: "%.2f", value)
        }
    }
    
    var body: some View {
        HStack {
            Text(name)
                .font(.bodyMedium)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Spacer()
            
            HStack(spacing: 12) {
                Text(formatValue(originalValue))
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Text(formatValue(optimizedValue))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                if abs(improvement) > 0.1 {
                    Text("\(improvement >= 0 ? "+" : "")\(Int(improvement))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(improvement >= 0 ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((improvement >= 0 ? Color.green : Color.red).opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Confidence Analysis View
struct ConfidenceAnalysisView: View {
    let confidence: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confidence Analysis")
                .font(.headline)
            
            // Overall Confidence
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Confidence")
                        .font(.bodyMedium)
                    
                    Text("Based on backtest quality and statistical significance")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: confidence,
                    color: confidence > 0.8 ? .green : confidence > 0.6 ? .orange : .red,
                    lineWidth: 8
                ) {
                    Text("\(Int(confidence * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .frame(width: 60, height: 60)
            }
            
            // Confidence Factors
            VStack(spacing: 8) {
                ConfidenceFactorRow(
                    factor: "Data Quality",
                    score: 0.9,
                    description: "High-quality historical data"
                )
                
                ConfidenceFactorRow(
                    factor: "Sample Size",
                    score: 0.85,
                    description: "Sufficient number of trades"
                )
                
                ConfidenceFactorRow(
                    factor: "Market Coverage",
                    score: 0.75,
                    description: "Multiple market conditions tested"
                )
                
                ConfidenceFactorRow(
                    factor: "Overfitting Risk",
                    score: 0.7,
                    description: "Low risk of overfitting"
                )
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct ConfidenceFactorRow: View {
    let factor: String
    let score: Double
    let description: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(factor)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: Double(index) < score * 5 ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundColor(
                                Double(index) < score * 5 ? .yellow : themeManager.currentTheme.secondaryTextColor
                            )
                    }
                }
            }
            
            Text(description)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Strategy Parameters View
struct StrategyParametersView: View {
    let original: TradingStrategy
    let optimized: TradingStrategy
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Strategy Parameters")
                .font(.headline)
            
            // Risk Management
            VStack(alignment: .leading, spacing: 12) {
                Label("Risk Management", systemImage: "shield")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                
                ParameterComparisonRow(
                    name: "Stop Loss",
                    originalValue: "\(original.riskManagement.stopLossPercent)%",
                    optimizedValue: "\(optimized.riskManagement.stopLossPercent)%"
                )
                
                ParameterComparisonRow(
                    name: "Take Profit",
                    originalValue: "\(original.riskManagement.takeProfitPercent)%",
                    optimizedValue: "\(optimized.riskManagement.takeProfitPercent)%"
                )
                
                ParameterComparisonRow(
                    name: "Position Size",
                    originalValue: "\(original.riskManagement.positionSizePercent)%",
                    optimizedValue: "\(optimized.riskManagement.positionSizePercent)%"
                )
                
                ParameterComparisonRow(
                    name: "Max Open Trades",
                    originalValue: "\(original.riskManagement.maxOpenTrades)",
                    optimizedValue: "\(optimized.riskManagement.maxOpenTrades)"
                )
            }
            .padding()
            .background(themeManager.currentTheme.backgroundColor)
            .cornerRadius(8)
            
            // Strategy Info
            VStack(alignment: .leading, spacing: 12) {
                Label("Strategy Information", systemImage: "info.circle")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                
                OptimizationInfoRow(label: "Name", value: original.name)
                OptimizationInfoRow(label: "Timeframe", value: original.timeframe.rawValue)
                OptimizationInfoRow(label: "Description", value: original.description)
            }
            .padding()
            .background(themeManager.currentTheme.backgroundColor)
            .cornerRadius(8)
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct ParameterComparisonRow: View {
    let name: String
    let originalValue: String
    let optimizedValue: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(originalValue)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                if originalValue != optimizedValue {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Text(optimizedValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct OptimizationInfoRow: View {
    let label: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textColor)
        }
        .padding(.vertical, 2)
    }
}