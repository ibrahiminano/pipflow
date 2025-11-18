//
//  AutoTradingSettingsView.swift
//  Pipflow
//
//  Auto-trading configuration settings
//

import SwiftUI

struct AutoTradingSettingsView: View {
    @ObservedObject var engine: AIAutoTradingEngine
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: AutoTradingMode
    @State private var enabledPairs: Set<String>
    @State private var maxDailyLoss: Double
    @State private var maxPositionSize: Double
    @State private var minWinRate: Double
    @State private var stopOnConsecutiveLosses: Double
    @State private var useMarketRegimeFilter: Bool
    @State private var requireConfirmation: Bool
    @State private var selectedTradingHours: TradingHoursOption = .allDay
    
    init(engine: AIAutoTradingEngine) {
        self.engine = engine
        _selectedMode = State(initialValue: engine.config.mode)
        _enabledPairs = State(initialValue: engine.config.enabledPairs)
        _maxDailyLoss = State(initialValue: engine.config.maxDailyLoss * 100)
        _maxPositionSize = State(initialValue: engine.config.maxPositionSize)
        _minWinRate = State(initialValue: engine.config.minWinRate * 100)
        _stopOnConsecutiveLosses = State(initialValue: Double(engine.config.stopTradingOnConsecutiveLosses))
        _useMarketRegimeFilter = State(initialValue: engine.config.useMarketRegimeFilter)
        _requireConfirmation = State(initialValue: engine.config.requireConfirmation)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Trading Mode
                    TradingModeSection(selectedMode: $selectedMode)
                    
                    // Currency Pairs
                    CurrencyPairsSection(enabledPairs: $enabledPairs)
                    
                    // Risk Management
                    AutoTradingRiskManagementSection(
                        maxDailyLoss: $maxDailyLoss,
                        maxPositionSize: $maxPositionSize,
                        stopOnConsecutiveLosses: $stopOnConsecutiveLosses
                    )
                    
                    // Trading Parameters
                    TradingParametersSection(
                        minWinRate: $minWinRate,
                        selectedTradingHours: $selectedTradingHours
                    )
                    
                    // Advanced Settings
                    AdvancedSettingsSection(
                        useMarketRegimeFilter: $useMarketRegimeFilter,
                        requireConfirmation: $requireConfirmation
                    )
                }
                .padding()
            }
            .background(Color.Theme.background)
            .navigationTitle("Auto-Trading Settings")
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
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveSettings() {
        engine.config.mode = selectedMode
        engine.config.enabledPairs = enabledPairs
        engine.config.maxDailyLoss = maxDailyLoss / 100
        engine.config.maxPositionSize = maxPositionSize
        engine.config.minWinRate = minWinRate / 100
        engine.config.stopTradingOnConsecutiveLosses = Int(stopOnConsecutiveLosses)
        engine.config.useMarketRegimeFilter = useMarketRegimeFilter
        engine.config.requireConfirmation = requireConfirmation
        engine.config.tradingHours = selectedTradingHours.toTradingHours()
    }
}

struct TradingModeSection: View {
    @Binding var selectedMode: AutoTradingMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trading Mode")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            ForEach(AutoTradingMode.allCases, id: \.self) { mode in
                TradingModeOption(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    onSelect: { selectedMode = mode }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct TradingModeOption: View {
    let mode: AutoTradingMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.Theme.text)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.Theme.accent)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.Theme.accent.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.Theme.accent : Color.Theme.text.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

struct CurrencyPairsSection: View {
    @Binding var enabledPairs: Set<String>
    
