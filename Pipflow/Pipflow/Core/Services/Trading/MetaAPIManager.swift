//
//  MetaAPIManager.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

// MARK: - MetaAPI Models

struct MetaAPIAccount: Codable {
    let id: String
    let name: String
    let type: String
    let platform: String
    let state: String
    let connectionStatus: String
    let balance: Double
    let equity: Double
    let margin: Double
    let freeMargin: Double
    let leverage: Int
    let currency: String
}

struct MetaAPIPosition: Codable {
    let id: String
    let symbol: String
    let type: PositionType
    let volume: Double
    let openPrice: Double
    let currentPrice: Double
    let profit: Double
    let swap: Double
    let commission: Double
    let openTime: Date
    
    enum PositionType: String, Codable {
        case buy = "POSITION_TYPE_BUY"
        case sell = "POSITION_TYPE_SELL"
    }
}

struct MetaAPIOrder: Codable {
    let id: String
    let symbol: String
    let type: OrderType
    let volume: Double
    let openPrice: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let currentPrice: Double
    let openTime: Date
    
    enum OrderType: String, Codable {
        case buyLimit = "ORDER_TYPE_BUY_LIMIT"
        case sellLimit = "ORDER_TYPE_SELL_LIMIT"
        case buyStop = "ORDER_TYPE_BUY_STOP"
        case sellStop = "ORDER_TYPE_SELL_STOP"
    }
}

struct MetaAPISymbolPrice: Codable {
    let symbol: String
    let bid: Double
    let ask: Double
    let time: Date
}

// MARK: - MetaAPI Manager

class MetaAPIManager: ObservableObject {
    static let shared = MetaAPIManager()
    
    @Published var connectedAccounts: [MetaAPIAccount] = []
    @Published var positions: [MetaAPIPosition] = []
    @Published var orders: [MetaAPIOrder] = []
    @Published var symbolPrices: [String: MetaAPISymbolPrice] = [:]
    @Published var isConnected = false
    
    private var cancellables = Set<AnyCancellable>()
    private let apiClient: APIClientProtocol
    private var webSocketConnection: URLSessionWebSocketTask?
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Account Management
    
    func connectAccount(accountId: String, password: String) -> AnyPublisher<MetaAPIAccount, APIError> {
        // Create connection request
        let endpoint = MetaAPIEndpoint.deployAccount(accountId: accountId, token: AppEnvironment.MetaAPI.token)
        
        return apiClient.request(endpoint)
            .flatMap { (_: EmptyResponse) in
                // Wait for deployment
                self.waitForDeployment(accountId: accountId)
            }
            .flatMap { _ in
                // Get account info
                self.getAccountInfo(accountId: accountId)
            }
            .handleEvents(receiveOutput: { account in
                self.connectedAccounts.append(account)
                self.startWebSocketConnection(accountId: accountId)
            })
            .eraseToAnyPublisher()
    }
    
    func disconnectAccount(accountId: String) -> AnyPublisher<Void, APIError> {
        let endpoint = MetaAPIEndpoint.undeployAccount(accountId: accountId, token: AppEnvironment.MetaAPI.token)
        
        return apiClient.request(endpoint)
            .map { (_: EmptyResponse) in () }
            .handleEvents(receiveOutput: { _ in
                self.connectedAccounts.removeAll { $0.id == accountId }
                if self.connectedAccounts.isEmpty {
                    self.stopWebSocketConnection()
                }
            })
            .eraseToAnyPublisher()
    }
    
    private func getAccountInfo(accountId: String) -> AnyPublisher<MetaAPIAccount, APIError> {
        let endpoint = MetaAPIEndpoint.getAccount(accountId: accountId, token: AppEnvironment.MetaAPI.token)
        
        return apiClient.request(endpoint)
    }
    
