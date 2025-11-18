//
//  MetaAPIWebSocketService.swift
//  Pipflow
//
//  Real-time WebSocket connection for MetaAPI
//

import Foundation
import Combine

// MARK: - WebSocket Message Types

struct MetaAPISubscribeMessage: Encodable {
    let type = "subscribe"
    let accountId: String
    let application = "Pipflow"
    let instanceIndex: Int = 0
}

struct MetaAPIUnsubscribeMessage: Encodable {
    let type = "unsubscribe"
    let accountId: String
}

struct MetaAPISynchronizeMessage: Encodable {
    let type = "synchronize"
    let accountId: String
    let instanceIndex: Int = 0
    let synchronizationId: String
    let application = "Pipflow"
    let host: String
    let keepAlive = true
}

// MARK: - WebSocket Response Types

struct MetaAPIWebSocketResponse: Decodable {
    let type: String
    let accountId: String?
    let instanceIndex: Int?
    let synchronizationId: String?
    let symbol: String?
    let accountInformation: AccountInformation?
    let specifications: [SymbolSpecification]?
    let positions: [PositionData]?
    let orders: [OrderData]?
    let price: PriceData?
    let candles: [CandleData]?
    let update: [PositionUpdate]?
    let deals: [DealData]?
    let historyOrders: [HistoryOrderData]?
}

struct AccountInformation: Decodable {
    let broker: String?
    let currency: String
    let server: String
    let balance: Double
    let equity: Double
    let margin: Double
    let freeMargin: Double
    let leverage: Int
    let marginLevel: Double?
    let tradeAllowed: Bool
}

struct SymbolSpecification: Decodable {
    let symbol: String
    let tickSize: Double
    let minVolume: Double
    let maxVolume: Double
    let volumeStep: Double
}

struct PositionData: Decodable {
    let id: String
    let type: String
    let symbol: String
    let magic: Int?
    let time: String
    let brokerTime: String?
    let openPrice: Double
    let volume: Double
    let swap: Double
    let commission: Double
    let profit: Double
    let currentPrice: Double?
    let currentTickValue: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let comment: String?
}

struct OrderData: Decodable {
    let id: String
    let type: String
    let state: String
    let symbol: String
    let magic: Int?
    let time: String
    let brokerTime: String?
    let openPrice: Double
    let currentPrice: Double?
    let volume: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let comment: String?
}

struct PriceData: Decodable {
    let symbol: String
    let bid: Double
    let ask: Double
    let brokerTime: String
    let profitTickValue: Double
    let lossTickValue: Double
}

struct CandleData: Decodable {
    let symbol: String
    let timeframe: String
    let time: String
    let brokerTime: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let tickVolume: Int
    let spread: Int
    let volume: Int
}

struct PositionUpdate: Decodable {
    let id: String
    let profit: Double?
    let currentPrice: Double?
    let currentTickValue: Double?
    let equity: Double?
    let margin: Double?
    let freeMargin: Double?
    let marginLevel: Double?
}

struct DealData: Decodable {
    let id: String
    let type: String
    let symbol: String
    let magic: Int?
    let time: String
    let brokerTime: String?
    let price: Double
    let volume: Double
    let profit: Double
    let swap: Double
    let commission: Double
    let positionId: String?
    let comment: String?
}

struct HistoryOrderData: Decodable {
    let id: String
    let type: String
    let state: String
    let symbol: String
    let magic: Int?
    let time: String
    let brokerTime: String?
    let doneTime: String?
    let doneBrokerTime: String?
    let openPrice: Double
    let volume: Double
    let doneVolume: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let comment: String?
}

// MARK: - WebSocket Service

class MetaAPIWebSocketService: ObservableObject {
    static let shared = MetaAPIWebSocketService()
    
    @Published var connectionState: WebSocketConnectionState = .disconnected
    @Published var accountInfo: AccountInformation?
    @Published var positions: [PositionData] = []
    @Published var orders: [OrderData] = []
    @Published var prices: [String: PriceData] = [:] // Symbol -> Price
    @Published var lastError: Error?
    
    private let webSocketManager: WebSocketManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private let decoder = JSONDecoder()
    
    private var authToken: String?
    private var currentAccountId: String?
    private var synchronizationId = UUID().uuidString
    
    private init(webSocketManager: WebSocketManagerProtocol = WebSocketManager()) {
        self.webSocketManager = webSocketManager
        setupBindings()
    }
    
    private func setupBindings() {
        // Monitor connection state
        webSocketManager.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
                if case .failed(let error) = state {
                    self?.lastError = error
                    print("WebSocket error: \(error)")
                }
            }
            .store(in: &cancellables)
        
        // Process incoming messages
        webSocketManager.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.processMessage(data)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func connect(authToken: String, accountId: String) {
        self.authToken = authToken
        self.currentAccountId = accountId
        
        // Create WebSocket URL with auth token as query parameter
        var components = URLComponents(string: "wss://mt-client-api-v1.london.agiliumtrade.ai/ws")
        components?.queryItems = [URLQueryItem(name: "auth-token", value: authToken)]
        
        guard let url = components?.url else {
            lastError = APIError.invalidURL
            return
        }
        
        webSocketManager.connect(to: url)
        
        // Monitor connection state changes
        webSocketManager.connectionStatePublisher
            .filter { $0.isConnected }
            .first()
            .sink { [weak self] _ in
                self?.subscribeToAccount()
            }
            .store(in: &cancellables)
    }
    
    func disconnect() {
        if let accountId = currentAccountId {
            let unsubscribeMessage = MetaAPIUnsubscribeMessage(accountId: accountId)
            webSocketManager.send(unsubscribeMessage)
        }
        
        webSocketManager.disconnect()
        currentAccountId = nil
    }
    
