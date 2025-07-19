//
//  Trade.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

struct Trade: Codable, Identifiable {
    let id: UUID
    let accountId: UUID
    let positionId: String
    let symbol: String
    let type: TradeType
    let volume: Decimal
    let openPrice: Decimal
    let currentPrice: Decimal
    let closePrice: Decimal?
    let stopLoss: Decimal?
    let takeProfit: Decimal?
    let commission: Decimal
    let swap: Decimal
    let profit: Decimal
    let status: TradeStatus
    let openTime: Date
    let closeTime: Date?
    let reason: TradeReason?
    let comment: String?
    
    var unrealizedPnL: Decimal {
        guard status == .open else { return profit }
        let priceDiff = type == .buy ? currentPrice - openPrice : openPrice - currentPrice
        return priceDiff * volume * 100000 // Assuming standard lot size
    }
    
    var duration: TimeInterval {
        if let closeTime = closeTime {
            return closeTime.timeIntervalSince(openTime)
        }
        return Date().timeIntervalSince(openTime)
    }
}

enum TradeType: String, Codable, CaseIterable {
    case buy = "BUY"
    case sell = "SELL"
    case buyLimit = "BUY_LIMIT"
    case sellLimit = "SELL_LIMIT"
    case buyStop = "BUY_STOP"
    case sellStop = "SELL_STOP"
    
    var isMarketOrder: Bool {
        self == .buy || self == .sell
    }
    
    var isPendingOrder: Bool {
        !isMarketOrder
    }
}

enum TradeStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case open = "OPEN"
    case closed = "CLOSED"
    case cancelled = "CANCELLED"
}

enum TradeReason: String, Codable, CaseIterable {
    case manual = "MANUAL"
    case signal = "SIGNAL"
    case copyTrade = "COPY_TRADE"
    case autoTrade = "AUTO_TRADE"
    case stopLoss = "STOP_LOSS"
    case takeProfit = "TAKE_PROFIT"
    case marginCall = "MARGIN_CALL"
}

enum TradeSide: String, Codable, CaseIterable {
    case buy = "BUY"
    case sell = "SELL"
}