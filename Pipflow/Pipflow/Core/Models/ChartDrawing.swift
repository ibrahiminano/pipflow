//
//  ChartDrawing.swift
//  Pipflow
//
//  Models for AI-powered chart drawings
//

import Foundation
import SwiftUI

// MARK: - Drawing Types

enum ChartDrawingType: String, CaseIterable, Codable {
    case supportLine = "support_line"
    case resistanceLine = "resistance_line"
    case trendLine = "trend_line"
    case channel = "channel"
    case supplyZone = "supply_zone"
    case demandZone = "demand_zone"
    case fibonacciRetracement = "fibonacci"
    case pricePattern = "pattern"
    case keyLevel = "key_level"
    
    var displayName: String {
        switch self {
        case .supportLine: return "Support"
        case .resistanceLine: return "Resistance"
        case .trendLine: return "Trend Line"
        case .channel: return "Channel"
        case .supplyZone: return "Supply Zone"
        case .demandZone: return "Demand Zone"
        case .fibonacciRetracement: return "Fibonacci"
        case .pricePattern: return "Pattern"
        case .keyLevel: return "Key Level"
        }
    }
    
    var color: Color {
        switch self {
        case .supportLine: return .green
        case .resistanceLine: return .red
        case .trendLine: return .blue
        case .channel: return .purple
        case .supplyZone: return .red.opacity(0.3)
        case .demandZone: return .green.opacity(0.3)
        case .fibonacciRetracement: return .orange
        case .pricePattern: return .yellow
        case .keyLevel: return .cyan
        }
    }
}

// MARK: - Base Drawing Model

protocol ChartDrawing: Identifiable {
    var id: UUID { get }
    var type: ChartDrawingType { get }
    var startPoint: ChartPoint { get }
    var endPoint: ChartPoint { get }
    var confidence: Double { get } // AI confidence 0-1
    var description: String { get }
    var isVisible: Bool { get set }
    var style: DrawingStyle { get }
}

struct ChartPoint: Codable {
    let timestamp: Date
    let price: Double
    let barIndex: Int?
    
    // Convert to TradingView coordinates
    var tvCoordinate: String {
        let formatter = ISO8601DateFormatter()
        return "[\(formatter.string(from: timestamp)), \(price)]"
    }
}

struct DrawingStyle: Codable {
    let color: String
    let lineWidth: Double
    let lineStyle: LineStyle
    let opacity: Double
    
    enum LineStyle: String, Codable {
        case solid = "solid"
        case dashed = "dashed"
        case dotted = "dotted"
    }
}

// MARK: - Specific Drawing Types

struct SupportResistanceLine: ChartDrawing, Codable {
    let id: UUID
    let type: ChartDrawingType
    let startPoint: ChartPoint
    let endPoint: ChartPoint
    let confidence: Double
    let description: String
    var isVisible: Bool
    let style: DrawingStyle
    let strength: Int // 1-5 based on touches
    let touches: [ChartPoint]
    
    init(
        id: UUID = UUID(),
        type: ChartDrawingType,
        startPoint: ChartPoint,
        endPoint: ChartPoint,
        confidence: Double,
        description: String,
        isVisible: Bool = true,
        style: DrawingStyle,
        strength: Int,
        touches: [ChartPoint]
    ) {
        self.id = id
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.confidence = confidence
        self.description = description
        self.isVisible = isVisible
        self.style = style
        self.strength = strength
        self.touches = touches
    }
}

struct TrendLine: ChartDrawing, Codable {
    let id: UUID
    let type: ChartDrawingType
    let startPoint: ChartPoint
    let endPoint: ChartPoint
    let confidence: Double
    let description: String
    var isVisible: Bool
    let style: DrawingStyle
    let direction: TrendDirection
    let slope: Double
    let touches: [ChartPoint]
    
    enum TrendDirection: String, Codable {
        case bullish = "bullish"
        case bearish = "bearish"
        case neutral = "neutral"
    }
    
    init(
        id: UUID = UUID(),
        type: ChartDrawingType = .trendLine,
        startPoint: ChartPoint,
        endPoint: ChartPoint,
        confidence: Double,
        description: String,
        isVisible: Bool = true,
        style: DrawingStyle,
        direction: TrendDirection,
        slope: Double,
        touches: [ChartPoint]
    ) {
        self.id = id
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.confidence = confidence
        self.description = description
        self.isVisible = isVisible
        self.style = style
        self.direction = direction
        self.slope = slope
        self.touches = touches
    }
}

struct SupplyDemandZone: ChartDrawing, Codable {
    let id: UUID
    let type: ChartDrawingType
    let startPoint: ChartPoint
    let endPoint: ChartPoint
    let confidence: Double
    let description: String
    var isVisible: Bool
    let style: DrawingStyle
    let strength: ZoneStrength
    let volume: Double?
    let retests: Int
    
    enum ZoneStrength: String, Codable {
        case weak = "weak"
        case medium = "medium"
        case strong = "strong"
    }
    
    init(
        id: UUID = UUID(),
        type: ChartDrawingType,
        startPoint: ChartPoint,
        endPoint: ChartPoint,
        confidence: Double,
        description: String,
        isVisible: Bool = true,
        style: DrawingStyle,
        strength: ZoneStrength,
        volume: Double? = nil,
        retests: Int
    ) {
        self.id = id
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.confidence = confidence
        self.description = description
        self.isVisible = isVisible
        self.style = style
        self.strength = strength
        self.volume = volume
        self.retests = retests
    }
}

