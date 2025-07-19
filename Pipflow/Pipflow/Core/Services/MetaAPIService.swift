//
//  MetaAPIService.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

protocol MetaAPIServiceProtocol {
    func linkAccount(login: String, password: String, server: String, platform: TradingPlatform) -> AnyPublisher<TradingAccount, APIError>
    func getAccountInfo(accountId: String) -> AnyPublisher<TradingAccount, APIError>
    func getPositions(accountId: String) -> AnyPublisher<[Trade], APIError>
    func getHistory(accountId: String, from: Date, to: Date) -> AnyPublisher<[Trade], APIError>
    func placeOrder(accountId: String, order: MetaAPIOrderRequest) -> AnyPublisher<Trade, APIError>
    func closePosition(accountId: String, positionId: String) -> AnyPublisher<Void, APIError>
    func modifyPosition(accountId: String, positionId: String, stopLoss: Decimal?, takeProfit: Decimal?) -> AnyPublisher<Void, APIError>
}

@MainActor
class MetaAPIService: MetaAPIServiceProtocol, ObservableObject {
    static let shared = MetaAPIService()
    
    @Published var accountInfo: AccountInfo?
    @Published var positions: [Position] = []
    @Published var isConnected = false
    
    private let apiClient: APIClientProtocol
    private let baseURL = "https://mt-client-api-v1.london.agiliumtrade.ai"
    private var authToken: String?
    private var accountId: String?
    private var cancellables = Set<AnyCancellable>()
    
    private init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    func setAuthToken(_ token: String) {
        self.authToken = token
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
                // Convert MetaAPI response to our TradingAccount model
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
    
    // MARK: - Async Methods for TradingService
    
    func connect(accountId: String, accountToken: String) async throws {
        self.accountId = accountId
        self.authToken = accountToken
        self.isConnected = true
        
        // In production, would establish WebSocket connection here
        // For now, we'll just mark as connected
    }
    
    func disconnect() {
        self.accountId = nil
        self.authToken = nil
        self.isConnected = false
        self.accountInfo = nil
        self.positions = []
    }
    
    func fetchAccountInfo() async throws {
        guard let accountId = accountId else { return }
        
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
            balance: Double(truncating: balance as NSNumber),
            equity: Double(truncating: equity as NSNumber),
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