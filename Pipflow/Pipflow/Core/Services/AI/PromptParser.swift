//
//  PromptParser.swift
//  Pipflow
//
//  Natural Language Parsing for Trading Prompts
//

import Foundation
import NaturalLanguage

// MARK: - Prompt Parser

class PromptParser {
    private let nlProcessor = NLTagger(tagSchemes: [.nameType, .lemma, .tokenType])
    private let numberFormatter = NumberFormatter()
    
    // Regex patterns for common trading terms
    private let patterns = PromptPatterns()
    
    init() {
        numberFormatter.numberStyle = .decimal
    }
    
    // MARK: - Main Parsing Method
    
    func parsePrompt(_ prompt: String) async throws -> TradingContext {
        let lowercasedPrompt = prompt.lowercased()
        
        // Extract different components
        let capital = extractCapital(from: lowercasedPrompt)
        let riskPerTrade = extractRiskPerTrade(from: lowercasedPrompt)
        let maxOpenTrades = extractMaxOpenTrades(from: lowercasedPrompt)
        let allowedSymbols = extractAllowedSymbols(from: lowercasedPrompt)
        let excludedSymbols = extractExcludedSymbols(from: lowercasedPrompt)
        let timeRestrictions = extractTimeRestrictions(from: lowercasedPrompt)
        let indicators = extractTechnicalIndicators(from: lowercasedPrompt)
        let conditions = extractTradingConditions(from: lowercasedPrompt)
        let stopLossStrategy = extractStopLossStrategy(from: lowercasedPrompt)
        let takeProfitStrategy = extractTakeProfitStrategy(from: lowercasedPrompt)
        
        return TradingContext(
            capital: capital,
            riskPerTrade: riskPerTrade,
            maxOpenTrades: maxOpenTrades,
            allowedSymbols: allowedSymbols,
            excludedSymbols: excludedSymbols,
            timeRestrictions: timeRestrictions,
            indicators: indicators,
            conditions: conditions,
            stopLossStrategy: stopLossStrategy,
            takeProfitStrategy: takeProfitStrategy
        )
    }
    
    // MARK: - Capital Extraction
    
    private func extractCapital(from prompt: String) -> Double {
        // Look for patterns like "$500", "500 USD", "capital is 1000"
        let patterns = [
            #"\$(\d+(?:\.\d+)?)"#,  // $500, $1000.50
            #"(\d+(?:\.\d+)?)\s*(?:usd|dollars?|bucks?)"#,  // 500 USD
            #"capital\s+(?:is\s+)?(?:\$)?(\d+(?:\.\d+)?)"#,  // capital is $500
            #"budget\s+(?:is\s+)?(?:\$)?(\d+(?:\.\d+)?)"#,   // budget is 500
            #"balance\s+(?:is\s+)?(?:\$)?(\d+(?:\.\d+)?)"#   // balance is 500
        ]
        
        for pattern in patterns {
            if let match = findFirstMatch(pattern: pattern, in: prompt),
               let capitalString = match.first,
               let capital = Double(capitalString) {
                return capital
            }
        }
        
        return 1000.0 // Default capital
    }
    
    // MARK: - Risk Per Trade Extraction
    
    private func extractRiskPerTrade(from prompt: String) -> Double {
        // Look for patterns like "2% risk", "risk 1%", "use 3% per trade"
        let patterns = [
            #"risk\s+(?:per\s+trade\s+)?(?:is\s+)?(\d+(?:\.\d+)?)%"#,
            #"(\d+(?:\.\d+)?)%\s+risk"#,
            #"use\s+(\d+(?:\.\d+)?)%\s+per\s+trade"#,
            #"risk\s+(\d+(?:\.\d+)?)%\s+per"#
        ]
        
        for pattern in patterns {
            if let match = findFirstMatch(pattern: pattern, in: prompt),
               let riskString = match.first,
               let risk = Double(riskString) {
                return risk / 100.0 // Convert percentage to decimal
            }
        }
        
        return 0.02 // Default 2% risk
    }
    
