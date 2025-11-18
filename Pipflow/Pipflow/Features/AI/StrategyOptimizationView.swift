//
//  StrategyOptimizationView.swift
//  Pipflow
//
//  AI-powered strategy optimization interface
//

import SwiftUI
import Charts

struct StrategyOptimizationView: View {
    @StateObject private var optimizer = StrategyOptimizer.shared
    @StateObject private var backtester = BacktestingEngine.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var optimizationProgress = 0.0
    
    @State private var selectedStrategy: TradingStrategy?
    @State private var optimizationGoal: OptimizationGoal = .balancedRiskReward
    @State private var showingOptimizationSettings = false
    @State private var showingBacktestResults = false
    @State private var showingABTestSetup = false
    
    // Constraints
    @State private var maxDrawdown: Double = 20
    @State private var minWinRate: Double = 40
    @State private var maxLeverage: Double = 10
    @State private var minTradesPerMonth: Int = 10
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                OptimizationHeaderView()
                
                // Strategy Selector
                StrategySelector(selectedStrategy: $selectedStrategy)
                
                // Optimization Controls
                if selectedStrategy != nil {
                    OptimizationControlsView(
                        goal: $optimizationGoal,
                        maxDrawdown: $maxDrawdown,
                        minWinRate: $minWinRate,
                        showingSettings: $showingOptimizationSettings
                    )
                    
                    // Start Optimization Button
                    OptimizeButton(
                        isOptimizing: optimizer.isOptimizing,
                        action: startOptimization
                    )
                }
                
                // Current Optimization Progress
                if optimizer.isOptimizing {
                    OptimizationProgressView(progress: backtester.backtestProgress)
                }
                
                // Recent Optimizations
                if !optimizer.currentOptimizations.isEmpty {
                    RecentOptimizationsView(
                        optimizations: optimizer.currentOptimizations,
                        onSelect: { result in
                            showingBacktestResults = true
                        }
                    )
                }
                
                // Active A/B Tests
                if !optimizer.activeABTests.isEmpty {
                    ActiveABTestsView(tests: optimizer.activeABTests)
                }
                
                // Evolution History
                if !optimizer.evolutionHistory.isEmpty {
                    StrategyEvolutionView(history: optimizer.evolutionHistory)
                }
            }
            .padding()
        }
        .navigationTitle("Strategy Optimization")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingABTestSetup = true }) {
                        Label("New A/B Test", systemImage: "chart.xyaxis.line")
                    }
                    
                    Button(action: { showingOptimizationSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingOptimizationSettings) {
            StrategyOptimizationSettingsView(
                maxDrawdown: $maxDrawdown,
                minWinRate: $minWinRate,
                maxLeverage: $maxLeverage,
                minTradesPerMonth: $minTradesPerMonth
            )
        }
        .sheet(isPresented: $showingBacktestResults) {
            if let result = optimizer.currentOptimizations.first {
                OptimizationBacktestResultsView(result: result)
            }
        }
        .sheet(isPresented: $showingABTestSetup) {
            ABTestSetupView()
        }
    }
    
    private func startOptimization() {
        guard let strategy = selectedStrategy else { return }
        
        Task {
            let request = OptimizationRequest(
                strategy: strategy,
                historicalData: [], // Will be fetched by optimizer
                optimizationGoal: optimizationGoal,
                constraints: OptimizationConstraints(
                    maxDrawdown: maxDrawdown / 100,
                    minWinRate: minWinRate / 100,
                    maxLeverage: maxLeverage,
                    minTradesPerMonth: minTradesPerMonth,
                    maxConsecutiveLosses: 5
                ),
                timeframe: strategy.timeframe
            )
            
            do {
                _ = try await optimizer.optimizeStrategy(request)
            } catch {
                print("Optimization error: \(error)")
            }
        }
    }
}

// MARK: - Header View
struct OptimizationHeaderView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain")
                    .font(.largeTitle)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                
                VStack(alignment: .leading) {
                    Text("AI Strategy Optimization")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enhance your trading strategies with machine learning")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Strategy Selector
struct StrategySelector: View {
    @Binding var selectedStrategy: TradingStrategy?
    @EnvironmentObject var themeManager: ThemeManager
    
    // Mock strategies for demo
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Strategy")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(strategies) { strategy in
                        OptimizationStrategyCard(
                            strategy: strategy,
                            isSelected: selectedStrategy?.id == strategy.id,
                            action: { selectedStrategy = strategy }
                        )
                    }
                }
            }
        }
    }
}

