//
//  FuturisticMetaTraderLinkView.swift
//  Pipflow
//
//  Revolutionary MetaTrader Connection Interface
//

import SwiftUI

struct FuturisticMetaTraderLinkView: View {
    @StateObject private var viewModel = MetaTraderLinkViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingPlatformPicker = false
    @State private var showingBrokerHelp = false
    @State private var scanAnimation = false
    @State private var dataTransfer = false
    @State private var connectionPulse = false
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            // Neural network background
            NeuralNetworkBackground()
                .opacity(0.4)
            
            // Main content
            ScrollView {
                VStack(spacing: 32) {
                    // Holographic header
                    holographicHeader
                    
                    // Connection form in floating containers
                    VStack(spacing: 24) {
                        platformQuantumSelector
                        credentialsHologram
                        securityMatrix
                    }
                    
                    // Connection button
                    quantumConnectButton
                    
                    // Trust indicators
                    trustIndicators
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            }
            
            // Floating help assistant
            floatingHelpAssistant
            
            // Scan overlay when connecting
            if viewModel.isConnecting {
                scanOverlay
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .alert("Connection Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showingBrokerHelp) {
            FuturisticBrokerHelpView()
        }
    }
    
    // MARK: - Holographic Header
    
    var holographicHeader: some View {
        VStack(spacing: 24) {
            // Close button
            HStack {
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.neonCyan.opacity(0.5), lineWidth: 1)
                            )
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            
            // Main header content
            VStack(spacing: 20) {
                // Animated connection icon
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.neonCyan, .electricBlue, .neonPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(scanAnimation ? 360 : 0))
                        .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: scanAnimation)
                    
                    // Inner icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.neonCyan.opacity(0.3),
                                        Color.deepSpace
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.neonCyan)
                            .neonGlow(color: .neonCyan, radius: 20)
                    }
                    .scaleEffect(connectionPulse ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: connectionPulse)
                }
                
                // Title with typing effect
                VStack(spacing: 12) {
                    Text("NEURAL LINK PROTOCOL")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.neonCyan, .electricBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .neonGlow(color: .neonCyan, radius: 5)
                    
                    Text("Establishing quantum tunnel to MetaTrader servers")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            scanAnimation = true
            connectionPulse = true
        }
    }
    
    // MARK: - Platform Quantum Selector
    
    var platformQuantumSelector: some View {
        Text("Platform Selector")
            .padding()
        /* VStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Platform Selection")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    ForEach([TradingPlatform.mt4, TradingPlatform.mt5], id: \.self) { platform in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedPlatform = platform
                            }
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    // Background
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            viewModel.selectedPlatform == platform ?
                                            LinearGradient(
                                                colors: [.neonCyan, .electricBlue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ) :
                                            AnyShapeStyle(Color.white.opacity(0.1))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    viewModel.selectedPlatform == platform ? Color.clear : Color.white.opacity(0.2),
                                                    lineWidth: 1
                                                )
                                        )
                                    
                                    // Icon
                                    Image(systemName: platform == .mt4 ? "4.circle" : "5.circle")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(
                                            viewModel.selectedPlatform == platform ? .black : .white
                                        )
                                }
                                .frame(height: 80)
                                
                                Text(platform.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(
                                        viewModel.selectedPlatform == platform ? .neonCyan : .white.opacity(0.7)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .scaleEffect(viewModel.selectedPlatform == platform ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedPlatform)
                    }
                }
            }
            .padding(24)
        } */
    }
    
    // MARK: - Credentials Hologram
    
    var credentialsHologram: some View {
        Text("Credentials Form")
            .padding()
        /* VStack {
            VStack(spacing: 24) {
                Text("Authentication Matrix")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 20) {
                    // Login field
                    HoloField(
                        title: "Account ID",
                        placeholder: "Enter your trading account number",
                        text: $viewModel.login,
                        icon: "person.circle",
                        keyboardType: .numberPad
                    )
                    
                    // Password field
                    HoloField(
                        title: "Security Key",
                        placeholder: "Enter your account password",
                        text: $viewModel.password,
                        icon: "lock.circle",
                        isSecure: true
                    )
                    
                    // Server field with helper
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Server Node")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Button(action: { showingBrokerHelp = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "questionmark.circle")
                                    Text("Find Server")
                                }
                                .font(.caption)
                                .foregroundColor(.neonCyan)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.neonCyan.opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.neonCyan.opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        HoloField(
                            title: "",
                            placeholder: "e.g., ICMarkets-Demo02",
                            text: $viewModel.server,
                            icon: "server.rack"
                        )
                    }
                    
                    // Account type selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Environment")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 12) {
                            ForEach([MTAccountType.demo, MTAccountType.real], id: \.self) { type in
                                Button(action: { viewModel.accountType = type }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: type == .demo ? "graduationcap" : "dollarsign.circle")
                                            .font(.system(size: 16))
                                        
                                        Text(type == .demo ? "Simulation" : "Live Trading")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(viewModel.accountType == type ? .black : .white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                viewModel.accountType == type ?
                                                LinearGradient(
                                                    colors: type == .demo ? [.plasmaGreen, .neonCyan] : [.neonPink, .neonPurple],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ) :
                                                AnyShapeStyle(Color.white.opacity(0.1))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        viewModel.accountType == type ? Color.clear : Color.white.opacity(0.2),
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .padding(24)
        } */
    }
    
    // MARK: - Security Matrix
    
    var securityMatrix: some View {
        HolographicCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.title2)
                        .foregroundColor(.plasmaGreen)
                        .neonGlow(color: .plasmaGreen, radius: 10)
                    
                    Text("Security Protocol")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    SecurityFeature(
                        icon: "lock.shield.fill",
                        title: "Quantum Encryption",
                        description: "Military-grade AES-256 encryption"
                    )
                    
                    SecurityFeature(
                        icon: "eye.slash.fill",
                        title: "Zero Knowledge",
                        description: "Credentials never stored on servers"
                    )
                    
                    SecurityFeature(
                        icon: "checkmark.shield.fill",
                        title: "Verified Connection",
                        description: "Direct MetaAPI secure tunnel"
                    )
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Quantum Connect Button
    
    var quantumConnectButton: some View {
        QuantumButton(
            title: viewModel.isConnecting ? "Establishing Link..." : "Initialize Neural Link",
            icon: viewModel.isConnecting ? nil : "brain.head.profile",
            action: { viewModel.connectAccount() }
        )
        .disabled(!viewModel.isFormValid || viewModel.isConnecting)
        .opacity(viewModel.isFormValid ? 1 : 0.5)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Trust Indicators
    
    var trustIndicators: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundColor(.plasmaGreen)
            
            Text("Secured by advanced neural encryption protocols")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Floating Help Assistant
    
    var floatingHelpAssistant: some View {
        VStack {
            HStack {
                Spacer()
                
                Button(action: { showingBrokerHelp = true }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color.electricBlue.opacity(0.5), lineWidth: 2)
                            )
                            .neonGlow(color: .electricBlue, radius: 10)
                        
                        Image(systemName: "questionmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.electricBlue)
                    }
                }
                .scaleEffect(scanAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: scanAnimation)
            }
            .padding(.trailing, 20)
            .padding(.top, 100)
            
            Spacer()
        }
    }
    
    // MARK: - Scan Overlay
    
    var scanOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                PlasmaOrb()
                
                VStack(spacing: 16) {
                    Text("NEURAL LINK ACTIVE")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.neonCyan)
                        .neonGlow(color: .neonCyan, radius: 10)
                    
                    Text("Establishing quantum tunnel to trading servers...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                // Progress indicators
                HStack(spacing: 20) {
                    ScanStep(title: "Authenticating", isActive: true, isComplete: true)
                    ScanStep(title: "Connecting", isActive: true, isComplete: false)
                    ScanStep(title: "Syncing", isActive: false, isComplete: false)
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct HoloField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @State private var isFocused = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isFocused ? .neonCyan : .white.opacity(0.5))
                    .frame(width: 24)
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                } else {
                    TextField(placeholder, text: $text)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .keyboardType(keyboardType)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color.neonCyan : Color.white.opacity(0.1),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            .onTapGesture {
                isFocused = true
            }
        }
    }
}

