//
//  AISignalService.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

// MARK: - AI Signal Models

struct AISignalRequest {
    let symbol: String
    let timeframe: String
    let marketData: MarketData
    let technicalIndicators: TechnicalIndicators
    let recentNews: [NewsItem]?
}

struct MarketData {
    let currentPrice: Double
    let high24h: Double
    let low24h: Double
    let volume24h: Double
    let priceChange24h: Double
    let bid: Double
    let ask: Double
    let spread: Double
}

struct TechnicalIndicators {
    let rsi: Double?
    let macd: MACDIndicator?
    let movingAverages: MovingAverages?
    let support: Double?
    let resistance: Double?
    let trend: TrendDirection
}

struct MACDIndicator {
    let macd: Double
    let signal: Double
    let histogram: Double
}

struct MovingAverages {
    let ma20: Double
    let ma50: Double
    let ma200: Double
}

enum TrendDirection: String {
    case bullish = "BULLISH"
    case bearish = "BEARISH"
    case neutral = "NEUTRAL"
}

struct NewsItem {
    let title: String
    let summary: String
    let sentiment: Double
    let timestamp: Date
}

struct AISignalResponse {
    let signal: Signal
    let confidence: Double
    let reasoning: String
    let risks: [String]
    let generatedAt: Date
}

// MARK: - AI Provider Protocol

protocol AIProviderProtocol {
    func generateSignal(request: AISignalRequest) -> AnyPublisher<AISignalResponse, Error>
}

// MARK: - AI Signal Service

class AISignalService: ObservableObject {
    static let shared = AISignalService()
    
    @Published var activeSignals: [Signal] = []
    @Published var isGenerating = false
    
    private var cancellables = Set<AnyCancellable>()
    private let openAIProvider: OpenAIProvider
    private let claudeProvider: ClaudeProvider
    
    init() {
        self.openAIProvider = OpenAIProvider()
        self.claudeProvider = ClaudeProvider()
    }
    
