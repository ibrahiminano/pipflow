//
//  AIRiskAnalyzer.swift
//  Pipflow
//
//  AI-powered risk analysis and management
//

import Foundation
import SwiftUI

// MARK: - Risk Analysis Models

struct RiskAnalysisRequest {
    let portfolio: Portfolio
    let marketConditions: MarketConditions
    let timeHorizon: RiskTimeHorizon
    let riskTolerance: RiskTolerance
}

struct RiskAnalysisResult: Identifiable {
    let id = UUID()
    let timestamp: Date
    let overallRiskScore: Double // 0-10
    let riskCategory: RiskCategory
    let portfolioRisks: PortfolioRisks
    let marketRisks: MarketRisks
    let recommendations: [RiskRecommendation]
    let alerts: [RiskAlert]
    let heatMap: RiskHeatMap
    let correlationMatrix: CorrelationMatrix
    let stressTestResults: [StressTestResult]
}

struct Portfolio {
    let positions: [Position]
    let totalValue: Double
    let cash: Double
    let leverage: Double
}

struct MarketConditions {
    let volatilityIndex: Double
    let trendStrength: Double
    let correlations: [String: Double]
    let economicIndicators: [EconomicIndicator]
}

enum RiskTimeHorizon: String, CaseIterable {
    case intraday = "Intraday"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

enum RiskTolerance: String, CaseIterable {
    case conservative = "Conservative"
    case moderate = "Moderate"
    case aggressive = "Aggressive"
    case veryAggressive = "Very Aggressive"
}

enum RiskCategory {
    case low
    case moderate
    case high
    case critical
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        case .critical: return "Critical Risk"
        }
    }
}

struct PortfolioRisks {
    let concentrationRisk: Double
    let correlationRisk: Double
    let leverageRisk: Double
    let liquidityRisk: Double
    let drawdownRisk: Double
    let valueAtRisk: ValueAtRisk
}

struct MarketRisks {
    let volatilityRisk: Double
    let trendRisk: Double
    let gapRisk: Double
    let blackSwanRisk: Double
    let liquidityRisk: Double
}

struct RiskRecommendation: Identifiable {
    let id = UUID()
    let priority: Priority
    let category: RecommendationCategory
    let title: String
    let description: String
    let action: String
    let impact: String
    let effort: EffortLevel
}

enum Priority {
    case critical
    case high
    case medium
    case low
}

enum RecommendationCategory {
    case positionSizing
    case diversification
    case hedging
    case stopLoss
    case profitTaking
    case rebalancing
}

enum EffortLevel {
    case easy
    case moderate
    case complex
}

struct RiskAlert: Identifiable {
    let id = UUID()
    let severity: AlertSeverity
    let type: AlertType
    let message: String
    let affectedPositions: [String]
    let timestamp: Date
}

enum AlertSeverity {
    case info
    case warning
    case danger
    case critical
}

enum AlertType {
    case concentration
    case correlation
    case volatility
    case drawdown
    case margin
    case news
}

struct RiskHeatMap {
    let data: [[RiskCell]]
    let xLabels: [String] // Symbols
    let yLabels: [String] // Risk factors
}

struct RiskCell {
    let value: Double
    let color: Color
}

struct CorrelationMatrix {
    let symbols: [String]
    let values: [[Double]]
}

struct StressTestResult: Identifiable {
    let id = UUID()
    let scenario: StressScenario
    let portfolioImpact: Double
    let worstCaseDrawdown: Double
    let affectedPositions: [(symbol: String, impact: Double)]
}

struct StressScenario {
    let name: String
    let description: String
    let marketMovements: [String: Double]
}

struct ValueAtRisk {
    let daily95: Double
    let daily99: Double
    let weekly95: Double
    let weekly99: Double
    let monthly95: Double
    let monthly99: Double
}

struct EconomicIndicator {
    let name: String
    let value: Double
    let impact: Double
}

// MARK: - AI Risk Analyzer

@MainActor
class AIRiskAnalyzer: ObservableObject {
    static let shared = AIRiskAnalyzer()
    
    @Published var isAnalyzing = false
    @Published var currentAnalysis: RiskAnalysisResult?
    @Published var analysisHistory: [RiskAnalysisResult] = []
    @Published var realtimeAlerts: [RiskAlert] = []
    @Published var riskMetrics = RiskMetrics()
    
    private let aiService = AISignalService.shared
    private let dataService = MarketDataService.shared
    private var analysisTimer: Timer?
    
