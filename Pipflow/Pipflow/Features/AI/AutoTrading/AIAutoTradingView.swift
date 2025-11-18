//
//  AIAutoTradingView.swift
//  Pipflow
//
//  AI Auto-Trading control interface
//

import SwiftUI

struct AIAutoTradingView: View {
    @StateObject private var engine = AIAutoTradingEngine.shared
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showStrategyBuilder = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main Control
                AutoTradingControlCard(engine: engine, pulseAnimation: $pulseAnimation)
                    .padding(.horizontal)
                
                // Performance Metrics
                PerformanceMetricsSection(metrics: engine.metrics)
                    .padding(.horizontal)
                
                // Active Trades
                if !engine.activeTrades.isEmpty {
                    ActiveTradesSection(trades: engine.activeTrades)
                        .padding(.horizontal)
                }
                
                // Current Signals
                if !engine.currentSignals.isEmpty {
                    CurrentSignalsSection(signals: engine.currentSignals)
                        .padding(.horizontal)
                }
                
                // Quick Actions
                QuickActionsSection(
                    engine: engine,
                    showSettings: $showSettings,
                    showHistory: $showHistory
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.Theme.background)
        .navigationTitle("AI Auto-Trading")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSettings) {
            AutoTradingSettingsView(engine: engine)
        }
        .sheet(isPresented: $showHistory) {
            TradeHistoryView(trades: engine.tradeHistory)
        }
        .sheet(isPresented: $showStrategyBuilder) {
            StrategyBuilderView()
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
}

struct AutoTradingControlCard: View {
    @ObservedObject var engine: AIAutoTradingEngine
    @Binding var pulseAnimation: Bool
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Indicator
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .scaleEffect(engine.isActive && pulseAnimation ? 1.2 : 1.0)
                
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                if let lastAnalysis = engine.lastAnalysis {
                    Text("Last: \(lastAnalysis, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
            }
            
            // Main Control Button
            Button(action: toggleAutoTrading) {
                HStack {
                    Image(systemName: engine.isActive ? "stop.fill" : "play.fill")
                        .font(.title2)
                    
                    Text(engine.isActive ? "Stop Auto-Trading" : "Start Auto-Trading")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(engine.isActive ? Color.red : Color.Theme.accent)
                )
            }
            
            // Pause/Resume Button
            if engine.isActive && engine.state != .stopped {
                Button(action: togglePause) {
                    HStack {
                        Image(systemName: engine.state == .paused ? "play.fill" : "pause.fill")
                        Text(engine.state == .paused ? "Resume" : "Pause")
                    }
                    .foregroundColor(Color.Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.Theme.accent, lineWidth: 1)
                    )
                }
            }
            
            // Status Message
            Text(engine.statusMessage)
                .font(.caption)
                .foregroundColor(Color.Theme.text.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Trading Mode
            HStack {
                Label("Mode", systemImage: "slider.horizontal.3")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
                
                Spacer()
                
                Text(engine.config.mode.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color.Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.Theme.accent.opacity(0.1))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
        .confirmationDialog(
            "Start Auto-Trading?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Start Trading", role: .destructive) {
                engine.startAutoTrading()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("AI will automatically execute trades based on your settings. Make sure you understand the risks.")
        }
    }
    
    private var statusColor: Color {
        switch engine.state {
        case .idle, .stopped:
            return Color.gray
        case .analyzing:
            return Color.blue
        case .executingTrade:
            return Color.orange
        case .monitoring:
            return Color.Theme.accent
        case .paused:
            return Color.yellow
        }
    }
    
    private var statusText: String {
        switch engine.state {
        case .idle:
            return "Idle"
        case .analyzing:
            return "Analyzing Markets"
        case .executingTrade:
            return "Executing Trade"
        case .monitoring:
            return "Monitoring Positions"
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        }
    }
    
    private func toggleAutoTrading() {
        if engine.isActive {
            engine.stopAutoTrading()
        } else {
            showConfirmation = true
        }
    }
    
    private func togglePause() {
        if engine.state == .paused {
            engine.resumeAutoTrading()
        } else {
            engine.pauseAutoTrading()
        }
    }
}

struct PerformanceMetricsSection: View {
    let metrics: AutoTradingMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AutoTradingMetricCard(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", metrics.winRate * 100),
                    icon: "percent",
                    color: metrics.winRate >= 0.55 ? .green : .orange
                )
                
