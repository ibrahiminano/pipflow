//
//  MarketRegimeView.swift
//  Pipflow
//
//  Market regime detection and adaptive strategy interface
//

import SwiftUI
import Charts

struct MarketRegimeView: View {
    @StateObject private var viewModel = MarketRegimeViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSymbol = "EURUSD"
    @State private var showStrategyDetails = false
    @State private var selectedStrategy: AdaptedStrategy?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.isAnalyzing {
                    ProgressView("Detecting Market Regime...")
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                        .scaleEffect(1.5)
                } else if let analysis = viewModel.currentAnalysis {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Regime Header
                            RegimeHeaderCard(
                                analysis: analysis,
                                accuracy: viewModel.detectionAccuracy,
                                theme: themeManager.currentTheme
                            )
                            
                            // Symbol Selector
                            RegimeSymbolSelector(
                                selectedSymbol: $selectedSymbol,
                                theme: themeManager.currentTheme
                            ) {
                                Task {
                                    await viewModel.analyzeRegime(for: selectedSymbol)
                                }
                            }
                            
                            // Regime Indicators
                            RegimeIndicatorsCard(
                                indicators: analysis.indicators,
                                theme: themeManager.currentTheme
                            )
                            
                            // Market Structure
                            MarketStructureCard(
                                structure: analysis.indicators.marketStructure,
                                priceAction: analysis.indicators.priceAction,
                                theme: themeManager.currentTheme
                            )
                            
                            // Regime Transitions
                            if !analysis.regimeTransitions.isEmpty {
                                RegimeTransitionsCard(
                                    transitions: analysis.regimeTransitions,
                                    theme: themeManager.currentTheme
                                )
                            }
                            
                            // Adapted Strategies
                            AdaptedStrategiesSection(
                                strategies: analysis.adaptedStrategies,
                                currentRegime: analysis.currentRegime,
                                theme: themeManager.currentTheme
                            ) { strategy in
                                selectedStrategy = strategy
                                showStrategyDetails = true
                            }
                            
                            // Predictions
                            RegimePredictionsCard(
                                predictions: analysis.predictions,
                                theme: themeManager.currentTheme
                            )
                            
                            // Historical Regimes
                            if !viewModel.regimeHistory.isEmpty {
                                RegimeHistoryChart(
                                    history: viewModel.regimeHistory.filter { $0.symbol == selectedSymbol },
                                    theme: themeManager.currentTheme
                                )
                            }
                        }
                        .padding()
                    }
                } else {
                    // Initial state
                    VStack(spacing: 30) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        
                        Text("Select a symbol to analyze market regime")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        RegimeSymbolSelector(
                            selectedSymbol: $selectedSymbol,
                            theme: themeManager.currentTheme
                        ) {
                            Task {
                                await viewModel.analyzeRegime(for: selectedSymbol)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                await viewModel.analyzeRegime(for: selectedSymbol)
                            }
                        }) {
                            Label("Analyze Market", systemImage: "waveform.path.ecg")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding()
                                .background(themeManager.currentTheme.accentColor)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Market Regime")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: viewModel.toggleRealtimeDetection) {
                            Label(
                                viewModel.isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                                systemImage: viewModel.isMonitoring ? "pause.circle" : "play.circle"
                            )
                        }
                        Button(action: {
                            Task {
                                await viewModel.refreshAnalysis()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showStrategyDetails) {
            if let strategy = selectedStrategy {
                StrategyDetailsView(
                    strategy: strategy,
                    regime: viewModel.currentAnalysis?.currentRegime ?? .ranging
                )
                .environmentObject(themeManager)
            }
        }
    }
}

// MARK: - Regime Header Card

