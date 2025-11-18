//
//  PromptBuilderView.swift
//  Pipflow
//
//  AI Prompt Builder for personalized trading strategies
//

import SwiftUI

struct PromptBuilderView: View {
    var body: some View {
        NaturalLanguageStrategyView()
    }
}

struct ModernPromptBuilderView: View {
    @StateObject private var promptEngine = PromptTradingEngine.shared
    @State private var promptText: String = ""
    @State private var promptTitle: String = ""
    @State private var selectedRiskLevel: RiskLevel = .moderate
    @State private var maxPositions: Int = 3
    @State private var isAnalyzing = false
    @State private var showValidationError = false
    @State private var validationMessage = ""
    @State private var showTemplates = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Quick Templates
                    templatesSection
                    
                    // Prompt Input
                    promptInputSection
                    
                    // Settings
                    settingsSection
                    
                    // Preview
                    if !promptText.isEmpty {
                        previewSection
                    }
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .background(Color(hex: "0A0A0F"))
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showTemplates) {
            PromptTemplatesView { template in
                promptTitle = template.name
                promptText = template.prompt
                showTemplates = false
            }
        }
        .alert("Validation Error", isPresented: $showValidationError) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
    }
    
    // MARK: - Section Views
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                
                Spacer()
                
                Text("AI Strategy Builder")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Placeholder for balance
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.top, 10)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "BD00FF"))
                        .background(
                            Circle()
                                .fill(Color(hex: "BD00FF").opacity(0.15))
                                .frame(width: 80, height: 80)
                        )
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Your Strategy")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Tell me how you want to trade in plain English")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.7))
                }
            }
        }
    }
    
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Templates")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showTemplates = true }) {
                    Text("View All")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0080FF"))
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickTemplates) { template in
                        ModernTemplateCard(template: template) {
                            promptTitle = template.name
                            promptText = template.prompt
                        }
                    }
                }
            }
        }
    }
    
    private var promptInputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Strategy Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
                
                TextField("EUR/USD Momentum Strategy", text: $promptTitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            
            // Natural Language Prompt
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Describe Your Strategy")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("AI-Powered")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "BD00FF"))
                }
                
                ZStack(alignment: .topLeading) {
                    if promptText.isEmpty {
                        Text("Example: Buy EUR/USD when RSI crosses below 30 and price touches the lower Bollinger Band. Set stop loss at 50 pips and take profit at 100 pips. Risk 2% per trade with maximum 3 open positions.")
                            .font(.system(size: 16))
                            .foregroundColor(Color.white.opacity(0.3))
                            .padding(16)
                    }
                    
                    TextEditor(text: $promptText)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .frame(minHeight: 180)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "BD00FF").opacity(0.2), lineWidth: 1)
                )
                
                // AI Helper
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "00FF88"))
                    
                    Text("I'll convert your natural language into a trading strategy with entry/exit rules, risk management, and automated execution")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.5))
                        .lineLimit(2)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "00FF88").opacity(0.1))
                )
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quick Settings")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            // Risk Level
            VStack(alignment: .leading, spacing: 12) {
                Text("Risk Preference")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.6))
                
                HStack(spacing: 8) {
                    riskLevelButton(.conservative)
                    riskLevelButton(.moderate)
                    riskLevelButton(.aggressive)
                }
            }
            
            // Max Positions
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Maximum Open Positions")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("\(maxPositions)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "0080FF"))
                }
                
                Slider(value: Binding(
                    get: { Double(maxPositions) },
                    set: { maxPositions = Int($0) }
                ), in: 1...10, step: 1)
                .accentColor(Color(hex: "0080FF"))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private func getRiskIcon(for level: RiskLevel) -> String {
        switch level {
        case .conservative: return "shield.fill"
        case .moderate: return "gauge.medium"
        case .aggressive: return "flame.fill"
        }
    }
    
    private func getRiskLabel(for level: RiskLevel) -> String {
        switch level {
        case .conservative: return "Conservative"
        case .moderate: return "Moderate"
        case .aggressive: return "Aggressive"
        }
    }
    
    private func getRiskColor(for level: RiskLevel) -> Color {
        switch level {
        case .conservative: return Color(hex: "00FF88")
        case .moderate: return Color(hex: "0080FF")
        case .aggressive: return Color(hex: "FF3B30")
        }
    }
    
    @ViewBuilder
    private func riskLevelButton(_ level: RiskLevel) -> some View {
        Button(action: { selectedRiskLevel = level }) {
            VStack(spacing: 8) {
                Image(systemName: getRiskIcon(for: level))
                    .font(.system(size: 24))
                    .foregroundColor(selectedRiskLevel == level ? .white : Color.white.opacity(0.5))
                
                Text(getRiskLabel(for: level))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(selectedRiskLevel == level ? .white : Color.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedRiskLevel == level ? getRiskColor(for: level).opacity(0.2) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedRiskLevel == level ? getRiskColor(for: level) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Features")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "BD00FF"))
            }
            
            VStack(spacing: 12) {
                AIFeatureRow(
                    icon: "doc.text.fill",
                    title: "MQL5 Code Generation",
                    subtitle: "Convert to Expert Advisor",
                    color: Color(hex: "0080FF")
                )
                
                AIFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Automatic Backtesting",
                    subtitle: "Test on historical data",
                    color: Color(hex: "00FF88")
                )
                
                AIFeatureRow(
                    icon: "shield.checkmark",
                    title: "Risk Validation",
                    subtitle: "AI safety checks",
                    color: Color(hex: "FF9500")
                )
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Generate Strategy Button
            Button(action: generateStrategy) {
                HStack(spacing: 12) {
                    if isAnalyzing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "brain")
                            .font(.system(size: 18))
                    }
                    
                    Text(isAnalyzing ? "AI is thinking..." : "Generate Strategy")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "BD00FF"), Color(hex: "0080FF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color(hex: "BD00FF").opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(promptText.isEmpty || isAnalyzing)
            
            HStack(spacing: 12) {
                // Test Strategy
                Button(action: testStrategy) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                        Text("Backtest")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "00FF88"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "00FF88").opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "00FF88"), lineWidth: 1)
                            )
                    )
                }
                .disabled(promptText.isEmpty)
                
                // Save Draft
                Button(action: saveDraft) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16))
                        Text("Save Draft")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(Color.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(.top, 20)
    }
    
    private func generateStrategy() {
        isAnalyzing = true
        
        Task {
            // Simulate AI processing
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            let result = await promptEngine.createPrompt(
                userId: "user-\(UUID().uuidString)",
                title: promptTitle.isEmpty ? "AI Strategy" : promptTitle,
                promptText: promptText
            )
            
            await MainActor.run {
                switch result {
                case .success:
                    // Show success and navigate to strategy details
                    dismiss()
                case .failure(let error):
                    validationMessage = error.localizedDescription
                    showValidationError = true
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func saveDraft() {
        // Save strategy draft
        print("Saving draft: \(promptTitle)")
    }
    
    // MARK: - Actions
    
    private func saveStrategy() {
        isAnalyzing = true
        
        Task {
            let result = await promptEngine.createPrompt(
                userId: "user-\(UUID().uuidString)",
                title: promptTitle.isEmpty ? "My Strategy" : promptTitle,
                promptText: promptText
            )
            
            await MainActor.run {
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    validationMessage = error.localizedDescription
                    showValidationError = true
                    isAnalyzing = false
                }
            }
        }
    }
    
    private func testStrategy() {
        // TODO: Implement strategy testing
        print("Testing strategy: \(promptText)")
    }
}

// MARK: - Supporting Views

struct ModernTemplateCard: View {
    let template: PromptTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: template.icon)
                        .font(.system(size: 20))
                        .foregroundColor(getIconColor(for: template.category))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.3))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(template.description)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.6))
                        .lineLimit(2)
                }
            }
            .frame(width: 160)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getIconColor(for category: PromptCategory) -> Color {
        switch category {
        case .general: return Color(hex: "0080FF")
        case .technical: return Color(hex: "BD00FF")
        case .scalping: return Color(hex: "00FF88")
        case .fundamental: return Color(hex: "FF9500")
        case .riskManagement: return Color(hex: "FF3B30")
        case .dayTrading: return Color(hex: "00D4FF")
        case .swingTrading: return Color(hex: "FF00FF")
        }
    }
}

