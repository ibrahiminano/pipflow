//
//  RiskScoreCalculator.swift
//  Pipflow
//
//  Advanced risk score calculation for traders based on multiple factors
//

import Foundation
import Combine

class RiskScoreCalculator {
    
    // MARK: - Risk Factors
    
    struct RiskFactors {
        let drawdownRisk: Double      // 0-10: Based on max drawdown
        let volatilityRisk: Double    // 0-10: Based on return volatility
        let concentrationRisk: Double // 0-10: Based on position/symbol concentration
        let leverageRisk: Double      // 0-10: Based on average leverage used
        let frequencyRisk: Double     // 0-10: Based on trading frequency
        let consistencyRisk: Double   // 0-10: Based on consistency of returns
    }
    
    struct RiskMetrics {
        let maxDrawdown: Double
        let volatility: Double
        let sharpeRatio: Double
        let calmarRatio: Double
        let averageLeverage: Double
        let positionConcentration: Double
        let winRateConsistency: Double
        let returnConsistency: Double
    }
    
    // MARK: - Public Methods
    
    func calculateRiskScore(for trader: Trader, positions: [TrackedPosition]? = nil) -> Int {
        let metrics = calculateRiskMetrics(for: trader, positions: positions)
        let factors = calculateRiskFactors(from: metrics)
        
        // Weighted average of risk factors
        let weightedScore = (
            factors.drawdownRisk * 0.25 +      // 25% weight
            factors.volatilityRisk * 0.20 +    // 20% weight
            factors.concentrationRisk * 0.15 + // 15% weight
            factors.leverageRisk * 0.20 +      // 20% weight
            factors.frequencyRisk * 0.10 +     // 10% weight
            factors.consistencyRisk * 0.10     // 10% weight
        )
        
        // Round to nearest integer (1-10)
        return max(1, min(10, Int(round(weightedScore))))
    }
    
    func calculateDetailedRiskAnalysis(for trader: Trader, positions: [TrackedPosition]? = nil) -> TraderRiskAnalysis {
        let metrics = calculateRiskMetrics(for: trader, positions: positions)
        let factors = calculateRiskFactors(from: metrics)
        let overallScore = calculateRiskScore(for: trader, positions: positions)
        
        return TraderRiskAnalysis(
            overallScore: overallScore,
            factors: factors,
            metrics: metrics,
            recommendations: generateRiskRecommendations(factors: factors, score: overallScore),
            strengths: identifyStrengths(factors: factors, metrics: metrics),
            weaknesses: identifyWeaknesses(factors: factors, metrics: metrics)
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateRiskMetrics(for trader: Trader, positions: [TrackedPosition]?) -> RiskMetrics {
        let performance = trader.performance
        
        // Calculate max drawdown
        let maxDrawdown = performance.maxDrawdown
        
        // Calculate return volatility
        let returns = performance.dailyReturns.map { $0.returnPercentage }
        let volatility = calculateVolatility(returns: returns)
        
        // Calculate Sharpe ratio
        let sharpeRatio = performance.sharpeRatio
        
        // Calculate Calmar ratio (annual return / max drawdown)
        let calmarRatio = maxDrawdown > 0 ? trader.yearlyReturn / maxDrawdown : 0
        
        // Calculate average leverage from positions
        let averageLeverage = calculateAverageLeverage(trader: trader, positions: positions)
        
        // Calculate position concentration
        let concentration = calculatePositionConcentration(trader: trader, positions: positions)
        
        // Calculate consistency metrics
        let winRateConsistency = calculateWinRateConsistency(performance: performance)
        let returnConsistency = calculateReturnConsistency(performance: performance)
        
        return RiskMetrics(
            maxDrawdown: maxDrawdown,
            volatility: volatility,
            sharpeRatio: sharpeRatio,
            calmarRatio: calmarRatio,
            averageLeverage: averageLeverage,
            positionConcentration: concentration,
            winRateConsistency: winRateConsistency,
            returnConsistency: returnConsistency
        )
    }
    
    private func calculateRiskFactors(from metrics: RiskMetrics) -> RiskFactors {
        // Drawdown risk (0-10)
        let drawdownRisk = min(10, metrics.maxDrawdown * 20) // 50% drawdown = 10 risk
        
        // Volatility risk (0-10)
        let volatilityRisk = min(10, metrics.volatility * 100) // 10% daily vol = 10 risk
        
        // Concentration risk (0-10)
        let concentrationRisk = metrics.positionConcentration * 10
        
        // Leverage risk (0-10)
        let leverageRisk = min(10, metrics.averageLeverage / 50) // 500:1 leverage = 10 risk
        
        // Frequency risk - higher frequency = higher risk
        let frequencyRisk = 5.0 // Default medium risk, would need trade frequency data
        
        // Consistency risk - lower consistency = higher risk
        let consistencyRisk = 10 - (metrics.returnConsistency * 10)
        
        return RiskFactors(
            drawdownRisk: drawdownRisk,
            volatilityRisk: volatilityRisk,
            concentrationRisk: concentrationRisk,
            leverageRisk: leverageRisk,
            frequencyRisk: frequencyRisk,
            consistencyRisk: consistencyRisk
        )
    }
    
    private func calculateVolatility(returns: [Double]) -> Double {
        guard !returns.isEmpty else { return 0 }
        
        let mean = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - mean, 2) }.reduce(0, +) / Double(returns.count)
        return sqrt(variance)
    }
    
