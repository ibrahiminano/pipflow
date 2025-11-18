//
//  MetaAPIService.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

// MARK: - Account Verification Result

struct AccountVerificationResult {
    let isValid: Bool
    let accountInfo: TradingAccount?
    let error: String?
}

protocol MetaAPIServiceProtocol {
    func linkAccount(login: String, password: String, server: String, platform: TradingPlatform) -> AnyPublisher<TradingAccount, APIError>
    func getAccountInfo(accountId: String) -> AnyPublisher<TradingAccount, APIError>
    func getPositions(accountId: String) -> AnyPublisher<[Trade], APIError>
    func getHistory(accountId: String, from: Date, to: Date) -> AnyPublisher<[Trade], APIError>
    func placeOrder(accountId: String, order: MetaAPIOrderRequest) -> AnyPublisher<Trade, APIError>
    func closePosition(accountId: String, positionId: String) -> AnyPublisher<Void, APIError>
    func modifyPosition(accountId: String, positionId: String, stopLoss: Decimal?, takeProfit: Decimal?) -> AnyPublisher<Void, APIError>
    func getCandles(accountId: String, symbol: String, timeframe: String, startTime: Date, limit: Int) -> AnyPublisher<[MetaAPICandleData], APIError>
}

class MetaAPIService: MetaAPIServiceProtocol, ObservableObject {
    static let shared = MetaAPIService()
    
    @Published var accountInfo: AccountInfo?
    @Published var positions: [Position] = []
    @Published var isConnected = false
    @Published var isWebSocketConnected = false
    
    private let apiClient: APIClientProtocol
    private let webSocketService = MetaAPIWebSocketService.shared
    private let baseURL = "https://mt-client-api-v1.london.agiliumtrade.ai"
    private var authToken: String?
    private var accountId: String?
    private var cancellables = Set<AnyCancellable>()
    
    // Public getters
    var currentAccountId: String? { accountId }
    var currentAuthToken: String? { authToken }
    