struct Channel: ChartDrawing, Codable {
    let id: UUID
    let type: ChartDrawingType
    let startPoint: ChartPoint
    let endPoint: ChartPoint
    let confidence: Double
    let description: String
    var isVisible: Bool
    let style: DrawingStyle
    let upperLine: TrendLine
    let lowerLine: TrendLine
    let width: Double
    
    init(
        id: UUID = UUID(),
        type: ChartDrawingType = .channel,
        startPoint: ChartPoint,
        endPoint: ChartPoint,
        confidence: Double,
        description: String,
        isVisible: Bool = true,
        style: DrawingStyle,
        upperLine: TrendLine,
        lowerLine: TrendLine,
        width: Double
    ) {
        self.id = id
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.confidence = confidence
        self.description = description
        self.isVisible = isVisible
        self.style = style
        self.upperLine = upperLine
        self.lowerLine = lowerLine
        self.width = width
    }
}

struct FibonacciRetracement: ChartDrawing, Codable {
    let id: UUID
    let type: ChartDrawingType
    let startPoint: ChartPoint
    let endPoint: ChartPoint
    let confidence: Double
    let description: String
    var isVisible: Bool
    let style: DrawingStyle
    let levels: [FibLevel]
    
    struct FibLevel: Codable {
        let level: Double // 0.236, 0.382, 0.5, 0.618, 0.786
        let price: Double
        let label: String
    }
    
    init(
        id: UUID = UUID(),
        type: ChartDrawingType = .fibonacciRetracement,
        startPoint: ChartPoint,
        endPoint: ChartPoint,
        confidence: Double,
        description: String,
        isVisible: Bool = true,
        style: DrawingStyle,
        levels: [FibLevel]
    ) {
        self.id = id
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.confidence = confidence
        self.description = description
        self.isVisible = isVisible
        self.style = style
        self.levels = levels
    }
}

struct PricePattern: ChartDrawing, Codable {
    let id: UUID
    let type: ChartDrawingType
    let startPoint: ChartPoint
    let endPoint: ChartPoint
    let confidence: Double
    let description: String
    var isVisible: Bool
    let style: DrawingStyle
    let patternType: PatternType
    let keyPoints: [ChartPoint]
    let target: Double?
    
    enum PatternType: String, Codable {
        case headAndShoulders = "head_and_shoulders"
        case doubleTop = "double_top"
        case doubleBottom = "double_bottom"
        case triangle = "triangle"
        case wedge = "wedge"
        case flag = "flag"
        case pennant = "pennant"
        case cup = "cup_and_handle"
    }
    
    init(
        id: UUID = UUID(),
        type: ChartDrawingType = .pricePattern,
        startPoint: ChartPoint,
        endPoint: ChartPoint,
        confidence: Double,
        description: String,
        isVisible: Bool = true,
        style: DrawingStyle,
        patternType: PatternType,
        keyPoints: [ChartPoint],
        target: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.confidence = confidence
        self.description = description
        self.isVisible = isVisible
        self.style = style
        self.patternType = patternType
        self.keyPoints = keyPoints
        self.target = target
    }
}

// MARK: - AI Analysis Request/Response

struct ChartAnalysisRequest: Codable {
    let symbol: String
    let timeframe: String
    let candles: [CandleData]
    let indicators: [String: [Double]]? // Optional indicators like RSI, MACD
    let analysisType: AnalysisType
    
    enum AnalysisType: String, Codable {
        case full = "full"
        case supportResistance = "support_resistance"
        case trendLines = "trend_lines"
        case supplyDemand = "supply_demand"
        case patterns = "patterns"
    }
    
    struct CandleData: Codable {
        let timestamp: Date
        let open: Double
        let high: Double
        let low: Double
        let close: Double
        let volume: Double
    }
}

struct ChartAnalysisResponse: Codable {
    let drawings: [DrawingData]
    let marketContext: MarketContext
    let tradingOpportunities: [TradingOpportunity]
    
    struct DrawingData: Codable {
        let type: String
        let coordinates: [[Double]] // [timestamp, price] pairs
        let properties: [String: String] // Changed from Any to String for Codable
        let confidence: Double
        let description: String
    }
    
    struct MarketContext: Codable {
        let trend: String
        let volatility: String
        let keyLevels: [Double]
        let marketStructure: String
    }
    
    struct TradingOpportunity: Codable {
        let type: String // "long", "short"
        let entry: Double
        let stopLoss: Double
        let targets: [Double]
        let reasoning: String
        let confidence: Double
    }
}

// MARK: - Drawing Collection

class ChartDrawingCollection: ObservableObject {
    @Published var drawings: [any ChartDrawing] = []
    @Published var isAnalyzing = false
    @Published var selectedDrawingTypes: Set<ChartDrawingType> = Set(ChartDrawingType.allCases)
    
    func addDrawing(_ drawing: any ChartDrawing) {
        drawings.append(drawing)
    }
    
    func removeDrawing(id: UUID) {
        drawings.removeAll { $0.id == id }
    }
    
    func toggleDrawingVisibility(id: UUID) {
        if let index = drawings.firstIndex(where: { $0.id == id }) {
            drawings[index].isVisible.toggle()
        }
    }
    
    func clearAllDrawings() {
        drawings.removeAll()
    }
    
    func filterDrawings(by types: Set<ChartDrawingType>) -> [any ChartDrawing] {
        drawings.filter { types.contains($0.type) && $0.isVisible }
    }
}