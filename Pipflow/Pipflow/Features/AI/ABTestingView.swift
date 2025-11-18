//
//  ABTestingView.swift
//  Pipflow
//
//  A/B testing interface for trading strategies
//

import SwiftUI
import Charts

struct ActiveABTestsView: View {
    let tests: [ABTestResult]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active A/B Tests")
                    .font(.headline)
                
                Spacer()
                
                Text("\(tests.count) running")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            ForEach(tests) { test in
                ABTestCard(test: test)
            }
        }
    }
}

struct ABTestCard: View {
    let test: ABTestResult
    @EnvironmentObject var themeManager: ThemeManager
    
    private var timeRemaining: String {
        let remaining = test.endDate.timeIntervalSinceNow
        if remaining <= 0 {
            return "Completed"
        }
        
        let days = Int(remaining / 86400)
        let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)
        
        if days > 0 {
            return "\(days)d \(hours)h remaining"
        } else {
            return "\(hours)h remaining"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(test.configuration.testName)
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                    
                    Text(timeRemaining)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                // Winner indicator
                if test.winner != .noSignificantDifference {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text(test.winner == .strategyA ? "A" : "B")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.currentTheme.accentColor.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            // Strategies
            HStack(spacing: 12) {
                ABTestStrategyView(
                    title: "Strategy A",
                    strategyName: test.configuration.strategyA.name,
                    performance: test.performanceA,
                    isWinning: test.winner == .strategyA
                )
                
                Text("vs")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                ABTestStrategyView(
                    title: "Strategy B",
                    strategyName: test.configuration.strategyB.name,
                    performance: test.performanceB,
                    isWinning: test.winner == .strategyB
                )
            }
            
            // Progress and significance
            VStack(spacing: 8) {
                // Trade count progress
                HStack {
                    Text("Trades")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Spacer()
                    
                    Text("\(test.performanceA.trades + test.performanceB.trades) / \(test.configuration.minimumTrades * 2)")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                ProgressView(value: Double(test.performanceA.trades + test.performanceB.trades), total: Double(test.configuration.minimumTrades * 2))
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                
                // Statistical significance
                if test.statisticalSignificance > 0 {
                    HStack {
                        Text("Statistical Significance")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Spacer()
                        
                        Text("\(Int(test.statisticalSignificance * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(
                                test.statisticalSignificance > 0.95 ? .green :
                                test.statisticalSignificance > 0.90 ? .orange : .red
                            )
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct ABTestStrategyView: View {
    let title: String
    let strategyName: String
    let performance: ABTestPerformance
    let isWinning: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                if isWinning {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            
            Text(strategyName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            VStack(alignment: .leading, spacing: 4) {
                ABTestMetricRow(label: "Win Rate", value: "\(Int(performance.winRate * 100))%")
                ABTestMetricRow(label: "Return", value: formatCurrency(performance.totalReturn))
                ABTestMetricRow(label: "Sharpe", value: String(format: "%.2f", performance.sharpeRatio))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.currentTheme.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isWinning ? themeManager.currentTheme.accentColor : Color.clear,
                            lineWidth: 2
                        )
                )
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct ABTestMetricRow: View {
    let label: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.textColor)
        }
    }
}

// MARK: - A/B Test Setup View
struct ABTestSetupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var optimizer = StrategyOptimizer.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var testName = ""
    @State private var strategyA: TradingStrategy?
    @State private var strategyB: TradingStrategy?
    @State private var testDuration = 7.0 // days
    @State private var splitRatio = 0.5
    @State private var minimumTrades = 50
    @State private var confidenceLevel = 0.95
    
    // Mock strategies
    let strategies = [
        TradingStrategy(
            name: "RSI Momentum",
            description: "RSI-based momentum strategy",
            conditions: [],
            riskManagement: RiskManagement(stopLossPercent: 1, takeProfitPercent: 2, positionSizePercent: 2, maxOpenTrades: 3),
            timeframe: .h1
        ),
        TradingStrategy(
            name: "Bollinger Breakout",
            description: "Bollinger Bands breakout strategy",
            conditions: [],
            riskManagement: RiskManagement(stopLossPercent: 1.5, takeProfitPercent: 3, positionSizePercent: 1.5, maxOpenTrades: 2),
            timeframe: .h4
        ),
        TradingStrategy(
            name: "EMA Cross",
            description: "Exponential moving average crossover",
            conditions: [],
            riskManagement: RiskManagement(stopLossPercent: 2, takeProfitPercent: 4, positionSizePercent: 1, maxOpenTrades: 1),
            timeframe: .d1
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Test Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Name")
                            .font(.headline)
                        
                        TextField("e.g., RSI vs Bollinger Test", text: $testName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Strategy Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Strategies")
                            .font(.headline)
                        
                        // Strategy A
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Strategy A", systemImage: "a.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(strategies) { strategy in
                                        CompactStrategyCard(
                                            strategy: strategy,
                                            isSelected: strategyA?.id == strategy.id,
                                            action: { strategyA = strategy }
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Strategy B
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Strategy B", systemImage: "b.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(strategies) { strategy in
                                        CompactStrategyCard(
                                            strategy: strategy,
                                            isSelected: strategyB?.id == strategy.id,
                                            action: { strategyB = strategy }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    // Test Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Test Configuration")
                            .font(.headline)
                        
                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Duration", systemImage: "calendar")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(Int(testDuration)) days")
                                    .font(.bodyMedium)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                            
                            Slider(value: $testDuration, in: 1...30, step: 1)
                        }
                        
                        // Split Ratio
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Traffic Split", systemImage: "arrow.left.arrow.right")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(Int(splitRatio * 100))% / \(Int((1 - splitRatio) * 100))%")
                                    .font(.bodyMedium)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                            
                            Slider(value: $splitRatio, in: 0.2...0.8)
                        }
                        
                        // Minimum Trades
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Minimum Trades", systemImage: "chart.bar")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(minimumTrades) per strategy")
                                    .font(.bodyMedium)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                            
                            Slider(value: Binding(
                                get: { Double(minimumTrades) },
                                set: { minimumTrades = Int($0) }
                            ), in: 10...200, step: 10)
                        }
                        
                        // Confidence Level
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Confidence Level", systemImage: "checkmark.seal")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(Int(confidenceLevel * 100))%")
                                    .font(.bodyMedium)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                            
                            Picker("Confidence", selection: $confidenceLevel) {
                                Text("90%").tag(0.90)
                                Text("95%").tag(0.95)
                                Text("99%").tag(0.99)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    
                    // Start Button
                    Button(action: startABTest) {
                        Text("Start A/B Test")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                canStartTest ? themeManager.currentTheme.accentColor : Color.gray
                            )
                            .cornerRadius(12)
                    }
                    .disabled(!canStartTest)
                }
                .padding()
            }
            .navigationTitle("New A/B Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canStartTest: Bool {
        !testName.isEmpty && strategyA != nil && strategyB != nil && strategyA?.id != strategyB?.id
    }
    
    private func startABTest() {
        guard let strategyA = strategyA,
              let strategyB = strategyB else { return }
        
        let configuration = ABTestConfiguration(
            testName: testName,
            strategyA: strategyA,
            strategyB: strategyB,
            testDuration: testDuration * 24 * 3600,
            splitRatio: splitRatio,
            minimumTrades: minimumTrades,
            confidenceLevel: confidenceLevel
        )
        
        Task {
            await optimizer.startABTest(configuration)
            dismiss()
        }
    }
}

struct CompactStrategyCard: View {
    let strategy: TradingStrategy
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(strategy.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                
                Text(strategy.timeframe.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : themeManager.currentTheme.secondaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryBackgroundColor
            )
            .cornerRadius(8)
        }
    }
}