//
//  TradingAccount.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

struct TradingAccount: Codable, Identifiable {
    let id: String
    let accountId: String
    let accountType: AccountType
    let brokerName: String
    let serverName: String
    let platformType: TradingPlatform
    let balance: Double
    let equity: Double
    let currency: String
    let leverage: Int
    let isActive: Bool
    let connectedDate: Date
    
    // Legacy properties for compatibility
    var userId: UUID { UUID() }
    var platform: TradingPlatform { platformType }
    var broker: String { brokerName }
    var margin: Decimal { Decimal(0) }
    var freeMargin: Decimal { Decimal(0) }
    var marginLevel: Decimal? { nil }
    var lastSyncedAt: Date { connectedDate }
    var createdAt: Date { connectedDate }
    var updatedAt: Date { connectedDate }
    
    var profitLoss: Double {
        equity - balance
    }
    
    var profitLossPercentage: Double {
        guard balance > 0 else { return 0 }
        return (profitLoss / balance) * 100
    }
}

enum TradingPlatform: String, Codable, CaseIterable {
    case mt4 = "MT4"
    case mt5 = "MT5"
    
    var displayName: String {
        switch self {
        case .mt4: return "MetaTrader 4"
        case .mt5: return "MetaTrader 5"
        }
    }
}

enum AccountType: String, Codable, CaseIterable {
    case demo = "DEMO"
    case real = "REAL"
    case live = "LIVE"
    
    var displayName: String {
        switch self {
        case .demo: return "Demo"
        case .real: return "Real"
        case .live: return "Live"
        }
    }
}