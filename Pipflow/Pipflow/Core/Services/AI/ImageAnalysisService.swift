//
//  ImageAnalysisService.swift
//  Pipflow
//
//  AI-powered analysis of trading charts and screenshots
//

import Foundation
import UIKit
import Vision
import CoreML

// MARK: - Image Analysis Models

struct ChartAnalysisResult {
    let chartType: ChartType
    let timeframe: String?
    let symbol: String?
    let priceAction: PriceActionAnalysis
    let patterns: [ChartPattern]
    let indicators: [DetectedIndicator]
    let keyLevels: [KeyLevel]
    let trendAnalysis: TrendAnalysis
    let annotations: [ChartAnnotation]
    let confidence: Double
    let suggestions: [TradingSuggestion]
    
    enum ChartType: String, CaseIterable {
        case candlestick = "Candlestick"
        case line = "Line"
        case bar = "Bar"
        case unknown = "Unknown"
    }
}

struct PriceActionAnalysis {
    let currentTrend: TrendDirection
    let momentum: MomentumStrength
    let volatility: VolatilityAssessment
    let recentMove: PriceMove?
    
    enum TrendDirection: String {
        case bullish = "Bullish"
        case bearish = "Bearish"
        case sideways = "Sideways"
        case uncertain = "Uncertain"
    }
    
    enum MomentumStrength: String {
        case strong = "Strong"
        case moderate = "Moderate"
        case weak = "Weak"
        case diverging = "Diverging"
    }
    
    struct VolatilityAssessment {
        let level: VolatilityLevel
        let expanding: Bool
        let averageRange: Double?
        
        enum VolatilityLevel: String {
            case low = "Low"
            case normal = "Normal"
            case high = "High"
            case extreme = "Extreme"
        }
    }
    
    struct PriceMove {
        let direction: TrendDirection
        let magnitude: Double
        let timeSpan: String
    }
}

struct ChartPattern {
    let type: PatternType
    let location: CGRect
    let reliability: Double
    let targetPrice: Double?
    let description: String
    
    enum PatternType: String, CaseIterable {
        case headAndShoulders = "Head and Shoulders"
        case doubleTop = "Double Top"
        case doubleBottom = "Double Bottom"
        case triangle = "Triangle"
        case wedge = "Wedge"
        case flag = "Flag"
        case pennant = "Pennant"
        case channel = "Channel"
        case supportResistance = "Support/Resistance"
    }
}

struct DetectedIndicator {
    let type: IndicatorType
    let value: Double?
    let signal: SignalType
    let location: CGRect?
    
    enum IndicatorType: String {
        case movingAverage = "Moving Average"
        case rsi = "RSI"
        case macd = "MACD"
        case bollingerBands = "Bollinger Bands"
        case volume = "Volume"
        case stochastic = "Stochastic"
        case other = "Other"
    }
    
    enum SignalType: String {
        case bullish = "Bullish"
        case bearish = "Bearish"
        case neutral = "Neutral"
        case overbought = "Overbought"
        case oversold = "Oversold"
    }
}

struct KeyLevel {
    let price: Double
    let type: LevelType
    let strength: Double
    let touches: Int
    
    enum LevelType: String {
        case support = "Support"
        case resistance = "Resistance"
        case pivot = "Pivot"
        case psychological = "Psychological"
    }
}

struct TrendAnalysis {
    let primaryTrend: Trend
    let secondaryTrend: Trend?
    let trendStrength: Double
    let trendAge: String?
    
    struct Trend {
        let direction: PriceActionAnalysis.TrendDirection
        let slope: Double?
        let consistency: Double
    }
}

struct ChartAnnotation {
    let type: AnnotationType
    let location: CGRect
    let text: String?
    let importance: Double
    
    enum AnnotationType: String {
        case priceLabel = "Price Label"
        case dateLabel = "Date Label"
        case indicator = "Indicator"
        case drawing = "Drawing"
        case alert = "Alert"
    }
}

struct TradingSuggestion {
    let action: SuggestedAction
    let reasoning: String
    let confidence: Double
    let riskLevel: RiskLevel
    
    enum SuggestedAction: String {
        case buy = "Buy"
        case sell = "Sell"
        case wait = "Wait"
        case closePosition = "Close Position"
        case tightenStop = "Tighten Stop"
        case takePartialProfit = "Take Partial Profit"
    }
    
    enum RiskLevel: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
}

// MARK: - Image Analysis Service

@MainActor
class ImageAnalysisService: ObservableObject {
    static let shared = ImageAnalysisService()
    
