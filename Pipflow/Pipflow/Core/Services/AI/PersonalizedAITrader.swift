//
//  PersonalizedAITrader.swift
//  Pipflow
//
//  Individual AI trading instances with personalized decision making
//

import Foundation
import Combine

// MARK: - AI Decision Models

struct AIDecisionRequest {
    let prompt: String
    let context: TradingContext
    let marketData: [String: Any]
    let currentPositions: [TrackedPosition]
    let recentTrades: [AITradeHistory]
    let timestamp: Date
}

struct AIDecisionResponse {
    let tradeDecision: AITradeDecision?
    let reasoning: String
    let confidence: Double
    let alternativeOptions: [AITradeDecision]
    let marketAnalysis: MarketAnalysis
    let riskAssessment: RiskAssessment
    let timestamp: Date
}

struct MarketAnalysis {
    let trend: TrendDirection
    let momentum: MomentumStrength
    let volatility: VolatilityLevel
    let support: Double?
    let resistance: Double?
    let keyLevels: [PriceLevel]
    let sentiment: MarketSentiment
    
    enum TrendDirection: String, CaseIterable {
        case bullish = "Bullish"
        case bearish = "Bearish"
        case sideways = "Sideways"
        case uncertain = "Uncertain"
    }
    
    enum MomentumStrength: String, CaseIterable {
        case strong = "Strong"
        case moderate = "Moderate"
        case weak = "Weak"
    }
    
    enum VolatilityLevel: String, CaseIterable {
        case low = "Low"
        case normal = "Normal"
        case high = "High"
        case extreme = "Extreme"
    }
    
    enum MarketSentiment: String, CaseIterable {
        case bullish = "Bullish"
        case bearish = "Bearish"
        case neutral = "Neutral"
        case fearful = "Fearful"
        case greedy = "Greedy"
    }
}

struct RiskAssessment {
    let overallRisk: RiskLevel
    let positionRisk: Double
    let portfolioRisk: Double
    let correlationRisk: Double
    let marketRisk: Double
    let recommendations: [String]
    
    enum RiskLevel: String, CaseIterable {
        case veryLow = "Very Low"
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case veryHigh = "Very High"
    }
}

struct PriceLevel {
    let price: Double
    let type: LevelType
    let strength: Double // 0.0 to 1.0
    let timeframe: String
    
    enum LevelType: String, CaseIterable {
        case support = "Support"
        case resistance = "Resistance"
        case pivot = "Pivot"
        case fibonacci = "Fibonacci"
    }
}

struct AITradeHistory {
    let id: String
    let symbol: String
    let side: TradeSide
    let entryPrice: Double
    let exitPrice: Double?
    let volume: Double
    let entryTime: Date
    let exitTime: Date?
    let profitLoss: Double
    let reasoning: String
    let confidence: Double
    let outcome: TradeOutcome
    
    enum TradeOutcome: String, CaseIterable {
        case pending = "Pending"
        case winning = "Winning"
        case losing = "Losing"
        case breakeven = "Break Even"
        case stopped = "Stopped Out"
    }
}

// MARK: - Personalized AI Trader

@MainActor
class PersonalizedAITrader: ObservableObject {
    private let userId: String
    private let aiService: AIService
    private let marketAnalyzer: MarketAnalyzer
    private let riskAnalyzer: RiskAnalyzer
    private let patternRecognizer: PatternRecognizer
    private let learningEngine: LearningEngine
    
    @Published var isProcessing: Bool = false
    @Published var lastDecision: AIDecisionResponse?
    @Published var decisionHistory: [AIDecisionResponse] = []
    @Published var performanceMetrics: AIPerformanceMetrics = AIPerformanceMetrics()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(userId: String) {
        self.userId = userId
        self.aiService = AIService()
        self.marketAnalyzer = MarketAnalyzer()
        self.riskAnalyzer = RiskAnalyzer()
        self.patternRecognizer = PatternRecognizer()
        self.learningEngine = LearningEngine(userId: userId)
        
        setupLearningFeedback()
    }
    
    // MARK: - Main Decision Making
    
