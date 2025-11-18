//
//  EnhancedChartDrawing.swift
//  Pipflow
//
//  Enhanced chart drawing models with annotations and trade ideas
//

import Foundation
import SwiftUI

// MARK: - Enhanced Drawing Protocol

protocol EnhancedChartDrawing: ChartDrawing {
    var annotation: String { get }
    var tradeIdea: String? { get }
    var priority: Int { get } // 1-5, higher is more important
}

// MARK: - Market Context Model

struct MarketContext: Codable {
    let trend: MarketTrend
    let trendStrength: TrendStrength
    let volatility: Volatility
    let keyLevels: [Double]
    let marketStructure: MarketStructure
    let commentary: String
    let tradingBias: TradingBias
    let riskFactors: [String]
    let opportunities: [String]
    
    enum MarketTrend: String, Codable {
        case bullish, bearish, neutral
    }
    
    enum TrendStrength: String, Codable {
        case strong, moderate, weak
    }
    
    enum Volatility: String, Codable {
        case low, medium, high
    }
    
    enum MarketStructure: String, Codable {
        case trending, ranging, breakout, breakdown
    }
    
    enum TradingBias: String, Codable {
        case long = "Long"
        case short = "Short"
        case neutral = "Neutral"
    }
}

// MARK: - Enhanced Support/Resistance

struct EnhancedSupportResistance: EnhancedChartDrawing, Codable {
    let id: UUID
    let type: ChartDrawingType
    let startPoint: ChartPoint
    let endPoint: ChartPoint
    let confidence: Double
    let description: String
    let annotation: String
    let tradeIdea: String?
    let priority: Int
    var isVisible: Bool
    let style: DrawingStyle
    let strength: Int
    let touches: [ChartPoint]
    let bounceRatio: Double // How much price bounces from this level
    
    init(
        id: UUID = UUID(),
        type: ChartDrawingType,
        startPoint: ChartPoint,
        endPoint: ChartPoint,
        confidence: Double,
        description: String,
        annotation: String,
        tradeIdea: String? = nil,
        priority: Int = 3,
        isVisible: Bool = true,
        style: DrawingStyle,
        strength: Int,
        touches: [ChartPoint],
        bounceRatio: Double = 0.0
    ) {
        self.id = id
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.confidence = confidence
        self.description = description
        self.annotation = annotation
        self.tradeIdea = tradeIdea
        self.priority = priority
        self.isVisible = isVisible
        self.style = style
        self.strength = strength
        self.touches = touches
        self.bounceRatio = bounceRatio
    }
}

// MARK: - Enhanced Trend Line

struct EnhancedTrendLine: EnhancedChartDrawing, Codable {
    let id: UUID
    let type: ChartDrawingType
    let startPoint: ChartPoint
    let endPoint: ChartPoint
    let confidence: Double
    let description: String
    let annotation: String
    let tradeIdea: String?
    let priority: Int
    var isVisible: Bool
    let style: DrawingStyle
    let direction: TrendLine.TrendDirection
    let slope: Double
    let touches: [ChartPoint]
    let projectedTarget: Double?
    
    init(
        id: UUID = UUID(),
        startPoint: ChartPoint,
        endPoint: ChartPoint,
        confidence: Double,
        description: String,
        annotation: String,
        tradeIdea: String? = nil,
        priority: Int = 3,
        isVisible: Bool = true,
        style: DrawingStyle,
        direction: TrendLine.TrendDirection,
        slope: Double,
        touches: [ChartPoint],
        projectedTarget: Double? = nil
    ) {
        self.id = id
        self.type = .trendLine
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.confidence = confidence
        self.description = description
        self.annotation = annotation
        self.tradeIdea = tradeIdea
        self.priority = priority
        self.isVisible = isVisible
        self.style = style
        self.direction = direction
        self.slope = slope
        self.touches = touches
        self.projectedTarget = projectedTarget
    }
}

// MARK: - Enhanced Supply/Demand Zone

struct EnhancedSupplyDemandZone: EnhancedChartDrawing, Codable {
    let id: UUID
    let type: ChartDrawingType
    let startPoint: ChartPoint
    let endPoint: ChartPoint
    let confidence: Double
    let description: String
    let annotation: String
    let tradeIdea: String?
    let priority: Int
    var isVisible: Bool
    let style: DrawingStyle
    let strength: SupplyDemandZone.ZoneStrength
    let volume: Double?
    let retests: Int
    let origin: ZoneOrigin
    let targetPrice: Double?
    
