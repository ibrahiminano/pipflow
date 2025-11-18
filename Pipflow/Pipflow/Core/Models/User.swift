//
//  User.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

// User model for social trading features
struct User: Identifiable, Codable {
    let id: UUID
    let name: String
    let email: String
    let bio: String
    let totalProfit: Double
    let winRate: Double
    let totalTrades: Int
    let followers: Int
    let following: Int
    let avatarURL: String?
    let riskScore: Int
    let isVerified: Bool
    let isPro: Bool
    
    // Computed properties
    var displayName: String {
        name.isEmpty ? email.components(separatedBy: "@").first ?? "User" : name
    }
    
    var formattedProfit: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalProfit)) ?? "$0.00"
    }
    
    var formattedWinRate: String {
        "\(Int(winRate))%"
    }
    
    var riskLevel: String {
        switch riskScore {
        case 0..<30: return "Low"
        case 30..<70: return "Medium"
        default: return "High"
        }
    }
    
    var riskColor: String {
        switch riskScore {
        case 0..<30: return "green"
        case 30..<70: return "orange"
        default: return "red"
        }
    }
}

// Legacy User model for backward compatibility
struct AppUser: Codable, Identifiable {
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
            return ["10 signals/month", "Copy 1 trader", "Basic analytics"]
        case .pro:
            return ["Unlimited signals", "Copy 5 traders", "Advanced analytics", "AI trading"]
        case .expert:
            return ["Everything in Pro", "Copy unlimited traders", "Custom strategies", "Priority support"]
        }
    }
    
    var monthlyPrice: Decimal {
        switch self {
        case .free: return 0
        case .basic: return 29.99
        case .pro: return 99.99
        case .expert: return 299.99
        }
    }
}