//
//  MockMetaAPIService.swift
//  Pipflow
//
//  Mock implementation of MetaAPIService for testing
//

import Foundation
import Combine

class MockMetaAPIService: MetaAPIServiceInterface {
    // Mock data storage
    private var mockAccounts: [String: TradingAccount] = [:]
    private var mockPositions: [String: [Position]] = [:]
    private var mockOrders: [String: [PendingOrder]] = [:]
    private var mockTrades: [Trade] = []
    
    // Publishers
    private let accountSubject = PassthroughSubject<TradingAccount, Never>()
    private let positionSubject = PassthroughSubject<[Position], Never>()
    private let orderSubject = PassthroughSubject<[PendingOrder], Never>()
    private let priceSubject = PassthroughSubject<MarketQuote, Never>()
    
    var accountUpdates: AnyPublisher<TradingAccount, Never> {
        accountSubject.eraseToAnyPublisher()
    }
    
    var positionUpdates: AnyPublisher<[Position], Never> {
        positionSubject.eraseToAnyPublisher()
    }
    
    var orderUpdates: AnyPublisher<[PendingOrder], Never> {
        orderSubject.eraseToAnyPublisher()
    }
    
    var priceUpdates: AnyPublisher<MarketQuote, Never> {
        priceSubject.eraseToAnyPublisher()
    }
    
    init() {
        setupMockData()
    }
    
    private func setupMockData() {
        // Create mock trading account
        let mockAccount = TradingAccount(
            id: "mock-account-1",
            accountId: "12345678",
            accountType: .demo,
            brokerName: "Mock Broker",
            serverName: "Demo-Server",
            platformType: .mt5,
            balance: 10000.0,
            equity: 10250.0,
            currency: "USD",
            leverage: 100,
            isActive: true,
            connectedDate: Date()
        )
        mockAccounts[mockAccount.id] = mockAccount
        
        // Create mock positions
        mockPositions[mockAccount.id] = [
            TrackedPosition(
                id: "pos-1",
                symbol: "EURUSD",
                type: .buy,
                volume: 0.1,
                openPrice: 1.0850,
                openTime: Date().addingTimeInterval(-3600),
                stopLoss: 1.0800,
                takeProfit: 1.0900,
                comment: nil,
                magic: nil,
                currentPrice: 1.0865,
                bid: 1.0864,
                ask: 1.0866,
                unrealizedPL: 15.0,
                unrealizedPLPercent: 0.138,
                commission: 0,
                swap: 0,
                netPL: 15.0,
                pipValue: 0.0001,
                pipsProfit: 15,
                spread: 0.0002,
                spreadCost: 0.2,
                marginUsed: 108.65,
                riskRewardRatio: 3.0,
                maxProfit: 15.0,
                maxLoss: 0
            ),
            TrackedPosition(
                id: "pos-2",
                symbol: "GBPUSD",
                type: .sell,
                volume: 0.05,
                openPrice: 1.2750,
                openTime: Date().addingTimeInterval(-7200),
                stopLoss: 1.2800,
                takeProfit: 1.2700,
                comment: nil,
                magic: nil,
                currentPrice: 1.2740,
                bid: 1.2739,
                ask: 1.2741,
                unrealizedPL: 5.0,
                unrealizedPLPercent: 0.078,
                commission: 0,
                swap: 0,
                netPL: 5.0,
                pipValue: 0.0001,
                pipsProfit: 10,
                spread: 0.0002,
                spreadCost: 0.1,
                marginUsed: 63.70,
                riskRewardRatio: 1.0,
                maxProfit: 5.0,
                maxLoss: 0
            )
        ]
        
        // Create mock orders
        mockOrders[mockAccount.id] = [
            PendingOrder(
                id: "ord-1",
                symbol: "XAUUSD",
                type: .buyLimit,
                volume: 0.01,
                price: 2000.0,
                stopLoss: 1990.0,
                takeProfit: 2020.0,
                createdAt: Date().addingTimeInterval(-1800)
            )
        ]
        
        // Start price simulation
        startPriceSimulation()
    }
    