    func generateSignal(
        for symbol: String,
        timeframe: String = "H1",
        marketData: MarketData,
        technicalIndicators: TechnicalIndicators,
        recentNews: [NewsItem]? = nil,
        provider: AIProvider = .claude
    ) -> AnyPublisher<Signal, Error> {
        isGenerating = true
        
        let request = AISignalRequest(
            symbol: symbol,
            timeframe: timeframe,
            marketData: marketData,
            technicalIndicators: technicalIndicators,
            recentNews: recentNews
        )
        
        let aiProvider: AIProviderProtocol = provider == .openai ? openAIProvider : claudeProvider
        
        return aiProvider.generateSignal(request: request)
            .map { response in
                self.activeSignals.append(response.signal)
                return response.signal
            }
            .handleEvents(
                receiveCompletion: { _ in
                    self.isGenerating = false
                },
                receiveCancel: {
                    self.isGenerating = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    func analyzeMultipleTimeframes(
        for symbol: String,
        marketData: MarketData,
        provider: AIProvider = .claude
    ) -> AnyPublisher<[Signal], Error> {
        let timeframes = ["M5", "M15", "H1", "H4", "D1"]
        
        let publishers = timeframes.map { timeframe in
            generateSignal(
                for: symbol,
                timeframe: timeframe,
                marketData: marketData,
                technicalIndicators: TechnicalIndicators(
                    rsi: nil,
                    macd: nil,
                    movingAverages: nil,
                    support: nil,
                    resistance: nil,
                    trend: .neutral
                ),
                provider: provider
            )
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }
}

// MARK: - AI Provider Enum

enum AIProvider {
    case openai
    case claude
}

// MARK: - OpenAI Provider

class OpenAIProvider: AIProviderProtocol {
    private let apiKey = AppEnvironment.OpenAI.apiKey
    private let model = AppEnvironment.OpenAI.model
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    func generateSignal(request: AISignalRequest) -> AnyPublisher<AISignalResponse, Error> {
        let prompt = buildPrompt(from: request)
        
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.3,
            "response_format": ["type": "json_object"]
        ]
        
        urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: OpenAISignalResponse.self, decoder: JSONDecoder())
            .tryMap { response in
                guard let content = response.choices.first?.message.content,
                      let data = content.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw APIError.decodingError(NSError(domain: "AISignalService", code: 0))
                }
                
                return self.parseSignalResponse(json: json, request: request)
            }
            .eraseToAnyPublisher()
    }
    
    private var systemPrompt: String {
        """
        You are an expert forex and crypto trading analyst with 20+ years of experience. Analyze market data and provide trading signals with the following JSON structure:
        {
            "action": "BUY" or "SELL" or "HOLD",
            "entry": number (exact entry price),
            "stopLoss": number (conservative stop loss, typically 1-2% risk),
            "takeProfit": number (realistic target, typically 1.5-3x risk),
            "confidence": number (0-1, where 0.7+ is high confidence),
            "reasoning": "detailed explanation including technical analysis, market structure, and key levels",
            "risks": ["specific risk factors for this trade"]
        }
        
        Guidelines:
        1. Only suggest BUY/SELL when there's a clear edge with good risk/reward
        2. Consider market structure, trend, momentum, and volume
        3. Factor in support/resistance levels and key psychological prices
        4. Account for spread and slippage in your calculations
        5. Be conservative - it's better to miss a trade than take a bad one
        6. Provide specific, actionable reasoning that traders can verify
        7. List concrete risks, not generic warnings
        """
    }
    
    private func buildPrompt(from request: AISignalRequest) -> String {
        var prompt = """
        Analyze \(request.symbol) on \(request.timeframe) timeframe:
        
        Market Data:
        - Current Price: \(request.marketData.currentPrice)
        - 24h High/Low: \(request.marketData.high24h)/\(request.marketData.low24h)
        - 24h Volume: \(request.marketData.volume24h)
        - 24h Change: \(request.marketData.priceChange24h)%
        - Bid/Ask: \(request.marketData.bid)/\(request.marketData.ask)
        - Spread: \(request.marketData.spread)
        
        Technical Indicators:
        - Trend: \(request.technicalIndicators.trend.rawValue)
        """
        
        if let rsi = request.technicalIndicators.rsi {
            prompt += "\n- RSI: \(rsi)"
        }
        
        if let macd = request.technicalIndicators.macd {
            prompt += "\n- MACD: \(macd.macd), Signal: \(macd.signal), Histogram: \(macd.histogram)"
        }
        
        if let ma = request.technicalIndicators.movingAverages {
            prompt += "\n- MA20: \(ma.ma20), MA50: \(ma.ma50), MA200: \(ma.ma200)"
        }
        
        if let support = request.technicalIndicators.support {
            prompt += "\n- Support: \(support)"
        }
        
        if let resistance = request.technicalIndicators.resistance {
            prompt += "\n- Resistance: \(resistance)"
        }
        
        if let news = request.recentNews, !news.isEmpty {
            prompt += "\n\nRecent News:"
            for item in news.prefix(3) {
                prompt += "\n- \(item.title) (Sentiment: \(item.sentiment))"
            }
        }
        
        prompt += "\n\nProvide a trading signal with entry, stop loss, and take profit levels."
        
        return prompt
    }
    
    private func parseSignalResponse(json: [String: Any], request: AISignalRequest) -> AISignalResponse {
        let action = json["action"] as? String ?? "HOLD"
        let entry = json["entry"] as? Double ?? request.marketData.currentPrice
        let stopLoss = json["stopLoss"] as? Double ?? 0
        let takeProfit = json["takeProfit"] as? Double ?? 0
        let confidence = json["confidence"] as? Double ?? 0.5
        let reasoning = json["reasoning"] as? String ?? "AI analysis"
        let risks = json["risks"] as? [String] ?? []
        
        let signal = Signal(
            id: UUID(),
            symbol: request.symbol,
            action: action == "BUY" ? .buy : (action == "SELL" ? .sell : .close),
            entry: Decimal(entry),
            stopLoss: Decimal(stopLoss),
            takeProfits: [TakeProfit(price: Decimal(takeProfit), percentage: 1.0, rationale: "Primary target")],
            confidence: confidence,
            rationale: reasoning,
            timeframe: Timeframe(rawValue: request.timeframe) ?? .h1,
            analysisType: .technical,
            riskRewardRatio: abs(takeProfit - entry) / abs(entry - stopLoss),
            generatedBy: .ai,
            generatedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            status: .active
        )
        
        return AISignalResponse(
            signal: signal,
            confidence: confidence,
            reasoning: reasoning,
            risks: risks,
            generatedAt: Date()
        )
    }
}

// MARK: - Claude Provider

class ClaudeProvider: AIProviderProtocol {
    private let apiKey = AppEnvironment.Claude.apiKey
    private let model = AppEnvironment.Claude.model
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    func generateSignal(request: AISignalRequest) -> AnyPublisher<AISignalResponse, Error> {
        let prompt = buildPrompt(from: request)
        
        var urlRequest = URLRequest(url: URL(string: baseURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": systemPrompt + "\n\n" + prompt
                ]
            ]
        ]
        
        urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .decode(type: ClaudeResponse.self, decoder: JSONDecoder())
            .tryMap { response in
                guard let content = response.content.first?.text,
                      let jsonStart = content.firstIndex(of: "{"),
                      let jsonEnd = content.lastIndex(of: "}") else {
                    throw APIError.decodingError(NSError(domain: "AISignalService", code: 0))
                }
                
                let jsonString = String(content[jsonStart...jsonEnd])
                guard let data = jsonString.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw APIError.decodingError(NSError(domain: "AISignalService", code: 0))
                }
                
