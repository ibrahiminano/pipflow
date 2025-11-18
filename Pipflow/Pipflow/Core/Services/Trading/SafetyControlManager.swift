//
//  SafetyControlManager.swift
//  Pipflow
//
//  Safety and control features for AI trading
//

import Foundation
import SwiftUI

// MARK: - Trade Action for Safety Checks
enum TradeAction: String, Codable {
    case buy
    case sell
}

// MARK: - Safety Control Models

struct SafetySettings: Codable {
    var isPaperTradingEnabled: Bool
    var dailyLossLimit: Double
    var maxDrawdownLimit: Double
    var requireApprovalAbove: Double
    var emergencyStopEnabled: Bool
    var anomalyDetectionEnabled: Bool
    var sandboxModeEnabled: Bool
    var maxOpenPositions: Int
    var maxLeverageAllowed: Double
    var restrictedTimeframes: [Timeframe]
    var blacklistedSymbols: [String]
    var whitelistedSymbols: [String]
    var allowedTradingHours: TradingHours
}

struct TradingHours: Codable {
    var monday: DaySchedule?
    var tuesday: DaySchedule?
    var wednesday: DaySchedule?
    var thursday: DaySchedule?
    var friday: DaySchedule?
    var saturday: DaySchedule?
    var sunday: DaySchedule?
}

struct DaySchedule: Codable {
    let startTime: String // "09:00"
    let endTime: String   // "17:00"
    let isEnabled: Bool
}

struct SafetyAlert: Identifiable {
    let id = UUID()
    let type: SafetyAlertType
    let severity: SafetyAlertSeverity
    let message: String
    let timestamp: Date
    let action: SafetyAction?
}

enum SafetyAlertType {
    case dailyLossLimit
    case drawdownLimit
    case anomalyDetected
    case unusualVolume
    case highLeverage
    case restrictedTime
    case blacklistedSymbol
    case emergencyStop
}

enum SafetyAlertSeverity {
    case info
    case warning
    case critical
    case emergency
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        case .emergency: return .purple
        }
    }
}

struct SafetyAction {
    let type: ActionType
    let description: String
    let execute: () -> Void
    
    enum ActionType {
        case pauseTrading
        case closeAllPositions
        case reducePositionSize
        case switchToPaperTrading
        case requireManualApproval
    }
}

struct TradingAnomalyReport: Identifiable {
    let id = UUID()
    let timestamp: Date
    let anomalyType: AnomalyType
    let confidence: Double
    let affectedTrades: [Trade]
    let description: String
    let recommendation: String
}

enum AnomalyType {
    case unusualTradeSize
    case abnormalFrequency
    case suspiciousPattern
    case deviationFromStrategy
    case technicalGlitch
}

struct ApprovalRequest: Identifiable {
    let id = UUID()
    let trade: TradeRequest
    let reason: String
    let riskScore: Double
    let timestamp: Date
    var status: ApprovalStatus = .pending
    var approvedBy: String?
    var approvedAt: Date?
    var notes: String?
}

enum ApprovalStatus {
    case pending
    case approved
    case rejected
    case expired
}

struct SafetyMetrics {
    let dailyPnL: Double
    let currentDrawdown: Double
    let openPositions: Int
    let currentLeverage: Double
    let anomaliesDetected: Int
    let safetyScore: Double
    let lastIncident: Date?
}

// MARK: - Safety Control Manager

@MainActor
class SafetyControlManager: ObservableObject {
    static let shared = SafetyControlManager()
    
    @Published var settings = SafetySettings(
        isPaperTradingEnabled: false,
        dailyLossLimit: 500,
        maxDrawdownLimit: 0.1, // 10%
        requireApprovalAbove: 10000,
        emergencyStopEnabled: true,
        anomalyDetectionEnabled: true,
        sandboxModeEnabled: false,
        maxOpenPositions: 10,
        maxLeverageAllowed: 10,
        restrictedTimeframes: [],
        blacklistedSymbols: [],
        whitelistedSymbols: [],
        allowedTradingHours: TradingHours()
    )
    
