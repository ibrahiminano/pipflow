//
//  ARModels.swift
//  Pipflow
//
//  AR Trading data models
//

import Foundation
import RealityKit
import ARKit

// MARK: - AR Chart Type
enum ARChartType: String, CaseIterable {
    case candlestick = "Candlestick"
    case line = "Line"
    case volume = "Volume"
    case heatmap = "Heat Map"
    case portfolio3D = "3D Portfolio"
    
    var icon: String {
        switch self {
        case .candlestick: return "chart.bar.fill"
        case .line: return "chart.line.uptrend.xyaxis"
        case .volume: return "chart.bar.xaxis"
        case .heatmap: return "square.grid.3x3.fill"
        case .portfolio3D: return "cube.fill"
        }
    }
}

// MARK: - AR Visualization Settings
struct ARVisualizationSettings {
    var chartType: ARChartType = .candlestick
    var timeframe: String = "H1"
    var showGrid: Bool = true
    var showIndicators: Bool = true
    var animationSpeed: Float = 1.0
    var scale: Float = 1.0
    var opacity: Float = 0.9
    var colorScheme: ARColorScheme = .default
}

// MARK: - AR Color Scheme
enum ARColorScheme: String, CaseIterable {
    case `default` = "Default"
    case neon = "Neon"
    case holographic = "Holographic"
    case matrix = "Matrix"
    case professional = "Professional"
    
    var bullishColor: UIColor {
        switch self {
        case .default: return .systemGreen
        case .neon: return UIColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 1.0)
        case .holographic: return UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
        case .matrix: return UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        case .professional: return UIColor(red: 0.0, green: 0.7, blue: 0.3, alpha: 1.0)
        }
    }
    
    var bearishColor: UIColor {
        switch self {
        case .default: return .systemRed
        case .neon: return UIColor(red: 1.0, green: 0.2, blue: 0.4, alpha: 1.0)
        case .holographic: return UIColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 1.0)
        case .matrix: return UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        case .professional: return UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        }
    }
}

// MARK: - AR Chart Data
struct ARChartData {
    let symbol: String
    let candles: [ARCandle]
    let indicators: [ARIndicator]
    let currentPrice: Double
    let change: Double
    let changePercent: Double
}

// MARK: - AR Indicator
struct ARIndicator {
    let type: IndicatorType
    let values: [Double]
    let color: UIColor
    let lineWidth: Float
    
    enum IndicatorType: String {
        case ma20 = "MA 20"
        case ma50 = "MA 50"
        case rsi = "RSI"
        case macd = "MACD"
        case bollinger = "Bollinger"
    }
}

// MARK: - AR Trading Gesture
enum ARTradingGesture {
    case tap(position: SIMD3<Float>)
    case longPress(position: SIMD3<Float>)
    case pinch(scale: Float)
    case rotate(angle: Float)
    case swipe(direction: SwipeDirection)
    
    enum SwipeDirection {
        case up, down, left, right
    }
}

// MARK: - AR Portfolio Item
struct ARPortfolioItem {
    let symbol: String
    let position: TrackedPosition
    let performance: Double
    let allocation: Double
    let risk: Double
}

// MARK: - AR Anchor Type
enum ARAnchorType {
    case wall
    case floor
    case table
    case floating
}

// MARK: - AR Session State
enum ARSessionState: Equatable {
    case initializing
    case ready
    case tracking
    case limited(reason: ARCamera.TrackingState.Reason)
    case failed(error: Error)
    
    static func == (lhs: ARSessionState, rhs: ARSessionState) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing),
             (.ready, .ready),
             (.tracking, .tracking):
            return true
        case (.limited(let lhsReason), .limited(let rhsReason)):
            return lhsReason == rhsReason
        case (.failed(_), .failed(_)):
            return true // For simplicity, consider all failed states equal
        default:
            return false
        }
    }
}

// MARK: - AR Performance Metrics
struct ARPerformanceMetrics {
    let fps: Int
    let trackingQuality: Float
    let anchorCount: Int
    let meshVertexCount: Int
    let cpuUsage: Float
    let memoryUsage: Float
}