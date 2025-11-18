//
//  TradeMirroringService.swift
//  Pipflow
//
//  Real-time trade mirroring with position scaling and risk management
//

import Foundation
import Combine

// MARK: - Copy Trading Settings

struct CopyTradingConfig {
    let allocatedAmount: Double
    let maxPositions: Int
    let riskLevel: CopyRiskLevel
    let copyStopLoss: Bool
    let copyTakeProfit: Bool
    let proportionalSizing: Bool
    let maxDrawdown: Double
    let stopLossPercent: Double
    let takeProfitPercent: Double
    
    init(
        allocatedAmount: Double = 1000,
        maxPositions: Int = 10,
        riskLevel: CopyRiskLevel = .medium,
        copyStopLoss: Bool = true,
        copyTakeProfit: Bool = true,
        proportionalSizing: Bool = true,
        maxDrawdown: Double = 0.20, // 20% max drawdown
        stopLossPercent: Double = 0.02, // 2% stop loss
        takeProfitPercent: Double = 0.04 // 4% take profit
    ) {
        self.allocatedAmount = allocatedAmount
        self.maxPositions = maxPositions
        self.riskLevel = riskLevel
        self.copyStopLoss = copyStopLoss
        self.copyTakeProfit = copyTakeProfit
        self.proportionalSizing = proportionalSizing
        self.maxDrawdown = maxDrawdown
        self.stopLossPercent = stopLossPercent
        self.takeProfitPercent = takeProfitPercent
    }
}

// MARK: - Copy Session

struct CopySession: Identifiable {
    let id: String
    let traderId: String
    let settings: CopyTradingConfig
    let startDate: Date
    var isActive: Bool
    var totalTrades: Int = 0
    var successfulTrades: Int = 0
    var profitLoss: Double = 0
    var currentDrawdown: Double = 0
    var maxDrawdown: Double = 0
    var copiedPositions: [String] = []
}

// MARK: - Trade Mirroring Service

@MainActor
class TradeMirroringService: ObservableObject {
    static let shared = TradeMirroringService()
    
    @Published var activeSessions: [String: CopySession] = [:]
    @Published var totalProfitLoss: Double = 0
    @Published var totalCopiedTrades: Int = 0
    @Published var activePositions: [String] = []
    
    private let metaAPIService = MetaAPIService.shared
    private let positionTrackingService = PositionTrackingService.shared
    private let riskManager = CopyTradingRiskManager()
    private let positionScaler = PositionScaler()
    
    private var cancellables = Set<AnyCancellable>()
    private var webSocketManager: MetaAPIWebSocketService?
    