    // Computed property for binding
    var isPaperTradingEnabled: Binding<Bool> {
        Binding(
            get: { self.settings.isPaperTradingEnabled },
            set: { self.settings.isPaperTradingEnabled = $0 }
        )
    }
    
    @Published var currentAlerts: [SafetyAlert] = []
    @Published var pendingApprovals: [ApprovalRequest] = []
    @Published var anomalyReports: [TradingAnomalyReport] = []
    @Published var safetyMetrics = SafetyMetrics(
        dailyPnL: 0,
        currentDrawdown: 0,
        openPositions: 0,
        currentLeverage: 0,
        anomaliesDetected: 0,
        safetyScore: 100,
        lastIncident: nil
    )
    
    @Published var isEmergencyStopActive = false
    @Published var tradingPaused = false
    
    private var dailyPnL: Double = 0
    private var sessionStartEquity: Double = 0
    private var peakEquity: Double = 0
    private var monitoringTimer: Timer?
    
    // MARK: - Public Methods
    
    func validateTrade(_ request: TradeRequest) async throws -> ValidationResult {
        // Check emergency stop
        if isEmergencyStopActive {
            throw SafetyError.emergencyStopActive
        }
        
        // Check if trading is paused
        if tradingPaused {
            throw SafetyError.tradingPaused
        }
        
        // Check paper trading mode
        if settings.isPaperTradingEnabled {
            return ValidationResult(
                isValid: true,
                isPaperTrade: true,
                warnings: ["Trade will be executed in paper trading mode"]
            )
        }
        
        // Perform safety checks
        var warnings: [String] = []
        var requiresApproval = false
        
        // 1. Check daily loss limit
        if dailyPnL < -settings.dailyLossLimit {
            throw SafetyError.dailyLossLimitExceeded
        }
        
        // 2. Check position size approval threshold
        let positionValue = request.volume * 100000 * (request.price ?? 0)
        if positionValue > settings.requireApprovalAbove {
            requiresApproval = true
            warnings.append("Trade requires manual approval (size: $\(Int(positionValue)))")
        }
        
        // 3. Check max open positions
        if safetyMetrics.openPositions >= settings.maxOpenPositions {
            throw SafetyError.maxPositionsExceeded
        }
        
        // 4. Check leverage
        let currentLeverage = calculateLeverage(additionalPosition: positionValue)
        if currentLeverage > settings.maxLeverageAllowed {
            throw SafetyError.leverageLimitExceeded
        }
        
        // 5. Check trading hours
        if !isWithinTradingHours() {
            throw SafetyError.outsideTradingHours
        }
        
        // 6. Check symbol restrictions
        if settings.blacklistedSymbols.contains(request.symbol) {
            throw SafetyError.blacklistedSymbol(request.symbol)
        }
        
        if !settings.whitelistedSymbols.isEmpty && !settings.whitelistedSymbols.contains(request.symbol) {
            throw SafetyError.notWhitelisted(request.symbol)
        }
        
        // 7. Run anomaly detection
        if settings.anomalyDetectionEnabled {
            let anomaly = await detectTradeAnomaly(request)
            if let anomaly = anomaly {
                warnings.append("Anomaly detected: \(anomaly.description)")
                
                if anomaly.confidence > 0.8 {
                    requiresApproval = true
                }
            }
        }
        
        // Create approval request if needed
        if requiresApproval {
            let approvalRequest = ApprovalRequest(
                trade: request,
                reason: warnings.joined(separator: "; "),
                riskScore: calculateRiskScore(request),
                timestamp: Date()
            )
            
            pendingApprovals.append(approvalRequest)
            
            // Wait for approval (timeout after 60 seconds)
            let approved = await waitForApproval(approvalRequest.id, timeout: 60)
            
            if !approved {
                throw SafetyError.approvalTimeout
            }
        }
        
        return ValidationResult(
            isValid: true,
            isPaperTrade: false,
            warnings: warnings
        )
    }
    
