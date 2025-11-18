//
//  PromptTradingEngine.swift
//  Pipflow
//
//  Revolutionary AI Prompt Trading System - Main Engine
//

import Foundation
import Combine
import SwiftUI

// MARK: - Trading Prompt Models

struct TradingPrompt: Identifiable, Codable {
    let id: String
    let userId: String
    var title: String
    var prompt: String
    let createdDate: Date
    var lastModified: Date
    var isActive: Bool
    var performanceMetrics: PromptPerformance?
    
    init(userId: String, title: String, prompt: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.title = title
        self.prompt = prompt
        self.createdDate = Date()
        self.lastModified = Date()
        self.isActive = false
        self.performanceMetrics = nil
    }
}

struct PromptPerformance: Codable {
    var totalTrades: Int = 0
    var winningTrades: Int = 0
    var totalProfitLoss: Double = 0
    var maxDrawdown: Double = 0
    var averageHoldTime: TimeInterval = 0
    var lastTradeDate: Date?
    var winRate: Double = 0
    var profitFactor: Double = 0
    var sharpeRatio: Double = 0
    
    mutating func updateMetrics() {
        if totalTrades > 0 {
            winRate = Double(winningTrades) / Double(totalTrades)
        }
    }
}

struct TradingContext: Codable {
    var capital: Double
    var riskPerTrade: Double // Percentage (e.g., 0.02 = 2%)
    var maxOpenTrades: Int
    var allowedSymbols: [String]
    var excludedSymbols: [String]
    var timeRestrictions: TimeRestrictions?
    var indicators: [TechnicalIndicator]
    var conditions: [TradingCondition]
    var stopLossStrategy: StopLossStrategy
    var takeProfitStrategy: TakeProfitStrategy
    
    init(capital: Double = 1000, riskPerTrade: Double = 0.02) {
        self.capital = capital
        self.riskPerTrade = riskPerTrade
        self.maxOpenTrades = 5
        self.allowedSymbols = []
        self.excludedSymbols = []
        self.timeRestrictions = nil
        self.indicators = []
        self.conditions = []
        self.stopLossStrategy = .percentage(0.02)
        self.takeProfitStrategy = .riskReward(2.0)
    }
    
    init(capital: Double,
         riskPerTrade: Double,
         maxOpenTrades: Int,
         allowedSymbols: [String],
         excludedSymbols: [String],
         timeRestrictions: TimeRestrictions?,
         indicators: [TechnicalIndicator],
         conditions: [TradingCondition],
         stopLossStrategy: StopLossStrategy,
         takeProfitStrategy: TakeProfitStrategy) {
        self.capital = capital
        self.riskPerTrade = riskPerTrade
        self.maxOpenTrades = maxOpenTrades
        self.allowedSymbols = allowedSymbols
        self.excludedSymbols = excludedSymbols
        self.timeRestrictions = timeRestrictions
        self.indicators = indicators
        self.conditions = conditions
        self.stopLossStrategy = stopLossStrategy
        self.takeProfitStrategy = takeProfitStrategy
    }
}

struct TimeRestrictions: Codable {
    var allowedHours: [Int] // 0-23
    var allowedDaysOfWeek: [Int] // 1-7 (Monday-Sunday)
    var excludeNewsEvents: Bool
    var excludeMarketOpen: Bool
    var excludeMarketClose: Bool
}

struct TechnicalIndicator: Codable {
    let type: IndicatorType
    let parameters: [String: Double]
    let condition: IndicatorCondition
    
    enum IndicatorType: String, Codable, CaseIterable {
        case rsi = "RSI"
        case macd = "MACD"
        case movingAverage = "MA"
        case bollingerBands = "BB"
        case stochastic = "STOCH"
        case atr = "ATR"
        case support = "SUPPORT"
        case resistance = "RESISTANCE"
    }
    
    enum IndicatorCondition: String, Codable, CaseIterable {
        case above = "above"
        case below = "below"
        case crossesAbove = "crosses_above"
        case crossesBelow = "crosses_below"
        case between = "between"
        case outside = "outside"
    }
}

struct TradingCondition: Codable {
    let type: ConditionType
    let parameters: [String: String]
    let `operator`: LogicalOperator
    
