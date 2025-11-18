//
//  PromptModels.swift
//  Pipflow
//
//  Common models for AI Prompt Trading
//

import Foundation
import SwiftUI

// MARK: - PromptTemplate
struct PromptTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let prompt: String
    let category: PromptCategory
    let icon: String
    let tags: [String]
    let author: String
    let performance: StrategyPerformanceData?
}

// MARK: - PromptCategory
enum PromptCategory: String, CaseIterable {
    case general = "General"
    case scalping = "Scalping"
    case dayTrading = "Day Trading"
    case swingTrading = "Swing Trading"
    case riskManagement = "Risk Management"
    case technical = "Technical Analysis"
    case fundamental = "Fundamental"
    
    var displayName: String { rawValue }
}

// MARK: - TemplateCategory (for the templates view)
enum TemplateCategory: String, CaseIterable {
    case all = "All"
    case trending = "Trending"
    case forex = "Forex"
    case crypto = "Crypto"
    case commodities = "Commodities"
    case technical = "Technical"
    case fundamental = "Fundamental"
    case aiDriven = "AI-Driven"
    
    var displayName: String {
        switch self {
        case .all: return "All Templates"
        case .trending: return "🔥 Trending"
        case .forex: return "💱 Forex"
        case .crypto: return "₿ Crypto"
        case .commodities: return "🏅 Commodities"
        case .technical: return "📊 Technical"
        case .fundamental: return "📈 Fundamental"
        case .aiDriven: return "🤖 AI-Driven"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .trending: return "flame.fill"
        case .forex: return "dollarsign.circle"
        case .crypto: return "bitcoinsign.circle"
        case .commodities: return "cube.fill"
        case .technical: return "chart.line.uptrend.xyaxis"
        case .fundamental: return "doc.text.magnifyingglass"
        case .aiDriven: return "brain"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return Color.blue
        case .trending: return Color.orange
        case .forex: return Color.green
        case .crypto: return Color.yellow
        case .commodities: return Color.purple
        case .technical: return Color.cyan
        case .fundamental: return Color.indigo
        case .aiDriven: return Color.pink
        }
    }
}

// MARK: - DetailedPromptTemplate
struct DetailedPromptTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let prompt: String
    let category: TemplateCategory
    let promptCategory: PromptCategory
    let icon: String
    let riskLevel: TemplateRiskLevel
    let averageWinRate: Double
    let averageReturn: Double
    let usageCount: Int
    let createdDate: Date
    let tags: [String]
    let keyFeatures: [String]
    let suitableFor: [String]
    let requirements: [String]
    let isPopular: Bool
    let author: String
    let performance: StrategyPerformanceData?
    let minimumCapital: Double?
    let rating: Double?
    let reviews: [TemplateReview]?
    
    func toPromptTemplate() -> PromptTemplate {
        PromptTemplate(
            name: name,
            description: description,
            prompt: prompt,
            category: promptCategory,
            icon: icon,
            tags: tags,
            author: author,
            performance: performance
        )
    }
}

// MARK: - TemplateRiskLevel
enum TemplateRiskLevel {
    case low, medium, high
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
}

// MARK: - TemplateReview
struct TemplateReview: Identifiable {
    let id = UUID()
    let userId: String
    let userName: String
    let rating: Int
    let comment: String
    let date: Date
    let profitMade: Double?
}

// MARK: - SortOption
enum SortOption: String, CaseIterable {
    case popularity = "Most Popular"
    case performance = "Best Performance"
    case newest = "Newest"
    case rating = "Highest Rated"
    
    var displayName: String { rawValue }
}

// MARK: - PromptExamples
struct PromptExamples {
    static func forCategory(_ category: PromptCategory) -> [String] {
        switch category {
        case .general:
            return [
                "Buy EUR/USD when RSI is below 30 and price is above 200 EMA",
                "Trade gold breakouts during London session with 2% risk",
                "Scalp major pairs when volume spikes above average"
            ]
        case .scalping:
            return [
                "Scalp EUR/USD on 1-minute chart with 5 pip targets",
                "Trade momentum bursts in GBPUSD during news releases",
                "Quick trades on XAUUSD using Bollinger Band touches"
            ]
        case .dayTrading:
            return [
                "Trade daily pivots on major forex pairs",
                "Buy support and sell resistance on 4H timeframe",
                "Trend follow BTCUSD with trailing stops"
            ]
        case .swingTrading:
            return [
                "Hold positions for 3-5 days based on weekly trends",
                "Trade major reversals at key Fibonacci levels",
                "Position trade using monthly support/resistance"
            ]
        case .riskManagement:
            return [
                "Never risk more than 1% per trade with automatic position sizing",
                "Use correlation analysis to avoid overexposure",
                "Scale out of winning positions at multiple targets"
            ]
        case .technical:
            return [
                "Trade MACD crossovers with RSI confirmation",
                "Enter on bullish engulfing patterns at support",
                "Use Ichimoku cloud for trend direction"
            ]
        case .fundamental:
            return [
                "Trade NFP releases with predetermined risk",
                "Position based on central bank policy divergence",
                "Trade earnings surprises in equity indices"
            ]
        }
    }
}