    func activateEmergencyStop() {
        isEmergencyStopActive = true
        tradingPaused = true
        
        // Create emergency alert
        let alert = SafetyAlert(
            type: .emergencyStop,
            severity: .emergency,
            message: "Emergency stop activated - All trading halted",
            timestamp: Date(),
            action: SafetyAction(
                type: .closeAllPositions,
                description: "Close all open positions",
                execute: { [weak self] in
                    self?.closeAllPositions()
                }
            )
        )
        
        currentAlerts.append(alert)
        
        // Notify user
        NotificationManager.shared.sendEmergencyNotification(
            title: "Emergency Stop Activated",
            body: "All trading has been halted. Review positions immediately."
        )
    }
    
    func deactivateEmergencyStop() {
        isEmergencyStopActive = false
        
        // Don't automatically resume trading - require manual confirmation
        showResumeConfirmation()
    }
    
    func pauseTrading(reason: String) {
        tradingPaused = true
        
        let alert = SafetyAlert(
            type: .emergencyStop,
            severity: .warning,
            message: "Trading paused: \(reason)",
            timestamp: Date(),
            action: nil
        )
        
        currentAlerts.append(alert)
    }
    
    func resumeTrading() {
        tradingPaused = false
        
        // Clear non-critical alerts
        currentAlerts.removeAll { $0.severity != .critical && $0.severity != .emergency }
    }
    
    func updateDailyPnL(_ pnl: Double) {
        dailyPnL = pnl
        
        // Check daily loss limit
        if dailyPnL <= -settings.dailyLossLimit {
            let alert = SafetyAlert(
                type: .dailyLossLimit,
                severity: .critical,
                message: "Daily loss limit reached: $\(Int(dailyPnL))",
                timestamp: Date(),
                action: SafetyAction(
                    type: .pauseTrading,
                    description: "Pause all trading",
                    execute: { [weak self] in
                        self?.pauseTrading(reason: "Daily loss limit exceeded")
                    }
                )
            )
            
            currentAlerts.append(alert)
            
            // Auto-pause if enabled
            if settings.emergencyStopEnabled {
                pauseTrading(reason: "Daily loss limit exceeded")
            }
        } else if dailyPnL <= -settings.dailyLossLimit * 0.8 {
            // Warning at 80% of limit
            let alert = SafetyAlert(
                type: .dailyLossLimit,
                severity: .warning,
                message: "Approaching daily loss limit: $\(Int(dailyPnL)) of $\(Int(settings.dailyLossLimit))",
                timestamp: Date(),
                action: nil
            )
            
            currentAlerts.append(alert)
        }
    }
    
    func updateDrawdown(_ equity: Double) {
        if equity > peakEquity {
            peakEquity = equity
        }
        
        let drawdown = (peakEquity - equity) / peakEquity
        
        // Check drawdown limit
        if drawdown >= settings.maxDrawdownLimit {
            let alert = SafetyAlert(
                type: .drawdownLimit,
                severity: .critical,
                message: String(format: "Max drawdown reached: %.1f%%", drawdown * 100),
                timestamp: Date(),
                action: SafetyAction(
                    type: .pauseTrading,
                    description: "Pause all trading",
                    execute: { [weak self] in
                        self?.pauseTrading(reason: "Max drawdown exceeded")
                    }
                )
            )
            
            currentAlerts.append(alert)
            
            if settings.emergencyStopEnabled {
                pauseTrading(reason: "Max drawdown exceeded")
            }
        }
        
        // Update metrics
        safetyMetrics = SafetyMetrics(
            dailyPnL: dailyPnL,
            currentDrawdown: drawdown,
            openPositions: safetyMetrics.openPositions,
            currentLeverage: safetyMetrics.currentLeverage,
            anomaliesDetected: safetyMetrics.anomaliesDetected,
            safetyScore: calculateSafetyScore(),
            lastIncident: safetyMetrics.lastIncident
        )
    }
    
    func approveTrade(_ requestId: UUID, notes: String? = nil) {
        if let index = pendingApprovals.firstIndex(where: { $0.id == requestId }) {
            pendingApprovals[index].status = .approved
            pendingApprovals[index].approvedBy = "User"
            pendingApprovals[index].approvedAt = Date()
            pendingApprovals[index].notes = notes
        }
    }
    
