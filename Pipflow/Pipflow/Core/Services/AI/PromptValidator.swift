//
//  PromptValidator.swift
//  Pipflow
//
//  Safety validation for AI trading prompts and decisions
//

import Foundation

// MARK: - Validation Models

struct AIPromptValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
    let riskLevel: RiskLevel
    let recommendations: [String]
    
    enum RiskLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .extreme: return "red"
            }
        }
    }
}

struct SafetyRule {
    let id: String
    let name: String
    let description: String
    let category: SafetyCategory
    let severity: RuleSeverity
    let isEnabled: Bool
    let validator: (TradingContext) -> ValidationIssue?
    
    enum SafetyCategory: String, CaseIterable {
        case riskManagement = "Risk Management"
        case capitalProtection = "Capital Protection"
        case marketConditions = "Market Conditions"
        case technicalAnalysis = "Technical Analysis"
        case timeRestrictions = "Time Restrictions"
        case regulatory = "Regulatory"
    }
    
    enum RuleSeverity: String, CaseIterable {
        case error = "Error"      // Blocks execution
        case warning = "Warning"  // Shows warning but allows
        case info = "Info"        // Informational only
    }
}

struct ValidationIssue {
    let ruleId: String
    let severity: SafetyRule.RuleSeverity
    let message: String
    let suggestion: String?
    let affectedParameter: String?
}

// MARK: - Prompt Validator

class PromptValidator {
    private var safetyRules: [SafetyRule] = []
    private let riskCalculator = RiskCalculator()
    private let marketValidator = MarketValidator()
    
    init() {
        setupDefaultSafetyRules()
    }
    
    // MARK: - Main Validation Methods
    
    func validatePrompt(_ prompt: String) async -> AIPromptValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        var recommendations: [String] = []
        
