//
//  TradingStrategy.swift
//  Pipflow
//
//  Trading strategy model
//

import Foundation

struct TradingStrategy: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let conditions: [StrategyCondition]
    let riskManagement: RiskManagement
    let timeframe: Timeframe
    let symbols: [String]
    let parameters: [String: Double]
    let createdAt: Date
    let updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        conditions: [StrategyCondition] = [],
        riskManagement: RiskManagement,
        timeframe: Timeframe = .h1,
        symbols: [String] = ["EURUSD"],
        parameters: [String: Double] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.conditions = conditions
        self.riskManagement = riskManagement
        self.timeframe = timeframe
        self.symbols = symbols
        self.parameters = parameters
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct RiskManagement: Codable {
    let stopLossPercent: Double
    let takeProfitPercent: Double
    let positionSizePercent: Double
    let maxOpenTrades: Int
    let maxDailyLoss: Double
    let maxDrawdown: Double
    let useTrailingStop: Bool
    let trailingStopDistance: Double
    
    init(
        stopLossPercent: Double = 1.0,
        takeProfitPercent: Double = 2.0,
        positionSizePercent: Double = 1.0,
        maxOpenTrades: Int = 3,
        maxDailyLoss: Double = 5.0,
        maxDrawdown: Double = 20.0,
        useTrailingStop: Bool = false,
        trailingStopDistance: Double = 1.0
    ) {
        self.stopLossPercent = stopLossPercent
        self.takeProfitPercent = takeProfitPercent
        self.positionSizePercent = positionSizePercent
        self.maxOpenTrades = maxOpenTrades
        self.maxDailyLoss = maxDailyLoss
        self.maxDrawdown = maxDrawdown
        self.useTrailingStop = useTrailingStop
        self.trailingStopDistance = trailingStopDistance
    }
}

enum TradeDirection: String, Codable {
    case long = "LONG"
    case short = "SHORT"
}

struct HistoricalDataPoint: Codable {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    // Convenience initializer for simple price data
    init(timestamp: Date, price: Double, volume: Double) {
        self.timestamp = timestamp
        self.open = price
        self.high = price
        self.low = price
        self.close = price
        self.volume = volume
    }
    
    // Full initializer for OHLC data
    init(timestamp: Date, open: Double, high: Double, low: Double, close: Double, volume: Double) {
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

// MARK: - Shared Strategy for Social Trading

struct SharedStrategy: Identifiable, Codable {
    let id: UUID
    let strategy: TradingStrategy
    let authorId: String
    let authorName: String
    let authorImage: String?
    let price: Double
    let subscribers: Int
    let rating: Double
    let reviews: Int
    let performance: TradingStrategyPerformance
    let isPublic: Bool
    let tags: [String]
    let publishedAt: Date
    
    init(
        id: UUID = UUID(),
        strategy: TradingStrategy,
        authorId: String,
        authorName: String,
        authorImage: String? = nil,
        price: Double = 0,
        subscribers: Int = 0,
        rating: Double = 0,
        reviews: Int = 0,
        performance: TradingStrategyPerformance,
        isPublic: Bool = true,
        tags: [String] = [],
        publishedAt: Date = Date()
    ) {
        self.id = id
        self.strategy = strategy
        self.authorId = authorId
        self.authorName = authorName
        self.authorImage = authorImage
        self.price = price
        self.subscribers = subscribers
        self.rating = rating
        self.reviews = reviews
        self.performance = performance
        self.isPublic = isPublic
        self.tags = tags
        self.publishedAt = publishedAt
    }
}

struct TradingStrategyPerformance: Codable {
    let totalReturn: Double
    let monthlyReturn: Double
    let winRate: Double
    let profitFactor: Double
    let sharpeRatio: Double
    let maxDrawdown: Double
    let totalTrades: Int
    let averageHoldTime: TimeInterval
    let lastUpdated: Date
}