    func rejectTrade(_ requestId: UUID, reason: String) {
        if let index = pendingApprovals.firstIndex(where: { $0.id == requestId }) {
            pendingApprovals[index].status = .rejected
            pendingApprovals[index].notes = reason
        }
    }
    
    func startSafetyMonitoring() {
        stopSafetyMonitoring()
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            Task {
                await self.performSafetyCheck()
            }
        }
        
        // Initialize session
        sessionStartEquity = getCurrentEquity()
        peakEquity = sessionStartEquity
    }
    
    func stopSafetyMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - Private Methods
    
    private func detectTradeAnomaly(_ request: TradeRequest) async -> TradingAnomalyReport? {
        // Simplified anomaly detection
        let recentTrades = getRecentTrades()
        
        // Check for unusual trade size
        let avgSize = recentTrades.map { Double(String(describing: $0.volume)) ?? 0 }.reduce(0, +) / Double(max(recentTrades.count, 1))
        if request.volume > avgSize * 3 {
            return TradingAnomalyReport(
                timestamp: Date(),
                anomalyType: .unusualTradeSize,
                confidence: min((request.volume / avgSize - 1) / 5, 1.0),
                affectedTrades: [],
                description: "Trade size is \(String(format: "%.1fx", request.volume / avgSize)) larger than average",
                recommendation: "Consider reducing position size or splitting the trade"
            )
        }
        
        // Check for abnormal frequency
        let recentTradeCount = recentTrades.filter { 
            Date().timeIntervalSince($0.openTime) < 300 // Last 5 minutes
        }.count
        
        if recentTradeCount > 10 {
            return TradingAnomalyReport(
                timestamp: Date(),
                anomalyType: .abnormalFrequency,
                confidence: min(Double(recentTradeCount) / 20, 1.0),
                affectedTrades: recentTrades,
                description: "\(recentTradeCount) trades in last 5 minutes",
                recommendation: "Review trading frequency - possible overtrading"
            )
        }
        
        return nil
    }
    
    private func waitForApproval(_ requestId: UUID, timeout: TimeInterval) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if let request = pendingApprovals.first(where: { $0.id == requestId }) {
                switch request.status {
                case .approved:
                    return true
                case .rejected, .expired:
                    return false
                case .pending:
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
            } else {
                return false
            }
        }
        
        // Timeout - mark as expired
        if let index = pendingApprovals.firstIndex(where: { $0.id == requestId }) {
            pendingApprovals[index].status = .expired
        }
        
        return false
    }
    
    private func calculateLeverage(additionalPosition: Double = 0) -> Double {
        let totalPositionValue = getCurrentPositionValue() + additionalPosition
        let equity = getCurrentEquity()
        return equity > 0 ? totalPositionValue / equity : 0
    }
    
    private func calculateRiskScore(_ request: TradeRequest) -> Double {
        var score = 0.0
        
        // Position size risk
        let positionValue = request.volume * 100000 * (request.price ?? 0)
        let equity = getCurrentEquity()
        let sizeRisk = positionValue / equity
        score += min(sizeRisk * 2, 1.0) * 30
        
        // Leverage risk
        let leverage = calculateLeverage(additionalPosition: positionValue)
        score += min(leverage / 10, 1.0) * 30
        
        // Daily loss risk
        let lossRisk = abs(dailyPnL) / settings.dailyLossLimit
        score += min(lossRisk, 1.0) * 20
        
        // Time risk (trading outside main hours)
        if !isMainTradingHours() {
            score += 20
        }
        
        return score
    }
    
    private func isWithinTradingHours() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentTime = String(format: "%02d:%02d", hour, minute)
        
        let daySchedule: DaySchedule?
        
        switch weekday {
        case 1: daySchedule = settings.allowedTradingHours.sunday
        case 2: daySchedule = settings.allowedTradingHours.monday
        case 3: daySchedule = settings.allowedTradingHours.tuesday
        case 4: daySchedule = settings.allowedTradingHours.wednesday
        case 5: daySchedule = settings.allowedTradingHours.thursday
        case 6: daySchedule = settings.allowedTradingHours.friday
        case 7: daySchedule = settings.allowedTradingHours.saturday
        default: daySchedule = nil
        }
        
        guard let schedule = daySchedule, schedule.isEnabled else {
            return true // No restriction
        }
        
        return currentTime >= schedule.startTime && currentTime <= schedule.endTime
    }
    
    private func isMainTradingHours() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 8 && hour <= 17 // Main trading hours
    }
    
    private func performSafetyCheck() async {
        // Update metrics
        let positions = PositionTrackingService.shared.trackedPositions
        
        safetyMetrics = SafetyMetrics(
            dailyPnL: calculateDailyPnL(),
            currentDrawdown: calculateCurrentDrawdown(),
            openPositions: positions.count,
            currentLeverage: calculateLeverage(),
            anomaliesDetected: anomalyReports.count,
            safetyScore: calculateSafetyScore(),
            lastIncident: getLastIncidentDate()
        )
        
        // Check for anomalies
        if settings.anomalyDetectionEnabled {
            await detectSystemAnomalies()
        }
        
        // Clean up old alerts
        let cutoffDate = Date().addingTimeInterval(-3600) // 1 hour
        currentAlerts.removeAll { $0.timestamp < cutoffDate && $0.severity != .critical }
    }
    
    private func detectSystemAnomalies() async {
        // Check for technical issues
        let positions = PositionTrackingService.shared.trackedPositions
        
        // Check for stuck positions
        for position in positions {
            if Date().timeIntervalSince(position.openTime) > 86400 * 7 { // 7 days
                let report = TradingAnomalyReport(
                    timestamp: Date(),
                    anomalyType: .suspiciousPattern,
                    confidence: 0.7,
                    affectedTrades: [Trade(from: position)],
                    description: "Position open for over 7 days",
                    recommendation: "Review long-standing positions"
                )
                
                if !anomalyReports.contains(where: { $0.anomalyType == report.anomalyType }) {
                    anomalyReports.append(report)
                }
            }
        }
    }
    
    private func calculateSafetyScore() -> Double {
        var score = 100.0
        
        // Deduct for daily loss
        let lossRatio = abs(dailyPnL) / settings.dailyLossLimit
        score -= min(lossRatio * 30, 30)
        
        // Deduct for drawdown
        score -= min(safetyMetrics.currentDrawdown * 200, 30)
        
        // Deduct for high leverage
        let leverageRatio = safetyMetrics.currentLeverage / settings.maxLeverageAllowed
        score -= min(leverageRatio * 20, 20)
        
        // Deduct for anomalies
        score -= min(Double(safetyMetrics.anomaliesDetected) * 5, 20)
        
        return max(score, 0)
    }
    
    private func closeAllPositions() {
        // Implementation to close all positions
        Task {
            let positions = PositionTrackingService.shared.trackedPositions
            for position in positions {
                try? await TradeExecutionService.shared.closePosition(UUID(uuidString: position.id) ?? UUID())
            }
        }
    }
    
    private func showResumeConfirmation() {
        // Show confirmation dialog
    }
    
    private func getRecentTrades() -> [Trade] {
        // Get trades from last 24 hours - for now return empty array
        // TODO: Implement trade history tracking
        return []
    }
    
    private func getCurrentEquity() -> Double {
        // Get current account equity
        return 10000 // Demo value
    }
    
    private func getCurrentPositionValue() -> Double {
        let positions = PositionTrackingService.shared.trackedPositions
        return positions.reduce(0) { $0 + ($1.volume * 100000 * $1.currentPrice) }
    }
    
    private func calculateDailyPnL() -> Double {
        let positions = PositionTrackingService.shared.trackedPositions
        
        // For now, only calculate unrealized P&L
        // TODO: Add realized P&L from closed positions
        let unrealizedPnL = positions.reduce(0) { $0 + $1.unrealizedPL }
        
        return unrealizedPnL
    }
    
    private func calculateCurrentDrawdown() -> Double {
        let equity = getCurrentEquity()
        if equity >= peakEquity {
            peakEquity = equity
            return 0
        }
        return (peakEquity - equity) / peakEquity
    }
    
    private func getLastIncidentDate() -> Date? {
        return currentAlerts
            .filter { $0.severity == .critical || $0.severity == .emergency }
            .map { $0.timestamp }
            .max()
    }
}

