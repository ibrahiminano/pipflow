//
//  TradingActivity.swift
//  Pipflow
//
//  Model for real-time trading activity in social feed
//

import Foundation
import SwiftUI

struct TradingActivity: Identifiable {
    let id = UUID()
    let traderId: String
    let traderName: String
    let traderAvatar: String?
    let symbol: String
    let action: String // "BUY" or "SELL"
    let entryPrice: Double
    let exitPrice: Double?
    let profit: String
    let returnPercentage: String
    let timestamp: Date
    let likes: Int
    let comments: Int
    let isFollowing: Bool
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var isProfit: Bool {
        profit.hasPrefix("+")
    }
}

struct TradingRoom: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let activeUsers: Int
    let description: String?
}

struct Conversation: Identifiable {
    let id = UUID()
    let userName: String
    let userAvatar: String?
    let lastMessage: String
    let lastMessageTime: String
    let unreadCount: Int
    let isOnline: Bool
    let isVerified: Bool
}

// Additional properties for ForumService models
extension ForumService {
    var activeDiscussions: [ForumDiscussion] {
        topics.sorted { $0.updatedAt > $1.updatedAt }
            .prefix(10)
            .map { topic in
                ForumDiscussion(
                    id: topic.id.uuidString,
                    title: topic.title,
                    author: "User\(topic.authorId.hashValue % 1000)",
                    category: categories.first { $0.id == topic.categoryId }?.name ?? "General",
                    repliesCount: topic.replyCount,
                    lastActivity: formatTimeAgo(topic.updatedAt)
                )
            }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ForumDiscussion: Identifiable {
    let id: String
    let title: String
    let author: String
    let category: String
    var repliesCount: Int
    var lastActivity: String
}

// Chat Service Extensions
extension ChatService {
    var unreadCount: Int {
        unreadCounts.values.reduce(0, +)
    }
    
    var activeChats: [ChatRoom] {
        chatRooms.filter { room in
            room.lastMessage != nil
        }
    }
    
    var recentChats: [Chat] {
        chatRooms.compactMap { room in
            guard let lastMessage = room.lastMessage else { return nil }
            
            // Use a placeholder for current user ID since we can't access authService directly
            let currentUserId = UUID() // This should be passed from the view
            let otherParticipant = room.participants.first { $0 != currentUserId }
            let _ = "User\(otherParticipant?.hashValue ?? 0)"
            
            return Chat(
                id: room.id,
                participants: room.participants.map { Chat.ChatParticipant(id: $0, name: "User\($0.hashValue)") },
                lastMessage: Chat.ChatMessage(
                    preview: lastMessage.content.textValue,
                    isFromMe: lastMessage.senderId == currentUserId
                ),
                lastMessageTime: formatTimeAgo(lastMessage.createdAt),
                unreadCount: unreadCounts[room.id] ?? 0,
                isGroup: room.type == .group,
                groupName: room.name,
                isOnline: onlineUsers.contains(otherParticipant ?? UUID())
            )
        }
    }
    
    var tradingRooms: [TradingRoom] {
        [
            TradingRoom(name: "Forex", icon: "dollarsign.circle", color: .green, activeUsers: 234, description: "Major currency pairs"),
            TradingRoom(name: "Crypto", icon: "bitcoinsign.circle", color: .orange, activeUsers: 567, description: "Digital assets"),
            TradingRoom(name: "Stocks", icon: "chart.line.uptrend.xyaxis", color: .blue, activeUsers: 189, description: "Equity markets"),
            TradingRoom(name: "Gold", icon: "cube.fill", color: .yellow, activeUsers: 123, description: "Precious metals")
        ]
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Helper models for Chat
struct Chat: Identifiable {
    let id: UUID
    let participants: [ChatParticipant]
    let lastMessage: ChatMessage
    let lastMessageTime: String
    let unreadCount: Int
    let isGroup: Bool
    let groupName: String?
    let isOnline: Bool
    
    struct ChatParticipant {
        let id: UUID
        let name: String
    }
    
    struct ChatMessage {
        let preview: String
        let isFromMe: Bool
    }
}

// Extension for MessageContent
extension MessageContent {
    var textValue: String {
        switch self {
        case .text(let text):
            return text
        case .tradingSignal(let signal):
            return "📊 \(signal.symbol) Signal"
        case .media(let media):
            if media.mimeType.hasPrefix("image") {
                return "📷 Image"
            } else if media.mimeType.hasPrefix("audio") {
                return "🎤 Voice message"
            } else if media.mimeType.hasPrefix("video") {
                return "🎥 Video"
            } else {
                return "📎 File"
            }
        case .trade(let trade):
            return "💹 \(trade.symbol) Trade"
        case .poll(let poll):
            return "📊 \(poll.question)"
        case .system(let system):
            return system.text
        case .achievement(let achievement):
            return "🏆 \(achievement.title)"
        }
    }
}

// Enhanced Social Trading Service Extensions
extension EnhancedSocialTradingService {
    var activeTraders: Int {
        // Return count of top traders as a proxy for active traders
        topTraders.count
    }
    
    var topThreeTraders: [Trader] {
        Array(topTraders.prefix(3))
    }
    
    var leaderboard: [Trader] {
        topTraders
    }
    
    var liveFeed: [TradingActivity] {
        // Generate mock live feed from social posts
        socialFeed.prefix(10).compactMap { post in
            guard let trade = post.trade else { return nil }
            
            return TradingActivity(
                traderId: post.traderId,
                traderName: post.traderName,
                traderAvatar: post.traderImage,
                symbol: trade.symbol,
                action: trade.side == .buy ? "BUY" : "SELL",
                entryPrice: trade.entryPrice,
                exitPrice: trade.exitPrice,
                profit: trade.profit > 0 ? "+$\(String(format: "%.2f", trade.profit))" : "-$\(String(format: "%.2f", abs(trade.profit)))",
                returnPercentage: "\(trade.profit > 0 ? "+" : "")\(String(format: "%.1f", trade.profitPercentage))%",
                timestamp: post.timestamp,
                likes: post.likes,
                comments: post.comments,
                isFollowing: followedTraders.contains { $0.id == post.traderId }
            )
        }
    }
}