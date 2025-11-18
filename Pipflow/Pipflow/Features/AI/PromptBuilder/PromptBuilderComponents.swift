//
//  PromptBuilderComponents.swift
//  Pipflow
//
//  Supporting Components for Enhanced Prompt Builder
//

import SwiftUI

// MARK: - Condition Builder Section

struct ConditionBuilderSection: View {
    let title: String
    @Binding var conditions: [ConditionItem]
    let theme: Theme
    
    @State private var showAddCondition = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Button(action: { showAddCondition = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(theme.accentColor)
                        .font(.system(size: 20))
                }
            }
            
            if conditions.isEmpty {
                Text("No conditions added yet")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(theme.separatorColor)
                    )
            } else {
                VStack(spacing: 8) {
                    ForEach(conditions.indices, id: \.self) { index in
                        ConditionRow(
                            condition: $conditions[index],
                            theme: theme,
                            onDelete: {
                                conditions.remove(at: index)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(16)
        .sheet(isPresented: $showAddCondition) {
            AddConditionView(
                conditions: $conditions,
                theme: theme
            )
        }
    }
}

// MARK: - Condition Row

struct ConditionRow: View {
    @Binding var condition: ConditionItem
    let theme: Theme
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: iconForCondition(condition))
                .foregroundColor(theme.accentColor)
                .frame(width: 30)
            
            Text(condition.description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(theme.secondaryTextColor)
                    .font(.system(size: 16))
            }
        }
        .padding(12)
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(8)
    }
    
    private func iconForCondition(_ condition: ConditionItem) -> String {
        switch condition.type {
        case .indicator: return "chart.line.uptrend.xyaxis"
        case .priceAction: return "chart.bar.fill"
        case .volume: return "chart.bar.doc.horizontal"
        case .time: return "clock"
        }
    }
}

// MARK: - Add Condition View

struct AddConditionView: View {
    @Binding var conditions: [ConditionItem]
    let theme: Theme
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: ConditionItem.ConditionType = .indicator
    @State private var selectedIndicator = "RSI"
    @State private var selectedComparison: ConditionItem.ComparisonOperator = .lessThan
    @State private var value: Double = 30
    