// MARK: - Supporting Types

struct ValidationResult {
    let isValid: Bool
    let isPaperTrade: Bool
    let warnings: [String]
}

enum SafetyError: LocalizedError {
    case emergencyStopActive
    case tradingPaused
    case dailyLossLimitExceeded
    case maxPositionsExceeded
    case leverageLimitExceeded
    case outsideTradingHours
    case blacklistedSymbol(String)
    case notWhitelisted(String)
    case approvalTimeout
    
    var errorDescription: String? {
        switch self {
        case .emergencyStopActive:
            return "Emergency stop is active"
        case .tradingPaused:
            return "Trading is currently paused"
        case .dailyLossLimitExceeded:
            return "Daily loss limit exceeded"
        case .maxPositionsExceeded:
            return "Maximum open positions exceeded"
        case .leverageLimitExceeded:
            return "Leverage limit exceeded"
        case .outsideTradingHours:
            return "Outside allowed trading hours"
        case .blacklistedSymbol(let symbol):
            return "\(symbol) is blacklisted"
        case .notWhitelisted(let symbol):
            return "\(symbol) is not whitelisted"
        case .approvalTimeout:
            return "Trade approval timeout"
        }
    }
}

// Extension to convert Position to Trade
extension Trade {
    init(from position: TrackedPosition) {
        self.init(
            id: UUID(),
            accountId: UUID(), // TODO: Get actual account ID
            positionId: position.id,
            symbol: position.symbol,
            type: position.type,
            volume: Decimal(position.volume),
            openPrice: Decimal(position.openPrice),
            currentPrice: Decimal(position.currentPrice),
            closePrice: nil,
            stopLoss: position.stopLoss.map { Decimal($0) },
            takeProfit: position.takeProfit.map { Decimal($0) },
            commission: Decimal(position.commission),
            swap: Decimal(position.swap),
            profit: Decimal(position.unrealizedPL),
            status: .open,
            openTime: position.openTime,
            closeTime: nil,
            reason: .manual,
            comment: position.comment
        )
    }
}

