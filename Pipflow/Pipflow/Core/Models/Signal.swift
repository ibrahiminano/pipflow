//
//  Signal.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

struct Signal: Codable, Identifiable {
    let id: UUID
    let symbol: String
    let action: SignalAction
    let entry: Decimal
    let stopLoss: Decimal
    let takeProfits: [TakeProfit]
    let confidence: Double
    let rationale: String
    let timeframe: Timeframe
    let analysisType: AnalysisType
    let riskRewardRatio: Double
    let generatedBy: SignalSource
    let generatedAt: Date
    let expiresAt: Date
    let status: SignalStatus
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0.8...1.0: return .high
        case 0.6..<0.8: return .medium
        default: return .low
        }
    }
    
    var potentialProfit: Decimal {
        guard let firstTP = takeProfits.first else { return 0 }
        return abs(firstTP.price - entry)
    }
    
    var potentialLoss: Decimal {
        abs(stopLoss - entry)
    }
    
    // Computed properties for backward compatibility
    var takeProfit: Decimal? {
        takeProfits.first?.price
    }
    
    var reasoning: String {
        rationale
    }
    
    var pair: String {
        symbol
    }
}

struct TakeProfit: Codable {
    let price: Decimal
    let percentage: Double // Percentage of position to close
    let rationale: String?
}

enum SignalAction: String, Codable, CaseIterable {
    case buy = "BUY"
    case sell = "SELL"
    case close = "CLOSE"
    case modify = "MODIFY"
}

enum SignalStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case triggered = "TRIGGERED"
    case expired = "EXPIRED"
    case cancelled = "CANCELLED"
    case completed = "COMPLETED"
}

enum Timeframe: String, Codable, CaseIterable {
    case m1 = "M1"
    case m5 = "M5"
    case m15 = "M15"
    case m30 = "M30"
    case h1 = "H1"
    case h4 = "H4"
    case d1 = "D1"
    case w1 = "W1"
    case mn1 = "MN1"
    
    var displayName: String {
        switch self {
        case .m1: return "1 Minute"
        case .m5: return "5 Minutes"
        case .m15: return "15 Minutes"
        case .m30: return "30 Minutes"
        case .h1: return "1 Hour"
        case .h4: return "4 Hours"
        case .d1: return "Daily"
        case .w1: return "Weekly"
        case .mn1: return "Monthly"
        }
    }
}

enum AnalysisType: String, Codable, CaseIterable {
    case technical = "TECHNICAL"
    case fundamental = "FUNDAMENTAL"
    case sentiment = "SENTIMENT"
    case mixed = "MIXED"
}

enum SignalSource: String, Codable, CaseIterable {
    case ai = "AI"
    case expert = "EXPERT"
    case community = "COMMUNITY"
    case system = "SYSTEM"
}

enum ConfidenceLevel: String, CaseIterable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    
    var color: String {
        switch self {
        case .low: return "red"
        case .medium: return "yellow"
        case .high: return "green"
        }
    }
}