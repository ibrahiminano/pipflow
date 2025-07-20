//
//  AIChartAnalysisService.swift
//  Pipflow
//
//  Created by Claude on 19/07/2025.
//

import Foundation
import Combine

// MARK: - AI Chart Analysis Service

class AIChartAnalysisService: ObservableObject {
    static let shared = AIChartAnalysisService()
    
    @Published var isAnalyzing = false
    @Published var latestAnalysis: AIChartAnalysis?
    
    private let aiSignalService = AISignalService.shared
    private let marketDataService = MarketDataService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func analyzeChart(
        symbol: String,
        timeframe: ChartTimeframe,
        candles: [CandleData],
        provider: AIProvider = .claude
    ) -> AnyPublisher<AIChartAnalysis, Error> {
        isAnalyzing = true
        
        return Future<AIChartAnalysis, Error> { [weak self] promise in
            guard let self = self else { return }
            
            // Prepare market data
            let currentPrice = candles.last?.close ?? 0
            let marketData = self.prepareMarketData(from: candles)
            let technicalIndicators = self.calculateTechnicalIndicators(from: candles)
            
            // Pattern Detection
            let patterns = self.detectPatterns(in: candles)
            
            // Support & Resistance Analysis
            let (supportLevels, resistanceLevels) = self.analyzeSupportResistance(candles: candles)
            
            // Risk Zone Analysis
            let riskZones = self.analyzeRiskZones(candles: candles, currentPrice: currentPrice)
            
            // Price Prediction
            let prediction = self.generatePricePrediction(
                candles: candles,
                currentPrice: currentPrice,
                timeframe: timeframe
            )
            
            // Trend Analysis
            let trendAnalysis = self.analyzeTrends(candles: candles)
            
            // Generate AI Signals
            self.aiSignalService.generateSignal(
                for: symbol,
                timeframe: timeframe.rawValue,
                marketData: marketData,
                technicalIndicators: technicalIndicators,
                provider: provider
            )
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                },
                receiveValue: { signal in
                    // Generate market commentary
                    let commentary = self.generateMarketCommentary(
                        symbol: symbol,
                        signal: signal,
                        patterns: patterns,
                        trendAnalysis: trendAnalysis,
                        currentPrice: currentPrice
                    )
                    
                    // Convert Signal to AISignal
                    let aiSignals = [
                        AISignal(
                            type: signal.action,
                            price: Double(truncating: signal.entry as NSNumber),
                            confidence: signal.confidence,
                            reason: signal.rationale,
                            timestamp: signal.generatedAt
                        )
                    ]
                    
                    let analysis = AIChartAnalysis(
                        patterns: patterns,
                        supportLevels: supportLevels,
                        resistanceLevels: resistanceLevels,
                        predictions: prediction,
                        riskZones: riskZones,
                        signals: aiSignals,
                        trendAnalysis: trendAnalysis,
                        marketCommentary: commentary,
                        timestamp: Date()
                    )
                    
                    self.latestAnalysis = analysis
                    self.isAnalyzing = false
                    promise(.success(analysis))
                }
            )
            .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Analysis Methods
    
    private func prepareMarketData(from candles: [CandleData]) -> MarketData {
        let currentPrice = candles.last?.close ?? 0
        let high24h = candles.suffix(24).map { $0.high }.max() ?? currentPrice
        let low24h = candles.suffix(24).map { $0.low }.min() ?? currentPrice
        let volume24h = candles.suffix(24).map { $0.volume }.reduce(0, +)
        let firstPrice = candles.suffix(24).first?.open ?? currentPrice
        let priceChange24h = ((currentPrice - firstPrice) / firstPrice) * 100
        
        return MarketData(
            currentPrice: currentPrice,
            high24h: high24h,
            low24h: low24h,
            volume24h: volume24h,
            priceChange24h: priceChange24h,
            bid: currentPrice * 0.9999,
            ask: currentPrice * 1.0001,
            spread: currentPrice * 0.0002
        )
    }
    
    private func calculateTechnicalIndicators(from candles: [CandleData]) -> TechnicalIndicators {
        // RSI Calculation
        let rsi = calculateRSI(candles: candles, period: 14)
        
        // MACD Calculation
        let macd = calculateMACD(candles: candles)
        
        // Moving Averages
        let ma20 = calculateSMA(candles: candles, period: 20)
        let ma50 = calculateSMA(candles: candles, period: 50)
        let ma200 = calculateSMA(candles: candles, period: 200)
        
        let movingAverages = MovingAverages(ma20: ma20, ma50: ma50, ma200: ma200)
        
        // Support & Resistance
        let (support, resistance) = findNearestSupportResistance(candles: candles)
        
        // Trend Detection
        let trend = detectTrend(candles: candles)
        
        return TechnicalIndicators(
            rsi: rsi,
            macd: macd,
            movingAverages: movingAverages,
            support: support,
            resistance: resistance,
            trend: trend
        )
    }
    
