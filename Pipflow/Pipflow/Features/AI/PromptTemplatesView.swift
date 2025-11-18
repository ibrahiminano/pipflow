//
//  PromptTemplatesView.swift
//  Pipflow
//
//  Pre-built trading strategy templates for quick setup
//

import SwiftUI

struct PromptTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: TemplateCategory = .all
    @State private var searchText = ""
    @State private var selectedTemplate: DetailedPromptTemplate?
    @State private var showingTemplateDetail = false
    @State private var sortOption: SortOption = .popularity
    
    let onTemplateSelected: (PromptTemplate) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Header
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                        
                        TextField("Search templates...", text: $searchText)
                            .foregroundColor(Color.Theme.text)
                    }
                    .padding()
                    .background(Color.Theme.cardBackground)
                    .cornerRadius(12)
                    
                    // Category Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TemplateCategory.allCases, id: \.self) { category in
                                TemplateCategoryChip(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                    }
                    
                    // Sort Options
                    HStack {
                        Text("Sort by:")
                            .font(.caption)
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                        
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(Color.Theme.accent)
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color.Theme.background)
                
                // Templates Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredTemplates, id: \.id) { template in
                            PromptTemplateCard(template: template) {
                                selectedTemplate = template
                                showingTemplateDetail = true
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color.Theme.background)
            .navigationTitle("Strategy Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTemplateDetail) {
            if let template = selectedTemplate {
                TemplateDetailView(template: template) { template in
                    onTemplateSelected(template.toPromptTemplate())
                    dismiss()
                }
            }
        }
    }
    
    private var filteredTemplates: [DetailedPromptTemplate] {
        var templates = DetailedPromptTemplate.allTemplates
        
        // Filter by category
        if selectedCategory != .all {
            templates = templates.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort templates
        switch sortOption {
        case .popularity:
            templates.sort { $0.usageCount > $1.usageCount }
        case .newest:
            templates.sort { $0.createdDate > $1.createdDate }
        case .performance:
            templates.sort { $0.averageWinRate > $1.averageWinRate }
        case .rating:
            templates.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        }
        
        return templates
    }
}

// MARK: - Template Card

struct PromptTemplateCard: View {
    let template: DetailedPromptTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundColor(template.category.color)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        RiskBadge(level: template.riskLevel)
                        