    @Published var isAnalyzing = false
    @Published var lastAnalysis: ChartAnalysisResult?
    @Published var analysisHistory: [ChartAnalysisResult] = []
    
    private let textRecognizer = TextRecognizer()
    private let patternDetector = PatternDetector()
    private let priceActionAnalyzer = PriceActionAnalyzer()
    private let aiAnalyzer = AIChartAnalyzer()
    
    private init() {}
    
    // MARK: - Main Analysis Method
    
    func analyzeChartImage(_ image: UIImage) async throws -> ChartAnalysisResult {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Preprocess image
        let processedImage = preprocessImage(image)
        
        // Extract text information
        let textData = try await textRecognizer.extractText(from: processedImage)
        let symbol = extractSymbol(from: textData)
        let timeframe = extractTimeframe(from: textData)
        
        // Detect chart type
        let chartType = detectChartType(in: processedImage)
        
        // Analyze price action
        let priceAction = await priceActionAnalyzer.analyze(processedImage)
        
        // Detect patterns
        let patterns = await patternDetector.detectPatterns(in: processedImage)
        
        // Detect indicators
        let indicators = detectIndicators(in: processedImage, textData: textData)
        
        // Identify key levels
        let keyLevels = identifyKeyLevels(in: processedImage, patterns: patterns)
        
        // Perform trend analysis
        let trendAnalysis = analyzeTrend(priceAction: priceAction, patterns: patterns)
        
        // Extract annotations
        let annotations = extractAnnotations(from: textData)
        
        // Generate AI-powered suggestions
        let suggestions = await generateTradingSuggestions(
            priceAction: priceAction,
            patterns: patterns,
            indicators: indicators,
            trend: trendAnalysis
        )
        
        // Calculate overall confidence
        let confidence = calculateConfidence(
            chartType: chartType,
            patterns: patterns,
            indicators: indicators
        )
        
        let result = ChartAnalysisResult(
            chartType: chartType,
            timeframe: timeframe,
            symbol: symbol,
            priceAction: priceAction,
            patterns: patterns,
            indicators: indicators,
            keyLevels: keyLevels,
            trendAnalysis: trendAnalysis,
            annotations: annotations,
            confidence: confidence,
            suggestions: suggestions
        )
        
        // Store in history
        lastAnalysis = result
        analysisHistory.append(result)
        if analysisHistory.count > 50 {
            analysisHistory.removeFirst()
        }
        
        return result
    }
    
    // MARK: - Image Preprocessing
    
