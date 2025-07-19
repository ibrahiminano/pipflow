//
//  ConnectedAccountsView.swift
//  Pipflow
//
//  Created by Claude on 19/07/2025.
//

import SwiftUI

struct ConnectedAccountsView: View {
    @StateObject private var tradingService = TradingService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingAddAccount = false
    @State private var showingDeleteAlert = false
    @State private var accountToDelete: TradingAccount?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if tradingService.connectedAccounts.isEmpty {
                    EmptyAccountsView(showingAddAccount: $showingAddAccount)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(tradingService.connectedAccounts) { account in
                                ConnectedAccountCard(
                                    account: account,
                                    isActive: account.id == tradingService.activeAccount?.id,
                                    onTap: {
                                        Task {
                                            await tradingService.switchAccount(account)
                                        }
                                    },
                                    onDelete: {
                                        accountToDelete = account
                                        showingDeleteAlert = true
                                    }
                                )
                            }
                            
                            // Add Account Button
                            Button(action: {
                                showingAddAccount = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Trading Account")
                                }
                                .font(.headline)
                                .foregroundColor(Color.Theme.accent)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.Theme.accent, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Trading Accounts")
            .navigationBarTitleDisplayMode(.large)
            .alert("Remove Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    if let account = accountToDelete {
                        tradingService.disconnectAccount(account)
                    }
                }
            } message: {
                Text("Are you sure you want to remove this trading account? This action cannot be undone.")
            }
            .sheet(isPresented: $showingAddAccount) {
                AccountLinkingView()
            }
        }
    }
}

// MARK: - Empty State

struct EmptyAccountsView: View {
    @Binding var showingAddAccount: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "link.circle")
                .font(.system(size: 80))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("No Trading Accounts")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text("Connect your MetaTrader account to start trading")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                showingAddAccount = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Trading Account")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Account Card

struct ConnectedAccountCard: View {
    let account: TradingAccount
    let isActive: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var tradingService = TradingService.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(account.brokerName)
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            if isActive {
                                Text("ACTIVE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.Theme.success)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text("Account ID: \(account.accountId)")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Account Type Badge
                        Text(account.accountType.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(account.accountType == .live ? Color.Theme.error : Color.Theme.warning)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        
                        // Platform Badge
                        Text(account.platformType.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(themeManager.currentTheme.backgroundColor)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .cornerRadius(4)
                    }
                }
                .padding()
                
                Divider()
                    .background(themeManager.currentTheme.separatorColor)
                
                // Account Details
                HStack {
                    AccountDetailItem(
                        title: "Balance",
                        value: String(format: "$%.2f", isActive ? tradingService.accountBalance : account.balance),
                        color: themeManager.currentTheme.textColor
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(themeManager.currentTheme.separatorColor)
                    
                    AccountDetailItem(
                        title: "Equity",
                        value: String(format: "$%.2f", isActive ? tradingService.accountEquity : account.equity),
                        color: themeManager.currentTheme.textColor
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(themeManager.currentTheme.separatorColor)
                    
                    AccountDetailItem(
                        title: "Leverage",
                        value: "1:\(account.leverage)",
                        color: Color.Theme.accent
                    )
                }
                .padding()
                
                // Connection Status
                if isActive {
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(tradingService.connectionStatus.isConnected ? Color.Theme.success : Color.Theme.error)
                                .frame(width: 8, height: 8)
                            
                            Text(connectionStatusText)
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        // Delete Button
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(Color.Theme.error)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.currentTheme.secondaryBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isActive ? Color.Theme.accent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var connectionStatusText: String {
        switch tradingService.connectionStatus {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

struct AccountDetailItem: View {
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ConnectedAccountsView()
        .environmentObject(ThemeManager.shared)
}