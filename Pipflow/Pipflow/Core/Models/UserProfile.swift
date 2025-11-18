//
//  UserProfile.swift
//  Pipflow
//
//  Enhanced user profile model with social features
//

import Foundation
import SwiftUI

// MARK: - User Profile
struct UserProfile: Identifiable, Codable {
    let id: UUID
    var username: String
    var displayName: String
    var email: String
    var bio: String?
    var avatarURL: String?
    var coverImageURL: String?
    var location: String?
    var website: String?
    var socialLinks: SocialLinks
    
    // Trading Info
    var tradingExperience: TradingExperience
    var preferredMarkets: [String]
    var tradingStyle: TradingStyle
    var riskLevel: RiskLevel
    
    // Statistics
    var stats: UserStats
    var achievements: [String] // Achievement IDs
    var badges: [UserBadge]
    
    // Social
    var followers: Set<UUID>
    var following: Set<UUID>
    var blockedUsers: Set<UUID>
    
    // Privacy & Settings
    var privacy: PrivacySettings
    var notifications: NotificationSettings
    
    // Metadata
    let createdAt: Date
    var updatedAt: Date
    var lastActive: Date
    var isVerified: Bool
    var isPro: Bool
    var isOnline: Bool
    
    // Computed properties
    var followerCount: Int { followers.count }
    var followingCount: Int { following.count }
    var initials: String {
        let names = displayName.split(separator: " ")
        let firstInitial = names.first?.first?.uppercased() ?? ""
        let lastInitial = names.count > 1 ? names.last?.first?.uppercased() ?? "" : ""
        return firstInitial + lastInitial
    }
}

// MARK: - Social Links
struct SocialLinks: Codable {
    var twitter: String?
    var telegram: String?
    var discord: String?
    var youtube: String?
    var tradingView: String?
}

// MARK: - Market Types
enum Market: String, Codable, CaseIterable {
    case forex = "Forex"
    case crypto = "Crypto"
    case stocks = "Stocks"
    case indices = "Indices"
    case commodities = "Commodities"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Trading Experience
enum TradingExperience: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case professional = "Professional"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .beginner: return "leaf"
        case .intermediate: return "chart.line.uptrend.xyaxis"
        case .advanced: return "star"
        case .professional: return "crown"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .purple
        case .professional: return .orange
        }
    }
}

// MARK: - Trading Style
enum TradingStyle: String, Codable, CaseIterable {
    case scalping = "Scalping"
    case dayTrading = "Day Trading"
    case swingTrading = "Swing Trading"
    case positionTrading = "Position Trading"
    case algorithmicTrading = "Algorithmic Trading"
    
    var description: String {
        switch self {
        case .scalping: return "Quick trades, small profits"
        case .dayTrading: return "Open and close within a day"
        case .swingTrading: return "Hold for days to weeks"
        case .positionTrading: return "Long-term positions"
        case .algorithmicTrading: return "Automated strategies"
        }
    }
}

// MARK: - Risk Level
enum RiskLevel: String, Codable, CaseIterable {
    case conservative = "Conservative"
    case moderate = "Moderate"
    case aggressive = "Aggressive"
    
    var color: Color {
        switch self {
        case .conservative: return .green
        case .moderate: return .orange
        case .aggressive: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .conservative: return "shield"
        case .moderate: return "gauge"
        case .aggressive: return "flame"
        }
    }
}

// MARK: - User Stats
struct UserStats: Codable {
    var totalTrades: Int
    var winRate: Double
    var profitFactor: Double
    var sharpeRatio: Double
    var maxDrawdown: Double
    var monthlyReturn: Double
    var totalReturn: Double
    var averageWin: Double
    var averageLoss: Double
    var bestTrade: Double
    var worstTrade: Double
    var currentStreak: Int
    var longestWinStreak: Int
    var longestLossStreak: Int
    var tradingDays: Int
    var lastUpdated: Date
}

// MARK: - User Badge
struct UserBadge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: BadgeCategory
    let rarity: BadgeRarity
    let earnedAt: Date
    
    enum BadgeCategory: String, Codable {
        case trading = "Trading"
        case social = "Social"
        case education = "Education"
        case achievement = "Achievement"
        case special = "Special"
    }
    
    enum BadgeRarity: String, Codable {
        case common = "Common"
        case rare = "Rare"
        case epic = "Epic"
        case legendary = "Legendary"
        
        var color: Color {
            switch self {
            case .common: return .gray
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .orange
            }
        }
    }
}

// MARK: - Privacy Settings
struct PrivacySettings: Codable {
    var profileVisibility: ProfileVisibility
    var showTradingStats: Bool
    var showFollowers: Bool
    var allowDirectMessages: MessagePrivacy
    var allowCopyTrading: Bool
    var hideFromSearch: Bool
    var showOnlineStatus: Bool
    
    enum ProfileVisibility: String, Codable, CaseIterable {
        case everyone = "Everyone"
        case followersOnly = "Followers Only"
        case nobody = "Nobody"
    }
    
