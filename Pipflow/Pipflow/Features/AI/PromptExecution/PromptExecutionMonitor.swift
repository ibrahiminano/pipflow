//
//  PromptExecutionMonitor.swift
//  Pipflow
//
//  Real-time monitoring and control for AI trading strategies
//

import SwiftUI
import Combine

struct PromptExecutionMonitor: View {
    @StateObject private var viewModel = PromptExecutionViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedPromptId: String?
    @State private var showEditPrompt = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.activePrompts.isEmpty {
                    PromptExecutionEmptyStateView(theme: themeManager.currentTheme)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Engine Status
                            EngineStatusCard(
                                isRunning: viewModel.isEngineRunning,
                                lastUpdate: viewModel.lastEngineUpdate,
                                theme: themeManager.currentTheme,
                                onToggle: viewModel.toggleEngine
                            )
                            
                            // Active Strategies
                            ForEach(viewModel.activePrompts) { prompt in
                                ActivePromptCard(
                                    prompt: prompt,
                                    performance: viewModel.getPerformance(for: prompt.id),
                                    executionLog: viewModel.getExecutionLog(for: prompt.id),
                                    theme: themeManager.currentTheme,
                                    onEdit: {
                                        selectedPromptId = prompt.id
                                        showEditPrompt = true
                                    },
                                    onToggle: {
                                        viewModel.togglePrompt(prompt.id)
                                    },
                                    onDelete: {
                                        viewModel.deletePrompt(prompt.id)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Strategy Monitor")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEditPrompt = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditPrompt) {
            if let promptId = selectedPromptId,
               let prompt = viewModel.activePrompts.first(where: { $0.id == promptId }) {
                PromptEditView(prompt: prompt, onSave: { updatedPrompt in
                    viewModel.updatePrompt(updatedPrompt)
                })
                .environmentObject(themeManager)
            } else {
                EnhancedPromptBuilderView()
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
}

// MARK: - Engine Status Card

struct EngineStatusCard: View {
    let isRunning: Bool
    let lastUpdate: Date
    let theme: Theme
    let onToggle: () -> Void
    
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Trading Engine")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isRunning ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(isRunning ? Color.green : Color.red, lineWidth: 8)
                                    .scaleEffect(pulseAnimation ? 1.5 : 1)
                                    .opacity(pulseAnimation ? 0 : 1)
                                    .animation(
                                        isRunning ? Animation.easeOut(duration: 1).repeatForever(autoreverses: false) : .default,
                                        value: pulseAnimation
                                    )
                            )
                        
                        Text(isRunning ? "Active" : "Stopped")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        
                        Text("•")
                            .foregroundColor(theme.separatorColor)
                        
                        Text("Updated \(timeAgo)")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                Button(action: onToggle) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(isRunning ? Color.red : Color.green)
                        .cornerRadius(22)
                }
            }
            
            if isRunning {
                HStack(spacing: 20) {
                    EngineMetric(
                        label: "Monitoring",
                        value: "5",
                        unit: "strategies",
                        icon: "eye",
                        theme: theme
                    )
                    
                    EngineMetric(
                        label: "Executed",
                        value: "12",
                        unit: "trades today",
                        icon: "checkmark.circle",
                        theme: theme
                    )
                    
                    EngineMetric(
                        label: "P&L",
                        value: "+$245",
                        unit: "today",
                        icon: "chart.line.uptrend.xyaxis",
                        theme: theme
                    )
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private var timeAgo: String {
        let interval = Date().timeIntervalSince(lastUpdate)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

struct EngineMetric: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(theme.accentColor)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textColor)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active Prompt Card

struct ActivePromptCard: View {
    let prompt: TradingPrompt
    let performance: PromptPerformance?
    let executionLog: [ExecutionLogEntry]
    let theme: Theme
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var showDetails = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prompt.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    HStack(spacing: 8) {
                        PromptStatusBadge(
                            isActive: prompt.isActive,
                            theme: theme
                        )
                        
                        if let performance = performance {
                            AIPerformanceBadge(
                                winRate: performance.winRate,
                                theme: theme
                            )
                        }
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit Strategy", systemImage: "pencil")
                    }
                    
                    Button(action: onToggle) {
                        Label(prompt.isActive ? "Pause" : "Resume", systemImage: prompt.isActive ? "pause" : "play")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(theme.secondaryTextColor)
                        .font(.system(size: 20))
                }
            }
            .padding()
            
            Divider()
                .background(theme.separatorColor)
            
            // Prompt Preview
            Text(prompt.prompt)
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
                .lineLimit(showDetails ? nil : 2)
                .padding()
            
            if let performance = performance {
                Divider()
                    .background(theme.separatorColor)
                
                // Performance Metrics
                HStack(spacing: 20) {
                    MetricView(
                        label: "Trades",
                        value: "\(performance.totalTrades)",
                        theme: theme
                    )
                    
                    MetricView(
                        label: "Win Rate",
                        value: String(format: "%.1f%%", performance.winRate * 100),
                        theme: theme
                    )
                    
                    MetricView(
                        label: "P&L",
                        value: formatCurrency(performance.totalProfitLoss),
                        valueColor: performance.totalProfitLoss >= 0 ? .green : .red,
                        theme: theme
                    )
                    
                    MetricView(
                        label: "Max DD",
                        value: formatCurrency(performance.maxDrawdown),
                        valueColor: .orange,
                        theme: theme
                    )
                }
                .padding()
            }
            
            if showDetails && !executionLog.isEmpty {
                Divider()
                    .background(theme.separatorColor)
                
                // Execution Log
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Executions")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    ForEach(executionLog.prefix(5)) { entry in
                        ExecutionLogRow(entry: entry, theme: theme)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
            
            // Expand/Collapse Button
            Button(action: { withAnimation { showDetails.toggle() } }) {
                HStack {
                    Text(showDetails ? "Show Less" : "Show More")
                        .font(.caption)
                        .foregroundColor(theme.accentColor)
                    
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .alert("Delete Strategy?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This will permanently delete the strategy and all its performance data.")
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(value))) ?? "$0"
    }
}

// MARK: - Supporting Components

struct PromptStatusBadge: View {
    let isActive: Bool
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
            
            Text(isActive ? "Active" : "Paused")
                .font(.caption2)
                .foregroundColor(isActive ? Color.green : Color.gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isActive ? Color.green : Color.gray).opacity(0.1))
        .cornerRadius(4)
    }
}

struct AIPerformanceBadge: View {
    let winRate: Double
    let theme: Theme
    
    var color: Color {
        if winRate >= 0.7 { return .green }
        else if winRate >= 0.5 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        Text("\(Int(winRate * 100))% Win")
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(4)
    }
}

struct MetricView: View {
    let label: String
    let value: String
    var valueColor: Color = Color.primary
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(valueColor == Color.primary ? theme.textColor : valueColor)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExecutionLogRow: View {
    let entry: ExecutionLogEntry
    let theme: Theme
    
    var body: some View {
        HStack {
            Image(systemName: entry.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(entry.success ? .green : .red)
                .font(.caption)
            
            Text(entry.action)
                .font(.caption)
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            Text(entry.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(.vertical, 4)
    }
}

struct PromptExecutionEmptyStateView: View {
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 60))
                .foregroundColor(theme.secondaryTextColor.opacity(0.5))
            
            Text("No Active Strategies")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.textColor)
            
            Text("Create your first AI trading strategy to start automated trading")
                .font(.body)
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - View Model

@MainActor
class PromptExecutionViewModel: ObservableObject {
    @Published var activePrompts: [TradingPrompt] = []
    @Published var isEngineRunning = false
    @Published var lastEngineUpdate = Date()
    @Published var performances: [String: PromptPerformance] = [:]
    @Published var executionLogs: [String: [ExecutionLogEntry]] = [:]
    
    private let promptEngine = PromptTradingEngine.shared
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    func startMonitoring() {
        // Bind to prompt engine
        promptEngine.$activePrompts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] prompts in
                self?.activePrompts = prompts
            }
            .store(in: &cancellables)
        
        promptEngine.$isEngineRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRunning in
                self?.isEngineRunning = isRunning
            }
            .store(in: &cancellables)
        
        promptEngine.$lastEngineUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.lastEngineUpdate = update
            }
            .store(in: &cancellables)
        
        promptEngine.$promptPerformance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] performances in
                self?.performances = performances
            }
            .store(in: &cancellables)
        
        // Start update timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateExecutionLogs()
        }
    }
    
    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func toggleEngine() {
        if isEngineRunning {
            promptEngine.stopEngine()
        } else {
            promptEngine.startEngine()
        }
    }
    
    func togglePrompt(_ promptId: String) {
        if let prompt = activePrompts.first(where: { $0.id == promptId }) {
            if prompt.isActive {
                promptEngine.deactivatePrompt(promptId)
            } else {
                promptEngine.activatePrompt(promptId)
            }
        }
    }
    
    func deletePrompt(_ promptId: String) {
        promptEngine.deletePrompt(promptId)
    }
    
    func updatePrompt(_ prompt: TradingPrompt) {
        // Update prompt in engine
        if let index = activePrompts.firstIndex(where: { $0.id == prompt.id }) {
            activePrompts[index] = prompt
        }
    }
    
    func getPerformance(for promptId: String) -> PromptPerformance? {
        return performances[promptId]
    }
    
    func getExecutionLog(for promptId: String) -> [ExecutionLogEntry] {
        return executionLogs[promptId] ?? []
    }
    
    private func updateExecutionLogs() {
        // Simulate execution logs - in real app, this would come from the engine
        for prompt in activePrompts where prompt.isActive {
            if executionLogs[prompt.id] == nil {
                executionLogs[prompt.id] = []
            }
            
            // Add random execution entries for demo
            if Int.random(in: 0...10) > 8 {
                let entry = ExecutionLogEntry(
                    id: UUID().uuidString,
                    promptId: prompt.id,
                    timestamp: Date(),
                    action: ["Buy EURUSD", "Sell GBPUSD", "Close position", "Adjust stop loss"].randomElement()!,
                    success: Bool.random(),
                    details: "Executed based on strategy conditions"
                )
                executionLogs[prompt.id]?.insert(entry, at: 0)
                
                // Keep only last 20 entries
                if executionLogs[prompt.id]!.count > 20 {
                    executionLogs[prompt.id] = Array(executionLogs[prompt.id]!.prefix(20))
                }
            }
        }
    }
}

struct ExecutionLogEntry: Identifiable {
    let id: String
    let promptId: String
    let timestamp: Date
    let action: String
    let success: Bool
    let details: String
}

// MARK: - Prompt Edit View

struct PromptEditView: View {
    let prompt: TradingPrompt
    let onSave: (TradingPrompt) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var editedTitle: String
    @State private var editedPrompt: String
    
    init(prompt: TradingPrompt, onSave: @escaping (TradingPrompt) -> Void) {
        self.prompt = prompt
        self.onSave = onSave
        _editedTitle = State(initialValue: prompt.title)
        _editedPrompt = State(initialValue: prompt.prompt)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Strategy Name") {
                    TextField("Title", text: $editedTitle)
                }
                
                Section("Strategy Description") {
                    TextEditor(text: $editedPrompt)
                        .frame(minHeight: 200)
                }
                
                Section("Quick Actions") {
                    Button("Analyze with AI") {
                        // Analyze prompt
                    }
                    
                    Button("Test Strategy") {
                        // Run backtest
                    }
                }
            }
            .navigationTitle("Edit Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedPrompt = prompt
                        updatedPrompt.title = editedTitle
                        updatedPrompt.prompt = editedPrompt
                        onSave(updatedPrompt)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}