//
//  TradeExecutionService.swift
//  Pipflow
//
//  Handles trade execution with MetaAPI
//

import Foundation
import Combine

// MARK: - Trade Execution Models

struct ExecutionTradeRequest {
    let symbol: String
    let side: TradeSide
    let volume: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let comment: String?
    let magicNumber: Int?
    
    var validate: Result<Void, TradeValidationError> {
        if symbol.isEmpty {
            return .failure(.invalidSymbol)
        }
        if volume <= 0 {
            return .failure(.invalidVolume)
        }
        if let sl = stopLoss, let tp = takeProfit {
            if side == .buy && sl >= tp {
                return .failure(.invalidStopLoss)
            } else if side == .sell && sl <= tp {
                return .failure(.invalidStopLoss)
            }
        }
        return .success(())
    }
}

enum TradeValidationError: LocalizedError {
    case invalidSymbol
    case invalidVolume
    case invalidStopLoss
    case invalidTakeProfit
    case insufficientMargin
    case marketClosed
    
    var errorDescription: String? {
        switch self {
        case .invalidSymbol:
            return "Invalid trading symbol"
        case .invalidVolume:
            return "Invalid trade volume"
        case .invalidStopLoss:
            return "Stop loss must be below take profit for buy orders"
        case .invalidTakeProfit:
            return "Take profit must be above stop loss for buy orders"
        case .insufficientMargin:
            return "Insufficient margin for this trade"
        case .marketClosed:
            return "Market is closed for this symbol"
        }
    }
}

struct TradeExecutionResult {
    let orderId: String
    let symbol: String
    let side: TradeSide
    let volume: Double
    let openPrice: Double
    let executionTime: Date
}

// MARK: - Trade Execution Service

@MainActor
class TradeExecutionService: ObservableObject {
    static let shared = TradeExecutionService()
    
    @Published var isExecuting = false
    @Published var lastExecutionResult: TradeExecutionResult?
    @Published var executionError: Error?
    @Published var pendingOrders: [MetaAPIOrderRequest] = []
    
