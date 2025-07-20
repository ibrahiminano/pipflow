//
//  AIChartComponents.swift
//  Pipflow
//
//  Created by Claude on 19/07/2025.
//

import SwiftUI
import Charts

// MARK: - AI Chart Models

enum AIChartFeature: String, CaseIterable {
    case signals = "Signals"
    case patterns = "Patterns"
    case supportResistance = "S/R Levels"
    case predictions = "Predictions"
    case riskZones = "Risk Zones"
    case commentary = "Commentary"
    case trendAnalysis = "Trends"
    
    var icon: String {
        switch self {
        case .signals: return "sparkles"
        case .patterns: return "chart.line.uptrend.xyaxis.circle"
        case .supportResistance: return "line.horizontal.3"
        case .predictions: return "waveform.path.ecg.rectangle"
        case .riskZones: return "exclamationmark.triangle"
        case .commentary: return "message"
        case .trendAnalysis: return "arrow.up.right.circle"
        }
    }
}

struct AIChartAnalysis {
    let patterns: [ChartPattern]
    let supportLevels: [PriceLevel]
    let resistanceLevels: [PriceLevel]
    let predictions: PricePrediction?
    let riskZones: [RiskZone]
    let signals: [AISignal]
    let trendAnalysis: TrendAnalysis
    let marketCommentary: String
    let timestamp: Date
}

struct ChartPattern {
    let type: PatternType
    let startIndex: Int
    let endIndex: Int
    let confidence: Double
    let description: String
    
    enum PatternType: String {
        case headAndShoulders = "Head and Shoulders"
        case triangle = "Triangle"
        case wedge = "Wedge"
        case flag = "Flag"
        case doubleTop = "Double Top"
        case doubleBottom = "Double Bottom"
        case channel = "Channel"
    }
}

struct PriceLevel {
    let price: Double
    let strength: Double // 0-1
    let touches: Int
    let lastTested: Date
}

struct PricePrediction {
    let timeHorizon: Int // minutes
    let predictedPrice: Double
    let upperBound: Double
    let lowerBound: Double
    let confidence: Double
}

struct RiskZone {
    let startPrice: Double
    let endPrice: Double
    let riskLevel: RiskLevel
    let reason: String
    
    enum RiskLevel: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green.opacity(0.3)
            case .medium: return .yellow.opacity(0.3)
            case .high: return .red.opacity(0.3)
            }
        }
    }
}

struct AISignal {
    let type: SignalAction
    let price: Double
    let confidence: Double
    let reason: String
    let timestamp: Date
}

struct TrendAnalysis {
    let shortTerm: TrendDirection
    let mediumTerm: TrendDirection
    let longTerm: TrendDirection
    let strength: Double
    let momentum: Double
}

// MARK: - AI Feature Toggle Bar

struct AIFeatureToggleBar: View {
    @Binding var selectedFeatures: Set<AIChartFeature>
    let onSettingsTapped: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AIChartFeature.allCases, id: \.self) { feature in
                    FeatureToggle(
                        feature: feature,
                        isSelected: selectedFeatures.contains(feature),
                        action: { toggleFeature(feature) }
                    )
                }
                
                Button(action: onSettingsTapped) {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(themeManager.currentTheme.cardBackgroundColor)
                        )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func toggleFeature(_ feature: AIChartFeature) {
        if selectedFeatures.contains(feature) {
            selectedFeatures.remove(feature)
        } else {
            selectedFeatures.insert(feature)
        }
    }
}

struct FeatureToggle: View {
    let feature: AIChartFeature
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: feature.icon)
                    .font(.system(size: 14))
                Text(feature.rawValue)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? themeManager.currentTheme.backgroundColor : themeManager.currentTheme.textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.cardBackgroundColor)
            )
        }
    }
}

// MARK: - AI Chart Overlay