struct PromptTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.Theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.Theme.accent.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Quick Templates

private let quickTemplates: [PromptTemplate] = [
    PromptTemplate(
        name: "Conservative",
        description: "Low risk, steady gains",
        prompt: "Trade major forex pairs with 1% risk per trade. Enter when RSI < 30 for buy or RSI > 70 for sell.",
        category: .general,
        icon: "shield.checkerboard",
        tags: ["low-risk", "forex"],
        author: "System",
        performance: nil
    ),
    PromptTemplate(
        name: "Trend Follower",
        description: "Ride market momentum",
        prompt: "Follow strong trends using 20/50 EMA crossover. Risk 2% per trade with trailing stops.",
        category: .technical,
        icon: "chart.line.uptrend.xyaxis",
        tags: ["trend", "momentum"],
        author: "System",
        performance: nil
    ),
    PromptTemplate(
        name: "Scalper",
        description: "Quick intraday trades",
        prompt: "Scalp 5-minute charts during high volume. Target 10 pips with 5 pip stop loss.",
        category: .scalping,
        icon: "bolt.circle",
        tags: ["scalping", "intraday"],
        author: "System",
        performance: nil
    )
]

// MARK: - AI Feature Row

struct AIFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "00FF88"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Professional Prompt Builder (kept for reference)