        // Basic prompt validation
        if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Prompt cannot be empty")
            return AIPromptValidationResult(isValid: false, errors: errors, warnings: warnings, riskLevel: .extreme, recommendations: recommendations)
        }
        
        if prompt.count < 10 {
            warnings.append("Prompt is very short. Consider adding more detail about your trading strategy.")
        }
        
        if prompt.count > 2000 {
            warnings.append("Prompt is very long. Consider breaking it into simpler conditions.")
        }
        
        // Check for dangerous keywords
        let dangerousKeywords = ["guaranteed", "risk-free", "100% profit", "never lose", "unlimited profit"]
        for keyword in dangerousKeywords {
            if prompt.lowercased().contains(keyword) {
                errors.append("Prompt contains unrealistic claims: '\(keyword)'. No trading strategy is guaranteed.")
            }
        }
        
        // Check for missing essential information
        if !containsCapitalInfo(prompt) {
            warnings.append("Consider specifying your capital amount for better position sizing.")
        }
        
        if !containsRiskInfo(prompt) {
            warnings.append("Consider specifying your risk tolerance (e.g., '2% per trade').")
        }
        
        if !containsStopLossInfo(prompt) {
            warnings.append("Consider adding stop loss strategy for risk management.")
        }
        
        // Generate recommendations
        recommendations.append(contentsOf: generatePromptRecommendations(prompt))
        
        let riskLevel = calculatePromptRiskLevel(prompt)
        return AIPromptValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            riskLevel: riskLevel,
            recommendations: recommendations
        )
    }
    
    func validateTradingContext(_ context: TradingContext) async -> AIPromptValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        var recommendations: [String] = []
        
        // Run all safety rules
        for rule in safetyRules where rule.isEnabled {
            if let issue = rule.validator(context) {
                switch issue.severity {
                case .error:
                    errors.append(issue.message)
                case .warning:
                    warnings.append(issue.message)
                case .info:
                    recommendations.append(issue.message)
                }
                
                if let suggestion = issue.suggestion {
                    recommendations.append(suggestion)
                }
            }
        }
        
        let riskLevel = riskCalculator.calculateOverallRisk(context)
        return AIPromptValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            riskLevel: riskLevel,
            recommendations: recommendations
        )
    }
    
    func validateTradeDecision(_ decision: AITradeDecision, context: TradingContext) async -> Bool {
        // Critical safety checks for trade execution
        
        // Check if symbol is allowed
        if !context.allowedSymbols.isEmpty && !context.allowedSymbols.contains(decision.symbol) {
            print("🛡️ Trade blocked: Symbol \(decision.symbol) not in allowed list")
            return false
        }
        
        // Check if symbol is excluded
        if context.excludedSymbols.contains(decision.symbol) {
            print("🛡️ Trade blocked: Symbol \(decision.symbol) is excluded")
            return false
        }
        
        // Check position size limits
        let positionSize = calculatePositionSize(decision, context: context)
        if positionSize > context.capital * 0.1 { // Max 10% of capital per trade
            print("🛡️ Trade blocked: Position size too large")
            return false
        }
        
        // Check risk per trade
        if let stopLoss = decision.stopLoss {
            let riskAmount = abs(decision.entryPrice - stopLoss) * positionSize
            let riskPercentage = riskAmount / context.capital
            if riskPercentage > context.riskPerTrade * 1.5 { // Allow 50% variance
                print("🛡️ Trade blocked: Risk exceeds limit")
                return false
            }
        }
        
        // Check confidence threshold
        if decision.confidence < 0.6 {
            print("🛡️ Trade blocked: AI confidence too low (\(decision.confidence))")
            return false
        }
        
        // Check market conditions
        if await !marketValidator.isMarketSuitableForTrading(symbol: decision.symbol) {
            print("🛡️ Trade blocked: Unfavorable market conditions")
            return false
        }
        
        return true
    }
    
    // MARK: - Safety Rules Setup
    
    private func setupDefaultSafetyRules() {
        safetyRules = [
            // Risk Management Rules
            SafetyRule(
                id: "max_risk_per_trade",
                name: "Maximum Risk Per Trade",
                description: "Risk per trade should not exceed 10%",
                category: .riskManagement,
                severity: .error,
                isEnabled: true,
                validator: { context in
                    if context.riskPerTrade > 0.1 {
                        return ValidationIssue(
                            ruleId: "max_risk_per_trade",
                            severity: .error,
                            message: "Risk per trade (\(context.riskPerTrade * 100)%) exceeds maximum allowed (10%)",
                            suggestion: "Consider reducing risk to 2-5% per trade",
                            affectedParameter: "riskPerTrade"
                        )
                    }
                    return nil
                }
            ),
            
            SafetyRule(
                id: "min_capital",
                name: "Minimum Capital",
                description: "Capital should be at least $100",
                category: .capitalProtection,
                severity: .warning,
                isEnabled: true,
                validator: { context in
                    if context.capital < 100 {
                        return ValidationIssue(
                            ruleId: "min_capital",
                            severity: .warning,
                            message: "Capital below $100 may not be suitable for active trading",
                            suggestion: "Consider starting with a higher capital amount",
                            affectedParameter: "capital"
                        )
                    }
                    return nil
                }
            ),
            
            SafetyRule(
                id: "max_open_positions",
                name: "Maximum Open Positions",
                description: "Should not exceed 20 open positions",
                category: .riskManagement,
                severity: .warning,
                isEnabled: true,
                validator: { context in
                    if context.maxOpenTrades > 20 {
                        return ValidationIssue(
                            ruleId: "max_open_positions",
                            severity: .warning,
                            message: "More than 20 open positions may be difficult to manage",
                            suggestion: "Consider limiting to 5-10 positions for better management",
                            affectedParameter: "maxOpenTrades"
                        )
                    }
                    return nil
                }
            ),
            
            SafetyRule(
                id: "stop_loss_required",
                name: "Stop Loss Required",
                description: "All strategies should include stop loss",
                category: .riskManagement,
                severity: .warning,
                isEnabled: true,
                validator: { context in
                    if case .none = context.stopLossStrategy {
                        return ValidationIssue(
                            ruleId: "stop_loss_required",
                            severity: .warning,
                            message: "No stop loss strategy defined",
                            suggestion: "Consider adding stop loss for risk management",
                            affectedParameter: "stopLossStrategy"
                        )
                    }
                    return nil
                }
            ),
            
            SafetyRule(
                id: "indicator_overload",
                name: "Indicator Overload",
                description: "Too many indicators can cause conflicting signals",
                category: .technicalAnalysis,
                severity: .warning,
                isEnabled: true,
                validator: { context in
                    if context.indicators.count > 5 {
                        return ValidationIssue(
                            ruleId: "indicator_overload",
                            severity: .warning,
                            message: "Using \(context.indicators.count) indicators may cause conflicting signals",
                            suggestion: "Consider focusing on 2-3 key indicators",
                            affectedParameter: "indicators"
                        )
                    }
                    return nil
                }
            ),
            
            SafetyRule(
                id: "time_restrictions",
                name: "Time Restrictions",
                description: "Validate trading time restrictions",
                category: .timeRestrictions,
                severity: .info,
                isEnabled: true,
                validator: { context in
                    if let timeRestrictions = context.timeRestrictions {
                        if timeRestrictions.allowedHours.isEmpty && timeRestrictions.allowedDaysOfWeek.isEmpty {
                            return ValidationIssue(
                                ruleId: "time_restrictions",
                                severity: .info,
                                message: "Time restrictions defined but no specific hours or days set",
                                suggestion: "Consider specifying trading hours or days",
                                affectedParameter: "timeRestrictions"
                            )
                        }
                    }
                    return nil
                }
            )
        ]
    }
    
    // MARK: - Helper Methods
    
    private func containsCapitalInfo(_ prompt: String) -> Bool {
        let capitalPatterns = ["capital", "balance", "budget", "$", "usd", "dollars"]
        return capitalPatterns.contains { prompt.lowercased().contains($0) }
    }
    
    private func containsRiskInfo(_ prompt: String) -> Bool {
        let riskPatterns = ["risk", "%", "percent"]
        return riskPatterns.contains { prompt.lowercased().contains($0) }
    }
    
    private func containsStopLossInfo(_ prompt: String) -> Bool {
        return prompt.lowercased().contains("stop") || 
               prompt.lowercased().contains("sl") ||
               prompt.lowercased().contains("loss")
    }
    
    private func calculatePromptRiskLevel(_ prompt: String) -> AIPromptValidationResult.RiskLevel {
        let prompt = prompt.lowercased()
        
        // High risk indicators
        let highRiskTerms = ["aggressive", "high risk", "maximum", "all in", "leverage"]
        if highRiskTerms.contains(where: { prompt.contains($0) }) {
            return .high
        }
        
        // Low risk indicators
        let lowRiskTerms = ["conservative", "safe", "low risk", "careful", "cautious"]
        if lowRiskTerms.contains(where: { prompt.contains($0) }) {
            return .low
        }
        
        return .medium
    }
    
    private func generatePromptRecommendations(_ prompt: String) -> [String] {
        var recommendations: [String] = []
        
        if !containsCapitalInfo(prompt) {
            recommendations.append("Specify your trading capital (e.g., 'My capital is $1000')")
        }
        
        if !containsRiskInfo(prompt) {
            recommendations.append("Define your risk per trade (e.g., 'Risk 2% per trade')")
        }
        
        if !prompt.lowercased().contains("symbol") && !prompt.lowercased().contains("eur") && !prompt.lowercased().contains("gold") {
            recommendations.append("Specify which instruments to trade (e.g., 'Trade EUR/USD only')")
        }
        
        if !containsStopLossInfo(prompt) {
            recommendations.append("Include stop loss strategy (e.g., 'Use 2% stop loss')")
        }
        
        return recommendations
    }
    
    private func calculatePositionSize(_ decision: AITradeDecision, context: TradingContext) -> Double {
        // Simplified position size calculation
        let riskAmount = context.capital * context.riskPerTrade
        
        guard let stopLoss = decision.stopLoss else {
            return riskAmount / 100000 // Default to small position
        }
        
        let pipRisk = abs(decision.entryPrice - stopLoss) * 10000
        guard pipRisk > 0 else { return 0.01 }
        
        let pipValue = 10.0 // USD per pip for standard lot
        let positionSize = riskAmount / (pipRisk * pipValue)
        
        return max(0.01, min(positionSize, 10.0)) // Between 0.01 and 10 lots
    }
    
    // MARK: - Rule Management
    
    func enableRule(_ ruleId: String) {
        if let index = safetyRules.firstIndex(where: { $0.id == ruleId }) {
            let rule = safetyRules[index]
            let updatedRule = SafetyRule(
                id: rule.id,
                name: rule.name,
                description: rule.description,
                category: rule.category,
                severity: rule.severity,
                isEnabled: true,
                validator: rule.validator
            )
            safetyRules[index] = updatedRule
        }
    }
    
    func disableRule(_ ruleId: String) {
        if let index = safetyRules.firstIndex(where: { $0.id == ruleId }) {
            let rule = safetyRules[index]
            let updatedRule = SafetyRule(
                id: rule.id,
                name: rule.name,
                description: rule.description,
                category: rule.category,
                severity: rule.severity,
                isEnabled: false,
                validator: rule.validator
            )
            safetyRules[index] = updatedRule
        }
    }
    
    func getAllRules() -> [SafetyRule] {
        return safetyRules
    }
    
    func getRulesByCategory(_ category: SafetyRule.SafetyCategory) -> [SafetyRule] {
        return safetyRules.filter { $0.category == category }
    }
}

