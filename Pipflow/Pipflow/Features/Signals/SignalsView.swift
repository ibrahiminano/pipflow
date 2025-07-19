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
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SignalFilter.allCases, id: \.self) { filter in
                                FilterChip(
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
                    } else if filteredSignals.isEmpty {
                        Spacer()
                        EmptySignalsView(theme: themeManager.currentTheme)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
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
            .navigationTitle("AI Signals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showGenerateSignal = true }) {
                        Image(systemName: "sparkles")
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
        .onAppear {
            viewModel.startListening()
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

struct FilterChip: View {
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

#Preview {
    SignalsView()
        .environmentObject(ThemeManager())
}