    private init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
        setupWebSocketBindings()
    }
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    private func setupWebSocketBindings() {
        // Monitor WebSocket connection state
        webSocketService.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isWebSocketConnected = state == .connected
            }
            .store(in: &cancellables)
        
        // Update positions from WebSocket
        webSocketService.$positions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] wsPositions in
                self?.updatePositionsFromWebSocket(wsPositions)
            }
            .store(in: &cancellables)
        
        // Update account info from WebSocket
        webSocketService.$accountInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] wsAccountInfo in
                self?.updateAccountInfoFromWebSocket(wsAccountInfo)
            }
            .store(in: &cancellables)
    }
    
    private func updatePositionsFromWebSocket(_ wsPositions: [PositionData]) {
        self.positions = wsPositions.map { wsPosition in
            // Create TrackedPosition (which is typealiased as Position)
            TrackedPosition(
                id: wsPosition.id,
                symbol: wsPosition.symbol,
                type: wsPosition.type == "POSITION_TYPE_BUY" ? .buy : .sell,
                volume: wsPosition.volume,
                openPrice: wsPosition.openPrice,
                openTime: parseMetaAPIDate(wsPosition.time) ?? Date(),
                stopLoss: wsPosition.stopLoss,
                takeProfit: wsPosition.takeProfit,
                comment: nil,
                magic: nil,
                currentPrice: wsPosition.currentPrice ?? wsPosition.openPrice,
                bid: wsPosition.currentPrice ?? wsPosition.openPrice,
                ask: wsPosition.currentPrice ?? wsPosition.openPrice,
                unrealizedPL: wsPosition.profit,
                unrealizedPLPercent: 0, // Will be calculated
                commission: 0,
                swap: 0,
                netPL: wsPosition.profit,
                pipValue: 0.0001, // Default pip value
                pipsProfit: 0, // Will be calculated
                spread: 0,
                spreadCost: 0,
                marginUsed: 0,
                riskRewardRatio: nil,
                maxProfit: wsPosition.profit,
                maxLoss: 0
            )
        }
    }
    
    private func updateAccountInfoFromWebSocket(_ wsAccountInfo: AccountInformation?) {
        guard let info = wsAccountInfo else { return }
        
        self.accountInfo = AccountInfo(
            balance: info.balance,
            equity: info.equity,
            margin: info.margin,
            freeMargin: info.freeMargin,
            marginLevel: info.marginLevel
        )
    }
    
    private func calculateProfitPercentage(openPrice: Double, currentPrice: Double, side: String) -> Double {
        let priceDiff = currentPrice - openPrice
        let percentage = (priceDiff / openPrice) * 100
        return side == "POSITION_TYPE_BUY" ? percentage : -percentage
    }
    
    private func parseMetaAPIDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
    
    func linkAccount(login: String, password: String, server: String, platform: TradingPlatform) -> AnyPublisher<TradingAccount, APIError> {
        let endpoint = MetaAPIEndpoint.linkAccount(
            login: login,
            password: password,
            server: server,
            platform: platform,
            token: authToken
        )
        
        return apiClient.request(endpoint)
            .map { (response: MetaAPIAccountResponse) in
                self.accountId = response.id
                // Start WebSocket connection after successful account linking
                if let token = self.authToken {
                    self.startWebSocketConnection(accountId: response.id, authToken: token)
                }
                return response.toTradingAccount()
            }
            .eraseToAnyPublisher()
    }
    
    func getAccountInfo(accountId: String) -> AnyPublisher<TradingAccount, APIError> {
        let endpoint = MetaAPIEndpoint.getAccount(accountId: accountId, token: authToken)
        
        return apiClient.request(endpoint)
            .map { (response: MetaAPIAccountResponse) in
                return response.toTradingAccount()
            }
            .eraseToAnyPublisher()
    }
    
    func getPositions(accountId: String) -> AnyPublisher<[Trade], APIError> {
        let endpoint = MetaAPIEndpoint.getPositions(accountId: accountId, token: authToken)
        
        return apiClient.request(endpoint)
            .map { (response: [MetaAPIPositionResponse]) in
                return response.map { $0.toTrade() }
            }
            .eraseToAnyPublisher()
    }
    
    func getHistory(accountId: String, from: Date, to: Date) -> AnyPublisher<[Trade], APIError> {
        let endpoint = MetaAPIEndpoint.getHistory(
            accountId: accountId,
            from: from,
            to: to,
            token: authToken
        )
        
        return apiClient.request(endpoint)
            .map { (response: [MetaAPITradeResponse]) in
                return response.map { $0.toTrade() }
            }
            .eraseToAnyPublisher()
    }
    
    func placeOrder(accountId: String, order: MetaAPIOrderRequest) -> AnyPublisher<Trade, APIError> {
        let endpoint = MetaAPIEndpoint.placeOrder(
            accountId: accountId,
            order: order,
            token: authToken
        )
        
        return apiClient.request(endpoint)
            .map { (response: MetaAPIOrderResponse) in
                return response.toTrade()
            }
            .eraseToAnyPublisher()
    }
    
    func closePosition(accountId: String, positionId: String) -> AnyPublisher<Void, APIError> {
        let endpoint = MetaAPIEndpoint.closePosition(
            accountId: accountId,
            positionId: positionId,
            token: authToken
        )
        
        return apiClient.requestWithoutResponse(endpoint)
    }
    
    func modifyPosition(accountId: String, positionId: String, stopLoss: Decimal?, takeProfit: Decimal?) -> AnyPublisher<Void, APIError> {
        let endpoint = MetaAPIEndpoint.modifyPosition(
            accountId: accountId,
            positionId: positionId,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            token: authToken
        )
        
        return apiClient.requestWithoutResponse(endpoint)
    }
    
    func getCandles(accountId: String, symbol: String, timeframe: String, startTime: Date, limit: Int) -> AnyPublisher<[MetaAPICandleData], APIError> {
        let endpoint = MetaAPIEndpoint.getCandles(
            accountId: accountId,
            symbol: symbol,
            timeframe: timeframe,
            startTime: startTime,
            limit: limit,
            token: authToken
        )
        
        return apiClient.request(endpoint)
            .map { (response: [MetaAPICandleResponse]) in
                return response.map { $0.toCandleData() }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Async Methods for TradingService
    
    func connect(accountId: String, accountToken: String) async throws {
        self.accountId = accountId
        self.authToken = accountToken
        self.isConnected = true
        
        // In production, would establish WebSocket connection here
        // For now, we'll just mark as connected
    }
    
    // MARK: - Account Verification
    
    func verifyAccount(accountId: String) async throws -> AccountVerificationResult {
        // First, try to fetch account info
        do {
            let accountInfo = try await withCheckedThrowingContinuation { continuation in
                getAccountInfo(accountId: accountId)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { info in
                            continuation.resume(returning: info)
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            // Check if account is active
            guard accountInfo.isActive else {
                return AccountVerificationResult(
                    isValid: false,
                    accountInfo: accountInfo,
                    error: "Trading account is not active"
                )
            }
            
            // Check connection stability by subscribing to market data
            try await testMarketDataConnection(accountId: accountId)
            
            return AccountVerificationResult(
                isValid: true,
                accountInfo: accountInfo,
                error: nil as String?
            )
            
        } catch {
            return AccountVerificationResult(
                isValid: false,
                accountInfo: nil as TradingAccount?,
                error: error.localizedDescription
            )
        }
    }
    
    private func testMarketDataConnection(accountId: String) async throws {
        // Test WebSocket connection by subscribing to a common symbol
        webSocketService.subscribeToMarketData(symbols: ["EURUSD"])
        
        // Wait for first price update or timeout
        try await withTimeout(seconds: 10) {
            await withCheckedContinuation { continuation in
                self.webSocketService.$prices
                    .dropFirst()
                    .first()
                    .sink { _ in
                        continuation.resume()
                    }
                    .store(in: &self.cancellables)
            }
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw APIError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    func disconnect() {
        // Disconnect WebSocket
        webSocketService.disconnect()
        
        self.accountId = nil
        self.authToken = nil
        self.isConnected = false
        self.accountInfo = nil
        self.positions = []
    }
    
    // MARK: - WebSocket Methods
    
    func startWebSocketConnection(accountId: String, authToken: String) {
        self.accountId = accountId
        webSocketService.connect(authToken: authToken, accountId: accountId)
    }
    
    func subscribeToRealTimeData(symbols: [String]) {
        webSocketService.subscribeToMarketData(symbols: symbols)
    }
    
    func getCurrentPrice(for symbol: String) -> (bid: Double, ask: Double)? {
        guard let price = webSocketService.getPrice(for: symbol) else { return nil }
        return (bid: price.bid, ask: price.ask)
    }
    
    func fetchAccountInfo() async throws {
        guard accountId != nil else { return }
        
        // Mock account info for demo
        self.accountInfo = AccountInfo(
            balance: 10000.0,
            equity: 10500.0,
            margin: 1000.0,
            freeMargin: 9500.0,
            marginLevel: 1050.0
        )
    }
    
    func fetchPositions() async throws {
        guard let accountId = accountId else { return }
        
        // Mock positions for demo
        self.positions = []
    }
    
    func openPosition(symbol: String, side: TradeSide, volume: Double, stopLoss: Double?, takeProfit: Double?) async throws {
        guard let accountId = accountId else { throw TradingError.notConnected }
        
        // In production, would call MetaAPI to open position
        print("Opening position: \(symbol) \(side) \(volume)")
    }
    
    func closePosition(positionId: String) async throws {
        guard let accountId = accountId else { throw TradingError.notConnected }
        
        // In production, would call MetaAPI to close position
        print("Closing position: \(positionId)")
    }
    
    func modifyPosition(positionId: String, stopLoss: Double?, takeProfit: Double?) async throws {
        guard let accountId = accountId else { throw TradingError.notConnected }
        
        // In production, would call MetaAPI to modify position
        print("Modifying position: \(positionId)")
    }
    
    func getHistoricalCandles(accountId: String, symbol: String, timeframe: String, startTime: Date, endTime: Date) async throws -> [Candle] {
        let interval = endTime.timeIntervalSince(startTime)
        let limit = min(Int(interval / 3600), 1000) // Estimate candle count, max 1000
        
        return try await withCheckedThrowingContinuation { continuation in
            getCandles(accountId: accountId, symbol: symbol, timeframe: timeframe, startTime: startTime, limit: limit)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { candles in
                        let mappedCandles = candles.map { candle in
                            Candle(
                                timestamp: candle.timestamp,
                                open: candle.open,
                                high: candle.high,
                                low: candle.low,
                                close: candle.close,
                                volume: candle.volume
                            )
                        }
                        continuation.resume(returning: mappedCandles)
                    }
                )
                .store(in: &self.cancellables)
        }
    }
}

// MARK: - Supporting Types

struct AccountInfo {
    let balance: Double
    let equity: Double
    let margin: Double
    let freeMargin: Double
    let marginLevel: Double?
}

// MARK: - MetaAPI Response Models

private struct MetaAPIAccountResponse: Decodable {
    let id: String
    let login: String
    let server: String
    let platform: String
    let broker: String
    let currency: String
    let balance: Decimal
    let equity: Decimal
    let margin: Decimal
    let freeMargin: Decimal
    let marginLevel: Decimal?
    let state: String
    
    func toTradingAccount() -> TradingAccount {
        TradingAccount(
            id: UUID().uuidString,
            accountId: id,
            accountType: server.lowercased().contains("demo") ? .demo : .real,
            brokerName: broker,
            serverName: server,
            platformType: TradingPlatform(rawValue: platform.uppercased()) ?? .mt4,
            balance: Double(String(describing: balance)) ?? 0,
            equity: Double(String(describing: equity)) ?? 0,
            currency: currency,
            leverage: 100, // Default leverage, should be fetched from API
            isActive: state == "DEPLOYED",
            connectedDate: Date()
        )
    }
}

private struct MetaAPIPositionResponse: Decodable {
    let id: String
    let symbol: String
    let type: String
    let volume: Decimal
    let openPrice: Decimal
    let currentPrice: Decimal
    let stopLoss: Decimal?
    let takeProfit: Decimal?
    let profit: Decimal
    let swap: Decimal
    let commission: Decimal
    let openTime: String
    
    func toTrade() -> Trade {
        let dateFormatter = ISO8601DateFormatter()
        
        return Trade(
            id: UUID(),
            accountId: UUID(), // Will be set by the caller
            positionId: id,
            symbol: symbol,
            type: TradeType(rawValue: type) ?? .buy,
            volume: volume,
            openPrice: openPrice,
            currentPrice: currentPrice,
            closePrice: nil,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            commission: commission,
            swap: swap,
            profit: profit,
            status: .open,
            openTime: dateFormatter.date(from: openTime) ?? Date(),
            closeTime: nil,
            reason: .manual,
            comment: nil
        )
    }
}

private struct MetaAPITradeResponse: Decodable {
    let id: String
    let symbol: String
    let type: String
    let volume: Decimal
    let openPrice: Decimal
    let closePrice: Decimal
    let stopLoss: Decimal?
    let takeProfit: Decimal?
    let profit: Decimal
    let swap: Decimal
    let commission: Decimal
    let openTime: String
    let closeTime: String
    
    func toTrade() -> Trade {
        let dateFormatter = ISO8601DateFormatter()
        
        return Trade(
            id: UUID(),
            accountId: UUID(), // Will be set by the caller
            positionId: id,
            symbol: symbol,
            type: TradeType(rawValue: type) ?? .buy,
            volume: volume,
            openPrice: openPrice,
            currentPrice: closePrice,
            closePrice: closePrice,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            commission: commission,
            swap: swap,
            profit: profit,
            status: .closed,
            openTime: dateFormatter.date(from: openTime) ?? Date(),
            closeTime: dateFormatter.date(from: closeTime),
            reason: .manual,
            comment: nil
        )
    }
}

private struct MetaAPIOrderResponse: Decodable {
    let orderId: String
    
    func toTrade() -> Trade {
        // Simplified - in real implementation, we'd need more data
        Trade(
            id: UUID(),
            accountId: UUID(),
            positionId: orderId,
            symbol: "",
            type: .buy,
            volume: 0,
            openPrice: 0,
            currentPrice: 0,
            closePrice: nil,
            stopLoss: nil,
            takeProfit: nil,
            commission: 0,
            swap: 0,
            profit: 0,
            status: .pending,
            openTime: Date(),
            closeTime: nil,
            reason: .manual,
            comment: nil
        )
    }
}

// MARK: - Candle Data Models

struct MetaAPICandleData {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

private struct MetaAPICandleResponse: Decodable {
    let time: String
    let brokerTime: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let tickVolume: Int
    let spread: Int
    let volume: Int
    
    func toCandleData() -> MetaAPICandleData {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.date(from: time) ?? Date()
        
        return MetaAPICandleData(
            timestamp: timestamp,
            open: open,
            high: high,
            low: low,
            close: close,
            volume: Double(volume > 0 ? volume : tickVolume)
        )
    }
}