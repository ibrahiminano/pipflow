//
//  Analytics.swift
//  Pipflow
//
//  Analytics models for trading performance tracking
//

import Foundation
import SwiftUI

// MARK: - Performance Metrics
struct AnalyticsPerformanceMetrics: Codable {
    let accountId: UUID
    let period: AnalyticsPeriod
    let startDate: Date
    let endDate: Date
    
    // Returns
    let totalReturn: Double
    let monthlyReturn: Double
    let dailyReturn: Double
    let maxDrawdown: Double
    let maxDrawdownDuration: Int // days
    
    // Trade Statistics
    let totalTrades: Int
    let winningTrades: Int
    let losingTrades: Int
    let winRate: Double
    let averageWin: Double
    let averageLoss: Double
    let largestWin: Double
    let largestLoss: Double
    let profitFactor: Double
    let expectancy: Double
    
    // Risk Metrics
    let sharpeRatio: Double
    let sortinoRatio: Double
    let calmarRatio: Double
    let standardDeviation: Double
    let downsideDeviation: Double
    let valueAtRisk: Double // 95% VaR
    let conditionalValueAtRisk: Double // CVaR
    
    // Trading Activity
    let averageTradesPerDay: Double
    let averageHoldingPeriod: TimeInterval
    let tradingDays: Int
    let activeDays: Int
    
    // Position Metrics
    let averagePositionSize: Double
    let maxConcurrentPositions: Int
    let exposure: Double // Average exposure as % of equity
    
    var winLossRatio: Double {
        guard averageLoss != 0 else { return 0 }
        return averageWin / abs(averageLoss)
    }
    
    var returnToDrawdownRatio: Double {
        guard maxDrawdown != 0 else { return 0 }
        return totalReturn / abs(maxDrawdown)
    }
}

// MARK: - Analytics Period
enum AnalyticsPeriod: String, Codable, CaseIterable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case allTime = "ALL"
    
    var displayName: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "1 Year"
        case .allTime: return "All Time"
        }
    }
    
    func startDate(from endDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch self {
        case .day:
            return calendar.startOfDay(for: endDate)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? endDate
        case .month:
            return calendar.dateInterval(of: .month, for: endDate)?.start ?? endDate
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: endDate) ?? endDate
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .allTime:
            return calendar.date(byAdding: .year, value: -10, to: endDate) ?? endDate
        }
    }
}

// MARK: - Equity Curve
struct EquityCurve: Codable {
    let dataPoints: [EquityDataPoint]
    let startingBalance: Double
    let endingBalance: Double
    let peakBalance: Double
    let troughBalance: Double
    
    var totalReturn: Double {
        guard startingBalance != 0 else { return 0 }
        return ((endingBalance - startingBalance) / startingBalance) * 100
    }
    
    var maxDrawdown: Double {
        guard peakBalance != 0 else { return 0 }
        return ((troughBalance - peakBalance) / peakBalance) * 100
    }
}

struct EquityDataPoint: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let balance: Double
    let profit: Double
    let drawdown: Double
    let openPositions: Int
    let realizedPnL: Double
    let unrealizedPnL: Double
}

// MARK: - Trade Distribution
struct TradeDistribution: Codable {
    let profitDistribution: [ProfitBucket]
    let timeDistribution: [TimeDistribution]
    let symbolDistribution: [SymbolPerformance]
    let dayOfWeekDistribution: [DayPerformance]
    let hourDistribution: [HourPerformance]
}

struct ProfitBucket: Codable, Identifiable {
    let id = UUID()
    let range: String
    let count: Int
    let percentage: Double
}

struct TimeDistribution: Codable, Identifiable {
    let id = UUID()
    let duration: String
    let count: Int
    let averageProfit: Double
}

struct SymbolPerformance: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let tradeCount: Int
    let totalProfit: Double
    let winRate: Double
    let averageProfit: Double
}

struct DayPerformance: Codable, Identifiable {
    let id = UUID()
    let dayOfWeek: String
    let tradeCount: Int
    let totalProfit: Double
    let winRate: Double
}

