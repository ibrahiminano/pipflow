//
//  FollowListView.swift
//  Pipflow
//
//  View for displaying followers and following lists
//

import SwiftUI

struct FollowListView: View {
    let userId: UUID
    let listType: ListType
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileService = UserProfileService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var users: [UserProfile] = []
    @State private var isLoading = false
    
    enum ListType {
        case followers
        case following
        
        var title: String {
            switch self {
            case .followers: return "Followers"
            case .following: return "Following"
            }
        }
    }
    
    var filteredUsers: [UserProfile] {
        if searchText.isEmpty {
            return users
        }
        return users.filter { user in
            user.displayName.localizedCaseInsensitiveContains(searchText) ||
            user.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, placeholder: "Search users...")
                    .padding()
                
                // User List
                if isLoading {
                    Spacer()
                    ProgressView("Loading...")
                        .padding()
                    Spacer()
                } else if users.isEmpty {
                    EmptyFollowListView(listType: listType)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredUsers) { user in
                                FollowUserRow(user: user)
                                
                                if user.id != filteredUsers.last?.id {
                                    Divider()
                                        .background(themeManager.currentTheme.separatorColor)
                                        .padding(.leading, 72)
                                }
                            }
                        }
                    }
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle(listType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadUsers()
        }
    }
    
    private func loadUsers() {
        isLoading = true
        
        Task {
            // In production, fetch from API based on listType
            // For now, use mock data
            let profile = userId == profileService.currentUserProfile?.id
                ? profileService.currentUserProfile
                : profileService.cachedProfiles[userId]
            
            let userIds: [UUID]
            switch listType {
            case .followers:
                userIds = Array(profile?.followers ?? [])
            case .following:
                userIds = Array(profile?.following ?? [])
            }
            
            // Load user profiles
            var loadedUsers: [UserProfile] = []
            for id in userIds.prefix(20) { // Limit to first 20 for demo
                if let user = try? await profileService.loadProfile(userId: id) {
                    loadedUsers.append(user)
                }
            }
            
            users = loadedUsers
            isLoading = false
        }
    }
}

// MARK: - Follow User Row
struct FollowUserRow: View {
    let user: UserProfile
    @StateObject private var profileService = UserProfileService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isFollowing: Bool = false
    @State private var showingProfile = false
    
    var isCurrentUser: Bool {
        user.id == profileService.currentUserProfile?.id
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ProfileImageView(profile: user, size: 48)
                .onTapGesture {
                    showingProfile = true
                }
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(user.displayName)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if user.isPro {
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                if let bio = user.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Follow Button
            if !isCurrentUser {
                FollowButton(
                    isFollowing: $isFollowing,
                    action: toggleFollow
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            showingProfile = true
        }
        .sheet(isPresented: $showingProfile) {
            NavigationView {
                UserProfileView(userId: user.id)
            }
        }
        .onAppear {
            isFollowing = profileService.isFollowing(user.id)
        }
    }
    
    private func toggleFollow() {
        Task {
            do {
                if isFollowing {
                    try await profileService.unfollowUser(user.id)
                } else {
                    try await profileService.followUser(user.id)
                }
                isFollowing.toggle()
            } catch {
                print("Error toggling follow: \(error)")
            }
        }
    }
}

// MARK: - Follow Button
struct FollowButton: View {
    @Binding var isFollowing: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(isFollowing ? "Following" : "Follow")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isFollowing ? themeManager.currentTheme.textColor : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    isFollowing
                        ? themeManager.currentTheme.secondaryBackgroundColor
                        : themeManager.currentTheme.accentColor
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFollowing
                                ? themeManager.currentTheme.separatorColor
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Empty State
struct EmptyFollowListView: View {
    let listType: FollowListView.ListType
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: listType == .followers ? "person.2" : "person.crop.circle.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text(emptyTitle)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(emptyMessage)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyTitle: String {
        switch listType {
        case .followers:
            return "No Followers Yet"
        case .following:
            return "Not Following Anyone"
        }
    }
    
    private var emptyMessage: String {
        switch listType {
        case .followers:
            return "When people follow this account, they'll appear here."
        case .following:
            return "When this account follows people, they'll appear here."
        }
    }
}

#Preview {
    FollowListView(userId: UUID(), listType: .followers)
        .environmentObject(ThemeManager())
}