                AutoTradingMetricCard(
                    title: "Net Profit",
                    value: String(format: "$%.2f", metrics.netProfit),
                    icon: "dollarsign.circle",
                    color: metrics.netProfit >= 0 ? .green : .red
                )
                
                AutoTradingMetricCard(
                    title: "Total Trades",
                    value: "\(metrics.totalTrades)",
                    icon: "arrow.left.arrow.right",
                    color: Color.Theme.accent
                )
                
                AutoTradingMetricCard(
                    title: "Profit Factor",
                    value: String(format: "%.2f", metrics.profitFactor),
                    icon: "chart.line.uptrend.xyaxis",
                    color: metrics.profitFactor >= 1.5 ? .green : .orange
                )
            }
            
            // Daily Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's P&L")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                    
                    Spacer()
                    
                    Text(String(format: "$%.2f", metrics.dailyProfit))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(metrics.dailyProfit >= 0 ? .green : .red)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.Theme.text.opacity(0.1))
                            .frame(height: 8)
                        
                        if metrics.sessionStartBalance > 0 {
                            let progress = (metrics.dailyProfit / metrics.sessionStartBalance) + 1
                            let width = geometry.size.width * min(max(progress, 0), 2) / 2
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(metrics.dailyProfit >= 0 ? Color.green : Color.red)
                                .frame(width: width, height: 8)
                        }
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct AutoTradingMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.Theme.text)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.text.opacity(0.6))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Theme.background)
        )
    }
}

struct ActiveTradesSection: View {
    let trades: [TrackedPosition]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active AI Trades")
                    .font(.headline)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
                
                Text("\(trades.count)")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.Theme.accent.opacity(0.1))
                    )
            }
            
            ForEach(trades) { trade in
                AutoTradeRow(position: trade)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct AutoTradeRow: View {
    let position: TrackedPosition
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(position.symbol)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.Theme.text)
                    
                    Text(position.type == .buy ? "BUY" : "SELL")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(position.type == .buy ? Color.green : Color.red)
                        )
                }
                
                Text("\(String(format: "%.2f", position.volume)) lots @ \(String(format: "%.5f", position.openPrice))")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", position.unrealizedPL))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(position.unrealizedPL >= 0 ? .green : .red)
                
                Text("\(String(format: "%.1f", position.pipsProfit)) pips")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
    }
}

struct CurrentSignalsSection: View {
    let signals: [AISignal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Signals")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            ForEach(signals) { signal in
                SignalRow(signal: signal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct SignalRow: View {
    let signal: AISignal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(signal.symbol)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.Theme.text)
                
                HStack(spacing: 4) {
                    Image(systemName: signal.action == .buy ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                        .foregroundColor(signal.action == .buy ? .green : .red)
                    
                    Text(signal.action.rawValue)
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Confidence: \(Int(signal.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(Color.Theme.accent)
                
                Text("Analyzing...")
                    .font(.caption2)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
    }
}

struct QuickActionsSection: View {
    @ObservedObject var engine: AIAutoTradingEngine
    @Binding var showSettings: Bool
    @Binding var showHistory: Bool
    @State private var showStrategyBuilder = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: { showStrategyBuilder = true }) {
                HStack {
                    Image(systemName: "cpu")
                    Text("Strategy Builder")
                    Spacer()
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.Theme.accent)
                        .cornerRadius(4)
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(Color.Theme.text)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.Theme.surface)
                )
            }
            
            Button(action: { showSettings = true }) {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(Color.Theme.text)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.Theme.surface)
                )
            }
            
            Button(action: { showHistory = true }) {
                HStack {
                    Image(systemName: "clock")
                    Text("Trade History")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(Color.Theme.text)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.Theme.surface)
                )
            }
        }
        .sheet(isPresented: $showStrategyBuilder) {
            StrategyBuilderView()
        }
    }
}

#Preview {
    NavigationView {
        AIAutoTradingView()
    }
}