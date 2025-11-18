//
//  PositionTrackingService.swift
//  Pipflow
//
//  Enhanced real-time position tracking with P&L calculations
//

import Foundation
import Combine
import SwiftUI

// MARK: - Enhanced Position Model

struct TrackedPosition: Identifiable, Hashable, Equatable {
    let id: String
    let symbol: String
    let type: PositionType
    let volume: Double
    let openPrice: Double
    let openTime: Date
    let stopLoss: Double?
    let takeProfit: Double?
    let comment: String?
    let magic: Int?
    
    // Real-time values
    var currentPrice: Double
    var bid: Double
    var ask: Double
    var unrealizedPL: Double
    var unrealizedPLPercent: Double
    var commission: Double
    var swap: Double
    var netPL: Double
    
    // Calculated values
    var pipValue: Double
    var pipsProfit: Double
    var spread: Double
    var spreadCost: Double
    var marginUsed: Double
    var riskRewardRatio: Double?
    
    // Performance metrics
    var maxProfit: Double = 0
    var maxLoss: Double = 0
    var durationInMinutes: Int {
        Int(Date().timeIntervalSince(openTime) / 60)
    }
    
    // Computed property for backward compatibility
    var profit: Double {
        unrealizedPL
    }
    
    // Additional computed properties
    var currentValue: Double {
        volume * currentPrice * 100000 // Standard lot size
    }
    
    var unrealizedPnL: Double {
        unrealizedPL
    }
    
    typealias PositionType = TradeType
}

// MARK: - Position Tracking Service

@MainActor
class PositionTrackingService: ObservableObject {
    static let shared = PositionTrackingService()
    
    @Published var trackedPositions: [TrackedPosition] = []
    @Published var totalUnrealizedPL: Double = 0
    @Published var totalRealizedPL: Double = 0
    @Published var totalVolume: Double = 0
    @Published var totalMarginUsed: Double = 0
    @Published var winRate: Double = 0
    @Published var averageWin: Double = 0
    @Published var averageLoss: Double = 0
    @Published var profitFactor: Double = 0
    
    private let metaAPIService = MetaAPIService.shared
    private let webSocketService = MetaAPIWebSocketService.shared
    private let marketDataService = MarketDataService.shared
    
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var priceUpdateCancellable: AnyCancellable?
    
