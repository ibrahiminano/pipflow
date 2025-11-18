//
//  TradeRequest.swift
//  Pipflow
//
//  Trade request model for opening positions
//

import Foundation

struct TradeRequest {
    let symbol: String
    let type: TradeType
    let side: TradeSide
    let volume: Double
    let price: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let comment: String?
    
    init(
        symbol: String,
        type: TradeType,
        side: TradeSide,
        volume: Double,
        price: Double? = nil,
        stopLoss: Double? = nil,
        takeProfit: Double? = nil,
        comment: String? = nil
    ) {
        self.symbol = symbol
        self.type = type
        self.side = side
        self.volume = volume
        self.price = price
        self.stopLoss = stopLoss
        self.takeProfit = takeProfit
        self.comment = comment
    }
    
    // Convenience initializer for market orders
    static func market(
        symbol: String,
        side: TradeSide,
        volume: Double,
        stopLoss: Double? = nil,
        takeProfit: Double? = nil,
        comment: String? = nil
    ) -> TradeRequest {
        TradeRequest(
            symbol: symbol,
            type: side == .buy ? .buy : .sell,
            side: side,
            volume: volume,
            price: nil,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            comment: comment
        )
    }
}