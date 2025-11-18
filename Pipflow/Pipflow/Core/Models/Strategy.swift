//
//  Strategy.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

struct Strategy: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let authorId: UUID
    let authorName: String
    let authorAvatarURL: String?
    let category: StrategyCategory
    let tradingStyle: StrategyTradingStyle
    let instruments: [String]
    let timeframes: [Timeframe]
    let performance: StrategyPerformance
    let riskScore: Int // 1-10
    let minimumCapital: Decimal
    let monthlyFee: Decimal?
    let profitShare: Double? // Percentage
    let subscribers: Int
    let rating: Double
    let reviews: Int
    let isVerified: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var riskLevel: StrategyRiskLevel {
        switch riskScore {
        case 1...3: return .low
        case 4...6: return .medium
        case 7...10: return .high
        default: return .medium
        }
    }
}

struct StrategyPerformance: Codable {
    let totalReturn: Decimal
    let monthlyReturn: Decimal
    let winRate: Double
    let profitFactor: Double
    let sharpeRatio: Double
    let maxDrawdown: Decimal
    let avgWin: Decimal
    let avgLoss: Decimal
    let totalTrades: Int
    let winningTrades: Int
    let losingTrades: Int
    let consecutiveWins: Int
    let consecutiveLosses: Int
    let lastUpdated: Date
}

enum StrategyCategory: String, Codable, CaseIterable {
    case scalping = "SCALPING"
    case dayTrading = "DAY_TRADING"
    case swingTrading = "SWING_TRADING"
    case positionTrading = "POSITION_TRADING"
    case algorithmic = "ALGORITHMIC"
    case grid = "GRID"
    case martingale = "MARTINGALE"
    case hedging = "HEDGING"
    
    var displayName: String {
        switch self {
        case .scalping: return "Scalping"
        case .dayTrading: return "Day Trading"
        case .swingTrading: return "Swing Trading"
        case .positionTrading: return "Position Trading"
        case .algorithmic: return "Algorithmic"
        case .grid: return "Grid Trading"
        case .martingale: return "Martingale"
        case .hedging: return "Hedging"
        }
    }
}

enum StrategyTradingStyle: String, Codable, CaseIterable {
    case conservative = "CONSERVATIVE"
    case moderate = "MODERATE"
    case aggressive = "AGGRESSIVE"
}

enum StrategyRiskLevel: String, CaseIterable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}