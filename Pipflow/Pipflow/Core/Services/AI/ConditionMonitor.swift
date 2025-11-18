//
//  ConditionMonitor.swift
//  Pipflow
//
//  Real-time monitoring of trading conditions and user-defined criteria
//

import Foundation
import Combine
import SwiftUI

// MARK: - Condition Monitoring Models

struct ConditionStatus: Identifiable {
    let id = UUID()
    let conditionId: String
    let promptId: String
    let name: String
    let currentValue: Double?
    let targetValue: Double
    let `operator`: ComparisonOperator
    let isMet: Bool
    let lastChecked: Date
    let metSince: Date?
    let metDuration: TimeInterval?
    
    enum ComparisonOperator: String, CaseIterable {
        case greaterThan = ">"
        case lessThan = "<"
        case equals = "="
        case greaterThanOrEqual = ">="
        case lessThanOrEqual = "<="
        case between = "between"
        case outside = "outside"
        case crossesAbove = "crosses above"
        case crossesBelow = "crosses below"
    }
}

struct IndicatorStatus: Identifiable {
    let id = UUID()
    let indicatorId: String
    let promptId: String
    let type: TechnicalIndicator.IndicatorType
    let symbol: String
    let currentValue: Double
    let conditionValue: Double
    let condition: TechnicalIndicator.IndicatorCondition
    let isMet: Bool
    let strength: Double // 0.0 to 1.0
    let lastUpdated: Date
    let history: [IndicatorDataPoint]
}

struct IndicatorDataPoint {
    let timestamp: Date
    let value: Double
    let isMet: Bool
}

struct AlertTrigger: Identifiable {
    let id = UUID()
    let promptId: String
    let conditionName: String
    let message: String
    let priority: AlertPriority
    let timestamp: Date
    let actionRequired: Bool
    
    enum AlertPriority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            case .critical: return .purple
            }
        }
    }
}

// MARK: - Condition Monitor

@MainActor
class ConditionMonitor: ObservableObject {
    static let shared = ConditionMonitor()
    
    @Published var conditionStatuses: [String: [ConditionStatus]] = [:] // promptId: [conditions]
    @Published var indicatorStatuses: [String: [IndicatorStatus]] = [:] // promptId: [indicators]
    @Published var alertTriggers: [AlertTrigger] = []
    @Published var isMonitoring: Bool = false
    @Published var lastUpdateTime: Date = Date()
    
    private let marketDataService = MarketDataService.shared
    private let technicalAnalyzer = TechnicalAnalyzer()
    private let alertManager = AlertManager()
    
    private var monitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var previousValues: [String: Double] = [:] // For cross detection
    
    private init() {
        setupMarketDataBinding()
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        startMonitoringTimer()
        print("🔍 Condition Monitor started")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("⏹️ Condition Monitor stopped")
    }
    
