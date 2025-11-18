//
//  NaturalLanguageStrategyParser.swift
//  Pipflow
//
//  Natural language to strategy component parser
//

import Foundation
import NaturalLanguage
import Combine

@MainActor
class NaturalLanguageStrategyParser: ObservableObject {
    static let shared = NaturalLanguageStrategyParser()
    
    @Published var isProcessing = false
    @Published var parseError: String?
    
    private let aiSignalService = AISignalService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Pattern Definitions
    
    private let entryPatterns = [
        "when (.+) crosses above (.+)": EntryCondition.crossAbove,
        "when (.+) crosses below (.+)": EntryCondition.crossBelow,
        "when (.+) is above (.+)": EntryCondition.above,
        "when (.+) is below (.+)": EntryCondition.below,
        "when RSI is oversold": EntryCondition.rsiOversold,
        "when RSI is overbought": EntryCondition.rsiOverbought,
        "when MACD crosses signal": EntryCondition.macdCross,
        "at (.+) time": EntryCondition.timeFilter,
        "when (.+) pattern forms": EntryCondition.pattern,
        "buy when (.+)": EntryCondition.buyCondition,
        "sell when (.+)": EntryCondition.sellCondition
    ]
    
    private let exitPatterns = [
        "stop loss at (.+) pips": ExitCondition.fixedStopLoss,
        "take profit at (.+) pips": ExitCondition.fixedTakeProfit,
        "trailing stop (.+) pips": ExitCondition.trailingStop,
        "exit after (.+) hours": ExitCondition.timeExit,
        "exit when (.+)": ExitCondition.conditionalExit,
        "risk reward (.+):(.+)": ExitCondition.riskReward
    ]
    
    private let riskPatterns = [
        "risk (.+)% per trade": RiskRule.riskPerTrade,
        "max (.+) positions": RiskRule.maxPositions,
        "max drawdown (.+)%": RiskRule.maxDrawdown,
        "position size (.+) lots": RiskRule.fixedLots,
        "kelly criterion": RiskRule.kellyCriterion
    ]
    
    // MARK: - Parse Strategy
    
    func parseStrategy(from text: String) async throws -> ParsedStrategy {
        isProcessing = true
        parseError = nil
        
        defer { isProcessing = false }
        
        // Tokenize and analyze
        let tokens = tokenize(text)
        let intent = detectIntent(from: tokens)
        
        // Extract components
        let entryConditions = extractEntryConditions(from: text)
        let exitConditions = extractExitConditions(from: text)
        let riskRules = extractRiskRules(from: text)
        let timeframe = extractTimeframe(from: text)
        let symbols = extractSymbols(from: text)
        
        // Use AI to enhance understanding
        let aiEnhanced = try await enhanceWithAI(
            text: text,
            intent: intent,
            conditions: entryConditions + exitConditions
        )
        
        return ParsedStrategy(
            originalText: text,
            intent: intent,
            entryConditions: entryConditions,
            exitConditions: exitConditions,
            riskRules: riskRules,
            timeframe: timeframe,
            symbols: symbols,
            components: aiEnhanced.components,
            confidence: aiEnhanced.confidence
        )
    }
    
    // MARK: - Component Extraction
    