                        if template.isPopular {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.caption2)
                                Text("Popular")
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(Color.Theme.text)
                        .lineLimit(2)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.7))
                        .lineLimit(3)
                }
                
                // Stats
                HStack(spacing: 16) {
                    PromptStatItem(
                        icon: "chart.line.uptrend.xyaxis",
                        value: String(format: "%.0f%%", template.averageWinRate * 100),
                        label: "Win Rate"
                    )
                    
                    PromptStatItem(
                        icon: "person.2",
                        value: formatCount(template.usageCount),
                        label: "Users"
                    )
                }
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(template.tags.prefix(3), id: \.self) { tag in
                            TagView(tag: tag)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.Theme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.Theme.accent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - Template Detail View

struct TemplateDetailView: View {
    let template: DetailedPromptTemplate
    let onUseTemplate: (DetailedPromptTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingFullPrompt = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    performanceSection
                    strategySection
                    promptSection
                    suitableForSection
                    requirementsSection
                    tagsSection
                    actionButton
                }
                .padding()
            }
            .background(Color.Theme.background)
            .navigationTitle("Template Details")
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
    
    // MARK: - Section Views
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: template.icon)
                    .font(.largeTitle)
                    .foregroundColor(template.category.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.Theme.text)
                    
                    Text(template.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(template.category.color)
                }
                
                Spacer()
            }
            
            Text(template.description)
                .font(.body)
                .foregroundColor(Color.Theme.text.opacity(0.8))
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Statistics")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                TemplatePerformanceStatCard(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", template.averageWinRate * 100),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                TemplatePerformanceStatCard(
                    title: "Avg. Return",
                    value: String(format: "%.1f%%", template.averageReturn * 100),
                    icon: "dollarsign.circle",
                    color: .blue
                )
                
                TemplatePerformanceStatCard(
                    title: "Risk Level",
                    value: template.riskLevel.displayName,
                    icon: "exclamationmark.triangle",
                    color: template.riskLevel.color
                )
                
                TemplatePerformanceStatCard(
                    title: "Users",
                    value: "\(template.usageCount)",
                    icon: "person.2",
                    color: .purple
                )
            }
        }
    }
    
    private var strategySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Strategy Details")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            ForEach(template.keyFeatures, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.Theme.success)
                    
                    Text(feature)
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.text)
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trading Prompt")
                    .font(.headline)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
                
                Button(action: { showingFullPrompt.toggle() }) {
                    Text(showingFullPrompt ? "Show Less" : "Show Full")
                        .font(.caption)
                        .foregroundColor(Color.Theme.accent)
                }
            }
            
            Text(showingFullPrompt ? template.prompt : String(template.prompt.prefix(150)) + "...")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color.Theme.text.opacity(0.8))
                .padding()
                .background(Color.Theme.background)
                .cornerRadius(8)
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var suitableForSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suitable For")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            ForEach(template.suitableFor, id: \.self) { item in
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .foregroundColor(Color.Theme.accent)
                    
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.text.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var requirementsSection: some View {
        if !template.requirements.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Requirements")
                    .font(.headline)
                    .foregroundColor(Color.Theme.text)
                
                ForEach(template.requirements, id: \.self) { requirement in
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color.orange)
                        
                        Text(requirement)
                            .font(.subheadline)
                            .foregroundColor(Color.Theme.text.opacity(0.8))
                    }
                }
            }
            .padding()
            .background(Color.Theme.cardBackground)
            .cornerRadius(16)
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            TemplateFlowContainer(spacing: 8) {
                ForEach(template.tags, id: \.self) { tag in
                    TagView(tag: tag)
                }
            }
        }
    }
    
    private var actionButton: some View {
        Button(action: { onUseTemplate(template) }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Use This Template")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .padding(.top)
    }
}

// MARK: - Supporting Views

struct TemplateCategoryChip: View {
    let category: TemplateCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : Color.Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? category.color : Color.Theme.cardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(category.color.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct RiskBadge: View {
    let level: TemplateRiskLevel
    
    var body: some View {
        Text(level.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(level.color)
            .cornerRadius(6)
    }
}

struct PromptStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.Theme.accent)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.Theme.text)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
        }
    }
}

struct TagView: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .foregroundColor(Color.Theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.Theme.accent.opacity(0.1))
            .cornerRadius(6)
    }
}

struct TemplatePerformanceStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.Theme.text)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.text.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
    }
}

struct TemplateFlowContainer: View {
    let spacing: CGFloat
    let content: () -> any View
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> any View) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        // Simplified flow layout - in production, use a proper flow layout
        HStack(spacing: spacing) {
            AnyView(content())
            Spacer()
        }
    }
}

// MARK: - Data Models


// MARK: - Template Data

extension DetailedPromptTemplate {
    static let allTemplates: [DetailedPromptTemplate] = []
    