struct HourPerformance: Codable, Identifiable {
    let id = UUID()
    let hour: Int
    let tradeCount: Int
    let totalProfit: Double
    let winRate: Double
}

// MARK: - Risk Analysis
struct RiskAnalysis: Codable {
    let currentRisk: CurrentRiskMetrics
    let historicalRisk: HistoricalRiskMetrics
    let correlations: [SymbolCorrelation]
    let exposureAnalysis: ExposureAnalysis
}

struct CurrentRiskMetrics: Codable {
    let openPositionRisk: Double
    let totalExposure: Double
    let marginUsed: Double
    let marginAvailable: Double
    let leverage: Double
    let correlatedRisk: Double
    let worstCaseScenario: Double
}

struct HistoricalRiskMetrics: Codable {
    let averageLeverage: Double
    let maxLeverage: Double
    let averageExposure: Double
    let maxExposure: Double
    let riskAdjustedReturn: Double
    let maxConsecutiveLosses: Int
    let largestDailyLoss: Double
    let recoveryTime: Int // days to recover from max drawdown
}

struct SymbolCorrelation: Codable, Identifiable {
    let id = UUID()
    let symbol1: String
    let symbol2: String
    let correlation: Double
    let period: Int // days
}

struct ExposureAnalysis: Codable {
    let bySymbol: [SymbolExposure]
    let bySector: [SectorExposure]
    let byCurrency: [CurrencyExposure]
    let concentrationRisk: Double
}

struct SymbolExposure: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let exposure: Double
    let percentage: Double
}

struct SectorExposure: Codable, Identifiable {
    let id = UUID()
    let sector: String
    let exposure: Double
    let percentage: Double
}

struct CurrencyExposure: Codable, Identifiable {
    let id = UUID()
    let currency: String
    let exposure: Double
    let percentage: Double
}

// MARK: - Trade Journal Entry
struct TradeJournalEntry: Codable, Identifiable {
    let id: UUID
    let tradeId: UUID
    let timestamp: Date
    let symbol: String
    let side: TradeSide
    let entryPrice: Double
    let exitPrice: Double?
    let quantity: Double
    let profit: Double?
    let notes: String
    let tags: [String]
    let screenshots: [String] // URLs
    let emotions: [TradeEmotion]
    let setupQuality: Int // 1-5
    let executionQuality: Int // 1-5
    let lessons: String?
}

enum TradeEmotion: String, Codable, CaseIterable {
    case confident = "Confident"
    case anxious = "Anxious"
    case fearful = "Fearful"
    case greedy = "Greedy"
    case neutral = "Neutral"
    case excited = "Excited"
    case frustrated = "Frustrated"
    
    var color: Color {
        switch self {
        case .confident: return .green
        case .anxious: return .orange
        case .fearful: return .red
        case .greedy: return .purple
        case .neutral: return .gray
        case .excited: return .yellow
        case .frustrated: return .red
        }
    }
}

// MARK: - Analytics Summary
struct AnalyticsSummary: Codable {
    let accountId: UUID
    let lastUpdated: Date
    let currentBalance: Double
    let dayChange: Double
    let dayChangePercent: Double
    let weekChange: Double
    let weekChangePercent: Double
    let monthChange: Double
    let monthChangePercent: Double
    let openPositions: Int
    let todayTrades: Int
    let todayPnL: Double
    let unrealizedPnL: Double
}

// MARK: - Performance Comparison
struct PerformanceComparison: Codable {
    let userPerformance: AnalyticsPerformanceMetrics
    let benchmarks: [BenchmarkComparison]
    let percentile: Double // User's percentile among all traders
    let rank: Int
    let totalTraders: Int
}

struct BenchmarkComparison: Codable, Identifiable {
    let id = UUID()
    let name: String
    let returnValue: Double
    let sharpeRatio: Double
    let maxDrawdown: Double
    let correlation: Double
}