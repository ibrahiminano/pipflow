//
//  UserProfileService.swift
//  Pipflow
//
//  Service for managing user profiles and social interactions
//

import Foundation
import SwiftUI
import Combine

@MainActor
class UserProfileService: ObservableObject {
    static let shared = UserProfileService()
    
    @Published var currentUserProfile: UserProfile?
    @Published var cachedProfiles: [UUID: UserProfile] = [:]
    @Published var followRequests: [FollowRequest] = []
    @Published var activityFeed: [ActivityFeedItem] = []
    @Published var suggestedUsers: [UserProfile] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupMockData()
        loadCurrentUserProfile()
        loadActivityFeed()
        loadSuggestedUsers()
    }
    
    // MARK: - Profile Management
    
    func loadCurrentUserProfile() {
        // In production, load from API/database
        currentUserProfile = UserProfile.mock
    }
    
    func loadProfile(userId: UUID) async throws -> UserProfile {
        // Check cache first
        if let cached = cachedProfiles[userId] {
            return cached
        }
        
        // In production, fetch from API
        // For now, return mock data with variations
        let profile = createMockProfile(userId: userId)
        cachedProfiles[userId] = profile
        return profile
    }
    
    func updateProfile(_ updates: ProfileUpdates) async throws {
        guard var profile = currentUserProfile else { return }
        
        // Apply updates
        if let displayName = updates.displayName {
            profile.displayName = displayName
        }
        if let bio = updates.bio {
            profile.bio = bio
        }
        if let location = updates.location {
            profile.location = location
        }
        if let website = updates.website {
            profile.website = website
        }
        if let tradingStyle = updates.tradingStyle {
            profile.tradingStyle = tradingStyle
        }
        if let riskLevel = updates.riskLevel {
            profile.riskLevel = riskLevel
        }
        if let preferredMarkets = updates.preferredMarkets {
            profile.preferredMarkets = preferredMarkets
        }
        
        profile.updatedAt = Date()
        
        // In production, save to API
        currentUserProfile = profile
    }
    
    func updatePrivacySettings(_ settings: PrivacySettings) async throws {
        guard var profile = currentUserProfile else { return }
        profile.privacy = settings
        profile.updatedAt = Date()
        currentUserProfile = profile
    }
    
    func updateNotificationSettings(_ settings: NotificationSettings) async throws {
        guard var profile = currentUserProfile else { return }
        profile.notifications = settings
        profile.updatedAt = Date()
        currentUserProfile = profile
    }
    
    // MARK: - Social Interactions
    
    func followUser(_ userId: UUID) async throws {
        guard var profile = currentUserProfile else { return }
        
        // Add to following
        profile.following.insert(userId)
        currentUserProfile = profile
        
        // Update target user's followers
        if var targetProfile = cachedProfiles[userId] {
            targetProfile.followers.insert(profile.id)
            cachedProfiles[userId] = targetProfile
        }
        
        // Add to activity feed
        let activity = ActivityFeedItem(
            id: UUID(),
            userId: profile.id,
            timestamp: Date(),
            type: .follow,
            content: .follow(targetUserId: userId),
            relatedUsers: [userId],
            metadata: [:]
        )
        activityFeed.insert(activity, at: 0)
        
        // Send notification to target user
        // In production, this would trigger a push notification
    }
    
    func unfollowUser(_ userId: UUID) async throws {
        guard var profile = currentUserProfile else { return }
        
        // Remove from following
        profile.following.remove(userId)
        currentUserProfile = profile
        
        // Update target user's followers
        if var targetProfile = cachedProfiles[userId] {
            targetProfile.followers.remove(profile.id)
            cachedProfiles[userId] = targetProfile
        }
    }
    
    func isFollowing(_ userId: UUID) -> Bool {
        currentUserProfile?.following.contains(userId) ?? false
    }
    
    func isFollowedBy(_ userId: UUID) -> Bool {
        currentUserProfile?.followers.contains(userId) ?? false
    }
    
    func blockUser(_ userId: UUID) async throws {
        guard var profile = currentUserProfile else { return }
        
        // Add to blocked users
        profile.blockedUsers.insert(userId)
        
        // Remove from following/followers
        profile.following.remove(userId)
        profile.followers.remove(userId)
        
        currentUserProfile = profile
    }
    
    func unblockUser(_ userId: UUID) async throws {
        guard var profile = currentUserProfile else { return }
        profile.blockedUsers.remove(userId)
        currentUserProfile = profile
    }
    
    // MARK: - Activity Feed
    
    func loadActivityFeed() {
        // In production, fetch from API
        // For now, generate mock activity
        activityFeed = generateMockActivityFeed()
    }
    
    func refreshActivityFeed() async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        loadActivityFeed()
    }
    
    // MARK: - User Discovery
    
    func loadSuggestedUsers() {
        // In production, fetch from recommendation API
        suggestedUsers = generateSuggestedUsers()
    }
    
    func searchUsers(query: String) async throws -> [UserProfile] {
        // In production, search API
        // For now, filter mock users
        guard !query.isEmpty else { return [] }
        
        return suggestedUsers.filter { user in
            user.displayName.localizedCaseInsensitiveContains(query) ||
            user.username.localizedCaseInsensitiveContains(query) ||
            (user.bio?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func setupMockData() {
        // Create some mock profiles
        let mockUserIds = (0..<10).map { _ in UUID() }
        for userId in mockUserIds {
            cachedProfiles[userId] = createMockProfile(userId: userId)
        }
    }
    
    private func createMockProfile(userId: UUID) -> UserProfile {
        let names = ["Alex Chen", "Sarah Johnson", "Mike Williams", "Emma Davis", "Carlos Rodriguez", "Lisa Anderson", "David Kim", "Maria Garcia", "Tom Wilson", "Jessica Lee"]
        let randomIndex = Int.random(in: 0..<names.count)
        let name = names[randomIndex]
        let username = name.lowercased().replacingOccurrences(of: " ", with: "_")
        
        return UserProfile(
            id: userId,
            username: username,
            displayName: name,
            email: "\(username)@example.com",
            bio: "Professional trader specializing in \(["forex", "crypto", "stocks", "commodities"].randomElement()!) markets.",
            avatarURL: nil,
            coverImageURL: nil,
            location: ["New York", "London", "Tokyo", "Singapore", "Dubai"].randomElement(),
            website: nil,
            socialLinks: SocialLinks(),
            tradingExperience: TradingExperience.allCases.randomElement()!,
            preferredMarkets: ["Forex", "Crypto", "Stocks"].shuffled().prefix(2).map { $0 },
            tradingStyle: TradingStyle.allCases.randomElement()!,
            riskLevel: RiskLevel.allCases.randomElement()!,
            stats: UserStats(
                totalTrades: Int.random(in: 100...2000),
                winRate: Double.random(in: 0.55...0.75),
                profitFactor: Double.random(in: 1.2...3.5),
                sharpeRatio: Double.random(in: 0.5...2.5),
                maxDrawdown: Double.random(in: 0.05...0.25),
                monthlyReturn: Double.random(in: -0.05...0.25),
                totalReturn: Double.random(in: 0.5...5.0),
                averageWin: Double.random(in: 50...200),
                averageLoss: Double.random(in: 20...100),
                bestTrade: Double.random(in: 200...1000),
                worstTrade: Double.random(in: -200 ... -50),
                currentStreak: Int.random(in: -3...8),
                longestWinStreak: Int.random(in: 5...15),
                longestLossStreak: Int.random(in: 2...6),
                tradingDays: Int.random(in: 30...500),
                lastUpdated: Date()
            ),
            achievements: [],
            badges: [],
            followers: Set((0..<Int.random(in: 10...1000)).map { _ in UUID() }),
            following: Set((0..<Int.random(in: 5...200)).map { _ in UUID() }),
            blockedUsers: Set(),
            privacy: PrivacySettings(
                profileVisibility: .everyone,
                showTradingStats: true,
                showFollowers: true,
                allowDirectMessages: .everyone,
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
                likes: true,
                newLessons: true,
                achievementUnlocked: true,
                courseUpdates: true,
                systemUpdates: true,
                promotions: false,
                weeklyReport: true
            ),
            createdAt: Date().addingTimeInterval(TimeInterval(-Int.random(in: 30...365) * 24 * 60 * 60)),
            updatedAt: Date(),
            lastActive: Date().addingTimeInterval(TimeInterval(-Int.random(in: 0...48) * 60 * 60)),
            isVerified: Bool.random(),
            isPro: Bool.random(),
            isOnline: Bool.random()
        )
    }
    
    private func generateMockActivityFeed() -> [ActivityFeedItem] {
        var activities: [ActivityFeedItem] = []
        
        // Generate various activity types
        for i in 0..<20 {
            let userId = cachedProfiles.keys.randomElement() ?? UUID()
            let timestamp = Date().addingTimeInterval(TimeInterval(-i * 3600))
            
            let activityType = ActivityFeedItem.ActivityType.allCases.randomElement()!
            var content: ActivityFeedItem.ActivityContent
            var relatedUsers: [UUID] = []
            
            switch activityType {
            case .trade:
                content = .trade(
                    symbol: ["EURUSD", "GBPUSD", "BTCUSD", "ETHUSD"].randomElement()!,
                    side: Bool.random() ? TradeSide.buy : TradeSide.sell,
                    profit: Double.random(in: -200...500)
                )
            case .follow:
                let targetId = cachedProfiles.keys.randomElement() ?? UUID()
                content = .follow(targetUserId: targetId)
                relatedUsers = [targetId]
            case .achievement:
                content = .achievement(achievementId: "profitable_week")
            case .post:
                content = .post(postId: UUID(), preview: "Just closed a great trade on EURUSD...")
            case .comment:
                content = .comment(postId: UUID(), commentId: UUID(), preview: "Great analysis!")
            case .like:
                content = .like(postId: UUID())
            case .share:
                content = .share(postId: UUID())
            case .milestone:
                content = .milestone(type: "trades", value: "1000")
            }
            
            activities.append(ActivityFeedItem(
                id: UUID(),
                userId: userId,
                timestamp: timestamp,
                type: activityType,
                content: content,
                relatedUsers: relatedUsers,
                metadata: [:]
            ))
        }
        
        return activities
    }
    
    private func generateSuggestedUsers() -> [UserProfile] {
        // Return some random profiles from cache
        Array(cachedProfiles.values.shuffled().prefix(5))
    }
}

// MARK: - Supporting Types

struct ProfileUpdates {
    var displayName: String?
    var bio: String?
    var location: String?
    var website: String?
    var avatarURL: String?
    var coverImageURL: String?
    var tradingStyle: TradingStyle?
    var riskLevel: RiskLevel?
    var preferredMarkets: [String]?
    var socialLinks: SocialLinks?
}

