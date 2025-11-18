//
//  BacktestingEngine.swift
//  Pipflow
//
//  AI-powered strategy backtesting engine
//

import Foundation
import SwiftUI

// MARK: - Backtesting Models

struct BacktestRequest {
    let strategy: TradingStrategy
    let symbol: String
    let startDate: Date
    let endDate: Date
    let initialCapital: Double
    let riskPerTrade: Double
    let commission: Double
    let spread: Double
}

struct BacktestResult: Identifiable {
    let id = UUID()
    let strategy: TradingStrategy
    let performance: BacktestPerformanceMetrics
    let trades: [BacktestTrade]
    let equityCurve: [BacktestEquityPoint]
    let drawdownCurve: [DrawdownPoint]
    let monthlyReturns: [BacktestMonthlyReturn]
    let statistics: BacktestStatistics
    let timestamp: Date
}

struct BacktestTrade: Identifiable {
    let id = UUID()
    let entryDate: Date
    let exitDate: Date
    let symbol: String
    let direction: TradeDirection
    let entryPrice: Double
    let exitPrice: Double
    let size: Double
    let pnl: Double
    let pnlPercentage: Double
    let commission: Double
    let holdingPeriod: TimeInterval
    let mae: Double // Maximum Adverse Excursion
    let mfe: Double // Maximum Favorable Excursion
}

struct BacktestPerformanceMetrics {
    let totalReturn: Double
    let annualizedReturn: Double
    let sharpeRatio: Double
    let sortinoRatio: Double
    let maxDrawdown: Double
    let winRate: Double
    let profitFactor: Double
    let averageWin: Double
    let averageLoss: Double
    let expectancy: Double
    let numberOfTrades: Int
    let averageTradesPerMonth: Double
}

struct BacktestStatistics {
    let calmarRatio: Double
    let recoveryFactor: Double
    let payoffRatio: Double
    let consecutiveWins: Int
    let consecutiveLosses: Int
    let largestWin: Double
    let largestLoss: Double
    let averageHoldingPeriod: TimeInterval
    let exposureTime: Double
    let marketCorrelation: Double
}

struct BacktestEquityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let drawdown: Double
}

struct DrawdownPoint: Identifiable {
    let id = UUID()
    let date: Date
    let drawdown: Double
}

struct BacktestMonthlyReturn: Identifiable {
    let id = UUID()
    let month: String
    let year: Int
    let returnValue: Double
}

// MARK: - Historical Data Models

struct HistoricalCandle {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

struct HistoricalDataRequest {
    let symbol: String
    let timeframe: Timeframe
    let startDate: Date
    let endDate: Date
}

// MARK: - Backtesting Engine

@MainActor
class BacktestingEngine: ObservableObject {
    static let shared = BacktestingEngine()
    
    @Published var isBacktesting = false
    @Published var backtestProgress: Double = 0
    @Published var currentBacktest: BacktestResult?
    @Published var backtestHistory: [BacktestResult] = []
    @Published var historicalData: [String: [HistoricalCandle]] = [:]
    
    private let dataService = MarketDataService.shared
    private let aiService = AISignalService.shared
    
    // MARK: - Public Methods
    
    func runBacktest(_ request: BacktestRequest) async throws -> BacktestResult {
        isBacktesting = true
        backtestProgress = 0
        
        do {
            // 1. Fetch historical data
            let candles = try await fetchHistoricalData(
                symbol: request.symbol,
                startDate: request.startDate,
                endDate: request.endDate
            )
            
            // 2. Generate signals based on strategy
            let signals = try await generateBacktestSignals(
                strategy: request.strategy,
                candles: candles
            )
            
            // 3. Simulate trades
            let trades = simulateTrades(
                signals: signals,
                candles: candles,
                request: request
            )
            
            // 4. Calculate performance metrics
            let performance = calculatePerformanceMetrics(
                trades: trades,
                initialCapital: request.initialCapital,
                candles: candles
            )
            
            // 5. Generate equity curve
            let equityCurve = generateEquityCurve(
                trades: trades,
                initialCapital: request.initialCapital
            )
            
            // 6. Calculate drawdown curve
            let drawdownCurve = calculateDrawdownCurve(equityCurve: equityCurve)
            
            // 7. Calculate monthly returns
            let monthlyReturns = calculateMonthlyReturns(trades: trades)
            
            // 8. Calculate advanced statistics
            let statistics = calculateAdvancedStatistics(
                trades: trades,
                equityCurve: equityCurve,
                candles: candles
            )
            
            let result = BacktestResult(
                strategy: request.strategy,
                performance: performance,
                trades: trades,
                equityCurve: equityCurve,
                drawdownCurve: drawdownCurve,
                monthlyReturns: monthlyReturns,
                statistics: statistics,
                timestamp: Date()
            )
            
            currentBacktest = result
            backtestHistory.append(result)
            
            isBacktesting = false
            return result
            
        } catch {
            isBacktesting = false
            throw error
        }
    }
    