    private func waitForDeployment(accountId: String, maxAttempts: Int = 30) -> AnyPublisher<Void, APIError> {
        Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect()
            .flatMap { _ in
                self.getAccountInfo(accountId: accountId)
            }
            .first { account in
                account.state == "DEPLOYED" && account.connectionStatus == "CONNECTED"
            }
            .map { _ in () }
            .timeout(.seconds(60), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Trading Operations
    
    func openPosition(
        accountId: String,
        symbol: String,
        volume: Double,
        side: TradeSide,
        stopLoss: Double? = nil,
        takeProfit: Double? = nil
    ) -> AnyPublisher<String, APIError> {
        let actionType = side == .buy ? "ORDER_TYPE_BUY" : "ORDER_TYPE_SELL"
        
        let orderRequest = MetaAPIOrderRequest(
            symbol: symbol,
            volume: volume,
            actionType: actionType,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            comment: nil
        )
        
        let endpoint = MetaAPIEndpoint.placeOrder(
            accountId: accountId,
            order: orderRequest,
            token: AppEnvironment.MetaAPI.token
        )
        
        return apiClient.request(endpoint)
            .map { (response: TradeResponse) in response.orderId }
            .eraseToAnyPublisher()
    }
    
    func closePosition(accountId: String, positionId: String) -> AnyPublisher<Void, APIError> {
        let endpoint = MetaAPIEndpoint.closePosition(
            accountId: accountId,
            positionId: positionId,
            token: AppEnvironment.MetaAPI.token
        )
        
        return apiClient.request(endpoint)
            .map { (_: EmptyResponse) in () }
            .eraseToAnyPublisher()
    }
    
    func modifyPosition(
        accountId: String,
        positionId: String,
        stopLoss: Double? = nil,
        takeProfit: Double? = nil
    ) -> AnyPublisher<Void, APIError> {
        let stopLossDecimal = stopLoss.map { Decimal($0) }
        let takeProfitDecimal = takeProfit.map { Decimal($0) }
        
        let endpoint = MetaAPIEndpoint.modifyPosition(
            accountId: accountId,
            positionId: positionId,
            stopLoss: stopLossDecimal,
            takeProfit: takeProfitDecimal,
            token: AppEnvironment.MetaAPI.token
        )
        
        return apiClient.request(endpoint)
            .map { (_: EmptyResponse) in () }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Market Data
    
    func subscribeToSymbols(_ symbols: [String]) {
        guard let webSocket = webSocketConnection else { return }
        
        let subscription: [String: Any] = [
            "type": "subscribe",
            "symbols": symbols
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: subscription) {
            let message = URLSessionWebSocketTask.Message.data(data)
            webSocket.send(message) { _ in }
        }
    }
    
    // MARK: - WebSocket Management
    
    private func startWebSocketConnection(accountId: String) {
        guard let url = URL(string: "\(AppEnvironment.MetaAPI.streamingURL)?auth-token=\(AppEnvironment.MetaAPI.token)") else { return }
        
        let session = URLSession(configuration: .default)
        webSocketConnection = session.webSocketTask(with: url)
        webSocketConnection?.resume()
        
        receiveWebSocketMessage()
        isConnected = true
    }
    
    private func stopWebSocketConnection() {
        webSocketConnection?.cancel(with: .goingAway, reason: nil)
        webSocketConnection = nil
        isConnected = false
    }
    
    private func receiveWebSocketMessage() {
        webSocketConnection?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleWebSocketMessage(message)
                self?.receiveWebSocketMessage() // Continue receiving
            case .failure(let error):
                print("WebSocket error: \(error)")
                self?.isConnected = false
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            handleWebSocketData(data)
        case .string(let string):
            if let data = string.data(using: .utf8) {
                handleWebSocketData(data)
            }
        @unknown default:
            break
        }
    }
    
    private func handleWebSocketData(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = json["type"] as? String {
                
                switch type {
                case "prices":
                    handlePriceUpdate(json)
                case "positions":
                    handlePositionsUpdate(json)
                case "orders":
                    handleOrdersUpdate(json)
                case "accountInformation":
                    handleAccountUpdate(json)
                default:
                    break
                }
            }
        } catch {
            print("Failed to parse WebSocket data: \(error)")
        }
    }
    
    private func handlePriceUpdate(_ json: [String: Any]) {
        guard let prices = json["prices"] as? [[String: Any]] else { return }
        
        for priceData in prices {
            guard let symbol = priceData["symbol"] as? String,
                  let bid = priceData["bid"] as? Double,
                  let ask = priceData["ask"] as? Double,
                  let timeString = priceData["time"] as? String else { continue }
            
            let formatter = ISO8601DateFormatter()
            let time = formatter.date(from: timeString) ?? Date()
            
            let symbolPrice = MetaAPISymbolPrice(
                symbol: symbol,
                bid: bid,
                ask: ask,
                time: time
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.symbolPrices[symbol] = symbolPrice
            }
        }
    }
    
    private func handlePositionsUpdate(_ json: [String: Any]) {
        // Parse and update positions
    }
    
    private func handleOrdersUpdate(_ json: [String: Any]) {
        // Parse and update orders
    }
    
    private func handleAccountUpdate(_ json: [String: Any]) {
        // Parse and update account info
    }
}

// MARK: - Supporting Types

private struct EmptyResponse: Codable {}

private struct TradeResponse: Codable {
    let orderId: String
}