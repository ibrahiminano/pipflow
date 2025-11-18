//
//  StrategyBuilderView.swift
//  Pipflow
//
//  Visual strategy builder with drag-and-drop components
//

import SwiftUI
import UniformTypeIdentifiers

struct StrategyBuilderView: View {
    @StateObject private var viewModel = StrategyBuilderViewModel()
    @State private var selectedComponent: StrategyComponent?
    @State private var showComponentPicker = false
    @State private var showTestResults = false
    @State private var showSaveDialog = false
    @State private var showNaturalLanguage = false
    @State private var strategyName = ""
    @State private var strategyDescription = ""
    
    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // Component Library
                componentLibrary
                    .frame(width: 250)
                    .background(Color.Theme.cardBackground)
                
                // Canvas Area
                ZStack {
                    // Grid Background
                    GridPattern()
                    
                    // Strategy Canvas
                    ScrollView([.horizontal, .vertical]) {
                        strategyCanvas
                            .frame(minWidth: 800, minHeight: 600)
                    }
                }
                .background(Color.Theme.background)
                
                // Properties Panel
                if let component = selectedComponent {
                    componentProperties(for: component)
                        .frame(width: 300)
                        .background(Color.Theme.cardBackground)
                }
            }
            .navigationTitle("Strategy Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    // Natural Language
                    Button(action: { showNaturalLanguage = true }) {
                        Label("Natural Language", systemImage: "text.bubble")
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Test Strategy
                    Button(action: { testStrategy() }) {
                        Label("Test", systemImage: "play.circle")
                    }
                    .disabled(viewModel.components.isEmpty)
                    
                    // Save Strategy
                    Button(action: { showSaveDialog = true }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                    .disabled(viewModel.components.isEmpty)
                    
                    // Load Strategy
                    Menu {
                        ForEach(viewModel.savedStrategies) { strategy in
                            Button(strategy.name) {
                                viewModel.loadStrategy(strategy)
                            }
                        }
                    } label: {
                        Label("Load", systemImage: "folder")
                    }
                }
            }
        }
        .sheet(isPresented: $showTestResults) {
            StrategyTestResultsView(results: viewModel.testResults)
        }
        .sheet(isPresented: $showSaveDialog) {
            SaveStrategyDialog(
                name: $strategyName,
                description: $strategyDescription,
                onSave: saveStrategy,
                onCancel: { showSaveDialog = false }
            )
        }
        .sheet(isPresented: $showNaturalLanguage) {
            NaturalLanguageStrategyView()
        }
    }
    
    // MARK: - Component Library
    
    private var componentLibrary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Components")
                .font(.headline)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Entry Conditions
                    ComponentSection(title: "Entry Conditions") {
                        ComponentItem(type: .priceAction, name: "Price Action", icon: "chart.line.uptrend.xyaxis")
                        ComponentItem(type: .indicator, name: "Indicator", icon: "waveform.path.ecg")
                        ComponentItem(type: .pattern, name: "Pattern", icon: "circle.grid.3x3")
                        ComponentItem(type: .time, name: "Time Filter", icon: "clock")
                        ComponentItem(type: .news, name: "News Event", icon: "newspaper")
                    }
                    
                    // Exit Conditions
                    ComponentSection(title: "Exit Conditions") {
                        ComponentItem(type: .stopLoss, name: "Stop Loss", icon: "stop.circle")
                        ComponentItem(type: .takeProfit, name: "Take Profit", icon: "checkmark.circle")
                        ComponentItem(type: .trailing, name: "Trailing Stop", icon: "arrow.triangle.2.circlepath")
                        ComponentItem(type: .timeExit, name: "Time Exit", icon: "timer")
                    }
                    
                    // Risk Management
                    ComponentSection(title: "Risk Management") {
                        ComponentItem(type: .positionSize, name: "Position Size", icon: "percent")
                        ComponentItem(type: .maxDrawdown, name: "Max Drawdown", icon: "arrow.down.to.line")
                        ComponentItem(type: .maxPositions, name: "Max Positions", icon: "number.circle")
                    }
                    
                    // Logic Gates
                    ComponentSection(title: "Logic") {
                        ComponentItem(type: .and, name: "AND Gate", icon: "arrow.triangle.merge")
                        ComponentItem(type: .or, name: "OR Gate", icon: "arrow.triangle.branch")
                        ComponentItem(type: .not, name: "NOT Gate", icon: "exclamationmark.circle")
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Strategy Canvas
    
    private var strategyCanvas: some View {
        ZStack {
            // Connections
            ForEach(viewModel.connections) { connection in
                ConnectionLine(
                    from: connectionPoint(for: connection.fromComponent, output: true),
                    to: connectionPoint(for: connection.toComponent, output: false)
                )
            }
            
            // Components
            ForEach(viewModel.components) { component in
                DraggableComponent(
                    component: component,
                    isSelected: selectedComponent?.id == component.id,
                    onTap: { selectedComponent = component },
                    onDrag: { offset in
                        viewModel.moveComponent(component, by: offset)
                    },
                    onConnect: { fromOutput in
                        handleConnection(from: component, output: fromOutput)
                    }
                )
                .position(component.position)
            }
        }
    }
    
    // MARK: - Properties Panel
    
    private func componentProperties(for component: StrategyComponent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: component.icon)
                Text(component.name)
                    .font(.headline)
                Spacer()
                Button(action: {
                    viewModel.removeComponent(component)
                    selectedComponent = nil
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(Color.Theme.error)
                }
            }
            .padding()
            
            Divider()
            
            // Properties
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch component.type {
                    case .indicator:
                        IndicatorProperties(component: component, viewModel: viewModel)
                    case .priceAction:
                        PriceActionProperties(component: component, viewModel: viewModel)
                    case .pattern:
                        PatternProperties(component: component, viewModel: viewModel)
                    case .stopLoss:
                        StopLossProperties(component: component, viewModel: viewModel)
                    case .takeProfit:
                        TakeProfitProperties(component: component, viewModel: viewModel)
                    case .positionSize:
                        PositionSizeProperties(component: component, viewModel: viewModel)
                    default:
                        GenericProperties(component: component, viewModel: viewModel)
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func connectionPoint(for componentId: UUID, output: Bool) -> CGPoint {
        guard let component = viewModel.components.first(where: { $0.id == componentId }) else {
            return .zero
        }
        
        let x = output ? component.position.x + 100 : component.position.x - 100
        return CGPoint(x: x, y: component.position.y)
    }
    
    private func handleConnection(from component: StrategyComponent, output: Bool) {
        // Implement connection logic
    }
    
    private func testStrategy() {
        viewModel.testStrategy { success in
            if success {
                showTestResults = true
            }
        }
    }
    
    private func saveStrategy() {
        viewModel.saveStrategy(name: strategyName, description: strategyDescription)
        showSaveDialog = false
        strategyName = ""
        strategyDescription = ""
    }
}

// MARK: - Supporting Views

struct ComponentSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
                .textCase(.uppercase)
            
            content
        }
    }
}

