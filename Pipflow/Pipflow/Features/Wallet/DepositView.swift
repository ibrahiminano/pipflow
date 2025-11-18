//
//  DepositView.swift
//  Pipflow
//
//  Crypto deposit interface for PIPS tokens
//

import SwiftUI

struct DepositView: View {
    @StateObject private var tokenService = PIPSTokenService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCrypto: SupportedCrypto = .usdt
    @State private var amount: String = ""
    @State private var showingQRCode = false
    @State private var depositInfo: CryptoDeposit?
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Crypto Selection
                        cryptoSelectionSection
                        
                        // Amount Input
                        amountInputSection
                        
                        // Exchange Rate Info
                        if !amount.isEmpty, let amountDouble = Double(amount) {
                            exchangeRateSection(amount: amountDouble)
                        }
                        
                        // Deposit Instructions
                        if depositInfo != nil {
                            depositInstructionsSection
                        }
                        
                        // Action Button
                        actionButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Deposit PIPS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: { dismiss() })
                }
            }
        }
        .sheet(isPresented: $showingQRCode) {
            if let info = depositInfo {
                QRCodeView(depositInfo: info)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.Theme.accent)
            
            Text("Top up your PIPS wallet")
                .font(.headline)
            
            Text("Deposit cryptocurrency to get PIPS tokens")
                .font(.subheadline)
                .foregroundColor(Color.Theme.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.Theme.cardBackground)
    }
    
    // MARK: - Crypto Selection
    
    private var cryptoSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Cryptocurrency")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SupportedCrypto.allCases, id: \.self) { crypto in
                        CryptoButton(
                            crypto: crypto,
                            isSelected: selectedCrypto == crypto,
                            action: { selectedCrypto = crypto }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Amount Input
    
    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Amount to Deposit")
                .font(.headline)
            
            HStack {
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 24, weight: .medium))
                
                Text(selectedCrypto.rawValue)
                    .font(.headline)
                    .foregroundColor(Color.Theme.secondaryText)
            }
            .padding()
            .background(Color.Theme.secondary.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.Theme.divider, lineWidth: 1)
            )
            
            // Minimum deposit
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("Minimum: \(String(format: "%.6f", selectedCrypto.minimumDeposit)) \(selectedCrypto.rawValue)")
                    .font(.caption)
            }
            .foregroundColor(Color.Theme.secondaryText)
        }
    }
    
    // MARK: - Exchange Rate Section
    
    private func exchangeRateSection(amount: Double) -> some View {
        VStack(spacing: 16) {
            // Exchange Rate
            HStack {
                Text("Exchange Rate")
                    .foregroundColor(Color.Theme.secondaryText)
                Spacer()
                Text("1 \(selectedCrypto.rawValue) = \(Int(1 / (tokenService.exchangeRates[selectedCrypto] ?? 1))) PIPS")
                    .fontWeight(.medium)
            }
            
            // Network Fee
            let networkFee = calculateNetworkFee(amount)
            HStack {
                Text("Network Fee")
                    .foregroundColor(Color.Theme.secondaryText)
                Spacer()
                Text("\(String(format: "%.6f", networkFee)) \(selectedCrypto.rawValue)")
                    .fontWeight(.medium)
            }
            
            Divider()
            
            // You Will Receive
            let pipsAmount = amount * (1 / (tokenService.exchangeRates[selectedCrypto] ?? 1))
            HStack {
                Text("You Will Receive")
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(Int(pipsAmount)) PIPS")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.Theme.accent)
                    
                    if let stats = tokenService.tokenStats {
                        Text("≈ $\(String(format: "%.2f", pipsAmount * stats.price))")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                }
            }
        }
        .padding()
        .background(Color.Theme.secondary.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Deposit Instructions
    
    private var depositInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Deposit Instructions")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Step 1
                InstructionRow(
                    number: "1",
                    text: "Send \(amount) \(selectedCrypto.rawValue) to the address below"
                )
                
                // Deposit Address
                if let address = depositInfo?.depositAddress {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Deposit Address")
                                .font(.subheadline)
                                .foregroundColor(Color.Theme.secondaryText)
                            
                            Spacer()
                            
                            Button(action: { showingQRCode = true }) {
                                Label("QR Code", systemImage: "qrcode")
                                    .font(.caption)
                            }
                        }
                        
                        HStack {
                            Text(address)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Button(action: {
                                UIPasteboard.general.string = address
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color.Theme.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Step 2
                InstructionRow(
                    number: "2",
                    text: "Wait for \(depositInfo?.confirmations ?? 0) network confirmations"
                )
                
                // Step 3
                InstructionRow(
                    number: "3",
                    text: "PIPS will be credited to your wallet automatically"
                )
            }
            
            // Warning
            VStack(alignment: .leading, spacing: 8) {
                Label("Important", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.warning)
                
                Text("• Only send \(selectedCrypto.displayName) to this address")
                Text("• Sending other tokens may result in permanent loss")
                Text("• Double-check the address before sending")
            }
            .font(.caption)
            .foregroundColor(Color.Theme.secondaryText)
            .padding()
            .background(Color.Theme.warning.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: generateDepositAddress) {
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if depositInfo == nil {
                Label("Generate Deposit Address", systemImage: "arrow.down.circle.fill")
            } else {
                Label("Generate New Address", systemImage: "arrow.clockwise")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.Theme.accent)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(isProcessing || amount.isEmpty || Double(amount) ?? 0 < selectedCrypto.minimumDeposit)
    }
    
    // MARK: - Actions
    
    private func generateDepositAddress() {
        guard let amountDouble = Double(amount) else { return }
        
        isProcessing = true
        
        Task {
            do {
                depositInfo = try await tokenService.depositCrypto(selectedCrypto, amount: amountDouble)
                isProcessing = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isProcessing = false
            }
        }
    }
    
    private func calculateNetworkFee(_ amount: Double) -> Double {
        // Simplified network fee calculation
        switch selectedCrypto {
        case .bitcoin: return 0.00001
        case .ethereum: return 0.001
        case .usdt, .usdc: return 1.0
        case .bnb: return 0.001
        case .sol: return 0.00025
        case .matic: return 0.01
        }
    }
}

// MARK: - Supporting Views

struct CryptoButton: View {
    let crypto: SupportedCrypto
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconForCrypto(crypto))
                    .font(.title2)
                
                Text(crypto.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.Theme.accent : Color.Theme.secondary.opacity(0.3))
            .foregroundColor(isSelected ? .white : Color.Theme.text)
            .cornerRadius(12)
        }
    }
    
    private func iconForCrypto(_ crypto: SupportedCrypto) -> String {
        switch crypto {
        case .bitcoin: return "bitcoinsign.circle.fill"
        case .ethereum: return "e.circle.fill"
        case .usdt, .usdc: return "dollarsign.circle.fill"
        case .bnb: return "b.circle.fill"
        case .sol: return "s.circle.fill"
        case .matic: return "p.circle.fill"
        }
    }
}

struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.Theme.accent)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.Theme.text)
            
            Spacer()
        }
    }
}

struct QRCodeView: View {
    let depositInfo: CryptoDeposit
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // QR Code placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 250, height: 250)
                    .overlay(
                        VStack {
                            Image(systemName: "qrcode")
                                .font(.system(size: 100))
                                .foregroundColor(.black)
                            Text("QR Code")
                                .foregroundColor(.black)
                        }
                    )
                
                // Address
                VStack(spacing: 8) {
                    Text("Deposit Address")
                        .font(.headline)
                    
                    Text(depositInfo.depositAddress)
                        .font(.system(.caption, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.Theme.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Copy Button
                Button(action: {
                    UIPasteboard.general.string = depositInfo.depositAddress
                }) {
                    Label("Copy Address", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: { dismiss() })
                }
            }
        }
    }
}

#Preview {
    DepositView()
        .preferredColorScheme(.dark)
}