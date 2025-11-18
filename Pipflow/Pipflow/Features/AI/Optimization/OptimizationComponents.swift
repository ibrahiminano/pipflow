//
//  OptimizationComponents.swift
//  Pipflow
//
//  Supporting components for Strategy Optimization
//

import SwiftUI
import Charts

// MARK: - A/B Testing Tab

struct ABTestingTab: View {
    let abTests: [ABTestResult]
    let theme: Theme
    let onCreateTest: (ABTestConfiguration) -> Void
    
    @State private var showCreateTest = false
    
    var activeTests: [ABTestResult] {
        abTests.filter { Date() < $0.endDate }
    }
    
    var completedTests: [ABTestResult] {
        abTests.filter { Date() >= $0.endDate }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Create Test Button
                Button(action: { showCreateTest = true }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Create A/B Test")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Active Tests
                if !activeTests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Tests")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        ForEach(activeTests) { test in
                            ActiveABTestCard(test: test, theme: theme)
                        }
                    }
                }
                
                // Completed Tests
                if !completedTests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Completed Tests")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        ForEach(completedTests) { test in
                            CompletedABTestCard(test: test, theme: theme)
                        }
                    }
                }
                
                if abTests.isEmpty {
                    EmptyStateView(
                        icon: "chart.xyaxis.line",
                        title: "No A/B Tests",
                        description: "Create an A/B test to compare strategy performance",
                        theme: theme
                    )
                    .padding(.top, 50)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showCreateTest) {
            CreateABTestView(onCreateTest: onCreateTest)
                .environmentObject(ThemeManager.shared)
        }
    }
}

struct ActiveABTestCard: View {
    let test: ABTestResult
    let theme: Theme
    