    struct RiskMetrics {
        var portfolioRiskScore: Double = 0
        var marketRiskScore: Double = 0
        var correlationRisk: Double = 0
        var concentrationRisk: Double = 0
        var volatilityRisk: Double = 0
    }
    
    // MARK: - Public Methods
    
    func analyzePortfolioRisk(_ request: RiskAnalysisRequest) async throws -> RiskAnalysisResult {
        isAnalyzing = true
        
        do {
            // 1. Calculate portfolio metrics
            let portfolioRisks = calculatePortfolioRisks(request.portfolio)
            
            // 2. Analyze market conditions
            let marketRisks = analyzeMarketRisks(request.marketConditions)
            
            // 3. Generate risk heat map
            let heatMap = generateRiskHeatMap(
                portfolio: request.portfolio,
                marketConditions: request.marketConditions
            )
            
            // 4. Calculate correlation matrix
            let correlationMatrix = calculateCorrelationMatrix(
                positions: request.portfolio.positions
            )
            
            // 5. Run stress tests
            let stressTests = runStressTests(
                portfolio: request.portfolio,
                marketConditions: request.marketConditions
            )
            
            // 6. Generate recommendations
            let recommendations = generateRecommendations(
                portfolioRisks: portfolioRisks,
                marketRisks: marketRisks,
                riskTolerance: request.riskTolerance
            )
            
            // 7. Check for alerts
            let alerts = checkForAlerts(
                portfolio: request.portfolio,
                portfolioRisks: portfolioRisks,
                marketRisks: marketRisks
            )
            
            // 8. Calculate overall risk score
            let overallScore = calculateOverallRiskScore(
                portfolioRisks: portfolioRisks,
                marketRisks: marketRisks
            )
            
            let result = RiskAnalysisResult(
                timestamp: Date(),
                overallRiskScore: overallScore,
                riskCategory: categorizeRisk(overallScore),
                portfolioRisks: portfolioRisks,
                marketRisks: marketRisks,
                recommendations: recommendations,
                alerts: alerts,
                heatMap: heatMap,
                correlationMatrix: correlationMatrix,
                stressTestResults: stressTests
            )
            
            currentAnalysis = result
            analysisHistory.append(result)
            realtimeAlerts.append(contentsOf: alerts)
            
            isAnalyzing = false
            return result
            
        } catch {
            isAnalyzing = false
            throw error
        }
    }
    