// MARK: - Risk Calculator

class RiskCalculator {
    func calculateOverallRisk(_ context: TradingContext) -> AIPromptValidationResult.RiskLevel {
        var riskScore = 0.0
        
        // Risk per trade scoring
        if context.riskPerTrade <= 0.01 { riskScore += 1 }
        else if context.riskPerTrade <= 0.02 { riskScore += 2 }
        else if context.riskPerTrade <= 0.05 { riskScore += 3 }
        else { riskScore += 5 }
        
        // Maximum open trades scoring
        if context.maxOpenTrades <= 3 { riskScore += 1 }
        else if context.maxOpenTrades <= 5 { riskScore += 2 }
        else if context.maxOpenTrades <= 10 { riskScore += 3 }
        else { riskScore += 4 }
        
        // Stop loss strategy scoring
        switch context.stopLossStrategy {
        case .none: riskScore += 5
        case .percentage(let pct) where pct > 0.05: riskScore += 3
        case .percentage(_): riskScore += 1
        case .atr(_), .supportResistance: riskScore += 2
        case .fixedPips(_): riskScore += 2
        }
        
        // Capital scoring
        if context.capital < 500 { riskScore += 2 }
        else if context.capital < 1000 { riskScore += 1 }
        
        // Convert score to risk level
        if riskScore <= 4 { return .low }
        else if riskScore <= 7 { return .medium }
        else if riskScore <= 10 { return .high }
        else { return .extreme }
    }
    
