//
//  TradingService.swift
//  Pipflow
//
//  Created by Claude on 19/07/2025.
//

import Foundation
import Combine

@MainActor
class TradingService: ObservableObject {
    static let shared = TradingService()
    
    @Published var connectedAccounts: [TradingAccount] = []
    @Published var activeAccount: TradingAccount?
    @Published var accountBalance: Double = 0
    @Published var accountEquity: Double = 0
    @Published var openPositions: [Position] = []
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isConnecting = false
    
    private let metaAPIService = MetaAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case error(String)
        
        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }
    }
    
    private init() {
        setupBindings()
        loadSavedAccounts()
    }
    
    private func setupBindings() {
        // Subscribe to MetaAPI updates
        metaAPIService.$accountInfo
            .sink { [weak self] info in
                guard let info = info else { return }
                self?.accountBalance = info.balance
                self?.accountEquity = info.equity
            }
            .store(in: &cancellables)
        
        metaAPIService.$positions
            .assign(to: &$openPositions)
    }
    
    private func loadSavedAccounts() {
        // Load saved accounts from UserDefaults or Keychain
        if let savedAccountsData = UserDefaults.standard.data(forKey: "tradingAccounts"),
           let accounts = try? JSONDecoder().decode([TradingAccount].self, from: savedAccountsData) {
            connectedAccounts = accounts
            
            // Set first account as active if available
            if let firstAccount = accounts.first {
                activeAccount = firstAccount
            }
        }
    }
    
    func connectAccount(credentials: MetaAPICredentials) async throws {
        isConnecting = true
        connectionStatus = .connecting
        
        do {
            // Create trading account object
            let account = TradingAccount(
                id: UUID().uuidString,
                accountId: credentials.accountId,
                accountType: credentials.accountType == "live" ? .live : .demo,
                brokerName: credentials.brokerName,
                serverName: credentials.serverName,
                platformType: credentials.serverType == "mt5" ? .mt5 : .mt4,
                balance: 0,
                equity: 0,
                currency: "USD",
                leverage: 100,
                isActive: true,
                connectedDate: Date()
            )
            
            // Connect via MetaAPI
            try await metaAPIService.connect(
                accountId: credentials.accountId,
                accountToken: "demo-token" // In production, get actual token from MetaAPI
            )
            
            // Add to connected accounts
            connectedAccounts.append(account)
            activeAccount = account
            
            // Save accounts
            saveAccounts()
            
            connectionStatus = .connected
            isConnecting = false
            
            // Start fetching account data
            await fetchAccountInfo()
            
        } catch {
            connectionStatus = .error(error.localizedDescription)
            isConnecting = false
            throw error
        }
    }
    
    func disconnectAccount(_ account: TradingAccount) {
        metaAPIService.disconnect()
        connectedAccounts.removeAll { $0.id == account.id }
        
        if activeAccount?.id == account.id {
            activeAccount = connectedAccounts.first
        }
        
        saveAccounts()
        connectionStatus = .disconnected
    }
    
    func switchAccount(_ account: TradingAccount) async {
        guard account.id != activeAccount?.id else { return }
        
        activeAccount = account
        connectionStatus = .connecting
        
        do {
            // Reconnect with new account
            try await metaAPIService.connect(
                accountId: account.accountId,
                accountToken: "demo-token"
            )
            
            connectionStatus = .connected
            await fetchAccountInfo()
            
        } catch {
            connectionStatus = .error(error.localizedDescription)
        }
    }
    
    func fetchAccountInfo() async {
        guard activeAccount != nil else { return }
        
        do {
            try await metaAPIService.fetchAccountInfo()
            try await metaAPIService.fetchPositions()
        } catch {
            print("Error fetching account info: \(error)")
        }
    }
    
    func refreshAccountData() async {
        await fetchAccountInfo()
    }
    
    private func saveAccounts() {
        if let encoded = try? JSONEncoder().encode(connectedAccounts) {
            UserDefaults.standard.set(encoded, forKey: "tradingAccounts")
        }
    }
    
    // MARK: - Trading Operations
    
    func openPosition(symbol: String, side: TradeSide, volume: Double, stopLoss: Double? = nil, takeProfit: Double? = nil) async throws {
        guard connectionStatus.isConnected else {
            throw TradingError.notConnected
        }
        
        try await metaAPIService.openPosition(
            symbol: symbol,
            side: side,
            volume: volume,
            stopLoss: stopLoss,
            takeProfit: takeProfit
        )
    }
    
    func closePosition(_ position: Position) async throws {
        guard connectionStatus.isConnected else {
            throw TradingError.notConnected
        }
        
        try await metaAPIService.closePosition(positionId: position.id)
    }
    
    func modifyPosition(_ position: Position, stopLoss: Double?, takeProfit: Double?) async throws {
        guard connectionStatus.isConnected else {
            throw TradingError.notConnected
        }
        
        try await metaAPIService.modifyPosition(
            positionId: position.id,
            stopLoss: stopLoss,
            takeProfit: takeProfit
        )
    }
}

// MARK: - Trading Errors

enum TradingError: LocalizedError {
    case notConnected
    case invalidCredentials
    case serverError(String)
    case insufficientBalance
    case invalidVolume
    case symbolNotFound
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "No trading account connected"
        case .invalidCredentials:
            return "Invalid account credentials"
        case .serverError(let message):
            return "Server error: \(message)"
        case .insufficientBalance:
            return "Insufficient account balance"
        case .invalidVolume:
            return "Invalid trade volume"
        case .symbolNotFound:
            return "Trading symbol not found"
        }
    }
}