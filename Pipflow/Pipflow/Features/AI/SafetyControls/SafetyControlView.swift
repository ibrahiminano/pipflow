//
//  SafetyControlView.swift
//  Pipflow
//
//  Safety and control features UI for AI trading
//

import SwiftUI

struct SafetyControlView: View {
    @StateObject private var viewModel = SafetyControlViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showEmergencyConfirmation = false
    @State private var showResumeConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Safety Score Header
                    SafetyScoreHeader(
                        metrics: viewModel.safetyMetrics,
                        isEmergencyStopActive: viewModel.isEmergencyStopActive,
                        tradingPaused: viewModel.tradingPaused,
                        theme: themeManager.currentTheme
                    )
                    
                    // Tab Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            SafetyTab(title: "Controls", icon: "shield", isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            SafetyTab(title: "Alerts", icon: "bell", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                            SafetyTab(title: "Approvals", icon: "checkmark.shield", isSelected: selectedTab == 2) {
                                selectedTab = 2
                            }
                            SafetyTab(title: "Anomalies", icon: "exclamationmark.triangle", isSelected: selectedTab == 3) {
                                selectedTab = 3
                            }
                            SafetyTab(title: "Settings", icon: "gearshape", isSelected: selectedTab == 4) {
                                selectedTab = 4
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        SafetyControlsTab(
                            viewModel: viewModel,
                            theme: themeManager.currentTheme,
                            onEmergencyStop: { showEmergencyConfirmation = true },
                            onResume: { showResumeConfirmation = true }
                        )
                        .tag(0)
                        
                        SafetyAlertsTab(
                            alerts: viewModel.currentAlerts,
                            theme: themeManager.currentTheme
                        )
                        .tag(1)
                        
                        ApprovalsTab(
                            approvals: viewModel.pendingApprovals,
                            theme: themeManager.currentTheme,
                            onApprove: viewModel.approveTrade,
                            onReject: viewModel.rejectTrade
                        )
                        .tag(2)
                        
                        AnomaliesTab(
                            anomalies: viewModel.anomalyReports,
                            theme: themeManager.currentTheme
                        )
                        .tag(3)
                        
                        SafetySettingsTab(
                            settings: $viewModel.settings,
                            theme: themeManager.currentTheme
                        )
                        .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Safety Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEmergencyStopActive {
                        Text("EMERGENCY STOP")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(4)
                    } else if viewModel.tradingPaused {
                        Text("PAUSED")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .alert("Emergency Stop", isPresented: $showEmergencyConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Activate", role: .destructive) {
                viewModel.activateEmergencyStop()
            }
        } message: {
            Text("This will immediately halt all trading activities and close all positions. Are you sure?")
        }
        .alert("Resume Trading", isPresented: $showResumeConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Resume") {
                viewModel.resumeTrading()
            }
        } message: {
            Text("Are you sure you want to resume trading? All safety checks will be re-enabled.")
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
}

// MARK: - Safety Score Header

struct SafetyScoreHeader: View {
    let metrics: SafetyMetrics
    let isEmergencyStopActive: Bool
    let tradingPaused: Bool
    let theme: Theme
    
    var statusColor: Color {
        if isEmergencyStopActive { return .red }
        if tradingPaused { return .orange }
        if metrics.safetyScore < 50 { return .red }
        if metrics.safetyScore < 70 { return .orange }
        return .green
    }
    
