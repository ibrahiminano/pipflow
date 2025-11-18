//
//  MarketRegimeDetector.swift
//  Pipflow
//
//  AI-powered market regime detection and adaptation
//

import Foundation
import SwiftUI

// MARK: - Market Regime Models

enum MarketRegime: String, CaseIterable {
    case trending = "Trending"
    case ranging = "Ranging"
    case volatile = "Volatile"
    case breakout = "Breakout"
    case reversal = "Reversal"
    case lowVolatility = "Low Volatility"
    
    var color: Color {
        switch self {
        case .trending: return .green
        case .ranging: return .blue
        case .volatile: return .red
        case .breakout: return .orange
        case .reversal: return .purple
        case .lowVolatility: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .trending: return "arrow.up.right"
        case .ranging: return "arrow.left.and.right"
        case .volatile: return "waveform.path.ecg"
        case .breakout: return "bolt"
        case .reversal: return "arrow.uturn.down"
        case .lowVolatility: return "minus"
        }
    }
    
    var description: String {
        switch self {
        case .trending:
            return "Strong directional movement with clear trend"
        case .ranging:
            return "Price oscillating between support and resistance"
        case .volatile:
            return "High volatility with unpredictable movements"
        case .breakout:
            return "Breaking key levels with momentum"
        case .reversal:
            return "Potential trend reversal in progress"
        case .lowVolatility:
            return "Calm market with minimal movement"
        }
    }
}

struct MarketRegimeAnalysis: Identifiable {
    let id = UUID()
    let timestamp: Date
    let symbol: String
    let currentRegime: MarketRegime
    let confidence: Double
    let regimeStrength: Double
    let timeInRegime: TimeInterval
    let regimeTransitions: [RegimeTransition]
    let indicators: RegimeIndicators
    let predictions: RegimePredictions
    let adaptedStrategies: [AdaptedStrategy]
}

struct RegimeTransition: Identifiable, Equatable {
    let id = UUID()
    let fromRegime: MarketRegime
    let toRegime: MarketRegime
    let timestamp: Date
    let probability: Double
}

struct RegimeIndicators {
    let trendStrength: Double
    let volatility: Double
    let momentum: Double
    let volume: Double
    let priceAction: PriceActionMetrics
    let marketStructure: MarketStructure
}

struct PriceActionMetrics {
    let averageTrueRange: Double
    let priceVelocity: Double
    let candlePatterns: [CandlePattern]
    let supportResistance: [RegimePriceLevel]
}

struct MarketStructure {
    let higherHighs: Int
    let lowerLows: Int
    let swingPoints: [SwingPoint]
    let trendlineBreaks: Int
}

struct RegimePredictions {
    let nextRegime: MarketRegime
    let transitionProbability: Double
    let timeToTransition: TimeInterval
    let confidenceInterval: (lower: Double, upper: Double)
}

struct AdaptedStrategy {
    let strategyName: String
    let originalSettings: StrategySettings
    let adaptedSettings: StrategySettings
    let expectedImprovement: Double
    let riskAdjustment: Double
}

struct StrategySettings {
    let entryThreshold: Double
    let exitThreshold: Double
    let stopLoss: Double
    let takeProfit: Double
    let positionSize: Double
    let indicators: [String: Double]
}

struct CandlePattern: Identifiable {
    let id = UUID()
    let name: String
    let type: PatternType
    let reliability: Double
    let timestamp: Date
    
    enum PatternType {
        case bullish
        case bearish
        case neutral
    }
}

struct RegimePriceLevel: Identifiable {
    let id = UUID()
    let price: Double
    let type: LevelType
    let strength: Double
    let touches: Int
    
    enum LevelType {
        case support
        case resistance
    }
}

struct SwingPoint: Identifiable {
    let id = UUID()
    let price: Double
    let timestamp: Date
    let type: SwingType
    
    enum SwingType {
        case high
        case low
    }
}

// MARK: - Market Regime Detector

@MainActor
class MarketRegimeDetector: ObservableObject {
    static let shared = MarketRegimeDetector()
    
    @Published var currentRegimes: [String: MarketRegimeAnalysis] = [:]
    @Published var regimeHistory: [MarketRegimeAnalysis] = []
    @Published var isAnalyzing = false
    @Published var detectionAccuracy: Double = 0
    
