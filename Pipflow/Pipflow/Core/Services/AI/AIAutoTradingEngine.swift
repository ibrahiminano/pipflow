//
//  AIAutoTradingEngine.swift
//  Pipflow
//
//  AI-powered automated trading engine
//

import Foundation
import Combine

// Type alias for compatibility
typealias AISignal = Signal

enum AutoTradingMode: String, CaseIterable {
    case conservative = "Conservative"
    case balanced = "Balanced"
    case aggressive = "Aggressive"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .conservative:
            return "Low risk, steady returns"
        case .balanced:
            return "Balanced risk/reward"
        case .aggressive:
            return "High risk, high reward"
        case .custom:
            return "User-defined parameters"
        }
    }
    
    var riskPerTrade: Double {
        switch self {
        case .conservative: return 0.01  // 1%
        case .balanced: return 0.02      // 2%
        case .aggressive: return 0.03    // 3%
        case .custom: return 0.02        // Default 2%
        }
    }
    
    var maxConcurrentTrades: Int {
        switch self {
        case .conservative: return 2
        case .balanced: return 4
        case .aggressive: return 6
        case .custom: return 4
        }
    }
}

enum AutoTradingState {
    case idle
    case analyzing
    case executingTrade
    case monitoring
    case paused
    case stopped
}

struct AutoTradingConfig {
    var mode: AutoTradingMode = .balanced
    var enabledPairs: Set<String> = ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD"]
    var maxDailyLoss: Double = 0.05  // 5%
    var maxPositionSize: Double = 1.0
    var minWinRate: Double = 0.55    // 55%
    var stopTradingOnConsecutiveLosses: Int = 3
    var tradingHours: AutoTradingHours = .allDay
    var useMarketRegimeFilter: Bool = true
    var requireConfirmation: Bool = false
}

struct AutoTradingHours {
    var startHour: Int
    var endHour: Int
    
    static let allDay = AutoTradingHours(startHour: 0, endHour: 24)
    static let londonNewYork = AutoTradingHours(startHour: 8, endHour: 17)
    static let asian = AutoTradingHours(startHour: 0, endHour: 9)
    
    func isWithinTradingHours() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        if startHour < endHour {
            return hour >= startHour && hour < endHour
        } else {
            // Handle overnight sessions
            return hour >= startHour || hour < endHour
        }
    }
}

struct AutoTradingMetrics {
    var totalTrades: Int = 0
    var winningTrades: Int = 0
    var losingTrades: Int = 0
    var totalProfit: Double = 0
    var totalLoss: Double = 0
    var consecutiveLosses: Int = 0
    var largestWin: Double = 0
    var largestLoss: Double = 0
    var dailyProfit: Double = 0
    var sessionStartBalance: Double = 0
    
    var winRate: Double {
        guard totalTrades > 0 else { return 0 }
        return Double(winningTrades) / Double(totalTrades)
    }
    
    var profitFactor: Double {
        guard totalLoss > 0 else { return totalProfit > 0 ? Double.infinity : 0 }
        return totalProfit / abs(totalLoss)
    }
    
    var netProfit: Double {
        return totalProfit - abs(totalLoss)
    }
    
    var averageWin: Double {
        guard winningTrades > 0 else { return 0 }
        return totalProfit / Double(winningTrades)
    }
    
    var averageLoss: Double {
        guard losingTrades > 0 else { return 0 }
        return abs(totalLoss) / Double(losingTrades)
    }
}

@MainActor
class AIAutoTradingEngine: ObservableObject {
    static let shared = AIAutoTradingEngine()
    
    @Published var state: AutoTradingState = .idle
    @Published var config = AutoTradingConfig()
    @Published var metrics = AutoTradingMetrics()
    @Published var isActive = false
    @Published var lastAnalysis: Date?
    @Published var currentSignals: [AISignal] = []
    @Published var activeTrades: [TrackedPosition] = []
    @Published var tradeHistory: [CompletedTrade] = []
    @Published var statusMessage = "Auto-trading inactive"
    