struct OptimizationStrategyCard: View {
    let strategy: TradingStrategy
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : themeManager.currentTheme.accentColor)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                
                Text(strategy.name)
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                
                Text(strategy.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : themeManager.currentTheme.secondaryTextColor)
                    .lineLimit(2)
                
                HStack {
                    Label("\(strategy.timeframe.rawValue)", systemImage: "clock")
                        .font(.caption2)
                    
                    Spacer()
                    
                    Label("\(strategy.riskManagement.stopLossPercent)% SL", systemImage: "shield")
                        .font(.caption2)
                }
                .foregroundColor(isSelected ? .white.opacity(0.8) : themeManager.currentTheme.secondaryTextColor)
            }
            .padding()
            .frame(width: 200)
            .background(
                isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryBackgroundColor
            )
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Optimization Controls
struct OptimizationControlsView: View {
    @Binding var goal: OptimizationGoal
    @Binding var maxDrawdown: Double
    @Binding var minWinRate: Double
    @Binding var showingSettings: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Optimization Goal")
                .font(.headline)
            
            Picker("Goal", selection: $goal) {
                Text("Maximize Profit").tag(OptimizationGoal.maximizeProfit)
                Text("Minimize Drawdown").tag(OptimizationGoal.minimizeDrawdown)
                Text("Maximize Sharpe Ratio").tag(OptimizationGoal.maximizeSharpeRatio)
                Text("Balanced Risk/Reward").tag(OptimizationGoal.balancedRiskReward)
                Text("Minimize Volatility").tag(OptimizationGoal.minimizeVolatility)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Quick Constraints
            HStack {
                ConstraintBadge(
                    icon: "arrow.down.circle",
                    label: "Max DD",
                    value: "\(Int(maxDrawdown))%",
                    color: .red
                )
                
                ConstraintBadge(
                    icon: "percent",
                    label: "Min Win",
                    value: "\(Int(minWinRate))%",
                    color: .green
                )
                
                Spacer()
                
                Button(action: { showingSettings = true }) {
                    Label("More", systemImage: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct ConstraintBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Optimize Button
struct OptimizeButton: View {
    let isOptimizing: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isOptimizing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                
                Text(isOptimizing ? "Optimizing..." : "Start Optimization")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isOptimizing ? Color.gray : themeManager.currentTheme.accentColor
            )
            .cornerRadius(12)
        }
        .disabled(isOptimizing)
    }
}

// MARK: - Progress View
struct OptimizationProgressView: View {
    let progress: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Optimization Progress")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.currentTheme.secondaryBackgroundColor)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.currentTheme.accentColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            
            Text(getProgressStage(progress))
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(12)
    }
    
    private func getProgressStage(_ progress: Double) -> String {
        if progress < 0.3 {
            return "Fetching historical data..."
        } else if progress < 0.6 {
            return "Generating signals..."
        } else if progress < 0.9 {
            return "Running backtests..."
        } else {
            return "Finalizing results..."
        }
    }
}

// MARK: - Recent Optimizations
struct RecentOptimizationsView: View {
    let optimizations: [OptimizationResult]
    let onSelect: (OptimizationResult) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Optimizations")
                .font(.headline)
            
            ForEach(optimizations) { result in
                StrategyOptimizationResultCard(result: result, onTap: {
                    onSelect(result)
                })
            }
        }
    }
}

struct StrategyOptimizationResultCard: View {
    let result: OptimizationResult
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.originalStrategy.name)
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                        
                        Text("Optimized \(Date().relative())")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.caption)
                            Text("+\(Int(result.improvements.profitImprovement))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.green)
                        
                        Text("\(Int(result.confidence * 100))% confidence")
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                // Improvements Grid
                HStack(spacing: 16) {
                    StrategyImprovementMetric(
                        label: "Profit",
                        value: "+\(Int(result.improvements.profitImprovement))%",
                        color: .green
                    )
                    
                    StrategyImprovementMetric(
                        label: "Drawdown",
                        value: "-\(Int(result.improvements.drawdownReduction))%",
                        color: .blue
                    )
                    
                    StrategyImprovementMetric(
                        label: "Sharpe",
                        value: "+\(String(format: "%.1f", result.improvements.sharpeRatioImprovement))%",
                        color: .orange
                    )
                    
                    StrategyImprovementMetric(
                        label: "Win Rate",
                        value: "+\(Int(result.improvements.winRateImprovement))%",
                        color: .purple
                    )
                }
                
                // Recommendations Preview
                if !result.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key Recommendations")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        ForEach(result.recommendations.prefix(2), id: \.parameter) { rec in
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                                
                                Text("\(rec.parameter): \(rec.originalValue) → \(rec.recommendedValue)")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StrategyImprovementMetric: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        StrategyOptimizationView()
            .environmentObject(ThemeManager())
    }
}