    enum MessagePrivacy: String, Codable, CaseIterable {
        case everyone = "Everyone"
        case followersOnly = "Followers Only"
        case followingOnly = "Following Only"
        case nobody = "Nobody"
    }
}

// MARK: - Notification Settings
struct NotificationSettings: Codable {
    // Trading
    var tradeExecuted: Bool
    var priceAlerts: Bool
    var positionUpdates: Bool
    var marketNews: Bool
    
    // Social
    var newFollower: Bool
    var mentions: Bool
    var directMessages: Bool
    var comments: Bool
    var likes: Bool
    
    // Education
    var newLessons: Bool
    var achievementUnlocked: Bool
    var courseUpdates: Bool
    
    // System
    var systemUpdates: Bool
    var promotions: Bool
    var weeklyReport: Bool
}

// MARK: - Activity Feed Item
struct ActivityFeedItem: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let timestamp: Date
    let type: ActivityType
    let content: ActivityContent
    let relatedUsers: [UUID]
    let metadata: [String: String]
    
    enum ActivityType: String, Codable, CaseIterable {
        case trade = "Trade"
        case follow = "Follow"
        case achievement = "Achievement"
        case post = "Post"
        case comment = "Comment"
        case like = "Like"
        case share = "Share"
        case milestone = "Milestone"
    }
    
    enum ActivityContent: Codable {
        case trade(symbol: String, side: TradeSide, profit: Double)
        case follow(targetUserId: UUID)
        case achievement(achievementId: String)
        case post(postId: UUID, preview: String)
        case comment(postId: UUID, commentId: UUID, preview: String)
        case like(postId: UUID)
        case share(postId: UUID)
        case milestone(type: String, value: String)
    }
}

// MARK: - Follow Request
struct FollowRequest: Identifiable, Codable {
    let id: UUID
    let fromUserId: UUID
    let toUserId: UUID
    let requestedAt: Date
    var status: RequestStatus
    var respondedAt: Date?
    
    enum RequestStatus: String, Codable {
        case pending = "Pending"
        case accepted = "Accepted"
        case rejected = "Rejected"
        case cancelled = "Cancelled"
    }
}

// MARK: - Mock Data
extension UserProfile {
    static var mock: UserProfile {
        UserProfile(
            id: UUID(),
            username: "johndoe",
            displayName: "John Doe",
            email: "john@example.com",
            bio: "Professional trader with 5+ years of experience. Specializing in forex and crypto markets.",
            avatarURL: nil,
            coverImageURL: nil,
            location: "New York, USA",
            website: "https://johndoe.trading",
            socialLinks: SocialLinks(
                twitter: "@johndoe",
                telegram: "@johndoe_trading",
                tradingView: "johndoe"
            ),
            tradingExperience: .advanced,
            preferredMarkets: ["Forex", "Crypto"],
            tradingStyle: .swingTrading,
            riskLevel: .moderate,
            stats: UserStats(
                totalTrades: 1250,
                winRate: 0.68,
                profitFactor: 2.4,
                sharpeRatio: 1.8,
                maxDrawdown: 0.15,
                monthlyReturn: 0.12,
                totalReturn: 2.45,
                averageWin: 125.50,
                averageLoss: 52.30,
                bestTrade: 850.00,
                worstTrade: -200.00,
                currentStreak: 5,
                longestWinStreak: 12,
                longestLossStreak: 4,
                tradingDays: 365,
                lastUpdated: Date()
            ),
            achievements: ["first_trade", "100_trades", "profitable_month"],
            badges: [
                UserBadge(
                    id: "verified_trader",
                    name: "Verified Trader",
                    description: "Verified trading track record",
                    icon: "checkmark.seal.fill",
                    category: .trading,
                    rarity: .rare,
                    earnedAt: Date()
                )
            ],
            followers: Set([UUID(), UUID(), UUID()]),
            following: Set([UUID(), UUID()]),
            blockedUsers: Set(),
            privacy: PrivacySettings(
                profileVisibility: .everyone,
                showTradingStats: true,
                showFollowers: true,
                allowDirectMessages: .followersOnly,
                allowCopyTrading: true,
                hideFromSearch: false,
                showOnlineStatus: true
            ),
            notifications: NotificationSettings(
                tradeExecuted: true,
                priceAlerts: true,
                positionUpdates: true,
                marketNews: true,
                newFollower: true,
                mentions: true,
                directMessages: true,
                comments: true,
                likes: false,
                newLessons: true,
                achievementUnlocked: true,
                courseUpdates: false,
                systemUpdates: true,
                promotions: false,
                weeklyReport: true
            ),
            createdAt: Date().addingTimeInterval(-365 * 24 * 60 * 60),
            updatedAt: Date(),
            lastActive: Date(),
            isVerified: true,
            isPro: true,
            isOnline: true
        )
    }
}