// MARK: - SafetyControlManager Extension for Trade Execution

extension SafetyControlManager {
    func canExecuteTrade(symbol: String, side: TradeAction, volume: Double, currentBalance: Double) -> (canTrade: Bool, reason: String?) {
        // Check emergency stop
        if self.isEmergencyStopActive {
            return (false, "Emergency stop is active")
        }
        
        // Check if trading is paused
        if self.tradingPaused {
            return (false, "Trading is paused")
        }
        
        // Check daily loss limit
        if self.safetyMetrics.dailyPnL < -self.settings.dailyLossLimit {
            return (false, "Daily loss limit exceeded")
        }
        
        // Check max open positions
        if self.safetyMetrics.openPositions >= self.settings.maxOpenPositions {
            return (false, "Maximum open positions reached")
        }
        
        // Check blacklisted symbols
        if self.settings.blacklistedSymbols.contains(symbol) {
            return (false, "Symbol is blacklisted")
        }
        
        // Check whitelisted symbols
        if !self.settings.whitelistedSymbols.isEmpty && !self.settings.whitelistedSymbols.contains(symbol) {
            return (false, "Symbol is not whitelisted")
        }
        
        // Check trading hours
        if !self.isWithinTradingHours() {
            return (false, "Outside trading hours")
        }
        
        // Check position size against balance
        let positionValue = volume * 100000 // Assuming standard lot size
        let maxPositionSize = currentBalance * Double(self.settings.maxLeverageAllowed)
        if positionValue > maxPositionSize {
            return (false, "Position size exceeds maximum leverage")
        }
        
        return (true, nil)
    }
}