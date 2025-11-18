//
//  NaturalLanguageStrategyView.swift
//  Pipflow
//
//  Enhanced AI Prompt Builder with all features
//

import SwiftUI
import PhotosUI

struct NaturalLanguageStrategyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = EnhancedPromptBuilderViewModel()
    
    @State private var selectedTab = 0
    @State private var showImagePicker = false
    @State private var selectedImages: [UIImage] = []
    @State private var uploadedImages: [UIImage] = []
    @State private var showAdvancedSettings = false
    @State private var isExecuting = false
    @State private var showVoiceInput = false
    @State private var showCodePreview = false
    @State private var generatedCode = ""
    
    var body: some View {
        let _ = print("🚀🚀🚀 NaturalLanguageStrategyView: ENHANCED VERSION WITH TABS LOADED! 🚀🚀🚀")
        let _ = print("Tab count: \(tabs.count)")
        let _ = print("Selected tab: \(selectedTab)")
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Tab Bar
                customTabBar
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Natural Language Tab
                    naturalLanguageTab
                        .tag(0)
                    
                    // Visual Builder Tab
                    visualBuilderTab
                        .tag(1)
                    
                    // Templates Tab
                    templatesTab
                        .tag(2)
                    
                    // Context Tab
                    contextTab
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom Action Bar
                actionBar
            }
        }
        .navigationTitle("AI Strategy Builder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { showVoiceInput.toggle() }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                    
                    Button(action: { showAdvancedSettings.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $uploadedImages)
        }
        .sheet(isPresented: $showAdvancedSettings) {
            AdvancedSettingsView(viewModel: viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showVoiceInput) {
            NavigationView {
                VoiceStrategyInput(promptText: $viewModel.promptText)
                    .environmentObject(themeManager)
                    .navigationTitle("Voice Input")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showVoiceInput = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showCodePreview) {
            VStack {
                Text("Generated Code")
                    .font(.headline)
                    .padding()
                ScrollView {
                    Text(generatedCode)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                Button("Close") {
                    showCodePreview = false
                }
                .padding()
            }
            .environmentObject(themeManager)
        }
    }
    
    // MARK: - Custom Tab Bar
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: { 
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].1)
                            .font(.system(size: 20))
                        Text(tabs[index].0)
                            .font(.caption2)
                    }
                    .foregroundColor(selectedTab == index ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == index ?
                        themeManager.currentTheme.accentColor.opacity(0.1) : Color.clear
                    )
                }
            }
        }
        .background(themeManager.currentTheme.secondaryBackgroundColor)
    }
    
    let tabs = [
        ("Natural Language", "text.bubble.fill"),
        ("Visual Builder", "square.grid.3x3.fill"),
        ("Templates", "doc.text.fill"),
        ("Context", "slider.horizontal.3")
    ]
    
    let templates = [
        PromptTemplate(
            name: "Scalping Strategy",
            description: "Quick trades on 1-5 minute timeframes",
            prompt: "Execute scalping trades on major pairs during high liquidity sessions. Enter when price breaks above/below the 20 EMA with momentum confirmation. Use tight 5-10 pip stops.",
            category: .scalping,
            icon: "gauge.high",
            tags: ["Scalping", "Short-term", "High Frequency"],
            author: "System",
            performance: nil
        ),
        PromptTemplate(
            name: "Trend Following",
            description: "Ride strong market trends",
            prompt: "Follow the trend using multiple timeframe analysis. Enter long when 50 EMA > 200 EMA and price pulls back to 50 EMA. Risk 2% per trade with 1:3 risk/reward.",
            category: .dayTrading,
            icon: "chart.line.uptrend.xyaxis",
            tags: ["Trend", "Medium-term", "EMA"],
            author: "System",
            performance: nil
        ),
        PromptTemplate(
            name: "Support/Resistance",
            description: "Trade key price levels",
            prompt: "Identify major support and resistance levels on daily chart. Buy at support with bullish confirmation, sell at resistance with bearish confirmation. Use ATR-based stops.",
            category: .technical,
            icon: "chart.bar.xaxis",
            tags: ["Price Action", "Support", "Resistance"],
            author: "System",
            performance: nil
        )
    ]
    
    // MARK: - Natural Language Tab
    
    private var naturalLanguageTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Prompt Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Describe Your Strategy")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Use natural language to describe your trading strategy. Be specific about conditions, indicators, and risk management.")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    // Enhanced Text Editor
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $viewModel.promptText)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(themeManager.currentTheme.secondaryBackgroundColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 2)
                            )
                        
                        if viewModel.promptText.isEmpty {
                            Text("Example: \"Buy EURUSD when RSI is below 30 and price touches the lower Bollinger Band. Set stop loss at 20 pips and take profit at 40 pips. Only trade during London session.\"")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
                    
                    // Quick Insert Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.quickInserts, id: \.self) { insert in
                                Button(action: { viewModel.promptText += " \(insert) " }) {
                                    Text(insert)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(themeManager.currentTheme.accentColor.opacity(0.1))
                                        .foregroundColor(themeManager.currentTheme.accentColor)
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
                .cornerRadius(16)
                
                // Image Context Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Visual Context")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Spacer()
                        
                        Button(action: { showImagePicker = true }) {
                            Label("Add Chart", systemImage: "photo.badge.plus")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                    }
                    
                    if !uploadedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(uploadedImages.enumerated()), id: \.offset) { index, image in
                                    ImageContextCard(
                                        image: image,
                                        index: index,
                                        theme: themeManager.currentTheme,
                                        onDelete: {
                                            uploadedImages.remove(at: index)
                                            viewModel.removeImageContext(at: index)
                                        }
                                    )
                                }
                            }
                        }
                    } else {
                        Text("Add chart screenshots or technical analysis images to provide visual context")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(themeManager.currentTheme.separatorColor)
                            )
                    }
                }
                .padding()
                .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
                .cornerRadius(16)
                
                // AI Suggestions
                if !viewModel.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Suggestions")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                                    .font(.system(size: 12))
                                
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                Spacer()
                                
                                Button(action: { viewModel.promptText += "\n\(suggestion)" }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(themeManager.currentTheme.accentColor)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(12)
                            .background(themeManager.currentTheme.accentColor.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
                    .cornerRadius(16)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Visual Builder Tab
    
    private var visualBuilderTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Entry Conditions
                ConditionBuilderSection(
                    title: "Entry Conditions",
                    conditions: $viewModel.entryConditions,
                    theme: themeManager.currentTheme
                )
                
                // Exit Conditions
                ConditionBuilderSection(
                    title: "Exit Conditions",
                    conditions: $viewModel.exitConditions,
                    theme: themeManager.currentTheme
                )
                
                // Risk Management
                RiskManagementSection(
                    viewModel: viewModel,
                    theme: themeManager.currentTheme
                )
                
                // Time Filters
                TimeFilterSection(
                    viewModel: viewModel,
                    theme: themeManager.currentTheme
                )
            }
            .padding()
        }
    }
    
    // MARK: - Templates Tab
    
    private var templatesTab: some View {
        VStack(spacing: 16) {
            // Header
            Text("Strategy Templates")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
            
            // Templates List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(templates) { template in
                        Button(action: {
                            viewModel.applyTemplate(template)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.headline)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                    
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    
                                    Text(template.prompt)
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                        .lineLimit(2)
                                        .padding(.top, 4)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            .padding()
                            .background(themeManager.currentTheme.secondaryBackgroundColor)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    // MARK: - Context Tab
    
    private var contextTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Trading Context")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Account Settings Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Settings")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Starting Capital")
                                .foregroundColor(themeManager.currentTheme.textColor)
                            Spacer()
                            Text(String(format: "$%.0f", viewModel.context.capital))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        HStack {
                            Text("Risk per Trade")
                                .foregroundColor(themeManager.currentTheme.textColor)
                            Spacer()
                            Text(String(format: "%.1f%%", viewModel.context.riskPerTrade * 100))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        Slider(
                            value: .init(
                                get: { viewModel.context.riskPerTrade },
                                set: { viewModel.updateRiskPerTrade($0) }
                            ),
                            in: 0.005...0.05,
                            step: 0.005
                        )
                        .accentColor(themeManager.currentTheme.accentColor)
                        
                        HStack {
                            Text("Max Open Trades")
                                .foregroundColor(themeManager.currentTheme.textColor)
                            Spacer()
                            Text("\(viewModel.context.maxOpenTrades)")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        Stepper(
                            "",
                            value: .init(
                                get: { viewModel.context.maxOpenTrades },
                                set: { viewModel.updateMaxOpenTrades($0) }
                            ),
                            in: 1...10
                        )
                        .labelsHidden()
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Trading Pairs Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Trading Pairs")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Select the currency pairs you want to trade")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    VStack {
                        ForEach(["EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCAD", "NZDUSD"], id: \.self) { pair in
                            HStack {
                                Text(pair)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                Spacer()
                                Image(systemName: viewModel.context.allowedSymbols.contains(pair) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.context.allowedSymbols.contains(pair) ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryTextColor)
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                var symbols = viewModel.context.allowedSymbols
                                if symbols.contains(pair) {
                                    symbols.removeAll { $0 == pair }
                                } else {
                                    symbols.append(pair)
                                }
                                viewModel.updateAllowedSymbols(symbols)
                            }
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Advanced Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Advanced Settings")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    VStack(spacing: 12) {
                        Toggle("Exclude News Events", isOn: .init(
                            get: { viewModel.context.timeRestrictions?.excludeNewsEvents ?? false },
                            set: { viewModel.updateExcludeNews($0) }
                        ))
                        .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Toggle("Exclude Market Open/Close", isOn: .init(
                            get: { viewModel.context.timeRestrictions?.excludeMarketOpen ?? false },
                            set: { viewModel.updateExcludeMarketOpenClose($0) }
                        ))
                        .foregroundColor(themeManager.currentTheme.textColor)
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    // MARK: - Action Bar
    
    private var actionBar: some View {
        VStack(spacing: 12) {
            // Validation Status
            if let validation = viewModel.validationResult {
                HStack {
                    Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(validation.isValid ? .green : .orange)
                    
                    Text(validation.isValid ? "Strategy is valid" : validation.errors.first ?? "Invalid strategy")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: savePrompt) {
                    Label("Save Strategy", systemImage: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(12)
                }
                
                Button(action: executePrompt) {
                    HStack {
                        if isExecuting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                            Text("Execute Now")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isExecuting || viewModel.validationResult?.isValid != true)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    // MARK: - Actions
    
    private func savePrompt() {
        Task {
            await viewModel.savePrompt()
            dismiss()
        }
    }
    
    private func executePrompt() {
        isExecuting = true
        Task {
            await viewModel.executePrompt()
            isExecuting = false
            if let code = viewModel.generatedCode {
                generatedCode = code
                showCodePreview = true
            }
        }
    }
}

// MARK: - Supporting Views






#Preview {
    NaturalLanguageStrategyView()
        .environmentObject(ThemeManager())
}