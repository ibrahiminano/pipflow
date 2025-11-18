//
//  EnhancedPromptBuilderView.swift
//  Pipflow
//
//  Enhanced AI Prompt Builder with Image Support and Advanced Context
//

import SwiftUI

struct EnhancedPromptBuilderView: View {
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
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Tab Bar
                    PromptBuilderTabBar(selectedTab: $selectedTab, theme: themeManager.currentTheme)
                    
                    // Tab Content
                    TabView(selection: $selectedTab) {
                        // Natural Language Tab
                        NaturalLanguageTab(
                            viewModel: viewModel,
                            uploadedImages: $uploadedImages,
                            showImagePicker: $showImagePicker,
                            theme: themeManager.currentTheme
                        )
                        .tag(0)
                        
                        // Visual Builder Tab
                        VisualBuilderTab(
                            viewModel: viewModel,
                            theme: themeManager.currentTheme
                        )
                        .tag(1)
                        
                        // Templates Tab
                        SimplifiedTemplatesTab(
                            viewModel: viewModel,
                            theme: themeManager.currentTheme
                        )
                        .tag(2)
                        
                        // Context Tab
                        SimplifiedContextTab(
                            viewModel: viewModel,
                            theme: themeManager.currentTheme
                        )
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Bottom Action Bar
                    PromptActionBar(
                        viewModel: viewModel,
                        isExecuting: $isExecuting,
                        showAdvancedSettings: $showAdvancedSettings,
                        theme: themeManager.currentTheme,
                        onSave: savePrompt,
                        onExecute: executePrompt
                    )
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
        }
        .sheet(isPresented: $showImagePicker) {
            if #available(iOS 14.0, *) {
                MultiImagePicker(images: $uploadedImages, maxSelection: 5)
            } else {
                ImagePicker(images: $uploadedImages)
            }
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
    }
    
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
        }
    }
}

// MARK: - Tab Bar

struct PromptBuilderTabBar: View {
    @Binding var selectedTab: Int
    let theme: Theme
    
    let tabs = [
        ("Natural Language", "text.bubble.fill"),
        ("Visual Builder", "square.grid.3x3.fill"),
        ("Templates", "doc.text.fill"),
        ("Context", "slider.horizontal.3")
    ]
    
    var body: some View {
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
                    .foregroundColor(selectedTab == index ? theme.accentColor : theme.secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == index ?
                        theme.accentColor.opacity(0.1) : Color.clear
                    )
                }
            }
        }
        .background(theme.secondaryBackgroundColor)
    }
}

// MARK: - Natural Language Tab