    func makeDecision(
        prompt: String,
        context: TradingContext,
        marketData: [String: Any]
    ) async throws -> AIDecisionResponse {
        
        isProcessing = true
        defer { isProcessing = false }
        
        let request = AIDecisionRequest(
            prompt: prompt,
            context: context,
            marketData: marketData,
            currentPositions: getCurrentPositions(),
            recentTrades: getRecentTrades(),
            timestamp: Date()
        )
        
        // Analyze market conditions
        let marketAnalysis = await analyzeMarket(request)
        
        // Assess risk
        let riskAssessment = await assessRisk(request, marketAnalysis: marketAnalysis)
        
        // Generate trading decision using AI
        let aiDecision = try await generateAIDecision(request, marketAnalysis: marketAnalysis, riskAssessment: riskAssessment)
        
        let response = AIDecisionResponse(
            tradeDecision: aiDecision.primaryDecision,
            reasoning: aiDecision.reasoning,
            confidence: aiDecision.confidence,
            alternativeOptions: aiDecision.alternatives,
            marketAnalysis: marketAnalysis,
            riskAssessment: riskAssessment,
            timestamp: Date()
        )
        
        // Store decision for learning
        await learningEngine.recordDecision(request, response: response)
        
        // Update tracking
        lastDecision = response
        decisionHistory.append(response)
        
        // Keep only last 100 decisions
        if decisionHistory.count > 100 {
            decisionHistory = Array(decisionHistory.suffix(100))
        }
        
        return response
    }
    
    // MARK: - Market Analysis
    
    private func analyzeMarket(_ request: AIDecisionRequest) async -> MarketAnalysis {
        let symbols = request.context.allowedSymbols.isEmpty ? ["EURUSD"] : request.context.allowedSymbols
        
        var combinedAnalysis = MarketAnalysis(
            trend: .uncertain,
            momentum: .weak,
            volatility: .normal,
            support: nil,
            resistance: nil,
            keyLevels: [],
            sentiment: .neutral
        )
        
        for symbol in symbols {
            let analysis = await marketAnalyzer.analyzeSymbol(symbol, with: request.context.indicators)
            combinedAnalysis = combineAnalysis(combinedAnalysis, with: analysis)
        }
        
        return combinedAnalysis
    }
    
    private func combineAnalysis(_ existing: MarketAnalysis, with new: MarketAnalysis) -> MarketAnalysis {
        // Combine multiple symbol analyses
        return MarketAnalysis(
            trend: combineTrends(existing.trend, new.trend),
            momentum: combineMomentum(existing.momentum, new.momentum),
            volatility: combineVolatility(existing.volatility, new.volatility),
            support: existing.support ?? new.support,
            resistance: existing.resistance ?? new.resistance,
            keyLevels: existing.keyLevels + new.keyLevels,
            sentiment: combineSentiment(existing.sentiment, new.sentiment)
        )
    }
    
    // MARK: - Risk Assessment
    
    private func assessRisk(_ request: AIDecisionRequest, marketAnalysis: MarketAnalysis) async -> RiskAssessment {
        let positionRisk = riskAnalyzer.calculatePositionRisk(request.context)
        let portfolioRisk = riskAnalyzer.calculatePortfolioRisk(request.currentPositions)
        let correlationRisk = riskAnalyzer.calculateCorrelationRisk(request.context.allowedSymbols)
        let marketRisk = riskAnalyzer.calculateMarketRisk(marketAnalysis)
        
        let overallRisk = determineOverallRisk(
            position: positionRisk,
            portfolio: portfolioRisk,
            correlation: correlationRisk,
            market: marketRisk
        )
        
        let recommendations = generateRiskRecommendations(
            overallRisk: overallRisk,
            context: request.context,
            marketAnalysis: marketAnalysis
        )
        
        return RiskAssessment(
            overallRisk: overallRisk,
            positionRisk: positionRisk,
            portfolioRisk: portfolioRisk,
            correlationRisk: correlationRisk,
            marketRisk: marketRisk,
            recommendations: recommendations
        )
    }
    
    // MARK: - AI Decision Generation
    