    private init() {
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Monitor WebSocket positions
        webSocketService.$positions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] positions in
                self?.updateTrackedPositions(from: positions)
            }
            .store(in: &cancellables)
        
        // Monitor price updates
        webSocketService.$prices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] prices in
                self?.updatePositionPrices(from: prices)
            }
            .store(in: &cancellables)
        
        // Start update timer for P&L calculations
        startUpdateTimer()
    }
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.recalculateAllPositions()
            }
        }
    }
    
    // MARK: - Position Updates
    
    private func updateTrackedPositions(from positions: [PositionData]) {
        // Convert WebSocket positions to tracked positions
        let newTrackedPositions = positions.compactMap { position -> TrackedPosition? in
            guard let currentPrice = position.currentPrice else { return nil }
            
            let positionType = position.type.uppercased().contains("BUY") ? TradeType.buy : .sell
            let symbol = position.symbol
            
            // Get current market prices
            let marketQuote = marketDataService.quotes[symbol]
            let bid = marketQuote?.bid ?? currentPrice
            let ask = marketQuote?.ask ?? currentPrice
            
            // Calculate P&L
            let (unrealizedPL, pipsProfit) = calculatePL(
                type: positionType,
                openPrice: position.openPrice,
                currentPrice: currentPrice,
                volume: position.volume,
                symbol: symbol
            )
            
            let netPL = unrealizedPL - position.commission - position.swap
            let unrealizedPLPercent = (unrealizedPL / (position.openPrice * position.volume * 100000)) * 100
            
            // Calculate additional metrics
            let pipValue = calculatePipValue(symbol: symbol, volume: position.volume)
            let spread = ask - bid
            let spreadCost = spread * position.volume * 100000
            let marginUsed = calculateMarginUsed(
                symbol: symbol,
                volume: position.volume,
                openPrice: position.openPrice,
                leverage: webSocketService.accountInfo?.leverage ?? 100
            )
            
            // Calculate risk/reward if SL and TP are set
            let riskRewardRatio = calculateRiskRewardRatio(
                type: positionType,
                openPrice: position.openPrice,
                stopLoss: position.stopLoss,
                takeProfit: position.takeProfit
            )
            
            return TrackedPosition(
                id: position.id,
                symbol: symbol,
                type: positionType,
                volume: position.volume,
                openPrice: position.openPrice,
                openTime: dateFromString(position.time) ?? Date(),
                stopLoss: position.stopLoss,
                takeProfit: position.takeProfit,
                comment: position.comment,
                magic: position.magic,
                currentPrice: currentPrice,
                bid: bid,
                ask: ask,
                unrealizedPL: unrealizedPL,
                unrealizedPLPercent: unrealizedPLPercent,
                commission: position.commission,
                swap: position.swap,
                netPL: netPL,
                pipValue: pipValue,
                pipsProfit: pipsProfit,
                spread: spread,
                spreadCost: spreadCost,
                marginUsed: marginUsed,
                riskRewardRatio: riskRewardRatio
            )
        }
        
        // Update tracked positions
        trackedPositions = newTrackedPositions
        updateAggregateMetrics()
    }
    
    private func updatePositionPrices(from prices: [String: PriceData]) {
        for (index, position) in trackedPositions.enumerated() {
            if let priceData = prices[position.symbol] {
                var updatedPosition = position
                updatedPosition.bid = priceData.bid
                updatedPosition.ask = priceData.ask
                updatedPosition.currentPrice = position.type == .buy ? priceData.bid : priceData.ask
                updatedPosition.spread = priceData.ask - priceData.bid
                
                // Recalculate P&L
                let (unrealizedPL, pipsProfit) = calculatePL(
                    type: position.type,
                    openPrice: position.openPrice,
                    currentPrice: updatedPosition.currentPrice,
                    volume: position.volume,
                    symbol: position.symbol
                )
                
                updatedPosition.unrealizedPL = unrealizedPL
                updatedPosition.pipsProfit = pipsProfit
                updatedPosition.netPL = unrealizedPL - position.commission - position.swap
                updatedPosition.unrealizedPLPercent = (unrealizedPL / (position.openPrice * position.volume * 100000)) * 100
                
                // Track max profit/loss
                updatedPosition.maxProfit = max(updatedPosition.maxProfit, unrealizedPL)
                updatedPosition.maxLoss = min(updatedPosition.maxLoss, unrealizedPL)
                
                trackedPositions[index] = updatedPosition
            }
        }
        
        updateAggregateMetrics()
    }
    
    // MARK: - P&L Calculations
    
    private func calculatePL(type: TrackedPosition.PositionType, openPrice: Double, currentPrice: Double, volume: Double, symbol: String) -> (pl: Double, pips: Double) {
        let priceChange = type == .buy ? currentPrice - openPrice : openPrice - currentPrice
        let pips = calculatePips(priceChange: priceChange, symbol: symbol)
        let pl = priceChange * volume * getContractSize(symbol: symbol)
        return (pl, pips)
    }
    
    private func calculatePips(priceChange: Double, symbol: String) -> Double {
        if symbol.contains("JPY") {
            return priceChange * 100
        } else {
            return priceChange * 10000
        }
    }
    
    private func calculatePipValue(symbol: String, volume: Double) -> Double {
        let contractSize = getContractSize(symbol: symbol)
        if symbol.contains("JPY") {
            return volume * contractSize * 0.01
        } else {
            return volume * contractSize * 0.0001
        }
    }
    
    private func getContractSize(symbol: String) -> Double {
        // Standard forex contract size
        return 100000
    }
    
    private func calculateMarginUsed(symbol: String, volume: Double, openPrice: Double, leverage: Int) -> Double {
        let contractSize = getContractSize(symbol: symbol)
        let notionalValue = volume * contractSize * openPrice
        return notionalValue / Double(leverage)
    }
    
    private func calculateRiskRewardRatio(type: TrackedPosition.PositionType, openPrice: Double, stopLoss: Double?, takeProfit: Double?) -> Double? {
        guard let sl = stopLoss, let tp = takeProfit else { return nil }
        
        let risk = abs(openPrice - sl)
        let reward = abs(tp - openPrice)
        
        guard risk > 0 else { return nil }
        return reward / risk
    }
    
    // MARK: - Aggregate Metrics
    
    private func updateAggregateMetrics() {
        // Calculate totals
        totalUnrealizedPL = trackedPositions.reduce(0) { $0 + $1.netPL }
        totalVolume = trackedPositions.reduce(0) { $0 + $1.volume }
        totalMarginUsed = trackedPositions.reduce(0) { $0 + $1.marginUsed }
        
        // Calculate win rate from history (would need historical data)
        // For now, calculate from current positions
        let profitablePositions = trackedPositions.filter { $0.netPL > 0 }
        let losingPositions = trackedPositions.filter { $0.netPL < 0 }
        
        if !trackedPositions.isEmpty {
            winRate = Double(profitablePositions.count) / Double(trackedPositions.count) * 100
        }
        
        if !profitablePositions.isEmpty {
            averageWin = profitablePositions.reduce(0) { $0 + $1.netPL } / Double(profitablePositions.count)
        }
        
        if !losingPositions.isEmpty {
            averageLoss = abs(losingPositions.reduce(0) { $0 + $1.netPL } / Double(losingPositions.count))
        }
        
        if averageLoss > 0 {
            profitFactor = averageWin / averageLoss
        }
    }
    
    private func recalculateAllPositions() {
        // Force recalculation of all positions
        updatePositionPrices(from: webSocketService.prices)
    }
    
    // MARK: - Utility Methods
    
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    func getPosition(by id: String) -> TrackedPosition? {
        trackedPositions.first { $0.id == id }
    }
    
    func getPositions(for symbol: String) -> [TrackedPosition] {
        trackedPositions.filter { $0.symbol == symbol }
    }
    
    func getTotalExposure(for symbol: String) -> Double {
        getPositions(for: symbol).reduce(0) { total, position in
            total + (position.type == .buy ? position.volume : -position.volume)
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - Position Summary View

struct PositionSummaryCard: View {
    @ObservedObject var trackingService = PositionTrackingService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Total P&L
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unrealized P&L")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(String(format: "$%.2f", trackingService.totalUnrealizedPL))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(trackingService.totalUnrealizedPL >= 0 ? Color.Theme.success : Color.Theme.error)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Positions")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(trackingService.trackedPositions.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Metrics Grid
            HStack(spacing: 20) {
                PositionMetricView(title: "Win Rate", value: String(format: "%.1f%%", trackingService.winRate), color: Color.white)
                PositionMetricView(title: "Volume", value: String(format: "%.2f", trackingService.totalVolume), color: Color.white)
                PositionMetricView(title: "Margin", value: String(format: "$%.0f", trackingService.totalMarginUsed), color: Color.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct PositionMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(color.opacity(0.7))
            
            Text(value)
                .font(.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}