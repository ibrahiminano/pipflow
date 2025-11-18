//
//  SignalsViewModel.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

@MainActor
class SignalsViewModel: ObservableObject {
    @Published var signals: [Signal] = []
    @Published var activePrompts: [TradingPrompt] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let aiSignalService = AISignalService.shared
    private let metaAPIManager = MetaAPIManager.shared
    private let promptEngine = PromptTradingEngine.shared
    
    init() {
        loadMockSignals()
        startListening()
        
        // Immediately set the active prompts from the prompt engine
        activePrompts = promptEngine.activePrompts
    }
    
    func startListening() {
        aiSignalService.$activeSignals
            .sink { [weak self] signals in
                self?.signals = signals.sorted(by: { $0.generatedAt > $1.generatedAt })
            }
            .store(in: &cancellables)
        
        promptEngine.$activePrompts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] prompts in
                print("SignalsViewModel received prompts update: \(prompts.count) prompts")
                self?.activePrompts = prompts
            }
            .store(in: &cancellables)
    }
    
    func executeSignal(_ signal: Signal) {
        guard let accountId = metaAPIManager.connectedAccounts.first?.id else {
            errorMessage = "No connected trading account"
            return
        }
        
        isLoading = true
        
        let volume = 0.01 // Default volume
        let side: TradeSide = signal.action == .buy ? .buy : .sell
        
        metaAPIManager.openPosition(
            accountId: accountId,
            symbol: signal.symbol,
            volume: volume,
            side: side,
            stopLoss: NSDecimalNumber(decimal: signal.stopLoss).doubleValue,
            takeProfit: signal.takeProfits.first.map { NSDecimalNumber(decimal: $0.price).doubleValue }
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] orderId in
                self?.isLoading = false
                print("Signal executed successfully: \(orderId)")
            }
        )
        .store(in: &cancellables)
    }
    
    func generateSignal(for symbol: String) {
        isLoading = true
        
        // Mock market data for demo
        let marketData = MarketData(
            currentPrice: 1.0850,
            high24h: 1.0890,
            low24h: 1.0820,
            volume24h: 1000000,
            priceChange24h: 0.25,
            bid: 1.0849,
            ask: 1.0851,
            spread: 0.0002
        )
        
        let technicalIndicators = TechnicalIndicators(
            rsi: 55.0,
            macd: MACDIndicator(macd: 0.0012, signal: 0.0010, histogram: 0.0002),
            movingAverages: MovingAverages(ma20: 1.0845, ma50: 1.0840, ma200: 1.0835),
            support: 1.0820,
            resistance: 1.0890,
            trend: .bullish
        )
        
        aiSignalService.generateSignal(
            for: symbol,
            marketData: marketData,
            technicalIndicators: technicalIndicators,
            provider: .claude
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { _ in
                // Signal will be added via the listening publisher
            }
        )
        .store(in: &cancellables)
    }
    
    private func loadMockSignals() {
        // Add some mock signals for demonstration
        signals = [
            Signal(
                id: UUID(),
                symbol: "EURUSD",
                action: .buy,
                entry: 1.0850,
                stopLoss: 1.0820,
                takeProfits: [
                    TakeProfit(price: 1.0900, percentage: 0.5, rationale: "First resistance level"),
                    TakeProfit(price: 1.0920, percentage: 0.5, rationale: "Major resistance zone")
                ],
                confidence: 0.85,
                rationale: "Strong bullish momentum detected. Price broke above key resistance at 1.0840 with increasing volume. RSI shows room for further upside without being overbought. MACD histogram turning positive confirms bullish sentiment.",
                timeframe: .h1,
                analysisType: .technical,
                riskRewardRatio: 1.67,
                generatedBy: .ai,
                generatedAt: Date().addingTimeInterval(-300),
                expiresAt: Date().addingTimeInterval(3600),
                status: .active
            ),
            Signal(
                id: UUID(),
                symbol: "BTCUSD",
                action: .sell,
                entry: 98500,
                stopLoss: 99200,
                takeProfits: [
                    TakeProfit(price: 96800, percentage: 1.0, rationale: "Key support level")
                ],
                confidence: 0.72,
                rationale: "Bearish divergence on RSI while price made new highs. Volume declining on recent rally suggests weakening momentum. Key support at 97000 likely to be tested.",
                timeframe: .h4,
                analysisType: .technical,
                riskRewardRatio: 2.43,
                generatedBy: .ai,
                generatedAt: Date().addingTimeInterval(-600),
                expiresAt: Date().addingTimeInterval(7200),
                status: .active
            ),
            Signal(
                id: UUID(),
                symbol: "GBPUSD",
                action: .buy,
                entry: 1.2750,
                stopLoss: 1.2700,
                takeProfits: [
                    TakeProfit(price: 1.2850, percentage: 1.0, rationale: "Previous high")
                ],
                confidence: 0.68,
                rationale: "Oversold conditions on shorter timeframes. Price approaching major support zone. Risk/reward favorable for a bounce play.",
                timeframe: .m30,
                analysisType: .technical,
                riskRewardRatio: 2.0,
                generatedBy: .ai,
                generatedAt: Date().addingTimeInterval(-900),
                expiresAt: Date().addingTimeInterval(1800),
                status: .active
            )
        ]
    }
}