struct AIChartOverlay: View {
    let analysis: AIChartAnalysis?
    let selectedFeatures: Set<AIChartFeature>
    let candles: [CandleData]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        GeometryReader { geometry in
            if let analysis = analysis {
                ZStack {
                    // Support & Resistance Levels
                    if selectedFeatures.contains(.supportResistance) {
                        SupportResistanceOverlay(
                            supportLevels: analysis.supportLevels,
                            resistanceLevels: analysis.resistanceLevels,
                            geometry: geometry,
                            candles: candles
                        )
                    }
                    
                    // Risk Zones
                    if selectedFeatures.contains(.riskZones) {
                        RiskZonesOverlay(
                            riskZones: analysis.riskZones,
                            geometry: geometry,
                            candles: candles
                        )
                    }
                    
                    // Chart Patterns
                    if selectedFeatures.contains(.patterns) {
                        PatternOverlay(
                            patterns: analysis.patterns,
                            geometry: geometry,
                            candles: candles
                        )
                    }
                    
                    // AI Signals
                    if selectedFeatures.contains(.signals) {
                        SignalsOverlay(
                            signals: analysis.signals,
                            geometry: geometry,
                            candles: candles
                        )
                    }
                    
                    // Price Predictions
                    if selectedFeatures.contains(.predictions), let prediction = analysis.predictions {
                        PredictionOverlay(
                            prediction: prediction,
                            geometry: geometry,
                            candles: candles
                        )
                    }
                    
                    // Trend Analysis
                    if selectedFeatures.contains(.trendAnalysis) {
                        TrendOverlay(
                            trendAnalysis: analysis.trendAnalysis,
                            geometry: geometry
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Support & Resistance Overlay

struct SupportResistanceOverlay: View {
    let supportLevels: [PriceLevel]
    let resistanceLevels: [PriceLevel]
    let geometry: GeometryProxy
    let candles: [CandleData]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Support Levels
            ForEach(supportLevels.indices, id: \.self) { index in
                let level = supportLevels[index]
                let y = priceToY(price: level.price)
                
                HStack {
                    Rectangle()
                        .fill(Color.green.opacity(level.strength))
                        .frame(height: 2)
                    
                    Text("S: \(String(format: "%.5f", level.price))")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.currentTheme.backgroundColor.opacity(0.8))
                        )
                }
                .position(x: geometry.size.width / 2, y: y)
            }
            
            // Resistance Levels
            ForEach(resistanceLevels.indices, id: \.self) { index in
                let level = resistanceLevels[index]
                let y = priceToY(price: level.price)
                
                HStack {
                    Rectangle()
                        .fill(Color.red.opacity(level.strength))
                        .frame(height: 2)
                    
                    Text("R: \(String(format: "%.5f", level.price))")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.currentTheme.backgroundColor.opacity(0.8))
                        )
                }
                .position(x: geometry.size.width / 2, y: y)
            }
        }
    }
    
    private func priceToY(price: Double) -> CGFloat {
        guard let minPrice = candles.map({ min($0.low, $0.high) }).min(),
              let maxPrice = candles.map({ max($0.low, $0.high) }).max() else {
            return 0
        }
        
        let range = maxPrice - minPrice
        let normalized = (price - minPrice) / range
        return geometry.size.height * (1 - normalized)
    }
}

// MARK: - AI Commentary Panel

struct AICommentaryPanel: View {
    let analysis: AIChartAnalysis?
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(themeManager.currentTheme.accentColor)
                Text("AI Market Commentary")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            if let commentary = analysis?.marketCommentary {
                ScrollView {
                    Text(commentary)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.easeInOut, value: isExpanded)
                }
                .frame(maxHeight: isExpanded ? .infinity : 60)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.cardBackgroundColor)
        )
    }
}

// MARK: - AI Settings View

