//
//  MetaTraderLinkView.swift
//  Pipflow
//
//  MetaTrader Account Linking Interface
//

import SwiftUI

struct MetaTraderLinkView: View {
    @StateObject private var viewModel = MetaTraderLinkViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPlatformPicker = false
    @State private var showingBrokerHelp = false
    @State private var animateGradient = false
    @State private var showingVerification = false
    @State private var verifyingAccount: TradingAccount?
    @State private var showingBrokerSelection = false
    @State private var selectedBroker: SupportedBroker?
    @State private var connectionMethod: ConnectionMethod = .manual
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Background
                LinearGradient(
                    colors: [
                        Color(hex: "0F0F0F"),
                        Color(hex: "1A1A2E"),
                        Color(hex: "0F0F0F")
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                )
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Card
                        headerCard
                        
                        // Connection Method Selector
                        connectionMethodSelector
                        
                        // Form Fields or OAuth
                        if connectionMethod == .manual {
                            VStack(spacing: 20) {
                                platformSelector
                                loginField
                                passwordField
                                serverField
                                accountTypeToggle
                            }
                            .padding(.horizontal)
                        } else {
                            oauthBrokerSelector
                        }
                        
                        // Info Cards
                        infoSection
                        
                        // Connect Button
                        connectButton
                        
                        // Security Note
                        securityNote
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Link MetaTrader Account")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .alert("Connection Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingBrokerHelp) {
                BrokerHelpView()
            }
            .fullScreenCover(item: $viewModel.connectedAccount) { account in
                AccountVerificationView(account: account)
                    .onReceive(NotificationCenter.default.publisher(for: .accountVerified)) { notification in
                        if let verifiedAccount = notification.object as? TradingAccount {
                            // Store the verified account
                            viewModel.storeConnectedAccount(verifiedAccount)
                            // Dismiss everything
                            dismiss()
                        }
                    }
            }
            .sheet(item: $selectedBroker) { broker in
                BrokerOAuthView(broker: broker) { result in
                    handleOAuthResult(result)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Helper Methods
    
    private func handleOAuthResult(_ result: BrokerOAuthResult) {
        // Create trading account from OAuth result
        let account = TradingAccount(
            id: UUID().uuidString,
            accountId: result.accountInfo.accountId,
            accountType: .real,
            brokerName: result.broker.displayName,
            serverName: result.accountInfo.serverName,
            platformType: result.accountInfo.platform == .mt4 ? .mt4 : .mt5,
            balance: result.accountInfo.balance,
            equity: result.accountInfo.balance,
            currency: result.accountInfo.currency,
            leverage: result.accountInfo.leverage,
            isActive: true,
            connectedDate: Date()
        )
        
        // Store OAuth tokens securely
        let keychain = KeychainManager.shared
        keychain.saveAccessToken(result.accessToken, for: account.id)
        keychain.saveRefreshToken(result.refreshToken, for: account.id)
        
        // Set for verification
        viewModel.connectedAccount = account
    }
    
    // MARK: - Components
    
    var connectionMethodSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connection Method")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                ForEach(ConnectionMethod.allCases, id: \.self) { method in
                    Button(action: { connectionMethod = method }) {
                        VStack(spacing: 8) {
                            Image(systemName: method.icon)
                                .font(.title2)
                            
                            Text(method.title)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(connectionMethod == method ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(connectionMethod == method ? Color(hex: "00F5A0") : Color.white.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var oauthBrokerSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Your Broker")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Text("Choose your broker to connect securely via OAuth")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(SupportedBroker.allCases.filter { $0.supportsOAuth }, id: \.self) { broker in
                    Button(action: { selectedBroker = broker }) {
                        VStack(spacing: 12) {
                            Image(systemName: "building.2.fill")
                                .font(.largeTitle)
                                .foregroundColor(Color(hex: "00F5A0"))
                            
                            Text(broker.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Text("More brokers coming soon")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.top)
        }
    }
    
    var headerCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "00F5A0"))
                .shadow(color: Color(hex: "00F5A0").opacity(0.5), radius: 20)
            
            Text("Connect Your Trading Account")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Link your MT4 or MT5 account to start automated trading with AI-powered insights")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
    }
    
    var platformSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Platform")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Button(action: { showingPlatformPicker.toggle() }) {
                HStack {
                    Image(systemName: viewModel.selectedPlatform == .mt4 ? "4.circle.fill" : "5.circle.fill")
                        .foregroundColor(Color(hex: "00F5A0"))
                    
                    Text(viewModel.selectedPlatform.rawValue)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(showingPlatformPicker ? 180 : 0))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .actionSheet(isPresented: $showingPlatformPicker) {
                ActionSheet(
                    title: Text("Select Platform"),
                    buttons: [
                        .default(Text("MetaTrader 4")) {
                            viewModel.selectedPlatform = .mt4
                        },
                        .default(Text("MetaTrader 5")) {
                            viewModel.selectedPlatform = .mt5
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    var loginField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Login")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Account Number", text: $viewModel.login)
                    .foregroundColor(.white)
                    .keyboardType(.numberPad)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            HStack {
                Image(systemName: "lock.circle")
                    .foregroundColor(.white.opacity(0.5))
                
                SecureField("Password", text: $viewModel.password)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    var serverField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Server")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Button(action: { showingBrokerHelp = true }) {
                    Label("Find Server", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(Color(hex: "00F5A0"))
                }
            }
            
            HStack {
                Image(systemName: "server.rack")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("e.g., ICMarkets-Demo02", text: $viewModel.server)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    var accountTypeToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Account Type")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(spacing: 12) {
                ForEach([MTAccountType.demo, MTAccountType.real], id: \.self) { type in
                    Button(action: { viewModel.accountType = type }) {
                        HStack {
                            Image(systemName: type == .demo ? "graduationcap" : "dollarsign.circle")
                                .font(.caption)
                            
                            Text(type == .demo ? "Demo" : "Real")
                                .font(.subheadline)
                        }
                        .foregroundColor(viewModel.accountType == type ? .black : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.accountType == type ? Color(hex: "00F5A0") : Color.white.opacity(0.1))
                        )
                    }
                }
            }
        }
    }
    
    var infoSection: some View {
        VStack(spacing: 12) {
            InfoCard(
                icon: "checkmark.shield",
                title: "Secure Connection",
                description: "Your credentials are encrypted and never stored",
                color: Color(hex: "00F5A0")
            )
            
            InfoCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Real-Time Data",
                description: "Get live market data and execute trades instantly",
                color: Color(hex: "3A86FF")
            )
            
            InfoCard(
                icon: "cpu",
                title: "AI-Powered Trading",
                description: "Let our AI analyze markets and execute trades 24/7",
                color: Color(hex: "FF006E")
            )
        }
        .padding(.horizontal)
    }
    
    var connectButton: some View {
        Button(action: { viewModel.connectAccount() }) {
            if viewModel.isConnecting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .frame(height: 22)
            } else {
                HStack {
                    Image(systemName: "link")
                    Text("Connect Account")
                        .fontWeight(.semibold)
                }
            }
        }
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color(hex: "00F5A0"), Color(hex: "00D9FF")],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .disabled(viewModel.isConnecting || !viewModel.isFormValid)
        .opacity(viewModel.isFormValid ? 1 : 0.5)
        .padding(.horizontal)
        .padding(.top)
    }
    