    private let metaAPIService = MetaAPIService.shared
    private let webSocketService = MetaAPIWebSocketService.shared
    private let syncService = AccountSyncService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        observePriceUpdates()
    }
    
    // MARK: - Public Methods
    
    func executeTrade(_ request: ExecutionTradeRequest) async throws -> TradeExecutionResult {
        // Validate request
        switch request.validate {
        case .failure(let error):
            throw error
        case .success:
            break
        }
        
        // Check connection
        guard metaAPIService.isConnected else {
            throw TradingError.notConnected
        }
        
        // Check margin
        try await validateMargin(for: request)
        
        isExecuting = true
        executionError = nil
        
        do {
            // Get current price for market order
            let currentPrice = getCurrentPrice(for: request.symbol, side: request.side)
            
            // Create MetaAPI order request
            let orderRequest = MetaAPIOrderRequest(
                symbol: request.symbol,
                volume: request.volume,
                actionType: request.side == .buy ? "ORDER_TYPE_BUY" : "ORDER_TYPE_SELL",
                stopLoss: request.stopLoss,
                takeProfit: request.takeProfit,
                comment: request.comment ?? "Pipflow Trade"
            )
            
            // Execute order
            let result = try await executeOrder(orderRequest)
            
            // Create execution result
            let executionResult = TradeExecutionResult(
                orderId: result.positionId,
                symbol: request.symbol,
                side: request.side,
                volume: request.volume,
                openPrice: currentPrice ?? 0,
                executionTime: Date()
            )
            
            lastExecutionResult = executionResult
            isExecuting = false
            
            // Trigger account sync
            Task {
                await syncService.syncAccount()
            }
            
            return executionResult
            
        } catch {
            isExecuting = false
            executionError = error
            throw error
        }
    }
    
    func closePosition(_ positionId: String) async throws {
        guard metaAPIService.isConnected else {
            throw TradingError.notConnected
        }
        
        guard let accountId = metaAPIService.currentAccountId else {
            throw TradingError.notConnected
        }
        
        isExecuting = true
        
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                metaAPIService.closePosition(accountId: accountId, positionId: positionId)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume(returning: ())
                            }
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &self.cancellables)
            }
            
            isExecuting = false
            
            // Trigger sync
            Task {
                await syncService.syncAccount()
            }
            
        } catch {
            isExecuting = false
            throw error
        }
    }
    
    func modifyPosition(_ positionId: String, stopLoss: Double?, takeProfit: Double?) async throws {
        guard metaAPIService.isConnected else {
            throw TradingError.notConnected
        }
        
        guard let accountId = metaAPIService.currentAccountId else {
            throw TradingError.notConnected
        }
        
        isExecuting = true
        
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                metaAPIService.modifyPosition(
                    accountId: accountId,
                    positionId: positionId,
                    stopLoss: stopLoss != nil ? Decimal(stopLoss!) : nil,
                    takeProfit: takeProfit != nil ? Decimal(takeProfit!) : nil
                )
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: ())
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &self.cancellables)
            }
            
            isExecuting = false
            
        } catch {
            isExecuting = false
            throw error
        }
    }
    
    // MARK: - Quick Trade Methods
    
    func quickBuy(symbol: String, volume: Double) async throws -> TradeExecutionResult {
        let request = ExecutionTradeRequest(
            symbol: symbol,
            side: .buy,
            volume: volume,
            stopLoss: nil,
            takeProfit: nil,
            comment: "Quick Buy",
            magicNumber: nil
        )
        return try await executeTrade(request)
    }
    
    func quickSell(symbol: String, volume: Double) async throws -> TradeExecutionResult {
        let request = ExecutionTradeRequest(
            symbol: symbol,
            side: .sell,
            volume: volume,
            stopLoss: nil,
            takeProfit: nil,
            comment: "Quick Sell",
            magicNumber: nil
        )
        return try await executeTrade(request)
    }
    
    // MARK: - Private Methods
    
    private func observePriceUpdates() {
        webSocketService.$prices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Update any pending order calculations
                self?.updatePendingOrders()
            }
            .store(in: &cancellables)
    }
    
    private func validateMargin(for request: ExecutionTradeRequest) async throws {
        guard let accountInfo = metaAPIService.accountInfo else {
            throw TradeValidationError.insufficientMargin
        }
        
        // Simple margin check (can be enhanced)
        let requiredMargin = estimateRequiredMargin(for: request)
        if accountInfo.freeMargin < requiredMargin {
            throw TradeValidationError.insufficientMargin
        }
    }
    
    private func estimateRequiredMargin(for request: ExecutionTradeRequest) -> Double {
        // Simplified margin calculation
        // In production, this should use symbol specifications
        let leverage = 100.0 // Default leverage
        let contractSize = request.symbol.contains("JPY") ? 100000 : 100000
        let estimatedPrice = getCurrentPrice(for: request.symbol, side: request.side) ?? 1.0
        
        return (request.volume * Double(contractSize) * estimatedPrice) / leverage
    }
    
    private func getCurrentPrice(for symbol: String, side: TradeSide) -> Double? {
        if let price = webSocketService.getPrice(for: symbol) {
            return side == .buy ? price.ask : price.bid
        }
        
        // Fallback to last known price
        if let price = metaAPIService.getCurrentPrice(for: symbol) {
            return side == .buy ? price.ask : price.bid
        }
        
        return nil
    }
    
    private func executeOrder(_ orderRequest: MetaAPIOrderRequest) async throws -> Trade {
        guard let accountId = metaAPIService.currentAccountId else {
            throw TradingError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            metaAPIService.placeOrder(accountId: accountId, order: orderRequest)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { trade in
                        continuation.resume(returning: trade)
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    private func updatePendingOrders() {
        // Update any calculations for pending orders
    }
}

// MARK: - Trade Execution Extensions

extension TradeExecutionService {
    func calculateStopLoss(for symbol: String, side: TradeSide, pips: Int) -> Double? {
        guard let currentPrice = getCurrentPrice(for: symbol, side: side) else { return nil }
        
        let pipValue = symbol.contains("JPY") ? 0.01 : 0.0001
        let pipDistance = Double(pips) * pipValue
        
        return side == .buy ? currentPrice - pipDistance : currentPrice + pipDistance
    }
    
    func calculateTakeProfit(for symbol: String, side: TradeSide, pips: Int) -> Double? {
        guard let currentPrice = getCurrentPrice(for: symbol, side: side) else { return nil }
        
        let pipValue = symbol.contains("JPY") ? 0.01 : 0.0001
        let pipDistance = Double(pips) * pipValue
        
        return side == .buy ? currentPrice + pipDistance : currentPrice - pipDistance
    }
    
    func estimateProfit(for symbol: String, side: TradeSide, volume: Double, pips: Int) -> Double {
        let pipValue = symbol.contains("JPY") ? 0.01 : 0.0001
        let contractSize = 100000.0 // Standard lot
        
        return volume * contractSize * Double(pips) * pipValue
    }
}