struct ProfessionalPromptBuilderView: View {
    @StateObject private var promptEngine = PromptTradingEngine.shared
    @StateObject private var backtestEngine = BacktestingEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    // Basic Info
    @State private var strategyName = ""
    @State private var selectedCategory: PromptStrategyCategory = .trend
    
    // Market Selection
    @State private var selectedMarkets: Set<String> = []
    @State private var selectedTimeframes: Set<String> = []
    
    // Entry Conditions
    @State private var entryConditions: [PromptConditionItem] = []
    @State private var exitConditions: [PromptConditionItem] = []
    
    // Risk Management
    @State private var riskPerTrade: Double = 1.0
    @State private var stopLossType: StopLossType = .fixed
    @State private var stopLossValue: Double = 50
    @State private var takeProfitRatio: Double = 2.0
    @State private var useTrailingStop = false
    @State private var maxPositions: Int = 3
    
    // Advanced Settings
    @State private var showAdvanced = false
    @State private var maxDrawdown: Double = 10.0
    @State private var dailyLossLimit: Double = 5.0
    @State private var correlationCheck = true
    
    // UI State
    @State private var currentStep = 0
    @State private var isValidating = false
    @State private var showPreview = false
    @State private var validationResults: PromptBuilderValidationResult?
    @State private var showError = false
    @State private var errorMessage = ""
    
