//
//  AccountConnectionManager.swift
//  Pipflow
//
//  Manages WebSocket connections for linked trading accounts
//

import SwiftUI
import Combine

@MainActor
class AccountConnectionManager: ObservableObject {
    static let shared = AccountConnectionManager()
    
    @Published var isConnecting = false
    @Published var connectionError: String?
    @Published var activeConnections: [String: WebSocketConnectionState] = [:] // accountId -> state
    
    private let metaAPIService = MetaAPIService.shared
    private let webSocketService = MetaAPIWebSocketService.shared
    private let keychainManager = KeychainManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Monitor WebSocket connection state changes
        webSocketService.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                // Update connection state for active account
                self?.updateConnectionState(state)
            }
            .store(in: &cancellables)
    }
    
    private func updateConnectionState(_ state: WebSocketConnectionState) {
        // Update the connection state for the currently active account
        // In a real implementation, we'd track which account is active
        if let firstAccountId = activeConnections.keys.first {
            activeConnections[firstAccountId] = state
        }
    }
    
    // MARK: - Public Methods
    
    /// Connect to a trading account's WebSocket feed
    func connectToAccount(_ account: TradingAccount) async {
        isConnecting = true
        connectionError = nil
        
        do {
            // Get access token from keychain
            guard let accessToken = keychainManager.getAccessToken(for: account.id) else {
                throw ConnectionError.noAccessToken
            }
            
            // For OAuth-connected accounts, use the stored token
            // For manually connected accounts, use MetaAPI token
            let authToken: String
            if account.isOAuthConnected {
                authToken = accessToken
            } else {
                // Get MetaAPI token for manual connections
                authToken = try await getMetaAPIToken(for: account)
            }
            
            // Connect WebSocket
            webSocketService.connect(authToken: authToken, accountId: account.accountId)
            
            // Store the active account ID
            activeConnections[account.accountId] = .connecting
            
            // Wait for connection to establish
            try await waitForConnection(accountId: account.accountId)
            
            isConnecting = false
            
        } catch {
            connectionError = error.localizedDescription
            isConnecting = false
        }
    }
    
    /// Disconnect from a trading account
    func disconnectFromAccount(_ accountId: String) {
        // Disconnect if this is the active account
        webSocketService.disconnect()
        activeConnections.removeValue(forKey: accountId)
    }
    
    /// Reconnect to all active accounts
    func reconnectAll() async {
        // Get all accounts with stored tokens
        let accounts = await getAllAccountsWithTokens()
        
        for account in accounts {
            await connectToAccount(account)
        }
    }
    
    // MARK: - Private Methods
    
    private func getMetaAPIToken(for account: TradingAccount) async throws -> String {
        // In a real implementation, this would authenticate with MetaAPI
        // For now, return mock token
        return "metaapi_token_\(account.accountId)"
    }
    
    private func waitForConnection(accountId: String, timeout: TimeInterval = 10) async throws {
        let startTime = Date()
        
        while activeConnections[accountId] != .connected {
            if Date().timeIntervalSince(startTime) > timeout {
                throw ConnectionError.timeout
            }
            
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
    }
    
    private func getAllAccountsWithTokens() async -> [TradingAccount] {
        // In a real app, this would fetch from local storage
        // For now, return empty array
        return []
    }
    
    // MARK: - Error Types
    
    enum ConnectionError: LocalizedError {
        case noAccessToken
        case timeout
        case authenticationFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .noAccessToken:
                return "No access token found for this account"
            case .timeout:
                return "Connection timeout"
            case .authenticationFailed(let message):
                return "Authentication failed: \(message)"
            }
        }
    }
}

// MARK: - Connection Status View

struct AccountConnectionStatusCard: View {
    @ObservedObject var connectionManager = AccountConnectionManager.shared
    let account: TradingAccount
    
    var connectionState: WebSocketConnectionState {
        connectionManager.activeConnections[account.accountId] ?? .disconnected
    }
    
    var body: some View {
        HStack {
            // Account Info
            VStack(alignment: .leading, spacing: 4) {
                Text(account.brokerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(account.accountId)
                    .font(.caption)
                    .foregroundColor(Color.Theme.secondaryText)
            }
            
            Spacer()
            
            // Connection Status
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(Color.Theme.secondaryText)
                
                if connectionManager.isConnecting && connectionState == .connecting {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            // Action Button
            Button(action: { toggleConnection() }) {
                Image(systemName: connectionState == .connected ? "stop.circle" : "play.circle")
                    .foregroundColor(Color.Theme.accent)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch connectionState {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        case .disconnecting:
            return .orange
        case .failed:
            return .red
        case .reconnecting:
            return .yellow
        }
    }
    
    private var statusText: String {
        switch connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .disconnecting:
            return "Disconnecting..."
        case .failed:
            return "Failed"
        case .reconnecting(let attempt):
            return "Reconnecting (attempt \(attempt))..."
        }
    }
    
    private func toggleConnection() {
        Task {
            if connectionState == .connected {
                connectionManager.disconnectFromAccount(account.accountId)
            } else {
                await connectionManager.connectToAccount(account)
            }
        }
    }
}

// MARK: - Extension for OAuth tracking

extension TradingAccount {
    var isOAuthConnected: Bool {
        // Check if this account was connected via OAuth
        // In a real app, this would be stored as a property
        KeychainManager.shared.getAccessToken(for: id) != nil
    }
}