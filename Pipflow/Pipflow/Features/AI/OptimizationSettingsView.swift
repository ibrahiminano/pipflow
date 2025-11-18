//
//  OptimizationSettingsView.swift
//  Pipflow
//
//  Settings for strategy optimization constraints
//

import SwiftUI

struct StrategyOptimizationSettingsView: View {
    @Binding var maxDrawdown: Double
    @Binding var minWinRate: Double
    @Binding var maxLeverage: Double
    @Binding var minTradesPerMonth: Int
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var maxConsecutiveLosses = 5
    @State private var minProfitFactor = 1.5
    @State private var minSharpeRatio = 1.0
    @State private var riskPerTrade = 2.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Risk Constraints
                    ConstraintSection(title: "Risk Constraints", icon: "shield") {
                        ConstraintSlider(
                            label: "Maximum Drawdown",
                            value: $maxDrawdown,
                            range: 5...50,
                            unit: "%",
                            color: .red,
                            description: "Maximum acceptable peak-to-trough decline"
                        )
                        
                        ConstraintSlider(
                            label: "Risk Per Trade",
                            value: $riskPerTrade,
                            range: 0.5...5,
                            step: 0.5,
                            unit: "%",
                            color: .orange,
                            description: "Maximum capital risk per individual trade"
                        )
                        
                        ConstraintSlider(
                            label: "Maximum Leverage",
                            value: $maxLeverage,
                            range: 1...50,
                            unit: "x",
                            color: .purple,
                            description: "Maximum position size multiplier"
                        )
                        
                        ConstraintSlider(
                            label: "Max Consecutive Losses",
                            value: Binding(
                                get: { Double(maxConsecutiveLosses) },
                                set: { maxConsecutiveLosses = Int($0) }
                            ),
                            range: 3...10,
                            step: 1,
                            unit: " trades",
                            color: .red,
                            description: "Maximum losing streak tolerance"
                        )
                    }
                    
                    // Performance Constraints
                    ConstraintSection(title: "Performance Constraints", icon: "chart.line.uptrend.xyaxis") {
                        ConstraintSlider(
                            label: "Minimum Win Rate",
                            value: $minWinRate,
                            range: 30...70,
                            unit: "%",
                            color: .green,
                            description: "Minimum acceptable winning trade percentage"
                        )
                        
                        ConstraintSlider(
                            label: "Minimum Profit Factor",
                            value: $minProfitFactor,
                            range: 1...3,
                            step: 0.1,
                            unit: "",
                            color: .blue,
                            description: "Ratio of gross profit to gross loss"
                        )
                        
                        ConstraintSlider(
                            label: "Minimum Sharpe Ratio",
                            value: $minSharpeRatio,
                            range: 0.5...3,
                            step: 0.1,
                            unit: "",
                            color: .indigo,
                            description: "Risk-adjusted return metric"
                        )
                    }
                    
                    // Activity Constraints
                    ConstraintSection(title: "Activity Constraints", icon: "calendar") {
                        ConstraintSlider(
                            label: "Min Trades Per Month",
                            value: Binding(
                                get: { Double(minTradesPerMonth) },
                                set: { minTradesPerMonth = Int($0) }
                            ),
                            range: 1...50,
                            step: 1,
                            unit: " trades",
                            color: .teal,
                            description: "Minimum monthly trading activity"
                        )
                    }
                    
                    // Preset Templates
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preset Templates")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                PresetButton(
                                    name: "Conservative",
                                    icon: "shield.fill",
                                    color: .blue,
                                    action: applyConservativePreset
                                )
                                
                                PresetButton(
                                    name: "Moderate",
                                    icon: "gauge",
                                    color: .orange,
                                    action: applyModeratePreset
                                )
                                
                                PresetButton(
                                    name: "Aggressive",
                                    icon: "flame",
                                    color: .red,
                                    action: applyAggressivePreset
                                )
                                
                                PresetButton(
                                    name: "Scalping",
                                    icon: "bolt",
                                    color: .purple,
                                    action: applyScalpingPreset
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Optimization Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Preset Actions
    
    private func applyConservativePreset() {
        withAnimation {
            maxDrawdown = 10
            minWinRate = 60
            maxLeverage = 5
            minTradesPerMonth = 5
            maxConsecutiveLosses = 3
            minProfitFactor = 2.0
            minSharpeRatio = 1.5
            riskPerTrade = 1.0
        }
    }
    
    private func applyModeratePreset() {
        withAnimation {
            maxDrawdown = 20
            minWinRate = 50
            maxLeverage = 10
            minTradesPerMonth = 10
            maxConsecutiveLosses = 5
            minProfitFactor = 1.5
            minSharpeRatio = 1.0
            riskPerTrade = 2.0
        }
    }
    
    private func applyAggressivePreset() {
        withAnimation {
            maxDrawdown = 30
            minWinRate = 40
            maxLeverage = 20
            minTradesPerMonth = 20
            maxConsecutiveLosses = 7
            minProfitFactor = 1.2
            minSharpeRatio = 0.75
            riskPerTrade = 3.0
        }
    }
    
    private func applyScalpingPreset() {
        withAnimation {
            maxDrawdown = 15
            minWinRate = 65
            maxLeverage = 30
            minTradesPerMonth = 50
            maxConsecutiveLosses = 10
            minProfitFactor = 1.3
            minSharpeRatio = 0.5
            riskPerTrade = 0.5
        }
    }
}

// MARK: - Constraint Section
struct ConstraintSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.accentColor)
            
            VStack(spacing: 20) {
                content
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
    }
}

// MARK: - Constraint Slider
struct ConstraintSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    let unit: String
    let color: Color
    let description: String
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(formatValue(value))
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                        .frame(minWidth: 40, alignment: .trailing)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            HStack(spacing: 12) {
                Text(formatValue(range.lowerBound))
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Slider(value: $value, in: range, step: step) { editing in
                    isEditing = editing
                }
                .accentColor(color)
                
                Text(formatValue(range.upperBound))
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            if isEditing {
                // Visual feedback bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.2))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(
                                width: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)
                .animation(.easeInOut(duration: 0.2), value: value)
            }
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Preset Button
struct PresetButton: View {
    let name: String
    let icon: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
            .frame(width: 80, height: 80)
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Circular Progress View
struct CircularProgressView<Content: View>: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 10
    @ViewBuilder let content: Content
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            content
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    StrategyOptimizationSettingsView(
        maxDrawdown: .constant(20),
        minWinRate: .constant(50),
        maxLeverage: .constant(10),
        minTradesPerMonth: .constant(10)
    )
    .environmentObject(ThemeManager())
}