    let steps = ["Strategy Type", "Markets & Time", "Entry Rules", "Exit Rules", "Risk Management", "Review"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0A0A0F")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Bar
                    progressBar
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // Step Content
                    TabView(selection: $currentStep) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            ScrollView {
                                stepContent(for: index)
                                    .padding()
                                    .padding(.bottom, 100)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Navigation Buttons
                    navigationButtons
                        .padding()
                        .background(
                            Color(hex: "1C1C1E")
                                .ignoresSafeArea()
                        )
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showPreview) {
            StrategyPreviewView(
                strategy: buildStrategy(),
                validationResults: validationResults
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Build Trading Strategy")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
            
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index <= currentStep ? Color(hex: "0080FF") : Color.white.opacity(0.2))
                            .frame(height: 4)
                        
                        if index == currentStep {
                            Text(steps[index])
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "0080FF"))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private func stepContent(for step: Int) -> some View {
        switch step {
        case 0:
            strategyTypeStep
        case 1:
            marketSelectionStep
        case 2:
            entryRulesStep
        case 3:
            exitRulesStep
        case 4:
            riskManagementStep
        case 5:
            reviewStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Step 1: Strategy Type
    private var strategyTypeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy Name")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                TextField("e.g., EUR/USD Momentum Strategy", text: $strategyName)
                    .textFieldStyle(ProfessionalTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy Category")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Select the type that best describes your approach")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                ForEach(PromptStrategyCategory.allCases, id: \.self) { category in
                    StrategyTypeCard(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
        }
    }
    
    // Continue with rest of the implementation...
    
    // MARK: - Step 2: Market Selection
    private var marketSelectionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Market Selection Step")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
    
    private var entryRulesStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Entry Rules Step")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
    
    private var exitRulesStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Exit Rules Step")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
    
    private var riskManagementStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Risk Management Step")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
    
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Review Step")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep > 0 {
                Button(action: { currentStep -= 1 }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
            
            Button(action: handleNext) {
                HStack {
                    if isValidating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(currentStep == steps.count - 1 ? "Create Strategy" : "Next")
                        if currentStep < steps.count - 1 {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(nextButtonColor)
                )
            }
            .disabled(!canProceed || isValidating)
        }
    }
    
    // MARK: - Helper Properties
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !strategyName.isEmpty
        case 1:
            return !selectedMarkets.isEmpty && !selectedTimeframes.isEmpty
        case 2:
            return !entryConditions.isEmpty
        case 3:
            return true // Exit conditions are optional
        case 4:
            return true
        case 5:
            return validationResults?.isValid ?? false
        default:
            return true
        }
    }
    
    private var nextButtonColor: Color {
        canProceed ? Color(hex: "0080FF") : Color.white.opacity(0.2)
    }
    
    private var riskColor: Color {
        if riskPerTrade <= 1 {
            return Color(hex: "00FF88")
        } else if riskPerTrade <= 2 {
            return Color(hex: "FF9500")
        } else {
            return Color(hex: "FF3B30")
        }
    }
    
    // MARK: - Actions
    private func handleNext() {
        if currentStep == steps.count - 1 {
            createStrategy()
        } else if currentStep == steps.count - 2 {
            validateStrategy()
        } else {
            currentStep += 1
        }
    }
    
    private func validateStrategy() {
        isValidating = true
        
        Task {
            // Simulate validation
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                validationResults = PromptBuilderValidationResult(
                    isValid: true,
                    warnings: [
                        "Consider adding more exit conditions for better risk management",
                        "Backtesting recommended for selected timeframes"
                    ],
                    suggestions: [
                        "Add a time-based exit for positions held too long",
                        "Consider correlation check for multiple positions"
                    ]
                )
                isValidating = false
                currentStep += 1
            }
        }
    }
    