    private var cancellables = Set<AnyCancellable>()
    private var analysisTimer: Timer?
    private let analysisInterval: TimeInterval = 60 // 1 minute
    
    private let aiSignalService = AISignalService.shared
    private let marketDataService = MarketDataService.shared
    private let tradingService = TradingService.shared
    private let marketRegimeDetector = MarketRegimeDetector.shared
    private let riskAnalyzer = AIRiskAnalyzer.shared
    private let safetyManager = SafetyControlManager.shared
    
    private init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Monitor position changes
        PositionTrackingService.shared.$trackedPositions
            .sink { [weak self] positions in
                self?.updateActiveTrades(positions)
            }
            .store(in: &cancellables)
        
        // Monitor safety controls
        safetyManager.$settings
            .sink { [weak self] settings in
                if settings.isPaperTradingEnabled {
                    self?.statusMessage = "Paper trading mode active"
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func startAutoTrading() {
        guard !isActive else { return }
        
        isActive = true
        state = .analyzing
        statusMessage = "Auto-trading started"
        metrics.sessionStartBalance = tradingService.accountBalance
        
        // Start analysis loop
        analysisTimer = Timer.scheduledTimer(withTimeInterval: analysisInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performMarketAnalysis()
            }
        }
        
        // Perform initial analysis
        Task {
            await performMarketAnalysis()
        }
    }
    
    func stopAutoTrading() {
        isActive = false
        state = .stopped
        statusMessage = "Auto-trading stopped"
        analysisTimer?.invalidate()
        analysisTimer = nil
    }
    
    func pauseAutoTrading() {
        state = .paused
        statusMessage = "Auto-trading paused"
        analysisTimer?.invalidate()
    }
    
    func resumeAutoTrading() {
        guard isActive else { return }
        
        state = .analyzing
        statusMessage = "Auto-trading resumed"
        
        analysisTimer = Timer.scheduledTimer(withTimeInterval: analysisInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performMarketAnalysis()
            }
        }
    }
    
    // MARK: - Market Analysis
    
    private func performMarketAnalysis() async {
        guard state != .paused && state != .stopped else { return }
        
        state = .analyzing
        lastAnalysis = Date()
        
        // Check pre-conditions
        guard checkPreConditions() else {
            state = .monitoring
            return
        }
        
        // Analyze each enabled pair
        var potentialSignals: [AISignal] = []
        
        for symbol in config.enabledPairs {
            if let signal = await analyzeSymbol(symbol) {
                potentialSignals.append(signal)
            }
        }
        
        // Filter and rank signals
        let validSignals = filterSignals(potentialSignals)
        currentSignals = validSignals
        
        // Execute top signals
        if !validSignals.isEmpty {
            state = .executingTrade
            await executeTopSignals(validSignals)
        }
        
        state = .monitoring
        updateStatusMessage()
    }
    
    private func checkPreConditions() -> Bool {
        // Check trading hours
        if !config.tradingHours.isWithinTradingHours() {
            statusMessage = "Outside trading hours"
            return false
        }
        
        // Check daily loss limit
        let dailyPnL = metrics.dailyProfit
        let dailyLossPercent = abs(dailyPnL) / metrics.sessionStartBalance
        if dailyPnL < 0 && dailyLossPercent >= config.maxDailyLoss {
            statusMessage = "Daily loss limit reached"
            stopAutoTrading()
            return false
        }
        
        // Check consecutive losses
        if metrics.consecutiveLosses >= config.stopTradingOnConsecutiveLosses {
            statusMessage = "Max consecutive losses reached"
            pauseAutoTrading()
            return false
        }
        
        // Check concurrent trades
        if activeTrades.count >= config.mode.maxConcurrentTrades {
            statusMessage = "Max concurrent trades reached"
            return false
        }
        
        // Check safety controls
        if !safetyManager.canExecuteTrade(
            symbol: "",
            side: .buy,
            volume: 0,
            currentBalance: tradingService.accountBalance
        ).canTrade {
            statusMessage = "Safety controls preventing trades"
            return false
        }
        
        return true
    }
    
