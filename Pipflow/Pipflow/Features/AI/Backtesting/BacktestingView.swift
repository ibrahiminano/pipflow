//
//  BacktestingView.swift
//  Pipflow
//
//  Strategy backtesting interface
//

import SwiftUI
import Charts

struct BacktestingView: View {
    @StateObject private var viewModel = BacktestingViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStrategy: TradingStrategy?
    @State private var selectedSymbol = "EURUSD"
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
    @State private var endDate = Date()
    @State private var initialCapital = 10000.0
    @State private var showResults = false
    @State private var showComparison = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.isBacktesting {
                    BacktestingProgressView(
                        progress: viewModel.backtestProgress,
                        theme: themeManager.currentTheme
                    )
                } else if showResults, let result = viewModel.currentResult {
                    BacktestResultsView(
                        result: result,
                        theme: themeManager.currentTheme,
                        onNewBacktest: {
                            showResults = false
                            viewModel.currentResult = nil
                        }
                    )
                } else {
                    BacktestSetupView(
                        selectedStrategy: $selectedStrategy,
                        selectedSymbol: $selectedSymbol,
                        startDate: $startDate,
                        endDate: $endDate,
                        initialCapital: $initialCapital,
                        availableStrategies: viewModel.availableStrategies,
                        theme: themeManager.currentTheme,
                        onRunBacktest: runBacktest,
                        onCompareStrategies: { showComparison = true }
                    )
                }
            }
            .navigationTitle("Strategy Backtesting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                if showResults {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: exportResults) {
                                Label("Export Results", systemImage: "square.and.arrow.up")
                            }
                            Button(action: saveStrategy) {
                                Label("Save Strategy", systemImage: "square.and.arrow.down")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showComparison) {
            StrategyComparisonView(
                strategies: viewModel.availableStrategies,
                symbol: selectedSymbol,
                startDate: startDate,
                endDate: endDate,
                theme: themeManager.currentTheme
            )
            .environmentObject(themeManager)
        }
    }
    
    private func runBacktest() {
        guard let strategy = selectedStrategy else { return }
        
        Task {
            await viewModel.runBacktest(
                strategy: strategy,
                symbol: selectedSymbol,
                startDate: startDate,
                endDate: endDate,
                initialCapital: initialCapital
            )
            
            showResults = true
        }
    }
    
    private func exportResults() {
        // Export functionality
    }
    
    private func saveStrategy() {
        // Save strategy
    }
}

// MARK: - Backtest Setup View

struct BacktestSetupView: View {
    @Binding var selectedStrategy: TradingStrategy?
    @Binding var selectedSymbol: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var initialCapital: Double
    
    let availableStrategies: [TradingStrategy]
    let theme: Theme
    let onRunBacktest: () -> Void
    let onCompareStrategies: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Strategy Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Strategy")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    ForEach(availableStrategies) { strategy in
                        StrategySelectionCard(
                            strategy: strategy,
                            isSelected: selectedStrategy?.id == strategy.id,
                            theme: theme
                        ) {
                            selectedStrategy = strategy
                        }
                    }
                    
                    Button(action: onCompareStrategies) {
                        HStack {
                            Image(systemName: "chart.xyaxis.line")
                            Text("Compare Multiple Strategies")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.accentColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(theme.secondaryBackgroundColor)
                .cornerRadius(16)
                
                // Market Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Market")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    SymbolPicker(
                        selectedSymbol: $selectedSymbol,
                        theme: theme
                    )
                }
                .padding()
                .background(theme.secondaryBackgroundColor)
                .cornerRadius(16)
                
                // Date Range
                VStack(alignment: .leading, spacing: 12) {
                    Text("Backtest Period")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .foregroundColor(theme.textColor)
                    
                    DatePicker("End Date", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                        .foregroundColor(theme.textColor)
                    
                    Text("\(daysBetween(startDate, endDate)) days of data")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding()
                .background(theme.secondaryBackgroundColor)
                .cornerRadius(16)
                
                // Capital Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Initial Capital")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    HStack {
                        Text("$")
                            .foregroundColor(theme.secondaryTextColor)
                        
                        TextField("10000", value: $initialCapital, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                .padding()
                .background(theme.secondaryBackgroundColor)
                .cornerRadius(16)
                
                // Run Button
                Button(action: onRunBacktest) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Run Backtest")
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
                .disabled(selectedStrategy == nil)
            }
            .padding()
        }
    }
    
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
}