struct SecurityFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.plasmaGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
}

struct ScanStep: View {
    let title: String
    let isActive: Bool
    let isComplete: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 40, height: 40)
                
                if isComplete {
                    Circle()
                        .fill(Color.plasmaGreen)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                } else if isActive {
                    Circle()
                        .fill(Color.neonCyan)
                        .frame(width: 30, height: 30)
                        .scaleEffect(isActive ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isActive)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(isComplete ? .plasmaGreen : (isActive ? .neonCyan : .white.opacity(0.5)))
        }
    }
}

// MARK: - Futuristic Broker Help View

struct FuturisticBrokerHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    let brokerServers = [
        ("IC Markets", [
            ("ICMarkets-Demo02", "Demo Server"),
            ("ICMarkets-Live06", "Live Server"),
            ("ICMarkets-Live07", "Live Server")
        ]),
        ("XM Global", [
            ("XMGlobal-Demo 3", "Demo Server"),
            ("XMGlobal-Real 25", "Live Server"),
            ("XMGlobal-Real 26", "Live Server")
        ]),
        ("Pepperstone", [
            ("Pepperstone-Demo01", "Demo Server"),
            ("Pepperstone-Live01", "Live Server"),
            ("Pepperstone-Edge01", "Edge Server")
        ])
    ]
    
    var body: some View {
        ZStack {
            NeuralNetworkBackground()
                .opacity(0.3)
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.neonCyan)
                        
                        Spacer()
                    }
                    
                    Text("Server Database")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header info
                        HolographicCard {
                            VStack(spacing: 16) {
                                Image(systemName: "server.rack")
                                    .font(.system(size: 40))
                                    .foregroundColor(.electricBlue)
                                    .neonGlow(color: .electricBlue, radius: 15)
                                
                                Text("Server Node Locator")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Your server name can be found in your MetaTrader platform under Account Settings or in the welcome email from your broker.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(24)
                        }
                        
                        // Broker list
                        ForEach(brokerServers, id: \.0) { broker, servers in
                            BrokerServerCard(brokerName: broker, servers: servers)
                        }
                    }
                    .padding()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct BrokerServerCard: View {
    let brokerName: String
    let servers: [(String, String)]
    
    var body: some View {
        Text(brokerName)
            .padding()
        /* VStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(brokerName)
                        .font(.headline)
                        .foregroundColor(.neonCyan)
                    
                    Spacer()
                    
                    Text("\(servers.count) servers")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                
                VStack(spacing: 8) {
                    ForEach(servers, id: \.0) { server, type in
                        HStack {
                            Text(server)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .fontFamily(.monospaced)
                            
                            Spacer()
                            
                            Text(type)
                                .font(.caption)
                                .foregroundColor(type.contains("Demo") ? .plasmaGreen : .electricBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(
                                            (type.contains("Demo") ? Color.plasmaGreen : Color.electricBlue).opacity(0.2)
                                        )
                                )
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                }
            }
            .padding(20)
        } */
    }
}

// MARK: - Preview

#Preview {
    FuturisticMetaTraderLinkView()
}