    var statusText: String {
        if isEmergencyStopActive { return "EMERGENCY STOP ACTIVE" }
        if tradingPaused { return "TRADING PAUSED" }
        if metrics.safetyScore < 50 { return "High Risk" }
        if metrics.safetyScore < 70 { return "Moderate Risk" }
        return "Safe"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Safety Score
            ZStack {
                Circle()
                    .stroke(theme.separatorColor, lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: metrics.safetyScore / 100)
                    .stroke(statusColor, lineWidth: 8)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: metrics.safetyScore)
                
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", metrics.safetyScore))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.textColor)
                    
                    Text("Safety Score")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            Text(statusText)
                .font(.headline)
                .foregroundColor(statusColor)
            
            // Quick Metrics
            HStack(spacing: 20) {
                SafetyQuickMetric(
                    title: "Daily P&L",
                    value: String(format: "$%.0f", metrics.dailyPnL),
                    color: metrics.dailyPnL >= 0 ? .green : .red,
                    theme: theme
                )
                
                SafetyQuickMetric(
                    title: "Drawdown",
                    value: String(format: "%.1f%%", metrics.currentDrawdown * 100),
                    color: metrics.currentDrawdown > 0.1 ? .red : .green,
                    theme: theme
                )
                
                SafetyQuickMetric(
                    title: "Positions",
                    value: "\(metrics.openPositions)",
                    color: theme.accentColor,
                    theme: theme
                )
                
                SafetyQuickMetric(
                    title: "Anomalies",
                    value: "\(metrics.anomaliesDetected)",
                    color: metrics.anomaliesDetected > 0 ? .orange : .green,
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
    }
}

struct SafetyQuickMetric: View {
    let title: String
    let value: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Safety Controls Tab

struct SafetyControlsTab: View {
    @ObservedObject var viewModel: SafetyControlViewModel
    let theme: Theme
    let onEmergencyStop: () -> Void
    let onResume: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Emergency Controls
                EmergencyControlsCard(
                    isEmergencyStopActive: viewModel.isEmergencyStopActive,
                    tradingPaused: viewModel.tradingPaused,
                    theme: theme,
                    onEmergencyStop: onEmergencyStop,
                    onPause: { viewModel.pauseTrading(reason: "Manual pause") },
                    onResume: onResume
                )
                
                // Paper Trading Toggle
                PaperTradingCard(
                    isEnabled: viewModel.settings.isPaperTradingEnabled,
                    theme: theme
                ) { enabled in
                    viewModel.settings.isPaperTradingEnabled = enabled
                }
                
                // Risk Limits
                SafetyRiskLimitsCard(
                    settings: viewModel.settings,
                    currentMetrics: viewModel.safetyMetrics,
                    theme: theme
                )
                
                // Trading Hours
                SafetyTradingHoursCard(
                    tradingHours: viewModel.settings.allowedTradingHours,
                    theme: theme
                )
                
                // Position Limits
                PositionLimitsCard(
                    maxPositions: viewModel.settings.maxOpenPositions,
                    maxLeverage: viewModel.settings.maxLeverageAllowed,
                    currentPositions: viewModel.safetyMetrics.openPositions,
                    currentLeverage: viewModel.safetyMetrics.currentLeverage,
                    theme: theme
                )
            }
            .padding()
        }
    }
}

// MARK: - Emergency Controls Card

struct EmergencyControlsCard: View {
    let isEmergencyStopActive: Bool
    let tradingPaused: Bool
    let theme: Theme
    let onEmergencyStop: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emergency Controls")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            VStack(spacing: 12) {
                // Emergency Stop Button
                Button(action: onEmergencyStop) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("EMERGENCY STOP")
                                .font(.system(size: 16, weight: .bold))
                            Text("Halt all trading & close positions")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        isEmergencyStopActive ?
                        Color.gray :
                        Color.red
                    )
                    .cornerRadius(12)
                }
                .disabled(isEmergencyStopActive)
                
                // Pause/Resume Trading
                if !isEmergencyStopActive {
                    Button(action: tradingPaused ? onResume : onPause) {
                        HStack {
                            Image(systemName: tradingPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 24))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tradingPaused ? "RESUME TRADING" : "PAUSE TRADING")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(tradingPaused ? "Resume normal operations" : "Temporarily halt new trades")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            tradingPaused ?
                            Color.green :
                            Color.orange
                        )
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Paper Trading Card

struct PaperTradingCard: View {
    let isEnabled: Bool
    let theme: Theme
    let onToggle: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Paper Trading Mode")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text(isEnabled ? "All trades are simulated" : "Live trading enabled")
                        .font(.caption)
                        .foregroundColor(isEnabled ? .green : .orange)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
            }
            
            if isEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Paper trading is active. No real orders will be executed.")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Risk Limits Card

struct SafetyRiskLimitsCard: View {
    let settings: SafetySettings
    let currentMetrics: SafetyMetrics
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Limits")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            // Daily Loss Limit
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily Loss Limit")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                    
                    Text(String(format: "$%.0f", settings.dailyLossLimit))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.accentColor)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.separatorColor)
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(lossLimitColor)
                            .frame(
                                width: geometry.size.width * min(abs(currentMetrics.dailyPnL) / settings.dailyLossLimit, 1.0),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)
                
                Text("Current: \(String(format: "$%.0f", currentMetrics.dailyPnL))")
                    .font(.caption)
                    .foregroundColor(currentMetrics.dailyPnL < 0 ? .red : .green)
            }
            
            Divider()
                .background(theme.separatorColor)
            
            // Max Drawdown Limit
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Max Drawdown Limit")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", settings.maxDrawdownLimit * 100))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.accentColor)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.separatorColor)
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(drawdownColor)
                            .frame(
                                width: geometry.size.width * min(currentMetrics.currentDrawdown / settings.maxDrawdownLimit, 1.0),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)
                
                Text("Current: \(String(format: "%.1f%%", currentMetrics.currentDrawdown * 100))")
                    .font(.caption)
                    .foregroundColor(drawdownColor)
            }
            
            Divider()
                .background(theme.separatorColor)
            
            // Approval Threshold
            HStack {
                Text("Require Approval Above")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Text(String(format: "$%.0f", settings.requireApprovalAbove))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.accentColor)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private var lossLimitColor: Color {
        let ratio = abs(currentMetrics.dailyPnL) / settings.dailyLossLimit
        if ratio > 0.8 { return .red }
        if ratio > 0.6 { return .orange }
        return .green
    }
    
    private var drawdownColor: Color {
        let ratio = currentMetrics.currentDrawdown / settings.maxDrawdownLimit
        if ratio > 0.8 { return .red }
        if ratio > 0.6 { return .orange }
        return .green
    }
}