    private let dataService = MarketDataService.shared
    private let aiService = AISignalService.shared
    private var monitoringTimer: Timer?
    private var regimeCache: [String: [RegimeDataPoint]] = [:]
    
    struct RegimeDataPoint {
        let timestamp: Date
        let regime: MarketRegime
        let confidence: Double
        let indicators: RegimeIndicators
    }
    
    // MARK: - Public Methods
    
    func detectMarketRegime(for symbol: String) async throws -> MarketRegimeAnalysis {
        isAnalyzing = true
        
        do {
            // 1. Fetch market data
            let marketData = try await fetchMarketData(symbol: symbol)
            
            // 2. Calculate regime indicators
            let indicators = calculateRegimeIndicators(data: marketData)
            
            // 3. Detect current regime
            let (regime, confidence) = detectRegime(indicators: indicators)
            
            // 4. Analyze regime transitions
            let transitions = analyzeRegimeTransitions(
                symbol: symbol,
                currentRegime: regime,
                indicators: indicators
            )
            
            // 5. Generate predictions
            let predictions = generateRegimePredictions(
                currentRegime: regime,
                indicators: indicators,
                history: regimeCache[symbol] ?? []
            )
            
            // 6. Adapt trading strategies
            let adaptedStrategies = adaptStrategiesForRegime(
                regime: regime,
                indicators: indicators
            )
            
            // 7. Calculate time in regime
            let timeInRegime = calculateTimeInRegime(
                symbol: symbol,
                currentRegime: regime
            )
            
            let analysis = MarketRegimeAnalysis(
                timestamp: Date(),
                symbol: symbol,
                currentRegime: regime,
                confidence: confidence,
                regimeStrength: calculateRegimeStrength(regime: regime, indicators: indicators),
                timeInRegime: timeInRegime,
                regimeTransitions: transitions,
                indicators: indicators,
                predictions: predictions,
                adaptedStrategies: adaptedStrategies
            )
            
            // Update cache
            updateRegimeCache(symbol: symbol, analysis: analysis)
            
            currentRegimes[symbol] = analysis
            regimeHistory.append(analysis)
            
            isAnalyzing = false
            return analysis
            
        } catch {
            isAnalyzing = false
            throw error
        }
    }
    