    private func generateAIDecision(
        _ request: AIDecisionRequest,
        marketAnalysis: MarketAnalysis,
        riskAssessment: RiskAssessment
    ) async throws -> (primaryDecision: AITradeDecision?, reasoning: String, confidence: Double, alternatives: [AITradeDecision]) {
        
        // Create enhanced prompt for AI service
        let enhancedPrompt = buildEnhancedPrompt(
            originalPrompt: request.prompt,
            context: request.context,
            marketAnalysis: marketAnalysis,
            riskAssessment: riskAssessment,
            recentTrades: request.recentTrades
        )
        
        // Get AI analysis
        let aiResponse = try await aiService.analyzeAndDecide(
            prompt: enhancedPrompt,
            marketData: request.marketData,
            context: request.context
        )
        
        // Apply learning adjustments
        let adjustedDecision = await learningEngine.adjustDecision(aiResponse.decision, based: request)
        
        // Generate alternatives
        let alternatives = await generateAlternativeDecisions(
            primary: adjustedDecision,
            request: request,
            marketAnalysis: marketAnalysis
        )
        
        return (
            primaryDecision: adjustedDecision,
            reasoning: aiResponse.reasoning,
            confidence: aiResponse.confidence,
            alternatives: alternatives
        )
    }
    
    private func buildEnhancedPrompt(
        originalPrompt: String,
        context: TradingContext,
        marketAnalysis: MarketAnalysis,
        riskAssessment: RiskAssessment,
        recentTrades: [AITradeHistory]
    ) -> String {
        
        var enhancedPrompt = """
        Original Trading Instructions: \(originalPrompt)
        
        Current Market Analysis:
        - Trend: \(marketAnalysis.trend.rawValue)
        - Momentum: \(marketAnalysis.momentum.rawValue)
        - Volatility: \(marketAnalysis.volatility.rawValue)
        - Sentiment: \(marketAnalysis.sentiment.rawValue)
        """
        
        if let support = marketAnalysis.support {
            enhancedPrompt += "\n- Support Level: \(support)"
        }
        
        if let resistance = marketAnalysis.resistance {
            enhancedPrompt += "\n- Resistance Level: \(resistance)"
        }
        
        enhancedPrompt += """
        
        Risk Assessment:
        - Overall Risk: \(riskAssessment.overallRisk.rawValue)
        - Position Risk: \(String(format: "%.2f", riskAssessment.positionRisk))%
        - Portfolio Risk: \(String(format: "%.2f", riskAssessment.portfolioRisk))%
        
        Trading Context:
        - Capital: $\(context.capital)
        - Risk per Trade: \(String(format: "%.1f", context.riskPerTrade * 100))%
        - Max Open Trades: \(context.maxOpenTrades)
        """
        
        if !recentTrades.isEmpty {
            enhancedPrompt += "\n\nRecent Trading Performance:"
            let recentPerformance = recentTrades.prefix(5)
            for trade in recentPerformance {
                let outcome = trade.outcome.rawValue
                let pl = trade.profitLoss >= 0 ? "+$\(trade.profitLoss)" : "-$\(abs(trade.profitLoss))"
                enhancedPrompt += "\n- \(trade.symbol) \(trade.side.rawValue): \(outcome) (\(pl))"
            }
        }
        
        enhancedPrompt += """
        
        Instructions:
        1. Analyze if current market conditions align with the user's trading strategy
        2. Consider recent performance and adjust approach if needed
        3. Only recommend trades with high probability of success (>60% confidence)
        4. Respect the user's risk parameters strictly
        5. Provide clear reasoning for your decision
        6. If conditions aren't met, recommend waiting for better opportunities
        
        Respond with a specific trade recommendation (BUY/SELL/WAIT) including entry price, stop loss, take profit, and detailed reasoning.
        """
        
        return enhancedPrompt
    }
    
    // MARK: - Alternative Decisions
    