    private func detectPatterns(in candles: [CandleData]) -> [ChartPattern] {
        var patterns: [ChartPattern] = []
        
        // Head and Shoulders Detection
        if let headAndShoulders = detectHeadAndShoulders(candles: candles) {
            patterns.append(headAndShoulders)
        }
        
        // Triangle Pattern Detection
        if let triangle = detectTriangle(candles: candles) {
            patterns.append(triangle)
        }
        
        // Double Top/Bottom Detection
        if let doublePattern = detectDoubleTopBottom(candles: candles) {
            patterns.append(doublePattern)
        }
        
        return patterns
    }
    
    private func analyzeSupportResistance(candles: [CandleData]) -> ([PriceLevel], [PriceLevel]) {
        var supportLevels: [PriceLevel] = []
        var resistanceLevels: [PriceLevel] = []
        
        // Find local minima and maxima
        let swingPoints = findSwingPoints(candles: candles)
        
        // Cluster swing points to find support/resistance zones
        let priceLevels = clusterPriceLevels(swingPoints: swingPoints)
        
        // Classify as support or resistance based on current price
        let currentPrice = candles.last?.close ?? 0
        
        for level in priceLevels {
            if level.price < currentPrice {
                supportLevels.append(level)
            } else {
                resistanceLevels.append(level)
            }
        }
        
        // Sort by strength and limit to top 3
        supportLevels.sort { $0.strength > $1.strength }
        resistanceLevels.sort { $0.strength > $1.strength }
        
        return (Array(supportLevels.prefix(3)), Array(resistanceLevels.prefix(3)))
    }
    
    private func analyzeRiskZones(candles: [CandleData], currentPrice: Double) -> [RiskZone] {
        var riskZones: [RiskZone] = []
        
        // High volatility zones
        let volatilityZones = identifyHighVolatilityZones(candles: candles)
        riskZones.append(contentsOf: volatilityZones)
        
        // Gap zones
        let gapZones = identifyGapZones(candles: candles)
        riskZones.append(contentsOf: gapZones)
        
        // Overbought/Oversold zones
        if let rsi = calculateRSI(candles: candles, period: 14) {
            if rsi > 70 {
                riskZones.append(RiskZone(
                    startPrice: currentPrice,
                    endPrice: currentPrice * 1.02,
                    riskLevel: .high,
                    reason: "Overbought condition (RSI > 70)"
                ))
            } else if rsi < 30 {
                riskZones.append(RiskZone(
                    startPrice: currentPrice * 0.98,
                    endPrice: currentPrice,
                    riskLevel: .high,
                    reason: "Oversold condition (RSI < 30)"
                ))
            }
        }
        
        return riskZones
    }
    
    private func generatePricePrediction(
        candles: [CandleData],
        currentPrice: Double,
        timeframe: ChartTimeframe
    ) -> PricePrediction {
        // Calculate momentum
        let momentum = calculateMomentum(candles: candles)
        
        // Calculate volatility
        let volatility = calculateVolatility(candles: candles)
        
        // Time horizon based on timeframe
        let timeHorizon: Int
        switch timeframe {
        case .m1: timeHorizon = 5
        case .m5: timeHorizon = 15
        case .m15: timeHorizon = 30
        case .m30: timeHorizon = 60
        case .h1: timeHorizon = 120
        case .h4: timeHorizon = 480
        case .d1: timeHorizon = 1440
        case .w1: timeHorizon = 10080
        case .mn: timeHorizon = 43200
        }
        
        // Simple prediction based on momentum and volatility
        let predictedChange = momentum * 0.5
        let predictedPrice = currentPrice * (1 + predictedChange)
        let upperBound = predictedPrice + (currentPrice * volatility)
        let lowerBound = predictedPrice - (currentPrice * volatility)
        
        // Confidence based on trend strength and volatility
        let confidence = max(0.3, min(0.9, (1 - volatility) * 0.8))
        
        return PricePrediction(
            timeHorizon: timeHorizon,
            predictedPrice: predictedPrice,
            upperBound: upperBound,
            lowerBound: lowerBound,
            confidence: confidence
        )
    }
    
