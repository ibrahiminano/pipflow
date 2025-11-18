//
//  OptimizationView.swift
//  Pipflow
//
//  Strategy optimization and improvement interface
//

import SwiftUI
import Charts

struct OptimizationView: View {
    @StateObject private var viewModel = OptimizationViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStrategy: TradingStrategy?
    @State private var showStrategyPicker = false
    @State private var selectedTab = 0
    @State private var showOptimizationSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    OptimizationHeader(
                        selectedStrategy: selectedStrategy,
                        isOptimizing: viewModel.isOptimizing,
                        theme: themeManager.currentTheme
                    ) {
                        showStrategyPicker = true
                    }
                    
                    // Tab Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            OptimizationTab(title: "Optimize", icon: "wand.and.stars", isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            OptimizationTab(title: "A/B Tests", icon: "chart.xyaxis.line", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                            OptimizationTab(title: "Evolution", icon: "tree", isSelected: selectedTab == 2) {
                                selectedTab = 2
                            }
                            OptimizationTab(title: "Predictions", icon: "crystal.ball", isSelected: selectedTab == 3) {
                                selectedTab = 3
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        OptimizationMainTab(
                            viewModel: viewModel,
                            selectedStrategy: $selectedStrategy,
                            theme: themeManager.currentTheme
                        )
                        .tag(0)
                        
                        ABTestingTab(
                            abTests: viewModel.activeABTests,
                            theme: themeManager.currentTheme,
                            onCreateTest: { config in
                                Task {
                                    await viewModel.startABTest(config)
                                }
                            }
                        )
                        .tag(1)
                        
                        EvolutionTab(
                            history: viewModel.evolutionHistory,
                            theme: themeManager.currentTheme
                        )
                        .tag(2)
                        
                        PredictionsTab(
                            viewModel: viewModel,
                            selectedStrategy: selectedStrategy,
                            theme: themeManager.currentTheme
                        )
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Strategy Optimization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showOptimizationSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showStrategyPicker) {
            StrategyPickerView(selectedStrategy: $selectedStrategy)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showOptimizationSettings) {
            OptimizationSettingsView(viewModel: viewModel)
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Optimization Header

struct OptimizationHeader: View {
    let selectedStrategy: TradingStrategy?
    let isOptimizing: Bool
    let theme: Theme
    let onSelectStrategy: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Strategy Selector
            Button(action: onSelectStrategy) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Strategy")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        
                        Text(selectedStrategy?.name ?? "Select Strategy")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.textColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(theme.accentColor)
                }
                .padding()
                .background(theme.secondaryBackgroundColor)
                .cornerRadius(12)
            }
            
            if isOptimizing {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.accentColor))
                        .scaleEffect(0.8)
                    
                    Text("Optimizing strategy parameters...")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
        }
        .padding()
    }
}

// MARK: - Optimization Main Tab

struct OptimizationMainTab: View {
    @ObservedObject var viewModel: OptimizationViewModel
    @Binding var selectedStrategy: TradingStrategy?
    let theme: Theme
    
    @State private var optimizationGoal: OptimizationGoal = .balancedRiskReward
    @State private var showResults = false
    @State private var currentResult: OptimizationResult?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if selectedStrategy == nil {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "No Strategy Selected",
                        description: "Select a strategy to begin optimization",
                        theme: theme
                    )
                    .padding(.top, 50)
                } else {
                    // Optimization Goal
                    OptimizationGoalSelector(
                        selectedGoal: $optimizationGoal,
                        theme: theme
                    )
                    
                    // Constraints
                    OptimizationConstraintsCard(
                        constraints: viewModel.defaultConstraints,
                        theme: theme
                    )
                    
                    // Optimize Button
                    Button(action: {
                        Task {
                            await optimizeStrategy()
                        }
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Optimize Strategy")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [theme.accentColor, theme.accentColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isOptimizing)
                    
                    // Recent Optimizations
                    if !viewModel.currentOptimizations.isEmpty {
                        RecentOptimizationsSection(
                            optimizations: viewModel.currentOptimizations,
                            theme: theme
                        ) { result in
                            currentResult = result
                            showResults = true
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showResults) {
            if let result = currentResult {
                OptimizationResultView(result: result)
                    .environmentObject(ThemeManager.shared)
            }
        }
    }
    
    private func optimizeStrategy() async {
        guard let strategy = selectedStrategy else { return }
        
        let request = OptimizationRequest(
            strategy: strategy,
            historicalData: [], // Will be fetched by optimizer
            optimizationGoal: optimizationGoal,
            constraints: viewModel.defaultConstraints,
            timeframe: strategy.timeframe
        )
        
        _ = try? await viewModel.optimizeStrategy(request)
    }
}

// MARK: - Optimization Goal Selector

struct OptimizationGoalSelector: View {
    @Binding var selectedGoal: OptimizationGoal
    let theme: Theme
    
    let goals: [(OptimizationGoal, String, String)] = [
        (.maximizeProfit, "chart.line.uptrend.xyaxis", "Maximize Profit"),
        (.minimizeDrawdown, "shield", "Minimize Drawdown"),
        (.maximizeSharpeRatio, "chart.bar", "Maximize Sharpe"),
        (.balancedRiskReward, "scale.3d", "Balanced Risk/Reward"),
        (.minimizeVolatility, "waveform.path", "Minimize Volatility")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimization Goal")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(goals, id: \.0) { item in
                    OptimizationGoalCard(
                        goal: item.0,
                        icon: item.1,
                        title: item.2,
                        isSelected: selectedGoal == item.0,
                        theme: theme
                    ) {
                        selectedGoal = item.0
                    }
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct OptimizationGoalCard: View {
    let goal: OptimizationGoal
    let icon: String
    let title: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : theme.accentColor)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : theme.textColor)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? theme.accentColor : theme.backgroundColor)
            .cornerRadius(12)
        }
    }
}

