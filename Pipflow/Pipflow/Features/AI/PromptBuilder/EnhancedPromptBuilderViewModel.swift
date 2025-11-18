//
//  EnhancedPromptBuilderViewModel.swift
//  Pipflow
//
//  Enhanced ViewModel for AI Prompt Builder
//

import SwiftUI
import Combine
import Vision

@MainActor
class EnhancedPromptBuilderViewModel: ObservableObject {
    @Published var promptText = ""
    @Published var context = TradingContext()
    @Published var entryConditions: [ConditionItem] = []
    @Published var exitConditions: [ConditionItem] = []
    @Published var suggestions: [String] = []
    @Published var validationResult: PromptValidationResult?
    @Published var executionResult: ExecutionResult?
    @Published var isAnalyzingImages = false
    @Published var imageAnalysisResults: [ImageAnalysis] = []
    @Published var generatedCode: String?
    
    // Quick inserts for natural language
    let quickInserts = [
        "RSI < 30",
        "RSI > 70",
        "MACD crossover",
        "Support level",
        "Resistance level",
        "Stop loss",
        "Take profit",
        "Risk 1%",
        "Risk 2%",
        "London session",
        "New York session",
        "Asian session"
    ]
    
    private let promptEngine = PromptTradingEngine.shared
    private let aiService = AISignalService.shared
    private let imageAnalyzer = ChartImageAnalyzer()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadSavedDraft()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Auto-validate as user types
        $promptText
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] text in
                Task {
                    await self?.validatePrompt(text)
                    await self?.generateSuggestions(for: text)
                }
            }
            .store(in: &cancellables)
        
        // Update context when conditions change
        $entryConditions
            .combineLatest($exitConditions)
            .sink { [weak self] entry, exit in
                self?.updateContextFromConditions(entry: entry, exit: exit)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Image Analysis
    
    func addImageContext(_ image: UIImage) {
        isAnalyzingImages = true
        
        Task {
            do {
                let analysis = try await imageAnalyzer.analyzeChart(image)
                await MainActor.run {
                    imageAnalysisResults.append(analysis)
                    updatePromptWithImageAnalysis(analysis)
                    isAnalyzingImages = false
                }
            } catch {
                print("Image analysis error: \(error)")
                isAnalyzingImages = false
            }
        }
    }
    
    func removeImageContext(at index: Int) {
        guard index < imageAnalysisResults.count else { return }
        imageAnalysisResults.remove(at: index)
        regeneratePromptFromAllSources()
    }
    
    private func updatePromptWithImageAnalysis(_ analysis: ImageAnalysis) {
        var additions = [String]()
        
        if let pattern = analysis.detectedPattern {
            additions.append("Pattern detected: \(pattern)")
        }
        
        if !analysis.supportLevels.isEmpty {
            let supports = analysis.supportLevels.map { String(format: "%.4f", $0) }.joined(separator: ", ")
            additions.append("Support levels at: \(supports)")
        }
        
        if !analysis.resistanceLevels.isEmpty {
            let resistances = analysis.resistanceLevels.map { String(format: "%.4f", $0) }.joined(separator: ", ")
            additions.append("Resistance levels at: \(resistances)")
        }
        
        if let trend = analysis.trendDirection {
            additions.append("Trend direction: \(trend)")
        }
        
        if !additions.isEmpty {
            promptText += "\n\n[Chart Analysis] " + additions.joined(separator: ". ")
        }
    }
    
    // MARK: - Prompt Management
    
    func updatePromptText(_ text: String) {
        promptText = text
    }
    
    func applyTemplate(_ template: PromptTemplate) {
        promptText = template.prompt
        
        // Parse template to extract conditions
        Task {
            await parseTemplateIntoConditions(template)
        }
    }
    
    private func parseTemplateIntoConditions(_ template: PromptTemplate) async {
        // Use AI to parse the template and extract structured conditions
        // This is a simplified version - real implementation would use NLP
        
        if template.prompt.contains("RSI") {
            entryConditions.append(ConditionItem(
                type: .indicator,
                indicator: "RSI",
                comparison: template.prompt.contains("<") ? .lessThan : .greaterThan,
                value: 30
            ))
        }
        
        if template.prompt.contains("EMA") {
            entryConditions.append(ConditionItem(
                type: .indicator,
                indicator: "EMA",
                comparison: .crossAbove,
                value: 50
            ))
        }
    }
    
    // MARK: - Validation
    
    private func validatePrompt(_ text: String) async {
        guard !text.isEmpty else {
            validationResult = nil
            return
        }
        
        // Perform comprehensive validation
        var errors = [String]()
        var warnings = [String]()
        
        // Check for required elements
        if !text.contains("stop loss") && !text.contains("risk") {
            warnings.append("No stop loss or risk management specified")
        }
        
        if !text.contains("buy") && !text.contains("sell") && !text.contains("long") && !text.contains("short") {
            errors.append("No clear trade direction specified")
        }
        
        // Check for conflicting conditions
        if text.contains("buy") && text.contains("sell") && !text.contains("or") {
            errors.append("Conflicting trade directions without clear conditions")
        }
        
        // Validate indicators mentioned
        let indicators = extractIndicators(from: text)
        for indicator in indicators {
            if !isValidIndicator(indicator) {
                warnings.append("Unknown indicator: \(indicator)")
            }
        }
        
        validationResult = PromptValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            suggestions: generateValidationSuggestions(for: text)
        )
    }
    
    private func extractIndicators(from text: String) -> [String] {
        let pattern = #"\b(RSI|MACD|EMA|SMA|BB|ATR|STOCH|ADX)\b"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
    }
    
    private func isValidIndicator(_ indicator: String) -> Bool {
        let validIndicators = ["RSI", "MACD", "EMA", "SMA", "BB", "ATR", "STOCH", "ADX", "BOLLINGER", "MA"]
        return validIndicators.contains(indicator.uppercased())
    }
    
    private func generateValidationSuggestions(for text: String) -> [String] {
        var suggestions = [String]()
        
        if !text.contains("timeframe") {
            suggestions.append("Consider specifying a timeframe (e.g., 1H, 4H, Daily)")
        }
        
        if !text.contains("session") && !text.contains("time") {
            suggestions.append("Add trading session restrictions for better results")
        }
        
        if text.contains("scalp") && !text.contains("spread") {
            suggestions.append("For scalping, consider mentioning maximum spread conditions")
        }
        
        return suggestions
    }
    
    // MARK: - AI Suggestions
    
    private func generateSuggestions(for text: String) async {
        guard text.count > 20 else {
            suggestions = []
            return
        }
        
        // Generate contextual suggestions based on current prompt
        let baseSuggestions = [
            "Add a trailing stop loss to protect profits",
            "Include volume confirmation for stronger signals",
            "Consider adding a time-based exit after X hours",
            "Add correlation check with market index",
            "Include volatility filter using ATR"
        ]
        
        // Filter suggestions based on what's already in the prompt
        suggestions = baseSuggestions.filter { suggestion in
            !text.lowercased().contains(suggestion.lowercased().prefix(10))
        }.prefix(3).map { String($0) }
    }
    
    // MARK: - Execution
    
    func savePrompt() async {
        let result = await promptEngine.createPrompt(
            userId: "current-user", // Get from auth service
            title: generateTitle(from: promptText),
            promptText: promptText
        )
        
        switch result {
        case .success(let prompt):
            print("Saved prompt: \(prompt.id)")
            clearDraft()
        case .failure(let error):
            print("Failed to save prompt: \(error)")
        }
    }
    
    func executePrompt() async {
        // First save the prompt
        let result = await promptEngine.createPrompt(
            userId: "current-user",
            title: generateTitle(from: promptText),
            promptText: promptText
        )
        
        switch result {
        case .success(let prompt):
            // Activate the prompt for immediate execution
            promptEngine.activatePrompt(prompt.id)
            
            // Start the engine if not running
            if !promptEngine.isEngineRunning {
                promptEngine.startEngine()
            }
            
            executionResult = ExecutionResult(
                success: true,
                promptId: prompt.id,
                message: "Strategy activated and monitoring markets"
            )
            
            // Generate sample MQL5 code
            generatedCode = generateMQL5Code(from: promptText)
            
        case .failure(let error):
            executionResult = ExecutionResult(
                success: false,
                promptId: nil,
                message: error.localizedDescription
            )
        }
    }
    
    // MARK: - Context Updates
    
    func updateRiskPerTrade(_ value: Double) {
        context.riskPerTrade = value
        saveDraft()
    }
    
    func updateMaxOpenTrades(_ value: Int) {
        context.maxOpenTrades = value
        saveDraft()
    }
    
    func updateAllowedSymbols(_ symbols: [String]) {
        context.allowedSymbols = symbols
        saveDraft()
    }
    
    func updateExcludeNews(_ exclude: Bool) {
        var restrictions = context.timeRestrictions ?? TimeRestrictions(
            allowedHours: Array(0...23),
            allowedDaysOfWeek: Array(1...7),
            excludeNewsEvents: false,
            excludeMarketOpen: false,
            excludeMarketClose: false
        )
        restrictions.excludeNewsEvents = exclude
        context.timeRestrictions = restrictions
        saveDraft()
    }
    
    func updateExcludeMarketOpenClose(_ exclude: Bool) {
        var restrictions = context.timeRestrictions ?? TimeRestrictions(
            allowedHours: Array(0...23),
            allowedDaysOfWeek: Array(1...7),
            excludeNewsEvents: false,
            excludeMarketOpen: false,
            excludeMarketClose: false
        )
        restrictions.excludeMarketOpen = exclude
        restrictions.excludeMarketClose = exclude
        context.timeRestrictions = restrictions
        saveDraft()
    }
    
    private func updateContextFromConditions(entry: [ConditionItem], exit: [ConditionItem]) {
        // Convert visual conditions to context conditions
        context.conditions = entry.map { item in
            TradingCondition(
                type: .custom,
                parameters: [
                    "indicator": item.indicator,
                    "comparison": item.comparison.rawValue,
                    "value": String(item.value)
                ],
                operator: .and
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateTitle(from prompt: String) -> String {
        // Extract key elements for title
        let words = prompt.split(separator: " ").prefix(5)
        if words.isEmpty {
            return "Trading Strategy"
        }
        
        // Look for key indicators or patterns
        if prompt.contains("scalp") {
            return "Scalping Strategy"
        } else if prompt.contains("trend") {
            return "Trend Following Strategy"
        } else if prompt.contains("support") || prompt.contains("resistance") {
            return "Support/Resistance Strategy"
        } else if let indicator = extractIndicators(from: prompt).first {
            return "\(indicator) Strategy"
        }
        
        return words.joined(separator: " ").capitalized
    }
    
    private func regeneratePromptFromAllSources() {
        // Combine all sources of information into a coherent prompt
        var components = [String]()
        
        // Add base prompt
        if !promptText.isEmpty {
            components.append(promptText)
        }
        
        // Add visual builder conditions
        if !entryConditions.isEmpty {
            let entryText = "Entry conditions: " + entryConditions.map { $0.description }.joined(separator: " AND ")
            components.append(entryText)
        }
        
        if !exitConditions.isEmpty {
            let exitText = "Exit conditions: " + exitConditions.map { $0.description }.joined(separator: " OR ")
            components.append(exitText)
        }
        
        // Add context information
        components.append("Risk \(context.riskPerTrade * 100)% per trade")
        components.append("Maximum \(context.maxOpenTrades) open trades")
        
        promptText = components.joined(separator: ". ")
    }
    
    // MARK: - Persistence
    
    private func saveDraft() {
        // Save current state to UserDefaults
        let draft = PromptDraft(
            promptText: promptText,
            context: context,
            entryConditions: entryConditions,
            exitConditions: exitConditions
        )
        
        if let encoded = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(encoded, forKey: "prompt_builder_draft")
        }
    }
    
    private func loadSavedDraft() {
        guard let data = UserDefaults.standard.data(forKey: "prompt_builder_draft"),
              let draft = try? JSONDecoder().decode(PromptDraft.self, from: data) else {
            return
        }
        
        promptText = draft.promptText
        context = draft.context
        entryConditions = draft.entryConditions
        exitConditions = draft.exitConditions
    }
    
    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: "prompt_builder_draft")
    }
    
    private func generateMQL5Code(from prompt: String) -> String {
        // This is a simplified code generation - in production, use AI service
        return """
        //+------------------------------------------------------------------+
        //|                           AI Generated Strategy                    |
        //|                           Generated by PipFlow AI                  |
        //+------------------------------------------------------------------+
        
        input double RiskPercent = \(context.riskPerTrade * 100);
        input int MaxOpenTrades = \(context.maxOpenTrades);
        input double StopLoss = 20.0;
        input double TakeProfit = 40.0;
        
        // Global variables
        datetime lastTradeTime = 0;
        int totalOpenTrades = 0;
        
        //+------------------------------------------------------------------+
        //| Expert initialization function                                   |
        //+------------------------------------------------------------------+
        int OnInit()
        {
            Print("AI Strategy initialized: \(generateTitle(from: prompt))");
            return(INIT_SUCCEEDED);
        }
        
        //+------------------------------------------------------------------+
        //| Expert tick function                                             |
        //+------------------------------------------------------------------+
        void OnTick()
        {
            // Check if we can open new trades
            if(totalOpenTrades >= MaxOpenTrades) return;
            
            // Get current market data
            double rsi = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE, 0);
            double ema20 = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
            double ema50 = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
            
            // Entry conditions from prompt
            bool buySignal = false;
            bool sellSignal = false;
            
            // Parse prompt for conditions
            if(StringFind(prompt, "RSI") >= 0 && StringFind(prompt, "30") >= 0)
            {
                buySignal = rsi < 30;
            }
            
            if(StringFind(prompt, "RSI") >= 0 && StringFind(prompt, "70") >= 0)
            {
                sellSignal = rsi > 70;
            }
            
            // Execute trades
            if(buySignal && TimeCurrent() - lastTradeTime > 300)
            {
                double lotSize = CalculateLotSize();
                int ticket = OrderSend(_Symbol, OP_BUY, lotSize, Ask, 3,
                                     Ask - StopLoss * _Point * 10,
                                     Ask + TakeProfit * _Point * 10,
                                     "AI Strategy", 0, 0, clrGreen);
                
                if(ticket > 0)
                {
                    lastTradeTime = TimeCurrent();
                    totalOpenTrades++;
                }
            }
            
            if(sellSignal && TimeCurrent() - lastTradeTime > 300)
            {
                double lotSize = CalculateLotSize();
                int ticket = OrderSend(_Symbol, OP_SELL, lotSize, Bid, 3,
                                     Bid + StopLoss * _Point * 10,
                                     Bid - TakeProfit * _Point * 10,
                                     "AI Strategy", 0, 0, clrRed);
                
                if(ticket > 0)
                {
                    lastTradeTime = TimeCurrent();
                    totalOpenTrades++;
                }
            }
        }
        
        //+------------------------------------------------------------------+
        //| Calculate lot size based on risk                                |
        //+------------------------------------------------------------------+
        double CalculateLotSize()
        {
            double accountBalance = AccountBalance();
            double riskAmount = accountBalance * RiskPercent / 100.0;
            double pipValue = MarketInfo(_Symbol, MODE_TICKVALUE);
            double lotSize = riskAmount / (StopLoss * pipValue);
            
            // Normalize lot size
            double minLot = MarketInfo(_Symbol, MODE_MINLOT);
            double maxLot = MarketInfo(_Symbol, MODE_MAXLOT);
            double lotStep = MarketInfo(_Symbol, MODE_LOTSTEP);
            
            lotSize = MathMax(minLot, MathMin(maxLot, NormalizeDouble(lotSize / lotStep, 0) * lotStep));
            
            return lotSize;
        }
        """
    }
}

