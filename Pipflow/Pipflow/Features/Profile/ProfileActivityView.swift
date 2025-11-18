//
//  ProfileActivityView.swift
//  Pipflow
//
//  Activity feed tab for user profile
//

import SwiftUI

struct ProfileActivityView: View {
    let userId: UUID
    @StateObject private var profileService = UserProfileService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isRefreshing = false
    
    var userActivities: [ActivityFeedItem] {
        profileService.activityFeed.filter { $0.userId == userId }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if userActivities.isEmpty {
                    EmptyActivityView()
                        .padding(.top, 50)
                } else {
                    ForEach(userActivities) { activity in
                        ActivityItemView(activity: activity)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await refreshActivities()
        }
    }
    
    private func refreshActivities() async {
        await profileService.refreshActivityFeed()
    }
}

// MARK: - Activity Item View
struct ActivityItemView: View {
    let activity: ActivityFeedItem
    @StateObject private var profileService = UserProfileService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var user: UserProfile? {
        profileService.cachedProfiles[activity.userId] ?? profileService.currentUserProfile
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User Avatar
            ProfileImageView(profile: user, size: 40)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user?.displayName ?? "User")
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text(activity.timestamp.relative())
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    activityIcon
                }
                
                // Activity Content
                activityContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var activityIcon: some View {
        Group {
            switch activity.type {
            case .trade:
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(themeManager.currentTheme.accentColor)
            case .follow:
                Image(systemName: "person.badge.plus")
                    .foregroundColor(.blue)
            case .achievement:
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
            case .post:
                Image(systemName: "square.and.pencil")
                    .foregroundColor(themeManager.currentTheme.accentColor)
            case .comment:
                Image(systemName: "bubble.left")
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            case .like:
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            case .share:
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            case .milestone:
                Image(systemName: "flag.checkered")
                    .foregroundColor(.purple)
            }
        }
        .font(.caption)
    }
    
    @ViewBuilder
    private var activityContent: some View {
        switch activity.content {
        case .trade(let symbol, let side, let profit):
            TradeActivityContent(symbol: symbol, side: side, profit: profit)
            
        case .follow(let targetUserId):
            FollowActivityContent(targetUserId: targetUserId)
            
        case .achievement(let achievementId):
            AchievementActivityContent(achievementId: achievementId)
            
        case .post(_, let preview):
            PostActivityContent(preview: preview)
            
        case .comment(_, _, let preview):
            CommentActivityContent(preview: preview)
            
        case .like(_):
            LikeActivityContent()
            
        case .share(_):
            ShareActivityContent()
            
        case .milestone(let type, let value):
            MilestoneActivityContent(type: type, value: value)
        }
    }
}

// MARK: - Activity Content Types
struct TradeActivityContent: View {
    let symbol: String
    let side: TradeSide
    let profit: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Closed \(side.rawValue) position on \(symbol)")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            HStack {
                Text(profit >= 0 ? "+$\(Int(profit))" : "-$\(Int(abs(profit)))")
                    .font(.headline)
                    .foregroundColor(profit >= 0 ? Color.green : Color.red)
                
                Text("(\(profit >= 0 ? "+" : "")\(Int(profit / 100))%)")
                    .font(.caption)
                    .foregroundColor(profit >= 0 ? Color.green : Color.red)
            }
        }
    }
}

struct FollowActivityContent: View {
    let targetUserId: UUID
    @StateObject private var profileService = UserProfileService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var targetUser: UserProfile? {
        profileService.cachedProfiles[targetUserId]
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Started following")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            if let targetUser = targetUser {
                HStack(spacing: 4) {
                    ProfileImageView(profile: targetUser, size: 24)
                    
                    Text(targetUser.displayName)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
    }
}

struct AchievementActivityContent: View {
    let achievementId: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Unlocked Achievement")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text("Profitable Week")
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PostActivityContent: View {
    let preview: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Published a new post")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(preview)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .lineLimit(2)
        }
    }
}

struct CommentActivityContent: View {
    let preview: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Commented on a post")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(preview)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .italic()
                .lineLimit(2)
        }
    }
}

struct LikeActivityContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Text("Liked a post")
            .font(.body)
            .foregroundColor(themeManager.currentTheme.textColor)
    }
}

struct ShareActivityContent: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Text("Shared a post")
            .font(.body)
            .foregroundColor(themeManager.currentTheme.textColor)
    }
}

struct MilestoneActivityContent: View {
    let type: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .font(.title3)
                .foregroundColor(.purple)
            
            Text("Reached \(value) \(type)!")
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Empty State
struct EmptyActivityView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text("No Activity Yet")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text("When you trade, follow others, or achieve milestones, your activity will appear here.")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// Date extension removed - using the one from Date+Extensions.swift