// MARK: - Trading Hours Card

struct SafetyTradingHoursCard: View {
    let tradingHours: TradingHours
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trading Hours")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            Text("Configure allowed trading hours for each day")
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
            
            // Show a few day examples
            if let monday = tradingHours.monday, monday.isEnabled {
                DayScheduleRow(day: "Monday", schedule: monday, theme: theme)
            }
            
            if let friday = tradingHours.friday, friday.isEnabled {
                DayScheduleRow(day: "Friday", schedule: friday, theme: theme)
            }
            
            Button(action: {}) {
                Text("Configure All Days")
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct DayScheduleRow: View {
    let day: String
    let schedule: DaySchedule
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(day)
                .font(.system(size: 14))
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            Text("\(schedule.startTime) - \(schedule.endTime)")
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
        }
    }
}

// MARK: - Position Limits Card

struct PositionLimitsCard: View {
    let maxPositions: Int
    let maxLeverage: Double
    let currentPositions: Int
    let currentLeverage: Double
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Position Limits")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max Open Positions")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text("\(currentPositions) / \(maxPositions)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(positionsColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Max Leverage")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text(String(format: "%.1fx / %.0fx", currentLeverage, maxLeverage))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(leverageColor)
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private var positionsColor: Color {
        let ratio = Double(currentPositions) / Double(maxPositions)
        if ratio > 0.8 { return .red }
        if ratio > 0.6 { return .orange }
        return .green
    }
    
    private var leverageColor: Color {
        let ratio = currentLeverage / maxLeverage
        if ratio > 0.8 { return .red }
        if ratio > 0.6 { return .orange }
        return .green
    }
}

// MARK: - Safety Tab

struct SafetyTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(8)
        }
    }
}

// MARK: - View Model

@MainActor
class SafetyControlViewModel: ObservableObject {
    @Published var settings: SafetySettings
    @Published var safetyMetrics: SafetyMetrics
    @Published var currentAlerts: [SafetyAlert] = []
    @Published var pendingApprovals: [ApprovalRequest] = []
    @Published var anomalyReports: [TradingAnomalyReport] = []
    @Published var isEmergencyStopActive = false
    @Published var tradingPaused = false
    
    private let safetyManager = SafetyControlManager.shared
    
    init() {
        self.settings = safetyManager.settings
        self.safetyMetrics = safetyManager.safetyMetrics
        self.currentAlerts = safetyManager.currentAlerts
        self.pendingApprovals = safetyManager.pendingApprovals
        self.anomalyReports = safetyManager.anomalyReports
        self.isEmergencyStopActive = safetyManager.isEmergencyStopActive
        self.tradingPaused = safetyManager.tradingPaused
    }
    
    func startMonitoring() {
        safetyManager.startSafetyMonitoring()
        
        // Subscribe to updates
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateFromManager()
        }
    }
    
    func stopMonitoring() {
        safetyManager.stopSafetyMonitoring()
    }
    
    func activateEmergencyStop() {
        safetyManager.activateEmergencyStop()
        updateFromManager()
    }
    
    func pauseTrading(reason: String) {
        safetyManager.pauseTrading(reason: reason)
        updateFromManager()
    }
    
    func resumeTrading() {
        if isEmergencyStopActive {
            safetyManager.deactivateEmergencyStop()
        } else {
            safetyManager.resumeTrading()
        }
        updateFromManager()
    }
    
    func approveTrade(_ id: UUID, notes: String? = nil) {
        safetyManager.approveTrade(id, notes: notes)
        updateFromManager()
    }
    
    func rejectTrade(_ id: UUID, reason: String) {
        safetyManager.rejectTrade(id, reason: reason)
        updateFromManager()
    }
    
    private func updateFromManager() {
        self.settings = safetyManager.settings
        self.safetyMetrics = safetyManager.safetyMetrics
        self.currentAlerts = safetyManager.currentAlerts
        self.pendingApprovals = safetyManager.pendingApprovals
        self.anomalyReports = safetyManager.anomalyReports
        self.isEmergencyStopActive = safetyManager.isEmergencyStopActive
        self.tradingPaused = safetyManager.tradingPaused
    }
}