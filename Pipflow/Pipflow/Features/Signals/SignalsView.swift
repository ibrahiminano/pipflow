//
//  SignalsView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI

struct SignalsView: View {
    @StateObject private var viewModel = SignalsViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedFilter: SignalFilter = .all
    @State private var showGenerateSignal = false
    @State private var showPromptBuilder = false
    @State private var showMyStrategies = false
    @State private var showAIDashboard = false
    @State private var showSafetyControls = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // AI Actions Bar
                    AIActionsBar(
                        showPromptBuilder: $showPromptBuilder,
                        showGenerateSignal: $showGenerateSignal,
                        showAIDashboard: $showAIDashboard,
                        showSafetyControls: $showSafetyControls,
                        theme: themeManager.currentTheme
                    )
                    
                    // Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SignalFilter.allCases, id: \.self) { filter in
                                SignalFilterChip(
                                    title: filter.title,
                                    isSelected: selectedFilter == filter,
                                    theme: themeManager.currentTheme
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    
                    // Signals List
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                            .scaleEffect(1.5)
                        Spacer()
                    } else if filteredSignals.isEmpty && viewModel.activePrompts.isEmpty {
                        Spacer()
                        EmptySignalsView(theme: themeManager.currentTheme)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Debug
                                Text("DEBUG: \(viewModel.activePrompts.count) active prompts")
                                    .foregroundColor(.red)
                                
                                // Active Strategies Section
                                if !viewModel.activePrompts.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Active AI Strategies")
                                                .font(.headline)
                                                .foregroundColor(themeManager.currentTheme.textColor)
                                            
                                            Spacer()
                                            
                                            Button(action: { showMyStrategies = true }) {
                                                Text("View All")
                                                    .font(.caption)
                                                    .foregroundColor(themeManager.currentTheme.accentColor)
                                            }
                                        }
                                        
                                        ForEach(viewModel.activePrompts.prefix(3)) { prompt in
                                            ActiveStrategyCard(prompt: prompt, theme: themeManager.currentTheme)
                                        }
                                    }
                                    .padding(.bottom, 20)
                                }
                                
                                // Signals Section
                                if !filteredSignals.isEmpty {
                                    Text("Trading Signals")
                                        .font(.headline)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.bottom, 8)
                                }
                                
                                ForEach(filteredSignals) { signal in
                                    SignalCard(
                                        signal: signal,
                                        theme: themeManager.currentTheme,
                                        onExecute: {
                                            viewModel.executeSignal(signal)
                                        }
                                    )
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showAIDashboard = true }) {
                            Label("AI Dashboard", systemImage: "brain")
                        }
                        Button(action: { showPromptBuilder = true }) {
                            Label("AI Prompt Builder", systemImage: "sparkles.rectangle.stack")
                        }
                        Button(action: { showMyStrategies = true }) {
                            Label("My Strategies", systemImage: "list.bullet.rectangle")
                        }
                        Button(action: { showGenerateSignal = true }) {
                            Label("Generate Signal", systemImage: "sparkles")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
        }
        .sheet(isPresented: $showGenerateSignal) {
            GenerateSignalView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showPromptBuilder) {
            EnhancedPromptBuilderView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showMyStrategies) {
            PromptPerformanceView()
        }
        .sheet(isPresented: $showAIDashboard) {
            NavigationView {
                AIStrategyDashboard()
                    .environmentObject(themeManager)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showAIDashboard = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showSafetyControls) {
            SafetyControlView()
                .environmentObject(themeManager)
        }
        .onAppear {
            print("DEBUG: Active prompts count on appear: \(viewModel.activePrompts.count)")
            print("DEBUG: Signals count on appear: \(viewModel.signals.count)")
            print("DEBUG: PromptTradingEngine active prompts: \(PromptTradingEngine.shared.activePrompts.count)")
        }
    }
    
    private var filteredSignals: [Signal] {
        switch selectedFilter {
        case .all:
            return viewModel.signals
        case .buy:
            return viewModel.signals.filter { $0.action == .buy }
        case .sell:
            return viewModel.signals.filter { $0.action == .sell }
        case .highConfidence:
            return viewModel.signals.filter { $0.confidence >= 0.8 }
        case .active:
            return viewModel.signals.filter { $0.expiresAt > Date() }
        }
    }
}

// MARK: - Signal Filter

enum SignalFilter: String, CaseIterable {
    case all
    case buy
    case sell
    case highConfidence
    case active
    
    var title: String {
        switch self {
        case .all: return "All"
        case .buy: return "Buy"
        case .sell: return "Sell"
        case .highConfidence: return "High Confidence"
        case .active: return "Active"
        }
    }
}

// MARK: - Filter Chip

struct SignalFilterChip: View {
    let title: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? theme.accentColor : theme.secondaryBackgroundColor)
                )
        }
    }
}

// MARK: - Signal Card

