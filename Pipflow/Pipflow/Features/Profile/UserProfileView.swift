//
//  UserProfileView.swift
//  Pipflow
//
//  Comprehensive user profile view with social features
//

import SwiftUI
import Charts

struct UserProfileView: View {
    let userId: UUID?  // nil for current user
    @StateObject private var profileService = UserProfileService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingFollowers = false
    @State private var showingFollowing = false
    @State private var isFollowing = false
    @State private var profile: UserProfile?
    
    private var isCurrentUser: Bool {
        userId == nil || userId == profileService.currentUserProfile?.id
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Header
                ProfileHeaderView(
                    profile: profile ?? profileService.currentUserProfile,
                    isCurrentUser: isCurrentUser,
                    isFollowing: $isFollowing,
                    onEditProfile: { showingEditProfile = true },
                    onFollowToggle: toggleFollow,
                    onMessage: sendMessage,
                    onShowFollowers: { showingFollowers = true },
                    onShowFollowing: { showingFollowing = true }
                )
                
                // Stats Overview
                if let profile = profile ?? profileService.currentUserProfile {
                    ProfileStatsView(stats: profile.stats)
                        .padding()
                }
                
                // Tab Selection
                ProfileTabSelector(selectedTab: $selectedTab)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Trading Performance
                    ProfileTradingView(profile: profile ?? profileService.currentUserProfile)
                        .tag(0)
                    
                    // Activity Feed
                    ProfileActivityView(
                        userId: profile?.id ?? profileService.currentUserProfile?.id ?? UUID()
                    )
                    .tag(1)
                    
                    // Achievements & Badges
                    ProfileAchievementsView(
                        profile: profile ?? profileService.currentUserProfile
                    )
                    .tag(2)
                    
                    // Shared Strategies (if applicable)
                    ProfileStrategiesView(
                        userId: profile?.id ?? profileService.currentUserProfile?.id ?? UUID()
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(minHeight: 400)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCurrentUser {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingSettings) {
            ProfileSettingsView()
        }
        .sheet(isPresented: $showingFollowers) {
            FollowListView(
                userId: profile?.id ?? profileService.currentUserProfile?.id ?? UUID(),
                listType: .followers
            )
        }
        .sheet(isPresented: $showingFollowing) {
            FollowListView(
                userId: profile?.id ?? profileService.currentUserProfile?.id ?? UUID(),
                listType: .following
            )
        }
        .onAppear {
            loadProfile()
        }
    }
    
    private func loadProfile() {
        if let userId = userId {
            Task {
                do {
                    profile = try await profileService.loadProfile(userId: userId)
                    isFollowing = profileService.isFollowing(userId)
                } catch {
                    print("Error loading profile: \(error)")
                }
            }
        } else {
            profile = profileService.currentUserProfile
        }
    }
    
    private func toggleFollow() {
        guard let userId = userId else { return }
        
        Task {
            do {
                if isFollowing {
                    try await profileService.unfollowUser(userId)
                } else {
                    try await profileService.followUser(userId)
                }
                isFollowing.toggle()
            } catch {
                print("Error toggling follow: \(error)")
            }
        }
    }
    
    private func sendMessage() {
        // Navigate to chat with this user
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    let profile: UserProfile?
    let isCurrentUser: Bool
    @Binding var isFollowing: Bool
    let onEditProfile: () -> Void
    let onFollowToggle: () -> Void
    let onMessage: () -> Void
    let onShowFollowers: () -> Void
    let onShowFollowing: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Cover Image
            Rectangle()
                .fill(LinearGradient(
                    colors: [
                        themeManager.currentTheme.accentColor.opacity(0.6),
                        themeManager.currentTheme.accentColor.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 150)
                .overlay(
                    // Profile Image
                    VStack {
                        Spacer()
                        ProfileImageView(profile: profile, size: 100)
                            .offset(y: 50)
                    }
                )
            
            // Profile Info
            VStack(spacing: 12) {
                // Spacer for profile image offset
                Color.clear.frame(height: 50)
                
                // Name and badges
                HStack(spacing: 8) {
                    Text(profile?.displayName ?? "User")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    if profile?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    
                    if profile?.isPro == true {
                        Text("PRO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                // Username
                Text("@\(profile?.username ?? "username")")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                // Bio
                if let bio = profile?.bio {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Stats
                HStack(spacing: 40) {
                    // Followers
                    Button(action: onShowFollowers) {
                        VStack(spacing: 4) {
                            Text("\(profile?.followerCount ?? 0)")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            Text("Followers")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    
                    // Following
                    Button(action: onShowFollowing) {
                        VStack(spacing: 4) {
                            Text("\(profile?.followingCount ?? 0)")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            Text("Following")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    
                    // Trades
                    VStack(spacing: 4) {
                        Text("\(profile?.stats.totalTrades ?? 0)")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        Text("Trades")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    if isCurrentUser {
                        Button(action: onEditProfile) {
                            Text("Edit Profile")
                                .font(.bodyMedium)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(themeManager.currentTheme.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    } else {
                        // Follow/Unfollow Button
                        Button(action: onFollowToggle) {
                            HStack {
                                Image(systemName: isFollowing ? "person.badge.minus" : "person.badge.plus")
                                Text(isFollowing ? "Unfollow" : "Follow")
                            }
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isFollowing ? themeManager.currentTheme.secondaryBackgroundColor : themeManager.currentTheme.accentColor)
                            .foregroundColor(isFollowing ? themeManager.currentTheme.textColor : .white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(themeManager.currentTheme.accentColor, lineWidth: isFollowing ? 1 : 0)
                            )
                        }
                        
                        // Message Button
                        Button(action: onMessage) {
                            Image(systemName: "envelope")
                                .font(.body)
                                .frame(width: 44, height: 44)
                                .background(themeManager.currentTheme.secondaryBackgroundColor)
                                .foregroundColor(themeManager.currentTheme.textColor)
                                .cornerRadius(8)
                        }
                        
                        // Copy Trading Button
                        if profile?.privacy.allowCopyTrading == true {
                            Button(action: {}) {
                                Image(systemName: "doc.on.doc")
                                    .font(.body)
                                    .frame(width: 44, height: 44)
                                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Additional Info
                HStack(spacing: 20) {
                    if let location = profile?.location {
                        Label(location, systemImage: "location")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    if let website = profile?.website {
                        Label("Website", systemImage: "link")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                    
                    Label("Joined \(profile?.createdAt.formatted(.dateTime.month().year()) ?? "")", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
        }
    }
}

// MARK: - Profile Image View
struct ProfileImageView: View {
    let profile: UserProfile?
    let size: CGFloat
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                .frame(width: size, height: size)
            
            if let avatarURL = profile?.avatarURL {
                // In production, load image from URL
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(themeManager.currentTheme.accentColor)
            } else {
                Text(profile?.initials ?? "?")
                    .font(.system(size: size * 0.4))
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
        }
        .overlay(
            Circle()
                .stroke(themeManager.currentTheme.backgroundColor, lineWidth: 4)
        )
        .overlay(
            // Online indicator
            Group {
                if profile?.isOnline == true {
                    Circle()
                        .fill(Color.green)
                        .frame(width: size * 0.2, height: size * 0.2)
                        .overlay(
                            Circle()
                                .stroke(themeManager.currentTheme.backgroundColor, lineWidth: 2)
                        )
                        .offset(x: size * 0.35, y: size * 0.35)
                }
            }
        )
    }
}

// MARK: - Tab Selector
struct ProfileTabSelector: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    let tabs = ["Trading", "Activity", "Achievements", "Strategies"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: { selectedTab = index }) {
                    Text(tabs[index])
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(
                            selectedTab == index
                                ? themeManager.currentTheme.accentColor
                                : themeManager.currentTheme.secondaryTextColor
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            VStack {
                                Spacer()
                                if selectedTab == index {
                                    Rectangle()
                                        .fill(themeManager.currentTheme.accentColor)
                                        .frame(height: 2)
                                }
                            }
                        )
                }
            }
        }
        .background(themeManager.currentTheme.secondaryBackgroundColor)
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        UserProfileView(userId: nil)
            .environmentObject(ThemeManager())
    }
}