    func compareStrategies(_ strategies: [TradingStrategy], on symbol: String, from startDate: Date, to endDate: Date) async throws -> [BacktestResult] {
        var results: [BacktestResult] = []
        
        for strategy in strategies {
            let request = BacktestRequest(
                strategy: strategy,
                symbol: symbol,
                startDate: startDate,
                endDate: endDate,
                initialCapital: 10000,
                riskPerTrade: 0.02,
                commission: 0.001,
                spread: 0.0001
            )
            
            let result = try await runBacktest(request)
            results.append(result)
        }
        
        return results
    }
    
    // MARK: - Private Methods
    
    private func fetchHistoricalData(symbol: String, startDate: Date, endDate: Date) async throws -> [HistoricalCandle] {
        // Check cache first
        let cacheKey = "\(symbol)_\(startDate)_\(endDate)"
        if let cached = historicalData[cacheKey] {
            return cached
        }
        
        // For demo, generate synthetic data
        var candles: [HistoricalCandle] = []
        var currentDate = startDate
        var price = 1.1000 + Double.random(in: -0.01...0.01)
        
        while currentDate <= endDate {
            let volatility = 0.0010
            let trend = sin(currentDate.timeIntervalSince1970 / 86400) * 0.0005
            
            let open = price
            let change = (Double.random(in: -1...1) * volatility) + trend
            let high = max(open, open + abs(change) * 1.5)
            let low = min(open, open - abs(change) * 1.5)
            let close = open + change
            
            let candle = HistoricalCandle(
                timestamp: currentDate,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: Double.random(in: 1000...5000)
            )
            
            candles.append(candle)
            price = close
            currentDate = currentDate.addingTimeInterval(3600) // 1 hour candles
            
            // Update progress
            let progress = currentDate.timeIntervalSince(startDate) / endDate.timeIntervalSince(startDate)
            await MainActor.run {
                self.backtestProgress = progress * 0.3 // 30% for data fetching
            }
        }
        
        // Cache the data
        historicalData[cacheKey] = candles
        
        return candles
    }
    
    private func generateBacktestSignals(strategy: TradingStrategy, candles: [HistoricalCandle]) async throws -> [BacktestSignal] {
        var signals: [BacktestSignal] = []
        
        // Calculate indicators
        let closes = candles.map { $0.close }
        let rsi = calculateRSI(prices: closes, period: 14)
        let (upperBand, _, lowerBand) = calculateBollingerBands(prices: closes, period: 20, standardDeviations: 2)
        _ = calculateEMA(prices: closes, period: 20)
        _ = calculateEMA(prices: closes, period: 50)
        
        // Generate signals based on strategy conditions
        for i in 50..<candles.count {
            let candle = candles[i]
            
            // Example: RSI oversold + price at lower Bollinger Band
            if rsi[i] < 30 && candle.low <= lowerBand[i] {
                let signal = BacktestSignal(
                    timestamp: candle.timestamp,
                    action: .buy,
                    price: candle.close,
                    stopLoss: candle.close * 0.995,
                    takeProfit: candle.close * 1.01,
                    confidence: 0.75
                )
                signals.append(signal)
            }
            
            // Example: RSI overbought + price at upper Bollinger Band
            if rsi[i] > 70 && candle.high >= upperBand[i] {
                let signal = BacktestSignal(
                    timestamp: candle.timestamp,
                    action: .sell,
                    price: candle.close,
                    stopLoss: candle.close * 1.005,
                    takeProfit: candle.close * 0.99,
                    confidence: 0.75
                )
                signals.append(signal)
            }
            
            // Update progress
            let progress = 0.3 + (Double(i) / Double(candles.count)) * 0.3 // 30-60% for signal generation
            await MainActor.run {
                self.backtestProgress = progress
            }
        }
        
        return signals
    }
    