    enum ConditionType: String, Codable, CaseIterable {
        case priceAction = "price_action"
        case volumeSpike = "volume_spike"
        case newsEvent = "news_event"
        case marketSentiment = "market_sentiment"
        case timeOfDay = "time_of_day"
        case custom = "custom"
    }
    
    enum LogicalOperator: String, Codable, CaseIterable {
        case and = "AND"
        case or = "OR"
        case not = "NOT"
    }
}

enum StopLossStrategy: Codable {
    case percentage(Double)
    case atr(Double) // ATR multiplier
    case fixedPips(Double)
    case supportResistance
    case none
}

enum TakeProfitStrategy: Codable {
    case riskReward(Double) // Risk:Reward ratio
    case percentage(Double)
    case fixedPips(Double)
    case supportResistance
    case trailing(Double) // Trailing percentage
    case none
}

// MARK: - Main Prompt Trading Engine

@MainActor
class PromptTradingEngine: ObservableObject {
    static let shared = PromptTradingEngine()
    
    @Published var activePrompts: [TradingPrompt] = [] {
        didSet {
            print("PromptTradingEngine: activePrompts updated, count: \(activePrompts.count)")
        }
    }
    @Published var promptPerformance: [String: PromptPerformance] = [:]
    @Published var isEngineRunning: Bool = false
    @Published var lastEngineUpdate: Date = Date()
    
    private let promptParser = PromptParser()
    private let contextManager = ContextManager.shared
    private let promptValidator = PromptValidator()
    private let aiDecisionEngine = AIDecisionEngine()
    private let conditionMonitor = ConditionMonitor.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var engineTimer: Timer?
    
    private init() {
        setupEngineBindings()
        loadMockPrompts()
        print("PromptTradingEngine initialized with \(activePrompts.count) prompts")
    }
    
    // MARK: - Mock Data
    
    private func loadMockPrompts() {
        let mockPrompts = [
            TradingPrompt(
                userId: "mock-user-1",
                title: "EUR/USD Scalper",
                prompt: "Trade EUR/USD when RSI is below 30 for buy or above 70 for sell. Use 1% risk per trade with 10 pip stop loss and 20 pip take profit."
            ),
            TradingPrompt(
                userId: "mock-user-1",
                title: "Trend Following Strategy",
                prompt: "Follow strong trends using 20/50 EMA crossover on 4H timeframe. Enter long when 20 EMA crosses above 50 EMA with 2% risk per trade."
            ),
            TradingPrompt(
                userId: "mock-user-1",
                title: "News Trading Bot",
                prompt: "Monitor high impact news events and trade breakouts. Use pending orders 10 pips above/below current price before news with tight 5 pip stop loss."
            ),
            TradingPrompt(
                userId: "mock-user-1",
                title: "Support/Resistance Trader",
                prompt: "Identify key support and resistance levels on daily chart. Buy at support with confirmation, sell at resistance. Risk 1.5% per trade."
            ),
            TradingPrompt(
                userId: "mock-user-1",
                title: "Asian Session Scalper",
                prompt: "Trade USDJPY and EURJPY during Asian session when volatility is low. Use 5-minute chart with 5 pip targets."
            )
        ]
        
        // Activate some prompts and add performance metrics
        for (index, var prompt) in mockPrompts.enumerated() {
            prompt.isActive = index < 3 // First 3 are active
            
            // Add mock performance metrics
            var performance = PromptPerformance()
            performance.totalTrades = Int.random(in: 10...50)
            performance.winningTrades = Int(Double(performance.totalTrades) * Double.random(in: 0.55...0.75))
            performance.totalProfitLoss = Double.random(in: 500...5000)
            performance.maxDrawdown = Double.random(in: -500...(-100))
            performance.averageHoldTime = TimeInterval(3600 * Double.random(in: 1...24))
            performance.lastTradeDate = Date().addingTimeInterval(-TimeInterval.random(in: 0...86400))
            performance.updateMetrics()
            
            prompt.performanceMetrics = performance
            activePrompts.append(prompt)
        }
    }
    
    // MARK: - Engine Management
    
    func startEngine() {
        guard !isEngineRunning else { return }
        
        isEngineRunning = true
        startEngineTimer()
        
        print("🚀 Prompt Trading Engine started")
    }
    