    // MARK: - Max Open Trades Extraction
    
    private func extractMaxOpenTrades(from prompt: String) -> Int {
        let patterns = [
            #"max\s+(?:open\s+)?(\d+)\s+trades?"#,
            #"maximum\s+(?:of\s+)?(\d+)\s+positions?"#,
            #"limit\s+(?:to\s+)?(\d+)\s+trades?"#,
            #"only\s+(\d+)\s+trades?\s+(?:at\s+once|open)"#
        ]
        
        for pattern in patterns {
            if let match = findFirstMatch(pattern: pattern, in: prompt),
               let maxString = match.first,
               let maxTrades = Int(maxString) {
                return maxTrades
            }
        }
        
        return 5 // Default max trades
    }
    
    // MARK: - Symbol Extraction
    
    private func extractAllowedSymbols(from prompt: String) -> [String] {
        var symbols: [String] = []
        
        // Common forex pairs
        let forexPairs = ["eurusd", "gbpusd", "usdjpy", "usdchf", "audusd", "usdcad", "nzdusd", "eurjpy", "gbpjpy", "chfjpy"]
        let commodities = ["xauusd", "xagusd", "gold", "silver", "oil", "crude"]
        let cryptos = ["btcusd", "ethusd", "bitcoin", "ethereum", "btc", "eth"]
        
        let allInstruments = forexPairs + commodities + cryptos
        
        for instrument in allInstruments {
            if prompt.contains(instrument) {
                symbols.append(instrument.uppercased())
            }
        }
        
        // Look for explicit mentions
        let patterns = [
            #"only\s+trade\s+([a-zA-Z]{6,})"#,
            #"focus\s+on\s+([a-zA-Z]{3,6}/?[a-zA-Z]{3})"#,
            #"trade\s+([a-zA-Z]{6,})\s+only"#
        ]
        
        for pattern in patterns {
            if let matches = findAllMatches(pattern: pattern, in: prompt) {
                symbols.append(contentsOf: matches.map { $0.uppercased() })
            }
        }
        
        return Array(Set(symbols)) // Remove duplicates
    }
    
    private func extractExcludedSymbols(from prompt: String) -> [String] {
        var excludedSymbols: [String] = []
        
        let patterns = [
            #"don't\s+trade\s+([a-zA-Z]{6,})"#,
            #"avoid\s+([a-zA-Z]{6,})"#,
            #"exclude\s+([a-zA-Z]{6,})"#,
            #"no\s+([a-zA-Z]{6,})"#
        ]
        
        for pattern in patterns {
            if let matches = findAllMatches(pattern: pattern, in: prompt) {
                excludedSymbols.append(contentsOf: matches.map { $0.uppercased() })
            }
        }
        
        return Array(Set(excludedSymbols))
    }
    
    // MARK: - Time Restrictions Extraction
    
    private func extractTimeRestrictions(from prompt: String) -> TimeRestrictions? {
        var allowedHours: [Int] = []
        var allowedDaysOfWeek: [Int] = []
        var excludeNewsEvents = false
        var excludeMarketOpen = false
        var excludeMarketClose = false
        
        // Extract trading hours
        if prompt.contains("during market hours") || prompt.contains("trading hours only") {
            allowedHours = Array(8...17) // Standard trading hours
        }
        
        if prompt.contains("london session") {
            allowedHours = Array(8...16)
        }
        
        if prompt.contains("new york session") {
            allowedHours = Array(13...22)
        }
        
        if prompt.contains("asian session") {
            allowedHours = Array(0...9)
        }
        
        // Extract days of week
        if prompt.contains("weekdays only") || prompt.contains("monday to friday") {
            allowedDaysOfWeek = Array(1...5)
        }
        
        // Extract news restrictions
        if prompt.contains("avoid news") || prompt.contains("no news events") || prompt.contains("exclude news") {
            excludeNewsEvents = true
        }
        
        if prompt.contains("avoid market open") || prompt.contains("no market open") {
            excludeMarketOpen = true
        }
        
        if prompt.contains("avoid market close") || prompt.contains("no market close") {
            excludeMarketClose = true
        }
        
        // Return nil if no restrictions found
        if allowedHours.isEmpty && allowedDaysOfWeek.isEmpty && !excludeNewsEvents && !excludeMarketOpen && !excludeMarketClose {
            return nil
        }
        
        return TimeRestrictions(
            allowedHours: allowedHours,
            allowedDaysOfWeek: allowedDaysOfWeek,
            excludeNewsEvents: excludeNewsEvents,
            excludeMarketOpen: excludeMarketOpen,
            excludeMarketClose: excludeMarketClose
        )
    }
    