    let indicators = ["RSI", "MACD", "EMA", "SMA", "ATR", "Stochastic", "ADX", "Bollinger Bands"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Condition Type
                Picker("Type", selection: $selectedType) {
                    Text("Indicator").tag(ConditionItem.ConditionType.indicator)
                    Text("Price Action").tag(ConditionItem.ConditionType.priceAction)
                    Text("Volume").tag(ConditionItem.ConditionType.volume)
                    Text("Time").tag(ConditionItem.ConditionType.time)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Indicator Selection
                if selectedType == .indicator {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Indicator")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        
                        Picker("Indicator", selection: $selectedIndicator) {
                            ForEach(indicators, id: \.self) { indicator in
                                Text(indicator).tag(indicator)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }
                    .padding(.horizontal)
                }
                
                // Comparison Operator
                HStack {
                    Text("Condition")
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                    
                    Picker("Comparison", selection: $selectedComparison) {
                        Text("Greater than").tag(ConditionItem.ComparisonOperator.greaterThan)
                        Text("Less than").tag(ConditionItem.ComparisonOperator.lessThan)
                        Text("Equals").tag(ConditionItem.ComparisonOperator.equals)
                        Text("Crosses Above").tag(ConditionItem.ComparisonOperator.crossAbove)
                        Text("Crosses Below").tag(ConditionItem.ComparisonOperator.crossBelow)
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                
                // Value Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Value")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    HStack {
                        TextField("Value", value: $value, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                        
                        Stepper("", value: $value, in: 0...100, step: 5)
                    }
                }
                .padding(.horizontal)
                
                // Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text("\(selectedIndicator) \(selectedComparison.symbol) \(Int(value))")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(theme.secondaryBackgroundColor)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Add Condition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let newCondition = ConditionItem(
                            type: selectedType,
                            indicator: selectedIndicator,
                            comparison: selectedComparison,
                            value: value
                        )
                        conditions.append(newCondition)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Risk Management Section

struct RiskManagementSection: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    let theme: Theme
    
    @State private var stopLossType = 0 // 0: Percentage, 1: ATR, 2: Fixed Pips
    @State private var takeProfitType = 0 // 0: Risk/Reward, 1: Percentage, 2: Fixed Pips
    @State private var stopLossValue: Double = 2.0
    @State private var takeProfitValue: Double = 2.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Management")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            // Stop Loss
            VStack(alignment: .leading, spacing: 8) {
                Text("Stop Loss Strategy")
                    .font(.subheadline)
                    .foregroundColor(theme.textColor)
                
                Picker("Stop Loss Type", selection: $stopLossType) {
                    Text("Percentage").tag(0)
                    Text("ATR Multiple").tag(1)
                    Text("Fixed Pips").tag(2)
                }
                .pickerStyle(.segmented)
                
                HStack {
                    Text(stopLossLabel)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Spacer()
                    
                    TextField("Value", value: $stopLossValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    
                    Text(stopLossUnit)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .padding()
            .background(theme.secondaryBackgroundColor.opacity(0.5))
            .cornerRadius(12)
            
            // Take Profit
            VStack(alignment: .leading, spacing: 8) {
                Text("Take Profit Strategy")
                    .font(.subheadline)
                    .foregroundColor(theme.textColor)
                
                Picker("Take Profit Type", selection: $takeProfitType) {
                    Text("Risk/Reward").tag(0)
                    Text("Percentage").tag(1)
                    Text("Fixed Pips").tag(2)
                }
                .pickerStyle(.segmented)
                
                HStack {
                    Text(takeProfitLabel)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Spacer()
                    
                    TextField("Value", value: $takeProfitValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    
                    Text(takeProfitUnit)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .padding()
            .background(theme.secondaryBackgroundColor.opacity(0.5))
            .cornerRadius(12)
            
            // Position Sizing
            VStack(alignment: .leading, spacing: 8) {
                Text("Position Sizing")
                    .font(.subheadline)
                    .foregroundColor(theme.textColor)
                
                Toggle("Use Kelly Criterion", isOn: .constant(false))
                    .foregroundColor(theme.textColor)
                
                Toggle("Scale In/Out", isOn: .constant(false))
                    .foregroundColor(theme.textColor)
            }
            .padding()
            .background(theme.secondaryBackgroundColor.opacity(0.5))
            .cornerRadius(12)
        }
        .padding()
        .background(theme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(16)
    }
    
    private var stopLossLabel: String {
        switch stopLossType {
        case 0: return "Risk Percentage"
        case 1: return "ATR Multiplier"
        case 2: return "Pips"
        default: return ""
        }
    }
    
    private var stopLossUnit: String {
        switch stopLossType {
        case 0: return "%"
        case 1: return "x"
        case 2: return "pips"
        default: return ""
        }
    }
    
    private var takeProfitLabel: String {
        switch takeProfitType {
        case 0: return "Risk/Reward Ratio"
        case 1: return "Profit Percentage"
        case 2: return "Pips"
        default: return ""
        }
    }
    
    private var takeProfitUnit: String {
        switch takeProfitType {
        case 0: return ":1"
        case 1: return "%"
        case 2: return "pips"
        default: return ""
        }
    }
}

// MARK: - Time Filter Section

struct TimeFilterSection: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    let theme: Theme
    
    @State private var selectedSessions = Set<String>()
    @State private var selectedDays = Set<Int>()
    
    let sessions = [
        ("Asian", "07:00-16:00 JST"),
        ("London", "08:00-17:00 GMT"),
        ("New York", "08:00-17:00 EST"),
        ("Sydney", "22:00-07:00 GMT")
    ]
    
    let days = [
        (1, "Mon"),
        (2, "Tue"),
        (3, "Wed"),
        (4, "Thu"),
        (5, "Fri")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trading Time Filters")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            // Trading Sessions
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Sessions")
                    .font(.subheadline)
                    .foregroundColor(theme.textColor)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(sessions, id: \.0) { session in
                        SessionToggle(
                            name: session.0,
                            time: session.1,
                            isSelected: selectedSessions.contains(session.0),
                            theme: theme
                        ) {
                            if selectedSessions.contains(session.0) {
                                selectedSessions.remove(session.0)
                            } else {
                                selectedSessions.insert(session.0)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(theme.secondaryBackgroundColor.opacity(0.5))
            .cornerRadius(12)
            
            // Trading Days
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Days")
                    .font(.subheadline)
                    .foregroundColor(theme.textColor)
                
                HStack(spacing: 8) {
                    ForEach(days, id: \.0) { day in
                        DayToggle(
                            day: day.1,
                            isSelected: selectedDays.contains(day.0),
                            theme: theme
                        ) {
                            if selectedDays.contains(day.0) {
                                selectedDays.remove(day.0)
                            } else {
                                selectedDays.insert(day.0)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(theme.secondaryBackgroundColor.opacity(0.5))
            .cornerRadius(12)
        }
        .padding()
        .background(theme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(16)
    }
}

// MARK: - Symbol Selector

struct SymbolSelector: View {
    @Binding var selectedSymbols: Set<String>
    let theme: Theme
    
    let majorPairs = ["EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "USDCAD", "NZDUSD"]
    let minorPairs = ["EURGBP", "EURJPY", "GBPJPY", "AUDJPY", "EURAUD", "GBPAUD"]
    let exoticPairs = ["USDZAR", "USDTRY", "USDMXN", "USDSEK", "USDNOK"]
    let cryptoPairs = ["BTCUSD", "ETHUSD", "XRPUSD", "LTCUSD", "BNBUSD"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quick Select
            HStack(spacing: 12) {
                Button("All Majors") {
                    selectedSymbols = selectedSymbols.union(Set(majorPairs))
                }
                .buttonStyle(QuickSelectButton(theme: theme))
                
                Button("Clear All") {
                    selectedSymbols.removeAll()
                }
                .buttonStyle(QuickSelectButton(theme: theme))
            }
            
            // Major Pairs
            SymbolGroup(
                title: "Major Pairs",
                symbols: majorPairs,
                selectedSymbols: $selectedSymbols,
                theme: theme
            )
            
            // Minor Pairs
            SymbolGroup(
                title: "Minor Pairs",
                symbols: minorPairs,
                selectedSymbols: $selectedSymbols,
                theme: theme
            )
            
            // Crypto
            SymbolGroup(
                title: "Cryptocurrencies",
                symbols: cryptoPairs,
                selectedSymbols: $selectedSymbols,
                theme: theme
            )
        }
    }
}

struct SymbolGroup: View {
    let title: String
    let symbols: [String]
    @Binding var selectedSymbols: Set<String>
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
            
            FlowLayout(spacing: 8) {
                ForEach(symbols, id: \.self) { symbol in
                    PromptSymbolChip(
                        symbol: symbol,
                        isSelected: selectedSymbols.contains(symbol),
                        theme: theme
                    ) {
                        if selectedSymbols.contains(symbol) {
                            selectedSymbols.remove(symbol)
                        } else {
                            selectedSymbols.insert(symbol)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct SessionToggle: View {
    let name: String
    let time: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                Text(time)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : theme.textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? theme.accentColor : theme.secondaryBackgroundColor)
            .cornerRadius(8)
        }
    }
}

struct DayToggle: View {
    let day: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : theme.textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? theme.accentColor : theme.secondaryBackgroundColor)
                .cornerRadius(8)
        }
    }
}

struct PromptSymbolChip: View {
    let symbol: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? theme.accentColor : theme.secondaryBackgroundColor)
                .cornerRadius(15)
        }
    }
}

struct QuickSelectButton: ButtonStyle {
    let theme: Theme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(theme.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.accentColor.opacity(0.1))
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for row in result.rows {
            for index in row.indices {
                let x = row.xOffsets[index] + bounds.minX
                let y = row.yOffset + bounds.minY
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: row.proposals[index])
            }
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var rows: [Row]
        
        struct Row {
            var indices: Range<Int>
            var xOffsets: [Double]
            var proposals: [ProposedViewSize]
            var yOffset: Double
        }
        
        init(in maxWidth: Double, subviews: Subviews, spacing: CGFloat) {
            var rows: [Row] = []
            var currentX = 0.0
            var currentRow = Row(indices: 0..<0, xOffsets: [], proposals: [], yOffset: 0)
            var yOffset = 0.0
            
            for (index, subview) in zip(subviews.indices, subviews) {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > maxWidth && !currentRow.indices.isEmpty {
                    rows.append(currentRow)
                    yOffset += currentRow.proposals.map { $0.height ?? 0 }.max() ?? 0
                    yOffset += spacing
                    currentRow = Row(indices: index..<index, xOffsets: [], proposals: [], yOffset: yOffset)
                    currentX = 0
                }
                currentRow.indices = currentRow.indices.lowerBound..<(index + 1)
                currentRow.xOffsets.append(currentX)
                currentRow.proposals.append(.init(size))
                currentX += size.width + spacing
            }
            
            if !currentRow.indices.isEmpty {
                rows.append(currentRow)
                yOffset += currentRow.proposals.map { $0.height ?? 0 }.max() ?? 0
            }
            
            self.size = CGSize(width: maxWidth, height: yOffset)
            self.rows = rows
        }
    }
}

// MARK: - Trading Hours Selector

struct TradingHoursSelector: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    let theme: Theme
    
    @State private var selectedHours = Set<Int>()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select active trading hours (UTC)")
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                ForEach(0..<24) { hour in
                    Button(action: {
                        if selectedHours.contains(hour) {
                            selectedHours.remove(hour)
                        } else {
                            selectedHours.insert(hour)
                        }
                        updateTradingHours()
                    }) {
                        Text("\(hour)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedHours.contains(hour) ? .white : theme.textColor)
                            .frame(width: 40, height: 40)
                            .background(selectedHours.contains(hour) ? theme.accentColor : theme.secondaryBackgroundColor)
                            .cornerRadius(8)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button("Select All") {
                    selectedHours = Set(0..<24)
                    updateTradingHours()
                }
                .buttonStyle(QuickSelectButton(theme: theme))
                
                Button("Business Hours") {
                    selectedHours = Set(8..<18)
                    updateTradingHours()
                }
                .buttonStyle(QuickSelectButton(theme: theme))
                
                Button("24/5") {
                    selectedHours = Set(0..<24)
                    updateTradingHours()
                }
                .buttonStyle(QuickSelectButton(theme: theme))
            }
        }
    }
    
    private func updateTradingHours() {
        var restrictions = viewModel.context.timeRestrictions ?? TimeRestrictions(
            allowedHours: Array(0...23),
            allowedDaysOfWeek: Array(1...5),
            excludeNewsEvents: false,
            excludeMarketOpen: false,
            excludeMarketClose: false
        )
        restrictions.allowedHours = Array(selectedHours).sorted()
        viewModel.context.timeRestrictions = restrictions
    }
}

// MARK: - Advanced Settings View

struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("AI Model Settings") {
                    Picker("Model Provider", selection: .constant("Claude")) {
                        Text("Claude").tag("Claude")
                        Text("GPT-4").tag("GPT-4")
                        Text("Local Model").tag("Local")
                    }
                    
                    Slider(value: .constant(0.7), in: 0...1) {
                        Text("Creativity")
                    }
                    
                    Toggle("Use Chain of Thought", isOn: .constant(true))
                }
                
                Section("Backtesting") {
                    Toggle("Enable Backtesting", isOn: .constant(false))
                    
                    DatePicker("Start Date", selection: .constant(Date()))
                    DatePicker("End Date", selection: .constant(Date()))
                    
                    Picker("Data Source", selection: .constant("Historical")) {
                        Text("Historical").tag("Historical")
                        Text("Simulated").tag("Simulated")
                    }
                }
                
                Section("Safety Settings") {
                    Toggle("Paper Trading Only", isOn: .constant(true))
                    Toggle("Require Manual Confirmation", isOn: .constant(false))
                    Toggle("Enable Emergency Stop", isOn: .constant(true))
                    
                    Stepper("Max Daily Loss: 5%", value: .constant(5), in: 1...20)
                }
                
                Section("Notifications") {
                    Toggle("Trade Executions", isOn: .constant(true))
                    Toggle("Strategy Alerts", isOn: .constant(true))
                    Toggle("Performance Reports", isOn: .constant(false))
                }
            }
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}