struct NaturalLanguageTab: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    @Binding var uploadedImages: [UIImage]
    @Binding var showImagePicker: Bool
    let theme: Theme
    
    @State private var promptText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Prompt Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Describe Your Strategy")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text("Use natural language to describe your trading strategy. Be specific about conditions, indicators, and risk management.")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    // Enhanced Text Editor
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $promptText)
                            .focused($isTextFieldFocused)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(theme.secondaryBackgroundColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.accentColor.opacity(isTextFieldFocused ? 1 : 0.3), lineWidth: 2)
                            )
                        
                        if promptText.isEmpty {
                            Text("Example: \"Buy EURUSD when RSI is below 30 and price touches the lower Bollinger Band. Set stop loss at 20 pips and take profit at 40 pips. Only trade during London session.\"")
                                .font(.system(size: 14))
                                .foregroundColor(theme.secondaryTextColor.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
                    
                    // Quick Insert Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.quickInserts, id: \.self) { insert in
                                Button(action: { promptText += " \(insert) " }) {
                                    Text(insert)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(theme.accentColor.opacity(0.1))
                                        .foregroundColor(theme.accentColor)
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(theme.secondaryBackgroundColor.opacity(0.5))
                .cornerRadius(16)
                
                // Image Context Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Visual Context")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        Spacer()
                        
                        Button(action: { showImagePicker = true }) {
                            Label("Add Chart", systemImage: "photo.badge.plus")
                                .font(.caption)
                                .foregroundColor(theme.accentColor)
                        }
                    }
                    
                    if !uploadedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(uploadedImages.enumerated()), id: \.offset) { index, image in
                                    ImageContextCard(
                                        image: image,
                                        index: index,
                                        theme: theme,
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
                            .foregroundColor(theme.secondaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(theme.separatorColor)
                            )
                    }
                }
                .padding()
                .background(theme.secondaryBackgroundColor.opacity(0.5))
                .cornerRadius(16)
                
                // AI Suggestions
                if !viewModel.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Suggestions")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(theme.accentColor)
                                    .font(.system(size: 12))
                                
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundColor(theme.textColor)
                                
                                Spacer()
                                
                                Button(action: { promptText += "\n\(suggestion)" }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(theme.accentColor)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(12)
                            .background(theme.accentColor.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(theme.secondaryBackgroundColor.opacity(0.5))
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .onChange(of: promptText) { _, newValue in
            viewModel.updatePromptText(newValue)
        }
        .onAppear {
            promptText = viewModel.promptText
        }
    }
}

// MARK: - Image Context Card

struct ImageContextCard: View {
    let image: UIImage
    let index: Int
    let theme: Theme
    let onDelete: () -> Void
    
    @State private var showAnalysis = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 100)
                    .clipped()
                    .cornerRadius(8)
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(4)
            }
            
            Button(action: { showAnalysis.toggle() }) {
                Text(showAnalysis ? "Hide Analysis" : "Analyze")
                    .font(.caption2)
                    .foregroundColor(theme.accentColor)
            }
            
            if showAnalysis {
                Text("Pattern detected: Head and shoulders")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryTextColor)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Action Bar

struct PromptActionBar: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    @Binding var isExecuting: Bool
    @Binding var showAdvancedSettings: Bool
    let theme: Theme
    let onSave: () -> Void
    let onExecute: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Validation Status
            if let validation = viewModel.validationResult {
                HStack {
                    Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(validation.isValid ? .green : .orange)
                    
                    Text(validation.isValid ? "Strategy is valid" : validation.errors.first ?? "Invalid strategy")
                        .font(.caption)
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onSave) {
                    Label("Save Strategy", systemImage: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.secondaryBackgroundColor)
                        .cornerRadius(12)
                }
                
                Button(action: onExecute) {
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
                            gradient: Gradient(colors: [theme.accentColor, theme.accentColor.opacity(0.8)]),
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
        .background(theme.backgroundColor)
    }
}

// MARK: - Visual Builder Tab

struct VisualBuilderTab: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    let theme: Theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Entry Conditions
                ConditionBuilderSection(
                    title: "Entry Conditions",
                    conditions: $viewModel.entryConditions,
                    theme: theme
                )
                
                // Exit Conditions
                ConditionBuilderSection(
                    title: "Exit Conditions",
                    conditions: $viewModel.exitConditions,
                    theme: theme
                )
                
                // Risk Management
                RiskManagementSection(
                    viewModel: viewModel,
                    theme: theme
                )
                
                // Time Filters
                TimeFilterSection(
                    viewModel: viewModel,
                    theme: theme
                )
            }
            .padding()
        }
    }
}

// MARK: - Templates Tab

