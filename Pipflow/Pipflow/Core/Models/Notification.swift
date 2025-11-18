//
//  Notification.swift
//  Pipflow
//
//  Notification models and types
//

import Foundation
import SwiftUI

// MARK: - Notification Types
enum NotificationType: String, CaseIterable, Codable {
    case priceAlert = "price_alert"
    case tradeExecution = "trade_execution"
    case tradeClosed = "trade_closed"
    case signalGenerated = "signal_generated"
    case marketNews = "market_news"
    case socialActivity = "social_activity"
    case achievementUnlocked = "achievement_unlocked"
    case strategyUpdate = "strategy_update"
    case riskWarning = "risk_warning"
    case accountUpdate = "account_update"
    case systemMessage = "system_message"
    
    var icon: String {
        switch self {
        case .priceAlert: return "chart.line.uptrend.xyaxis"
        case .tradeExecution: return "arrow.up.arrow.down.circle"
        case .tradeClosed: return "checkmark.circle"
        case .signalGenerated: return "bell.badge"
        case .marketNews: return "newspaper"
        case .socialActivity: return "person.2"
        case .achievementUnlocked: return "trophy"
        case .strategyUpdate: return "brain"
        case .riskWarning: return "exclamationmark.triangle"
        case .accountUpdate: return "person.circle"
        case .systemMessage: return "info.circle"
        }
    }
    
    var defaultPriority: NotificationPriority {
        switch self {
        case .riskWarning, .tradeExecution: return .high
        case .priceAlert, .signalGenerated, .tradeClosed: return .medium
        default: return .low
        }
    }
}

// MARK: - Notification Priority
enum NotificationPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Notification Model
struct PipflowNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let priority: NotificationPriority
    let isRead: Bool
    let data: NotificationData?
    let actionUrl: String?
    let expiresAt: Date?
    
    init(
        id: String = UUID().uuidString,
        type: NotificationType,
        title: String,
        message: String,
        timestamp: Date = Date(),
        priority: NotificationPriority? = nil,
        isRead: Bool = false,
        data: NotificationData? = nil,
        actionUrl: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.priority = priority ?? type.defaultPriority
        self.isRead = isRead
        self.data = data
        self.actionUrl = actionUrl
        self.expiresAt = expiresAt
    }
}

// MARK: - Notification Data
enum NotificationData: Codable {
    case priceAlert(PriceAlertData)
    case trade(TradeNotificationData)
    case signal(SignalNotificationData)
    case social(SocialNotificationData)
    case news(NewsNotificationData)
    case achievement(AchievementNotificationData)
    
    private enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "priceAlert":
            let data = try container.decode(PriceAlertData.self, forKey: .data)
            self = .priceAlert(data)
        case "trade":
            let data = try container.decode(TradeNotificationData.self, forKey: .data)
            self = .trade(data)
        case "signal":
            let data = try container.decode(SignalNotificationData.self, forKey: .data)
            self = .signal(data)
        case "social":
            let data = try container.decode(SocialNotificationData.self, forKey: .data)
            self = .social(data)
        case "news":
            let data = try container.decode(NewsNotificationData.self, forKey: .data)
            self = .news(data)
        case "achievement":
            let data = try container.decode(AchievementNotificationData.self, forKey: .data)
            self = .achievement(data)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown notification data type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .priceAlert(let data):
            try container.encode("priceAlert", forKey: .type)
            try container.encode(data, forKey: .data)
        case .trade(let data):
            try container.encode("trade", forKey: .type)
            try container.encode(data, forKey: .data)
        case .signal(let data):
            try container.encode("signal", forKey: .type)
            try container.encode(data, forKey: .data)
        case .social(let data):
            try container.encode("social", forKey: .type)
            try container.encode(data, forKey: .data)
        case .news(let data):
            try container.encode("news", forKey: .type)
            try container.encode(data, forKey: .data)
        case .achievement(let data):
            try container.encode("achievement", forKey: .type)
            try container.encode(data, forKey: .data)
        }
    }
}

// MARK: - Specific Notification Data Types
struct PriceAlertData: Codable {
    let symbol: String
    let condition: PriceAlertCondition
    let targetPrice: Double
    let currentPrice: Double
    let priceChange: Double
    let priceChangePercent: Double
}

struct TradeNotificationData: Codable {
    let tradeId: String
    let symbol: String
    let type: String // "BUY" or "SELL"
    let volume: Double
    let price: Double
    let profit: Double?
    let status: String // "OPENED", "CLOSED", "MODIFIED"
}

struct SignalNotificationData: Codable {
    let signalId: String
    let symbol: String
    let action: String
    let confidence: Double
    let entryPrice: Double
    let stopLoss: Double
    let takeProfit: Double
}

struct SocialNotificationData: Codable {
    let userId: String
    let username: String
    let action: String // "followed", "liked", "commented", "copied"
    let targetId: String?
    let targetType: String? // "post", "strategy", "trade"
}

struct NewsNotificationData: Codable {
    let newsId: String
    let category: String
    let importance: String // "low", "medium", "high"
    let affectedSymbols: [String]
    let sourceUrl: String?
}

struct AchievementNotificationData: Codable {
    let achievementId: String
    let achievementName: String
    let achievementDescription: String
    let badgeImage: String
    let rewardPoints: Int?
}