    private func simulateTrades(signals: [BacktestSignal], candles: [HistoricalCandle], request: BacktestRequest) -> [BacktestTrade] {
        var trades: [BacktestTrade] = []
        var capital = request.initialCapital
        var openPosition: OpenPosition? = nil
        
        _ = Dictionary(uniqueKeysWithValues: candles.map { ($0.timestamp, $0) })
        
        for (index, signal) in signals.enumerated() {
            // Skip if we have an open position
            if openPosition != nil { continue }
            
            // Calculate position size based on risk
            let riskAmount = capital * request.riskPerTrade
            let stopDistance = abs(signal.price - signal.stopLoss)
            let positionSize = riskAmount / stopDistance
            
            // Open position
            openPosition = OpenPosition(
                entryDate: signal.timestamp,
                entryPrice: signal.price,
                direction: signal.action,
                size: positionSize,
                stopLoss: signal.stopLoss,
                takeProfit: signal.takeProfit
            )
            
            // Find exit point
            var mae: Double = 0
            var mfe: Double = 0
            
            for candle in candles.suffix(from: candles.firstIndex(where: { $0.timestamp >= signal.timestamp }) ?? 0) {
                guard let position = openPosition else { break }
                
                // Track MAE/MFE
                let unrealizedPnL = position.direction == .buy ?
                    (candle.low - position.entryPrice) * position.size :
                    (position.entryPrice - candle.high) * position.size
                
                mae = min(mae, unrealizedPnL)
                mfe = max(mfe, unrealizedPnL)
                
                // Check stop loss
                if (position.direction == .buy && candle.low <= position.stopLoss) ||
                   (position.direction == .sell && candle.high >= position.stopLoss) {
                    let exitPrice = position.stopLoss
                    let pnl = calculatePnL(position: position, exitPrice: exitPrice, commission: request.commission)
                    
                    trades.append(BacktestTrade(
                        entryDate: position.entryDate,
                        exitDate: candle.timestamp,
                        symbol: request.symbol,
                        direction: position.direction == .buy ? .long : .short,
                        entryPrice: position.entryPrice,
                        exitPrice: exitPrice,
                        size: position.size,
                        pnl: pnl,
                        pnlPercentage: pnl / (position.entryPrice * position.size) * 100,
                        commission: request.commission * position.size * 2,
                        holdingPeriod: candle.timestamp.timeIntervalSince(position.entryDate),
                        mae: mae,
                        mfe: mfe
                    ))
                    
                    capital += pnl
                    openPosition = nil
                    break
                }
                
                // Check take profit
                if (position.direction == .buy && candle.high >= position.takeProfit) ||
                   (position.direction == .sell && candle.low <= position.takeProfit) {
                    let exitPrice = position.takeProfit
                    let pnl = calculatePnL(position: position, exitPrice: exitPrice, commission: request.commission)
                    
                    trades.append(BacktestTrade(
                        entryDate: position.entryDate,
                        exitDate: candle.timestamp,
                        symbol: request.symbol,
                        direction: position.direction == .buy ? .long : .short,
                        entryPrice: position.entryPrice,
                        exitPrice: exitPrice,
                        size: position.size,
                        pnl: pnl,
                        pnlPercentage: pnl / (position.entryPrice * position.size) * 100,
                        commission: request.commission * position.size * 2,
                        holdingPeriod: candle.timestamp.timeIntervalSince(position.entryDate),
                        mae: mae,
                        mfe: mfe
                    ))
                    
                    capital += pnl
                    openPosition = nil
                    break
                }
            }
            
            // Update progress
            let progress = 0.6 + (Double(index) / Double(signals.count)) * 0.3 // 60-90% for trade simulation
            backtestProgress = progress
        }
        
        return trades
    }
    
    private func calculatePnL(position: OpenPosition, exitPrice: Double, commission: Double) -> Double {
        let grossPnL = position.direction == .buy ?
            (exitPrice - position.entryPrice) * position.size :
            (position.entryPrice - exitPrice) * position.size
        
        let commissionCost = commission * position.size * 2 // Entry and exit
        return grossPnL - commissionCost
    }
    