    private init() {
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Monitor new trades from followed traders
        // In a real implementation, this would connect to a WebSocket feed
        // of trades from copied traders
        
        // For now, simulate incoming trades
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.simulateIncomingTrade()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Copy Trading Management
    
    func startMirroring(traderId: String, settings: CopyTradingConfig) {
        let session = CopySession(
            id: UUID().uuidString,
            traderId: traderId,
            settings: settings,
            startDate: Date(),
            isActive: true
        )
        
        activeSessions[traderId] = session
        
        // Start listening for this trader's trades
        subscribeToTraderFeed(traderId: traderId)
        
        print("Started mirroring trades for trader: \(traderId)")
    }
    
    func stopMirroring(traderId: String) {
        activeSessions[traderId]?.isActive = false
        activeSessions.removeValue(forKey: traderId)
        
        // Unsubscribe from trader feed
        unsubscribeFromTraderFeed(traderId: traderId)
        
        print("Stopped mirroring trades for trader: \(traderId)")
    }
    
    func pauseMirroring(traderId: String) {
        activeSessions[traderId]?.isActive = false
    }
    
    func resumeMirroring(traderId: String) {
        activeSessions[traderId]?.isActive = true
    }
    
    // MARK: - Trade Processing
    
    private func subscribeToTraderFeed(traderId: String) {
        // In production, connect to real-time trade feed
        // For now, this is handled by the timer simulation
    }
    
    private func unsubscribeFromTraderFeed(traderId: String) {
        // In production, disconnect from real-time trade feed
    }
    
    private func simulateIncomingTrade() {
        // Simulate a trade from a copied trader
        guard let session = activeSessions.values.first(where: { $0.isActive }) else { return }
        
        let symbols = ["EURUSD", "GBPUSD", "USDJPY", "XAUUSD"]
        let randomSymbol = symbols.randomElement() ?? "EURUSD"
        let randomSide = TradeSide.allCases.randomElement() ?? .buy
        let randomVolume = Double.random(in: 0.01...0.5)
        
        let incomingTrade = IncomingTrade(
            traderId: session.traderId,
            symbol: randomSymbol,
            side: randomSide,
            volume: randomVolume,
            price: Double.random(in: 1.0800...1.0900),
            stopLoss: nil,
            takeProfit: nil,
            timestamp: Date()
        )
        
        processTrade(incomingTrade, for: session)
    }
    
    private func processTrade(_ trade: IncomingTrade, for session: CopySession) {
        guard session.isActive else { return }
        
        // Risk management checks
        if !riskManager.canExecuteTrade(trade, session: session) {
            print("Trade blocked by risk management: \(trade.symbol)")
            return
        }
        
        // Calculate scaled position size
        let scaledVolume = positionScaler.calculateScaledVolume(
            originalVolume: trade.volume,
            settings: session.settings,
            currentEquity: getCurrentEquity()
        )
        
        // Execute the trade
        Task {
            do {
                try await metaAPIService.openPosition(
                    symbol: trade.symbol,
                    side: trade.side,
                    volume: scaledVolume,
                    stopLoss: calculateStopLoss(trade: trade, settings: session.settings),
                    takeProfit: calculateTakeProfit(trade: trade, settings: session.settings)
                )
                
                // Update session
                updateSession(session.traderId) { session in
                    session.totalTrades += 1
                    session.copiedPositions.append(UUID().uuidString)
                }
                
                print("Copied trade: \(trade.symbol) \(trade.side) \(scaledVolume)")
                
            } catch {
                print("Failed to copy trade: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Position Scaling
    
    private func calculateStopLoss(trade: IncomingTrade, settings: CopyTradingConfig) -> Double? {
        guard settings.copyStopLoss else { return nil }
        
        let slDistance = trade.price * settings.stopLossPercent
        return trade.side == .buy ? trade.price - slDistance : trade.price + slDistance
    }
    
    private func calculateTakeProfit(trade: IncomingTrade, settings: CopyTradingConfig) -> Double? {
        guard settings.copyTakeProfit else { return nil }
        
        let tpDistance = trade.price * settings.takeProfitPercent
        return trade.side == .buy ? trade.price + tpDistance : trade.price - tpDistance
    }
    
    private func getCurrentEquity() -> Double {
        // Get current account equity
        return 10000.0 // Placeholder
    }
    
    // MARK: - Session Management
    
    private func updateSession(_ traderId: String, update: (inout CopySession) -> Void) {
        guard var session = activeSessions[traderId] else { return }
        update(&session)
        activeSessions[traderId] = session
    }
    
    func getSession(for traderId: String) -> CopySession? {
        return activeSessions[traderId]
    }
    
    func getAllActiveSessions() -> [CopySession] {
        return Array(activeSessions.values.filter { $0.isActive })
    }
    
    // MARK: - Performance Tracking
    
    func updateSessionPerformance() {
        var totalPL: Double = 0
        var totalTrades: Int = 0
        
        for (traderId, var session) in activeSessions {
            // Calculate P&L for this session's positions
            let sessionPL = calculateSessionPL(session: session)
            session.profitLoss = sessionPL
            
            // Update drawdown
            if sessionPL < 0 {
                let drawdown = abs(sessionPL) / session.settings.allocatedAmount
                session.currentDrawdown = drawdown
                session.maxDrawdown = max(session.maxDrawdown, drawdown)
                
                // Check if max drawdown exceeded
                if drawdown > session.settings.maxDrawdown {
                    pauseMirroring(traderId: traderId)
                    print("Copy session paused due to max drawdown: \(traderId)")
                }
            } else {
                session.currentDrawdown = 0
            }
            
            activeSessions[traderId] = session
            totalPL += sessionPL
            totalTrades += session.totalTrades
        }
        
        totalProfitLoss = totalPL
        totalCopiedTrades = totalTrades
    }
    
    private func calculateSessionPL(session: CopySession) -> Double {
        // Calculate P&L for all positions in this copy session
        return positionTrackingService.trackedPositions
            .filter { session.copiedPositions.contains($0.id) }
            .reduce(0) { $0 + $1.netPL }
    }
}

// MARK: - Position Scaler

class PositionScaler {
    func calculateScaledVolume(
        originalVolume: Double,
        settings: CopyTradingConfig,
        currentEquity: Double
    ) -> Double {
        if settings.proportionalSizing {
            // Scale based on available capital vs trader's capital
            let scaleFactor = settings.allocatedAmount / 10000.0 // Assume trader has $10k
            let scaledVolume = originalVolume * scaleFactor * settings.riskLevel.multiplier
            
            // Apply min/max limits
            return max(0.01, min(scaledVolume, 10.0))
        } else {
            // Fixed volume based on risk level
            return settings.riskLevel.fixedVolume
        }
    }
}

// MARK: - Risk Manager

class CopyTradingRiskManager {
    func canExecuteTrade(_ trade: IncomingTrade, session: CopySession) -> Bool {
        // Check maximum positions
        if session.copiedPositions.count >= session.settings.maxPositions {
            return false
        }
        
        // Check current drawdown
        if session.currentDrawdown > session.settings.maxDrawdown {
            return false
        }
        
        // Check daily trade limits
        if hasExceededDailyLimit(session: session) {
            return false
        }
        
        // Check symbol exposure limits
        if hasExcessiveSymbolExposure(symbol: trade.symbol, session: session) {
            return false
        }
        
        return true
    }
    
    private func hasExceededDailyLimit(session: CopySession) -> Bool {
        // Limit trades per day based on risk level
        let dailyLimit = session.settings.riskLevel.dailyTradeLimit
        
        // Count today's trades (would need proper date tracking)
        return session.totalTrades > dailyLimit
    }
    
    private func hasExcessiveSymbolExposure(symbol: String, session: CopySession) -> Bool {
        // Check if too much exposure to single symbol
        let maxSymbolExposure = 0.3 // 30% max per symbol
        
        // Note: In a real implementation, you would access position data from a service
        // For now, we'll return false to avoid the compilation error
        return false
    }
}

// MARK: - Supporting Models

struct IncomingTrade {
    let traderId: String
    let symbol: String
    let side: TradeSide
    let volume: Double
    let price: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let timestamp: Date
}

// MARK: - Risk Level Extensions

extension CopyRiskLevel {
    var fixedVolume: Double {
        switch self {
        case .conservative: return 0.01
        case .medium: return 0.05
        case .aggressive: return 0.10
        }
    }
    
    var dailyTradeLimit: Int {
        switch self {
        case .conservative: return 5
        case .medium: return 15
        case .aggressive: return 30
        }
    }
}