struct ComponentItem: View {
    let type: ComponentType
    let name: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 24)
            
            Text(name)
                .font(.subheadline)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.Theme.secondary.opacity(0.3))
        .cornerRadius(8)
        .draggable(ComponentDragItem(type: type, name: name, icon: icon))
    }
}

struct GridPattern: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 20
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Vertical lines
                for x in stride(from: 0, through: width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                
                // Horizontal lines
                for y in stride(from: 0, through: height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(Color.Theme.divider.opacity(0.2), lineWidth: 0.5)
        }
    }
}

struct DraggableComponent: View {
    let component: StrategyComponent
    let isSelected: Bool
    let onTap: () -> Void
    let onDrag: (CGSize) -> Void
    let onConnect: (Bool) -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Input Port
            Circle()
                .fill(Color.Theme.accent)
                .frame(width: 12, height: 12)
                .onTapGesture {
                    onConnect(false)
                }
            
            // Component Body
            VStack(spacing: 4) {
                Image(systemName: component.icon)
                    .font(.title2)
                
                Text(component.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 100, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.Theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.Theme.accent : Color.Theme.divider, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .onTapGesture(perform: onTap)
            
            // Output Port
            Circle()
                .fill(Color.Theme.accent)
                .frame(width: 12, height: 12)
                .onTapGesture {
                    onConnect(true)
                }
        }
        .offset(dragOffset)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isDragging)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                    isDragging = true
                }
                .onEnded { value in
                    onDrag(value.translation)
                    dragOffset = .zero
                    isDragging = false
                }
        )
    }
}

struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            
            let midX = (from.x + to.x) / 2
            let controlPoint1 = CGPoint(x: midX, y: from.y)
            let controlPoint2 = CGPoint(x: midX, y: to.y)
            
            path.addCurve(to: to, control1: controlPoint1, control2: controlPoint2)
        }
        .stroke(Color.Theme.accent, lineWidth: 2)
    }
}

struct SaveStrategyDialog: View {
    @Binding var name: String
    @Binding var description: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Strategy Details") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Save Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: onSave)
                        .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Property Views

struct IndicatorProperties: View {
    let component: StrategyComponent
    let viewModel: StrategyBuilderViewModel
    
