//
//  SafetyModels.swift
//  Pipflow
//
//  Additional models for Safety Control features
//

import Foundation

// MARK: - Notification Manager Extension

extension NotificationManager {
    func sendEmergencyNotification(title: String, body: String) {
        // Implementation for emergency notifications
        sendNotification(
            title: title,
            body: body,
            identifier: "emergency-\(UUID().uuidString)",
            timeInterval: 1
        )
    }
}

// MARK: - Trade Execution Service Extension

// MARK: - Position Type Alias
typealias Position = TrackedPosition

extension TradeExecutionService {
    func closePosition(_ positionId: UUID) async throws {
        // Find position
        guard let position = PositionTrackingService.shared.trackedPositions.first(where: { $0.id == positionId.uuidString }) else {
            throw TradeError.positionNotFound
        }
        
        // Create close order request
        let request = ExecutionTradeRequest(
            symbol: position.symbol,
            side: position.type == .buy ? .sell : .buy,
            volume: position.volume,
            stopLoss: nil,
            takeProfit: nil,
            comment: "Close position",
            magicNumber: nil
        )
        
        try await executeTrade(request)
    }
}

enum TradeError: LocalizedError {
    case positionNotFound
    case executionFailed(String)
    case insufficientBalance
    case marketClosed
    
    var errorDescription: String? {
        switch self {
        case .positionNotFound:
            return "Position not found"
        case .executionFailed(let reason):
            return "Trade execution failed: \(reason)"
        case .insufficientBalance:
            return "Insufficient balance"
        case .marketClosed:
            return "Market is closed"
        }
    }
}