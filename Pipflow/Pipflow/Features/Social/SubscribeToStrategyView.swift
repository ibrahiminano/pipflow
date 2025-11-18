//
//  SubscribeToStrategyView.swift
//  Pipflow
//
//  Configure and subscribe to a strategy
//

import SwiftUI

struct SubscribeToStrategyView: View {
    let strategy: SharedStrategy
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var scalingFactor: Double = 1.0
    @State private var maxPositions: Int = 5
    @State private var maxRiskPerTrade: Double = 2.0
    @State private var stopCopyingOnDrawdown: Double = 20.0
    @State private var enableStopCopying = true
    @State private var reverseTrading = false
    @State private var selectedSymbols: Set<String> = []
    @State private var useAllSymbols = true
    
    @State private var showConfirmation = false
    @State private var isSubscribing = false
    
    let availableSymbols = ["EURUSD", "GBPUSD", "USDJPY", "XAUUSD", "BTCUSD", "ETHUSD"]
    
    var monthlyFee: String {
        if strategy.price > 0 {
            return "$\(Int(strategy.price))/month"
        } else {
            return "Free"
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                strategyInfoSection
                copySettingsSection
                riskManagementSection
                subscriptionSection
            }
            .navigationTitle("Subscribe to Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Subscribe") {
                        showConfirmation = true
                    }
                    .disabled(isSubscribing || (!useAllSymbols && selectedSymbols.isEmpty))
                }
            }
        }
        .confirmationDialog("Confirm Subscription", isPresented: $showConfirmation) {
            Button("Subscribe") {
                Task {
                    await subscribe()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Subscribe to \(strategy.strategy.name) for \(monthlyFee)?")
        }
    }
    
    private var strategyInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(strategy.strategy.name)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text("by \(strategy.authorName)")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(monthlyFee)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        
                        if strategy.price > 0 {
                            Text("Monthly subscription")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                }
                
                // Quick Stats
                HStack(spacing: 20) {
                    SubscribeStatItem(label: "Return", value: String(format: "%.1f%%", strategy.performance.totalReturn))
                    SubscribeStatItem(label: "Win Rate", value: String(format: "%.0f%%", strategy.performance.winRate * 100))
                    SubscribeStatItem(label: "Subscribers", value: "\(strategy.subscribers)")
                }
                .font(.caption)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Strategy")
        }
    }
    
    private var copySettingsSection: some View {
        Section {
                    // Scaling Factor
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Position Size Scaling")
                            Spacer()
                            Text(String(format: "%.1fx", scalingFactor))
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                        
                        Slider(value: $scalingFactor, in: 0.1...10.0, step: 0.1)
                            .accentColor(themeManager.currentTheme.accentColor)
                        
                        Text("Adjusts the size of copied positions relative to the strategy")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    .padding(.vertical, 4)
                    
                    // Max Positions
                    Stepper(value: $maxPositions, in: 1...20) {
                        HStack {
                            Text("Max Open Positions")
                            Spacer()
                            Text("\(maxPositions)")
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                    }
                    
                    // Max Risk
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max Risk Per Trade")
                            Spacer()
                            Text(String(format: "%.1f%%", maxRiskPerTrade))
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                        
                        Slider(value: $maxRiskPerTrade, in: 0.5...10.0, step: 0.5)
                            .accentColor(themeManager.currentTheme.accentColor)
                    }
                    .padding(.vertical, 4)
        } header: {
            Text("Copy Settings")
        }
    }
    
    private var riskManagementSection: some View {
        Section {
                    // Stop Copying on Drawdown
                    Toggle(isOn: $enableStopCopying) {
                        Text("Stop Copying on Drawdown")
                    }
                    
                    if enableStopCopying {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Drawdown Limit")
                                Spacer()
                                Text(String(format: "%.0f%%", stopCopyingOnDrawdown))
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                            
                            Slider(value: $stopCopyingOnDrawdown, in: 5...50, step: 5)
                                .accentColor(themeManager.currentTheme.accentColor)
                            
                            Text("Automatically pause copying if drawdown exceeds this limit")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Reverse Trading
                    Toggle(isOn: $reverseTrading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reverse Trading")
                            Text("Copy opposite positions (buy→sell, sell→buy)")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
        } header: {
            Text("Risk Management")
        }
    }
    
    private var subscriptionSection: some View {
        Group {
            // Symbol Selection Section
            Section {
                Toggle(isOn: $useAllSymbols) {
                    Text("Copy All Symbols")
                }
                
                if !useAllSymbols {
                    ForEach(availableSymbols, id: \.self) { symbol in
                        HStack {
                            Text(symbol)
                            Spacer()
                            if selectedSymbols.contains(symbol) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedSymbols.contains(symbol) {
                                selectedSymbols.remove(symbol)
                            } else {
                                selectedSymbols.insert(symbol)
                            }
                        }
                    }
                }
            } header: {
                Text("Symbol Selection")
            }
            
            // Summary Section
            Section {
                SubscribeSummaryRow(label: "Monthly Fee", value: monthlyFee)
                SubscribeSummaryRow(label: "Scaling", value: "\(Int(scalingFactor * 100))%")
                SubscribeSummaryRow(label: "Max Risk", value: "\(Int(maxRiskPerTrade))%")
                
                Button("Subscribe Now") {
                    showConfirmation = true
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.currentTheme.accentColor)
                .cornerRadius(12)
                .disabled(isSubscribing)
                .opacity(isSubscribing ? 0.6 : 1.0)
            } header: {
                Text("Summary")
            }
        }
    }
    
    private func subscribe() async {
        isSubscribing = true
        
        let settings = CopySettings(
            scalingFactor: scalingFactor,
            maxPositions: maxPositions,
            maxRiskPerTrade: maxRiskPerTrade / 100,
            allowedSymbols: useAllSymbols ? nil : Array(selectedSymbols),
            stopCopyingOnDrawdown: enableStopCopying ? stopCopyingOnDrawdown / 100 : nil,
            reverseTrading: reverseTrading
        )
        
        do {
            _ = try await SocialTradingServiceV2.shared.subscribeToStrategy(
                strategy.id.uuidString,
                settings: settings
            )
            dismiss()
        } catch {
            // Handle error
            print("Subscription error: \(error)")
        }
        
        isSubscribing = false
    }
}

struct SubscribeStatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundColor(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct SubscribeSummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Edit Copy Settings View

struct EditCopySettingsView: View {
    let subscription: StrategySubscription
    let onSave: (CopySettings) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var scalingFactor: Double
    @State private var maxPositions: Int
    @State private var maxRiskPerTrade: Double
    @State private var stopCopyingOnDrawdown: Double
    @State private var enableStopCopying: Bool
    @State private var reverseTrading: Bool
    @State private var selectedSymbols: Set<String>
    @State private var useAllSymbols: Bool
    
    let availableSymbols = ["EURUSD", "GBPUSD", "USDJPY", "XAUUSD", "BTCUSD", "ETHUSD"]
    
    init(subscription: StrategySubscription, onSave: @escaping (CopySettings) -> Void) {
        self.subscription = subscription
        self.onSave = onSave
        
        let settings = subscription.copySettings
        _scalingFactor = State(initialValue: settings.scalingFactor)
        _maxPositions = State(initialValue: settings.maxPositions)
        _maxRiskPerTrade = State(initialValue: settings.maxRiskPerTrade * 100)
        _stopCopyingOnDrawdown = State(initialValue: (settings.stopCopyingOnDrawdown ?? 0.2) * 100)
        _enableStopCopying = State(initialValue: settings.stopCopyingOnDrawdown != nil)
        _reverseTrading = State(initialValue: settings.reverseTrading)
        _selectedSymbols = State(initialValue: Set(settings.allowedSymbols ?? []))
        _useAllSymbols = State(initialValue: settings.allowedSymbols == nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Copy Settings Section
                Section {
                    // Scaling Factor
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Position Size Scaling")
                            Spacer()
                            Text(String(format: "%.1fx", scalingFactor))
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                        
                        Slider(value: $scalingFactor, in: 0.1...10.0, step: 0.1)
                            .accentColor(themeManager.currentTheme.accentColor)
                    }
                    
                    // Max Positions
                    Stepper(value: $maxPositions, in: 1...20) {
                        HStack {
                            Text("Max Open Positions")
                            Spacer()
                            Text("\(maxPositions)")
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                    }
                    
                    // Max Risk
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max Risk Per Trade")
                            Spacer()
                            Text(String(format: "%.1f%%", maxRiskPerTrade))
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                        
                        Slider(value: $maxRiskPerTrade, in: 0.5...10.0, step: 0.5)
                            .accentColor(themeManager.currentTheme.accentColor)
                    }
                } header: {
                    Text("Position Management")
                }
                
                // Risk Management Section
                Section {
                    Toggle(isOn: $enableStopCopying) {
                        Text("Stop Copying on Drawdown")
                    }
                    
                    if enableStopCopying {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Drawdown Limit")
                                Spacer()
                                Text(String(format: "%.0f%%", stopCopyingOnDrawdown))
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                            
                            Slider(value: $stopCopyingOnDrawdown, in: 5...50, step: 5)
                                .accentColor(themeManager.currentTheme.accentColor)
                        }
                    }
                    
                    Toggle(isOn: $reverseTrading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reverse Trading")
                            Text("Copy opposite positions")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                } header: {
                    Text("Risk Management")
                }
                
                // Symbol Selection
                Section {
                    Toggle(isOn: $useAllSymbols) {
                        Text("Copy All Symbols")
                    }
                    
                    if !useAllSymbols {
                        ForEach(availableSymbols, id: \.self) { symbol in
                            HStack {
                                Text(symbol)
                                Spacer()
                                if selectedSymbols.contains(symbol) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeManager.currentTheme.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedSymbols.contains(symbol) {
                                    selectedSymbols.remove(symbol)
                                } else {
                                    selectedSymbols.insert(symbol)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Symbol Selection")
                }
            }
            .navigationTitle("Edit Copy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveSettings() {
        let settings = CopySettings(
            scalingFactor: scalingFactor,
            maxPositions: maxPositions,
            maxRiskPerTrade: maxRiskPerTrade / 100,
            allowedSymbols: useAllSymbols ? nil : Array(selectedSymbols),
            stopCopyingOnDrawdown: enableStopCopying ? stopCopyingOnDrawdown / 100 : nil,
            reverseTrading: reverseTrading
        )
        
        onSave(settings)
    }
}