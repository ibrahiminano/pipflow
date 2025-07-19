//
//  MarketDataService.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

// MARK: - Market Data Models

struct MarketQuote: Codable {
    let symbol: String
    let bid: Double
    let ask: Double
    let spread: Double
    let timestamp: Date
    
    var mid: Double {
        (bid + ask) / 2
    }
}

struct MarketCandle: Codable {
    let symbol: String
    let timeframe: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    let timestamp: Date
}

struct MarketTick: Codable {
    let symbol: String
    let price: Double
    let volume: Double
    let side: TradeSide
    let timestamp: Date
}

// MARK: - Market Data Service

class MarketDataService: ObservableObject {
    static let shared = MarketDataService()
    
    // Published properties for real-time updates
    @Published var quotes: [String: MarketQuote] = [:]
    @Published var candles: [String: [MarketCandle]] = [:]
    @Published var ticks: [String: [MarketTick]] = [:]
    @Published var isStreaming = false
    
    // Price change tracking
    @Published var priceChanges: [String: PriceChange] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private let metaAPIManager = MetaAPIManager.shared
    
    // Supported symbols
    let supportedSymbols = [
        "EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCAD",
        "BTCUSD", "ETHUSD", "XAUUSD", "XAGUSD", "USOIL"
    ]
    
    struct PriceChange {
        let previousPrice: Double
        let currentPrice: Double
        let changeAmount: Double
        let changePercent: Double
        let isPositive: Bool
        
        init(previous: Double, current: Double) {
            self.previousPrice = previous
            self.currentPrice = current
            self.changeAmount = current - previous
            self.changePercent = ((current - previous) / previous) * 100
            self.isPositive = changeAmount >= 0
        }
    }
    
    init() {
        setupSubscriptions()
        startMockDataStream() // For demo purposes
    }
    
    private func setupSubscriptions() {
        // Subscribe to MetaAPI symbol prices
        metaAPIManager.$symbolPrices
            .sink { [weak self] prices in
                self?.updateQuotes(from: prices)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func startStreaming(symbols: [String]) {
        isStreaming = true
        metaAPIManager.subscribeToSymbols(symbols)
    }
    
    func stopStreaming() {
        isStreaming = false
        // In production, would unsubscribe from WebSocket
    }
    
    func getQuote(for symbol: String) -> MarketQuote? {
        quotes[symbol]
    }
    
    func getLatestCandle(for symbol: String, timeframe: String = "H1") -> MarketCandle? {
        candles[symbol]?.last
    }
    
    func getPriceChange(for symbol: String) -> PriceChange? {
        priceChanges[symbol]
    }
    
    // MARK: - Private Methods
    
    private func updateQuotes(from prices: [String: MetaAPISymbolPrice]) {
        for (symbol, price) in prices {
            let quote = MarketQuote(
                symbol: symbol,
                bid: price.bid,
                ask: price.ask,
                spread: price.ask - price.bid,
                timestamp: price.time
            )
            
            // Track price changes
            if let previousQuote = quotes[symbol] {
                priceChanges[symbol] = PriceChange(
                    previous: previousQuote.mid,
                    current: quote.mid
                )
            }
            
            quotes[symbol] = quote
        }
    }
    
    // MARK: - Mock Data Stream (for demo)
    
    private func startMockDataStream() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.generateMockQuotes()
            }
            .store(in: &cancellables)
    }
    
    private func generateMockQuotes() {
        let baseQuotes: [String: (bid: Double, ask: Double)] = [
            "EURUSD": (1.0850, 1.0852),
            "GBPUSD": (1.2750, 1.2752),
            "USDJPY": (155.50, 155.52),
            "AUDUSD": (0.6550, 0.6552),
            "BTCUSD": (98500, 98520),
            "ETHUSD": (3850, 3852),
            "XAUUSD": (2650, 2652)
        ]
        
        for (symbol, basePrice) in baseQuotes {
            // Add small random variation
            let variation = Double.random(in: -0.0005...0.0005)
            let bid = basePrice.bid + variation
            let ask = basePrice.ask + variation
            
            let quote = MarketQuote(
                symbol: symbol,
                bid: bid,
                ask: ask,
                spread: ask - bid,
                timestamp: Date()
            )
            
            // Track price changes
            if let previousQuote = quotes[symbol] {
                priceChanges[symbol] = PriceChange(
                    previous: previousQuote.mid,
                    current: quote.mid
                )
            }
            
            quotes[symbol] = quote
            
            // Generate mock tick
            if Bool.random() {
                let tick = MarketTick(
                    symbol: symbol,
                    price: Bool.random() ? bid : ask,
                    volume: Double.random(in: 0.01...10.0),
                    side: Bool.random() ? .buy : .sell,
                    timestamp: Date()
                )
                
                if ticks[symbol] == nil {
                    ticks[symbol] = []
                }
                ticks[symbol]?.append(tick)
                
                // Keep only last 100 ticks
                if let count = ticks[symbol]?.count, count > 100 {
                    ticks[symbol]?.removeFirst(count - 100)
                }
            }
        }
    }
}

// MARK: - Extensions

extension MarketDataService {
    func formatPrice(_ price: Double, for symbol: String) -> String {
        let decimals = symbol.contains("JPY") ? 2 : (symbol.contains("BTC") || symbol.contains("XAU") ? 0 : 4)
        return String(format: "%.\(decimals)f", price)
    }
    
    func formatSpread(_ spread: Double, for symbol: String) -> String {
        if symbol.contains("JPY") {
            return String(format: "%.1f", spread * 100) // In pips
        } else if symbol.contains("BTC") || symbol.contains("XAU") {
            return String(format: "%.0f", spread)
        } else {
            return String(format: "%.1f", spread * 10000) // In pips
        }
    }
}