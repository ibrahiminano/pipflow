//
//  Chat.swift
//  Pipflow
//
//  Data models for the Social Features/Chat system
//

import Foundation
import SwiftUI

// MARK: - Chat Models

struct ChatRoom: Identifiable, Codable, Equatable {
    let id: UUID
    let type: ChatRoomType
    let name: String?
    let description: String?
    let avatarURL: String?
    let participants: [UUID]
    let admins: [UUID]
    let createdAt: Date
    let updatedAt: Date
    let lastMessage: ChatMessage?
    let unreadCount: Int
    let isPinned: Bool
    let isMuted: Bool
    let settings: ChatRoomSettings
    
    var displayName: String {
        name ?? "Chat Room"
    }
    
    var isGroup: Bool {
        type == .group || type == .channel
    }
    
    static func == (lhs: ChatRoom, rhs: ChatRoom) -> Bool {
        lhs.id == rhs.id
    }
}

enum ChatRoomType: String, Codable, CaseIterable {
    case direct = "direct"
    case group = "group"
    case channel = "channel"
    case support = "support"
    case aiAssistant = "ai_assistant"
    
    var icon: String {
        switch self {
        case .direct: return "person.fill"
        case .group: return "person.3.fill"
        case .channel: return "number"
        case .support: return "questionmark.circle.fill"
        case .aiAssistant: return "brain"
        }
    }
}

struct ChatRoomSettings: Codable {
    let allowedMessageTypes: Set<MessageType>
    let maxParticipants: Int?
    let isPublic: Bool
    let requiresApproval: Bool
    let allowedRoles: [UserRole]
    let features: Set<ChatFeature>
}

enum ChatFeature: String, Codable, CaseIterable {
    case voiceMessages = "voice_messages"
    case fileSharing = "file_sharing"
    case screenSharing = "screen_sharing"
    case tradingSignals = "trading_signals"
    case liveTrading = "live_trading"
    case polls = "polls"
    case events = "events"
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let roomId: UUID
    let senderId: UUID
    let type: MessageType
    let content: MessageContent
    let createdAt: Date
    let updatedAt: Date?
    let editedAt: Date?
    let deletedAt: Date?
    var readBy: Set<UUID>
    var reactions: [MessageReaction]
    let replyTo: UUID?
    let mentions: [UUID]
    let isPinned: Bool
    let metadata: MessageMetadata?
}

enum MessageType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case file = "file"
    case tradingSignal = "trading_signal"
    case trade = "trade"
    case poll = "poll"
    case system = "system"
    case achievement = "achievement"
}

enum MessageContent: Codable {
    case text(String)
    case media(MediaContent)
    case tradingSignal(TradingSignalContent)
    case trade(TradeContent)
    case poll(PollContent)
    case system(SystemMessageContent)
    case achievement(AchievementContent)
}

struct MediaContent: Codable {
    let url: String
    let thumbnailURL: String?
    let duration: Int? // For audio/video in seconds
    let mimeType: String
    let size: Int // In bytes
    let caption: String?
}

struct TradingSignalContent: Codable {
    let signalId: UUID
    let symbol: String
    let action: TradeAction
    let entry: Double
    let stopLoss: Double
    let takeProfit: Double
    let confidence: Double
    let analysis: String?
}

struct TradeContent: Codable {
    let tradeId: UUID
    let symbol: String
    let action: TradeAction
    let volume: Double
    let entryPrice: Double
    let currentPrice: Double
    let pnl: Double
    let pnlPercentage: Double
    let status: TradeStatus
}

struct PollContent: Codable {
    let question: String
    let options: [PollOption]
    let allowMultiple: Bool
    let expiresAt: Date?
    let totalVotes: Int
    let userVote: Set<UUID>?
}

struct PollOption: Identifiable, Codable {
    let id: UUID
    let text: String
    let votes: Int
    let voters: Set<UUID>
}

struct SystemMessageContent: Codable {
    let type: SystemMessageType
    let text: String
    let actionUserId: UUID?
    let targetUserId: UUID?
}

enum SystemMessageType: String, Codable {
    case userJoined = "user_joined"
    case userLeft = "user_left"
    case userAdded = "user_added"
    case userRemoved = "user_removed"
    case roomCreated = "room_created"
    case roomUpdated = "room_updated"
    case adminPromoted = "admin_promoted"
    case adminDemoted = "admin_demoted"
}

struct AchievementContent: Codable {
    let achievementId: UUID
    let title: String
    let description: String
    let icon: String
    let rarity: AchievementRarity
}

struct MessageReaction: Codable {
    let emoji: String
    let users: Set<UUID>
    
    var count: Int {
        users.count
    }
}

struct MessageMetadata: Codable {
    let editHistory: [EditRecord]?
    let forwardedFrom: UUID?
    let scheduledAt: Date?
    let expiresAt: Date?
    let isAnnouncement: Bool
}

