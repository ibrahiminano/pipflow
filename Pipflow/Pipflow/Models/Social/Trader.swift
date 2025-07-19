//
//  Trader.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Trader Model

struct Trader: Identifiable, Codable {
    let id: String
    let username: String
    let displayName: String
    let profileImageURL: String?
    let bio: String
    let isVerified: Bool
    let isPro: Bool
    let followers: Int
    let following: Int
    let totalTrades: Int
    let winRate: Double
    let profitFactor: Double
    let averageReturn: Double
    let monthlyReturn: Double
    let yearlyReturn: Double
    let riskScore: Int // 1-10
    let tradingStyle: TraderStyle
    let specialties: [String]
    let performance: PerformanceData
    let stats: TraderStats
    let joinedDate: Date
    let lastActiveDate: Date
    
    var formattedWinRate: String {
        String(format: "%.1f%%", winRate * 100)
    }
    
    var formattedMonthlyReturn: String {
        String(format: "%+.1f%%", monthlyReturn * 100)
    }
    
    var formattedYearlyReturn: String {
        String(format: "%+.1f%%", yearlyReturn * 100)
    }
    
    var riskLevel: TraderRiskLevel {
        switch riskScore {
        case 1...3: return .low
        case 4...6: return .medium
        case 7...10: return .high
        default: return .medium
        }
    }
}

// MARK: - Trading Style

enum TraderStyle: String, Codable, CaseIterable {
    case scalping = "Scalping"
    case dayTrading = "Day Trading"
    case swingTrading = "Swing Trading"
    case positionTrading = "Position Trading"
    case algorithmic = "Algorithmic"
    case mixed = "Mixed"
    
    var description: String {
        switch self {
        case .scalping: return "Quick trades, small profits"
        case .dayTrading: return "Intraday positions only"
        case .swingTrading: return "Multi-day trend following"
        case .positionTrading: return "Long-term positions"
        case .algorithmic: return "Automated strategies"
        case .mixed: return "Various strategies"
        }
    }
    
    var color: Color {
        switch self {
        case .scalping: return .orange
        case .dayTrading: return .blue
        case .swingTrading: return .green
        case .positionTrading: return .purple
        case .algorithmic: return .pink
        case .mixed: return .gray
        }
    }
}

// MARK: - Risk Level

enum TraderRiskLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Conservative approach"
        case .medium: return "Balanced risk/reward"
        case .high: return "Aggressive strategies"
        }
    }
}

// MARK: - Performance Data

struct PerformanceData: Codable {
    let dailyReturns: [DailyReturn]
    let monthlyReturns: [MonthlyReturn]
    let drawdownHistory: [DrawdownEvent]
    let equityCurve: [EquityPoint]
    
    var maxDrawdown: Double {
        drawdownHistory.map { $0.percentage }.max() ?? 0
    }
    
    var sharpeRatio: Double {
        // Simplified Sharpe ratio calculation
        let returns = dailyReturns.map { $0.returnPercentage }
        guard !returns.isEmpty else { return 0 }
        
        let avgReturn = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.map { pow($0 - avgReturn, 2) }.reduce(0, +) / Double(returns.count)
        let stdDev = sqrt(variance)
        
        return stdDev > 0 ? (avgReturn * sqrt(252)) / stdDev : 0
    }
}

struct DailyReturn: Codable {
    let date: Date
    let returnPercentage: Double
    let profit: Double
    let trades: Int
}

struct MonthlyReturn: Codable {
    let month: Date
    let returnPercentage: Double
    let profit: Double
    let trades: Int
    let winRate: Double
}

struct DrawdownEvent: Codable {
    let startDate: Date
    let endDate: Date?
    let percentage: Double
    let recovered: Bool
}

struct EquityPoint: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
    let equity: Double
    
    enum CodingKeys: String, CodingKey {
        case date, balance, equity
    }
}

// MARK: - Trader Statistics

struct TraderStats: Codable {
    let totalProfit: Double
    let totalLoss: Double
    let largestWin: Double
    let largestLoss: Double
    let averageWin: Double
    let averageLoss: Double
    let averageTradeTime: TimeInterval
    let profitableDays: Int
    let losingDays: Int
    let tradingDays: Int
    let favoriteSymbols: [String]
    let successRateBySymbol: [String: Double]
    
    var profitLossRatio: Double {
        guard averageLoss != 0 else { return 0 }
        return abs(averageWin / averageLoss)
    }
    
    var expectancy: Double {
        let winProb = profitableDays > 0 ? Double(profitableDays) / Double(tradingDays) : 0
        let lossProb = 1 - winProb
        return (winProb * averageWin) - (lossProb * abs(averageLoss))
    }
}

// MARK: - Trader Relationship

struct TraderRelationship: Codable {
    let followerId: String
    let traderId: String
    let isFollowing: Bool
    let isCopying: Bool
    let copySettings: CopyTradingSettings?
    let followedSince: Date
    let copiedSince: Date?
}

// MARK: - Copy Trading Settings

struct CopyTradingSettings: Codable {
    let maxInvestment: Double
    let maxRiskPerTrade: Double
    let copyRatio: Double // 0.1 = 10%, 1.0 = 100%
    let stopLossEnabled: Bool
    let maxDailyLoss: Double?
    let allowedSymbols: [String]?
    let excludedSymbols: [String]?
    let copyOpenTrades: Bool
    let reverseCopy: Bool // Copy opposite trades
}