struct RegimeHeaderCard: View {
    let analysis: MarketRegimeAnalysis
    let accuracy: Double
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 16) {
            // Current Regime
            HStack {
                Image(systemName: analysis.currentRegime.icon)
                    .font(.system(size: 40))
                    .foregroundColor(analysis.currentRegime.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.currentRegime.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.textColor)
                    
                    Text(analysis.currentRegime.description)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f%%", analysis.confidence * 100))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(analysis.currentRegime.color)
                    
                    Text("Confidence")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            Divider()
                .background(theme.separatorColor)
            
            // Metrics
            HStack {
                RegimeMetric(
                    title: "Strength",
                    value: String(format: "%.1f", analysis.regimeStrength * 10),
                    color: strengthColor(analysis.regimeStrength),
                    theme: theme
                )
                
                RegimeMetric(
                    title: "Time in Regime",
                    value: formatDuration(analysis.timeInRegime),
                    color: theme.accentColor,
                    theme: theme
                )
                
                RegimeMetric(
                    title: "Detection Accuracy",
                    value: String(format: "%.1f%%", accuracy * 100),
                    color: accuracy > 0.7 ? .green : .orange,
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private func strengthColor(_ strength: Double) -> Color {
        switch strength {
        case 0..<0.3: return .red
        case 0.3..<0.6: return .orange
        case 0.6..<0.8: return .yellow
        default: return .green
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let days = hours / 24
        
        if days > 0 {
            return "\(days)d \(hours % 24)h"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = Int(interval) / 60
            return "\(minutes)m"
        }
    }
}

struct RegimeMetric: View {
    let title: String
    let value: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Regime Indicators Card

struct RegimeIndicatorsCard: View {
    let indicators: RegimeIndicators
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Regime Indicators")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            VStack(spacing: 12) {
                IndicatorBar(
                    name: "Trend Strength",
                    value: indicators.trendStrength,
                    theme: theme
                )
                
                IndicatorBar(
                    name: "Volatility",
                    value: min(indicators.volatility * 50, 1),
                    theme: theme
                )
                
                IndicatorBar(
                    name: "Momentum",
                    value: abs(indicators.momentum),
                    theme: theme
                )
                
                IndicatorBar(
                    name: "Volume",
                    value: min(indicators.volume / 5000, 1),
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct IndicatorBar: View {
    let name: String
    let value: Double
    let theme: Theme
    
    var color: Color {
        switch value {
        case 0..<0.3: return .blue
        case 0.3..<0.6: return .yellow
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.separatorColor)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * value, height: 6)
                        .animation(.easeInOut, value: value)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Market Structure Card

struct MarketStructureCard: View {
    let structure: MarketStructure
    let priceAction: PriceActionMetrics
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Market Structure")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            HStack(spacing: 20) {
                StructureMetric(
                    title: "Higher Highs",
                    value: "\(structure.higherHighs)",
                    icon: "arrow.up",
                    color: structure.higherHighs > 0 ? .green : .gray,
                    theme: theme
                )
                
                StructureMetric(
                    title: "Lower Lows",
                    value: "\(structure.lowerLows)",
                    icon: "arrow.down",
                    color: structure.lowerLows > 0 ? .red : .gray,
                    theme: theme
                )
                
                StructureMetric(
                    title: "Swing Points",
                    value: "\(structure.swingPoints.count)",
                    icon: "point.topleft.down.curvedto.point.bottomright.up",
                    color: theme.accentColor,
                    theme: theme
                )
            }
            
            if !priceAction.supportResistance.isEmpty {
                Divider()
                    .background(theme.separatorColor)
                
                Text("Key Levels")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                ForEach(priceAction.supportResistance.prefix(3)) { level in
                    HStack {
                        Circle()
                            .fill(level.type == .support ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        
                        Text(level.type == .support ? "Support" : "Resistance")
                            .font(.caption)
                            .foregroundColor(theme.textColor)
                        
                        Spacer()
                        
                        Text(String(format: "%.5f", level.price))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.textColor)
                        
                        Text("(\(level.touches))")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
            
            if !priceAction.candlePatterns.isEmpty {
                Divider()
                    .background(theme.separatorColor)
                
                Text("Recent Patterns")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                HStack {
                    ForEach(priceAction.candlePatterns.prefix(3)) { pattern in
                        CandlePatternChip(pattern: pattern, theme: theme)
                    }
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct StructureMetric: View {
    let title: String
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
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.textColor)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CandlePatternChip: View {
    let pattern: CandlePattern
    let theme: Theme
    
    var color: Color {
        switch pattern.type {
        case .bullish: return .green
        case .bearish: return .red
        case .neutral: return .gray
        }
    }
    
    var body: some View {
        Text(pattern.name)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .cornerRadius(12)
    }
}

// MARK: - Regime Transitions Card

struct RegimeTransitionsCard: View {
    let transitions: [RegimeTransition]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Potential Transitions")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            ForEach(transitions.prefix(3)) { transition in
                HStack {
                    Image(systemName: transition.fromRegime.icon)
                        .foregroundColor(transition.fromRegime.color)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Image(systemName: transition.toRegime.icon)
                        .foregroundColor(transition.toRegime.color)
                    
                    Text(transition.toRegime.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", transition.probability * 100))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(probabilityColor(transition.probability))
                }
                .padding(.vertical, 4)
                
                if transition != transitions.last {
                    Divider()
                        .background(theme.separatorColor.opacity(0.5))
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private func probabilityColor(_ probability: Double) -> Color {
        switch probability {
        case 0..<0.3: return .gray
        case 0.3..<0.6: return .orange
        default: return .green
        }
    }
}

// MARK: - Adapted Strategies Section

struct AdaptedStrategiesSection: View {
    let strategies: [AdaptedStrategy]
    let currentRegime: MarketRegime
    let theme: Theme
    let onSelectStrategy: (AdaptedStrategy) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Adapted Strategies")
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Text("for \(currentRegime.rawValue)")
                    .font(.caption)
                    .foregroundColor(currentRegime.color)
            }
            
            ForEach(strategies, id: \.strategyName) { strategy in
                AdaptedStrategyCard(
                    strategy: strategy,
                    theme: theme,
                    onTap: { onSelectStrategy(strategy) }
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct AdaptedStrategyCard: View {
    let strategy: AdaptedStrategy
    let theme: Theme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(strategy.strategyName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                        Text(String(format: "+%.0f%%", strategy.expectedImprovement * 100))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                }
                
                HStack(spacing: 16) {
                    StrategyAdjustment(
                        label: "Risk",
                        original: strategy.originalSettings.positionSize,
                        adapted: strategy.adaptedSettings.positionSize,
                        theme: theme
                    )
                    
                    StrategyAdjustment(
                        label: "Stop",
                        original: strategy.originalSettings.stopLoss,
                        adapted: strategy.adaptedSettings.stopLoss,
                        theme: theme,
                        format: "%.3f"
                    )
                    
                    StrategyAdjustment(
                        label: "Target",
                        original: strategy.originalSettings.takeProfit,
                        adapted: strategy.adaptedSettings.takeProfit,
                        theme: theme,
                        format: "%.3f"
                    )
                }
            }
            .padding()
            .background(theme.backgroundColor)
            .cornerRadius(12)
        }
    }
}

struct StrategyAdjustment: View {
    let label: String
    let original: Double
    let adapted: Double
    let theme: Theme
    var format: String = "%.1f%%"
    
    var changeColor: Color {
        if adapted > original { return .green }
        else if adapted < original { return .red }
        else { return theme.secondaryTextColor }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
            
            HStack(spacing: 4) {
                Text(String(format: format, format.contains("%%") ? original * 100 : original))
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .strikethrough()
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                
                Text(String(format: format, format.contains("%%") ? adapted * 100 : adapted))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(changeColor)
            }
        }
    }
}

// MARK: - Predictions Card

struct RegimePredictionsCard: View {
    let predictions: RegimePredictions
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Regime Predictions")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Likely Regime")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    HStack(spacing: 8) {
                        Image(systemName: predictions.nextRegime.icon)
                            .font(.system(size: 24))
                            .foregroundColor(predictions.nextRegime.color)
                        
                        Text(predictions.nextRegime.rawValue)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.textColor)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Probability")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text(String(format: "%.0f%%", predictions.transitionProbability * 100))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(probabilityColor(predictions.transitionProbability))
                }
            }
            
            Divider()
                .background(theme.separatorColor)
            
            HStack {
                Label("Time to Transition", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                Spacer()
                
                Text(formatDuration(predictions.timeToTransition))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textColor)
            }
            
            HStack {
                Label("Confidence Range", systemImage: "chart.bar")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                Spacer()
                
                Text(String(format: "%.0f%% - %.0f%%",
                           predictions.confidenceInterval.lower * 100,
                           predictions.confidenceInterval.upper * 100))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textColor)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private func probabilityColor(_ probability: Double) -> Color {
        switch probability {
        case 0..<0.3: return .red
        case 0.3..<0.6: return .orange
        default: return .green
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let days = hours / 24
        
        if days > 0 {
            return "~\(days) days"
        } else {
            return "~\(hours) hours"
        }
    }
}

// MARK: - Regime History Chart

@available(iOS 16.0, *)
struct RegimeHistoryChart: View {
    let history: [MarketRegimeAnalysis]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Regime History")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            Chart(history) { analysis in
                RectangleMark(
                    xStart: .value("Start", analysis.timestamp),
                    xEnd: .value("End", analysis.timestamp.addingTimeInterval(analysis.timeInRegime)),
                    yStart: .value("Regime", 0),
                    yEnd: .value("Regime", 1)
                )
                .foregroundStyle(analysis.currentRegime.color)
                .opacity(0.8)
            }
            .frame(height: 100)
            .chartYAxis(.hidden)
            
            // Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(MarketRegime.allCases, id: \.self) { regime in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(regime.color)
                                .frame(width: 8, height: 8)
                            
                            Text(regime.rawValue)
                                .font(.caption2)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - View Model

@MainActor
class MarketRegimeViewModel: ObservableObject {
    @Published var isAnalyzing = false
    @Published var currentAnalysis: MarketRegimeAnalysis?
    @Published var regimeHistory: [MarketRegimeAnalysis] = []
    @Published var detectionAccuracy: Double = 0
    @Published var isMonitoring = false
    
    private let detector = MarketRegimeDetector.shared
    
    init() {
        // Subscribe to detector updates
        detectionAccuracy = detector.detectionAccuracy
        regimeHistory = detector.regimeHistory
    }
    
    func analyzeRegime(for symbol: String) async {
        isAnalyzing = true
        
        do {
            let analysis = try await detector.detectMarketRegime(for: symbol)
            currentAnalysis = analysis
            detectionAccuracy = detector.detectionAccuracy
            regimeHistory = detector.regimeHistory
        } catch {
            print("Regime analysis error: \(error)")
        }
        
        isAnalyzing = false
    }
    
    func refreshAnalysis() async {
        if let symbol = currentAnalysis?.symbol {
            await analyzeRegime(for: symbol)
        }
    }
    
    func toggleRealtimeDetection() {
        if isMonitoring {
            detector.stopRealtimeDetection()
            isMonitoring = false
        } else {
            let symbols = ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD"]
            detector.startRealtimeDetection(symbols: symbols)
            isMonitoring = true
        }
    }
}

// MARK: - Strategy Details View

struct StrategyDetailsView: View {
    let strategy: AdaptedStrategy
    let regime: MarketRegime
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(strategy.strategyName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        HStack {
                            Label("Optimized for \(regime.rawValue)", systemImage: regime.icon)
                                .font(.caption)
                                .foregroundColor(regime.color)
                            
                            Spacer()
                            
                            Text(String(format: "+%.0f%% Expected", strategy.expectedImprovement * 100))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(16)
                    
                    // Settings Comparison
                    SettingsComparisonCard(
                        original: strategy.originalSettings,
                        adapted: strategy.adaptedSettings,
                        theme: themeManager.currentTheme
                    )
                    
                    // Risk Adjustment
                    RiskAdjustmentCard(
                        riskAdjustment: strategy.riskAdjustment,
                        theme: themeManager.currentTheme
                    )
                    
                    // Apply Button
                    Button(action: applyStrategy) {
                        Text("Apply This Strategy")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        themeManager.currentTheme.accentColor,
                                        themeManager.currentTheme.accentColor.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Strategy Details")
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
    
    private func applyStrategy() {
        // Apply the adapted strategy
        dismiss()
    }
}

struct SettingsComparisonCard: View {
    let original: StrategySettings
    let adapted: StrategySettings
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings Comparison")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            ComparisonRow(
                label: "Entry Threshold",
                original: String(format: "%.2f", original.entryThreshold),
                adapted: String(format: "%.2f", adapted.entryThreshold),
                theme: theme
            )
            
            ComparisonRow(
                label: "Exit Threshold",
                original: String(format: "%.2f", original.exitThreshold),
                adapted: String(format: "%.2f", adapted.exitThreshold),
                theme: theme
            )
            
            ComparisonRow(
                label: "Stop Loss",
                original: String(format: "%.1f%%", original.stopLoss * 100),
                adapted: String(format: "%.1f%%", adapted.stopLoss * 100),
                theme: theme
            )
            
            ComparisonRow(
                label: "Take Profit",
                original: String(format: "%.1f%%", original.takeProfit * 100),
                adapted: String(format: "%.1f%%", adapted.takeProfit * 100),
                theme: theme
            )
            
            ComparisonRow(
                label: "Position Size",
                original: String(format: "%.1f%%", original.positionSize * 100),
                adapted: String(format: "%.1f%%", adapted.positionSize * 100),
                theme: theme
            )
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct ComparisonRow: View {
    let label: String
    let original: String
    let adapted: String
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(original)
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryTextColor)
                    .strikethrough()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                Text(adapted)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.accentColor)
            }
        }
        
        if label != "Position Size" {
            Divider()
                .background(theme.separatorColor.opacity(0.5))
        }
    }
}

struct RiskAdjustmentCard: View {
    let riskAdjustment: Double
    let theme: Theme
    
    var adjustmentColor: Color {
        if riskAdjustment > 1.2 { return .red }
        else if riskAdjustment > 1 { return .orange }
        else if riskAdjustment < 0.8 { return .green }
        else { return .blue }
    }
    
    var adjustmentText: String {
        if riskAdjustment > 1.2 { return "Aggressive" }
        else if riskAdjustment > 1 { return "Moderate Risk" }
        else if riskAdjustment < 0.8 { return "Conservative" }
        else { return "Balanced" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Adjustment")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(adjustmentText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(adjustmentColor)
                    
                    Text("Risk multiplier: \(String(format: "%.1fx", riskAdjustment))")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(theme.separatorColor, lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: min(riskAdjustment / 2, 1))
                        .stroke(adjustmentColor, lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Symbol Selector

struct RegimeSymbolSelector: View {
    @Binding var selectedSymbol: String
    let theme: Theme
    let onSelect: () -> Void
    
    let symbols = ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCHF", "NZDUSD", "USDCAD"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(symbols, id: \.self) { symbol in
                    Button(action: {
                        selectedSymbol = symbol
                        onSelect()
                    }) {
                        Text(symbol)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedSymbol == symbol ? .white : theme.textColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedSymbol == symbol ? theme.accentColor : theme.secondaryBackgroundColor)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}