    private func setupMarketDataBinding() {
        // Monitor market data changes
        marketDataService.$marketData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.isMonitoring == true {
                    Task { await self?.updateAllConditions() }
                }
            }
            .store(in: &cancellables)
    }
    
    private func startMonitoringTimer() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateAllConditions()
                self?.lastUpdateTime = Date()
            }
        }
    }
    
    // MARK: - Condition Management
    
    func addConditionsForPrompt(_ promptId: String, conditions: [TradingCondition]) async {
        var statuses: [ConditionStatus] = []
        
        for (index, condition) in conditions.enumerated() {
            let status = ConditionStatus(
                conditionId: "\(promptId)_condition_\(index)",
                promptId: promptId,
                name: condition.type.rawValue,
                currentValue: nil,
                targetValue: extractTargetValue(from: condition),
                `operator`: extractOperator(from: condition),
                isMet: false,
                lastChecked: Date(),
                metSince: nil,
                metDuration: nil
            )
            statuses.append(status)
        }
        
        conditionStatuses[promptId] = statuses
        print("✅ Added \(conditions.count) conditions for prompt: \(promptId)")
    }
    
    func addIndicatorsForPrompt(_ promptId: String, indicators: [TechnicalIndicator], symbols: [String]) async {
        var statuses: [IndicatorStatus] = []
        
        for indicator in indicators {
            for symbol in symbols {
                let status = IndicatorStatus(
                    indicatorId: "\(promptId)_\(indicator.type.rawValue)_\(symbol)",
                    promptId: promptId,
                    type: indicator.type,
                    symbol: symbol,
                    currentValue: 0.0,
                    conditionValue: extractConditionValue(from: indicator),
                    condition: indicator.condition,
                    isMet: false,
                    strength: 0.0,
                    lastUpdated: Date(),
                    history: []
                )
                statuses.append(status)
            }
        }
        
        indicatorStatuses[promptId] = statuses
        print("✅ Added \(statuses.count) indicators for prompt: \(promptId)")
    }
    
    func removeConditionsForPrompt(_ promptId: String) {
        conditionStatuses.removeValue(forKey: promptId)
        indicatorStatuses.removeValue(forKey: promptId)
        alertTriggers.removeAll { $0.promptId == promptId }
        print("🗑️ Removed conditions for prompt: \(promptId)")
    }
    
    // MARK: - Real-time Updates
    
    private func updateAllConditions() async {
        for promptId in Set(Array(conditionStatuses.keys) + Array(indicatorStatuses.keys)) {
            await updateConditionsForPrompt(promptId)
        }
    }
    
    private func updateConditionsForPrompt(_ promptId: String) async {
        // Update trading conditions
        if var conditions = conditionStatuses[promptId] {
            for (index, condition) in conditions.enumerated() {
                conditions[index] = await updateConditionStatus(condition)
            }
            conditionStatuses[promptId] = conditions
        }
        
        // Update indicator conditions
        if var indicators = indicatorStatuses[promptId] {
            for (index, indicator) in indicators.enumerated() {
                indicators[index] = await updateIndicatorStatus(indicator)
            }
            indicatorStatuses[promptId] = indicators
        }
        
        // Check for alerts
        await checkForAlerts(promptId)
    }
    
    private func updateConditionStatus(_ status: ConditionStatus) async -> ConditionStatus {
        let currentValue = await getCurrentValue(for: status)
        let wasMet = status.isMet
        let isMet = evaluateCondition(currentValue: currentValue, targetValue: status.targetValue, comparisonOperator: status.`operator`)
        
        var metSince = status.metSince
        var metDuration = status.metDuration
        
        if isMet && !wasMet {
            // Condition just became true
            metSince = Date()
            metDuration = 0
        } else if isMet && wasMet {
            // Condition remains true
            if let since = metSince {
                metDuration = Date().timeIntervalSince(since)
            }
        } else if !isMet && wasMet {
            // Condition just became false
            metSince = nil
            metDuration = nil
        }
        
        return ConditionStatus(
            conditionId: status.conditionId,
            promptId: status.promptId,
            name: status.name,
            currentValue: currentValue,
            targetValue: status.targetValue,
            `operator`: status.`operator`,
            isMet: isMet,
            lastChecked: Date(),
            metSince: metSince,
            metDuration: metDuration
        )
    }
    
    private func updateIndicatorStatus(_ status: IndicatorStatus) async -> IndicatorStatus {
        let newValue = await calculateIndicatorValue(status.type, symbol: status.symbol)
        let wasMet = status.isMet
        let isMet = evaluateIndicatorCondition(
            current: newValue,
            target: status.conditionValue,
            condition: status.condition,
            previousValue: getPreviousIndicatorValue(status.indicatorId)
        )
        
        // Calculate strength (how strongly the condition is met)
        let strength = calculateIndicatorStrength(
            current: newValue,
            target: status.conditionValue,
            condition: status.condition
        )
        
        // Update history
        var history = status.history
        let dataPoint = IndicatorDataPoint(timestamp: Date(), value: newValue, isMet: isMet)
        history.append(dataPoint)
        
        // Keep only last 100 data points
        if history.count > 100 {
            history = Array(history.suffix(100))
        }
        
        // Store for cross detection
        previousValues[status.indicatorId] = newValue
        
        return IndicatorStatus(
            indicatorId: status.indicatorId,
            promptId: status.promptId,
            type: status.type,
            symbol: status.symbol,
            currentValue: newValue,
            conditionValue: status.conditionValue,
            condition: status.condition,
            isMet: isMet,
            strength: strength,
            lastUpdated: Date(),
            history: history
        )
    }
    
    // MARK: - Condition Evaluation
    
    private func evaluateCondition(currentValue: Double?, targetValue: Double, comparisonOperator: ConditionStatus.ComparisonOperator) -> Bool {
        guard let current = currentValue else { return false }
        
        switch comparisonOperator {
        case .greaterThan:
            return current > targetValue
        case .lessThan:
            return current < targetValue
        case .equals:
            return abs(current - targetValue) < 0.0001
        case .greaterThanOrEqual:
            return current >= targetValue
        case .lessThanOrEqual:
            return current <= targetValue
        case .between:
            // For between, targetValue would need to be encoded differently
            return false
        case .outside:
            return false
        case .crossesAbove, .crossesBelow:
            return false // These need special handling with previous values
        }
    }
    
    private func evaluateIndicatorCondition(
        current: Double,
        target: Double,
        condition: TechnicalIndicator.IndicatorCondition,
        previousValue: Double?
    ) -> Bool {
        switch condition {
        case .above:
            return current > target
        case .below:
            return current < target
        case .crossesAbove:
            guard let previous = previousValue else { return false }
            return previous <= target && current > target
        case .crossesBelow:
            guard let previous = previousValue else { return false }
            return previous >= target && current < target
        case .between:
            return false // Would need range values
        case .outside:
            return false // Would need range values
        }
    }
    
    private func calculateIndicatorStrength(current: Double, target: Double, condition: TechnicalIndicator.IndicatorCondition) -> Double {
        switch condition {
        case .above:
            return min(1.0, max(0.0, (current - target) / target))
        case .below:
            return min(1.0, max(0.0, (target - current) / target))
        case .crossesAbove, .crossesBelow:
            return 1.0 // Binary condition
        case .between, .outside:
            return 0.5 // Default
        }
    }
    
    // MARK: - Value Calculation
    
    private func getCurrentValue(for status: ConditionStatus) async -> Double? {
        switch status.name.lowercased() {
        case "price_action":
            return await getCurrentPrice(symbol: "EURUSD") // Default symbol
        case "volume_spike":
            return await getCurrentVolume(symbol: "EURUSD")
        case "time_of_day":
            return Double(Calendar.current.component(.hour, from: Date()))
        default:
            return nil
        }
    }
    
    private func calculateIndicatorValue(_ type: TechnicalIndicator.IndicatorType, symbol: String) async -> Double {
        switch type {
        case .rsi:
            return await technicalAnalyzer.calculateRSI(symbol: symbol, period: 14)
        case .macd:
            return await technicalAnalyzer.calculateMACD(symbol: symbol).macd
        case .movingAverage:
            return await technicalAnalyzer.calculateSMA(symbol: symbol, period: 20)
        case .bollingerBands:
            return await technicalAnalyzer.calculateBollingerBands(symbol: symbol).middle
        case .stochastic:
            return await technicalAnalyzer.calculateStochastic(symbol: symbol).k
        case .atr:
            return await technicalAnalyzer.calculateATR(symbol: symbol, period: 14)
        case .support:
            return await technicalAnalyzer.findSupport(symbol: symbol)
        case .resistance:
            return await technicalAnalyzer.findResistance(symbol: symbol)
        }
    }
    
    private func getCurrentPrice(symbol: String) async -> Double {
        return marketDataService.marketData[symbol]?.marketData.ask ?? 0.0
    }
    
    private func getCurrentVolume(symbol: String) async -> Double {
        // This would get volume data from market service
        return 1000.0 // Placeholder
    }
    
    private func getPreviousIndicatorValue(_ indicatorId: String) -> Double? {
        return previousValues[indicatorId]
    }
    
    // MARK: - Alert Management
    
    private func checkForAlerts(_ promptId: String) async {
        let conditions = conditionStatuses[promptId] ?? []
        let indicators = indicatorStatuses[promptId] ?? []
        
        // Check for newly met conditions
        for condition in conditions where condition.isMet {
            if condition.metSince != nil && condition.metDuration ?? 0 < 5 { // Recently met
                let alert = AlertTrigger(
                    promptId: promptId,
                    conditionName: condition.name,
                    message: "Condition '\(condition.name)' is now met",
                    priority: .medium,
                    timestamp: Date(),
                    actionRequired: true
                )
                addAlert(alert)
            }
        }
        
        // Check for indicator signals
        for indicator in indicators where indicator.isMet && indicator.strength > 0.8 {
            let alert = AlertTrigger(
                promptId: promptId,
                conditionName: "\(indicator.type.rawValue) - \(indicator.symbol)",
                message: "\(indicator.type.rawValue) signal triggered for \(indicator.symbol)",
                priority: .high,
                timestamp: Date(),
                actionRequired: true
            )
            addAlert(alert)
        }
    }
    
    private func addAlert(_ alert: AlertTrigger) {
        // Avoid duplicate alerts
        let isDuplicate = alertTriggers.contains { existing in
            existing.promptId == alert.promptId &&
            existing.conditionName == alert.conditionName &&
            Date().timeIntervalSince(existing.timestamp) < 60 // Within last minute
        }
        
        if !isDuplicate {
            alertTriggers.insert(alert, at: 0)
            
            // Keep only last 50 alerts
            if alertTriggers.count > 50 {
                alertTriggers = Array(alertTriggers.prefix(50))
            }
            
            // Notify alert manager
            alertManager.handleAlert(alert)
            
            print("🚨 Alert: \(alert.message)")
        }
    }
    
    func dismissAlert(_ alertId: UUID) {
        alertTriggers.removeAll { $0.id == alertId }
    }
    
    func clearAllAlerts() {
        alertTriggers.removeAll()
    }
    
    // MARK: - Public Query Methods
    
    func checkConditions(_ conditions: [TradingCondition]) async -> ConditionResult {
        // This is called by the main engine to check if all conditions are met
        var metConditions: [String] = []
        var unmetConditions: [String] = []
        
        for (index, condition) in conditions.enumerated() {
            let isConditionMet = await evaluateGenericCondition(condition)
            
            if isConditionMet {
                metConditions.append(condition.type.rawValue)
            } else {
                unmetConditions.append(condition.type.rawValue)
            }
        }
        
        return ConditionResult(
            allMet: unmetConditions.isEmpty,
            metConditions: metConditions,
            unmetConditions: unmetConditions
        )
    }
    
    func updateConditionStatus(for promptId: String, conditions: [TradingCondition]) async {
        await addConditionsForPrompt(promptId, conditions: conditions)
    }
    
    func getConditionSummary(for promptId: String) -> (total: Int, met: Int, pending: Int) {
        let conditions = conditionStatuses[promptId] ?? []
        let indicators = indicatorStatuses[promptId] ?? []
        
        let totalConditions = conditions.count + indicators.count
        let metConditions = conditions.filter(\.isMet).count + indicators.filter(\.isMet).count
        let pendingConditions = totalConditions - metConditions
        
        return (total: totalConditions, met: metConditions, pending: pendingConditions)
    }
    
    // MARK: - Helper Methods
    
    private func extractTargetValue(from condition: TradingCondition) -> Double {
        // Extract numeric values from condition parameters
        for (_, value) in condition.parameters {
            if let doubleValue = Double(value) {
                return doubleValue
            }
        }
        return 0.0
    }
    
    private func extractOperator(from condition: TradingCondition) -> ConditionStatus.ComparisonOperator {
        // Extract comparison operator from condition
        return .greaterThan // Default
    }
    
    private func extractConditionValue(from indicator: TechnicalIndicator) -> Double {
        return indicator.parameters["level"] ?? indicator.parameters["period"] ?? 50.0
    }
    
    private func evaluateGenericCondition(_ condition: TradingCondition) async -> Bool {
        // Generic condition evaluation for the main engine
        switch condition.type {
        case .timeOfDay:
            let currentHour = Calendar.current.component(.hour, from: Date())
            return currentHour >= 9 && currentHour <= 17 // Market hours
        case .volumeSpike:
            return await getCurrentVolume(symbol: "EURUSD") > 1500
        case .priceAction:
            return true // Would need more specific implementation
        case .newsEvent:
            return false // Would need news feed integration
        case .marketSentiment:
            return true // Would need sentiment analysis
        case .custom:
            return false // Would need custom evaluation logic
        }
    }
}