    private func analyzeTrends(candles: [CandleData]) -> TrendAnalysis {
        // Short-term trend (last 10 candles)
        let shortTerm = detectTrend(candles: Array(candles.suffix(10)))
        
        // Medium-term trend (last 50 candles)
        let mediumTerm = detectTrend(candles: Array(candles.suffix(50)))
        
        // Long-term trend (all candles)
        let longTerm = detectTrend(candles: candles)
        
        // Calculate trend strength
        let strength = calculateTrendStrength(candles: candles)
        
        // Calculate momentum
        let momentum = calculateMomentum(candles: candles)
        
        return TrendAnalysis(
            shortTerm: shortTerm,
            mediumTerm: mediumTerm,
            longTerm: longTerm,
            strength: strength,
            momentum: momentum
        )
    }
    
    private func generateMarketCommentary(
        symbol: String,
        signal: Signal,
        patterns: [ChartPattern],
        trendAnalysis: TrendAnalysis,
        currentPrice: Double
    ) -> String {
        var commentary = "Market Analysis for \(symbol):\n\n"
        
        // Trend Commentary
        commentary += "The market is showing \(trendAnalysis.shortTerm.rawValue.lowercased()) momentum in the short term "
        commentary += "with \(trendAnalysis.mediumTerm.rawValue.lowercased()) medium-term trend. "
        commentary += "Trend strength is at \(Int(trendAnalysis.strength * 100))%.\n\n"
        
        // Pattern Commentary
        if !patterns.isEmpty {
            commentary += "Technical patterns detected: "
            commentary += patterns.map { "\($0.type.rawValue) (confidence: \(Int($0.confidence * 100))%)" }.joined(separator: ", ")
            commentary += ".\n\n"
        }
        
        // Signal Commentary
        commentary += "AI recommendation: \(signal.action.rawValue) signal generated "
        commentary += "with \(Int(signal.confidence * 100))% confidence. "
        commentary += signal.rationale + "\n\n"
        
        // Risk Commentary
        commentary += "Risk management: Set stop loss at \(String(format: "%.5f", Double(truncating: signal.stopLoss as NSNumber))) "
        commentary += "and take profit at \(String(format: "%.5f", Double(truncating: signal.takeProfits.first?.price ?? 0 as NSNumber))). "
        commentary += "Risk-reward ratio: \(String(format: "%.2f", signal.riskRewardRatio))."
        
        return commentary
    }
    
    // MARK: - Technical Analysis Helpers
    