    private func analyzeSymbol(_ symbol: String) async -> AISignal? {
        // Get market data
        guard let marketData = marketDataService.getMarketData(for: symbol) else {
            return nil
        }
        
        // Check market regime if enabled
        if config.useMarketRegimeFilter {
            let regime = marketRegimeDetector.currentRegime
            // Check if market is too volatile or confidence is too low
            if regime.currentRegime == .volatile || regime.confidence < 0.6 {
                return nil
            }
        }
        
        // Generate AI signal
        let request = AISignalRequest(
            symbol: symbol,
            timeframe: "H1",
            marketData: marketData,
            technicalIndicators: marketDataService.technicalIndicators ?? TechnicalIndicators(
                rsi: nil,
                macd: nil,
                movingAverages: nil,
                support: nil,
                resistance: nil,
                trend: .neutral
            ),
            recentNews: nil
        )
        
        // Use Combine to async conversion
        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = aiSignalService.generateSignal(
                for: symbol,
                timeframe: "H1",
                marketData: marketData,
                technicalIndicators: marketDataService.technicalIndicators ?? TechnicalIndicators(
                    rsi: nil,
                    macd: nil,
                    movingAverages: nil,
                    support: nil,
                    resistance: nil,
                    trend: .neutral
                )
            )
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            print("Error generating signal for \(symbol): \(error)")
                            continuation.resume(returning: nil)
                        case .finished:
                            break
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { signal in
                        // Additional validation
                        if signal.confidence >= 0.7 && self.validateSignal(signal) {
                            continuation.resume(returning: signal)
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                )
        }
    }
    
    private func calculateRRRatio(entry: Double, sl: Double, tp: Double) -> Double {
        let risk = abs(entry - sl)
        let reward = abs(tp - entry)
        return risk > 0 ? reward / risk : 0
    }
    
    private func determineAnalysisType() -> String {
        switch config.mode {
        case .conservative:
            return "conservative_trend_following"
        case .balanced:
            return "balanced_momentum"
        case .aggressive:
            return "aggressive_breakout"
        case .custom:
            return "adaptive_strategy"
        }
    }
    
    private func validateSignal(_ signal: AISignal) -> Bool {
        // Validate risk/reward ratio
        let entry = signal.entry
        let sl = signal.stopLoss
        let tp = signal.takeProfits.first?.price ?? entry
        
        let risk = abs(NSDecimalNumber(decimal: entry - sl).doubleValue)
        let reward = abs(NSDecimalNumber(decimal: tp - entry).doubleValue)
        let rrRatio = risk > 0 ? reward / risk : 0
        
        // Minimum 1.5:1 RR ratio
        if rrRatio < 1.5 {
            return false
        }
        
        // Check against recent performance
        if metrics.winRate < config.minWinRate && metrics.totalTrades > 10 {
            // Be more selective when underperforming
            return signal.confidence >= 0.8
        }
        
        return true
    }
    