// MARK: - Supporting Types

struct PromptValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
    let suggestions: [String]
}

struct ExecutionResult {
    let success: Bool
    let promptId: String?
    let message: String
}

struct ImageAnalysis {
    let detectedPattern: String?
    let supportLevels: [Double]
    let resistanceLevels: [Double]
    let trendDirection: String?
    let indicators: [String: Double]
}

struct ConditionItem: Identifiable, Codable {
    let id = UUID()
    var type: ConditionType
    var indicator: String
    var comparison: ComparisonOperator
    var value: Double
    
    var description: String {
        "\(indicator) \(comparison.symbol) \(value)"
    }
    
    enum ConditionType: String, Codable {
        case indicator
        case priceAction
        case volume
        case time
    }
    
    enum ComparisonOperator: String, Codable {
        case greaterThan = ">"
        case lessThan = "<"
        case equals = "="
        case crossAbove = "crosses above"
        case crossBelow = "crosses below"
        
        var symbol: String {
            switch self {
            case .greaterThan: return ">"
            case .lessThan: return "<"
            case .equals: return "="
            case .crossAbove: return "↗"
            case .crossBelow: return "↘"
            }
        }
    }
}

struct PromptDraft: Codable {
    let promptText: String
    let context: TradingContext
    let entryConditions: [ConditionItem]
    let exitConditions: [ConditionItem]
}

// MARK: - Chart Image Analyzer

class ChartImageAnalyzer {
    func analyzeChart(_ image: UIImage) async throws -> ImageAnalysis {
        // In a real implementation, this would use Vision framework or ML models
        // For now, return mock analysis
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate processing
        
        return ImageAnalysis(
            detectedPattern: ["Head and Shoulders", "Double Top", "Triangle", "Flag"].randomElement(),
            supportLevels: [1.0820, 1.0800, 1.0780],
            resistanceLevels: [1.0880, 1.0900, 1.0920],
            trendDirection: ["Bullish", "Bearish", "Sideways"].randomElement(),
            indicators: [
                "RSI": Double.random(in: 20...80),
                "MACD": Double.random(in: -0.01...0.01)
            ]
        )
    }
}