                return self.parseSignalResponse(json: json, request: request)
            }
            .eraseToAnyPublisher()
    }
    
    private var systemPrompt: String {
        """
        You are an expert forex and crypto trading analyst with 20+ years of experience. Analyze market data and provide trading signals.
        
        Return your analysis in this exact JSON format:
        {
            "action": "BUY" or "SELL" or "HOLD",
            "entry": number (exact entry price),
            "stopLoss": number (conservative stop loss, typically 1-2% risk),
            "takeProfit": number (realistic target, typically 1.5-3x risk),
            "confidence": number (0-1, where 0.7+ is high confidence),
            "reasoning": "detailed explanation including technical analysis, market structure, and key levels",
            "risks": ["specific risk factors for this trade"]
        }
        
        Guidelines:
        1. Only suggest BUY/SELL when there's a clear edge with good risk/reward
        2. Consider market structure, trend, momentum, and volume
        3. Factor in support/resistance levels and key psychological prices
        4. Account for spread and slippage in your calculations
        5. Be conservative - it's better to miss a trade than take a bad one
        6. Provide specific, actionable reasoning that traders can verify
        7. List concrete risks, not generic warnings
        8. If RSI > 70 or < 30, mention overbought/oversold conditions
        9. Consider MACD crossovers and divergences
        10. Note if price is near moving averages for potential support/resistance
        """
    }
    
    private func buildPrompt(from request: AISignalRequest) -> String {
        // Same as OpenAI provider
        var prompt = """
        Analyze \(request.symbol) on \(request.timeframe) timeframe:
        
        Market Data:
        - Current Price: \(request.marketData.currentPrice)
        - 24h High/Low: \(request.marketData.high24h)/\(request.marketData.low24h)
        - 24h Volume: \(request.marketData.volume24h)
        - 24h Change: \(request.marketData.priceChange24h)%
        - Bid/Ask: \(request.marketData.bid)/\(request.marketData.ask)
        - Spread: \(request.marketData.spread)
        
        Technical Indicators:
        - Trend: \(request.technicalIndicators.trend.rawValue)
        """
        
        if let rsi = request.technicalIndicators.rsi {
            prompt += "\n- RSI: \(rsi)"
        }
        
        if let macd = request.technicalIndicators.macd {
            prompt += "\n- MACD: \(macd.macd), Signal: \(macd.signal), Histogram: \(macd.histogram)"
        }
        
        if let ma = request.technicalIndicators.movingAverages {
            prompt += "\n- MA20: \(ma.ma20), MA50: \(ma.ma50), MA200: \(ma.ma200)"
        }
        
        if let support = request.technicalIndicators.support {
            prompt += "\n- Support: \(support)"
        }
        
        if let resistance = request.technicalIndicators.resistance {
            prompt += "\n- Resistance: \(resistance)"
        }
        
        if let news = request.recentNews, !news.isEmpty {
            prompt += "\n\nRecent News:"
            for item in news.prefix(3) {
                prompt += "\n- \(item.title) (Sentiment: \(item.sentiment))"
            }
        }
        
        prompt += "\n\nProvide a trading signal with entry, stop loss, and take profit levels."
        
        return prompt
    }
    
    private func parseSignalResponse(json: [String: Any], request: AISignalRequest) -> AISignalResponse {
        let action = json["action"] as? String ?? "HOLD"
        let entry = json["entry"] as? Double ?? request.marketData.currentPrice
        let stopLoss = json["stopLoss"] as? Double ?? 0
        let takeProfit = json["takeProfit"] as? Double ?? 0
        let confidence = json["confidence"] as? Double ?? 0.5
        let reasoning = json["reasoning"] as? String ?? "AI analysis"
        let risks = json["risks"] as? [String] ?? []
        
        let signal = Signal(
            id: UUID(),
            symbol: request.symbol,
            action: action == "BUY" ? .buy : (action == "SELL" ? .sell : .close),
            entry: Decimal(entry),
            stopLoss: Decimal(stopLoss),
            takeProfits: [TakeProfit(price: Decimal(takeProfit), percentage: 1.0, rationale: "Primary target")],
            confidence: confidence,
            rationale: reasoning,
            timeframe: Timeframe(rawValue: request.timeframe) ?? .h1,
            analysisType: .technical,
            riskRewardRatio: abs(takeProfit - entry) / abs(entry - stopLoss),
            generatedBy: .ai,
            generatedAt: Date(),
            expiresAt: Date().addingTimeInterval(3600),
            status: .active
        )
        
        return AISignalResponse(
            signal: signal,
            confidence: confidence,
            reasoning: reasoning,
            risks: risks,
            generatedAt: Date()
        )
    }
}

// MARK: - Response Models

private struct OpenAISignalResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String
    }
}

private struct ClaudeResponse: Decodable {
    let content: [Content]
    
    struct Content: Decodable {
        let text: String
    }
}