    func startRealtimeMonitoring(portfolio: Portfolio) {
        stopRealtimeMonitoring()
        
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await self.performRealtimeAnalysis(portfolio: portfolio)
            }
        }
    }
    
    func stopRealtimeMonitoring() {
        analysisTimer?.invalidate()
        analysisTimer = nil
    }
    
    // MARK: - Private Methods
    
    private func calculatePortfolioRisks(_ portfolio: Portfolio) -> PortfolioRisks {
        // Concentration Risk
        let totalValue = portfolio.positions.reduce(0) { $0 + $1.currentValue }
        let largestPosition = portfolio.positions.map { $0.currentValue }.max() ?? 0
        let concentrationRisk = largestPosition / totalValue
        
        // Correlation Risk
        let correlationRisk = calculatePortfolioCorrelation(portfolio.positions)
        
        // Leverage Risk
        let leverageRisk = min(portfolio.leverage / 10, 1.0)
        
        // Liquidity Risk
        let liquidityRisk = calculateLiquidityRisk(portfolio.positions)
        
        // Drawdown Risk
        let drawdownRisk = calculateDrawdownRisk(portfolio.positions)
        
        // Value at Risk
        let valueAtRisk = calculateValueAtRisk(portfolio)
        
        return PortfolioRisks(
            concentrationRisk: concentrationRisk,
            correlationRisk: correlationRisk,
            leverageRisk: leverageRisk,
            liquidityRisk: liquidityRisk,
            drawdownRisk: drawdownRisk,
            valueAtRisk: valueAtRisk
        )
    }
    
    private func analyzeMarketRisks(_ conditions: MarketConditions) -> MarketRisks {
        // Volatility Risk
        let volatilityRisk = min(conditions.volatilityIndex / 50, 1.0)
        
        // Trend Risk
        let trendRisk = 1.0 - abs(conditions.trendStrength)
        
        // Gap Risk
        let gapRisk = calculateGapRisk(volatility: conditions.volatilityIndex)
        
        // Black Swan Risk
        let blackSwanRisk = calculateBlackSwanRisk(
            volatility: conditions.volatilityIndex,
            correlations: conditions.correlations
        )
        
        // Liquidity Risk
        let liquidityRisk = calculateMarketLiquidityRisk(conditions)
        
        return MarketRisks(
            volatilityRisk: volatilityRisk,
            trendRisk: trendRisk,
            gapRisk: gapRisk,
            blackSwanRisk: blackSwanRisk,
            liquidityRisk: liquidityRisk
        )
    }
    
    private func generateRiskHeatMap(portfolio: Portfolio, marketConditions: MarketConditions) -> RiskHeatMap {
        let symbols = portfolio.positions.map { $0.symbol }
        let riskFactors = ["Volatility", "Correlation", "Liquidity", "Drawdown", "Concentration"]
        
        var data: [[RiskCell]] = []
        
        for factor in riskFactors {
            var row: [RiskCell] = []
            
            for position in portfolio.positions {
                let risk = calculatePositionRisk(
                    position: position,
                    factor: factor,
                    marketConditions: marketConditions
                )
                
                let color = riskToColor(risk)
                row.append(RiskCell(value: risk, color: color))
            }
            
            data.append(row)
        }
        
        return RiskHeatMap(
            data: data,
            xLabels: symbols,
            yLabels: riskFactors
        )
    }
    
    private func calculateCorrelationMatrix(positions: [Position]) -> CorrelationMatrix {
        let symbols = positions.map { $0.symbol }
        var matrix: [[Double]] = []
        
        // For demo, generate synthetic correlations
        for i in 0..<symbols.count {
            var row: [Double] = []
            for j in 0..<symbols.count {
                if i == j {
                    row.append(1.0)
                } else {
                    // Generate realistic correlations
                    let baseCorr = Double.random(in: -0.3...0.7)
                    row.append(baseCorr)
                }
            }
            matrix.append(row)
        }
        
        return CorrelationMatrix(symbols: symbols, values: matrix)
    }
    
    private func runStressTests(portfolio: Portfolio, marketConditions: MarketConditions) -> [StressTestResult] {
        let scenarios = [
            StressScenario(
                name: "Market Crash",
                description: "Sudden 20% market decline",
                marketMovements: ["SPX": -0.20, "VIX": 2.0]
            ),
            StressScenario(
                name: "Flash Crash",
                description: "Rapid 10% drop and recovery",
                marketMovements: ["SPX": -0.10, "VIX": 3.0]
            ),
            StressScenario(
                name: "Currency Crisis",
                description: "Major currency devaluation",
                marketMovements: ["DXY": 0.15, "EUR": -0.20]
            ),
            StressScenario(
                name: "Interest Rate Shock",
                description: "Unexpected rate hike",
                marketMovements: ["RATES": 0.02, "BONDS": -0.05]
            )
        ]
        
        var results: [StressTestResult] = []
        
        for scenario in scenarios {
            let impact = simulateScenarioImpact(
                portfolio: portfolio,
                scenario: scenario,
                marketConditions: marketConditions
            )
            results.append(impact)
        }
        
        return results
    }
    
    private func generateRecommendations(
        portfolioRisks: PortfolioRisks,
        marketRisks: MarketRisks,
        riskTolerance: RiskTolerance
    ) -> [RiskRecommendation] {
        var recommendations: [RiskRecommendation] = []
        
        // Concentration recommendations
        if portfolioRisks.concentrationRisk > 0.3 {
            recommendations.append(RiskRecommendation(
                priority: .high,
                category: .diversification,
                title: "Reduce Position Concentration",
                description: "Your largest position represents over 30% of your portfolio",
                action: "Consider reducing position size or adding more diversified positions",
                impact: "Reduce concentration risk by 40%",
                effort: .easy
            ))
        }
        
        // Correlation recommendations
        if portfolioRisks.correlationRisk > 0.7 {
            recommendations.append(RiskRecommendation(
                priority: .medium,
                category: .diversification,
                title: "Diversify Correlated Positions",
                description: "Multiple positions are highly correlated",
                action: "Add positions in uncorrelated assets or markets",
                impact: "Reduce correlation risk by 30%",
                effort: .moderate
            ))
        }
        
        // Volatility recommendations
        if marketRisks.volatilityRisk > 0.6 {
            recommendations.append(RiskRecommendation(
                priority: .high,
                category: .positionSizing,
                title: "Reduce Position Sizes",
                description: "Market volatility is elevated",
                action: "Reduce position sizes by 25-30%",
                impact: "Lower portfolio volatility by 20%",
                effort: .easy
            ))
        }
        
        // Stop loss recommendations
        if portfolioRisks.drawdownRisk > 0.15 {
            recommendations.append(RiskRecommendation(
                priority: .critical,
                category: .stopLoss,
                title: "Tighten Stop Losses",
                description: "Current drawdown risk exceeds 15%",
                action: "Move stop losses closer to current prices",
                impact: "Limit maximum loss to 10%",
                effort: .easy
            ))
        }
        
        // Hedging recommendations
        if marketRisks.blackSwanRisk > 0.3 {
            recommendations.append(RiskRecommendation(
                priority: .medium,
                category: .hedging,
                title: "Consider Hedging",
                description: "Tail risk is elevated",
                action: "Add protective puts or volatility hedges",
                impact: "Reduce tail risk by 50%",
                effort: .complex
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    private func checkForAlerts(
        portfolio: Portfolio,
        portfolioRisks: PortfolioRisks,
        marketRisks: MarketRisks
    ) -> [RiskAlert] {
        var alerts: [RiskAlert] = []
        let timestamp = Date()
        
        // Concentration alerts
        if portfolioRisks.concentrationRisk > 0.4 {
            alerts.append(RiskAlert(
                severity: .danger,
                type: .concentration,
                message: "Position concentration exceeds 40% - immediate action required",
                affectedPositions: [portfolio.positions.max(by: { $0.currentValue < $1.currentValue })?.symbol ?? ""],
                timestamp: timestamp
            ))
        }
        
        // Drawdown alerts
        if portfolioRisks.drawdownRisk > 0.2 {
            alerts.append(RiskAlert(
                severity: .critical,
                type: .drawdown,
                message: "Portfolio drawdown risk exceeds 20%",
                affectedPositions: portfolio.positions.filter { $0.unrealizedPnL < 0 }.map { $0.symbol },
                timestamp: timestamp
            ))
        }
        
        // Volatility alerts
        if marketRisks.volatilityRisk > 0.8 {
            alerts.append(RiskAlert(
                severity: .warning,
                type: .volatility,
                message: "Market volatility is extremely high",
                affectedPositions: portfolio.positions.map { $0.symbol },
                timestamp: timestamp
            ))
        }
        
        // Margin alerts
        if portfolio.leverage > 5 {
            alerts.append(RiskAlert(
                severity: .danger,
                type: .margin,
                message: "Leverage exceeds safe levels",
                affectedPositions: [],
                timestamp: timestamp
            ))
        }
        
        return alerts
    }
    
    // MARK: - Helper Methods
    
    private func calculatePortfolioCorrelation(_ positions: [Position]) -> Double {
        // Simplified correlation calculation
        guard positions.count > 1 else { return 0 }
        
        // In real implementation, would calculate actual correlations
        return Double.random(in: 0.3...0.8)
    }
    
    private func calculateLiquidityRisk(_ positions: [Position]) -> Double {
        // Based on position sizes and typical volume
        return positions.map { position in
            let sizeRatio = position.currentValue / 100000 // Assume $100k daily volume
            return min(sizeRatio, 1.0)
        }.reduce(0, +) / Double(positions.count)
    }
    
    private func calculateDrawdownRisk(_ positions: [Position]) -> Double {
        let totalValue = positions.reduce(0) { $0 + $1.currentValue }
        let totalLoss = positions.reduce(0) { $0 + min($1.unrealizedPnL, 0) }
        return abs(totalLoss) / totalValue
    }
    
    private func calculateValueAtRisk(_ portfolio: Portfolio) -> ValueAtRisk {
        // Simplified VaR calculation
        let portfolioVolatility = 0.02 // 2% daily volatility assumption
        let portfolioValue = portfolio.totalValue
        
        return ValueAtRisk(
            daily95: portfolioValue * portfolioVolatility * 1.645,
            daily99: portfolioValue * portfolioVolatility * 2.326,
            weekly95: portfolioValue * portfolioVolatility * sqrt(5) * 1.645,
            weekly99: portfolioValue * portfolioVolatility * sqrt(5) * 2.326,
            monthly95: portfolioValue * portfolioVolatility * sqrt(22) * 1.645,
            monthly99: portfolioValue * portfolioVolatility * sqrt(22) * 2.326
        )
    }
    
    private func calculateGapRisk(volatility: Double) -> Double {
        // Higher volatility increases gap risk
        return min(volatility / 30 * 0.5, 1.0)
    }
    
    private func calculateBlackSwanRisk(volatility: Double, correlations: [String: Double]) -> Double {
        let avgCorrelation = correlations.values.reduce(0, +) / Double(correlations.count)
        return min((volatility / 50 + avgCorrelation) / 2, 1.0)
    }
    
    private func calculateMarketLiquidityRisk(_ conditions: MarketConditions) -> Double {
        // Based on market conditions and economic indicators
        let stressIndicator = conditions.economicIndicators
            .filter { $0.impact < 0 }
            .reduce(0) { accumulator, indicator in accumulator + abs(indicator.impact) }
        
        return min(stressIndicator / 10, 1.0)
    }
    
    private func calculatePositionRisk(
        position: Position,
        factor: String,
        marketConditions: MarketConditions
    ) -> Double {
        switch factor {
        case "Volatility":
            return min(marketConditions.volatilityIndex / 50, 1.0)
        case "Correlation":
            return marketConditions.correlations[position.symbol] ?? 0.5
        case "Liquidity":
            return position.currentValue / 100000 // Liquidity based on size
        case "Drawdown":
            return abs(min(position.unrealizedPnL, 0)) / position.currentValue
        case "Concentration":
            return position.currentValue / 50000 // Concentration based on size
        default:
            return 0.5
        }
    }
    
    private func riskToColor(_ risk: Double) -> Color {
        switch risk {
        case 0..<0.3:
            return .green
        case 0.3..<0.6:
            return .yellow
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private func simulateScenarioImpact(
        portfolio: Portfolio,
        scenario: StressScenario,
        marketConditions: MarketConditions
    ) -> StressTestResult {
        var totalImpact = 0.0
        var worstDrawdown = 0.0
        var affectedPositions: [(String, Double)] = []
        
        for position in portfolio.positions {
            // Simulate position impact based on scenario
            let marketMove = scenario.marketMovements["SPX"] ?? 0
            let volatilityMultiplier = scenario.marketMovements["VIX"] ?? 1
            
            let positionBeta = Double.random(in: 0.5...1.5) // Position beta to market
            let impact = position.currentValue * marketMove * positionBeta * volatilityMultiplier
            
            totalImpact += impact
            worstDrawdown = min(worstDrawdown, impact)
            
            affectedPositions.append((position.symbol, impact))
        }
        
        return StressTestResult(
            scenario: scenario,
            portfolioImpact: totalImpact,
            worstCaseDrawdown: worstDrawdown,
            affectedPositions: affectedPositions.sorted { abs($0.1) > abs($1.1) }
        )
    }
    
    private func calculateOverallRiskScore(
        portfolioRisks: PortfolioRisks,
        marketRisks: MarketRisks
    ) -> Double {
        let portfolioScore = (
            portfolioRisks.concentrationRisk * 2 +
            portfolioRisks.correlationRisk * 1.5 +
            portfolioRisks.leverageRisk * 3 +
            portfolioRisks.liquidityRisk * 1 +
            portfolioRisks.drawdownRisk * 2.5
        ) / 10
        
        let marketScore = (
            marketRisks.volatilityRisk * 2 +
            marketRisks.trendRisk * 1 +
            marketRisks.gapRisk * 1.5 +
            marketRisks.blackSwanRisk * 2.5 +
            marketRisks.liquidityRisk * 1
        ) / 8
        
        return (portfolioScore * 0.6 + marketScore * 0.4) * 10
    }
    
    private func categorizeRisk(_ score: Double) -> RiskCategory {
        switch score {
        case 0..<3:
            return .low
        case 3..<6:
            return .moderate
        case 6..<8:
            return .high
        default:
            return .critical
        }
    }
    
    private func performRealtimeAnalysis(portfolio: Portfolio) async {
        // Update risk metrics in real-time
        let portfolioRisks = calculatePortfolioRisks(portfolio)
        
        await MainActor.run {
            self.riskMetrics.portfolioRiskScore = calculateOverallRiskScore(
                portfolioRisks: portfolioRisks,
                marketRisks: MarketRisks(
                    volatilityRisk: 0.5,
                    trendRisk: 0.3,
                    gapRisk: 0.2,
                    blackSwanRisk: 0.1,
                    liquidityRisk: 0.3
                )
            )
            self.riskMetrics.concentrationRisk = portfolioRisks.concentrationRisk
            self.riskMetrics.correlationRisk = portfolioRisks.correlationRisk
        }
    }
}

// MARK: - Supporting Extensions

extension Priority: Comparable {
    var rawValue: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
    
    static func < (lhs: Priority, rhs: Priority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}