    var securityNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.caption)
            
            Text("Your credentials are transmitted securely and are never stored on our servers")
                .font(.caption)
        }
        .foregroundColor(.white.opacity(0.5))
        .padding(.horizontal, 40)
        .padding(.top, 8)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Supporting Views

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct BrokerHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    let brokerServers = [
        ("IC Markets", ["ICMarkets-Demo02", "ICMarkets-Live06", "ICMarkets-Live07"]),
        ("XM", ["XMGlobal-Demo 3", "XMGlobal-Real 25", "XMGlobal-Real 26"]),
        ("Pepperstone", ["Pepperstone-Demo01", "Pepperstone-Live01", "Pepperstone-Edge01"]),
        ("FXCM", ["FXCM-USDDemo01", "FXCM-USDReal01", "FXCM-GBPReal01"]),
        ("Oanda", ["OANDA-Demo", "OANDA-Live", "OANDA-v20Live"])
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F0F0F").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Finding Your Server")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Text("Your server name can be found in your MetaTrader platform under Account Settings or in the email from your broker.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Common Broker Servers")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ForEach(brokerServers, id: \.0) { broker, servers in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(broker)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "00F5A0"))
                                    
                                    ForEach(servers, id: \.self) { server in
                                        Text(server)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "00F5A0"))
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum ConnectionMethod: String, CaseIterable {
    case manual = "Manual"
    case oauth = "OAuth"
    
    var title: String {
        switch self {
        case .manual: return "Manual Login"
        case .oauth: return "Broker OAuth"
        }
    }
    
    var icon: String {
        switch self {
        case .manual: return "key.fill"
        case .oauth: return "checkmark.shield.fill"
        }
    }
}

// MARK: - Extensions

extension SupportedBroker: Identifiable {
    var id: String { rawValue }
}

#Preview {
    MetaTraderLinkView()
}