    private func calculatePerformanceMetrics(trades: [BacktestTrade], initialCapital: Double, candles: [HistoricalCandle]) -> BacktestPerformanceMetrics {
        let totalPnL = trades.reduce(0) { $0 + $1.pnl }
        let totalReturn = (totalPnL / initialCapital) * 100
        
        let wins = trades.filter { $0.pnl > 0 }
        let losses = trades.filter { $0.pnl < 0 }
        let winRate = Double(wins.count) / Double(trades.count) * 100
        
        let averageWin = wins.isEmpty ? 0 : wins.map { $0.pnl }.reduce(0, +) / Double(wins.count)
        let averageLoss = losses.isEmpty ? 0 : abs(losses.map { $0.pnl }.reduce(0, +) / Double(losses.count))
        
        let profitFactor = losses.isEmpty ? Double.infinity :
            wins.map { $0.pnl }.reduce(0, +) / abs(losses.map { $0.pnl }.reduce(0, +))
        
        let expectancy = trades.isEmpty ? 0 :
            trades.map { $0.pnl }.reduce(0, +) / Double(trades.count)
        
        // Calculate annualized return
        let timeSpan = candles.last!.timestamp.timeIntervalSince(candles.first!.timestamp)
        let years = timeSpan / (365.25 * 24 * 3600)
        let annualizedReturn = pow(1 + totalReturn / 100, 1 / years) - 1
        
        // Calculate Sharpe Ratio (simplified)
        let returns = calculateDailyReturns(trades: trades, initialCapital: initialCapital)
        let avgReturn = returns.reduce(0, +) / Double(returns.count)
        let stdDev = calculateStandardDeviation(returns)
        let sharpeRatio = stdDev > 0 ? (avgReturn * 252) / (stdDev * sqrt(252)) : 0
        
        // Calculate Sortino Ratio
        let downsideReturns = returns.filter { $0 < 0 }
        let downsideStdDev = calculateStandardDeviation(downsideReturns)
        let sortinoRatio = downsideStdDev > 0 ? (avgReturn * 252) / (downsideStdDev * sqrt(252)) : 0
        
        // Calculate max drawdown
        var equity = initialCapital
        var peak = initialCapital
        var maxDrawdown = 0.0
        
        for trade in trades.sorted(by: { $0.exitDate < $1.exitDate }) {
            equity += trade.pnl
            if equity > peak {
                peak = equity
            }
            let drawdown = (peak - equity) / peak * 100
            maxDrawdown = max(maxDrawdown, drawdown)
        }
        
        let tradesPerMonth = Double(trades.count) / (timeSpan / (30.44 * 24 * 3600))
        
        return BacktestPerformanceMetrics(
            totalReturn: totalReturn,
            annualizedReturn: annualizedReturn * 100,
            sharpeRatio: sharpeRatio,
            sortinoRatio: sortinoRatio,
            maxDrawdown: maxDrawdown,
            winRate: winRate,
            profitFactor: profitFactor,
            averageWin: averageWin,
            averageLoss: averageLoss,
            expectancy: expectancy,
            numberOfTrades: trades.count,
            averageTradesPerMonth: tradesPerMonth
        )
    }
    
    private func generateEquityCurve(trades: [BacktestTrade], initialCapital: Double) -> [BacktestEquityPoint] {
        var equityCurve: [BacktestEquityPoint] = []
        var equity = initialCapital
        var peak = initialCapital
        
        // Add initial point
        equityCurve.append(BacktestEquityPoint(
            date: trades.first?.entryDate ?? Date(),
            value: equity,
            drawdown: 0
        ))
        
        // Add points for each trade exit
        for trade in trades.sorted(by: { $0.exitDate < $1.exitDate }) {
            equity += trade.pnl
            if equity > peak {
                peak = equity
            }
            let drawdown = (peak - equity) / peak * 100
            
            equityCurve.append(BacktestEquityPoint(
                date: trade.exitDate,
                value: equity,
                drawdown: drawdown
            ))
        }
        
        return equityCurve
    }
    
    private func calculateDrawdownCurve(equityCurve: [BacktestEquityPoint]) -> [DrawdownPoint] {
        return equityCurve.map { point in
            DrawdownPoint(date: point.date, drawdown: point.drawdown)
        }
    }
    