    private func filterSignals(_ signals: [AISignal]) -> [AISignal] {
        return signals
            .filter { $0.confidence >= 0.7 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(config.mode.maxConcurrentTrades - activeTrades.count)
            .map { $0 }
    }
    
    // MARK: - Trade Execution
    
    private func executeTopSignals(_ signals: [AISignal]) async {
        for signal in signals {
            // Calculate position size
            let positionSize = calculatePositionSize(for: signal)
            
            // Check if confirmation required
            if config.requireConfirmation {
                // Store signal for manual confirmation
                // In a real app, this would trigger a notification
                statusMessage = "Signal requires confirmation: \(signal.symbol)"
                continue
            }
            
            // Execute trade
            await executeTrade(signal: signal, volume: positionSize)
        }
    }
    
    private func calculatePositionSize(for signal: AISignal) -> Double {
        let accountBalance = tradingService.accountBalance
        let riskAmount = accountBalance * config.mode.riskPerTrade
        
        let entry = NSDecimalNumber(decimal: signal.entry).doubleValue
        let stopLoss = NSDecimalNumber(decimal: signal.stopLoss).doubleValue
        
        let pipRisk = abs(entry - stopLoss) * 10000
        let pipValue = 10.0 // Simplified - should be calculated based on pair
        
        var positionSize = riskAmount / (pipRisk * pipValue)
        
        // Apply limits
        positionSize = min(positionSize, config.maxPositionSize)
        positionSize = max(positionSize, 0.01)
        
        return round(positionSize * 100) / 100
    }
    
    private func executeTrade(signal: AISignal, volume: Double) async {
        let request = ExecutionTradeRequest(
            symbol: signal.symbol,
            side: signal.action == .buy ? .buy : .sell,
            volume: volume,
            stopLoss: NSDecimalNumber(decimal: signal.stopLoss).doubleValue,
            takeProfit: signal.takeProfits.first.map { NSDecimalNumber(decimal: $0.price).doubleValue },
            comment: "AI Auto-Trade",
            magicNumber: 777 // AI trading identifier
        )
        
        do {
            try await tradingService.executeTrade(
                symbol: request.symbol,
                side: request.side,
                volume: request.volume,
                stopLoss: request.stopLoss,
                takeProfit: request.takeProfit,
                comment: request.comment
            )
            statusMessage = "Executed \(signal.action.rawValue) \(signal.symbol)"
        } catch {
            print("Trade execution error: \(error)")
            statusMessage = "Trade execution failed"
        }
    }
    
    // MARK: - Position Management
    
    private func updateActiveTrades(_ positions: [TrackedPosition]) {
        // Filter positions opened by auto-trading
        activeTrades = positions.filter { $0.magic == 777 }
        
        // Update metrics for closed positions
        for trade in activeTrades {
            if trade.unrealizedPL != 0 {
                // Position still open, monitor it
                monitorPosition(trade)
            }
        }
    }
    
    private func monitorPosition(_ position: TrackedPosition) {
        // Implement trailing stop logic
        if position.unrealizedPL > 0 {
            let profitPips = position.pipsProfit
            if profitPips > 30 {
                // Move stop loss to breakeven
                adjustStopLoss(position: position, newSL: position.openPrice)
            } else if profitPips > 50 {
                // Trail stop loss
                let trailDistance = 20.0 / 10000
                let newSL = position.type == .buy
                    ? position.currentPrice - trailDistance
                    : position.currentPrice + trailDistance
                adjustStopLoss(position: position, newSL: newSL)
            }
        }
    }
    
    private func adjustStopLoss(position: TrackedPosition, newSL: Double) {
        // Implement stop loss modification
        Task {
            // This would call MetaAPI to modify the position
            print("Adjusting SL for \(position.symbol) to \(newSL)")
        }
    }
    
    // MARK: - Helpers
    
    private func updateStatusMessage() {
        if state == .analyzing {
            statusMessage = "Analyzing \(config.enabledPairs.count) pairs..."
        } else if state == .monitoring {
            statusMessage = "Monitoring \(activeTrades.count) positions"
        } else if state == .executingTrade {
            statusMessage = "Executing trades..."
        }
    }
}

struct CompletedTrade: Identifiable {
    let id = UUID()
    let symbol: String
    let side: TradeSide
    let openPrice: Double
    let closePrice: Double
    let volume: Double
    let profit: Double
    let openTime: Date
    let closeTime: Date
    let duration: TimeInterval
    
    var pips: Double {
        return abs(closePrice - openPrice) * 10000
    }
    
    var isWin: Bool {
        return profit > 0
    }
}