struct EditRecord: Codable {
    let editedAt: Date
    let previousContent: String
    let editedBy: UUID
}

// MARK: - Community Forum Models

struct ForumCategory: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let color: String
    let orderIndex: Int
    let isLocked: Bool
    let requiredRole: UserRole?
    let topicCount: Int
    let postCount: Int
    let lastPost: ForumPost?
}

struct ForumTopic: Identifiable, Codable {
    let id: UUID
    let categoryId: UUID
    let authorId: UUID
    let title: String
    let content: String
    let tags: [String]
    let isPinned: Bool
    let isLocked: Bool
    let isFeatured: Bool
    var viewCount: Int
    var replyCount: Int
    var lastReply: ForumPost?
    let createdAt: Date
    var updatedAt: Date
    var votes: Int
    var userVote: VoteType?
    var subscribers: Set<UUID>
    var rank: Int
    var postsCount: Int
    var viewsCount: Int
}

struct ForumPost: Identifiable, Codable, Equatable {
    let id: UUID
    let topicId: UUID
    let authorId: UUID
    let title: String
    let content: String
    let category: String
    let preview: String
    let replyTo: UUID?
    let createdAt: Date
    let updatedAt: Date?
    let editedAt: Date?
    let deletedAt: Date?
    var votes: Int
    var replies: Int
    var likes: Int
    var views: Int
    var isPinned: Bool
    var userVote: VoteType?
    var reactions: [PostReaction]
    let attachments: [ForumAttachment]
    let mentions: [UUID]
    let isAcceptedAnswer: Bool
    let isModeratorsChoice: Bool
    
    static func == (lhs: ForumPost, rhs: ForumPost) -> Bool {
        lhs.id == rhs.id
    }
}

enum VoteType: String, Codable {
    case upvote = "upvote"
    case downvote = "downvote"
}

struct PostReaction: Codable {
    let type: ReactionType
    var count: Int
    var users: Set<UUID>
}

enum ReactionType: String, Codable, CaseIterable {
    case like = "like"
    case love = "love"
    case insightful = "insightful"
    case helpful = "helpful"
    case celebrate = "celebrate"
    
    var emoji: String {
        switch self {
        case .like: return "👍"
        case .love: return "❤️"
        case .insightful: return "💡"
        case .helpful: return "🙏"
        case .celebrate: return "🎉"
        }
    }
}

struct ForumAttachment: Identifiable, Codable {
    let id: UUID
    let type: AttachmentType
    let url: String
    let name: String
    let size: Int
    let mimeType: String
}

// MARK: - User Profile Models

struct ChatUserProfile: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let username: String
    let displayName: String
    let bio: String?
    let avatarURL: String?
    let bannerURL: String?
    let location: String?
    let website: String?
    let socialLinks: ChatSocialLinks?
    let tradingStats: TradingStats
    let socialStats: SocialStats
    let badges: [ChatUserBadge]
    let preferences: ProfilePreferences
    let joinedAt: Date
    let lastActiveAt: Date
    let isVerified: Bool
    let isPremium: Bool
    let role: UserRole
}

struct ChatSocialLinks: Codable {
    let twitter: String?
    let telegram: String?
    let discord: String?
    let youtube: String?
    let tradingView: String?
}

struct TradingStats: Codable {
    let totalTrades: Int
    let winRate: Double
    let averageReturn: Double
    let profitFactor: Double
    let sharpeRatio: Double
    let maxDrawdown: Double
    let tradingDays: Int
    let favoriteAssets: [String]
    let tradingStyle: ChatTradingStyle?
}

enum ChatTradingStyle: String, Codable, CaseIterable {
    case scalping = "scalping"
    case dayTrading = "day_trading"
    case swingTrading = "swing_trading"
    case positionTrading = "position_trading"
    case algorithmic = "algorithmic"
    
    var displayName: String {
        switch self {
        case .scalping: return "Scalper"
        case .dayTrading: return "Day Trader"
        case .swingTrading: return "Swing Trader"
        case .positionTrading: return "Position Trader"
        case .algorithmic: return "Algo Trader"
        }
    }
}

struct SocialStats: Codable {
    let followers: Int
    let following: Int
    let posts: Int
    let signals: Int
    let reputation: Int
    let helpfulVotes: Int
    let strategiesShared: Int
    let studentsHelped: Int
}

struct ChatUserBadge: Identifiable, Codable {
    let id: UUID
    let type: BadgeType
    let name: String
    let description: String
    let icon: String
    let earnedAt: Date
    let expiresAt: Date?
    let metadata: [String: String]
}

enum BadgeType: String, Codable {
    case verified = "verified"
    case topTrader = "top_trader"
    case mentor = "mentor"
    case contributor = "contributor"
    case earlyAdopter = "early_adopter"
    case streak = "streak"
    case achievement = "achievement"
    case event = "event"
}