    let availablePairs = [
        "EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCAD",
        "NZDUSD", "USDCHF", "EURJPY", "GBPJPY", "EURGBP",
        "XAUUSD", "BTCUSD", "ETHUSD"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enabled Pairs")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            Text("Select currency pairs for auto-trading")
                .font(.caption)
                .foregroundColor(Color.Theme.text.opacity(0.6))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(availablePairs, id: \.self) { pair in
                    PairToggle(
                        pair: pair,
                        isEnabled: enabledPairs.contains(pair),
                        onToggle: {
                            if enabledPairs.contains(pair) {
                                enabledPairs.remove(pair)
                            } else {
                                enabledPairs.insert(pair)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct PairToggle: View {
    let pair: String
    let isEnabled: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            Text(pair)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isEnabled ? .white : Color.Theme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isEnabled ? Color.Theme.accent : Color.Theme.background)
                )
        }
    }
}

struct AutoTradingRiskManagementSection: View {
    @Binding var maxDailyLoss: Double
    @Binding var maxPositionSize: Double
    @Binding var stopOnConsecutiveLosses: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Risk Management")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            // Max Daily Loss
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Max Daily Loss")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.text)
                    
                    Spacer()
                    
                    Text("\(Int(maxDailyLoss))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.Theme.accent)
                }
                
                Slider(value: $maxDailyLoss, in: 1...10, step: 1)
                    .tint(Color.Theme.accent)
            }
            
            Divider()
            
            // Max Position Size
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Max Position Size")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.text)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f lots", maxPositionSize))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.Theme.accent)
                }
                
                Slider(value: $maxPositionSize, in: 0.01...5.0, step: 0.01)
                    .tint(Color.Theme.accent)
            }
            
            Divider()
            
            // Stop on Consecutive Losses
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Stop After Consecutive Losses")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.text)
                    
                    Spacer()
                    
                    Text("\(Int(stopOnConsecutiveLosses))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.Theme.accent)
                }
                
                Slider(value: $stopOnConsecutiveLosses, in: 1...10, step: 1)
                    .tint(Color.Theme.accent)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct TradingParametersSection: View {
    @Binding var minWinRate: Double
    @Binding var selectedTradingHours: TradingHoursOption
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Trading Parameters")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            // Minimum Win Rate
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Minimum Win Rate")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.text)
                    
                    Spacer()
                    
                    Text("\(Int(minWinRate))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.Theme.accent)
                }
                
                Slider(value: $minWinRate, in: 40...80, step: 5)
                    .tint(Color.Theme.accent)
                
                Text("Stop trading if win rate falls below this threshold")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
            
            Divider()
            
            // Trading Hours
            VStack(alignment: .leading, spacing: 12) {
                Text("Trading Hours")
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.text)
                
                ForEach(TradingHoursOption.allCases, id: \.self) { option in
                    HStack {
                        Label(option.rawValue, systemImage: option.icon)
                            .font(.caption)
                            .foregroundColor(Color.Theme.text)
                        
                        Spacer()
                        
                        if selectedTradingHours == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.Theme.accent)
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTradingHours = option
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct AdvancedSettingsSection: View {
    @Binding var useMarketRegimeFilter: Bool
    @Binding var requireConfirmation: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Settings")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            Toggle(isOn: $useMarketRegimeFilter) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Market Regime Filter")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.text)
                    
                    Text("Avoid trading in extreme market conditions")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
            }
            .tint(Color.Theme.accent)
            
            Divider()
            
            Toggle(isOn: $requireConfirmation) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Require Confirmation")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.text)
                    
                    Text("Manually approve trades before execution")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
            }
            .tint(Color.Theme.accent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

enum TradingHoursOption: String, CaseIterable {
    case allDay = "24/7 Trading"
    case londonNewYork = "London & New York"
    case asian = "Asian Session"
    case custom = "Custom Hours"
    
    var icon: String {
        switch self {
        case .allDay: return "clock"
        case .londonNewYork: return "globe.americas"
        case .asian: return "globe.asia.australia"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    func toTradingHours() -> AutoTradingHours {
        switch self {
        case .allDay: return .allDay
        case .londonNewYork: return .londonNewYork
        case .asian: return .asian
        case .custom: return AutoTradingHours(startHour: 9, endHour: 17)
        }
    }
}

#Preview {
    AutoTradingSettingsView(engine: AIAutoTradingEngine.shared)
}