struct AIChartSettingsView: View {
    @Binding var selectedFeatures: Set<AIChartFeature>
    let viewModel: ChartViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var autoRefresh = true
    @State private var refreshInterval: Double = 30
    @State private var confidenceThreshold: Double = 0.7
    @State private var showNotifications = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("AI Features") {
                    ForEach(AIChartFeature.allCases, id: \.self) { feature in
                        Toggle(isOn: Binding(
                            get: { selectedFeatures.contains(feature) },
                            set: { isOn in
                                if isOn {
                                    selectedFeatures.insert(feature)
                                } else {
                                    selectedFeatures.remove(feature)
                                }
                            }
                        )) {
                            Label(feature.rawValue, systemImage: feature.icon)
                        }
                    }
                }
                
                Section("Analysis Settings") {
                    Toggle("Auto-refresh Analysis", isOn: $autoRefresh)
                    
                    if autoRefresh {
                        HStack {
                            Text("Refresh Interval")
                            Spacer()
                            Text("\(Int(refreshInterval))s")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        Slider(value: $refreshInterval, in: 10...120, step: 10)
                    }
                    
                    HStack {
                        Text("Confidence Threshold")
                        Spacer()
                        Text("\(Int(confidenceThreshold * 100))%")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    Slider(value: $confidenceThreshold, in: 0.5...0.95, step: 0.05)
                }
                
                Section("Notifications") {
                    Toggle("Signal Notifications", isOn: $showNotifications)
                    Toggle("Pattern Detection Alerts", isOn: $showNotifications)
                    Toggle("Risk Zone Warnings", isOn: $showNotifications)
                }
            }
            .navigationTitle("AI Chart Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Additional Overlay Components

struct SignalsOverlay: View {
    let signals: [AISignal]
    let geometry: GeometryProxy
    let candles: [CandleData]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ForEach(signals.indices, id: \.self) { index in
            let signal = signals[index]
            let y = priceToY(price: signal.price)
            
            VStack(spacing: 4) {
                Image(systemName: signal.type == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(signal.type == .buy ? .green : .red)
                
                Text("\(Int(signal.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(themeManager.currentTheme.backgroundColor.opacity(0.8))
                    )
            }
            .position(x: geometry.size.width - 50, y: y)
        }
    }
    
    private func priceToY(price: Double) -> CGFloat {
        guard let minPrice = candles.map({ min($0.low, $0.high) }).min(),
              let maxPrice = candles.map({ max($0.low, $0.high) }).max() else {
            return 0
        }
        
        let range = maxPrice - minPrice
        let normalized = (price - minPrice) / range
        return geometry.size.height * (1 - normalized)
    }
}

struct RiskZonesOverlay: View {
    let riskZones: [RiskZone]
    let geometry: GeometryProxy
    let candles: [CandleData]
    
    var body: some View {
        ForEach(riskZones.indices, id: \.self) { index in
            let zone = riskZones[index]
            let topY = priceToY(price: zone.endPrice)
            let bottomY = priceToY(price: zone.startPrice)
            
            Rectangle()
                .fill(zone.riskLevel.color)
                .frame(width: geometry.size.width, height: abs(bottomY - topY))
                .position(x: geometry.size.width / 2, y: (topY + bottomY) / 2)
        }
    }
    
    private func priceToY(price: Double) -> CGFloat {
        guard let minPrice = candles.map({ min($0.low, $0.high) }).min(),
              let maxPrice = candles.map({ max($0.low, $0.high) }).max() else {
            return 0
        }
        
        let range = maxPrice - minPrice
        let normalized = (price - minPrice) / range
        return geometry.size.height * (1 - normalized)
    }
}

struct PatternOverlay: View {
    let patterns: [ChartPattern]
    let geometry: GeometryProxy
    let candles: [CandleData]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ForEach(patterns.indices, id: \.self) { index in
            let pattern = patterns[index]
            
            if pattern.startIndex < candles.count && pattern.endIndex < candles.count {
                PatternShape(
                    pattern: pattern,
                    candles: Array(candles[pattern.startIndex...pattern.endIndex]),
                    geometry: geometry,
                    allCandles: candles
                )
                .stroke(themeManager.currentTheme.accentColor, lineWidth: 2)
                .overlay(
                    Text(pattern.type.rawValue)
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.currentTheme.backgroundColor.opacity(0.8))
                        )
                        .position(
                            x: CGFloat(pattern.startIndex + pattern.endIndex) / 2 * (geometry.size.width / CGFloat(candles.count)),
                            y: 20
                        )
                )
            }
        }
    }
}