    @State private var indicatorType = "RSI"
    @State private var period = 14
    @State private var overbought = 70.0
    @State private var oversold = 30.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Indicator Type")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Picker("Type", selection: $indicatorType) {
                Text("RSI").tag("RSI")
                Text("MACD").tag("MACD")
                Text("Moving Average").tag("MA")
                Text("Bollinger Bands").tag("BB")
                Text("Stochastic").tag("STOCH")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Divider()
            
            if indicatorType == "RSI" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Period: \(period)")
                        .font(.caption)
                    Slider(value: .init(get: { Double(period) }, set: { period = Int($0) }), in: 5...50, step: 1)
                    
                    Text("Overbought: \(Int(overbought))")
                        .font(.caption)
                    Slider(value: $overbought, in: 50...95, step: 5)
                    
                    Text("Oversold: \(Int(oversold))")
                        .font(.caption)
                    Slider(value: $oversold, in: 5...50, step: 5)
                }
            }
        }
        .onChange(of: indicatorType) { _ in updateComponent() }
        .onChange(of: period) { _ in updateComponent() }
        .onChange(of: overbought) { _ in updateComponent() }
        .onChange(of: oversold) { _ in updateComponent() }
    }
    
    private func updateComponent() {
        viewModel.updateComponentProperties(component, properties: [
            "type": indicatorType,
            "period": period,
            "overbought": overbought,
            "oversold": oversold
        ])
    }
}

struct PriceActionProperties: View {
    let component: StrategyComponent
    let viewModel: StrategyBuilderViewModel
    
    @State private var condition = "Above"
    @State private var priceType = "Close"
    @State private var compareWith = "Value"
    @State private var value = 1.0000
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Condition")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Picker("Condition", selection: $condition) {
                Text("Above").tag("Above")
                Text("Below").tag("Below")
                Text("Crosses Above").tag("CrossAbove")
                Text("Crosses Below").tag("CrossBelow")
            }
            .pickerStyle(MenuPickerStyle())
            
            Text("Price Type")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Picker("Price", selection: $priceType) {
                Text("Close").tag("Close")
                Text("Open").tag("Open")
                Text("High").tag("High")
                Text("Low").tag("Low")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text("Compare With")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Picker("Compare", selection: $compareWith) {
                Text("Value").tag("Value")
                Text("Moving Average").tag("MA")
                Text("Previous High").tag("PrevHigh")
                Text("Previous Low").tag("PrevLow")
            }
            .pickerStyle(MenuPickerStyle())
            
            if compareWith == "Value" {
                TextField("Value", value: $value, format: .number.precision(.fractionLength(4)))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .onChange(of: condition) { _ in updateComponent() }
        .onChange(of: priceType) { _ in updateComponent() }
        .onChange(of: compareWith) { _ in updateComponent() }
        .onChange(of: value) { _ in updateComponent() }
    }
    
    private func updateComponent() {
        viewModel.updateComponentProperties(component, properties: [
            "condition": condition,
            "priceType": priceType,
            "compareWith": compareWith,
            "value": value
        ])
    }
}

struct PatternProperties: View {
    let component: StrategyComponent
    let viewModel: StrategyBuilderViewModel
    
    @State private var patternType = "Doji"
    @State private var sensitivity = 0.7
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern Type")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Picker("Pattern", selection: $patternType) {
                Text("Doji").tag("Doji")
                Text("Hammer").tag("Hammer")
                Text("Shooting Star").tag("ShootingStar")
                Text("Engulfing").tag("Engulfing")
                Text("Harami").tag("Harami")
                Text("Head & Shoulders").tag("HeadShoulders")
                Text("Double Top").tag("DoubleTop")
                Text("Double Bottom").tag("DoubleBottom")
            }
            .pickerStyle(MenuPickerStyle())
            
            Text("Sensitivity: \(Int(sensitivity * 100))%")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Slider(value: $sensitivity, in: 0.5...1.0)
        }
        .onChange(of: patternType) { _ in updateComponent() }
        .onChange(of: sensitivity) { _ in updateComponent() }
    }
    
    private func updateComponent() {
        viewModel.updateComponentProperties(component, properties: [
            "patternType": patternType,
            "sensitivity": sensitivity
        ])
    }
}

struct StopLossProperties: View {
    let component: StrategyComponent
    let viewModel: StrategyBuilderViewModel
    