    private func extractEntryConditions(from text: String) -> [StrategyCondition] {
        var conditions: [StrategyCondition] = []
        
        for (pattern, conditionType) in entryPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    var params: [String] = []
                    for i in 1..<match.numberOfRanges {
                        if let range = Range(match.range(at: i), in: text) {
                            params.append(String(text[range]))
                        }
                    }
                    
                    conditions.append(StrategyCondition(
                        type: .entry(conditionType),
                        parameters: params,
                        logicOperator: .and
                    ))
                }
            }
        }
        
        return conditions
    }
    
    private func extractExitConditions(from text: String) -> [StrategyCondition] {
        var conditions: [StrategyCondition] = []
        
        for (pattern, conditionType) in exitPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    var params: [String] = []
                    for i in 1..<match.numberOfRanges {
                        if let range = Range(match.range(at: i), in: text) {
                            params.append(String(text[range]))
                        }
                    }
                    
                    conditions.append(StrategyCondition(
                        type: .exit(conditionType),
                        parameters: params,
                        logicOperator: .or
                    ))
                }
            }
        }
        
        return conditions
    }
    
    private func extractRiskRules(from text: String) -> [RiskCondition] {
        var rules: [RiskCondition] = []
        
        for (pattern, ruleType) in riskPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    var params: [String] = []
                    for i in 1..<match.numberOfRanges {
                        if let range = Range(match.range(at: i), in: text) {
                            params.append(String(text[range]))
                        }
                    }
                    
                    rules.append(RiskCondition(
                        type: ruleType,
                        value: Double(params.first ?? "0") ?? 0
                    ))
                }
            }
        }
        
        // Add defaults if missing
        if !rules.contains(where: { $0.type == .riskPerTrade }) {
            rules.append(RiskCondition(type: .riskPerTrade, value: 1.0))
        }
        if !rules.contains(where: { $0.type == .maxPositions }) {
            rules.append(RiskCondition(type: .maxPositions, value: 3))
        }
        
        return rules
    }
    
    private func extractTimeframe(from text: String) -> Timeframe {
        let timeframes: [(String, Timeframe)] = [
            ("1 minute", .m1),
            ("5 minute", .m5),
            ("15 minute", .m15),
            ("30 minute", .m30),
            ("1 hour", .h1),
            ("4 hour", .h4),
            ("daily", .d1),
            ("weekly", .w1),
            ("monthly", .mn1),
            ("m1", .m1),
            ("m5", .m5),
            ("m15", .m15),
            ("m30", .m30),
            ("h1", .h1),
            ("h4", .h4),
            ("d1", .d1)
        ]
        
        let lowercased = text.lowercased()
        for (pattern, timeframe) in timeframes {
            if lowercased.contains(pattern) {
                return timeframe
            }
        }
        
        return .h1 // Default
    }
    
    private func extractSymbols(from text: String) -> [String] {
        let commonSymbols = [
            "EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "USDCAD", "NZDUSD",
            "EURJPY", "GBPJPY", "EURGBP", "XAUUSD", "XAGUSD", "BTCUSD", "ETHUSD"
        ]
        
        var symbols: [String] = []
        let uppercased = text.uppercased()
        
        for symbol in commonSymbols {
            if uppercased.contains(symbol) {
                symbols.append(symbol)
            }
        }
        
        // If no symbols found, default to EURUSD
        if symbols.isEmpty {
            symbols = ["EURUSD"]
        }
        
        return symbols
    }
    
    // MARK: - NLP Processing
    
    private func tokenize(_ text: String) -> [Token] {
        var tokens: [Token] = []
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            let word = String(text[tokenRange])
            let lemma = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma).0?.rawValue ?? word
            
            tokens.append(Token(
                text: word,
                lemma: lemma,
                type: tag ?? .other,
                range: tokenRange
            ))
            
            return true
        }
        
        return tokens
    }
    
    private func detectIntent(from tokens: [Token]) -> StrategyIntent {
        let verbs = tokens.filter { $0.type == .verb }.map { $0.lemma.lowercased() }
        
        if verbs.contains(where: { ["buy", "long", "purchase"].contains($0) }) {
            return .long
        } else if verbs.contains(where: { ["sell", "short"].contains($0) }) {
            return .short
        } else if verbs.contains(where: { ["hedge", "protect"].contains($0) }) {
            return .hedge
        } else {
            return .both
        }
    }
    
    // MARK: - AI Enhancement
    
    private func enhanceWithAI(text: String, intent: StrategyIntent, conditions: [StrategyCondition]) async throws -> AIEnhancement {
        let prompt = """
        Analyze this trading strategy and extract components:
        
        Text: "\(text)"
        Detected Intent: \(intent)
        Detected Conditions: \(conditions.count)
        
        Please identify:
        1. Entry conditions with specific parameters
        2. Exit conditions (stop loss, take profit)
        3. Risk management rules
        4. Any indicators mentioned with their settings
        5. Time filters or market conditions
        
        Return as structured components for a strategy builder.
        """
        
        // Use AI to enhance understanding  
        let marketData = MarketData(
            currentPrice: 1.1000,
            high24h: 1.1050,
            low24h: 1.0950,
            volume24h: 1000000,
            priceChange24h: 0.0050,
            bid: 1.0999,
            ask: 1.1001,
            spread: 0.0002
        )
        
        let technicalIndicators = TechnicalIndicators(
            rsi: 55.0,
            macd: MACDIndicator(macd: 0.0012, signal: 0.0010, histogram: 0.0002),
            movingAverages: MovingAverages(ma20: 1.0995, ma50: 1.0980, ma200: 1.0970),
            support: 1.0950,
            resistance: 1.1050,
            trend: .bullish
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            aiSignalService.generateSignal(
                for: "EURUSD",
                timeframe: "H1",
                marketData: marketData,
                technicalIndicators: technicalIndicators,
                recentNews: nil,
                provider: .claude
            )
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { signal in
                    // Parse AI response into components
                    let components = self.parseAIResponse(signal.rationale)
                    
                    let enhancement = AIEnhancement(
                        components: components,
                        confidence: signal.confidence
                    )
                    continuation.resume(returning: enhancement)
                }
            )
            .store(in: &cancellables)
        }
    }
    
    private func parseAIResponse(_ analysis: String) -> [StrategyComponent] {
        // In production, parse the AI response more thoroughly
        // For now, return empty array
        return []
    }
}

// MARK: - Models

struct ParsedStrategy {
    let originalText: String
    let intent: StrategyIntent
    let entryConditions: [StrategyCondition]
    let exitConditions: [StrategyCondition]
    let riskRules: [RiskCondition]
    let timeframe: Timeframe
    let symbols: [String]
    let components: [StrategyComponent]
    let confidence: Double
}

struct StrategyCondition: Codable {
    let type: ConditionType
    let parameters: [String]
    let logicOperator: LogicOperator
}

struct RiskCondition {
    let type: RiskRule
    let value: Double
}

struct Token {
    let text: String
    let lemma: String
    let type: NLTag
    let range: Range<String.Index>
}

struct AIEnhancement {
    let components: [StrategyComponent]
    let confidence: Double
}

// MARK: - Enums

enum StrategyIntent {
    case long
    case short
    case both
    case hedge
}

enum ConditionType: Codable {
    case entry(EntryCondition)
    case exit(ExitCondition)
}

enum EntryCondition: String, Codable {
    case crossAbove
    case crossBelow
    case above
    case below
    case rsiOversold
    case rsiOverbought
    case macdCross
    case timeFilter
    case pattern
    case buyCondition
    case sellCondition
}

enum ExitCondition: String, Codable {
    case fixedStopLoss
    case fixedTakeProfit
    case trailingStop
    case timeExit
    case conditionalExit
    case riskReward
}

enum RiskRule {
    case riskPerTrade
    case maxPositions
    case maxDrawdown
    case fixedLots
    case kellyCriterion
}

enum LogicOperator: Codable {
    case and
    case or
    case not
}