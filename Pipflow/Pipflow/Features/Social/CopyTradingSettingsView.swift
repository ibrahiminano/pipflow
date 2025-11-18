//
//  CopyTradingSettingsView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI

struct CopyTradingSettingsView: View {
    let trader: Trader
    @StateObject private var socialService = SocialTradingService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var maxInvestment: String = "1000"
    @State private var maxRiskPerTrade: String = "2"
    @State private var copyRatio: Double = 1.0
    @State private var stopLossEnabled = true
    @State private var maxDailyLoss: String = "5"
    @State private var copyOpenTrades = false
    @State private var reverseCopy = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Trader Info
                        HStack(spacing: 12) {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(trader.displayName.prefix(2))
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Copy Trading Settings")
                                    .font(.headline)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                Text("Configure how you want to copy \(trader.displayName)")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(12)
                        
                        // Investment Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Investment Settings")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            // Max Investment
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Maximum Investment")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                HStack {
                                    Text("$")
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    
                                    TextField("1000", text: $maxInvestment)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                }
                                .padding()
                                .background(themeManager.currentTheme.backgroundColor)
                                .cornerRadius(8)
                                
                                Text("Total amount allocated for copying this trader")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            
                            // Copy Ratio
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Copy Ratio")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(copyRatio * 100))%")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.Theme.accent)
                                }
                                
                                Slider(value: $copyRatio, in: 0.1...2.0, step: 0.1)
                                    .accentColor(Color.Theme.accent)
                                
                                Text("Percentage of trader's position size to copy")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(12)
                        
                        // Risk Management
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Risk Management")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            // Max Risk Per Trade
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Max Risk Per Trade")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                HStack {
                                    TextField("2", text: $maxRiskPerTrade)
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    
                                    Text("%")
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                                .padding()
                                .background(themeManager.currentTheme.backgroundColor)
                                .cornerRadius(8)
                            }
                            
                            // Stop Loss Protection
                            Toggle(isOn: $stopLossEnabled) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Stop Loss Protection")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    Text("Automatically add stop loss to copied trades")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color.Theme.accent))
                            
                            // Max Daily Loss
                            if stopLossEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Max Daily Loss")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    
                                    HStack {
                                        TextField("5", text: $maxDailyLoss)
                                            .keyboardType(.decimalPad)
                                            .foregroundColor(themeManager.currentTheme.textColor)
                                        
                                        Text("%")
                                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    }
                                    .padding()
                                    .background(themeManager.currentTheme.backgroundColor)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(12)
                        
                        // Advanced Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Advanced Settings")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Toggle(isOn: $copyOpenTrades) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Copy Open Trades")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    Text("Copy trader's existing open positions")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color.Theme.accent))
                            
                            Toggle(isOn: $reverseCopy) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reverse Copy")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    Text("Take opposite positions (buy when trader sells)")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color.Theme.accent))
                        }
                        .padding()
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(12)
                        
                        // Warning
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text("Copy trading involves risk. Past performance does not guarantee future results.")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Start Copy Trading Button
                        Button(action: startCopyTrading) {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                Text("Start Copy Trading")
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
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Copy Trading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
    }
    
    private func startCopyTrading() {
        let config = CopyTradingConfig(
            allocatedAmount: Double(maxInvestment) ?? 1000,
            maxPositions: 10,
            riskLevel: .medium,
            copyStopLoss: stopLossEnabled,
            copyTakeProfit: true,
            proportionalSizing: true,
            maxDrawdown: stopLossEnabled ? (Double(maxDailyLoss) ?? 10) / 100 : 0.10,
            stopLossPercent: 0.02,
            takeProfitPercent: 0.04
        )
        
        socialService.startCopyTrading(trader: trader, settings: config)
        dismiss()
    }
}

#Preview {
    CopyTradingSettingsView(trader: SocialTradingService.shared.topTraders.first!)
        .environmentObject(ThemeManager.shared)
}