    @State private var stopType = "Fixed"
    @State private var value = 50.0
    @State private var atrMultiplier = 2.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stop Loss Type")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Picker("Type", selection: $stopType) {
                Text("Fixed Pips").tag("Fixed")
                Text("Percentage").tag("Percentage")
                Text("ATR Multiple").tag("ATR")
                Text("Previous Low").tag("PrevLow")
            }
            .pickerStyle(MenuPickerStyle())
            
            if stopType == "Fixed" {
                HStack {
                    Text("Pips:")
                    TextField("Value", value: $value, format: .number.precision(.fractionLength(1)))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            } else if stopType == "Percentage" {
                HStack {
                    Text("Percent:")
                    TextField("Value", value: $value, format: .percent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            } else if stopType == "ATR" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ATR Multiplier: \(atrMultiplier, specifier: "%.1f")")
                        .font(.caption)
                    Slider(value: $atrMultiplier, in: 0.5...5.0, step: 0.5)
                }
            }
        }
        .onChange(of: stopType) { _ in updateComponent() }
        .onChange(of: value) { _ in updateComponent() }
        .onChange(of: atrMultiplier) { _ in updateComponent() }
    }
    
    private func updateComponent() {
        viewModel.updateComponentProperties(component, properties: [
            "stopType": stopType,
            "value": value,
            "atrMultiplier": atrMultiplier
        ])
    }
}

struct TakeProfitProperties: View {
    let component: StrategyComponent
    let viewModel: StrategyBuilderViewModel
    
    @State private var tpType = "Fixed"
    @State private var value = 100.0
    @State private var riskRewardRatio = 2.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Take Profit Type")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Picker("Type", selection: $tpType) {
                Text("Fixed Pips").tag("Fixed")
                Text("Percentage").tag("Percentage")
                Text("Risk/Reward").tag("RiskReward")
                Text("Previous High").tag("PrevHigh")
            }
            .pickerStyle(MenuPickerStyle())
            
            if tpType == "Fixed" {
                HStack {
                    Text("Pips:")
                    TextField("Value", value: $value, format: .number.precision(.fractionLength(1)))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            } else if tpType == "Percentage" {
                HStack {
                    Text("Percent:")
                    TextField("Value", value: $value, format: .percent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            } else if tpType == "RiskReward" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("R:R Ratio: \(riskRewardRatio, specifier: "%.1f"):1")
                        .font(.caption)
                    Slider(value: $riskRewardRatio, in: 0.5...5.0, step: 0.5)
                }
            }
        }
        .onChange(of: tpType) { _ in updateComponent() }
        .onChange(of: value) { _ in updateComponent() }
        .onChange(of: riskRewardRatio) { _ in updateComponent() }
    }
    
    private func updateComponent() {
        viewModel.updateComponentProperties(component, properties: [
            "tpType": tpType,
            "value": value,
            "riskRewardRatio": riskRewardRatio
        ])
    }
}

struct PositionSizeProperties: View {
    let component: StrategyComponent
    let viewModel: StrategyBuilderViewModel
    
    @State private var sizeType = "FixedRisk"
    @State private var riskPercent = 1.0
    @State private var fixedLots = 0.01
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Position Size Type")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Picker("Type", selection: $sizeType) {
                Text("Fixed Risk %").tag("FixedRisk")
                Text("Fixed Lots").tag("FixedLots")
                Text("Kelly Criterion").tag("Kelly")
                Text("Martingale").tag("Martingale")
            }
            .pickerStyle(MenuPickerStyle())
            
            if sizeType == "FixedRisk" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Risk per Trade: \(riskPercent, specifier: "%.1f")%")
                        .font(.caption)
                    Slider(value: $riskPercent, in: 0.1...5.0, step: 0.1)
                }
            } else if sizeType == "FixedLots" {
                HStack {
                    Text("Lot Size:")
                    TextField("Lots", value: $fixedLots, format: .number.precision(.fractionLength(2)))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
        .onChange(of: sizeType) { _ in updateComponent() }
        .onChange(of: riskPercent) { _ in updateComponent() }
        .onChange(of: fixedLots) { _ in updateComponent() }
    }
    
    private func updateComponent() {
        viewModel.updateComponentProperties(component, properties: [
            "sizeType": sizeType,
            "riskPercent": riskPercent,
            "fixedLots": fixedLots
        ])
    }
}

struct GenericProperties: View {
    let component: StrategyComponent
    let viewModel: StrategyBuilderViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Component Type")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Text(component.type.rawValue)
                .font(.body)
            
            Text("No additional properties available for this component.")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
                .padding(.top)
        }
    }
}

// MARK: - Drag Item

struct ComponentDragItem: Transferable, Codable {
    let type: ComponentType
    let name: String
    let icon: String
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .strategyComponent)
    }
}

extension UTType {
    static let strategyComponent = UTType(exportedAs: "com.pipflow.strategycomponent")
}

#Preview {
    StrategyBuilderView()
}