    enum ZoneOrigin: String, Codable {
        case accumulation = "Accumulation"
        case distribution = "Distribution"
        case consolidation = "Consolidation"
    }
    
    init(
        id: UUID = UUID(),
        type: ChartDrawingType,
        startPoint: ChartPoint,
        endPoint: ChartPoint,
        confidence: Double,
        description: String,
        annotation: String,
        tradeIdea: String? = nil,
        priority: Int = 3,
        isVisible: Bool = true,
        style: DrawingStyle,
        strength: SupplyDemandZone.ZoneStrength,
        volume: Double? = nil,
        retests: Int,
        origin: ZoneOrigin,
        targetPrice: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.confidence = confidence
        self.description = description
        self.annotation = annotation
        self.tradeIdea = tradeIdea
        self.priority = priority
        self.isVisible = isVisible
        self.style = style
        self.strength = strength
        self.volume = volume
        self.retests = retests
        self.origin = origin
        self.targetPrice = targetPrice
    }
}

// MARK: - Enhanced Chart Pattern

struct EnhancedChartPattern: EnhancedChartDrawing, Codable {
    let id: UUID
    let type: ChartDrawingType
    let startPoint: ChartPoint
    let endPoint: ChartPoint
    let confidence: Double
    let description: String
    let annotation: String
    let tradeIdea: String?
    let priority: Int
    var isVisible: Bool
    let style: DrawingStyle
    let patternType: PricePattern.PatternType
    let keyPoints: [ChartPoint]
    let necklinePrice: Double?
    let targetPrice: Double
    let stopLoss: Double
    let completion: Double // 0-1 how complete the pattern is
    
    init(
        id: UUID = UUID(),
        startPoint: ChartPoint,
        endPoint: ChartPoint,
        confidence: Double,
        description: String,
        annotation: String,
        tradeIdea: String? = nil,
        priority: Int = 4,
        isVisible: Bool = true,
        style: DrawingStyle,
        patternType: PricePattern.PatternType,
        keyPoints: [ChartPoint],
        necklinePrice: Double? = nil,
        targetPrice: Double,
        stopLoss: Double,
        completion: Double
    ) {
        self.id = id
        self.type = .pricePattern
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.confidence = confidence
        self.description = description
        self.annotation = annotation
        self.tradeIdea = tradeIdea
        self.priority = priority
        self.isVisible = isVisible
        self.style = style
        self.patternType = patternType
        self.keyPoints = keyPoints
        self.necklinePrice = necklinePrice
        self.targetPrice = targetPrice
        self.stopLoss = stopLoss
        self.completion = completion
    }
}

// MARK: - Drawing Annotation View

struct DrawingAnnotationView: View {
    let drawing: any EnhancedChartDrawing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Annotation Label
            HStack {
                Image(systemName: iconForDrawingType(drawing.type))
                    .foregroundColor(drawing.type.color)
                
                Text(drawing.annotation)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Confidence Badge
                Text("\(Int(drawing.confidence * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(confidenceColor(drawing.confidence))
                    )
            }
            
            // Description
            Text(drawing.description)
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.8))
                .lineLimit(2)
            
            // Trade Idea
            if let tradeIdea = drawing.tradeIdea {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)
                    
                    Text(tradeIdea)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(drawing.type.color.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private func iconForDrawingType(_ type: ChartDrawingType) -> String {
        switch type {
        case .supportLine: return "arrow.up.to.line"
        case .resistanceLine: return "arrow.down.to.line"
        case .trendLine: return "arrow.up.right"
        case .channel: return "rectangle.split.2x1"
        case .supplyZone: return "square.stack.3d.down.fill"
        case .demandZone: return "square.stack.3d.up.fill"
        case .fibonacciRetracement: return "ruler"
        case .pricePattern: return "waveform.path.ecg"
        case .keyLevel: return "star.fill"
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return Color.green
        } else if confidence >= 0.6 {
            return Color.yellow
        } else {
            return Color.orange
        }
    }
}