    private func createStrategy() {
        let strategy = buildStrategy()
        
        Task {
            let result = await promptEngine.createPrompt(
                userId: "user-\(UUID().uuidString)",
                title: strategy.name,
                promptText: strategy.toPromptText()
            )
            
            await MainActor.run {
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func buildStrategy() -> PromptBuilderStrategy {
        PromptBuilderStrategy(
            name: strategyName.isEmpty ? "Unnamed Strategy" : strategyName,
            category: selectedCategory,
            markets: Array(selectedMarkets),
            timeframes: Array(selectedTimeframes),
            entryConditions: entryConditions,
            exitConditions: exitConditions,
            riskPerTrade: riskPerTrade,
            stopLossType: stopLossType,
            stopLossValue: stopLossValue,
            takeProfitRatio: takeProfitRatio,
            useTrailingStop: useTrailingStop,
            maxPositions: maxPositions,
            maxDrawdown: maxDrawdown,
            dailyLossLimit: dailyLossLimit,
            correlationCheck: correlationCheck
        )
    }
}

// MARK: - Supporting Types

enum PromptStrategyCategory: String, CaseIterable {
    case trend = "Trend Following"
    case reversal = "Mean Reversion"
    case breakout = "Breakout"
    case scalping = "Scalping"
    case swing = "Swing Trading"
    case arbitrage = "Arbitrage"
    
    var icon: String {
        switch self {
        case .trend: return "chart.line.uptrend.xyaxis"
        case .reversal: return "arrow.left.arrow.right"
        case .breakout: return "bolt.fill"
        case .scalping: return "speedometer"
        case .swing: return "chart.xyaxis.line"
        case .arbitrage: return "arrow.triangle.2.circlepath"
        }
    }
    
    var description: String {
        switch self {
        case .trend: return "Follow market momentum and ride trends"
        case .reversal: return "Trade price reversals at extremes"
        case .breakout: return "Enter on price breakouts from ranges"
        case .scalping: return "Quick trades on small price movements"
        case .swing: return "Hold positions for days to weeks"
        case .arbitrage: return "Exploit price differences across markets"
        }
    }
}

enum StopLossType {
    case fixed, atr, percentage
    
    var label: String {
        switch self {
        case .fixed: return "Fixed Stop"
        case .atr: return "ATR Multiplier"
        case .percentage: return "Percentage"
        }
    }
    
    var unit: String {
        switch self {
        case .fixed: return "pips"
        case .atr: return "x ATR"
        case .percentage: return "%"
        }
    }
}

struct PromptConditionItem: Identifiable {
    let id = UUID()
    var indicator = "RSI"
    var comparison = ComparisonType.lessThan
    var value: Double = 30
    var note = ""
}

enum ComparisonType {
    case lessThan, greaterThan, equals, crossAbove, crossBelow
    
    var symbol: String {
        switch self {
        case .lessThan: return "<"
        case .greaterThan: return ">"
        case .equals: return "="
        case .crossAbove: return "↗"
        case .crossBelow: return "↘"
        }
    }
}

struct PromptBuilderValidationResult {
    let isValid: Bool
    let warnings: [String]
    let suggestions: [String]
}

struct PromptBuilderStrategy {
    let name: String
    let category: PromptStrategyCategory
    let markets: [String]
    let timeframes: [String]
    let entryConditions: [PromptConditionItem]
    let exitConditions: [PromptConditionItem]
    let riskPerTrade: Double
    let stopLossType: StopLossType
    let stopLossValue: Double
    let takeProfitRatio: Double
    let useTrailingStop: Bool
    let maxPositions: Int
    let maxDrawdown: Double
    let dailyLossLimit: Double
    let correlationCheck: Bool
    
    func toPromptText() -> String {
        var prompt = "Trade \(markets.joined(separator: ", ")) on \(timeframes.joined(separator: ", ")) timeframes. "
        
        // Entry conditions
        if !entryConditions.isEmpty {
            prompt += "Enter when "
            prompt += entryConditions.map { "\($0.indicator) \($0.comparison.symbol) \($0.value)" }.joined(separator: " AND ")
            prompt += ". "
        }
        
        // Exit conditions
        if !exitConditions.isEmpty {
            prompt += "Exit when "
            prompt += exitConditions.map { "\($0.indicator) \($0.comparison.symbol) \($0.value)" }.joined(separator: " OR ")
            prompt += ". "
        }
        
        // Risk management
        prompt += "Risk \(String(format: "%.1f", riskPerTrade))% per trade with "
        prompt += "\(String(format: "%.0f", stopLossValue)) \(stopLossType.unit) stop loss. "
        prompt += "Take profit at 1:\(String(format: "%.1f", takeProfitRatio)) risk/reward. "
        
        if useTrailingStop {
            prompt += "Use trailing stop. "
        }
        
        prompt += "Maximum \(maxPositions) positions. "
        prompt += "Stop trading if drawdown exceeds \(String(format: "%.0f", maxDrawdown))% or daily loss exceeds \(String(format: "%.0f", dailyLossLimit))%."
        
        return prompt
    }
}

// MARK: - Supporting Views

struct ProfessionalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct StrategyTypeCard: View {
    let category: PromptStrategyCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isSelected ? .white : Color.white.opacity(0.8))
                    
                    Text(category.description)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "0080FF"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "0080FF").opacity(0.15) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: "0080FF") : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StrategyPreviewView: View {
    let strategy: PromptBuilderStrategy
    let validationResults: PromptBuilderValidationResult?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Strategy summary...
                    Text("Strategy Preview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .background(Color(hex: "0A0A0F"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PromptBuilderView()
}