    var timeRemaining: String {
        let remaining = test.endDate.timeIntervalSinceNow
        let hours = Int(remaining) / 3600
        let days = hours / 24
        
        if days > 0 {
            return "\(days) days remaining"
        } else {
            return "\(hours) hours remaining"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(test.configuration.testName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Text(timeRemaining)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            // Performance Comparison
            HStack(spacing: 20) {
                ABTestMetric(
                    label: "Strategy A",
                    trades: test.performanceA.trades,
                    winRate: test.performanceA.winRate,
                    return: test.performanceA.totalReturn,
                    color: .blue,
                    theme: theme
                )
                
                Text("VS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.secondaryTextColor)
                
                ABTestMetric(
                    label: "Strategy B",
                    trades: test.performanceB.trades,
                    winRate: test.performanceB.winRate,
                    return: test.performanceB.totalReturn,
                    color: .green,
                    theme: theme
                )
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.separatorColor)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accentColor)
                        .frame(
                            width: geometry.size.width * progressPercentage,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    private var progressPercentage: Double {
        let elapsed = test.startDate.timeIntervalSinceNow * -1
        let total = test.configuration.testDuration
        return min(elapsed / total, 1.0)
    }
}

struct CompletedABTestCard: View {
    let test: ABTestResult
    let theme: Theme
    
    var winnerColor: Color {
        switch test.winner {
        case .strategyA: return .blue
        case .strategyB: return .green
        case .noSignificantDifference: return theme.secondaryTextColor
        }
    }
    
    var winnerText: String {
        switch test.winner {
        case .strategyA: return "Strategy A Won"
        case .strategyB: return "Strategy B Won"
        case .noSignificantDifference: return "No Clear Winner"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(test.configuration.testName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Text(winnerText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(winnerColor)
            }
            
            // Final Results
            HStack {
                ABTestFinalResult(
                    label: "Strategy A",
                    performance: test.performanceA,
                    isWinner: test.winner == .strategyA,
                    theme: theme
                )
                
                Spacer()
                
                ABTestFinalResult(
                    label: "Strategy B",
                    performance: test.performanceB,
                    isWinner: test.winner == .strategyB,
                    theme: theme
                )
            }
            
            // Statistical Significance
            HStack {
                Text("Statistical Significance")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                Spacer()
                
                Text(String(format: "%.1f%%", test.statisticalSignificance * 100))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(significanceColor)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    private var significanceColor: Color {
        if test.statisticalSignificance > 0.95 { return .green }
        if test.statisticalSignificance > 0.8 { return .orange }
        return .red
    }
}

struct ABTestMetric: View {
    let label: String
    let trades: Int
    let winRate: Double
    let `return`: Double
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.caption)
                    .foregroundColor(theme.textColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(trades) trades")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                
                Text(String(format: "%.1f%% win", winRate * 100))
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                
                Text(String(format: "$%.0f", `return`))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(`return` >= 0 ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ABTestFinalResult: View {
    let label: String
    let performance: ABTestPerformance
    let isWinner: Bool
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption)
                    .fontWeight(isWinner ? .bold : .regular)
                    .foregroundColor(theme.textColor)
                
                if isWinner {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                OptimizationMetricRow(label: "Return", value: String(format: "$%.0f", performance.totalReturn), theme: theme)
                OptimizationMetricRow(label: "Win Rate", value: String(format: "%.1f%%", performance.winRate * 100), theme: theme)
                OptimizationMetricRow(label: "Sharpe", value: String(format: "%.2f", performance.sharpeRatio), theme: theme)
                OptimizationMetricRow(label: "Drawdown", value: String(format: "%.1f%%", performance.maxDrawdown * 100), theme: theme)
            }
        }
        .padding()
        .background(isWinner ? theme.accentColor.opacity(0.1) : theme.backgroundColor)
        .cornerRadius(8)
    }
}

struct OptimizationMetricRow: View {
    let label: String
    let value: String
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
            Spacer()
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(theme.textColor)
        }
    }
}

// MARK: - Evolution Tab

struct EvolutionTab: View {
    let history: [StrategyEvolution]
    let theme: Theme
    
    var groupedByStrategy: [String: [StrategyEvolution]] {
        Dictionary(grouping: history, by: { $0.strategyId })
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if history.isEmpty {
                    EmptyStateView(
                        icon: "tree",
                        title: "No Evolution History",
                        description: "Strategy evolution will be tracked here as optimizations occur",
                        theme: theme
                    )
                    .padding(.top, 50)
                } else {
                    ForEach(Array(groupedByStrategy.keys), id: \.self) { strategyId in
                        if let evolutions = groupedByStrategy[strategyId] {
                            StrategyEvolutionSection(
                                strategyId: strategyId,
                                evolutions: evolutions.sorted { $0.timestamp > $1.timestamp },
                                theme: theme
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct StrategyEvolutionSection: View {
    let strategyId: String
    let evolutions: [StrategyEvolution]
    let theme: Theme
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text("Strategy \(strategyId.prefix(8))")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(evolutions.count) versions")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
            
            if isExpanded {
                ForEach(evolutions) { evolution in
                    EvolutionCard(evolution: evolution, theme: theme)
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct EvolutionCard: View {
    let evolution: StrategyEvolution
    let theme: Theme
    
    @State private var showChanges = false
    
    var triggerIcon: String {
        switch evolution.trigger {
        case .manual: return "hand.point.up"
        case .scheduled: return "clock"
        case .performanceDrop: return "arrow.down.circle"
        case .marketRegimeChange: return "cloud.sun.rain"
        case .mlRecommendation: return "sparkles"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: triggerIcon)
                        .font(.caption)
                        .foregroundColor(theme.accentColor)
                    
                    Text("Version \(evolution.version)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textColor)
                }
                
                Spacer()
                
                Text(formatDate(evolution.timestamp))
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            if evolution.performanceChange != 0 {
                Text(String(format: "%+.1f%% performance", evolution.performanceChange))
                    .font(.caption)
                    .foregroundColor(evolution.performanceChange > 0 ? .green : .red)
            }
            
            Button(action: { showChanges.toggle() }) {
                HStack {
                    Text("\(evolution.changes.count) changes")
                        .font(.caption)
                    Image(systemName: showChanges ? "chevron.up" : "chevron.down")
                }
                .foregroundColor(theme.accentColor)
            }
            
            if showChanges {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(evolution.changes, id: \.parameter) { change in
                        ParameterChangeRow(change: change, theme: theme)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(theme.backgroundColor)
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ParameterChangeRow: View {
    let change: ParameterChange
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(change.parameter)
                .font(.caption2)
                .foregroundColor(theme.textColor)
            
            HStack(spacing: 4) {
                Text(String(format: "%.2f", change.oldValue))
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                    .strikethrough()
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                
                Text(String(format: "%.2f", change.newValue))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(theme.accentColor)
            }
            
            Spacer()
        }
    }
}

// MARK: - Predictions Tab

struct PredictionsTab: View {
    @ObservedObject var viewModel: OptimizationViewModel
    let selectedStrategy: TradingStrategy?
    let theme: Theme
    
    @State private var prediction: PerformancePrediction?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if selectedStrategy == nil {
                    EmptyStateView(
                        icon: "crystal.ball",
                        title: "No Strategy Selected",
                        description: "Select a strategy to predict its performance",
                        theme: theme
                    )
                    .padding(.top, 50)
                } else {
                    // Predict Button
                    Button(action: predictPerformance) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text("Predict Performance")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.accentColor)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    
                    if let prediction = prediction {
                        PredictionResultCard(prediction: prediction, theme: theme)
                        
                        PredictionDetailsCard(prediction: prediction, theme: theme)
                        
                        PredictionConfidenceCard(
                            confidence: prediction.confidence,
                            timeHorizon: prediction.timeHorizon,
                            theme: theme
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private func predictPerformance() {
        guard let strategy = selectedStrategy else { return }
        
        isLoading = true
        
        Task {
            prediction = await viewModel.predictPerformance(strategy: strategy)
            isLoading = false
        }
    }
}

struct PredictionResultCard: View {
    let prediction: PerformancePrediction
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Performance Prediction")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            HStack(spacing: 20) {
                PredictionMetric(
                    label: "Expected Return",
                    value: String(format: "%+.1f%%", prediction.expectedReturn),
                    color: prediction.expectedReturn > 0 ? .green : .red,
                    theme: theme
                )
                
                PredictionMetric(
                    label: "Max Drawdown",
                    value: String(format: "%.1f%%", prediction.expectedDrawdown * 100),
                    color: .orange,
                    theme: theme
                )
                
                PredictionMetric(
                    label: "Sharpe Ratio",
                    value: String(format: "%.2f", prediction.expectedSharpeRatio),
                    color: theme.accentColor,
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct PredictionMetric: View {
    let label: String
    let value: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views

struct CreateABTestView: View {
    let onCreateTest: (ABTestConfiguration) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var testName = ""
    @State private var selectedStrategyA: TradingStrategy?
    @State private var selectedStrategyB: TradingStrategy?
    @State private var testDuration: TimeInterval = 7 * 24 * 3600 // 7 days
    @State private var splitRatio = 0.5
    @State private var minimumTrades = 20
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Test Configuration")) {
                    TextField("Test Name", text: $testName)
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Picker("Duration", selection: $testDuration) {
                            Text("3 Days").tag(3.0 * 24 * 3600)
                            Text("7 Days").tag(7.0 * 24 * 3600)
                            Text("14 Days").tag(14.0 * 24 * 3600)
                            Text("30 Days").tag(30.0 * 24 * 3600)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Minimum Trades")
                        Spacer()
                        TextField("", value: $minimumTrades, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)
                    }
                }
                
                Section(header: Text("Strategies")) {
                    StrategyPickerRow(
                        label: "Strategy A",
                        strategy: selectedStrategyA,
                        onSelect: { selectedStrategyA = $0 }
                    )
                    
                    StrategyPickerRow(
                        label: "Strategy B",
                        strategy: selectedStrategyB,
                        onSelect: { selectedStrategyB = $0 }
                    )
                }
                
                Section(header: Text("Split Ratio")) {
                    VStack {
                        Slider(value: $splitRatio, in: 0.2...0.8)
                        HStack {
                            Text("A: \(Int(splitRatio * 100))%")
                            Spacer()
                            Text("B: \(Int((1 - splitRatio) * 100))%")
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
            .navigationTitle("Create A/B Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTest()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !testName.isEmpty && selectedStrategyA != nil && selectedStrategyB != nil
    }
    
    private func createTest() {
        guard let strategyA = selectedStrategyA,
              let strategyB = selectedStrategyB else { return }
        
        let config = ABTestConfiguration(
            testName: testName,
            strategyA: strategyA,
            strategyB: strategyB,
            testDuration: testDuration,
            splitRatio: splitRatio,
            minimumTrades: minimumTrades,
            confidenceLevel: 0.95
        )
        
        onCreateTest(config)
        dismiss()
    }
}

struct StrategyPickerRow: View {
    let label: String
    let strategy: TradingStrategy?
    let onSelect: (TradingStrategy) -> Void
    
    @State private var showPicker = false
    
    var body: some View {
        Button(action: { showPicker = true }) {
            HStack {
                Text(label)
                Spacer()
                Text(strategy?.name ?? "Select")
                    .foregroundColor(.gray)
            }
        }
        .sheet(isPresented: $showPicker) {
            StrategyPickerView(selectedStrategy: .constant(strategy)) { selected in
                if let selected = selected {
                    onSelect(selected)
                }
            }
        }
    }
}

struct StrategyPickerView: View {
    @Binding var selectedStrategy: TradingStrategy?
    var onSelect: ((TradingStrategy?) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    // Demo strategies
    let strategies = [
        TradingStrategy(
            name: "Trend Following",
            description: "Follow market trends",
            conditions: [],
            riskManagement: RiskManagement(stopLossPercent: 1, takeProfitPercent: 2, positionSizePercent: 2, maxOpenTrades: 3),
            timeframe: .h1
        ),
        TradingStrategy(
            name: "Range Trading",
            description: "Trade between support and resistance",
            conditions: [],
            riskManagement: RiskManagement(stopLossPercent: 0.5, takeProfitPercent: 1, positionSizePercent: 1.5, maxOpenTrades: 5),
            timeframe: .h1
        ),
        TradingStrategy(
            name: "Scalping",
            description: "Quick in and out trades",
            conditions: [],
            riskManagement: RiskManagement(stopLossPercent: 0.2, takeProfitPercent: 0.3, positionSizePercent: 1, maxOpenTrades: 10),
            timeframe: .m5
        )
    ]
    
    var body: some View {
        NavigationView {
            List(strategies, id: \.name) { strategy in
                Button(action: {
                    selectedStrategy = strategy
                    onSelect?(strategy)
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(strategy.name)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text(strategy.description)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct OptimizationResultView: View {
    let result: OptimizationResult
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Improvements Summary
                    ImprovementsSummaryCard(
                        improvements: result.improvements,
                        theme: themeManager.currentTheme
                    )
                    
                    // Recommendations
                    RecommendationsCard(
                        recommendations: result.recommendations,
                        theme: themeManager.currentTheme
                    )
                    
                    // Backtest Comparison
                    BacktestComparisonCard(
                        comparison: result.backtestResults,
                        theme: themeManager.currentTheme
                    )
                    
                    // Apply Button
                    Button(action: applyOptimization) {
                        Text("Apply Optimization")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.currentTheme.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Optimization Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func applyOptimization() {
        // Apply the optimized strategy
        // This would update the active strategy with optimized parameters
        dismiss()
    }
}

struct ImprovementsSummaryCard: View {
    let improvements: StrategyImprovements
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Improvements")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ImprovementItem(
                    label: "Profit",
                    value: String(format: "%+.1f%%", improvements.profitImprovement),
                    icon: "dollarsign.circle",
                    color: improvements.profitImprovement > 0 ? .green : .red,
                    theme: theme
                )
                
                ImprovementItem(
                    label: "Drawdown",
                    value: String(format: "%.1f%%", improvements.drawdownReduction),
                    icon: "shield",
                    color: improvements.drawdownReduction > 0 ? .green : .red,
                    theme: theme
                )
                
                ImprovementItem(
                    label: "Sharpe Ratio",
                    value: String(format: "%+.1f%%", improvements.sharpeRatioImprovement),
                    icon: "chart.line.uptrend.xyaxis",
                    color: improvements.sharpeRatioImprovement > 0 ? .green : .red,
                    theme: theme
                )
                
                ImprovementItem(
                    label: "Win Rate",
                    value: String(format: "%+.1f%%", improvements.winRateImprovement),
                    icon: "percent",
                    color: improvements.winRateImprovement > 0 ? .green : .red,
                    theme: theme
                )
            }
            
            // Consistency Score
            VStack(spacing: 8) {
                HStack {
                    Text("Strategy Consistency")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f/100", improvements.consistencyScore * 100))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.textColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.separatorColor)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(consistencyColor)
                            .frame(
                                width: geometry.size.width * improvements.consistencyScore,
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private var consistencyColor: Color {
        if improvements.consistencyScore > 0.8 { return .green }
        if improvements.consistencyScore > 0.6 { return .orange }
        return .red
    }
}

struct ImprovementItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.backgroundColor)
        .cornerRadius(12)
    }
}

struct RecommendationsCard: View {
    let recommendations: [OptimizationRecommendation]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimization Recommendations")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            ForEach(recommendations, id: \.parameter) { recommendation in
                RecommendationRow(
                    recommendation: recommendation, 
                    theme: theme,
                    isLast: recommendation == recommendations.last
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct RecommendationRow: View {
    let recommendation: OptimizationRecommendation
    let theme: Theme
    let isLast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.parameter)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(String(format: "%.2f", recommendation.originalValue))
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .strikethrough()
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text(String(format: "%.2f", recommendation.recommendedValue))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(theme.accentColor)
                }
            }
            
            Text(recommendation.impact)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
            
            // Confidence
            HStack {
                Text("Confidence")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                
                ConfidenceBar(confidence: recommendation.confidence, theme: theme)
                    .frame(width: 100)
            }
        }
        .padding(.vertical, 4)
        
        if !isLast {
            Divider()
                .background(theme.separatorColor)
        }
    }
}

struct BacktestComparisonCard: View {
    let comparison: BacktestComparison
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Backtest Comparison")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            HStack(spacing: 16) {
                PerformanceColumn(
                    title: "Original",
                    metrics: comparison.originalMetrics,
                    theme: theme,
                    highlight: false
                )
                
                Divider()
                    .background(theme.separatorColor)
                
                PerformanceColumn(
                    title: "Optimized",
                    metrics: comparison.optimizedMetrics,
                    theme: theme,
                    highlight: true
                )
            }
            
            // Overall Improvement
            HStack {
                Text("Overall Improvement")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Text(String(format: "+%.1f%%", comparison.improvementPercentage))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct PerformanceColumn: View {
    let title: String
    let metrics: PerformanceMetrics
    let theme: Theme
    let highlight: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(highlight ? .bold : .regular)
                .foregroundColor(theme.textColor)
            
            VStack(alignment: .leading, spacing: 4) {
                MetricValue(label: "Return", value: String(format: "%.1f%%", metrics.totalReturn), highlight: highlight, theme: theme)
                MetricValue(label: "Sharpe", value: String(format: "%.2f", metrics.sharpeRatio), highlight: highlight, theme: theme)
                MetricValue(label: "Drawdown", value: String(format: "%.1f%%", metrics.maxDrawdown * 100), highlight: highlight, theme: theme)
                MetricValue(label: "Win Rate", value: String(format: "%.1f%%", metrics.winRate * 100), highlight: highlight, theme: theme)
                MetricValue(label: "Profit Factor", value: String(format: "%.2f", metrics.profitFactor), highlight: highlight, theme: theme)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MetricValue: View {
    let label: String
    let value: String
    let highlight: Bool
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(highlight ? .medium : .regular)
                .foregroundColor(highlight ? theme.accentColor : theme.textColor)
        }
    }
}

struct PredictionDetailsCard: View {
    let prediction: PerformancePrediction
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Analysis")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            // Risk/Reward Visualization
            GeometryReader { geometry in
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.separatorColor)
                        .frame(height: 40)
                    
                    // Risk (Left side)
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.3))
                            .frame(width: geometry.size.width * 0.5 * abs(prediction.expectedDrawdown * 4), height: 40)
                        
                        Spacer()
                    }
                    
                    // Reward (Right side)
                    HStack(spacing: 0) {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.3))
                            .frame(width: geometry.size.width * 0.5 * (prediction.expectedReturn / 30), height: 40)
                    }
                    
                    // Center line
                    Rectangle()
                        .fill(theme.textColor)
                        .frame(width: 2, height: 40)
                        .position(x: geometry.size.width / 2, y: 20)
                    
                    // Labels
                    HStack {
                        Text("Risk")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 8)
                        
                        Spacer()
                        
                        Text("Reward")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.trailing, 8)
                    }
                }
            }
            .frame(height: 40)
            
            // Risk/Reward Ratio
            let ratio = abs(prediction.expectedReturn / (prediction.expectedDrawdown * 100))
            HStack {
                Text("Risk/Reward Ratio")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                Spacer()
                
                Text(String(format: "1:%.2f", ratio))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ratio > 2 ? .green : ratio > 1 ? .orange : .red)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct PredictionConfidenceCard: View {
    let confidence: Double
    let timeHorizon: TimeHorizon
    let theme: Theme
    
    var horizonText: String {
        switch timeHorizon {
        case .daily: return "24 hours"
        case .weekly: return "7 days"
        case .monthly: return "30 days"
        case .quarterly: return "90 days"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prediction Confidence")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            // Confidence Score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.0f%%", confidence * 100))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(confidenceColor)
                    
                    Text("ML Model Confidence")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                // Confidence Gauge
                ZStack {
                    Circle()
                        .stroke(theme.separatorColor, lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: confidence)
                        .stroke(confidenceColor, lineWidth: 8)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            Divider()
                .background(theme.separatorColor)
            
            // Time Horizon
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(theme.accentColor)
                
                Text("Prediction timeframe:")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                Text(horizonText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textColor)
            }
            
            // Disclaimer
            Text("Note: Predictions are based on historical data and ML models. Actual results may vary.")
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
                .italic()
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private var confidenceColor: Color {
        if confidence > 0.8 { return .green }
        if confidence > 0.6 { return .orange }
        return .red
    }
}

struct OptimizationSettingsView: View {
    @ObservedObject var viewModel: OptimizationViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var autoOptimizeEnabled = false
    @State private var optimizationInterval: TimeInterval = 7 * 24 * 3600
    @State private var selectedGoal: OptimizationGoal = .balancedRiskReward
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Auto-Optimization")) {
                    Toggle("Enable Auto-Optimization", isOn: $autoOptimizeEnabled)
                    
                    if autoOptimizeEnabled {
                        Picker("Optimization Interval", selection: $optimizationInterval) {
                            Text("Daily").tag(24.0 * 3600)
                            Text("Weekly").tag(7.0 * 24 * 3600)
                            Text("Bi-Weekly").tag(14.0 * 24 * 3600)
                            Text("Monthly").tag(30.0 * 24 * 3600)
                        }
                        
                        Picker("Default Goal", selection: $selectedGoal) {
                            Text("Maximize Profit").tag(OptimizationGoal.maximizeProfit)
                            Text("Minimize Drawdown").tag(OptimizationGoal.minimizeDrawdown)
                            Text("Maximize Sharpe").tag(OptimizationGoal.maximizeSharpeRatio)
                            Text("Balanced").tag(OptimizationGoal.balancedRiskReward)
                        }
                    }
                }
                
                Section(header: Text("Constraints")) {
                    HStack {
                        Text("Max Drawdown")
                        Spacer()
                        Text("\(Int(viewModel.defaultConstraints.maxDrawdown * 100))%")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Min Win Rate")
                        Spacer()
                        Text("\(Int(viewModel.defaultConstraints.minWinRate * 100))%")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Max Leverage")
                        Spacer()
                        Text("\(Int(viewModel.defaultConstraints.maxLeverage))x")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Optimization History")) {
                    HStack {
                        Text("Total Optimizations")
                        Spacer()
                        Text("\(viewModel.currentOptimizations.count)")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Active A/B Tests")
                        Spacer()
                        Text("\(viewModel.activeABTests.filter { Date() < $0.endDate }.count)")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Strategy Versions")
                        Spacer()
                        Text("\(viewModel.evolutionHistory.count)")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Optimization Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}