    func startRealtimeDetection(symbols: [String]) {
        stopRealtimeDetection()
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.performRealtimeDetection(symbols: symbols)
            }
        }
    }
    
    func stopRealtimeDetection() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    func getOptimalStrategyForRegime(_ regime: MarketRegime) -> TradingStrategy {
        switch regime {
        case .trending:
            return createTrendFollowingStrategy()
        case .ranging:
            return createRangeStrategy()
        case .volatile:
            return createVolatilityStrategy()
        case .breakout:
            return createBreakoutStrategy()
        case .reversal:
            return createReversalStrategy()
        case .lowVolatility:
            return createScalpingStrategy()
        }
    }
    
    // MARK: - Computed Properties
    
    var currentRegime: MarketRegimeAnalysis {
        // Return the most recent regime analysis or a default
        if let firstSymbol = currentRegimes.keys.first,
           let regime = currentRegimes[firstSymbol] {
            return regime
        }
        
        // Return default regime analysis
        return MarketRegimeAnalysis(
            timestamp: Date(),
            symbol: "DEFAULT",
            currentRegime: .ranging,
            confidence: 0.5,
            regimeStrength: 0.5,
            timeInRegime: 0,
            regimeTransitions: [],
            indicators: RegimeIndicators(
                trendStrength: 0.5,
                volatility: 0.01,
                momentum: 0,
                volume: 0,
                priceAction: PriceActionMetrics(
                    averageTrueRange: 0.01,
                    priceVelocity: 0,
                    candlePatterns: [],
                    supportResistance: []
                ),
                marketStructure: MarketStructure(
                    higherHighs: 0,
                    lowerLows: 0,
                    swingPoints: [],
                    trendlineBreaks: 0
                )
            ),
            predictions: RegimePredictions(
                nextRegime: .ranging,
                transitionProbability: 0.5,
                timeToTransition: 3600,
                confidenceInterval: (0.3, 0.7)
            ),
            adaptedStrategies: []
        )
    }
    
    // MARK: - Private Methods
    
    private func fetchMarketData(symbol: String) async throws -> RegimeMarketData {
        // Fetch market data
        _ = try await dataService.fetchMarketData(for: symbol)
        
        // Get historical candles from MetaAPI
        guard let accountId = MetaAPIService.shared.currentAccountId else {
            throw NSError(domain: "MarketRegimeDetector", code: 401, userInfo: [NSLocalizedDescriptionKey: "No MetaAPI account connected"])
        }
        
        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-100 * 3600) // 100 hours
        
        let candles = try await MetaAPIService.shared.getHistoricalCandles(
            accountId: accountId,
            symbol: symbol,
            timeframe: "1h",
            startTime: startTime,
            endTime: endTime
        )
        
        return RegimeMarketData(
            symbol: symbol,
            candles: candles,
            volume: calculateAverageVolume(candles),
            volatility: calculateVolatility(candles)
        )
    }
    
    private func calculateRegimeIndicators(data: RegimeMarketData) -> RegimeIndicators {
        let closes = data.candles.map { $0.close }
        
        // Trend Strength
        let trendStrength = calculateTrendStrength(prices: closes)
        
        // Volatility
        let volatility = calculateATR(candles: data.candles, period: 14)
        
        // Momentum
        let momentum = calculateMomentum(prices: closes, period: 10)
        
        // Price Action
        let priceAction = analyzePriceAction(candles: data.candles)
        
        // Market Structure
        let marketStructure = analyzeMarketStructure(candles: data.candles)
        
        return RegimeIndicators(
            trendStrength: trendStrength,
            volatility: volatility.last ?? 0,
            momentum: momentum,
            volume: data.volume,
            priceAction: priceAction,
            marketStructure: marketStructure
        )
    }
    
    private func detectRegime(indicators: RegimeIndicators) -> (MarketRegime, Double) {
        var scores: [MarketRegime: Double] = [:]
        
        // Trending regime detection
        if indicators.trendStrength > 0.7 && indicators.momentum > 0.5 {
            scores[.trending] = indicators.trendStrength * 0.6 + indicators.momentum * 0.4
        }
        
        // Ranging regime detection
        if indicators.trendStrength < 0.3 && indicators.priceAction.supportResistance.count >= 2 {
            scores[.ranging] = (1 - indicators.trendStrength) * 0.7 + 0.3
        }
        
        // Volatile regime detection
        if indicators.volatility > 0.02 && indicators.priceAction.averageTrueRange > 0.015 {
            scores[.volatile] = indicators.volatility * 50 * 0.8 + 0.2
        }
        
        // Breakout regime detection
        if indicators.marketStructure.trendlineBreaks > 0 || indicators.momentum > 0.8 {
            scores[.breakout] = indicators.momentum * 0.7 + 0.3
        }
        
        // Reversal regime detection
        if indicators.marketStructure.higherHighs < 0 && indicators.marketStructure.lowerLows > 2 {
            scores[.reversal] = 0.8
        }
        
        // Low volatility regime detection
        if indicators.volatility < 0.005 && indicators.trendStrength < 0.2 {
            scores[.lowVolatility] = (1 - indicators.volatility * 100) * 0.9
        }
        
        // Find regime with highest score
        let bestRegime = scores.max(by: { $0.value < $1.value })
        
        return (bestRegime?.key ?? .ranging, bestRegime?.value ?? 0.5)
    }
    
    private func analyzeRegimeTransitions(
        symbol: String,
        currentRegime: MarketRegime,
        indicators: RegimeIndicators
    ) -> [RegimeTransition] {
        var transitions: [RegimeTransition] = []
        
        // Analyze potential transitions based on indicators
        for targetRegime in MarketRegime.allCases {
            if targetRegime != currentRegime {
                let probability = calculateTransitionProbability(
                    from: currentRegime,
                    to: targetRegime,
                    indicators: indicators
                )
                
                if probability > 0.2 {
                    transitions.append(RegimeTransition(
                        fromRegime: currentRegime,
                        toRegime: targetRegime,
                        timestamp: Date(),
                        probability: probability
                    ))
                }
            }
        }
        
        return transitions.sorted { $0.probability > $1.probability }
    }
    
    private func calculateTransitionProbability(
        from: MarketRegime,
        to: MarketRegime,
        indicators: RegimeIndicators
    ) -> Double {
        // Simplified transition probability based on indicators
        switch (from, to) {
        case (.trending, .ranging):
            return indicators.trendStrength < 0.4 ? 0.6 : 0.2
        case (.ranging, .breakout):
            return indicators.momentum > 0.6 ? 0.7 : 0.3
        case (.ranging, .trending):
            return indicators.trendStrength > 0.5 ? 0.5 : 0.2
        case (.volatile, .trending):
            return indicators.volatility < 0.01 ? 0.4 : 0.1
        case (.trending, .reversal):
            return indicators.marketStructure.higherHighs < 0 ? 0.5 : 0.1
        default:
            return 0.3
        }
    }
    
    private func generateRegimePredictions(
        currentRegime: MarketRegime,
        indicators: RegimeIndicators,
        history: [RegimeDataPoint]
    ) -> RegimePredictions {
        // Analyze historical patterns
        let avgRegimeDuration = calculateAverageRegimeDuration(regime: currentRegime, history: history)
        
        // Predict next regime based on patterns
        let transitions = analyzeHistoricalTransitions(from: currentRegime, history: history)
        let mostLikelyNext = transitions.max(by: { $0.value < $1.value })
        
        return RegimePredictions(
            nextRegime: mostLikelyNext?.key ?? .ranging,
            transitionProbability: mostLikelyNext?.value ?? 0.5,
            timeToTransition: avgRegimeDuration,
            confidenceInterval: (0.3, 0.8)
        )
    }
    
    private func adaptStrategiesForRegime(
        regime: MarketRegime,
        indicators: RegimeIndicators
    ) -> [AdaptedStrategy] {
        var adaptedStrategies: [AdaptedStrategy] = []
        
        // Base strategy settings
        let baseSettings = StrategySettings(
            entryThreshold: 0.5,
            exitThreshold: 0.3,
            stopLoss: 0.01,
            takeProfit: 0.02,
            positionSize: 0.02,
            indicators: ["RSI": 50, "MA": 20]
        )
        
        // Adapt for different regimes
        switch regime {
        case .trending:
            let adapted = StrategySettings(
                entryThreshold: 0.3, // Lower threshold for trend entries
                exitThreshold: 0.6, // Higher threshold to ride trends
                stopLoss: 0.015, // Wider stops
                takeProfit: 0.04, // Larger targets
                positionSize: 0.03, // Larger positions in trends
                indicators: ["RSI": 40, "MA": 50]
            )
            
            adaptedStrategies.append(AdaptedStrategy(
                strategyName: "Trend Following",
                originalSettings: baseSettings,
                adaptedSettings: adapted,
                expectedImprovement: 0.25,
                riskAdjustment: 1.2
            ))
            
        case .ranging:
            let adapted = StrategySettings(
                entryThreshold: 0.7, // Higher threshold for range trades
                exitThreshold: 0.2, // Quick exits
                stopLoss: 0.005, // Tight stops
                takeProfit: 0.01, // Small targets
                positionSize: 0.015, // Smaller positions
                indicators: ["RSI": 30, "BB": 20]
            )
            
            adaptedStrategies.append(AdaptedStrategy(
                strategyName: "Range Trading",
                originalSettings: baseSettings,
                adaptedSettings: adapted,
                expectedImprovement: 0.15,
                riskAdjustment: 0.8
            ))
            
        case .volatile:
            let adapted = StrategySettings(
                entryThreshold: 0.8, // Very selective entries
                exitThreshold: 0.1, // Quick exits
                stopLoss: 0.02, // Wide stops for volatility
                takeProfit: 0.03, // Decent targets
                positionSize: 0.01, // Small positions
                indicators: ["ATR": 14, "VOL": 20]
            )
            
            adaptedStrategies.append(AdaptedStrategy(
                strategyName: "Volatility Trading",
                originalSettings: baseSettings,
                adaptedSettings: adapted,
                expectedImprovement: 0.1,
                riskAdjustment: 0.5
            ))
            
        default:
            adaptedStrategies.append(AdaptedStrategy(
                strategyName: "Default",
                originalSettings: baseSettings,
                adaptedSettings: baseSettings,
                expectedImprovement: 0,
                riskAdjustment: 1.0
            ))
        }
        
        return adaptedStrategies
    }
    
    // MARK: - Helper Methods
    
    private func calculateTrendStrength(prices: [Double]) -> Double {
        guard prices.count > 20 else { return 0 }
        
        // Linear regression
        let n = Double(prices.count)
        let xValues = Array(0..<prices.count).map { Double($0) }
        
        let sumX = xValues.reduce(0, +)
        let sumY = prices.reduce(0, +)
        let sumXY = zip(xValues, prices).map(*).reduce(0, +)
        let sumXX = xValues.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        // R-squared
        let yMean = sumY / n
        let ssTotal = prices.map { pow($0 - yMean, 2) }.reduce(0, +)
        let ssResidual: Double = zip(xValues, prices).map { x, y in
            let predicted = slope * x + intercept
            return pow(y - predicted, 2)
        }.reduce(0) { $0 + $1 }
        
        let rSquared = 1 - (ssResidual / ssTotal)
        
        // Combine slope and R-squared for trend strength
        let normalizedSlope = tanh(slope * 1000) // Normalize slope
        return abs(normalizedSlope) * rSquared
    }
    
    private func calculateATR(candles: [Candle], period: Int) -> [Double] {
        var atr: [Double] = []
        var tr: [Double] = []
        
        for i in 0..<candles.count {
            if i == 0 {
                tr.append(candles[i].high - candles[i].low)
            } else {
                let highLow = candles[i].high - candles[i].low
                let highPrevClose = abs(candles[i].high - candles[i-1].close)
                let lowPrevClose = abs(candles[i].low - candles[i-1].close)
                tr.append(max(highLow, max(highPrevClose, lowPrevClose)))
            }
            
            if i >= period - 1 {
                let avgTR = tr.suffix(period).reduce(0, +) / Double(period)
                atr.append(avgTR)
            } else {
                atr.append(tr[i])
            }
        }
        
        return atr
    }
    
    private func calculateMomentum(prices: [Double], period: Int) -> Double {
        guard prices.count > period else { return 0 }
        
        let recentPrice = prices.last!
        let pastPrice = prices[prices.count - period - 1]
        
        return (recentPrice - pastPrice) / pastPrice
    }
    
    private func analyzePriceAction(candles: [Candle]) -> PriceActionMetrics {
        let atr = calculateATR(candles: candles, period: 14).last ?? 0
        
        // Price velocity
        let priceChanges = zip(candles.dropFirst(), candles).map { $0.close - $1.close }
        let velocity = priceChanges.reduce(0, +) / Double(priceChanges.count)
        
        // Identify candle patterns
        let patterns = identifyCandlePatterns(candles: Array(candles.suffix(10)))
        
        // Find support/resistance levels
        let levels = findSupportResistanceLevels(candles: candles)
        
        return PriceActionMetrics(
            averageTrueRange: atr,
            priceVelocity: velocity,
            candlePatterns: patterns,
            supportResistance: levels
        )
    }
    
    private func analyzeMarketStructure(candles: [Candle]) -> MarketStructure {
        let swings = findSwingPoints(candles: candles)
        
        var higherHighs = 0
        var lowerLows = 0
        
        let highSwings = swings.filter { $0.type == .high }
        let lowSwings = swings.filter { $0.type == .low }
        
        // Count higher highs
        for i in 1..<highSwings.count {
            if highSwings[i].price > highSwings[i-1].price {
                higherHighs += 1
            }
        }
        
        // Count lower lows
        for i in 1..<lowSwings.count {
            if lowSwings[i].price < lowSwings[i-1].price {
                lowerLows += 1
            }
        }
        
        return MarketStructure(
            higherHighs: higherHighs,
            lowerLows: lowerLows,
            swingPoints: swings,
            trendlineBreaks: 0 // Simplified
        )
    }
    
    private func identifyCandlePatterns(candles: [Candle]) -> [CandlePattern] {
        var patterns: [CandlePattern] = []
        
        guard candles.count >= 3 else { return patterns }
        
        // Doji pattern
        let lastCandle = candles.last!
        let bodySize = abs(lastCandle.close - lastCandle.open)
        let range = lastCandle.high - lastCandle.low
        
        if bodySize < range * 0.1 {
            patterns.append(CandlePattern(
                name: "Doji",
                type: .neutral,
                reliability: 0.7,
                timestamp: Date()
            ))
        }
        
        // Hammer pattern
        if candles.count >= 2 {
            let prevCandle = candles[candles.count - 2]
            if lastCandle.close > lastCandle.open && // Bullish
               (lastCandle.low - min(lastCandle.open, lastCandle.close)) > bodySize * 2 && // Long lower wick
               prevCandle.close < prevCandle.open { // Previous was bearish
                patterns.append(CandlePattern(
                    name: "Hammer",
                    type: .bullish,
                    reliability: 0.8,
                    timestamp: Date()
                ))
            }
        }
        
        // Engulfing pattern
        if candles.count >= 2 {
            let prevCandle = candles[candles.count - 2]
            if lastCandle.close > lastCandle.open && // Current bullish
               prevCandle.close < prevCandle.open && // Previous bearish
               lastCandle.open < prevCandle.close && // Opens below previous close
               lastCandle.close > prevCandle.open { // Closes above previous open
                patterns.append(CandlePattern(
                    name: "Bullish Engulfing",
                    type: .bullish,
                    reliability: 0.85,
                    timestamp: Date()
                ))
            }
        }
        
        return patterns
    }
    
    private func findSupportResistanceLevels(candles: [Candle]) -> [RegimePriceLevel] {
        var levels: [RegimePriceLevel] = []
        let pricePoints = candles.flatMap { [$0.high, $0.low] }
        
        // Group similar prices
        let sortedPrices = pricePoints.sorted()
        var clusters: [[Double]] = []
        var currentCluster: [Double] = []
        let threshold = 0.0010 // 10 pips
        
        for price in sortedPrices {
            if currentCluster.isEmpty {
                currentCluster.append(price)
            } else if abs(price - currentCluster.last!) < threshold {
                currentCluster.append(price)
            } else {
                if currentCluster.count >= 3 {
                    clusters.append(currentCluster)
                }
                currentCluster = [price]
            }
        }
        
        if currentCluster.count >= 3 {
            clusters.append(currentCluster)
        }
        
        // Create levels from clusters
        for cluster in clusters {
            let avgPrice = cluster.reduce(0, +) / Double(cluster.count)
            let currentPrice = candles.last?.close ?? 0
            
            levels.append(RegimePriceLevel(
                price: avgPrice,
                type: avgPrice > currentPrice ? .resistance : .support,
                strength: Double(cluster.count) / Double(pricePoints.count),
                touches: cluster.count
            ))
        }
        
        return levels.sorted { $0.strength > $1.strength }.prefix(5).map { $0 }
    }
    
    private func findSwingPoints(candles: [Candle]) -> [SwingPoint] {
        var swings: [SwingPoint] = []
        let lookback = 5
        
        for i in lookback..<(candles.count - lookback) {
            let current = candles[i]
            let leftCandles = candles[(i-lookback)..<i]
            let rightCandles = candles[(i+1)...(i+lookback)]
            
            // Check for swing high
            if leftCandles.allSatisfy({ $0.high < current.high }) &&
               rightCandles.allSatisfy({ $0.high < current.high }) {
                swings.append(SwingPoint(
                    price: current.high,
                    timestamp: Date(),
                    type: .high
                ))
            }
            
            // Check for swing low
            if leftCandles.allSatisfy({ $0.low > current.low }) &&
               rightCandles.allSatisfy({ $0.low > current.low }) {
                swings.append(SwingPoint(
                    price: current.low,
                    timestamp: Date(),
                    type: .low
                ))
            }
        }
        
        return swings
    }
    
    private func calculateAverageVolume(_ candles: [Candle]) -> Double {
        guard !candles.isEmpty else { return 0 }
        return candles.map { $0.volume }.reduce(0, +) / Double(candles.count)
    }
    
    private func calculateVolatility(_ candles: [Candle]) -> Double {
        let returns = zip(candles.dropFirst(), candles).map { log($0.close / $1.close) }
        guard !returns.isEmpty else { return 0 }
        
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0, +) / Double(returns.count)
        
        return sqrt(variance)
    }
    
    private func calculateRegimeStrength(regime: MarketRegime, indicators: RegimeIndicators) -> Double {
        switch regime {
        case .trending:
            return indicators.trendStrength
        case .ranging:
            return 1 - indicators.trendStrength
        case .volatile:
            return min(indicators.volatility * 50, 1)
        case .breakout:
            return indicators.momentum
        case .reversal:
            return Double(indicators.marketStructure.higherHighs + indicators.marketStructure.lowerLows) / 10
        case .lowVolatility:
            return 1 - min(indicators.volatility * 100, 1)
        }
    }
    
    private func calculateTimeInRegime(symbol: String, currentRegime: MarketRegime) -> TimeInterval {
        let history = regimeCache[symbol] ?? []
        
        // Find last regime change
        var timeInRegime: TimeInterval = 0
        
        for point in history.reversed() {
            if point.regime == currentRegime {
                timeInRegime = Date().timeIntervalSince(point.timestamp)
            } else {
                break
            }
        }
        
        return timeInRegime
    }
    
    private func updateRegimeCache(symbol: String, analysis: MarketRegimeAnalysis) {
        var cache = regimeCache[symbol] ?? []
        
        cache.append(RegimeDataPoint(
            timestamp: analysis.timestamp,
            regime: analysis.currentRegime,
            confidence: analysis.confidence,
            indicators: analysis.indicators
        ))
        
        // Keep last 100 data points
        if cache.count > 100 {
            cache = Array(cache.suffix(100))
        }
        
        regimeCache[symbol] = cache
    }
    
    private func calculateAverageRegimeDuration(regime: MarketRegime, history: [RegimeDataPoint]) -> TimeInterval {
        var durations: [TimeInterval] = []
        var startTime: Date?
        
        for (_, point) in history.enumerated() {
            if point.regime == regime && startTime == nil {
                startTime = point.timestamp
            } else if point.regime != regime && startTime != nil {
                let duration = point.timestamp.timeIntervalSince(startTime!)
                durations.append(duration)
                startTime = nil
            }
        }
        
        if durations.isEmpty {
            return 3600 * 4 // Default 4 hours
        }
        
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    private func analyzeHistoricalTransitions(from regime: MarketRegime, history: [RegimeDataPoint]) -> [MarketRegime: Double] {
        var transitions: [MarketRegime: Int] = [:]
        var totalTransitions = 0
        
        for i in 1..<history.count {
            if history[i-1].regime == regime && history[i].regime != regime {
                transitions[history[i].regime, default: 0] += 1
                totalTransitions += 1
            }
        }
        
        var probabilities: [MarketRegime: Double] = [:]
        
        for (toRegime, count) in transitions {
            probabilities[toRegime] = Double(count) / Double(max(totalTransitions, 1))
        }
        
        return probabilities
    }
    
    private func performRealtimeDetection(symbols: [String]) async {
        for symbol in symbols {
            do {
                _ = try await detectMarketRegime(for: symbol)
                
                // Update accuracy based on historical performance
                updateDetectionAccuracy()
            } catch {
                print("Regime detection error for \(symbol): \(error)")
            }
        }
    }
    
    private func updateDetectionAccuracy() {
        // Calculate accuracy based on regime predictions vs actual
        let recentHistory = regimeHistory.suffix(50)
        var correctPredictions = 0
        var totalPredictions = 0
        
        for i in 1..<recentHistory.count {
            let predicted = recentHistory[i-1].predictions.nextRegime
            let actual = recentHistory[i].currentRegime
            
            if predicted == actual {
                correctPredictions += 1
            }
            totalPredictions += 1
        }
        
        if totalPredictions > 0 {
            detectionAccuracy = Double(correctPredictions) / Double(totalPredictions)
        }
    }
    
    // MARK: - Strategy Creation
    
    private func createTrendFollowingStrategy() -> TradingStrategy {
        return TradingStrategy(
            name: "Adaptive Trend Following",
            description: "Optimized for trending markets with dynamic position sizing",
            conditions: [
                StrategyCondition(type: .entry(.above), parameters: ["EMA20", "greaterThan", "0"], logicOperator: .and),
                StrategyCondition(type: .entry(.above), parameters: ["ADX", "greaterThan", "25"], logicOperator: .and)
            ],
            riskManagement: RiskManagement(
                stopLossPercent: 1.5,
                takeProfitPercent: 4.0,
                positionSizePercent: 3.0,
                maxOpenTrades: 3,
                maxDailyLoss: 5.0,
                maxDrawdown: 20.0,
                useTrailingStop: false,
                trailingStopDistance: 1.0
            ),
            timeframe: .h4
        )
    }
    
    private func createRangeStrategy() -> TradingStrategy {
        return TradingStrategy(
            name: "Range Bound Trading",
            description: "Buy support, sell resistance in ranging markets",
            conditions: [
                StrategyCondition(type: .entry(.below), parameters: ["RSI", "lessThan", "30"], logicOperator: .and),
                StrategyCondition(type: .entry(.below), parameters: ["Price", "lessThanOrEqual", "0"], logicOperator: .and)
            ],
            riskManagement: RiskManagement(
                stopLossPercent: 0.5,
                takeProfitPercent: 1.0,
                positionSizePercent: 2.0,
                maxOpenTrades: 5
            ),
            timeframe: .h1
        )
    }
    
    private func createVolatilityStrategy() -> TradingStrategy {
        return TradingStrategy(
            name: "Volatility Breakout",
            description: "Trade volatility expansions with wide stops",
            conditions: [
                StrategyCondition(type: .entry(.above), parameters: ["ATR", "greaterThan", "0.02"], logicOperator: .and),
                StrategyCondition(type: .entry(.above), parameters: ["BB_Width", "greaterThan", "0.03"], logicOperator: .and)
            ],
            riskManagement: RiskManagement(
                stopLossPercent: 2.0,
                takeProfitPercent: 3.0,
                positionSizePercent: 1.0,
                maxOpenTrades: 2
            ),
            timeframe: .m30
        )
    }
    
    private func createBreakoutStrategy() -> TradingStrategy {
        return TradingStrategy(
            name: "Momentum Breakout",
            description: "Trade breakouts with momentum confirmation",
            conditions: [
                StrategyCondition(type: .entry(.above), parameters: ["Price", "greaterThan", "0"], logicOperator: .and),
                StrategyCondition(type: .entry(.above), parameters: ["Volume", "greaterThan", "1.5"], logicOperator: .and)
            ],
            riskManagement: RiskManagement(
                stopLossPercent: 0.75,
                takeProfitPercent: 2.5,
                positionSizePercent: 2.5,
                maxOpenTrades: 3
            ),
            timeframe: .h1
        )
    }
    
    private func createReversalStrategy() -> TradingStrategy {
        return TradingStrategy(
            name: "Reversal Trading",
            description: "Catch trend reversals with tight risk management",
            conditions: [
                StrategyCondition(type: .entry(.above), parameters: ["RSI", "greaterThan", "70"], logicOperator: .and),
                StrategyCondition(type: .entry(.crossAbove), parameters: ["Divergence", "equalTo", "1"], logicOperator: .and)
            ],
            riskManagement: RiskManagement(
                stopLossPercent: 1.0,
                takeProfitPercent: 3.0,
                positionSizePercent: 1.5,
                maxOpenTrades: 2
            ),
            timeframe: .h4
        )
    }
    
    private func createScalpingStrategy() -> TradingStrategy {
        return TradingStrategy(
            name: "Low Vol Scalping",
            description: "Quick scalps in low volatility environments",
            conditions: [
                StrategyCondition(type: .entry(.below), parameters: ["Spread", "lessThan", "0.0002"], logicOperator: .and),
                StrategyCondition(type: .entry(.below), parameters: ["ATR", "lessThan", "0.005"], logicOperator: .and)
            ],
            riskManagement: RiskManagement(
                stopLossPercent: 0.2,
                takeProfitPercent: 0.3,
                positionSizePercent: 5.0,
                maxOpenTrades: 10
            ),
            timeframe: .m5
        )
    }
}

// MARK: - Supporting Types

struct RegimeMarketData {
    let symbol: String
    let candles: [Candle]
    let volume: Double
    let volatility: Double
}