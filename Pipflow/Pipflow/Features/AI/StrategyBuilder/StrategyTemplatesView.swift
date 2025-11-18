//
//  StrategyTemplatesView.swift
//  Pipflow
//
//  Pre-built strategy templates
//

import SwiftUI

struct StrategyTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory = TemplateStrategyCategory.all
    @State private var searchText = ""
    let onSelect: (StrategyBuilderTemplate) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                    
                    TextField("Search templates", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Color.Theme.text)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.Theme.text.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.Theme.cardBackground)
                .cornerRadius(10)
                .padding()
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TemplateStrategyCategory.allCases, id: \.self) { category in
                            StrategyTemplateCategoryChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // Templates List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTemplates) { template in
                            TemplateCard(template: template) {
                                onSelect(template)
                                dismiss()
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
    }
    
    private var filteredTemplates: [StrategyBuilderTemplate] {
        StrategyBuilderTemplate.allTemplates
            .filter { template in
                (selectedCategory == .all || template.category == selectedCategory) &&
                (searchText.isEmpty ||
                 template.name.localizedCaseInsensitiveContains(searchText) ||
                 template.description.localizedCaseInsensitiveContains(searchText))
            }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: StrategyBuilderTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundColor(template.category.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(Color.Theme.text)
                        
                        Text(template.category.rawValue)
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Difficulty Badge
                    DifficultyBadge(difficulty: template.difficulty)
                }
                
                // Description
                Text(template.description)
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.secondaryText)
                    .lineLimit(3)
                
                // Key Features
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Features")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                        .textCase(.uppercase)
                    
                    ForEach(template.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.Theme.success)
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(Color.Theme.text)
                            
                            Spacer()
                        }
                    }
                }
                
                // Performance Preview
                HStack(spacing: 20) {
                    PerformanceMetric(
                        label: "Win Rate",
                        value: "\(template.expectedWinRate)%",
                        color: template.expectedWinRate >= 50 ? Color.Theme.success : Color.Theme.warning
                    )
                    
                    PerformanceMetric(
                        label: "Avg Return",
                        value: String(format: "%.1f%%", template.expectedReturn),
                        color: template.expectedReturn >= 0 ? Color.Theme.success : Color.Theme.error
                    )
                    
                    PerformanceMetric(
                        label: "Risk Level",
                        value: template.riskLevel.rawValue,
                        color: template.riskLevel.colorTheme
                    )
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color.Theme.cardBackground)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

struct StrategyTemplateCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : Color.Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.Theme.accent : Color.Theme.cardBackground
                )
                .cornerRadius(20)
        }
    }
}

struct DifficultyBadge: View {
    let difficulty: StrategyDifficulty
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(difficulty.color)
            .cornerRadius(8)
    }
}

struct PerformanceMetric: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.Theme.secondaryText)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Models

enum TemplateStrategyCategory: String, CaseIterable {
    case all = "All"
    case trending = "Trending"
    case rangebound = "Range-Bound"
    case scalping = "Scalping"
    case swing = "Swing Trading"
    case dayTrading = "Day Trading"
    case algorithmic = "Algorithmic"
    
    var color: Color {
        switch self {
        case .all: return Color.Theme.text
        case .trending: return Color.blue
        case .rangebound: return Color.orange
        case .scalping: return Color.purple
        case .swing: return Color.green
        case .dayTrading: return Color.yellow
        case .algorithmic: return Color.pink
        }
    }
}

enum StrategyDifficulty: String {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: Color {
        switch self {
        case .beginner: return Color.Theme.success
        case .intermediate: return Color.Theme.warning
        case .advanced: return Color.Theme.error
        }
    }
}

// Using StrategyRiskLevel from Strategy.swift
extension StrategyRiskLevel {
    var colorTheme: Color {
        switch self {
        case .low: return Color.Theme.success
        case .medium: return Color.Theme.warning
        case .high: return Color.Theme.error
        }
    }
}