    func subscribeToMarketData(symbols: [String]) {
        // MetaAPI automatically streams market data for symbols in open positions
        // Additional symbols can be subscribed through terminal commands
        print("Market data will be streamed for symbols: \(symbols)")
    }
    
    // MARK: - Private Methods
    
    private func subscribeToAccount() {
        guard let accountId = currentAccountId else { return }
        
        // Subscribe to account
        let subscribeMessage = MetaAPISubscribeMessage(accountId: accountId)
        webSocketManager.send(subscribeMessage)
        
        // Synchronize account data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            let syncMessage = MetaAPISynchronizeMessage(
                accountId: accountId,
                synchronizationId: self.synchronizationId,
                host: "pipflow.ios.app"
            )
            self.webSocketManager.send(syncMessage)
        }
    }
    
    private func processMessage(_ data: Data) {
        do {
            let response = try decoder.decode(MetaAPIWebSocketResponse.self, from: data)
            
            switch response.type {
            case "authenticated":
                print("WebSocket authenticated")
                
            case "accountInformation":
                if let info = response.accountInformation {
                    accountInfo = info
                    print("Account info updated: Balance: \(info.balance), Equity: \(info.equity)")
                }
                
            case "specifications":
                if let specs = response.specifications {
                    print("Received \(specs.count) symbol specifications")
                }
                
            case "positions":
                if let positions = response.positions {
                    self.positions = positions
                    print("Positions updated: \(positions.count) positions")
                }
                
            case "orders":
                if let orders = response.orders {
                    self.orders = orders
                    print("Orders updated: \(orders.count) orders")
                }
                
            case "prices":
                if let symbol = response.symbol, let price = response.price {
                    prices[symbol] = price
                }
                
            case "candles":
                if let candles = response.candles {
                    print("Received \(candles.count) candles")
                }
                
            case "update":
                if let updates = response.update {
                    processPositionUpdates(updates)
                }
                
            case "deals":
                if let deals = response.deals {
                    print("New deals: \(deals.count)")
                }
                
            case "historyOrders":
                if let orders = response.historyOrders {
                    print("History orders: \(orders.count)")
                }
                
            case "synchronizationStarted":
                print("Synchronization started")
                
            case "synchronized":
                print("Account synchronized")
                
            default:
                print("Unknown message type: \(response.type)")
            }
            
        } catch {
            print("Failed to decode WebSocket message: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw message: \(jsonString)")
            }
        }
    }
    
    private func processPositionUpdates(_ updates: [PositionUpdate]) {
        // Create mutable copy of positions array
        var updatedPositions = positions
        
        for update in updates {
            if let index = updatedPositions.firstIndex(where: { $0.id == update.id }) {
                let position = updatedPositions[index]
                
                // Create updated position with new values
                let updatedPosition = PositionData(
                    id: position.id,
                    type: position.type,
                    symbol: position.symbol,
                    magic: position.magic,
                    time: position.time,
                    brokerTime: position.brokerTime,
                    openPrice: position.openPrice,
                    volume: position.volume,
                    swap: position.swap,
                    commission: position.commission,
                    profit: update.profit ?? position.profit,
                    currentPrice: update.currentPrice ?? position.currentPrice,
                    currentTickValue: update.currentTickValue ?? position.currentTickValue,
                    stopLoss: position.stopLoss,
                    takeProfit: position.takeProfit,
                    comment: position.comment
                )
                
                updatedPositions[index] = updatedPosition
                
                print("Position \(update.id) updated - Profit: \(update.profit ?? 0), Current Price: \(update.currentPrice ?? 0)")
            }
        }
        
        // Update positions array
        self.positions = updatedPositions
        
        // Update account metrics if provided
        if let firstUpdate = updates.first {
            var shouldUpdateAccount = false
            var newEquity = accountInfo?.equity ?? 0
            var newMargin = accountInfo?.margin ?? 0
            var newFreeMargin = accountInfo?.freeMargin ?? 0
            var newMarginLevel: Double? = accountInfo?.marginLevel
            
            if let equity = firstUpdate.equity {
                newEquity = equity
                shouldUpdateAccount = true
            }
            
            if let margin = firstUpdate.margin {
                newMargin = margin
                shouldUpdateAccount = true
            }
            
            if let freeMargin = firstUpdate.freeMargin {
                newFreeMargin = freeMargin
                shouldUpdateAccount = true
            }
            
            if let marginLevel = firstUpdate.marginLevel {
                newMarginLevel = marginLevel
                shouldUpdateAccount = true
            }
            
            if shouldUpdateAccount {
                accountInfo = AccountInformation(
                    broker: accountInfo?.broker,
                    currency: accountInfo?.currency ?? "USD",
                    server: accountInfo?.server ?? "",
                    balance: accountInfo?.balance ?? 0,
                    equity: newEquity,
                    margin: newMargin,
                    freeMargin: newFreeMargin,
                    leverage: accountInfo?.leverage ?? 100,
                    marginLevel: newMarginLevel,
                    tradeAllowed: accountInfo?.tradeAllowed ?? true
                )
            }
        }
    }
}

// MARK: - Convenience Methods for Integration

extension MetaAPIWebSocketService {
    func getPosition(by id: String) -> PositionData? {
        positions.first { $0.id == id }
    }
    
    func getPrice(for symbol: String) -> PriceData? {
        prices[symbol]
    }
    
    func getCurrentSpread(for symbol: String) -> Double? {
        guard let price = prices[symbol] else { return nil }
        return price.ask - price.bid
    }
    
    var totalProfit: Double {
        positions.reduce(0) { $0 + $1.profit }
    }
    
    var totalVolume: Double {
        positions.reduce(0) { $0 + $1.volume }
    }
}