    func stopEngine() {
        isEngineRunning = false
        engineTimer?.invalidate()
        engineTimer = nil
        
        print("⏹️ Prompt Trading Engine stopped")
    }
    
    private func setupEngineBindings() {
        // Monitor market data changes
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if self?.isEngineRunning == true {
                    Task { @MainActor in
                        await self?.processActivePrompts()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func startEngineTimer() {
        engineTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.lastEngineUpdate = Date()
                await self.monitorConditions()
            }
        }
    }
    
    // MARK: - Prompt Management
    
    func createPrompt(userId: String, title: String, promptText: String) async -> Result<TradingPrompt, PromptError> {
        // Validate prompt
        let validation = await promptValidator.validatePrompt(promptText)
        guard validation.isValid else {
            return .failure(.invalidPrompt(validation.errors.joined(separator: ", ")))
        }
        
        // Parse prompt to extract trading context
        do {
            let context = try await promptParser.parsePrompt(promptText)
            let prompt = TradingPrompt(userId: userId, title: title, prompt: promptText)
            
            // Store context
            await contextManager.storeContext(for: prompt.id, context: context)
            
            // Add to active prompts if valid
            if validation.isValid {
                activePrompts.append(prompt)
                promptPerformance[prompt.id] = PromptPerformance()
            }
            
            print("✅ Created prompt: \(title)")
            return .success(prompt)
            
        } catch {
            return .failure(.parsingFailed(error.localizedDescription))
        }
    }
    
    func activatePrompt(_ promptId: String) {
        if let index = activePrompts.firstIndex(where: { $0.id == promptId }) {
            activePrompts[index].isActive = true
            print("▶️ Activated prompt: \(activePrompts[index].title)")
        }
    }
    
    func deactivatePrompt(_ promptId: String) {
        if let index = activePrompts.firstIndex(where: { $0.id == promptId }) {
            activePrompts[index].isActive = false
            print("⏸️ Deactivated prompt: \(activePrompts[index].title)")
        }
    }
    
    func deletePrompt(_ promptId: String) {
        activePrompts.removeAll { $0.id == promptId }
        promptPerformance.removeValue(forKey: promptId)
        Task {
            await contextManager.removeContext(for: promptId)
        }
        print("🗑️ Deleted prompt: \(promptId)")
    }
    
    // MARK: - Core Processing
    
    private func processActivePrompts() async {
        let activePromptsList = activePrompts.filter { $0.isActive }
        
        for prompt in activePromptsList {
            await processPrompt(prompt)
        }
    }
    
    private func processPrompt(_ prompt: TradingPrompt) async {
        guard let context = await contextManager.getContext(for: prompt.id) else {
            print("❌ No context found for prompt: \(prompt.title)")
            return
        }
        
        // Check if conditions are met
        let conditionsMetResult = await conditionMonitor.checkConditions(context.conditions)
        guard conditionsMetResult.allMet else {
            return // Conditions not met, skip this cycle
        }
        
        // Get AI decision
        do {
            let decision = try await aiDecisionEngine.makeDecision(
                prompt: prompt.prompt,
                context: context,
                marketData: getCurrentMarketData()
            )
            
            if let tradeDecision = decision.tradeDecision {
                await executeTradeDecision(tradeDecision, for: prompt, context: context)
            }
            
        } catch {
            print("❌ AI Decision error for prompt \(prompt.title): \(error)")
        }
    }
    
    private func executeTradeDecision(_ decision: AITradeDecision, for prompt: TradingPrompt, context: TradingContext) async {
        // Additional safety checks
        guard await promptValidator.validateTradeDecision(decision, context: context) else {
            print("🛡️ Trade decision blocked by safety validator")
            return
        }
        
        // Calculate position size based on context
        let positionSize = calculatePositionSize(
            capital: context.capital,
            riskPerTrade: context.riskPerTrade,
            stopLoss: decision.stopLoss,
            entryPrice: decision.entryPrice
        )
        
        // Create trade request
        let tradeRequest = TradeRequest(
            symbol: decision.symbol,
            type: .buy, // Market order
            side: decision.side,
            volume: positionSize,
            stopLoss: decision.stopLoss,
            takeProfit: decision.takeProfit,
            comment: "AI Prompt: \(prompt.title.prefix(20))"
        )
        
        // Execute trade
        do {
            try await MetaAPIService.shared.openPosition(
                symbol: decision.symbol,
                side: decision.side,
                volume: positionSize,
                stopLoss: decision.stopLoss,
                takeProfit: decision.takeProfit
            )
            
            // Create trade result for performance tracking
            let result = TradeResult(
                positionId: UUID().uuidString,
                success: true,
                error: nil
            )
            await updatePromptPerformance(promptId: prompt.id, trade: result)
            
            print("✅ Executed trade for prompt: \(prompt.title) | \(decision.symbol) \(decision.side)")
            
        } catch {
            print("❌ Trade execution failed: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func monitorConditions() async {
        // Monitor all active prompt conditions in real-time
        for prompt in activePrompts.filter({ $0.isActive }) {
            if let context = await contextManager.getContext(for: prompt.id) {
                await conditionMonitor.updateConditionStatus(for: prompt.id, conditions: context.conditions)
            }
        }
    }
    
    private func getCurrentMarketData() -> [String: Any] {
        // Get current market data from MarketDataService
        let marketData = MarketDataService.shared.marketData
        return marketData.mapValues { extendedData in
            [
                "bid": extendedData.marketData.bid,
                "ask": extendedData.marketData.ask,
                "spread": extendedData.marketData.spread,
                "currentPrice": extendedData.marketData.currentPrice,
                "high24h": extendedData.marketData.high24h,
                "low24h": extendedData.marketData.low24h,
                "volume24h": extendedData.marketData.volume24h,
                "priceChange24h": extendedData.marketData.priceChange24h
            ]
        }
    }
    
    private func calculatePositionSize(capital: Double, riskPerTrade: Double, stopLoss: Double?, entryPrice: Double) -> Double {
        guard let sl = stopLoss else {
            // Default to 1% of capital converted to lots
            return (capital * 0.01) / 100000 // Standard lot size
        }
        
        let riskAmount = capital * riskPerTrade
        let pipRisk = abs(entryPrice - sl) * 10000 // Convert to pips
        let pipValue = 10.0 // USD per pip for standard lot
        
        guard pipRisk > 0 else { return 0.01 } // Minimum lot size
        
        let positionSize = riskAmount / (pipRisk * pipValue)
        return max(0.01, min(positionSize, 10.0)) // Between 0.01 and 10 lots
    }
    
    private func updatePromptPerformance(promptId: String, trade: TradeResult) async {
        guard var performance = promptPerformance[promptId] else { return }
        
        performance.totalTrades += 1
        performance.lastTradeDate = Date()
        
        // Update other metrics based on trade result
        // This would be expanded with actual P&L calculation
        performance.updateMetrics()
        
        promptPerformance[promptId] = performance
    }
    
    func getPromptPerformance(for promptId: String) -> PromptPerformance? {
        return promptPerformance[promptId]
    }
    
    func getAllActivePrompts() -> [TradingPrompt] {
        return activePrompts.filter { $0.isActive }
    }
}

// MARK: - Supporting Types

struct AITradeDecision {
    let symbol: String
    let side: TradeSide
    let entryPrice: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let confidence: Double // 0.0 to 1.0
    let reasoning: String
}

struct ConditionResult {
    let allMet: Bool
    let metConditions: [String]
    let unmetConditions: [String]
}

enum PromptError: Error {
    case invalidPrompt(String)
    case parsingFailed(String)
    case validationFailed(String)
    case executionFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidPrompt(let message): return "Invalid prompt: \(message)"
        case .parsingFailed(let message): return "Parsing failed: \(message)"
        case .validationFailed(let message): return "Validation failed: \(message)"
        case .executionFailed(let message): return "Execution failed: \(message)"
        }
    }
}

// MARK: - Dummy Implementations (Will be implemented in separate files)

// Mock classes have been moved to their respective files

// Temporary AIDecisionEngine placeholder
class AIDecisionEngine {
    func makeDecision(prompt: String, context: TradingContext, marketData: [String: Any]) async throws -> (tradeDecision: AITradeDecision?, reasoning: String) {
        return (nil, "Analysis pending")
    }
}

struct TradeResult {
    let positionId: String?
    let success: Bool
    let error: String?
}