struct TemplatesTab: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    let theme: Theme
    
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
        ),
        PromptTemplate(
            name: "News Trading",
            description: "Trade around economic events",
            prompt: "Monitor high-impact news events. Place pending orders 15 pips above/below current price 2 minutes before news. Use 10 pip stop loss and 30 pip take profit.",
            category: .fundamental,
            icon: "newspaper",
            tags: ["News", "Events", "High Impact"],
            author: "System",
            performance: nil
        )
    ]
    
    @State private var selectedCategory = "All"
    @State private var searchText = ""
    
    var filteredTemplates: [PromptTemplate] {
        templates.filter { template in
            (selectedCategory == "All" || template.category.rawValue == selectedCategory) &&
            (searchText.isEmpty || template.name.localizedCaseInsensitiveContains(searchText) ||
             template.description.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.secondaryTextColor)
                
                TextField("Search templates...", text: $searchText)
                    .foregroundColor(theme.textColor)
            }
            .padding(12)
            .background(theme.secondaryBackgroundColor)
            .cornerRadius(10)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(["All", "Scalping", "Trend", "Price Action", "News"], id: \.self) { category in
                        PromptCategoryChip(
                            title: category,
                            isSelected: selectedCategory == category,
                            theme: theme,
                            action: { selectedCategory = category }
                        )
                    }
                }
            }
            
            // Templates List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTemplates) { template in
                        EnhancedPromptTemplateCard(
                            template: template,
                            theme: theme,
                            onSelect: {
                                viewModel.applyTemplate(template)
                            }
                        )
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Context Builder Tab

struct ContextBuilderTab: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    let theme: Theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Account Settings
                ContextSection(title: "Account Settings", theme: theme) {
                    VStack(spacing: 16) {
                        ContextRow(
                            label: "Starting Capital",
                            value: String(format: "$%.0f", viewModel.context.capital),
                            theme: theme
                        )
                        
                        HStack {
                            Text("Risk per Trade")
                                .foregroundColor(theme.textColor)
                            Spacer()
                            Text(String(format: "%.1f%%", viewModel.context.riskPerTrade * 100))
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { viewModel.context.riskPerTrade },
                                set: { viewModel.updateRiskPerTrade($0) }
                            ),
                            in: 0.005...0.05,
                            step: 0.005
                        )
                        .accentColor(theme.accentColor)
                        
                        Stepper(
                            "Max Open Trades: \(viewModel.context.maxOpenTrades)",
                            value: Binding(
                                get: { viewModel.context.maxOpenTrades },
                                set: { viewModel.updateMaxOpenTrades($0) }
                            ),
                            in: 1...10
                        )
                        .foregroundColor(theme.textColor)
                    }
                }
                
                // Allowed Symbols
                ContextSection(title: "Trading Pairs", theme: theme) {
                    VStack(spacing: 12) {
                        SymbolSelector(
                            selectedSymbols: Binding(
                                get: { Set(viewModel.context.allowedSymbols) },
                                set: { viewModel.updateAllowedSymbols(Array($0)) }
                            ),
                            theme: theme
                        )
                    }
                }
                
                // Trading Hours
                ContextSection(title: "Trading Hours", theme: theme) {
                    TradingHoursSelector(
                        viewModel: viewModel,
                        theme: theme
                    )
                }
                
                // Advanced Filters
                ContextSection(title: "Advanced Filters", theme: theme) {
                    VStack(spacing: 16) {
                        Toggle("Exclude News Events", isOn: Binding(
                            get: { viewModel.context.timeRestrictions?.excludeNewsEvents ?? false },
                            set: { viewModel.updateExcludeNews($0) }
                        ))
                        .foregroundColor(theme.textColor)
                        
                        Toggle("Exclude Market Open/Close", isOn: Binding(
                            get: { viewModel.context.timeRestrictions?.excludeMarketOpen ?? false },
                            set: { viewModel.updateExcludeMarketOpenClose($0) }
                        ))
                        .foregroundColor(theme.textColor)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Types

// Types are defined in EnhancedPromptBuilderViewModel.swift to avoid duplication

struct PromptCategoryChip: View {
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

struct EnhancedPromptTemplateCard: View {
    let template: PromptTemplate
    let theme: Theme
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textColor)
                        
                        Text(template.description)
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(template.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                
                Text(template.prompt)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            .padding()
            .background(theme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
    }
}

struct ContextSection<Content: View>: View {
    let title: String
    let theme: Theme
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            content
                .padding()
                .background(theme.secondaryBackgroundColor)
                .cornerRadius(12)
        }
    }
}

struct ContextRow: View {
    let label: String
    let value: String
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(theme.textColor)
            Spacer()
            Text(value)
                .foregroundColor(theme.secondaryTextColor)
        }
    }
}