    private func generateAlternativeDecisions(
        primary: AITradeDecision?,
        request: AIDecisionRequest,
        marketAnalysis: MarketAnalysis
    ) async -> [AITradeDecision] {
        
        guard let primary = primary else { return [] }
        
        var alternatives: [AITradeDecision] = []
        
        // Generate conservative alternative
        if let conservative = generateConservativeAlternative(primary: primary, request: request) {
            alternatives.append(conservative)
        }
        
        // Generate aggressive alternative
        if let aggressive = generateAggressiveAlternative(primary: primary, request: request) {
            alternatives.append(aggressive)
        }
        
        // Generate different timeframe alternative
        if let timeframeAlt = generateTimeframeAlternative(primary: primary, marketAnalysis: marketAnalysis) {
            alternatives.append(timeframeAlt)
        }
        
        return alternatives
    }
    
    // MARK: - Learning & Adaptation
    
    private func setupLearningFeedback() {
        // Monitor trade outcomes and feed back to learning engine
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.updateLearningFromOutcomes() }
            }
            .store(in: &cancellables)
    }
    
    private func updateLearningFromOutcomes() async {
        // This would analyze completed trades and update the learning engine
        let completedTrades = getRecentTrades().filter { $0.exitTime != nil }
        await learningEngine.updateFromOutcomes(completedTrades)
        
        // Update performance metrics
        updatePerformanceMetrics(from: completedTrades)
    }
    
    private func updatePerformanceMetrics(from trades: [AITradeHistory]) {
        guard !trades.isEmpty else { return }
        
        let totalTrades = trades.count
        let winningTrades = trades.filter { $0.profitLoss > 0 }.count
        let totalPL = trades.reduce(0) { $0 + $1.profitLoss }
        let avgConfidence = trades.reduce(0) { $0 + $1.confidence } / Double(totalTrades)
        
        performanceMetrics = AIPerformanceMetrics(
            totalDecisions: decisionHistory.count,
            executedTrades: totalTrades,
            winRate: Double(winningTrades) / Double(totalTrades),
            totalProfitLoss: totalPL,
            averageConfidence: avgConfidence,
            learningProgress: learningEngine.getLearningProgress()
        )
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentPositions() -> [TrackedPosition] {
        return PositionTrackingService.shared.trackedPositions
    }
    
    private func getRecentTrades() -> [AITradeHistory] {
        // This would retrieve recent AI trade history
        // For now, return empty array as it would be populated from actual trading history
        return []
    }
    
    private func combineTrends(_ trend1: MarketAnalysis.TrendDirection, _ trend2: MarketAnalysis.TrendDirection) -> MarketAnalysis.TrendDirection {
        if trend1 == trend2 { return trend1 }
        return .uncertain
    }
    
    private func combineMomentum(_ momentum1: MarketAnalysis.MomentumStrength, _ momentum2: MarketAnalysis.MomentumStrength) -> MarketAnalysis.MomentumStrength {
        let values = [momentum1, momentum2]
        if values.contains(.strong) { return .strong }
        if values.contains(.moderate) { return .moderate }
        return .weak
    }
    
    private func combineVolatility(_ vol1: MarketAnalysis.VolatilityLevel, _ vol2: MarketAnalysis.VolatilityLevel) -> MarketAnalysis.VolatilityLevel {
        let values = [vol1, vol2]
        if values.contains(.extreme) { return .extreme }
        if values.contains(.high) { return .high }
        if values.contains(.normal) { return .normal }
        return .low
    }
    
    private func combineSentiment(_ sentiment1: MarketAnalysis.MarketSentiment, _ sentiment2: MarketAnalysis.MarketSentiment) -> MarketAnalysis.MarketSentiment {
        if sentiment1 == sentiment2 { return sentiment1 }
        return .neutral
    }
    
    private func determineOverallRisk(position: Double, portfolio: Double, correlation: Double, market: Double) -> RiskAssessment.RiskLevel {
        let avgRisk = (position + portfolio + correlation + market) / 4.0
        
        if avgRisk < 0.2 { return .veryLow }
        else if avgRisk < 0.4 { return .low }
        else if avgRisk < 0.6 { return .moderate }
        else if avgRisk < 0.8 { return .high }
        else { return .veryHigh }
    }
    
    private func generateRiskRecommendations(overallRisk: RiskAssessment.RiskLevel, context: TradingContext, marketAnalysis: MarketAnalysis) -> [String] {
        var recommendations: [String] = []
        
        switch overallRisk {
        case .veryHigh, .high:
            recommendations.append("Consider reducing position size")
            recommendations.append("Tighten stop losses")
            if context.maxOpenTrades > 3 {
                recommendations.append("Limit open positions to 3 or fewer")
            }
        case .moderate:
            recommendations.append("Current risk level is acceptable")
            recommendations.append("Monitor positions closely")
        case .low, .veryLow:
            recommendations.append("Risk level is conservative")
            if marketAnalysis.volatility == .low {
                recommendations.append("Consider slightly larger positions in low volatility environment")
            }
        }
        
        return recommendations
    }
    
    private func generateConservativeAlternative(primary: AITradeDecision, request: AIDecisionRequest) -> AITradeDecision? {
        // Create a more conservative version with smaller position and tighter stops
        return AITradeDecision(
            symbol: primary.symbol,
            side: primary.side,
            entryPrice: primary.entryPrice,
            stopLoss: primary.stopLoss,
            takeProfit: primary.takeProfit,
            confidence: primary.confidence * 0.9,
            reasoning: "Conservative alternative: " + primary.reasoning
        )
    }
    
    private func generateAggressiveAlternative(primary: AITradeDecision, request: AIDecisionRequest) -> AITradeDecision? {
        // Create a more aggressive version with larger position and wider targets
        return AITradeDecision(
            symbol: primary.symbol,
            side: primary.side,
            entryPrice: primary.entryPrice,
            stopLoss: primary.stopLoss,
            takeProfit: primary.takeProfit,
            confidence: primary.confidence * 0.8,
            reasoning: "Aggressive alternative: " + primary.reasoning
        )
    }
    
    private func generateTimeframeAlternative(primary: AITradeDecision, marketAnalysis: MarketAnalysis) -> AITradeDecision? {
        // Generate alternative for different timeframe
        return nil // Implementation would depend on specific timeframe analysis
    }
}