struct StrategyBuilderTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: TemplateStrategyCategory
    let difficulty: StrategyDifficulty
    let icon: String
    let features: [String]
    let expectedWinRate: Int
    let expectedReturn: Double
    let riskLevel: StrategyRiskLevel
    let components: [ComponentType]
    
    static let allTemplates: [StrategyBuilderTemplate] = [
        // Trending Strategies
        StrategyBuilderTemplate(
            name: "Moving Average Crossover",
            description: "Classic trend-following strategy using fast and slow moving averages to identify trend changes.",
            category: .trending,
            difficulty: .beginner,
            icon: "chart.line.uptrend.xyaxis",
            features: [
                "Simple to understand and implement",
                "Works well in trending markets",
                "Clear entry and exit signals"
            ],
            expectedWinRate: 55,
            expectedReturn: 15.5,
            riskLevel: .low,
            components: [.indicator, .stopLoss, .takeProfit, .positionSize]
        ),
        
        StrategyBuilderTemplate(
            name: "Trend Rider Pro",
            description: "Advanced trend-following system with multiple confirmations and dynamic position sizing.",
            category: .trending,
            difficulty: .advanced,
            icon: "arrow.up.right.circle",
            features: [
                "Multiple timeframe analysis",
                "Dynamic position sizing",
                "Adaptive stop loss"
            ],
            expectedWinRate: 65,
            expectedReturn: 28.3,
            riskLevel: .medium,
            components: [.indicator, .priceAction, .pattern, .trailing, .positionSize, .maxDrawdown]
        ),
        
        // Range-Bound Strategies
        StrategyBuilderTemplate(
            name: "RSI Reversal",
            description: "Mean reversion strategy using RSI oversold/overbought levels to trade range-bound markets.",
            category: .rangebound,
            difficulty: .beginner,
            icon: "arrow.left.arrow.right",
            features: [
                "High win rate in sideways markets",
                "Clear oversold/overbought signals",
                "Limited risk per trade"
            ],
            expectedWinRate: 68,
            expectedReturn: 12.8,
            riskLevel: .low,
            components: [.indicator, .stopLoss, .takeProfit, .positionSize]
        ),
        
        StrategyBuilderTemplate(
            name: "Bollinger Band Bounce",
            description: "Trade price bounces from Bollinger Band extremes with volume confirmation.",
            category: .rangebound,
            difficulty: .intermediate,
            icon: "arrow.up.and.down",
            features: [
                "Visual entry points",
                "Volume confirmation",
                "Adaptive bands"
            ],
            expectedWinRate: 62,
            expectedReturn: 18.5,
            riskLevel: .medium,
            components: [.indicator, .priceAction, .stopLoss, .takeProfit, .positionSize]
        ),
        
        // Scalping Strategies
        StrategyBuilderTemplate(
            name: "1-Minute Scalper",
            description: "High-frequency scalping strategy for quick profits on small price movements.",
            category: .scalping,
            difficulty: .advanced,
            icon: "bolt.circle",
            features: [
                "Quick in-and-out trades",
                "Tight stop losses",
                "High trade frequency"
            ],
            expectedWinRate: 72,
            expectedReturn: 8.5,
            riskLevel: .high,
            components: [.priceAction, .indicator, .stopLoss, .takeProfit, .time, .maxPositions]
        ),
        
        // Swing Trading
        StrategyBuilderTemplate(
            name: "Swing Momentum",
            description: "Multi-day swing trading strategy capturing medium-term price movements.",
            category: .swing,
            difficulty: .intermediate,
            icon: "chart.xyaxis.line",
            features: [
                "Hold positions for days",
                "Lower time commitment",
                "Larger profit targets"
            ],
            expectedWinRate: 58,
            expectedReturn: 22.7,
            riskLevel: .medium,
            components: [.pattern, .indicator, .priceAction, .trailing, .positionSize]
        ),
        
        // Day Trading
        StrategyBuilderTemplate(
            name: "Opening Range Breakout",
            description: "Trade breakouts from the first hour's trading range with volume confirmation.",
            category: .dayTrading,
            difficulty: .intermediate,
            icon: "sunrise",
            features: [
                "Clear entry timing",
                "Volume confirmation",
                "Day trade only"
            ],
            expectedWinRate: 60,
            expectedReturn: 19.2,
            riskLevel: .medium,
            components: [.time, .priceAction, .stopLoss, .takeProfit, .timeExit]
        ),
        
        // Algorithmic
        StrategyBuilderTemplate(
            name: "AI Pattern Recognition",
            description: "Machine learning-based pattern recognition for automated trading decisions.",
            category: .algorithmic,
            difficulty: .advanced,
            icon: "cpu",
            features: [
                "AI-powered decisions",
                "Self-learning system",
                "Multi-pattern analysis"
            ],
            expectedWinRate: 70,
            expectedReturn: 35.8,
            riskLevel: .high,
            components: [.pattern, .indicator, .priceAction, .news, .trailing, .positionSize, .maxDrawdown, .maxPositions]
        ),
        
        StrategyBuilderTemplate(
            name: "Grid Trading Bot",
            description: "Automated grid trading system for ranging markets with fixed intervals.",
            category: .algorithmic,
            difficulty: .intermediate,
            icon: "square.grid.3x3",
            features: [
                "Automated execution",
                "Profits from volatility",
                "No directional bias"
            ],
            expectedWinRate: 45,
            expectedReturn: 15.3,
            riskLevel: .medium,
            components: [.priceAction, .positionSize, .maxPositions, .maxDrawdown]
        )
    ]
}

#Preview {
    StrategyTemplatesView { template in
        print("Selected template: \(template.name)")
    }
}