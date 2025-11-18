//
//  TradingPreferencesView.swift
//  Pipflow
//
//  Trading preferences and default settings
//

import SwiftUI

struct TradingPreferencesView: View {
    @StateObject private var settingsService = SettingsService.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var defaultLotSize: Double
    @State private var defaultStopLoss: Double
    @State private var defaultTakeProfit: Double
    @State private var maxRiskPerTrade: Double
    @State private var maxOpenTrades: Int
    @State private var defaultTimeframe: Timeframe
    @State private var defaultChartType: TradingChartType
    @State private var showTradeConfirmation: Bool
    @State private var enableOneTapTrading: Bool
    @State private var autoCalculatePositionSize: Bool
    @State private var riskRewardRatio: Double
    
    // For number input
    @State private var lotSizeText: String = ""
    @State private var stopLossText: String = ""
    @State private var takeProfitText: String = ""
    @State private var maxRiskText: String = ""
    @State private var maxTradesText: String = ""
    @State private var riskRewardText: String = ""
    
    init() {
        let trading = SettingsService.shared.settings.trading
        _defaultLotSize = State(initialValue: trading.defaultLotSize)
        _defaultStopLoss = State(initialValue: trading.defaultStopLoss)
        _defaultTakeProfit = State(initialValue: trading.defaultTakeProfit)
        _maxRiskPerTrade = State(initialValue: trading.maxRiskPerTrade)
        _maxOpenTrades = State(initialValue: trading.maxOpenTrades)
        _defaultTimeframe = State(initialValue: trading.defaultTimeframe)
        _defaultChartType = State(initialValue: trading.defaultChartType)
        _showTradeConfirmation = State(initialValue: trading.showTradeConfirmation)
        _enableOneTapTrading = State(initialValue: trading.enableOneTapTrading)
        _autoCalculatePositionSize = State(initialValue: trading.autoCalculatePositionSize)
        _riskRewardRatio = State(initialValue: trading.riskRewardRatio)
        
        // Initialize text fields
        _lotSizeText = State(initialValue: String(format: "%.2f", trading.defaultLotSize))
        _stopLossText = State(initialValue: String(format: "%.0f", trading.defaultStopLoss))
        _takeProfitText = State(initialValue: String(format: "%.0f", trading.defaultTakeProfit))
        _maxRiskText = State(initialValue: String(format: "%.1f", trading.maxRiskPerTrade))
        _maxTradesText = State(initialValue: String(trading.maxOpenTrades))
        _riskRewardText = State(initialValue: String(format: "%.1f", trading.riskRewardRatio))
    }
    