    private func startPriceSimulation() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let symbols = ["EURUSD", "GBPUSD", "USDJPY", "XAUUSD", "BTCUSD"]
            let randomSymbol = symbols.randomElement()!
            
            let basePrice: Double
            switch randomSymbol {
            case "EURUSD": basePrice = 1.0850
            case "GBPUSD": basePrice = 1.2750
            case "USDJPY": basePrice = 150.50
            case "XAUUSD": basePrice = 2000.0
            case "BTCUSD": basePrice = 45000.0
            default: basePrice = 1.0
            }
            
            let randomChange = Double.random(in: -0.0010...0.0010)
            let bid = basePrice + randomChange
            let spread = randomSymbol.contains("USD") && !randomSymbol.contains("BTC") ? 0.0002 : 0.5
            let ask = bid + spread
            
            let quote = MarketQuote(
                symbol: randomSymbol,
                bid: bid,
                ask: ask,
                spread: spread,
                timestamp: Date()
            )
            
            self.priceSubject.send(quote)
        }
    }
    
    // MARK: - MetaAPIServiceInterface Implementation
    
    func connectAccount(_ account: TradingAccount) async throws {
        mockAccounts[account.id] = account
        accountSubject.send(account)
    }
    
    func disconnectAccount(_ accountId: String) async throws {
        mockAccounts.removeValue(forKey: accountId)
    }
    
    func getAccountInfo(_ accountId: String) async throws -> TradingAccount {
        guard let account = mockAccounts[accountId] else {
            throw APIError.custom("Account not found")
        }
        return account
    }
    
    func getPositions(_ accountId: String) async throws -> [Position] {
        return mockPositions[accountId] ?? []
    }
    
    func getOrders(_ accountId: String) async throws -> [PendingOrder] {
        return mockOrders[accountId] ?? []
    }
    
    func openTrade(_ accountId: String, request: TradeRequest) async throws -> Trade {
        let currentPrice = request.price ?? 1.0850 // Mock price
        let trade = Trade(
            id: UUID(),
            accountId: UUID(), // Convert string to UUID
            positionId: "POS-\(UUID().uuidString.prefix(8))",
            symbol: request.symbol,
            type: request.type,
            volume: Decimal(request.volume),
            openPrice: Decimal(currentPrice),
            currentPrice: Decimal(currentPrice),
            closePrice: nil,
            stopLoss: request.stopLoss.map { Decimal($0) },
            takeProfit: request.takeProfit.map { Decimal($0) },
            commission: Decimal(2.0), // Mock commission
            swap: Decimal(0),
            profit: Decimal(0),
            status: .open,
            openTime: Date(),
            closeTime: nil,
            reason: .manual,
            comment: request.comment
        )
        
        mockTrades.append(trade)
        
        // Create a new position
        let position = TrackedPosition(
            id: trade.positionId,
            symbol: trade.symbol,
            type: request.side == .buy ? .buy : .sell,
            volume: request.volume,
            openPrice: Double(String(describing: trade.openPrice)) ?? 0,
            openTime: trade.openTime,
            stopLoss: request.stopLoss,
            takeProfit: request.takeProfit,
            comment: request.comment,
            magic: nil,
            currentPrice: Double(String(describing: trade.currentPrice)) ?? 0,
            bid: (Double(String(describing: trade.currentPrice)) ?? 0) - 0.0001,
            ask: (Double(String(describing: trade.currentPrice)) ?? 0) + 0.0001,
            unrealizedPL: 0,
            unrealizedPLPercent: 0,
            commission: 0,
            swap: 0,
            netPL: 0,
            pipValue: 0.0001,
            pipsProfit: 0,
            spread: 0.0002,
            spreadCost: 0.2,
            marginUsed: request.volume * 100000 * (Double(String(describing: trade.openPrice)) ?? 0) / 100,
            riskRewardRatio: nil,
            maxProfit: 0,
            maxLoss: 0
        )
        
        if mockPositions[accountId] == nil {
            mockPositions[accountId] = []
        }
        mockPositions[accountId]?.append(position)
        positionSubject.send(mockPositions[accountId] ?? [])
        
        return trade
    }
    
    func closeTrade(_ accountId: String, positionId: String) async throws {
        mockPositions[accountId]?.removeAll { $0.id == positionId }
        positionSubject.send(mockPositions[accountId] ?? [])
    }
    
    func modifyPosition(_ accountId: String, positionId: String, stopLoss: Double?, takeProfit: Double?) async throws {
        guard let index = mockPositions[accountId]?.firstIndex(where: { $0.id == positionId }) else {
            throw APIError.custom("Position not found")
        }
        
        let oldPosition = mockPositions[accountId]![index]
        let updatedPosition = TrackedPosition(
            id: oldPosition.id,
            symbol: oldPosition.symbol,
            type: oldPosition.type,
            volume: oldPosition.volume,
            openPrice: oldPosition.openPrice,
            openTime: oldPosition.openTime,
            stopLoss: stopLoss ?? oldPosition.stopLoss,
            takeProfit: takeProfit ?? oldPosition.takeProfit,
            comment: oldPosition.comment,
            magic: oldPosition.magic,
            currentPrice: oldPosition.currentPrice,
            bid: oldPosition.bid,
            ask: oldPosition.ask,
            unrealizedPL: oldPosition.unrealizedPL,
            unrealizedPLPercent: oldPosition.unrealizedPLPercent,
            commission: oldPosition.commission,
            swap: oldPosition.swap,
            netPL: oldPosition.netPL,
            pipValue: oldPosition.pipValue,
            pipsProfit: oldPosition.pipsProfit,
            spread: oldPosition.spread,
            spreadCost: oldPosition.spreadCost,
            marginUsed: oldPosition.marginUsed,
            riskRewardRatio: oldPosition.riskRewardRatio,
            maxProfit: oldPosition.maxProfit,
            maxLoss: oldPosition.maxLoss
        )
        mockPositions[accountId]![index] = updatedPosition
        positionSubject.send(mockPositions[accountId] ?? [])
    }
    
    func cancelOrder(_ accountId: String, orderId: String) async throws {
        mockOrders[accountId]?.removeAll { $0.id == orderId }
        orderSubject.send(mockOrders[accountId] ?? [])
    }
    
    func getHistoricalTrades(_ accountId: String, startDate: Date?, endDate: Date?) async throws -> [Trade] {
        return mockTrades.filter { trade in
            // For mock purposes, return all trades
            if let start = startDate, trade.openTime < start { return false }
            if let end = endDate, trade.openTime > end { return false }
            return true
        }
    }
    
    func subscribeToMarketData(_ symbols: [String]) async throws {
        // Already handled by price simulation
    }
    
    func unsubscribeFromMarketData(_ symbols: [String]) async throws {
        // No-op for mock
    }
}