    func calculatePortfolioRisk(_ contexts: [TradingContext]) -> Double {
        // Calculate overall portfolio risk across multiple trading contexts
        let totalCapital = contexts.reduce(0) { $0 + $1.capital }
        let totalRisk = contexts.reduce(0) { total, context in
            total + (context.capital * context.riskPerTrade * Double(context.maxOpenTrades))
        }
        
        return totalCapital > 0 ? totalRisk / totalCapital : 0
    }
}

// MARK: - Market Validator

class MarketValidator {
    func isMarketSuitableForTrading(symbol: String) async -> Bool {
        // Check market conditions
        
        // Check if market is open
        let isMarketOpen = await checkMarketHours(for: symbol)
        guard isMarketOpen else { return false }
        
        // Check volatility levels
        let volatility = await getVolatility(for: symbol)
        if volatility > 3.0 { // Too volatile
            return false
        }
        
        // Check spread levels
        let spread = await getSpread(for: symbol)
        if spread > 5.0 { // Spread too wide
            return false
        }
        
        return true
    }
    
    private func checkMarketHours(for symbol: String) async -> Bool {
        // Simplified market hours check
        let hour = Calendar.current.component(.hour, from: Date())
        
        if symbol.contains("USD") {
            return hour >= 0 && hour <= 23 // Forex trades 24/5
        }
        
        return hour >= 9 && hour <= 17 // Stock market hours
    }
    
    private func getVolatility(for symbol: String) async -> Double {
        // Mock volatility calculation
        return Double.random(in: 0.5...2.5)
    }
    
    private func getSpread(for symbol: String) async -> Double {
        // Mock spread calculation
        return Double.random(in: 0.5...3.0)
    }
}

// MARK: - Validation Extensions

extension TradingContext {
    var riskAssessment: String {
        let validator = PromptValidator()
        let riskLevel = RiskCalculator().calculateOverallRisk(self)
        
        switch riskLevel {
        case .low: return "Conservative approach with low risk"
        case .medium: return "Balanced risk/reward strategy"
        case .high: return "Aggressive strategy with higher risk"
        case .extreme: return "Very high risk - exercise caution"
        }
    }
}