    var body: some View {
        NavigationView {
            List {
                // Position Size Section
                Section {
                    HStack {
                        Label("Default Lot Size", systemImage: "scalemass")
                        Spacer()
                        TextField("0.01", text: $lotSizeText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .onChange(of: lotSizeText) { newValue in
                                if let value = Double(newValue), value > 0 {
                                    defaultLotSize = value
                                }
                            }
                    }
                    
                    Toggle(isOn: $autoCalculatePositionSize) {
                        Label("Auto-Calculate Position Size", systemImage: "function")
                    }
                    
                    if autoCalculatePositionSize {
                        HStack {
                            Label("Max Risk Per Trade", systemImage: "percent")
                            Spacer()
                            TextField("2.0", text: $maxRiskText)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                                .onChange(of: maxRiskText) { newValue in
                                    if let value = Double(newValue), value > 0 && value <= 100 {
                                        maxRiskPerTrade = value
                                    }
                                }
                            Text("%")
                                .foregroundColor(Color.Theme.secondaryText)
                        }
                    }
                } header: {
                    Text("Position Management")
                } footer: {
                    Text(autoCalculatePositionSize ? "Position size will be calculated based on account balance and risk percentage" : "Manual position sizing will be used")
                }
                
                // Risk Management Section
                Section {
                    HStack {
                        Label("Default Stop Loss", systemImage: "shield")
                        Spacer()
                        TextField("50", text: $stopLossText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .onChange(of: stopLossText) { newValue in
                                if let value = Double(newValue), value > 0 {
                                    defaultStopLoss = value
                                }
                            }
                        Text("pips")
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                    
                    HStack {
                        Label("Default Take Profit", systemImage: "target")
                        Spacer()
                        TextField("100", text: $takeProfitText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .onChange(of: takeProfitText) { newValue in
                                if let value = Double(newValue), value > 0 {
                                    defaultTakeProfit = value
                                }
                            }
                        Text("pips")
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                    
                    HStack {
                        Label("Risk/Reward Ratio", systemImage: "chart.xyaxis.line")
                        Spacer()
                        TextField("2.0", text: $riskRewardText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .onChange(of: riskRewardText) { newValue in
                                if let value = Double(newValue), value > 0 {
                                    riskRewardRatio = value
                                }
                            }
                        Text(":1")
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                } header: {
                    Text("Risk Management")
                } footer: {
                    Text("These values will be used as defaults when opening new trades")
                }
                
                // Trading Limits Section
                Section {
                    HStack {
                        Label("Max Open Trades", systemImage: "square.stack.3d.up")
                        Spacer()
                        TextField("5", text: $maxTradesText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .onChange(of: maxTradesText) { newValue in
                                if let value = Int(newValue), value > 0 {
                                    maxOpenTrades = value
                                }
                            }
                    }
                } header: {
                    Text("Trading Limits")
                } footer: {
                    Text("Maximum number of trades that can be open simultaneously")
                }
                
                // Chart Settings Section
                Section {
                    Picker("Default Timeframe", selection: $defaultTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.displayName).tag(timeframe)
                        }
                    }
                    
                    Picker("Default Chart Type", selection: $defaultChartType) {
                        ForEach(TradingChartType.allCases, id: \.self) { chartType in
                            Label(chartType.displayName, systemImage: chartType.icon)
                                .tag(chartType)
                        }
                    }
                } header: {
                    Text("Chart Settings")
                }
                
                // Safety Settings Section
                Section {
                    Toggle(isOn: $showTradeConfirmation) {
                        Label("Show Trade Confirmation", systemImage: "checkmark.shield")
                    }
                    
                    Toggle(isOn: $enableOneTapTrading) {
                        Label("Enable One-Tap Trading", systemImage: "hand.tap")
                    }
                } header: {
                    Text("Safety Settings")
                } footer: {
                    Text(enableOneTapTrading ? "⚠️ One-tap trading allows instant trade execution without confirmation" : "Trade confirmation will be required before execution")
                }
                
                // Quick Actions Section
                Section {
                    Button(action: resetToDefaults) {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                            .foregroundColor(Color.Theme.accent)
                    }
                } header: {
                    Text("Actions")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Trading Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        settingsService.settings.trading.defaultLotSize = defaultLotSize
        settingsService.settings.trading.defaultStopLoss = defaultStopLoss
        settingsService.settings.trading.defaultTakeProfit = defaultTakeProfit
        settingsService.settings.trading.maxRiskPerTrade = maxRiskPerTrade
        settingsService.settings.trading.maxOpenTrades = maxOpenTrades
        settingsService.settings.trading.defaultTimeframe = defaultTimeframe
        settingsService.settings.trading.defaultChartType = defaultChartType
        settingsService.settings.trading.showTradeConfirmation = showTradeConfirmation
        settingsService.settings.trading.enableOneTapTrading = enableOneTapTrading
        settingsService.settings.trading.autoCalculatePositionSize = autoCalculatePositionSize
        settingsService.settings.trading.riskRewardRatio = riskRewardRatio
    }
    
    private func resetToDefaults() {
        let defaults = TradingSettings()
        
        defaultLotSize = defaults.defaultLotSize
        defaultStopLoss = defaults.defaultStopLoss
        defaultTakeProfit = defaults.defaultTakeProfit
        maxRiskPerTrade = defaults.maxRiskPerTrade
        maxOpenTrades = defaults.maxOpenTrades
        defaultTimeframe = defaults.defaultTimeframe
        defaultChartType = defaults.defaultChartType
        showTradeConfirmation = defaults.showTradeConfirmation
        enableOneTapTrading = defaults.enableOneTapTrading
        autoCalculatePositionSize = defaults.autoCalculatePositionSize
        riskRewardRatio = defaults.riskRewardRatio
        
        // Update text fields
        lotSizeText = String(format: "%.2f", defaults.defaultLotSize)
        stopLossText = String(format: "%.0f", defaults.defaultStopLoss)
        takeProfitText = String(format: "%.0f", defaults.defaultTakeProfit)
        maxRiskText = String(format: "%.1f", defaults.maxRiskPerTrade)
        maxTradesText = String(defaults.maxOpenTrades)
        riskRewardText = String(format: "%.1f", defaults.riskRewardRatio)
    }
}

#Preview {
    TradingPreferencesView()
}