// MARK: - Technical Analyzer

class TechnicalAnalyzer {
    func calculateRSI(symbol: String, period: Int) async -> Double {
        // Mock RSI calculation
        return Double.random(in: 20...80)
    }
    
    func calculateMACD(symbol: String) async -> (macd: Double, signal: Double, histogram: Double) {
        return (
            macd: Double.random(in: -0.01...0.01),
            signal: Double.random(in: -0.01...0.01),
            histogram: Double.random(in: -0.005...0.005)
        )
    }
    
    func calculateSMA(symbol: String, period: Int) async -> Double {
        let currentPrice = await MarketDataService.shared.marketData[symbol]?.marketData.ask ?? 1.0
        return currentPrice * Double.random(in: 0.98...1.02)
    }
    
    func calculateBollingerBands(symbol: String) async -> (upper: Double, middle: Double, lower: Double) {
        let currentPrice = await MarketDataService.shared.marketData[symbol]?.marketData.ask ?? 1.0
        return (
            upper: currentPrice * 1.02,
            middle: currentPrice,
            lower: currentPrice * 0.98
        )
    }
    
    func calculateStochastic(symbol: String) async -> (k: Double, d: Double) {
        return (
            k: Double.random(in: 20...80),
            d: Double.random(in: 20...80)
        )
    }
    