// MARK: - Supporting Models

struct AIPerformanceMetrics {
    var totalDecisions: Int = 0
    var executedTrades: Int = 0
    var winRate: Double = 0.0
    var totalProfitLoss: Double = 0.0
    var averageConfidence: Double = 0.0
    var learningProgress: Double = 0.0
    
    var formattedWinRate: String {
        String(format: "%.1f%%", winRate * 100)
    }
    
    var formattedProfitLoss: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalProfitLoss)) ?? "$0.00"
    }
}

// MARK: - Service Implementations (Stubs)

// These would be implemented as separate services
class AIService {
    func analyzeAndDecide(prompt: String, marketData: [String: Any], context: TradingContext) async throws -> (decision: AITradeDecision?, reasoning: String, confidence: Double) {
        // This would integrate with OpenAI/Claude API
        return (nil, "Analysis pending", 0.5)
    }
}

class MarketAnalyzer {
    func analyzeSymbol(_ symbol: String, with indicators: [TechnicalIndicator]) async -> MarketAnalysis {
        // This would perform technical analysis
        return MarketAnalysis(
            trend: .uncertain,
            momentum: .weak,
            volatility: .normal,
            support: nil,
            resistance: nil,
            keyLevels: [],
            sentiment: .neutral
        )
    }
}

class RiskAnalyzer {
    func calculatePositionRisk(_ context: TradingContext) -> Double { return 0.02 }
    func calculatePortfolioRisk(_ positions: [TrackedPosition]) -> Double { return 0.05 }
    func calculateCorrelationRisk(_ symbols: [String]) -> Double { return 0.03 }
    func calculateMarketRisk(_ analysis: MarketAnalysis) -> Double { return 0.04 }
}

class PatternRecognizer {
    func recognizePatterns(in marketData: [String: Any]) async -> [String] {
        return []
    }
}

class LearningEngine {
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    func recordDecision(_ request: AIDecisionRequest, response: AIDecisionResponse) async {}
    func adjustDecision(_ decision: AITradeDecision?, based request: AIDecisionRequest) async -> AITradeDecision? { return decision }
    func updateFromOutcomes(_ trades: [AITradeHistory]) async {}
    func getLearningProgress() -> Double { return 0.0 }
}