    private func calculateMonthlyReturns(trades: [BacktestTrade]) -> [BacktestMonthlyReturn] {
        let calendar = Calendar.current
        var monthlyPnL: [String: Double] = [:]
        
        for trade in trades {
            let components = calendar.dateComponents([.year, .month], from: trade.exitDate)
            let key = "\(components.year!)-\(String(format: "%02d", components.month!))"
            monthlyPnL[key, default: 0] += trade.pnl
        }
        
        return monthlyPnL.map { key, pnl in
            let parts = key.split(separator: "-")
            return BacktestMonthlyReturn(
                month: getMonthName(Int(parts[1])!),
                year: Int(parts[0])!,
                returnValue: pnl
            )
        }.sorted { $0.year < $1.year || ($0.year == $1.year && getMonthNumber($0.month) < getMonthNumber($1.month)) }
    }
    
    private func calculateAdvancedStatistics(trades: [BacktestTrade], equityCurve: [BacktestEquityPoint], candles: [HistoricalCandle]) -> BacktestStatistics {
        // Calmar Ratio
        let annualizedReturn = calculateAnnualizedReturn(equityCurve: equityCurve)
        let maxDrawdown = equityCurve.map { $0.drawdown }.max() ?? 0
        let calmarRatio = maxDrawdown > 0 ? annualizedReturn / maxDrawdown : 0
        
        // Recovery Factor
        let totalProfit = trades.filter { $0.pnl > 0 }.map { $0.pnl }.reduce(0, +)
        let recoveryFactor = maxDrawdown > 0 ? totalProfit / maxDrawdown : 0
        
        // Payoff Ratio
        let avgWin = trades.filter { $0.pnl > 0 }.map { $0.pnl }.reduce(0, +) / Double(trades.filter { $0.pnl > 0 }.count)
        let avgLoss = abs(trades.filter { $0.pnl < 0 }.map { $0.pnl }.reduce(0, +) / Double(trades.filter { $0.pnl < 0 }.count))
        let payoffRatio = avgLoss > 0 ? avgWin / avgLoss : 0
        
        // Consecutive wins/losses
        var currentWinStreak = 0
        var currentLossStreak = 0
        var maxWinStreak = 0
        var maxLossStreak = 0
        
        for trade in trades {
            if trade.pnl > 0 {
                currentWinStreak += 1
                currentLossStreak = 0
                maxWinStreak = max(maxWinStreak, currentWinStreak)
            } else {
                currentLossStreak += 1
                currentWinStreak = 0
                maxLossStreak = max(maxLossStreak, currentLossStreak)
            }
        }
        
        // Largest win/loss
        let largestWin = trades.map { $0.pnl }.max() ?? 0
        let largestLoss = trades.map { $0.pnl }.min() ?? 0
        
        // Average holding period
        let avgHoldingPeriod = trades.map { $0.holdingPeriod }.reduce(0, +) / Double(trades.count)
        
        // Exposure time
        let totalHoldingTime = trades.map { $0.holdingPeriod }.reduce(0, +)
        let totalTime = candles.last!.timestamp.timeIntervalSince(candles.first!.timestamp)
        let exposureTime = (totalHoldingTime / totalTime) * 100
        
        // Market correlation (simplified)
        let marketReturns = calculateMarketReturns(candles: candles)
        let strategyReturns = calculateStrategyReturns(trades: trades)
        let correlation = calculateCorrelation(marketReturns, strategyReturns)
        
        return BacktestStatistics(
            calmarRatio: calmarRatio,
            recoveryFactor: recoveryFactor,
            payoffRatio: payoffRatio,
            consecutiveWins: maxWinStreak,
            consecutiveLosses: maxLossStreak,
            largestWin: largestWin,
            largestLoss: largestLoss,
            averageHoldingPeriod: avgHoldingPeriod,
            exposureTime: exposureTime,
            marketCorrelation: correlation
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateRSI(prices: [Double], period: Int) -> [Double] {
        guard prices.count > period else { return Array(repeating: 50, count: prices.count) }
        
        var rsi = Array(repeating: 50.0, count: prices.count)
        var gains = [Double]()
        var losses = [Double]()
        
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            gains.append(max(0, change))
            losses.append(max(0, -change))
            
            if i >= period {
                let avgGain = gains.suffix(period).reduce(0, +) / Double(period)
                let avgLoss = losses.suffix(period).reduce(0, +) / Double(period)
                
                if avgLoss > 0 {
                    let rs = avgGain / avgLoss
                    rsi[i] = 100 - (100 / (1 + rs))
                } else {
                    rsi[i] = 100
                }
            }
        }
        
        return rsi
    }
    
    private func calculateBollingerBands(prices: [Double], period: Int, standardDeviations: Double) -> (upper: [Double], middle: [Double], lower: [Double]) {
        var upper = Array(repeating: 0.0, count: prices.count)
        var middle = Array(repeating: 0.0, count: prices.count)
        var lower = Array(repeating: 0.0, count: prices.count)
        
        for i in 0..<prices.count {
            if i >= period - 1 {
                let slice = Array(prices[(i-period+1)...i])
                let sma = slice.reduce(0, +) / Double(period)
                let variance = slice.map { pow($0 - sma, 2) }.reduce(0, +) / Double(period)
                let stdDev = sqrt(variance)
                
                middle[i] = sma
                upper[i] = sma + (stdDev * standardDeviations)
                lower[i] = sma - (stdDev * standardDeviations)
            } else {
                middle[i] = prices[i]
                upper[i] = prices[i]
                lower[i] = prices[i]
            }
        }
        
        return (upper, middle, lower)
    }
    
    private func calculateEMA(prices: [Double], period: Int) -> [Double] {
        guard !prices.isEmpty else { return [] }
        
        var ema = [Double]()
        let multiplier = 2.0 / Double(period + 1)
        
        // Start with SMA
        let sma = prices.prefix(period).reduce(0, +) / Double(period)
        ema.append(sma)
        
        // Calculate EMA for remaining prices
        for i in period..<prices.count {
            let value = (prices[i] - ema.last!) * multiplier + ema.last!
            ema.append(value)
        }
        
        // Pad the beginning
        return Array(repeating: prices.first!, count: period - 1) + ema
    }
    
    private func calculateDailyReturns(trades: [BacktestTrade], initialCapital: Double) -> [Double] {
        var dailyReturns: [Double] = []
        var equity = initialCapital
        let calendar = Calendar.current
        
        let sortedTrades = trades.sorted { $0.exitDate < $1.exitDate }
        var currentDate = calendar.startOfDay(for: sortedTrades.first?.exitDate ?? Date())
        var dailyPnL = 0.0
        
        for trade in sortedTrades {
            let tradeDate = calendar.startOfDay(for: trade.exitDate)
            
            if tradeDate > currentDate {
                // New day
                dailyReturns.append(dailyPnL / equity)
                equity += dailyPnL
                dailyPnL = trade.pnl
                currentDate = tradeDate
            } else {
                // Same day
                dailyPnL += trade.pnl
            }
        }
        
        // Add last day
        if dailyPnL != 0 {
            dailyReturns.append(dailyPnL / equity)
        }
        
        return dailyReturns
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    private func calculateAnnualizedReturn(equityCurve: [BacktestEquityPoint]) -> Double {
        guard equityCurve.count >= 2 else { return 0 }
        
        let initialValue = equityCurve.first!.value
        let finalValue = equityCurve.last!.value
        let timeSpan = equityCurve.last!.date.timeIntervalSince(equityCurve.first!.date)
        let years = timeSpan / (365.25 * 24 * 3600)
        
        return (pow(finalValue / initialValue, 1 / years) - 1) * 100
    }
    
    private func calculateMarketReturns(candles: [HistoricalCandle]) -> [Double] {
        var returns: [Double] = []
        for i in 1..<candles.count {
            let dailyReturn = (candles[i].close - candles[i-1].close) / candles[i-1].close
            returns.append(dailyReturn)
        }
        return returns
    }
    
    private func calculateStrategyReturns(trades: [BacktestTrade]) -> [Double] {
        return trades.map { $0.pnlPercentage / 100 }
    }
    
    private func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumXX = x.map { $0 * $0 }.reduce(0, +)
        let sumYY = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY))
        
        return denominator > 0 ? numerator / denominator : 0
    }
    
    private func getMonthName(_ month: Int) -> String {
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return monthNames[month - 1]
    }
    
    private func getMonthNumber(_ monthName: String) -> Int {
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return (monthNames.firstIndex(of: monthName) ?? 0) + 1
    }
}

// MARK: - Supporting Types

struct BacktestSignal {
    let timestamp: Date
    let action: TradeAction
    let price: Double
    let stopLoss: Double
    let takeProfit: Double
    let confidence: Double
}

struct OpenPosition {
    let entryDate: Date
    let entryPrice: Double
    let direction: TradeAction
    let size: Double
    let stopLoss: Double
    let takeProfit: Double
}