// MARK: - Constraints Card

struct OptimizationConstraintsCard: View {
    let constraints: OptimizationConstraints
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Constraints")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            VStack(spacing: 8) {
                ConstraintRow(label: "Max Drawdown", value: "\(Int(constraints.maxDrawdown * 100))%", theme: theme)
                ConstraintRow(label: "Min Win Rate", value: "\(Int(constraints.minWinRate * 100))%", theme: theme)
                ConstraintRow(label: "Max Leverage", value: "\(Int(constraints.maxLeverage))x", theme: theme)
                ConstraintRow(label: "Min Trades/Month", value: "\(constraints.minTradesPerMonth)", theme: theme)
                ConstraintRow(label: "Max Consecutive Losses", value: "\(constraints.maxConsecutiveLosses)", theme: theme)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct ConstraintRow: View {
    let label: String
    let value: String
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.accentColor)
        }
    }
}

// MARK: - Recent Optimizations

struct RecentOptimizationsSection: View {
    let optimizations: [OptimizationResult]
    let theme: Theme
    let onSelect: (OptimizationResult) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Optimizations")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            ForEach(optimizations) { result in
                OptimizationResultCard(
                    result: result,
                    theme: theme,
                    onTap: { onSelect(result) }
                )
            }
        }
    }
}

struct OptimizationResultCard: View {
    let result: OptimizationResult
    let theme: Theme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(result.originalStrategy.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                    
                    Text(String(format: "+%.1f%%", result.improvements.profitImprovement))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                
                HStack(spacing: 20) {
                    ImprovementMetric(
                        label: "Sharpe",
                        value: String(format: "+%.1f%%", result.improvements.sharpeRatioImprovement),
                        isPositive: result.improvements.sharpeRatioImprovement > 0,
                        theme: theme
                    )
                    
                    ImprovementMetric(
                        label: "Drawdown",
                        value: String(format: "%.1f%%", result.improvements.drawdownReduction),
                        isPositive: result.improvements.drawdownReduction > 0,
                        theme: theme
                    )
                    
                    ImprovementMetric(
                        label: "Win Rate",
                        value: String(format: "+%.1f%%", result.improvements.winRateImprovement),
                        isPositive: result.improvements.winRateImprovement > 0,
                        theme: theme
                    )
                }
                
                // Confidence Bar
                HStack {
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Spacer()
                    
                    ConfidenceBar(confidence: result.confidence, theme: theme)
                }
            }
            .padding()
            .background(theme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
    }
}

struct ImprovementMetric: View {
    let label: String
    let value: String
    let isPositive: Bool
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? .green : .red)
        }
    }
}

struct ConfidenceBar: View {
    let confidence: Double
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Rectangle()
                    .fill(Double(index) < confidence * 5 ? theme.accentColor : theme.separatorColor)
                    .frame(width: 20, height: 4)
                    .cornerRadius(2)
            }
        }
    }
}

// MARK: - Tab Components

struct OptimizationTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(8)
        }
    }
}

// MARK: - View Model

@MainActor
class OptimizationViewModel: ObservableObject {
    @Published var isOptimizing = false
    @Published var currentOptimizations: [OptimizationResult] = []
    @Published var activeABTests: [ABTestResult] = []
    @Published var evolutionHistory: [StrategyEvolution] = []
    
    let defaultConstraints = OptimizationConstraints(
        maxDrawdown: 0.2,
        minWinRate: 0.4,
        maxLeverage: 10,
        minTradesPerMonth: 10,
        maxConsecutiveLosses: 5
    )
    
    private let optimizer = StrategyOptimizer.shared
    
    init() {
        // Sync with optimizer
        self.currentOptimizations = optimizer.currentOptimizations
        self.activeABTests = optimizer.activeABTests
        self.evolutionHistory = optimizer.evolutionHistory
    }
    
    func optimizeStrategy(_ request: OptimizationRequest) async throws -> OptimizationResult {
        isOptimizing = true
        let result = try await optimizer.optimizeStrategy(request)
        
        // Update local state
        currentOptimizations = optimizer.currentOptimizations
        evolutionHistory = optimizer.evolutionHistory
        
        isOptimizing = false
        return result
    }
    
    func startABTest(_ config: ABTestConfiguration) async {
        await optimizer.startABTest(config)
        activeABTests = optimizer.activeABTests
    }
    
    func predictPerformance(strategy: TradingStrategy) async -> PerformancePrediction? {
        let marketConditions = MarketConditions(
            volatilityIndex: 20,
            trendStrength: 0.6,
            correlations: [:],
            economicIndicators: []
        )
        
        return await optimizer.predictPerformance(
            strategy: strategy,
            marketConditions: marketConditions
        )
    }
}