    static let mockTemplates: [DetailedPromptTemplate] = [
        /*
        // Conservative Templates
        DetailedPromptTemplate(
            name: "Safe Forex Trader",
            description: "Low-risk strategy focusing on major currency pairs",
            prompt: "Trade only EUR/USD, GBP/USD, and USD/JPY. Risk 1% per trade with stop loss at 1.5%. Enter long when RSI is below 30 and price is above 50-period moving average. Enter short when RSI is above 70 and price is below 50-period moving average. Take profit at 1:2 risk-reward ratio. Maximum 3 trades open at once.",
            category: .forex,
            promptCategory: .general,
            icon: "shield.checkerboard",
            riskLevel: .low,
            averageWinRate: 0.68,
            averageReturn: 0.045,
            usageCount: 2547,
            createdDate: Date().addingTimeInterval(-30*24*60*60),
            tags: ["forex", "low-risk", "RSI", "moving-average", "beginner-friendly"],
            keyFeatures: [
                "Trades only major currency pairs",
                "1% risk per trade maximum",
                "Clear entry and exit rules",
                "Maximum 3 concurrent positions",
                "Uses popular technical indicators"
            ],
            suitableFor: [
                "Beginners in forex trading",
                "Risk-averse traders",
                "Part-time traders",
                "Small account sizes"
            ],
            requirements: [
                "Minimum $500 capital recommended",
                "Basic understanding of RSI and MA",
                "Access to major forex pairs"
            ],
            isPopular: true
        ),
        
        DetailedPromptTemplate(
            name: "Gold Scalper Pro",
            description: "Quick profits from gold price movements",
            detailedDescription: "High-frequency scalping strategy designed for gold (XAUUSD) during high volatility periods. Requires focus and quick execution.",
            fullPrompt: "Scalp XAUUSD during London and New York sessions only. Use 5-minute chart. Enter long when price breaks above previous 15-minute high with volume spike. Enter short when price breaks below previous 15-minute low with volume spike. Use 0.5% stop loss and 0.75% take profit. Maximum position size 2% of capital. Exit all positions before major news events.",
            category: .scalping,
            icon: "bolt.circle",
            riskLevel: .high,
            averageWinRate: 0.72,
            averageReturn: 0.082,
            usageCount: 1823,
            createdDate: Date().addingTimeInterval(-15*24*60*60),
            tags: ["gold", "scalping", "intraday", "high-frequency", "breakout"],
            keyFeatures: [
                "Focuses on gold volatility",
                "Quick in-and-out trades",
                "Session-based trading",
                "Volume confirmation required",
                "Tight stop losses"
            ],
            suitableFor: [
                "Experienced scalpers",
                "Full-time traders",
                "Those who can monitor charts",
                "Traders seeking quick profits"
            ],
            requirements: [
                "Fast execution broker",
                "Stable internet connection",
                "Ability to monitor 5-minute charts",
                "Understanding of breakout patterns"
            ],
            isPopular: true
        ),
        
        DetailedPromptTemplate(
            name: "Trend Follower",
            description: "Ride strong market trends with patience",
            detailedDescription: "This strategy identifies and follows strong market trends using multiple timeframe analysis. Suitable for patient traders.",
            fullPrompt: "Trade major forex pairs and gold. Identify trend on daily chart using 20 and 50 EMA crossover. Enter trades on 4-hour chart pullbacks to 20 EMA. Risk 2% per trade. Use trailing stop loss at 2x ATR. Take partial profits at 1:3 risk-reward and let the rest run with trailing stop. Maximum 5 positions open. Only trade in direction of daily trend.",
            category: .swingTrading,
            icon: "chart.line.uptrend.xyaxis",
            riskLevel: .medium,
            averageWinRate: 0.58,
            averageReturn: 0.125,
            usageCount: 3156,
            createdDate: Date().addingTimeInterval(-45*24*60*60),
            tags: ["trend-following", "swing-trading", "multi-timeframe", "EMA", "ATR"],
            keyFeatures: [
                "Multiple timeframe analysis",
                "Trend-following approach",
                "Trailing stop loss",
                "Partial profit taking",
                "Clear trend identification"
            ],
            suitableFor: [
                "Patient traders",
                "Medium-term investors",
                "Those who can't monitor constantly",
                "Trend traders"
            ],
            requirements: [
                "Understanding of trend analysis",
                "Patience to wait for setups",
                "Ability to hold positions for days",
                "Multi-timeframe chart access"
            ],
            isPopular: false
        ),
        
        DetailedPromptTemplate(
            name: "News Fade Strategy",
            description: "Trade against initial news reactions",
            detailedDescription: "This contrarian strategy fades extreme price movements after major news releases, capitalizing on overreactions.",
            fullPrompt: "Monitor major news events for EUR/USD, GBP/USD, and USD/JPY. Wait 15 minutes after high-impact news release. If price moved more than 50 pips in one direction, enter counter-trend trade. Use 30-pip stop loss and 60-pip take profit. Risk 1.5% per trade. Only trade if RSI shows extreme overbought (>80) or oversold (<20) condition. Exit immediately if momentum continues against position.",
            category: .news,
            icon: "newspaper",
            riskLevel: .high,
            averageWinRate: 0.65,
            averageReturn: 0.098,
            usageCount: 987,
            createdDate: Date().addingTimeInterval(-20*24*60*60),
            tags: ["news-trading", "fade", "contrarian", "high-impact", "RSI"],
            keyFeatures: [
                "Trades news overreactions",
                "Contrarian approach",
                "Fixed pip targets",
                "RSI confirmation required",
                "Quick decision making"
            ],
            suitableFor: [
                "News traders",
                "Contrarian traders",
                "Those available during news",
                "Risk-tolerant traders"
            ],
            requirements: [
                "Economic calendar access",
                "Fast news feed",
                "Quick execution capability",
                "Understanding of news impact"
            ],
            isPopular: false
        ),
        
        DetailedPromptTemplate(
            name: "Asian Session Ranger",
            description: "Trade range-bound markets during Asian hours",
            detailedDescription: "Specialized strategy for trading during the typically quieter Asian session when markets often range.",
            fullPrompt: "Trade EUR/USD and GBP/USD during Asian session (00:00-09:00 GMT). Identify range high and low from previous 4 hours. Enter short at range high with RSI>65, enter long at range low with RSI<35. Use stop loss 10 pips beyond range. Take profit at opposite range boundary. Risk 1% per trade. Skip if range is greater than 40 pips. Exit all trades before London open.",
            category: .dayTrading,
            icon: "moon.stars",
            riskLevel: .low,
            averageWinRate: 0.74,
            averageReturn: 0.056,
            usageCount: 1456,
            createdDate: Date().addingTimeInterval(-60*24*60*60),
            tags: ["asian-session", "range-trading", "session-specific", "low-volatility"],
            keyFeatures: [
                "Session-specific strategy",
                "Range-bound trading",
                "Clear entry/exit levels",
                "Low volatility environment",
                "Time-based exits"
            ],
            suitableFor: [
                "Asian timezone traders",
                "Night owls in Western timezones",
                "Range traders",
                "Conservative traders"
            ],
            requirements: [
                "Ability to trade during Asian hours",
                "Understanding of range trading",
                "Discipline to skip wide ranges"
            ],
            isPopular: false
        ),
        
        DetailedPromptTemplate(
            name: "Momentum Breakout",
            description: "Catch strong moves as they begin",
            detailedDescription: "This strategy identifies and trades momentum breakouts with volume confirmation for high-probability setups.",
            fullPrompt: "Trade all major forex pairs and gold. On 1-hour chart, mark previous day's high and low. Enter long when price breaks above with 2x average volume. Enter short when price breaks below with 2x average volume. Confirm with MACD histogram turning positive/negative. Risk 1.5% with stop at breakout level. Trail stop at 1.5x ATR. Target 1:3 minimum risk-reward.",
            category: .technical,
            icon: "speedometer",
            riskLevel: .medium,
            averageWinRate: 0.61,
            averageReturn: 0.115,
            usageCount: 2890,
            createdDate: Date().addingTimeInterval(-25*24*60*60),
            tags: ["breakout", "momentum", "volume", "MACD", "technical"],
            keyFeatures: [
                "Volume-confirmed breakouts",
                "Multiple instrument trading",
                "MACD confirmation",
                "Trailing stop loss",
                "High reward targets"
            ],
            suitableFor: [
                "Technical traders",
                "Breakout specialists",
                "Medium-risk tolerance",
                "Active traders"
            ],
            requirements: [
                "Volume indicator access",
                "Understanding of breakout patterns",
                "Ability to set trailing stops"
            ],
            isPopular: true
        )
        */
    ]
}

#Preview {
    PromptTemplatesView { template in
        print("Selected template: \(template.name)")
    }
}