struct PatternShape: Shape {
    let pattern: ChartPattern
    let candles: [CandleData]
    let geometry: GeometryProxy
    let allCandles: [CandleData]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Simple pattern visualization - connect highs and lows
        for (index, candle) in candles.enumerated() {
            let x = CGFloat(pattern.startIndex + index) / CGFloat(allCandles.count) * rect.width
            let highY = priceToY(price: candle.high, in: rect)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: highY))
            } else {
                path.addLine(to: CGPoint(x: x, y: highY))
            }
        }
        
        return path
    }
    
    private func priceToY(price: Double, in rect: CGRect) -> CGFloat {
        guard let minPrice = allCandles.map({ min($0.low, $0.high) }).min(),
              let maxPrice = allCandles.map({ max($0.low, $0.high) }).max() else {
            return 0
        }
        
        let range = maxPrice - minPrice
        let normalized = (price - minPrice) / range
        return rect.height * (1 - normalized)
    }
}

struct PredictionOverlay: View {
    let prediction: PricePrediction
    let geometry: GeometryProxy
    let candles: [CandleData]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Prediction band
            Path { path in
                let startX = geometry.size.width
                let endX = startX + CGFloat(prediction.timeHorizon) * 2
                
                let upperY = priceToY(price: prediction.upperBound)
                let lowerY = priceToY(price: prediction.lowerBound)
                let predictedY = priceToY(price: prediction.predictedPrice)
                
                path.move(to: CGPoint(x: startX, y: upperY))
                path.addLine(to: CGPoint(x: endX, y: upperY))
                path.addLine(to: CGPoint(x: endX, y: lowerY))
                path.addLine(to: CGPoint(x: startX, y: lowerY))
                path.closeSubpath()
            }
            .fill(themeManager.currentTheme.accentColor.opacity(0.2))
            
            // Predicted price line
            Path { path in
                let startX = geometry.size.width
                let endX = startX + CGFloat(prediction.timeHorizon) * 2
                let y = priceToY(price: prediction.predictedPrice)
                
                path.move(to: CGPoint(x: startX, y: y))
                path.addLine(to: CGPoint(x: endX, y: y))
            }
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            .foregroundColor(themeManager.currentTheme.accentColor)
        }
    }
    
    private func priceToY(price: Double) -> CGFloat {
        guard let minPrice = candles.map({ min($0.low, $0.high) }).min(),
              let maxPrice = candles.map({ max($0.low, $0.high) }).max() else {
            return 0
        }
        
        let range = maxPrice - minPrice
        let normalized = (price - minPrice) / range
        return geometry.size.height * (1 - normalized)
    }
}

struct TrendOverlay: View {
    let trendAnalysis: TrendAnalysis
    let geometry: GeometryProxy
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TrendIndicator(label: "Short", trend: trendAnalysis.shortTerm)
            TrendIndicator(label: "Medium", trend: trendAnalysis.mediumTerm)
            TrendIndicator(label: "Long", trend: trendAnalysis.longTerm)
            
            HStack(spacing: 4) {
                Text("Strength:")
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                Text("\(Int(trendAnalysis.strength * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.currentTheme.cardBackgroundColor.opacity(0.9))
        )
        .position(x: 60, y: 50)
    }
}

struct TrendIndicator: View {
    let label: String
    let trend: TrendDirection
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Image(systemName: trend == .bullish ? "arrow.up.right" : (trend == .bearish ? "arrow.down.right" : "arrow.right"))
                .font(.caption)
                .foregroundColor(trend == .bullish ? .green : (trend == .bearish ? .red : .gray))
        }
    }
}