// MARK: - Preview

// MARK: - Simplified Tabs (Temporary)

struct SimplifiedTemplatesTab: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    let theme: Theme
    
    @State private var selectedCategory = "All"
    
    let templates = [
        PromptTemplate(
            name: "Scalping Strategy",
            description: "Quick trades on 1-5 minute timeframes",
            prompt: "Execute scalping trades on major pairs during high liquidity sessions.",
            category: .scalping,
            icon: "gauge.high",
            tags: ["Scalping"],
            author: "System",
            performance: nil
        ),
        PromptTemplate(
            name: "Trend Following",
            description: "Ride strong market trends",
            prompt: "Follow the trend using multiple timeframe analysis.",
            category: .dayTrading,
            icon: "chart.line.uptrend.xyaxis",
            tags: ["Trend"],
            author: "System",
            performance: nil
        )
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Strategy Templates")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.textColor)
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
                                        .foregroundColor(theme.textColor)
                                    
                                    Text(template.description)
                                        .font(.caption)
                                        .foregroundColor(theme.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            .padding()
                            .background(theme.secondaryBackgroundColor)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(theme.backgroundColor)
    }
}

struct SimplifiedContextTab: View {
    @ObservedObject var viewModel: EnhancedPromptBuilderViewModel
    let theme: Theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Trading Context")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Account Settings Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Settings")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Starting Capital")
                                .foregroundColor(theme.textColor)
                            Spacer()
                            Text(String(format: "$%.0f", viewModel.context.capital))
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        HStack {
                            Text("Risk per Trade")
                                .foregroundColor(theme.textColor)
                            Spacer()
                            Text(String(format: "%.1f%%", viewModel.context.riskPerTrade * 100))
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { viewModel.context.riskPerTrade },
                                set: { viewModel.updateRiskPerTrade($0) }
                            ),
                            in: 0.005...0.05,
                            step: 0.005
                        )
                        .accentColor(theme.accentColor)
                        
                        HStack {
                            Text("Max Open Trades")
                                .foregroundColor(theme.textColor)
                            Spacer()
                            Text("\(viewModel.context.maxOpenTrades)")
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        Stepper(
                            "",
                            value: Binding(
                                get: { viewModel.context.maxOpenTrades },
                                set: { viewModel.updateMaxOpenTrades($0) }
                            ),
                            in: 1...10
                        )
                        .labelsHidden()
                    }
                    .padding()
                    .background(theme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Trading Pairs Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Trading Pairs")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Text("Select the currency pairs you want to trade")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    
                    VStack {
                        ForEach(["EURUSD", "GBPUSD", "USDJPY", "AUDUSD"], id: \.self) { pair in
                            HStack {
                                Text(pair)
                                    .foregroundColor(theme.textColor)
                                Spacer()
                                Image(systemName: viewModel.context.allowedSymbols.contains(pair) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.context.allowedSymbols.contains(pair) ? theme.accentColor : theme.secondaryTextColor)
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
                    .background(theme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Advanced Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Advanced Settings")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    VStack(spacing: 12) {
                        Toggle("Exclude News Events", isOn: Binding(
                            get: { viewModel.context.timeRestrictions?.excludeNewsEvents ?? false },
                            set: { viewModel.updateExcludeNews($0) }
                        ))
                        .foregroundColor(theme.textColor)
                        
                        Toggle("Exclude Market Open/Close", isOn: Binding(
                            get: { viewModel.context.timeRestrictions?.excludeMarketOpen ?? false },
                            set: { viewModel.updateExcludeMarketOpenClose($0) }
                        ))
                        .foregroundColor(theme.textColor)
                    }
                    .padding()
                    .background(theme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(theme.backgroundColor)
    }
}

#Preview {
    EnhancedPromptBuilderView()
        .environmentObject(ThemeManager())
}