// MARK: - Progress View

struct BacktestingProgressView: View {
    let progress: Double
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Progress Indicator
            ZStack {
                Circle()
                    .stroke(theme.separatorColor, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(theme.accentColor, lineWidth: 8)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text(currentPhase)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            Text("Running Backtest...")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.textColor)
            
            Text("This may take a few moments depending on the date range")
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var currentPhase: String {
        switch progress {
        case 0..<0.3:
            return "Loading Data"
        case 0.3..<0.6:
            return "Generating Signals"
        case 0.6..<0.9:
            return "Simulating Trades"
        default:
            return "Calculating Metrics"
        }
    }
}

// MARK: - Results View

struct BacktestResultsView: View {
    let result: BacktestResult
    let theme: Theme
    let onNewBacktest: () -> Void
    
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Results Tab Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ResultsTab(title: "Overview", icon: "chart.line.uptrend.xyaxis", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    ResultsTab(title: "Trades", icon: "list.bullet", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    ResultsTab(title: "Charts", icon: "chart.xyaxis.line", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                    ResultsTab(title: "Statistics", icon: "percent", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(theme.secondaryBackgroundColor)
            
            // Tab Content
            TabView(selection: $selectedTab) {
                BacktestOverviewTab(result: result, theme: theme)
                    .tag(0)
                
                BacktestTradesTab(trades: result.trades, theme: theme)
                    .tag(1)
                
                BacktestChartsTab(result: result, theme: theme)
                    .tag(2)
                
                BacktestStatisticsTab(result: result, theme: theme)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Action Button
            Button(action: onNewBacktest) {
                Text("Run New Backtest")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.accentColor.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - Overview Tab

struct BacktestOverviewTab: View {
    let result: BacktestResult
    let theme: Theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance Summary
                PerformanceSummaryCard(
                    performance: result.performance,
                    theme: theme
                )
                
                // Key Metrics Grid
                BacktestKeyMetricsGrid(
                    performance: result.performance,
                    statistics: result.statistics,
                    theme: theme
                )
                
                // Monthly Returns Heatmap
                if !result.monthlyReturns.isEmpty {
                    MonthlyReturnsHeatmap(
                        monthlyReturns: result.monthlyReturns,
                        theme: theme
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct StrategySelectionCard: View {
    let strategy: TradingStrategy
    let isSelected: Bool
    let theme: Theme
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strategy.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    Text(strategy.description)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? theme.accentColor : theme.secondaryTextColor)
                    .font(.system(size: 20))
            }
            .padding()
            .background(isSelected ? theme.accentColor.opacity(0.1) : theme.backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct SymbolPicker: View {
    @Binding var selectedSymbol: String
    let theme: Theme
    
    let symbols = ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCHF", "NZDUSD", "USDCAD"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(symbols, id: \.self) { symbol in
                    Button(action: { selectedSymbol = symbol }) {
                        Text(symbol)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedSymbol == symbol ? .white : theme.textColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedSymbol == symbol ? theme.accentColor : theme.backgroundColor)
                            )
                    }
                }
            }
        }
    }
}

struct ResultsTab: View {
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
class BacktestingViewModel: ObservableObject {
    @Published var isBacktesting = false
    @Published var backtestProgress: Double = 0
    @Published var currentResult: BacktestResult?
    @Published var availableStrategies: [TradingStrategy] = []
    
    private let backtestingEngine = BacktestingEngine.shared
    
    init() {
        loadAvailableStrategies()
    }
    
    private func loadAvailableStrategies() {
        // Load default strategies
        availableStrategies = [
            TradingStrategy(
                name: "RSI Oversold Bounce",
                description: "Buy when RSI < 30 and price touches lower Bollinger Band",
                conditions: [
                    StrategyCondition(type: .entry(.below), parameters: ["RSI", "lessThan", "30"], logicOperator: .and),
                    StrategyCondition(type: .entry(.below), parameters: ["Price", "lessThanOrEqual", "0"], logicOperator: .and) // Lower BB
                ],
                riskManagement: RiskManagement(
                    stopLossPercent: 0.5,
                    takeProfitPercent: 1.0,
                    positionSizePercent: 2.0,
                    maxOpenTrades: 3
                ),
                timeframe: .h1
            ),
            TradingStrategy(
                name: "Trend Following EMA",
                description: "Follow trend using EMA crossovers with momentum confirmation",
                conditions: [
                    StrategyCondition(type: .entry(.above), parameters: ["EMA20", "greaterThan", "0"], logicOperator: .and), // EMA50
                    StrategyCondition(type: .entry(.above), parameters: ["MACD", "greaterThan", "0"], logicOperator: .and)
                ],
                riskManagement: RiskManagement(
                    stopLossPercent: 1.0,
                    takeProfitPercent: 3.0,
                    positionSizePercent: 1.5,
                    maxOpenTrades: 2
                ),
                timeframe: .h4
            ),
            TradingStrategy(
                name: "Support/Resistance Breakout",
                description: "Trade breakouts from key support and resistance levels",
                conditions: [
                    StrategyCondition(type: .entry(.above), parameters: ["Price", "greaterThan", "0"], logicOperator: .and), // Resistance
                    StrategyCondition(type: .entry(.above), parameters: ["Volume", "greaterThan", "1.5"], logicOperator: .and) // Volume spike
                ],
                riskManagement: RiskManagement(
                    stopLossPercent: 0.75,
                    takeProfitPercent: 2.0,
                    positionSizePercent: 2.5,
                    maxOpenTrades: 4
                ),
                timeframe: .h1
            )
        ]
    }
    
    func runBacktest(strategy: TradingStrategy, symbol: String, startDate: Date, endDate: Date, initialCapital: Double) async {
        isBacktesting = true
        
        // Subscribe to progress updates
        let cancellable = backtestingEngine.$backtestProgress
            .assign(to: \.backtestProgress, on: self)
        
        let request = BacktestRequest(
            strategy: strategy,
            symbol: symbol,
            startDate: startDate,
            endDate: endDate,
            initialCapital: initialCapital,
            riskPerTrade: strategy.riskManagement.positionSizePercent / 100,
            commission: 0.0001,
            spread: 0.00001
        )
        
        do {
            let result = try await backtestingEngine.runBacktest(request)
            currentResult = result
        } catch {
            print("Backtest error: \(error)")
        }
        
        isBacktesting = false
        cancellable.cancel()
    }
}

// MARK: - Performance Summary Card

struct PerformanceSummaryCard: View {
    let performance: BacktestPerformanceMetrics
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Performance Summary")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                PerformanceMetricView(
                    title: "Total Return",
                    value: String(format: "%.2f%%", performance.totalReturn),
                    color: performance.totalReturn >= 0 ? .green : .red,
                    theme: theme
                )
                
                PerformanceMetricView(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", performance.winRate),
                    color: performance.winRate >= 50 ? .green : .orange,
                    theme: theme
                )
                
                PerformanceMetricView(
                    title: "Sharpe Ratio",
                    value: String(format: "%.2f", performance.sharpeRatio),
                    color: performance.sharpeRatio >= 1 ? .green : .orange,
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct PerformanceMetricView: View {
    let title: String
    let value: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}