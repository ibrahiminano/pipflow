//
//  AccountLinkingView.swift
//  Pipflow
//
//  Created by Claude on 19/07/2025.
//

import SwiftUI

struct AccountLinkingView: View {
    @StateObject private var tradingService = TradingService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var accountId = ""
    @State private var accountPassword = ""
    @State private var serverName = ""
    @State private var serverType: ServerType = .mt5
    @State private var accountType: AccountType = .demo
    @State private var brokerName = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum ServerType: String, CaseIterable {
        case mt4 = "MetaTrader 4"
        case mt5 = "MetaTrader 5"
        
        var apiValue: String {
            switch self {
            case .mt4: return "mt4"
            case .mt5: return "mt5"
            }
        }
    }
    
    enum AccountType: String, CaseIterable {
        case demo = "Demo"
        case live = "Live"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.Theme.accent)
                            
                            Text("Link Trading Account")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Text("Connect your MetaTrader account to start trading")
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top)
                        
                        // Account Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Account Type")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            HStack(spacing: 12) {
                                ForEach(AccountType.allCases, id: \.self) { type in
                                    AccountTypeButton(
                                        title: type.rawValue,
                                        isSelected: accountType == type,
                                        color: type == .live ? Color.Theme.error : Color.Theme.success
                                    ) {
                                        accountType = type
                                    }
                                }
                            }
                        }
                        
                        // Platform Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trading Platform")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            HStack(spacing: 12) {
                                ForEach(ServerType.allCases, id: \.self) { type in
                                    PlatformButton(
                                        title: type.rawValue,
                                        isSelected: serverType == type
                                    ) {
                                        serverType = type
                                    }
                                }
                            }
                        }
                        
                        // Account Credentials
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Details")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            // Broker Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Broker Name")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                TextField("e.g., IC Markets, XM, etc.", text: $brokerName)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Account ID
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Account ID / Login")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                TextField("Enter your account ID", text: $accountId)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                SecureField("Enter your password", text: $accountPassword)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Server
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Server")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                TextField("e.g., ICMarkets-Demo01", text: $serverName)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.none)
                            }
                        }
                        
                        // Security Notice
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your credentials are encrypted")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                Text("We use bank-level encryption to protect your trading account information")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Link Account Button
                        Button(action: linkAccount) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "link")
                                }
                                Text(isLoading ? "Connecting..." : "Link Account")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .opacity(canLinkAccount ? 1 : 0.6)
                        }
                        .disabled(!canLinkAccount || isLoading)
                        
                        // Help Text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Need help finding your server details?")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Button(action: {
                                // Show help modal
                            }) {
                                Text("View Setup Guide")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.Theme.accent)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Link Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            .alert("Connection Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var canLinkAccount: Bool {
        !accountId.isEmpty && !accountPassword.isEmpty && !serverName.isEmpty && !brokerName.isEmpty
    }
    
    private func linkAccount() {
        isLoading = true
        
        Task {
            do {
                // Create account credentials
                let credentials = MetaAPICredentials(
                    accountId: accountId,
                    password: accountPassword,
                    serverName: serverName,
                    serverType: serverType.apiValue,
                    brokerName: brokerName,
                    accountType: accountType == .live ? "live" : "demo"
                )
                
                // Connect account via trading service
                try await tradingService.connectAccount(credentials: credentials)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Custom Components

struct AccountTypeButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? color : themeManager.currentTheme.secondaryTextColor)
                
                Text(title)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? color : themeManager.currentTheme.textColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.secondaryBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct PlatformButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                .frame(maxWidth: .infinity)
                .padding()
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        themeManager.currentTheme.secondaryBackgroundColor
                    }
                }
            )
            .cornerRadius(12)
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    @EnvironmentObject var themeManager: ThemeManager
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(themeManager.currentTheme.backgroundColor)
            .cornerRadius(8)
            .foregroundColor(themeManager.currentTheme.textColor)
    }
}

// MARK: - MetaAPI Credentials Model

struct MetaAPICredentials {
    let accountId: String
    let password: String
    let serverName: String
    let serverType: String
    let brokerName: String
    let accountType: String
}

#Preview {
    AccountLinkingView()
        .environmentObject(ThemeManager.shared)
}