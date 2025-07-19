//
//  User.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let username: String
    let firstName: String?
    let lastName: String?
    let avatarURL: String?
    let tradingAccounts: [TradingAccount]
    let walletBalance: Decimal
    let tier: UserTier
    let createdAt: Date
    let updatedAt: Date
    
    var fullName: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName) \(lastName)"
        }
        return username
    }
}

enum UserTier: String, Codable, CaseIterable {
    case free = "FREE"
    case basic = "BASIC"
    case pro = "PRO"
    case expert = "EXPERT"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .basic: return "Basic"
        case .pro: return "Pro"
        case .expert: return "Expert"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return ["View signals", "Basic education", "Community access"]
        case .basic:
            return ["All Free features", "Copy trading", "5 signals/day", "Basic AI insights"]
        case .pro:
            return ["All Basic features", "Unlimited signals", "AI auto-trading", "Advanced analytics"]
        case .expert:
            return ["All Pro features", "Priority support", "Custom strategies", "API access"]
        }
    }
}