    // MARK: - Technical Indicators Extraction
    
    private func extractTechnicalIndicators(from prompt: String) -> [TechnicalIndicator] {
        var indicators: [TechnicalIndicator] = []
        
        // RSI indicators
        if prompt.contains("rsi") {
            let rsiPattern = #"rsi\s+(?:is\s+)?(?:(above|below)\s+)?(\d+)"#
            if let regex = try? NSRegularExpression(pattern: rsiPattern, options: [.caseInsensitive]) {
                let range = NSRange(prompt.startIndex..<prompt.endIndex, in: prompt)
                let matches = regex.matches(in: prompt, options: [], range: range)
                
                for match in matches {
                    var condition: TechnicalIndicator.IndicatorCondition = .above
                    var level: Double = 70
                    
                    if match.numberOfRanges >= 3 {
                        // Check for condition (above/below)
                        if let conditionRange = Range(match.range(at: 1), in: prompt) {
                            let conditionStr = String(prompt[conditionRange])
                            condition = conditionStr == "below" ? .below : .above
                        }
                        
                        // Get level value
                        if let levelRange = Range(match.range(at: 2), in: prompt) {
                            let levelStr = String(prompt[levelRange])
                            level = Double(levelStr) ?? 70
                        }
                    } else if match.numberOfRanges >= 2 {
                        // Only level value
                        if let levelRange = Range(match.range(at: 1), in: prompt) {
                            let levelStr = String(prompt[levelRange])
                            level = Double(levelStr) ?? 70
                        }
                    }
                    
                    indicators.append(TechnicalIndicator(
                        type: .rsi,
                        parameters: ["level": level, "period": 14],
                        condition: condition
                    ))
                }
            }
        }
        
        // Moving Average indicators
        if prompt.contains("moving average") || prompt.contains("ma") {
            let patterns = [
                #"(\d+)\s+(?:period\s+)?(?:moving\s+)?average"#,
                #"ma\s+(\d+)"#,
                #"sma\s+(\d+)"#,
                #"ema\s+(\d+)"#
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                    let range = NSRange(prompt.startIndex..<prompt.endIndex, in: prompt)
                    let matches = regex.matches(in: prompt, options: [], range: range)
                    
                    for match in matches {
                        if match.numberOfRanges >= 2,
                           let periodRange = Range(match.range(at: 1), in: prompt) {
                            let periodStr = String(prompt[periodRange])
                            if let period = Double(periodStr) {
                                indicators.append(TechnicalIndicator(
                                    type: .movingAverage,
                                    parameters: ["period": period],
                                    condition: .above
                                ))
                            }
                        }
                    }
                }
            }
        }
        
        // MACD indicators
        if prompt.contains("macd") {
            indicators.append(TechnicalIndicator(
                type: .macd,
                parameters: ["fast": 12, "slow": 26, "signal": 9],
                condition: .above
            ))
        }
        
        // Bollinger Bands
        if prompt.contains("bollinger") || prompt.contains("bb") {
            indicators.append(TechnicalIndicator(
                type: .bollingerBands,
                parameters: ["period": 20, "deviation": 2],
                condition: .outside
            ))
        }
        
        // Support and Resistance
        if prompt.contains("support") || prompt.contains("resistance") {
            if prompt.contains("support") {
                indicators.append(TechnicalIndicator(
                    type: .support,
                    parameters: [:],
                    condition: .above
                ))
            }
            if prompt.contains("resistance") {
                indicators.append(TechnicalIndicator(
                    type: .resistance,
                    parameters: [:],
                    condition: .below
                ))
            }
        }
        