    private func calculateAverageLeverage(trader: Trader, positions: [TrackedPosition]?) -> Double {
        // If we have current positions, calculate from them
        if let positions = positions, !positions.isEmpty {
            let totalMargin = positions.reduce(0) { $0 + $1.marginUsed }
            let totalVolume = positions.reduce(0) { $0 + $1.volume }
            // Rough leverage calculation
            return totalVolume > 0 ? (totalMargin * 100) / totalVolume : 100
        }
        
        // Otherwise use default based on trading style
        switch trader.tradingStyle {
        case .scalping:
            return 200 // High leverage typical for scalping
        case .dayTrading:
            return 100
        case .swingTrading:
            return 50
        case .positionTrading:
            return 30
        case .algorithmic:
            return 100
        case .mixed:
            return 75
        }
    }
    
    private func calculatePositionConcentration(trader: Trader, positions: [TrackedPosition]?) -> Double {
        guard let positions = positions, !positions.isEmpty else {
            // Use historical data from trader stats
            let symbols = trader.stats.favoriteSymbols
            return symbols.count <= 2 ? 0.8 : (symbols.count <= 5 ? 0.5 : 0.3)
        }
        
        // Calculate concentration from current positions
        var symbolVolumes: [String: Double] = [:]
        let totalVolume = positions.reduce(0) { $0 + $1.volume }
        
        for position in positions {
            symbolVolumes[position.symbol, default: 0] += position.volume
        }
        
        // Calculate Herfindahl index (sum of squared market shares)
        let herfindahlIndex = symbolVolumes.values.reduce(0) { acc, volume in
            let share = volume / totalVolume
            return acc + pow(share, 2)
        }
        
        return herfindahlIndex // Higher = more concentrated
    }
    
    private func calculateWinRateConsistency(performance: PerformanceData) -> Double {
        let monthlyWinRates = performance.monthlyReturns.map { $0.winRate }
        guard !monthlyWinRates.isEmpty else { return 0.5 }
        
        // Calculate standard deviation of win rates
        let mean = monthlyWinRates.reduce(0, +) / Double(monthlyWinRates.count)
        let variance = monthlyWinRates.map { pow($0 - mean, 2) }.reduce(0, +) / Double(monthlyWinRates.count)
        let stdDev = sqrt(variance)
        
        // Convert to 0-1 scale (lower stdDev = higher consistency)
        return max(0, 1 - stdDev * 2)
    }
    
    private func calculateReturnConsistency(performance: PerformanceData) -> Double {
        let monthlyReturns = performance.monthlyReturns.map { $0.returnPercentage }
        guard monthlyReturns.count >= 3 else { return 0.5 }
        
        // Count profitable months
        let profitableMonths = monthlyReturns.filter { $0 > 0 }.count
        let consistency = Double(profitableMonths) / Double(monthlyReturns.count)
        
        return consistency
    }
    
    private func generateRiskRecommendations(factors: RiskFactors, score: Int) -> [String] {
        var recommendations: [String] = []
        
        if factors.drawdownRisk > 7 {
            recommendations.append("High drawdown risk detected. Consider reducing position sizes.")
        }
        
        if factors.volatilityRisk > 7 {
            recommendations.append("High volatility in returns. Implement tighter risk controls.")
        }
        
        if factors.concentrationRisk > 7 {
            recommendations.append("Position concentration is high. Diversify across more instruments.")
        }
        
        if factors.leverageRisk > 7 {
            recommendations.append("Leverage usage is aggressive. Consider reducing leverage.")
        }
        
        if factors.consistencyRisk > 7 {
            recommendations.append("Returns show low consistency. Focus on systematic approach.")
        }
        
        if score <= 3 {
            recommendations.append("Overall risk is low. Suitable for conservative investors.")
        } else if score >= 7 {
            recommendations.append("Overall risk is high. Suitable only for risk-tolerant investors.")
        }
        
        return recommendations
    }
    
    private func identifyStrengths(factors: RiskFactors, metrics: RiskMetrics) -> [String] {
        var strengths: [String] = []
        
        if factors.drawdownRisk <= 3 {
            strengths.append("Excellent drawdown control")
        }
        
        if metrics.sharpeRatio > 1.5 {
            strengths.append("Strong risk-adjusted returns")
        }
        
        if factors.consistencyRisk <= 3 {
            strengths.append("Highly consistent performance")
        }
        
        if metrics.calmarRatio > 1.0 {
            strengths.append("Good return to drawdown ratio")
        }
        
        return strengths
    }
    
    private func identifyWeaknesses(factors: RiskFactors, metrics: RiskMetrics) -> [String] {
        var weaknesses: [String] = []
        
        if factors.drawdownRisk > 7 {
            weaknesses.append("High drawdown periods")
        }
        
        if factors.volatilityRisk > 7 {
            weaknesses.append("Volatile returns")
        }
        
        if factors.leverageRisk > 7 {
            weaknesses.append("Excessive leverage usage")
        }
        
        if metrics.sharpeRatio < 0.5 {
            weaknesses.append("Poor risk-adjusted returns")
        }
        
        return weaknesses
    }
}

// MARK: - Risk Analysis Model

struct TraderRiskAnalysis {
    let overallScore: Int
    let factors: RiskScoreCalculator.RiskFactors
    let metrics: RiskScoreCalculator.RiskMetrics
    let recommendations: [String]
    let strengths: [String]
    let weaknesses: [String]
    
    var riskLevel: TraderRiskLevel {
        switch overallScore {
        case 1...3:
            return .low
        case 4...6:
            return .medium
        default:
            return .high
        }
    }
    
    var riskDescription: String {
        switch riskLevel {
        case .low:
            return "This trader exhibits conservative risk management with stable returns and controlled drawdowns."
        case .medium:
            return "This trader shows balanced risk-taking with moderate volatility and reasonable return consistency."
        case .high:
            return "This trader employs aggressive strategies with higher volatility and potential for larger drawdowns."
        }
    }
}