    func calculateATR(symbol: String, period: Int) async -> Double {
        return Double.random(in: 0.0001...0.002)
    }
    
    func findSupport(symbol: String) async -> Double {
        let currentPrice = await MarketDataService.shared.marketData[symbol]?.marketData.ask ?? 1.0
        return currentPrice * Double.random(in: 0.95...0.99)
    }
    
    func findResistance(symbol: String) async -> Double {
        let currentPrice = await MarketDataService.shared.marketData[symbol]?.marketData.ask ?? 1.0
        return currentPrice * Double.random(in: 1.01...1.05)
    }
}

// MARK: - Alert Manager

class AlertManager {
    func handleAlert(_ alert: AlertTrigger) {
        // Handle different types of alerts
        switch alert.priority {
        case .critical:
            sendPushNotification(alert)
            sendEmailAlert(alert)
        case .high:
            sendPushNotification(alert)
        case .medium:
            sendInAppNotification(alert)
        case .low:
            logAlert(alert)
        }
    }
    
    private func sendPushNotification(_ alert: AlertTrigger) {
        // Send push notification
        print("📱 Push notification: \(alert.message)")
    }
    
    private func sendEmailAlert(_ alert: AlertTrigger) {
        // Send email alert
        print("📧 Email alert: \(alert.message)")
    }
    
    private func sendInAppNotification(_ alert: AlertTrigger) {
        // Send in-app notification
        print("🔔 In-app notification: \(alert.message)")
    }
    
    private func logAlert(_ alert: AlertTrigger) {
        // Log alert for later review
        print("📝 Logged alert: \(alert.message)")
    }
}