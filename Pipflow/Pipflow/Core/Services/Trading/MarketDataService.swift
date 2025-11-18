//
//  MarketDataService.swift
//  Pipflow
//
//  Real-time market data service for AI signal generation
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

struct SupportResistanceLevels {
    let support: [Double]
    let resistance: [Double]
}

@MainActor
class MarketDataService: ObservableObject {
    static let shared = MarketDataService()
    
    @Published var marketData: [String: ExtendedMarketData] = [:]
    @Published var technicalData: [String: TechnicalIndicators] = [:]
    @Published var quotes: [String: MarketQuote] = [:]
    @Published var priceChanges: [String: PriceChange] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    
    let supportedSymbols = ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCAD", "BTCUSD", "ETHUSD", "XAUUSD", "XAGUSD", "USOIL"]
    
    private let metaAPIService = MetaAPIService.shared
    private let webSocketService = MetaAPIWebSocketService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSubscriptions()
        initializeMockData()
    }
    
    private func setupSubscriptions() {
        // Subscribe to real-time price updates
        webSocketService.$prices
            .sink { [weak self] prices in
                self?.updateMarketData(from: prices)
                self?.updateQuotes(from: prices)
            }
            .store(in: &cancellables)
    }
    
    private func initializeMockData() {
        // Initialize with mock data for demonstration
        let mockPrices: [String: (bid: Double, ask: Double)] = [
            "EURUSD": (bid: 1.0853, ask: 1.0855),
            "GBPUSD": (bid: 1.2748, ask: 1.2750),
            "USDJPY": (bid: 155.48, ask: 155.50),
            "XAUUSD": (bid: 2648.50, ask: 2650.50),
            "BTCUSD": (bid: 98450.00, ask: 98550.00),
            "ETHUSD": (bid: 3845.00, ask: 3855.00)
        ]
        
        for (symbol, prices) in mockPrices {
            let quote = MarketQuote(
                symbol: symbol,
                bid: prices.bid,
                ask: prices.ask,
                spread: prices.ask - prices.bid,
                timestamp: Date()
            )
            quotes[symbol] = quote
            
            // Initialize with random price changes for demo
            let changePercent = Double.random(in: -2.5...2.5)
            let changeValue = prices.bid * (changePercent / 100)
            priceChanges[symbol] = PriceChange(changeValue: changeValue, changePercent: changePercent)
        }
    }
    
    func fetchMarketData(for symbol: String) async throws -> MarketData {
        // First check if we have cached data
        if let cachedData = marketData[symbol],
           Date().timeIntervalSince(cachedData.lastUpdated) < 60 { // 1 minute cache
            return cachedData.marketData
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch historical data for technical analysis
            let candles = try await fetchHistoricalData(symbol: symbol, timeframe: "1h", count: 100)
            
            // Calculate technical indicators
            let indicators = calculateTechnicalIndicators(from: candles)
            technicalData[symbol] = indicators
            
            // Get current price from WebSocket or last candle
            let currentPrice = webSocketService.prices[symbol]?.bid ?? candles.last?.close ?? 0
            
            // Calculate 24h data
            let last24hCandles = candles.suffix(24)
            let high24h = last24hCandles.map { $0.high }.max() ?? currentPrice
            let low24h = last24hCandles.map { $0.low }.min() ?? currentPrice
            let volume24h = last24hCandles.map { $0.volume }.reduce(0, +)
            let open24h = last24hCandles.first?.open ?? currentPrice
            let priceChange24h = ((currentPrice - open24h) / open24h) * 100
            
            let extendedMarketData = ExtendedMarketData(
                symbol: symbol,
                currentPrice: currentPrice,
                high24h: high24h,
                low24h: low24h,
                volume24h: volume24h,
                priceChange24h: priceChange24h,
                bid: webSocketService.prices[symbol]?.bid ?? currentPrice,
                ask: webSocketService.prices[symbol]?.ask ?? currentPrice,
                spread: calculateSpread(
                    bid: webSocketService.prices[symbol]?.bid ?? currentPrice,
                    ask: webSocketService.prices[symbol]?.ask ?? currentPrice
                ),
                lastUpdated: Date()
            )
            
            self.marketData[symbol] = extendedMarketData
            
            // Also update quotes
            let quote = MarketQuote(
                symbol: symbol,
                bid: extendedMarketData.marketData.bid,
                ask: extendedMarketData.marketData.ask,
                spread: extendedMarketData.marketData.spread,
                timestamp: Date()
            )
            self.quotes[symbol] = quote
            
            return extendedMarketData.marketData
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    func fetchTechnicalIndicators(for symbol: String) async throws -> TechnicalIndicators {
        // Check cache first
        if let cached = technicalData[symbol],
           let extendedMarketData = self.marketData[symbol],
           Date().timeIntervalSince(extendedMarketData.lastUpdated) < 60 {
            return cached
        }
        
        // Fetch fresh data
        _ = try await fetchMarketData(for: symbol)
        
        guard let indicators = technicalData[symbol] else {
            throw NSError(domain: "MarketDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Technical indicators not found"])
        }
        
        return indicators
    }
    
    private func fetchHistoricalData(symbol: String, timeframe: String, count: Int) async throws -> [Candle] {
        guard let accountId = metaAPIService.currentAccountId else {
            // Return mock data for testing when no MetaAPI account is connected
            return generateMockCandles(symbol: symbol, count: count)
        }
        
        let endTime = Date()
        let startTime = endTime.addingTimeInterval(-Double(count * 3600)) // 1 hour per candle
        
        return try await metaAPIService.getHistoricalCandles(
            accountId: accountId,
            symbol: symbol,
            timeframe: timeframe,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    private func calculateTechnicalIndicators(from candles: [Candle]) -> TechnicalIndicators {
        let closes = candles.map { $0.close }
        
        // Calculate RSI
        let rsi = calculateRSI(prices: closes, period: 14)
        
        // Calculate MACD
        let macd = calculateMACD(prices: closes)
        
        // Calculate Moving Averages
        let ma20 = calculateSMA(prices: closes, period: 20)
        let ma50 = calculateSMA(prices: closes, period: 50)
        let ma200 = calculateSMA(prices: closes, period: 200)
        
        // Find support and resistance
        let (support, resistance) = findSupportResistance(candles: candles)
        
        // Determine trend
        let trend = determineTrend(candles: candles, ma20: ma20, ma50: ma50)
        
        return TechnicalIndicators(
            rsi: rsi,
            macd: macd,
            movingAverages: MovingAverages(ma20: ma20, ma50: ma50, ma200: ma200),
            support: support,
            resistance: resistance,
            trend: trend
        )
    }
    
    private func calculateRSI(prices: [Double], period: Int) -> Double {
        guard prices.count > period else { return 50 }
        
        var gains: [Double] = []
        var losses: [Double] = []
        
        for i in 1..<prices.count {
            let change = prices[i] - prices[i-1]
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(abs(change))
            }
        }
        
        let avgGain = gains.suffix(period).reduce(0, +) / Double(period)
        let avgLoss = losses.suffix(period).reduce(0, +) / Double(period)
        
        guard avgLoss != 0 else { return 100 }
        
        let rs = avgGain / avgLoss
        return 100 - (100 / (1 + rs))
    }
    
    private func calculateMACD(prices: [Double]) -> MACDIndicator? {
        guard prices.count >= 26 else { return nil }
        
        let ema12 = calculateEMA(prices: prices, period: 12)
        let ema26 = calculateEMA(prices: prices, period: 26)
        let macdLine = ema12 - ema26
        
        // Calculate signal line (9-period EMA of MACD)
        let macdValues = prices.indices.compactMap { index -> Double? in
            guard index >= 25 else { return nil }
            let ema12 = calculateEMA(prices: Array(prices[0...index]), period: 12)
            let ema26 = calculateEMA(prices: Array(prices[0...index]), period: 26)
            return ema12 - ema26
        }
        
        let signalLine = calculateEMA(prices: macdValues, period: 9)
        let histogram = macdLine - signalLine
        
        return MACDIndicator(macd: macdLine, signal: signalLine, histogram: histogram)
    }
    
    private func calculateEMA(prices: [Double], period: Int) -> Double {
        guard prices.count >= period else { return prices.last ?? 0 }
        
        let multiplier = 2.0 / Double(period + 1)
        var ema = prices.prefix(period).reduce(0, +) / Double(period)
        
        for i in period..<prices.count {
            ema = (prices[i] - ema) * multiplier + ema
        }
        
        return ema
    }
    
    private func calculateSMA(prices: [Double], period: Int) -> Double {
        guard prices.count >= period else { return prices.last ?? 0 }
        return prices.suffix(period).reduce(0, +) / Double(period)
    }
    
    private func findSupportResistance(candles: [Candle]) -> (support: Double, resistance: Double) {
        guard !candles.isEmpty else { return (0, 0) }
        
        let highs = candles.map { $0.high }
        let lows = candles.map { $0.low }
        
        // Simple approach: use recent swing high/low
        let recentHighs = highs.suffix(20)
        let recentLows = lows.suffix(20)
        
        let resistance = recentHighs.max() ?? highs.last ?? 0
        let support = recentLows.min() ?? lows.last ?? 0
        
        return (support, resistance)
    }
    
    private func determineTrend(candles: [Candle], ma20: Double, ma50: Double) -> TrendDirection {
        guard let currentPrice = candles.last?.close else { return .neutral }
        
        // Price above both MAs and MA20 > MA50 = Bullish
        if currentPrice > ma20 && currentPrice > ma50 && ma20 > ma50 {
            return .bullish
        }
        // Price below both MAs and MA20 < MA50 = Bearish
        else if currentPrice < ma20 && currentPrice < ma50 && ma20 < ma50 {
            return .bearish
        }
        
        return .neutral
    }
    
    private func calculateSpread(bid: Double, ask: Double) -> Double {
        return ask - bid
    }
    
    private func updateMarketData(from prices: [String: PriceData]) {
        for (symbol, priceData) in prices {
            if let existingData = marketData[symbol] {
                let updatedData = ExtendedMarketData(
                    symbol: symbol,
                    currentPrice: priceData.bid,
                    high24h: existingData.marketData.high24h,
                    low24h: existingData.marketData.low24h,
                    volume24h: existingData.marketData.volume24h,
                    priceChange24h: existingData.marketData.priceChange24h,
                    bid: priceData.bid,
                    ask: priceData.ask,
                    spread: calculateSpread(bid: priceData.bid, ask: priceData.ask),
                    lastUpdated: Date()
                )
                marketData[symbol] = updatedData
            }
        }
    }
    
    private func updateQuotes(from prices: [String: PriceData]) {
        for (symbol, priceData) in prices {
            let quote = MarketQuote(
                symbol: symbol,
                bid: priceData.bid,
                ask: priceData.ask,
                spread: calculateSpread(bid: priceData.bid, ask: priceData.ask),
                timestamp: Date()
            )
            
            // Calculate price change if we have previous data
            if let previousQuote = quotes[symbol] {
                let changeValue = priceData.bid - previousQuote.bid
                let changePercent = (changeValue / previousQuote.bid) * 100
                priceChanges[symbol] = PriceChange(changeValue: changeValue, changePercent: changePercent)
            }
            
            quotes[symbol] = quote
        }
    }
    
    // Mock news fetching - in production, integrate with news API
    func fetchRecentNews(for symbol: String) async -> [NewsItem] {
        // This would integrate with a news API in production
        return [
            NewsItem(
                title: "Fed Minutes Show Cautious Stance on Rate Cuts",
                summary: "Federal Reserve officials expressed caution about cutting interest rates too quickly.",
                sentiment: -0.2,
                timestamp: Date().addingTimeInterval(-3600)
            ),
            NewsItem(
                title: "\(symbol) Shows Strong Technical Setup",
                summary: "Technical analysts point to bullish patterns forming on the daily chart.",
                sentiment: 0.6,
                timestamp: Date().addingTimeInterval(-7200)
            )
        ]
    }
    
    // MARK: - Streaming Methods
    
    func startStreaming(symbols: [String]) {
        // Subscribe to real-time data for specified symbols
        webSocketService.subscribeToMarketData(symbols: symbols)
        
        // Initialize price changes for each symbol
        for symbol in symbols {
            if priceChanges[symbol] == nil {
                priceChanges[symbol] = PriceChange(changeValue: 0, changePercent: 0)
            }
        }
    }
    
    func stopStreaming(symbols: [String]) {
        // In production, would unsubscribe from WebSocket
        // For now, just remove from tracking
        for symbol in symbols {
            priceChanges.removeValue(forKey: symbol)
        }
    }
    
    // MARK: - Formatting Methods
    
    func formatPrice(_ price: Double, for symbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        // Determine decimal places based on symbol
        if symbol.contains("JPY") {
            formatter.minimumFractionDigits = 3
            formatter.maximumFractionDigits = 3
        } else if symbol.contains("BTC") || symbol.contains("ETH") {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        } else if symbol.contains("XAU") {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        } else {
            formatter.minimumFractionDigits = 4
            formatter.maximumFractionDigits = 5
        }
        
        return formatter.string(from: NSNumber(value: price)) ?? String(format: "%.4f", price)
    }
    
    func formatSpread(_ spread: Double, for symbol: String) -> String {
        if symbol.contains("JPY") {
            return String(format: "%.1f", spread * 100) // Convert to pipettes
        } else {
            return String(format: "%.1f", spread * 10000) // Convert to pips
        }
    }
    
    func stopStreaming() {
        // Stop all symbol streaming
        let symbols = Array(quotes.keys)
        stopStreaming(symbols: symbols)
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockCandles(symbol: String, count: Int) -> [Candle] {
        var candles: [Candle] = []
        let now = Date()
        
        // Base prices for different symbols
        let basePrices: [String: Double] = [
            "EURUSD": 1.0850,
            "GBPUSD": 1.2750,
            "USDJPY": 155.50,
            "AUDUSD": 0.6450,
            "BTCUSD": 98500,
            "ETHUSD": 3850,
            "XAUUSD": 2650
        ]
        
        let basePrice = basePrices[symbol] ?? 1.0
        var currentPrice = basePrice
        
        for i in (0..<count).reversed() {
            let timestamp = now.addingTimeInterval(-Double(i * 3600))
            
            // Generate random price movement
            let change = (Double.random(in: -0.002...0.002)) * currentPrice
            currentPrice += change
            
            let open = currentPrice
            let high = open + (Double.random(in: 0...0.001) * open)
            let low = open - (Double.random(in: 0...0.001) * open)
            let close = low + (Double.random(in: 0...(high - low)))
            let volume = Double.random(in: 100000...500000)
            
            candles.append(Candle(
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
            
            currentPrice = close
        }
        
        return candles
    }
    
    // MARK: - Synchronous Accessors for AI Auto Trading
    
    func getMarketData(for symbol: String) -> MarketData? {
        return marketData[symbol]?.marketData
    }
    
    var technicalIndicators: TechnicalIndicators? {
        // Return the most recent technical indicators
        guard let firstSymbol = technicalData.keys.first else { return nil }
        return technicalData[firstSymbol]
    }
    
    var supportResistanceLevels: SupportResistanceLevels? {
        // Return support/resistance levels from the most recent technical data
        guard let firstSymbol = technicalData.keys.first,
              let indicators = technicalData[firstSymbol] else { return nil }
        
        return SupportResistanceLevels(
            support: indicators.support.map { [$0] } ?? [],
            resistance: indicators.resistance.map { [$0] } ?? []
        )
    }
}

// MARK: - Extended MarketData Model

struct ExtendedMarketData {
    let marketData: MarketData
    let symbol: String
    let lastUpdated: Date
    
    init(symbol: String, currentPrice: Double, high24h: Double, low24h: Double, 
         volume24h: Double, priceChange24h: Double, bid: Double, ask: Double, 
         spread: Double, lastUpdated: Date = Date()) {
        self.symbol = symbol
        self.marketData = MarketData(
            currentPrice: currentPrice,
            high24h: high24h,
            low24h: low24h,
            volume24h: volume24h,
            priceChange24h: priceChange24h,
            bid: bid,
            ask: ask,
            spread: spread
        )
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Candle Model

struct Candle {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}