struct ProfilePreferences: Codable {
    let isPublic: Bool
    let showTradingStats: Bool
    let showPortfolio: Bool
    let allowMessages: MessagePrivacy
    let allowFollows: Bool
    let emailNotifications: NotificationPreferences
    let pushNotifications: NotificationPreferences
}

enum MessagePrivacy: String, Codable {
    case everyone = "everyone"
    case followers = "followers"
    case following = "following"
    case mutual = "mutual"
    case nobody = "nobody"
}

struct NotificationPreferences: Codable {
    let messages: Bool
    let mentions: Bool
    let follows: Bool
    let trades: Bool
    let signals: Bool
    let achievements: Bool
    let news: Bool
    let marketing: Bool
}

// MARK: - Activity Feed Models

struct ActivityItem: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let type: ActivityType
    let data: ActivityData
    let createdAt: Date
    let isRead: Bool
    let relatedUsers: [UUID]
    let metadata: [String: String]
}

enum ActivityType: String, Codable, CaseIterable {
    case follow = "follow"
    case trade = "trade"
    case signal = "signal"
    case achievement = "achievement"
    case post = "post"
    case comment = "comment"
    case reaction = "reaction"
    case milestone = "milestone"
    case strategy = "strategy"
    
    var icon: String {
        switch self {
        case .follow: return "person.badge.plus"
        case .trade: return "chart.line.uptrend.xyaxis"
        case .signal: return "bell.badge"
        case .achievement: return "trophy"
        case .post: return "doc.text"
        case .comment: return "bubble.left"
        case .reaction: return "heart"
        case .milestone: return "flag.checkered"
        case .strategy: return "brain"
        }
    }
}

enum ActivityData: Codable {
    case follow(FollowActivity)
    case trade(TradeActivity)
    case signal(SignalActivity)
    case achievement(AchievementActivity)
    case post(PostActivity)
    case comment(CommentActivity)
    case reaction(ReactionActivity)
    case milestone(MilestoneActivity)
    case strategy(StrategyActivity)
}

struct FollowActivity: Codable {
    let followerId: UUID
    let followedId: UUID
    let isFollowBack: Bool
}

struct TradeActivity: Codable {
    let tradeId: UUID
    let symbol: String
    let action: TradeAction
    let profit: Decimal?
    let profitPercentage: Double?
}

struct SignalActivity: Codable {
    let signalId: UUID
    let symbol: String
    let accuracy: Double?
    let subscribers: Int
}

struct AchievementActivity: Codable {
    let achievementId: UUID
    let title: String
    let rarity: AchievementRarity
}

struct PostActivity: Codable {
    let postId: UUID
    let title: String?
    let excerpt: String
    let type: PostType
}

enum PostType: String, Codable {
    case forum = "forum"
    case analysis = "analysis"
    case education = "education"
    case news = "news"
}

struct CommentActivity: Codable {
    let commentId: UUID
    let postId: UUID
    let excerpt: String
}

struct ReactionActivity: Codable {
    let targetId: UUID
    let targetType: String
    let reactionType: ReactionType
}

struct MilestoneActivity: Codable {
    let type: MilestoneType
    let value: Int
    let previousValue: Int
}

enum MilestoneType: String, Codable {
    case trades = "trades"
    case followers = "followers"
    case profitTarget = "profit_target"
    case winStreak = "win_streak"
    case reputation = "reputation"
}

struct StrategyActivity: Codable {
    let strategyId: UUID
    let name: String
    let performance: Double
    let subscribers: Int
}

// MARK: - Supporting Types

struct TypingIndicator: Codable {
    let userId: UUID
    let roomId: UUID
    let startedAt: Date
}

struct OnlineStatus: Codable {
    let userId: UUID
    let status: UserStatus
    let lastSeen: Date?
    let statusMessage: String?
}

enum UserStatus: String, Codable {
    case online = "online"
    case away = "away"
    case busy = "busy"
    case offline = "offline"
}

enum UserRole: String, Codable, CaseIterable {
    case user = "user"
    case premium = "premium"
    case mentor = "mentor"
    case moderator = "moderator"
    case admin = "admin"
    
    var permissions: Set<Permission> {
        switch self {
        case .user:
            return [.read, .write, .react]
        case .premium:
            return [.read, .write, .react, .createChannels, .hostEvents]
        case .mentor:
            return [.read, .write, .react, .createChannels, .hostEvents, .pin, .announce]
        case .moderator:
            return [.read, .write, .react, .createChannels, .hostEvents, .pin, .announce, .moderate, .delete]
        case .admin:
            return Permission.allCases.reduce(into: Set<Permission>()) { $0.insert($1) }
        }
    }
}

enum Permission: String, Codable, CaseIterable {
    case read = "read"
    case write = "write"
    case react = "react"
    case delete = "delete"
    case moderate = "moderate"
    case pin = "pin"
    case announce = "announce"
    case createChannels = "create_channels"
    case hostEvents = "host_events"
    case manageBadges = "manage_badges"
    case manageUsers = "manage_users"
}