// Protocol definition for dependency injection
protocol MetaAPIServiceInterface {
    var accountUpdates: AnyPublisher<TradingAccount, Never> { get }
    var positionUpdates: AnyPublisher<[Position], Never> { get }
    var orderUpdates: AnyPublisher<[PendingOrder], Never> { get }
    var priceUpdates: AnyPublisher<MarketQuote, Never> { get }
    
    func connectAccount(_ account: TradingAccount) async throws
    func disconnectAccount(_ accountId: String) async throws
    func getAccountInfo(_ accountId: String) async throws -> TradingAccount
    func getPositions(_ accountId: String) async throws -> [Position]
    func getOrders(_ accountId: String) async throws -> [PendingOrder]
    func openTrade(_ accountId: String, request: TradeRequest) async throws -> Trade
    func closeTrade(_ accountId: String, positionId: String) async throws
    func modifyPosition(_ accountId: String, positionId: String, stopLoss: Double?, takeProfit: Double?) async throws
    func cancelOrder(_ accountId: String, orderId: String) async throws
    func getHistoricalTrades(_ accountId: String, startDate: Date?, endDate: Date?) async throws -> [Trade]
    func subscribeToMarketData(_ symbols: [String]) async throws
    func unsubscribeFromMarketData(_ symbols: [String]) async throws
}