    private func calculateRSI(candles: [CandleData], period: Int = 14) -> Double? {
        guard candles.count > period else { return nil }
        
        let prices = candles.map { $0.close }
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(abs(change))
            }
        }
        
        let avgGain = gains.suffix(period).reduce(0, +) / Double(period)
        let avgLoss = losses.suffix(period).reduce(0, +) / Double(period)
        
        guard avgLoss > 0 else { return 100 }
        
        let rs = avgGain / avgLoss
        let rsi = 100 - (100 / (1 + rs))
        
        return rsi
    }
    
    private func calculateMACD(candles: [CandleData]) -> MACDIndicator? {
        guard candles.count >= 26 else { return nil }
        
        let closes = candles.map { $0.close }
        let ema12 = calculateEMA(values: closes, period: 12)
        let ema26 = calculateEMA(values: closes, period: 26)
        
        guard let shortEMA = ema12, let longEMA = ema26 else { return nil }
        
        let macd = shortEMA - longEMA
        let signal = calculateEMA(values: [macd], period: 9) ?? 0
        let histogram = macd - signal
        
        return MACDIndicator(macd: macd, signal: signal, histogram: histogram)
    }
    
    private func calculateSMA(candles: [CandleData], period: Int) -> Double {
        let closes = candles.suffix(period).map { $0.close }
        return closes.reduce(0, +) / Double(closes.count)
    }
    
    private func calculateEMA(values: [Double], period: Int) -> Double? {
        guard values.count >= period else { return nil }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema = values.prefix(period).reduce(0, +) / Double(period)
        
        for i in period..<values.count {
            ema = (values[i] - ema) * multiplier + ema
        }
        
        return ema
    }
    
    private func detectTrend(candles: [CandleData]) -> TrendDirection {
        guard candles.count > 2 else { return .neutral }
        
        let firstPrice = candles.first!.close
        let lastPrice = candles.last!.close
        let change = (lastPrice - firstPrice) / firstPrice
        
        if change > 0.001 {
            return .bullish
        } else if change < -0.001 {
            return .bearish
        } else {
            return .neutral
        }
    }
    
    private func calculateTrendStrength(candles: [CandleData]) -> Double {
        guard candles.count > 2 else { return 0 }
        
        let closes = candles.map { $0.close }
        var trendPoints = 0.0
        
        for i in 1..<closes.count {
            if closes[i] > closes[i-1] {
                trendPoints += 1
            }
        }
        
        return trendPoints / Double(closes.count - 1)
    }
    
    private func calculateMomentum(candles: [CandleData]) -> Double {
        guard candles.count >= 10 else { return 0 }
        
        let recentCandles = candles.suffix(10)
        let oldPrice = recentCandles.first!.close
        let currentPrice = recentCandles.last!.close
        
        return (currentPrice - oldPrice) / oldPrice
    }
    
    private func calculateVolatility(candles: [CandleData]) -> Double {
        guard candles.count > 1 else { return 0 }
        
        let returns = (1..<candles.count).map { i in
            (candles[i].close - candles[i-1].close) / candles[i-1].close
        }
        
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0, +) / Double(returns.count)
        
        return sqrt(variance)
    }
    
    // MARK: - Pattern Detection Methods
    
    private func detectHeadAndShoulders(candles: [CandleData]) -> ChartPattern? {
        guard candles.count >= 15 else { return nil }
        
        // Simplified head and shoulders detection
        let highs = candles.map { $0.high }
        
        // Find peaks
        var peaks: [(index: Int, value: Double)] = []
        for i in 1..<highs.count-1 {
            if highs[i] > highs[i-1] && highs[i] > highs[i+1] {
                peaks.append((i, highs[i]))
            }
        }
        
        // Look for head and shoulders pattern
        guard peaks.count >= 3 else { return nil }
        
        let lastThreePeaks = peaks.suffix(3)
        if lastThreePeaks[1].value > lastThreePeaks[0].value &&
           lastThreePeaks[1].value > lastThreePeaks[2].value &&
           abs(lastThreePeaks[0].value - lastThreePeaks[2].value) / lastThreePeaks[0].value < 0.02 {
            
            return ChartPattern(
                type: .headAndShoulders,
                startIndex: lastThreePeaks[0].index,
                endIndex: lastThreePeaks[2].index,
                confidence: 0.7,
                description: "Head and shoulders pattern detected, potential reversal signal"
            )
        }
        
        return nil
    }
    
    private func detectTriangle(candles: [CandleData]) -> ChartPattern? {
        guard candles.count >= 10 else { return nil }
        
        let recentCandles = Array(candles.suffix(20))
        let highs = recentCandles.map { $0.high }
        let lows = recentCandles.map { $0.low }
        
        // Check for converging highs and lows
        let highSlope = calculateSlope(values: highs)
        let lowSlope = calculateSlope(values: lows)
        
        if highSlope < 0 && lowSlope > 0 && abs(highSlope) > 0.0001 && abs(lowSlope) > 0.0001 {
            return ChartPattern(
                type: .triangle,
                startIndex: candles.count - 20,
                endIndex: candles.count - 1,
                confidence: 0.65,
                description: "Symmetrical triangle pattern forming"
            )
        }
        
        return nil
    }
    
    private func detectDoubleTopBottom(candles: [CandleData]) -> ChartPattern? {
        guard candles.count >= 20 else { return nil }
        
        let highs = candles.map { $0.high }
        let lows = candles.map { $0.low }
        
        // Find recent peaks
        var peaks: [(index: Int, value: Double)] = []
        var troughs: [(index: Int, value: Double)] = []
        
        for i in 2..<candles.count-2 {
            if highs[i] > highs[i-1] && highs[i] > highs[i+1] &&
               highs[i] > highs[i-2] && highs[i] > highs[i+2] {
                peaks.append((i, highs[i]))
            }
            if lows[i] < lows[i-1] && lows[i] < lows[i+1] &&
               lows[i] < lows[i-2] && lows[i] < lows[i+2] {
                troughs.append((i, lows[i]))
            }
        }
        
        // Check for double top
        if peaks.count >= 2 {
            let lastTwoPeaks = peaks.suffix(2)
            if abs(lastTwoPeaks[0].value - lastTwoPeaks[1].value) / lastTwoPeaks[0].value < 0.01 {
                return ChartPattern(
                    type: .doubleTop,
                    startIndex: lastTwoPeaks[0].index,
                    endIndex: lastTwoPeaks[1].index,
                    confidence: 0.75,
                    description: "Double top pattern detected, bearish reversal signal"
                )
            }
        }
        
        // Check for double bottom
        if troughs.count >= 2 {
            let lastTwoTroughs = troughs.suffix(2)
            if abs(lastTwoTroughs[0].value - lastTwoTroughs[1].value) / lastTwoTroughs[0].value < 0.01 {
                return ChartPattern(
                    type: .doubleBottom,
                    startIndex: lastTwoTroughs[0].index,
                    endIndex: lastTwoTroughs[1].index,
                    confidence: 0.75,
                    description: "Double bottom pattern detected, bullish reversal signal"
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Support/Resistance Helpers
    
    private func findSwingPoints(candles: [CandleData]) -> [(price: Double, type: String, index: Int)] {
        var swingPoints: [(price: Double, type: String, index: Int)] = []
        
        for i in 2..<candles.count-2 {
            let high = candles[i].high
            let low = candles[i].low
            
            // Swing high
            if high > candles[i-1].high && high > candles[i+1].high &&
               high > candles[i-2].high && high > candles[i+2].high {
                swingPoints.append((high, "resistance", i))
            }
            
            // Swing low
            if low < candles[i-1].low && low < candles[i+1].low &&
               low < candles[i-2].low && low < candles[i+2].low {
                swingPoints.append((low, "support", i))
            }
        }
        
        return swingPoints
    }
    
    private func clusterPriceLevels(swingPoints: [(price: Double, type: String, index: Int)]) -> [PriceLevel] {
        var levels: [PriceLevel] = []
        let threshold = 0.001 // 0.1% price difference to cluster
        
        var clustered = Set<Int>()
        
        for i in 0..<swingPoints.count {
            if clustered.contains(i) { continue }
            
            var cluster: [(price: Double, type: String, index: Int)] = [swingPoints[i]]
            clustered.insert(i)
            
            for j in (i+1)..<swingPoints.count {
                if clustered.contains(j) { continue }
                
                let priceDiff = abs(swingPoints[i].price - swingPoints[j].price) / swingPoints[i].price
                if priceDiff < threshold {
                    cluster.append(swingPoints[j])
                    clustered.insert(j)
                }
            }
            
            // Create price level from cluster
            let avgPrice = cluster.map { $0.price }.reduce(0, +) / Double(cluster.count)
            let strength = Double(cluster.count) / Double(swingPoints.count)
            let lastTested = cluster.map { $0.index }.max() ?? 0
            
            levels.append(PriceLevel(
                price: avgPrice,
                strength: min(1.0, strength * 3), // Normalize strength
                touches: cluster.count,
                lastTested: Date() // In real implementation, convert index to date
            ))
        }
        
        return levels.sorted { $0.strength > $1.strength }
    }
    
    private func findNearestSupportResistance(candles: [CandleData]) -> (Double?, Double?) {
        let currentPrice = candles.last?.close ?? 0
        let swingPoints = findSwingPoints(candles: candles)
        
        let supports = swingPoints.filter { $0.type == "support" && $0.price < currentPrice }
            .sorted { $0.price > $1.price }
        let resistances = swingPoints.filter { $0.type == "resistance" && $0.price > currentPrice }
            .sorted { $0.price < $1.price }
        
        return (supports.first?.price, resistances.first?.price)
    }
    
    // MARK: - Risk Zone Helpers
    
    private func identifyHighVolatilityZones(candles: [CandleData]) -> [RiskZone] {
        var zones: [RiskZone] = []
        let avgVolatility = calculateVolatility(candles: candles)
        
        for i in 0..<candles.count-5 {
            let window = Array(candles[i..<i+5])
            let windowVolatility = calculateVolatility(candles: window)
            
            if windowVolatility > avgVolatility * 1.5 {
                let highPrice = window.map { $0.high }.max() ?? 0
                let lowPrice = window.map { $0.low }.min() ?? 0
                
                zones.append(RiskZone(
                    startPrice: lowPrice,
                    endPrice: highPrice,
                    riskLevel: .medium,
                    reason: "High volatility zone"
                ))
            }
        }
        
        return zones
    }
    
    private func identifyGapZones(candles: [CandleData]) -> [RiskZone] {
        var zones: [RiskZone] = []
        
        for i in 1..<candles.count {
            let gap = candles[i].open - candles[i-1].close
            let gapPercent = abs(gap) / candles[i-1].close
            
            if gapPercent > 0.002 { // 0.2% gap
                let riskLevel: RiskZone.RiskLevel = gapPercent > 0.005 ? .high : .medium
                zones.append(RiskZone(
                    startPrice: min(candles[i].open, candles[i-1].close),
                    endPrice: max(candles[i].open, candles[i-1].close),
                    riskLevel: riskLevel,
                    reason: "Price gap zone"
                ))
            }
        }
        
        return zones
    }
    
    private func calculateSlope(values: [Double]) -> Double {
        let n = Double(values.count)
        let indices = Array(0..<values.count).map { Double($0) }
        
        let sumX = indices.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(indices, values).map { $0 * $1 }.reduce(0, +)
        let sumX2 = indices.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        return slope
    }
}