    private func preprocessImage(_ image: UIImage) -> UIImage {
        // Apply filters to enhance chart visibility
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext()
        
        // Increase contrast
        let contrastFilter = CIFilter(name: "CIColorControls")!
        contrastFilter.setValue(ciImage, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.2, forKey: kCIInputContrastKey)
        
        // Sharpen
        let sharpenFilter = CIFilter(name: "CISharpenLuminance")!
        sharpenFilter.setValue(contrastFilter.outputImage, forKey: kCIInputImageKey)
        sharpenFilter.setValue(0.5, forKey: kCIInputSharpnessKey)
        
        guard let outputImage = sharpenFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Chart Type Detection
    
    private func detectChartType(in image: UIImage) -> ChartAnalysisResult.ChartType {
        // Use Vision framework to detect chart characteristics
        // For now, return a default
        return .candlestick
    }
    
    // MARK: - Text Extraction
    
    private func extractSymbol(from textData: [RecognizedText]) -> String? {
        // Look for common symbol patterns
        for text in textData {
            let upperText = text.content.uppercased()
            
            // Forex pairs
            if upperText.matches(pattern: #"[A-Z]{3}/[A-Z]{3}"#) ||
               upperText.matches(pattern: #"[A-Z]{6}"#) {
                return upperText
            }
            
            // Commodities
            if upperText.contains("GOLD") || upperText.contains("XAUUSD") {
                return "XAUUSD"
            }
            if upperText.contains("SILVER") || upperText.contains("XAGUSD") {
                return "XAGUSD"
            }
            
            // Crypto
            if upperText.contains("BTC") || upperText.contains("BITCOIN") {
                return "BTCUSD"
            }
        }
        
        return nil
    }
    
    private func extractTimeframe(from textData: [RecognizedText]) -> String? {
        // Look for timeframe patterns
        for text in textData {
            let content = text.content.uppercased()
            
            // Common timeframes
            if content.matches(pattern: #"\b(M1|M5|M15|M30|H1|H4|D1|W1|MN)\b"#) {
                return content
            }
            
            if content.contains("DAILY") { return "D1" }
            if content.contains("HOURLY") { return "H1" }
            if content.contains("4 HOUR") { return "H4" }
            if content.contains("WEEKLY") { return "W1" }
        }
        
        return nil
    }
    
    // MARK: - Indicator Detection
    
    private func detectIndicators(in image: UIImage, textData: [RecognizedText]) -> [DetectedIndicator] {
        var indicators: [DetectedIndicator] = []
        
        // Check text for indicator values
        for text in textData {
            let content = text.content.uppercased()
            
            // RSI
            if let rsiMatch = content.firstMatch(pattern: #"RSI.*?(\d+\.?\d*)"#) {
                if let value = Double(rsiMatch) {
                    let signal: DetectedIndicator.SignalType
                    if value > 70 { signal = .overbought }
                    else if value < 30 { signal = .oversold }
                    else { signal = .neutral }
                    
                    indicators.append(DetectedIndicator(
                        type: .rsi,
                        value: value,
                        signal: signal,
                        location: text.boundingBox
                    ))
                }
            }
            
            // MACD
            if content.contains("MACD") {
                indicators.append(DetectedIndicator(
                    type: .macd,
                    value: nil,
                    signal: .neutral,
                    location: text.boundingBox
                ))
            }
        }
        
        return indicators
    }
    
    // MARK: - Key Level Identification
    
    private func identifyKeyLevels(in image: UIImage, patterns: [ChartPattern]) -> [KeyLevel] {
        var levels: [KeyLevel] = []
        
        // Extract from patterns
        for pattern in patterns {
            if pattern.type == .supportResistance,
               let targetPrice = pattern.targetPrice {
                levels.append(KeyLevel(
                    price: targetPrice,
                    type: pattern.description.contains("Support") ? .support : .resistance,
                    strength: pattern.reliability,
                    touches: 3 // Default estimate
                ))
            }
        }
        
        return levels
    }
    
    // MARK: - Trend Analysis
    
    private func analyzeTrend(priceAction: PriceActionAnalysis, patterns: [ChartPattern]) -> TrendAnalysis {
        let primaryTrend = TrendAnalysis.Trend(
            direction: priceAction.currentTrend,
            slope: nil,
            consistency: 0.7
        )
        
        return TrendAnalysis(
            primaryTrend: primaryTrend,
            secondaryTrend: nil,
            trendStrength: 0.7,
            trendAge: nil
        )
    }
    
    // MARK: - Annotation Extraction
    
    private func extractAnnotations(from textData: [RecognizedText]) -> [ChartAnnotation] {
        return textData.map { text in
            let type: ChartAnnotation.AnnotationType
            if text.content.contains("$") || text.content.matches(pattern: #"\d+\.\d+"#) {
                type = .priceLabel
            } else if text.content.matches(pattern: #"\d{1,2}[:/]\d{1,2}"#) {
                type = .dateLabel
            } else {
                type = .indicator
            }
            
            return ChartAnnotation(
                type: type,
                location: text.boundingBox,
                text: text.content,
                importance: 0.5
            )
        }
    }
    
    // MARK: - AI Suggestions
    
    private func generateTradingSuggestions(
        priceAction: PriceActionAnalysis,
        patterns: [ChartPattern],
        indicators: [DetectedIndicator],
        trend: TrendAnalysis
    ) async -> [TradingSuggestion] {
        
        // Analyze conditions
        let isBullish = priceAction.currentTrend == .bullish
        let hasStrongMomentum = priceAction.momentum == .strong
        let hasOversoldRSI = indicators.contains { $0.type == .rsi && $0.signal == .oversold }
        let hasOverboughtRSI = indicators.contains { $0.type == .rsi && $0.signal == .overbought }
        
        var suggestions: [TradingSuggestion] = []
        
        // Generate suggestions based on analysis
        if isBullish && hasStrongMomentum && !hasOverboughtRSI {
            suggestions.append(TradingSuggestion(
                action: .buy,
                reasoning: "Strong bullish trend with momentum, no overbought conditions",
                confidence: 0.75,
                riskLevel: .medium
            ))
        }
        
        if hasOverboughtRSI && !isBullish {
            suggestions.append(TradingSuggestion(
                action: .sell,
                reasoning: "Overbought RSI in non-bullish trend suggests reversal",
                confidence: 0.65,
                riskLevel: .medium
            ))
        }
        
        if hasOversoldRSI && trend.trendStrength < 0.5 {
            suggestions.append(TradingSuggestion(
                action: .wait,
                reasoning: "Oversold but weak trend - wait for confirmation",
                confidence: 0.8,
                riskLevel: .low
            ))
        }
        
        // Default suggestion if no clear signal
        if suggestions.isEmpty {
            suggestions.append(TradingSuggestion(
                action: .wait,
                reasoning: "No clear trading signal identified",
                confidence: 0.9,
                riskLevel: .low
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Confidence Calculation
    
    private func calculateConfidence(
        chartType: ChartAnalysisResult.ChartType,
        patterns: [ChartPattern],
        indicators: [DetectedIndicator]
    ) -> Double {
        var confidence = 0.5
        
        // Chart type bonus
        if chartType != .unknown {
            confidence += 0.1
        }
        
        // Pattern detection bonus
        confidence += Double(patterns.count) * 0.05
        
        // Indicator detection bonus
        confidence += Double(indicators.count) * 0.05
        
        return min(confidence, 0.95)
    }
    
    // MARK: - Export Analysis
    
    func exportAnalysisAsPrompt(_ analysis: ChartAnalysisResult) -> String {
        var prompt = ""
        
        if let symbol = analysis.symbol {
            prompt += "Trade \(symbol) "
        }
        
        if let timeframe = analysis.timeframe {
            prompt += "on \(timeframe) timeframe. "
        }
        
        // Add trend information
        prompt += "Current trend is \(analysis.priceAction.currentTrend.rawValue.lowercased()) "
        prompt += "with \(analysis.priceAction.momentum.rawValue.lowercased()) momentum. "
        
        // Add pattern information
        if !analysis.patterns.isEmpty {
            let patternNames = analysis.patterns.map { $0.type.rawValue }.joined(separator: ", ")
            prompt += "Chart shows \(patternNames) patterns. "
        }
        
        // Add indicator information
        for indicator in analysis.indicators {
            if indicator.type == .rsi, let value = indicator.value {
                prompt += "RSI is at \(Int(value)) (\(indicator.signal.rawValue.lowercased())). "
            }
        }
        
        // Add suggestions
        if let mainSuggestion = analysis.suggestions.first {
            prompt += "Suggested action: \(mainSuggestion.action.rawValue) - \(mainSuggestion.reasoning)"
        }
        
        return prompt
    }
}

// MARK: - Supporting Services

class TextRecognizer {
    func extractText(from image: UIImage) async throws -> [RecognizedText] {
        guard let cgImage = image.cgImage else {
            throw ImageAnalysisError.invalidImage
        }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let recognizedTexts = observations.compactMap { observation -> RecognizedText? in
                    guard let text = observation.topCandidates(1).first else { return nil }
                    
                    return RecognizedText(
                        content: text.string,
                        confidence: text.confidence,
                        boundingBox: self.convertBoundingBox(observation.boundingBox)
                    )
                }
                
                continuation.resume(returning: recognizedTexts)
            }
            
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    private func convertBoundingBox(_ box: CGRect) -> CGRect {
        // Convert Vision coordinates to UIKit coordinates
        return CGRect(
            x: box.origin.x,
            y: 1 - box.origin.y - box.height,
            width: box.width,
            height: box.height
        )
    }
}

class PatternDetector {
    func detectPatterns(in image: UIImage) async -> [ChartPattern] {
        // Simplified pattern detection
        // In production, use Core ML or Vision framework
        return []
    }
}

class PriceActionAnalyzer {
    func analyze(_ image: UIImage) async -> PriceActionAnalysis {
        // Simplified price action analysis
        return PriceActionAnalysis(
            currentTrend: .uncertain,
            momentum: .moderate,
            volatility: PriceActionAnalysis.VolatilityAssessment(
                level: .normal,
                expanding: false,
                averageRange: nil
            ),
            recentMove: nil
        )
    }
}

class AIChartAnalyzer {
    func analyzeWithAI(_ image: UIImage, context: String) async throws -> String {
        // This would integrate with AI service for advanced analysis
        return "AI analysis pending implementation"
    }
}

// MARK: - Supporting Models

struct RecognizedText {
    let content: String
    let confidence: Float
    let boundingBox: CGRect
}

enum ImageAnalysisError: Error {
    case invalidImage
    case analysisFailed
    case textRecognitionFailed
    case noDataExtracted
}

// MARK: - String Extensions

extension String {
    func matches(pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
    
    func firstMatch(pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(self.startIndex..<self.endIndex, in: self)
        guard let match = regex.firstMatch(in: self, options: [], range: range) else {
            return nil
        }
        
        if match.numberOfRanges > 1 {
            let matchRange = match.range(at: 1)
            if let swiftRange = Range(matchRange, in: self) {
                return String(self[swiftRange])
            }
        }
        
        return nil
    }
}