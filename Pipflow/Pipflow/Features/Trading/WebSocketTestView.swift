//
//  WebSocketTestView.swift
//  Pipflow
//
//  Test view for WebSocket integration
//

import SwiftUI
import Combine

struct WebSocketTestView: View {
    @StateObject private var metaAPIService = MetaAPIService.shared
    @StateObject private var webSocketService = MetaAPIWebSocketService.shared
    @State private var authToken = ""
    @State private var accountId = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status
                    ConnectionStatusCard(
                        connectionState: webSocketService.connectionState,
                        isWebSocketConnected: metaAPIService.isWebSocketConnected
                    )
                    
                    // Connection Form
                    if webSocketService.connectionState == .disconnected {
                        ConnectionFormCard(
                            authToken: $authToken,
                            accountId: $accountId,
                            isConnecting: $isConnecting,
                            errorMessage: errorMessage,
                            onConnect: connectWebSocket
                        )
                    }
                    
                    // Account Info
                    if let accountInfo = webSocketService.accountInfo {
                        AccountInfoCard(accountInfo: accountInfo)
                    }
                    
                    // Positions
                    if !metaAPIService.positions.isEmpty {
                        PositionsCard(positions: metaAPIService.positions)
                    }
                    
                    // Real-time Prices
                    if !webSocketService.prices.isEmpty {
                        PricesCard(prices: webSocketService.prices)
                    }
                    
                    // Disconnect Button
                    if webSocketService.connectionState == .connected {
                        Button(action: disconnectWebSocket) {
                            Text("Disconnect")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("WebSocket Test")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func connectWebSocket() {
        guard !authToken.isEmpty && !accountId.isEmpty else {
            errorMessage = "Please enter both auth token and account ID"
            return
        }
        
        isConnecting = true
        errorMessage = nil
        
        // Set auth token and connect
        metaAPIService.setAuthToken(authToken)
        metaAPIService.startWebSocketConnection(accountId: accountId, authToken: authToken)
        
        // Reset form after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isConnecting = false
        }
    }
    
    private func disconnectWebSocket() {
        webSocketService.disconnect()
    }
}

struct ConnectionStatusCard: View {
    let connectionState: WebSocketConnectionState
    let isWebSocketConnected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
            }
            
            if isWebSocketConnected {
                Label("Real-time data streaming", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    var statusColor: Color {
        switch connectionState {
        case .connected:
            return .green
        case .connecting, .disconnecting:
            return .orange
        case .disconnected:
            return .gray
        case .failed:
            return .red
        case .reconnecting:
            return .yellow
        }
    }
    
    var statusText: String {
        switch connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnecting:
            return "Disconnecting..."
        case .disconnected:
            return "Disconnected"
        case .failed(let error):
            return "Failed: \(error.localizedDescription)"
        case .reconnecting(let attempt):
            return "Reconnecting (attempt \(attempt))..."
        }
    }
}

struct ConnectionFormCard: View {
    @Binding var authToken: String
    @Binding var accountId: String
    @Binding var isConnecting: Bool
    let errorMessage: String?
    let onConnect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connect to MetaAPI WebSocket")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Auth Token")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
                
                TextField("Enter MetaAPI auth token", text: $authToken)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Account ID")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
                
                TextField("Enter account ID", text: $accountId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button(action: onConnect) {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "link")
                    }
                    Text("Connect")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isConnecting)
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct AccountInfoCard: View {
    let accountInfo: AccountInformation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Information")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            HStack {
                WebSocketInfoRow(label: "Broker", value: accountInfo.broker ?? "N/A")
                Spacer()
                WebSocketInfoRow(label: "Currency", value: accountInfo.currency)
            }
            
            HStack {
                WebSocketInfoRow(label: "Balance", value: String(format: "%.2f", accountInfo.balance))
                Spacer()
                WebSocketInfoRow(label: "Equity", value: String(format: "%.2f", accountInfo.equity))
            }
            
            HStack {
                WebSocketInfoRow(label: "Margin", value: String(format: "%.2f", accountInfo.margin))
                Spacer()
                WebSocketInfoRow(label: "Free Margin", value: String(format: "%.2f", accountInfo.freeMargin))
            }
            
            if let marginLevel = accountInfo.marginLevel {
                WebSocketInfoRow(label: "Margin Level", value: String(format: "%.2f%%", marginLevel))
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct WebSocketInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color.Theme.text.opacity(0.6))
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color.Theme.text)
        }
    }
}

struct PositionsCard: View {
    let positions: [Position]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Open Positions (\(positions.count))")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
                .padding(.horizontal)
            
            ForEach(positions) { position in
                PositionCardView(position: position)
                    .padding(.horizontal)
            }
        }
    }
}

struct PricesCard: View {
    let prices: [String: PriceData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Real-time Prices")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            ForEach(Array(prices.keys.sorted()), id: \.self) { symbol in
                if let price = prices[symbol] {
                    HStack {
                        Text(symbol)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color.Theme.text)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Bid: \(String(format: "%.5f", price.bid))")
                                .font(.caption)
                                .foregroundColor(Color.Theme.sell)
                            Text("Ask: \(String(format: "%.5f", price.ask))")
                                .font(.caption)
                                .foregroundColor(Color.Theme.buy)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    WebSocketTestView()
}