// MARK: - Price Alert Models
struct PriceAlert: Identifiable, Codable {
    let id: String
    let symbol: String
    let condition: PriceAlertCondition
    let targetPrice: Double
    let isActive: Bool
    let createdAt: Date
    let triggeredAt: Date?
    let expiresAt: Date?
    let note: String?
    
    init(
        id: String = UUID().uuidString,
        symbol: String,
        condition: PriceAlertCondition,
        targetPrice: Double,
        isActive: Bool = true,
        createdAt: Date = Date(),
        triggeredAt: Date? = nil,
        expiresAt: Date? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.condition = condition
        self.targetPrice = targetPrice
        self.isActive = isActive
        self.createdAt = createdAt
        self.triggeredAt = triggeredAt
        self.expiresAt = expiresAt
        self.note = note
    }
}

enum PriceAlertCondition: String, CaseIterable, Codable {
    case above = "above"
    case below = "below"
    case crosses = "crosses"
    case percentChangeUp = "percent_up"
    case percentChangeDown = "percent_down"
    
    var description: String {
        switch self {
        case .above: return "Price rises above"
        case .below: return "Price falls below"
        case .crosses: return "Price crosses"
        case .percentChangeUp: return "Price increases by"
        case .percentChangeDown: return "Price decreases by"
        }
    }
    
    var icon: String {
        switch self {
        case .above: return "arrow.up"
        case .below: return "arrow.down"
        case .crosses: return "arrow.up.arrow.down"
        case .percentChangeUp: return "percent"
        case .percentChangeDown: return "percent"
        }
    }
}

// MARK: - Notification Preferences
struct PipflowNotificationPreferences: Codable {
    var enablePushNotifications: Bool
    var enableInAppNotifications: Bool
    var enableEmailNotifications: Bool
    var enableSoundAlerts: Bool
    var enableVibration: Bool
    
    var priceAlerts: Bool
    var tradeNotifications: Bool
    var signalAlerts: Bool
    var newsAlerts: Bool
    var socialNotifications: Bool
    var achievementNotifications: Bool
    var marketingMessages: Bool
    
    var quietHoursEnabled: Bool
    var quietHoursStart: Date?
    var quietHoursEnd: Date?
    
    var minimumPriority: NotificationPriority
    
    init() {
        self.enablePushNotifications = true
        self.enableInAppNotifications = true
        self.enableEmailNotifications = false
        self.enableSoundAlerts = true
        self.enableVibration = true
        
        self.priceAlerts = true
        self.tradeNotifications = true
        self.signalAlerts = true
        self.newsAlerts = true
        self.socialNotifications = true
        self.achievementNotifications = true
        self.marketingMessages = false
        
        self.quietHoursEnabled = false
        self.quietHoursStart = nil
        self.quietHoursEnd = nil
        
        self.minimumPriority = .low
    }
    
    func shouldShowNotification(type: NotificationType, priority: NotificationPriority) -> Bool {
        // Check minimum priority
        guard priority.rawValue >= minimumPriority.rawValue else { return false }
        
        // Check quiet hours
        if quietHoursEnabled, let start = quietHoursStart, let end = quietHoursEnd {
            let now = Date()
            let calendar = Calendar.current
            let currentTime = calendar.dateComponents([.hour, .minute], from: now)
            let startTime = calendar.dateComponents([.hour, .minute], from: start)
            let endTime = calendar.dateComponents([.hour, .minute], from: end)
            
            if let currentHour = currentTime.hour,
               let startHour = startTime.hour,
               let endHour = endTime.hour {
                let isInQuietHours = startHour < endHour
                    ? (currentHour >= startHour && currentHour < endHour)
                    : (currentHour >= startHour || currentHour < endHour)
                
                if isInQuietHours && priority != .urgent {
                    return false
                }
            }
        }
        
        // Check type-specific preferences
        switch type {
        case .priceAlert: return priceAlerts
        case .tradeExecution, .tradeClosed: return tradeNotifications
        case .signalGenerated: return signalAlerts
        case .marketNews: return newsAlerts
        case .socialActivity: return socialNotifications
        case .achievementUnlocked: return achievementNotifications
        case .systemMessage: return true
        case .strategyUpdate: return tradeNotifications
        case .riskWarning: return true // Always show risk warnings
        case .accountUpdate: return true
        }
    }
}

// MARK: - Notification Channel
enum NotificationChannel: String, CaseIterable {
    case push = "push"
    case inApp = "in_app"
    case email = "email"
    case sms = "sms"
    
    var displayName: String {
        switch self {
        case .push: return "Push Notifications"
        case .inApp: return "In-App Alerts"
        case .email: return "Email"
        case .sms: return "SMS"
        }
    }
}

// MARK: - Notification History
struct NotificationHistory: Codable {
    let notifications: [PipflowNotification]
    let lastReadAt: Date
    let unreadCount: Int
    
    var unreadNotifications: [PipflowNotification] {
        notifications.filter { !$0.isRead }
    }
    
    var readNotifications: [PipflowNotification] {
        notifications.filter { $0.isRead }
    }
    
    var highPriorityUnread: [PipflowNotification] {
        unreadNotifications.filter { $0.priority == .high || $0.priority == .urgent }
    }
}