struct SignalCard: View {
    let signal: Signal
    let theme: Theme
    let onExecute: () -> Void
    @State private var isExpanded = false
    @State private var showingExecuteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(signal.symbol)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.textColor)
                        
                        SignalBadge(action: signal.action, theme: theme)
                    }
                    
                    Text(signal.timeframe.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    ConfidenceIndicator(confidence: signal.confidence, theme: theme)
                    
                    Text(timeRemaining)
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .padding()
            
            Divider()
                .background(theme.separatorColor)
            
            // Price Levels
            VStack(spacing: 12) {
                PriceLevelRow(
                    label: "Entry",
                    value: signal.entry,
                    icon: "arrow.right.circle.fill",
                    color: theme.accentColor,
                    theme: theme
                )
                
                PriceLevelRow(
                    label: "Stop Loss",
                    value: signal.stopLoss,
                    icon: "xmark.octagon.fill",
                    color: .red,
                    theme: theme
                )
                
                if let firstTP = signal.takeProfits.first {
                    PriceLevelRow(
                        label: "Take Profit",
                        value: firstTP.price,
                        icon: "checkmark.circle.fill",
                        color: .green,
                        theme: theme
                    )
                }
            }
            .padding()
            
            // Reasoning (Expandable)
            if !signal.rationale.isEmpty {
                Divider()
                    .background(theme.separatorColor)
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack {
                        Text("AI Analysis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textColor)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    .padding()
                }
                
                if isExpanded {
                    Text(signal.rationale)
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryTextColor)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .transition(.opacity)
                }
            }
            
            // Action Button
            Divider()
                .background(theme.separatorColor)
            
            Button(action: { showingExecuteConfirmation = true }) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16))
                    
                    Text("Execute Signal")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            signal.action == .buy ? Color.green : Color.red,
                            signal.action == .buy ? Color.green.opacity(0.8) : Color.red.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .shadow(color: theme.shadowColor, radius: 8, x: 0, y: 4)
        .alert("Execute Signal?", isPresented: $showingExecuteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Execute", role: .destructive) {
                onExecute()
            }
        } message: {
            Text("This will open a \(signal.action.rawValue.uppercased()) position for \(signal.symbol) at market price.")
        }
    }
    
    private var timeRemaining: String {
        let remaining = signal.expiresAt.timeIntervalSinceNow
        if remaining <= 0 {
            return "Expired"
        } else if remaining < 3600 {
            return "\(Int(remaining / 60))m remaining"
        } else {
            return "\(Int(remaining / 3600))h remaining"
        }
    }
}

// MARK: - Supporting Views

struct SignalBadge: View {
    let action: SignalAction
    let theme: Theme
    
    var body: some View {
        Text(action.rawValue.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(action == .buy ? Color.green : (action == .sell ? Color.red : Color.gray))
            )
    }
}

struct ConfidenceIndicator: View {
    let confidence: Double
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(
                        Double(index) < confidence * 5 ? Color.yellow : theme.separatorColor
                    )
            }
        }
    }
}

struct PriceLevelRow: View {
    let label: String
    let value: Decimal
    let icon: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
            
            Spacer()
            
            Text(formatPrice(value))
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(theme.textColor)
        }
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 5
        return formatter.string(from: price as NSNumber) ?? "0.00"
    }
}

struct EmptySignalsView: View {
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 60))
                .foregroundColor(theme.secondaryTextColor.opacity(0.5))
            
            Text("No Active Signals")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(theme.textColor)
            
            Text("AI-generated signals will appear here")
                .font(.system(size: 16))
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Active Strategy Card

struct ActiveStrategyCard: View {
    let prompt: TradingPrompt
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles.rectangle.stack")
                    .foregroundColor(theme.accentColor)
                    .font(.system(size: 20))
                
                Text(prompt.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Text(prompt.isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)
            }
            
            Text(prompt.prompt)
                .font(.system(size: 14))
                .foregroundColor(theme.textColor.opacity(0.8))
                .lineLimit(2)
            
            HStack {
                Label("Strategy", systemImage: "checklist")
                    .font(.caption)
                    .foregroundColor(theme.textColor.opacity(0.6))
                
                Spacer()
                
                if let performance = prompt.performanceMetrics {
                    Label("\(performance.totalTrades) trades", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(theme.textColor.opacity(0.6))
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .shadow(color: theme.shadowColor, radius: 8, x: 0, y: 4)
    }
    
    private var statusColor: Color {
        return prompt.isActive ? .green : .gray
    }
}

// MARK: - AI Actions Bar

struct AIActionsBar: View {
    @Binding var showPromptBuilder: Bool
    @Binding var showGenerateSignal: Bool
    @Binding var showAIDashboard: Bool
    @Binding var showSafetyControls: Bool
    let theme: Theme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // AI Dashboard
                Button(action: { showAIDashboard = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "brain")
                            .font(.system(size: 20))
                        Text("Dashboard")
                            .font(.caption2)
                    }
                    .foregroundColor(theme.accentColor)
                    .frame(width: 80, height: 60)
                    .background(theme.accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // AI Prompt Builder
                Button(action: { showPromptBuilder = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.system(size: 18))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Strategy Builder")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Create complex strategies")
                                .font(.caption2)
                                .opacity(0.7)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .opacity(0.5)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [theme.accentColor, theme.accentColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Quick Signal Generator
                Button(action: { showGenerateSignal = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                        Text("Quick Signal")
                            .font(.caption2)
                    }
                    .foregroundColor(theme.accentColor)
                    .frame(width: 80, height: 60)
                    .background(theme.accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Safety Controls
                Button(action: { 
                    print("DEBUG: Safety button tapped")
                    showSafetyControls = true 
                    print("DEBUG: showSafetyControls set to: \(showSafetyControls)")
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 20))
                        Text("Safety")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                    .frame(width: 80, height: 60)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(theme.backgroundColor)
    }
}

#Preview {
    SignalsView()
        .environmentObject(ThemeManager())
}