        return indicators
    }
    
    // MARK: - Trading Conditions Extraction
    
    private func extractTradingConditions(from prompt: String) -> [TradingCondition] {
        var conditions: [TradingCondition] = []
        
        // Price action conditions
        if prompt.contains("breakout") {
            conditions.append(TradingCondition(
                type: .priceAction,
                parameters: ["type": "breakout"],
                operator: .and
            ))
        }
        
        if prompt.contains("reversal") {
            conditions.append(TradingCondition(
                type: .priceAction,
                parameters: ["type": "reversal"],
                operator: .and
            ))
        }
        
        // Volume conditions
        if prompt.contains("volume spike") || prompt.contains("high volume") {
            conditions.append(TradingCondition(
                type: .volumeSpike,
                parameters: ["threshold": "2.0"],
                operator: .and
            ))
        }
        
        // Time-based conditions
        if prompt.contains("during") {
            conditions.append(TradingCondition(
                type: .timeOfDay,
                parameters: ["session": "london"],
                operator: .and
            ))
        }
        
        return conditions
    }
    
    // MARK: - Stop Loss Strategy Extraction
    
    private func extractStopLossStrategy(from prompt: String) -> StopLossStrategy {
        // Look for percentage-based stop loss
        if let match = findFirstMatch(pattern: #"stop\s+loss\s+(?:at\s+)?(\d+(?:\.\d+)?)%"#, in: prompt),
           let percentage = Double(match.first ?? "2") {
            return .percentage(percentage / 100.0)
        }
        
        // Look for pip-based stop loss
        if let match = findFirstMatch(pattern: #"stop\s+loss\s+(?:at\s+)?(\d+)\s+pips?"#, in: prompt),
           let pips = Double(match.first ?? "20") {
            return .fixedPips(pips)
        }
        
        // Look for ATR-based stop loss
        if prompt.contains("atr stop") || prompt.contains("atr based") {
            return .atr(2.0) // Default 2x ATR
        }
        
        // Look for support/resistance based
        if prompt.contains("support") && prompt.contains("stop") {
            return .supportResistance
        }
        
        // No stop loss mentioned
        if prompt.contains("no stop") || prompt.contains("without stop") {
            return .none
        }
        
        return .percentage(0.02) // Default 2%
    }
    
    // MARK: - Take Profit Strategy Extraction
    
    private func extractTakeProfitStrategy(from prompt: String) -> TakeProfitStrategy {
        // Look for risk-reward ratio
        if let match = findFirstMatch(pattern: #"(?:risk\s+reward|rr)\s+(?:ratio\s+)?(?:of\s+)?1:(\d+(?:\.\d+)?)"#, in: prompt),
           let ratio = Double(match.first ?? "2") {
            return .riskReward(ratio)
        }
        
        // Look for percentage-based take profit
        if let match = findFirstMatch(pattern: #"take\s+profit\s+(?:at\s+)?(\d+(?:\.\d+)?)%"#, in: prompt),
           let percentage = Double(match.first ?? "4") {
            return .percentage(percentage / 100.0)
        }
        
        // Look for pip-based take profit
        if let match = findFirstMatch(pattern: #"take\s+profit\s+(?:at\s+)?(\d+)\s+pips?"#, in: prompt),
           let pips = Double(match.first ?? "40") {
            return .fixedPips(pips)
        }
        
        // Look for trailing take profit
        if prompt.contains("trailing") {
            return .trailing(0.5) // Default 0.5% trailing
        }
        
        // No take profit mentioned
        if prompt.contains("no take profit") || prompt.contains("let it run") {
            return .none
        }
        
        return .riskReward(2.0) // Default 1:2 risk-reward
    }
    
    // MARK: - Helper Methods
    
    private func findFirstMatch(pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        var results: [String] = []
        for i in 1..<match.numberOfRanges {
            let matchRange = match.range(at: i)
            if matchRange.location != NSNotFound,
               let range = Range(matchRange, in: text) {
                results.append(String(text[range]))
            }
        }
        
        return results.isEmpty ? nil : results
    }
    
    private func findAllMatches(pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        var allResults: [String] = []
        for match in matches {
            for i in 1..<match.numberOfRanges {
                let matchRange = match.range(at: i)
                if matchRange.location != NSNotFound,
                   let range = Range(matchRange, in: text) {
                    allResults.append(String(text[range]))
                }
            }
        }
        
        return allResults.isEmpty ? nil : allResults
    }
}

// MARK: - Prompt Patterns

struct PromptPatterns {
    // Common trading symbols and their variations
    static let forexPairs = [
        "eurusd": "EURUSD", "eur/usd": "EURUSD", "euro dollar": "EURUSD",
        "gbpusd": "GBPUSD", "gbp/usd": "GBPUSD", "pound dollar": "GBPUSD", "cable": "GBPUSD",
        "usdjpy": "USDJPY", "usd/jpy": "USDJPY", "dollar yen": "USDJPY",
        "usdchf": "USDCHF", "usd/chf": "USDCHF", "dollar swiss": "USDCHF",
        "audusd": "AUDUSD", "aud/usd": "AUDUSD", "aussie dollar": "AUDUSD",
        "usdcad": "USDCAD", "usd/cad": "USDCAD", "dollar cad": "USDCAD",
        "nzdusd": "NZDUSD", "nzd/usd": "NZDUSD", "kiwi dollar": "NZDUSD"
    ]
    
    static let commodities = [
        "xauusd": "XAUUSD", "gold": "XAUUSD", "gold/usd": "XAUUSD",
        "xagusd": "XAGUSD", "silver": "XAGUSD", "silver/usd": "XAGUSD",
        "oil": "CRUDE", "crude": "CRUDE", "wti": "CRUDE"
    ]
    
    static let cryptos = [
        "btcusd": "BTCUSD", "bitcoin": "BTCUSD", "btc": "BTCUSD",
        "ethusd": "ETHUSD", "ethereum": "ETHUSD", "eth": "ETHUSD"
    ]
    
    // Common trading terms and their meanings
    static let tradingTerms = [
        "bullish": "buy bias",
        "bearish": "sell bias",
        "long": "buy",
        "short": "sell",
        "breakout": "price breaks resistance/support",
        "reversal": "price changes direction",
        "pullback": "temporary price retracement",
        "consolidation": "sideways price movement"
    ]
    
    // Risk management terms
    static let riskTerms = [
        "conservative": "1% risk",
        "moderate": "2% risk",
        "aggressive": "5% risk",
        "tight stop": "1% stop loss",
        "wide stop": "3% stop loss"
    ]
    
    // Time session mappings
    static let tradingSessions = [
        "london": (8, 16),
        "new york": (13, 22),
        "asian": (0, 9),
        "sydney": (22, 6),
        "tokyo": (0, 9)
    ]
}

// MARK: - Prompt Examples
// Using PromptExamples from PromptModels.swift

// MARK: - Prompt Validation

extension PromptParser {
    func validateParsedContext(_ context: TradingContext) -> (isValid: Bool, warnings: [String]) {
        var warnings: [String] = []
        
        // Validate capital
        if context.capital < 100 {
            warnings.append("Capital below $100 may not be suitable for trading")
        }
        
        // Validate risk
        if context.riskPerTrade > 0.1 {
            warnings.append("Risk per trade above 10% is extremely risky")
        }
        
        if context.riskPerTrade < 0.005 {
            warnings.append("Risk per trade below 0.5% may limit profit potential")
        }
        
        // Validate max trades
        if context.maxOpenTrades > 20 {
            warnings.append("More than 20 open trades may be difficult to manage")
        }
        
        // Validate indicators
        if context.indicators.count > 5 {
            warnings.append("Using too many indicators may lead to conflicting signals")
        }
        
        return (warnings.count < 3, warnings) // Valid if less than 3 warnings
    }
}