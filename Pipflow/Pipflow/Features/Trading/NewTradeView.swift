//
//  NewTradeView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI

struct NewTradeView: View {
    let symbol: String
    let side: TradeSide
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss: DismissAction
    @State private var volume = "0.01"
    @State private var stopLoss = ""
    @State private var takeProfit = ""
    @State private var stopLossPoints = "50"
    @State private var takeProfitPoints = "100"
    @State private var usePoints = true
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let volumes = ["0.01", "0.02", "0.05", "0.10", "0.20", "0.50", "1.00"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Text(symbol)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(side == .buy ? "BUY" : "SELL")
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(side == .buy ? Color.Theme.buy : Color.Theme.sell)
                                .cornerRadius(.smallCornerRadius)
                        }
                        .foregroundColor(Color.Theme.text)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Price")
                                    .font(.caption)
                                    .foregroundColor(Color.Theme.text.opacity(0.6))
                                Text("1.0854")
                                    .font(.bodyLarge)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.Theme.text)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Account Balance")
                                    .font(.caption)
                                    .foregroundColor(Color.Theme.text.opacity(0.6))
                                Text("$10,000.00")
                                    .font(.bodyLarge)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.Theme.text)
                            }
                        }
                    }
                    .padding()
                    .background(Color.Theme.cardBackground)
                    .cornerRadius(.cornerRadius)
                    
                    // Volume Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Volume (Lots)")
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.Theme.text)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(volumes, id: \.self) { vol in
                                    VolumeButton(
                                        volume: vol,
                                        isSelected: volume == vol,
                                        action: { volume = vol }
                                    )
                                }
                            }
                        }
                        
                        // Custom volume input
                        TextField("Custom volume", text: $volume)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color.Theme.cardBackground)
                            .cornerRadius(.smallCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: .smallCornerRadius)
                                    .stroke(Color.Theme.divider, lineWidth: 1)
                            )
                    }
                    
                    // Stop Loss & Take Profit
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Risk Management")
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.Theme.text)
                            
                            Spacer()
                            
                            Toggle("Use Points", isOn: $usePoints)
                                .toggleStyle(SwitchToggleStyle(tint: Color.Theme.accent))
                        }
                        
                        if usePoints {
                            // Points input
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Stop Loss", systemImage: "shield.fill")
                                        .font(.caption)
                                        .foregroundColor(Color.Theme.error)
                                    
                                    TextField("Points", text: $stopLossPoints)
                                        .keyboardType(.numberPad)
                                        .padding()
                                        .background(Color.Theme.cardBackground)
                                        .cornerRadius(.smallCornerRadius)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: .smallCornerRadius)
                                                .stroke(Color.Theme.error.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Take Profit", systemImage: "target")
                                        .font(.caption)
                                        .foregroundColor(Color.Theme.success)
                                    
                                    TextField("Points", text: $takeProfitPoints)
                                        .keyboardType(.numberPad)
                                        .padding()
                                        .background(Color.Theme.cardBackground)
                                        .cornerRadius(.smallCornerRadius)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: .smallCornerRadius)
                                                .stroke(Color.Theme.success.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        } else {
                            // Price input
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Stop Loss Price", systemImage: "shield.fill")
                                        .font(.caption)
                                        .foregroundColor(Color.Theme.error)
                                    
                                    TextField("0.00000", text: $stopLoss)
                                        .keyboardType(.decimalPad)
                                        .padding()
                                        .background(Color.Theme.cardBackground)
                                        .cornerRadius(.smallCornerRadius)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: .smallCornerRadius)
                                                .stroke(Color.Theme.error.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Take Profit Price", systemImage: "target")
                                        .font(.caption)
                                        .foregroundColor(Color.Theme.success)
                                    
                                    TextField("0.00000", text: $takeProfit)
                                        .keyboardType(.decimalPad)
                                        .padding()
                                        .background(Color.Theme.cardBackground)
                                        .cornerRadius(.smallCornerRadius)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: .smallCornerRadius)
                                                .stroke(Color.Theme.success.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Risk Calculation
                    RiskCalculationView(
                        volume: Double(volume) ?? 0.01,
                        stopLossPoints: Int(stopLossPoints) ?? 50
                    )
                    
                    // Execute Button
                    Button(action: executeTrade) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                Text("Execute \(side == .buy ? "Buy" : "Sell") Order")
                            }
                        }
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: side == .buy ? 
                                    [Color.Theme.buy, Color.Theme.buy.opacity(0.8)] :
                                    [Color.Theme.sell, Color.Theme.sell.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(.cornerRadius)
                        .shadow(color: Color.Theme.shadow, radius: 4, x: 0, y: 2)
                    }
                    .disabled(isLoading)
                }
                .padding()
            }
            .background(Color.Theme.background)
            .navigationTitle("New Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.Theme.accent)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func executeTrade() {
        guard validateTrade() else { return }
        
        isLoading = true
        
        // Simulate trade execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            onComplete()
        }
    }
    
    private func validateTrade() -> Bool {
        guard let vol = Double(volume), vol > 0 else {
            showError(message: "Please enter a valid volume")
            return false
        }
        
        if usePoints {
            guard let sl = Int(stopLossPoints), sl > 0 else {
                showError(message: "Please enter a valid stop loss")
                return false
            }
            
            guard let tp = Int(takeProfitPoints), tp > 0 else {
                showError(message: "Please enter a valid take profit")
                return false
            }
        }
        
        return true
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

struct VolumeButton: View {
    let volume: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(volume)
                .font(.bodyMedium)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : Color.Theme.text)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.Theme.cardBackground
                        }
                    }
                )
                .cornerRadius(.smallCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: .smallCornerRadius)
                        .stroke(isSelected ? Color.clear : Color.Theme.divider, lineWidth: 1)
                )
        }
    }
}

struct RiskCalculationView: View {
    let volume: Double
    let stopLossPoints: Int
    
    var riskAmount: Double {
        // Simplified calculation - normally would use actual pip value
        return volume * Double(stopLossPoints) * 10
    }
    
    var riskPercentage: Double {
        // Assuming $10,000 balance
        return (riskAmount / 10000) * 100
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Risk Amount", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(Color.Theme.warning)
                
                Spacer()
                
                Text("$\(riskAmount, specifier: "%.2f")")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.Theme.text)
            }
            
            HStack {
                Label("Risk Percentage", systemImage: "percent")
                    .font(.caption)
                    .foregroundColor(Color.Theme.warning)
                
                Spacer()
                
                Text("\(riskPercentage, specifier: "%.2f")%")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(riskPercentage > 2 ? Color.Theme.error : Color.Theme.text)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground.opacity(0.5))
        .cornerRadius(.smallCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: .smallCornerRadius)
                .stroke(Color.Theme.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

struct NewTradeView_Previews: PreviewProvider {
    static var previews: some View {
        NewTradeView(
            symbol: "EURUSD",
            side: .buy,
            onComplete: {}
        )
    }
}