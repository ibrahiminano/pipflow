//
//  ProfileAchievementsView.swift
//  Pipflow
//
//  Achievements and badges tab for user profile
//

import SwiftUI

struct ProfileAchievementsView: View {
    let profile: UserProfile?
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedCategory: UserBadge.BadgeCategory?
    
    var filteredBadges: [UserBadge] {
        guard let selectedCategory = selectedCategory else {
            return profile?.badges ?? []
        }
        return profile?.badges.filter { $0.category == selectedCategory } ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        AchievementCategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        ForEach([UserBadge.BadgeCategory.trading, .social, .education, .achievement, .special], id: \.self) { category in
                            AchievementCategoryChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Badges Grid
                if filteredBadges.isEmpty {
                    EmptyBadgesView(category: selectedCategory)
                        .padding(.top, 50)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredBadges) { badge in
                            BadgeItemView(badge: badge)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Stats Overview
                AchievementStatsView(profile: profile)
                    .padding(.horizontal)
                
                // Achievement Progress
                AchievementProgressView()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Badge Item View
struct BadgeItemView: View {
    let badge: UserBadge
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingDetail = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Badge Icon
            ZStack {
                Circle()
                    .fill(badge.rarity.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: badge.icon)
                    .font(.title2)
                    .foregroundColor(badge.rarity.color)
            }
            
            // Badge Name
            Text(badge.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 30)
            
            // Rarity
            Text(badge.rarity.rawValue)
                .font(.caption2)
                .foregroundColor(badge.rarity.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            BadgeDetailView(badge: badge)
        }
    }
}

// MARK: - Badge Detail View
struct BadgeDetailView: View {
    let badge: UserBadge
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Badge Display
                ZStack {
                    Circle()
                        .fill(badge.rarity.color.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: badge.icon)
                        .font(.system(size: 60))
                        .foregroundColor(badge.rarity.color)
                }
                
                // Badge Info
                VStack(spacing: 12) {
                    Text(badge.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    HStack {
                        Label(badge.category.rawValue, systemImage: "tag")
                        Text("•")
                        Text(badge.rarity.rawValue)
                            .foregroundColor(badge.rarity.color)
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Text(badge.description)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Earned on \(badge.earnedAt.formatted(.dateTime.day().month().year()))")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                // Share Button
                Button(action: {}) {
                    Label("Share Achievement", systemImage: "square.and.arrow.up")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(themeManager.currentTheme.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Badge Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Achievement Stats
struct AchievementStatsView: View {
    let profile: UserProfile?
    @EnvironmentObject var themeManager: ThemeManager
    
    var totalBadges: Int { profile?.badges.count ?? 0 }
    var legendaryCount: Int { profile?.badges.filter { $0.rarity == .legendary }.count ?? 0 }
    var epicCount: Int { profile?.badges.filter { $0.rarity == .epic }.count ?? 0 }
    var rareCount: Int { profile?.badges.filter { $0.rarity == .rare }.count ?? 0 }
    var commonCount: Int { profile?.badges.filter { $0.rarity == .common }.count ?? 0 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievement Stats")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            HStack(spacing: 20) {
                // Total Count
                VStack(spacing: 8) {
                    Text("\(totalBadges)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Total Badges")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                // Rarity Breakdown
                VStack(alignment: .leading, spacing: 6) {
                    RarityRow(rarity: .legendary, count: legendaryCount)
                    RarityRow(rarity: .epic, count: epicCount)
                    RarityRow(rarity: .rare, count: rareCount)
                    RarityRow(rarity: .common, count: commonCount)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct RarityRow: View {
    let rarity: UserBadge.BadgeRarity
    let count: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(rarity.color)
                .frame(width: 8, height: 8)
            
            Text(rarity.rawValue)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.textColor)
        }
        .frame(width: 120)
    }
}

// MARK: - Achievement Progress
struct AchievementProgressView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    // Mock progress data
    let progressItems = [
        ("Trade Master", "Complete 1000 trades", 0.75),
        ("Profit Streak", "7 profitable days in a row", 0.57),
        ("Social Butterfly", "Follow 50 traders", 0.34),
        ("Knowledge Seeker", "Complete 10 courses", 0.9)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In Progress")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            VStack(spacing: 16) {
                ForEach(progressItems, id: \.0) { item in
                    ProgressItemView(
                        title: item.0,
                        description: item.1,
                        progress: item.2
                    )
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct ProgressItemView: View {
    let title: String
    let description: String
    let progress: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(themeManager.currentTheme.backgroundColor)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(themeManager.currentTheme.accentColor)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Supporting Views
struct AchievementCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(
                    isSelected
                        ? .white
                        : themeManager.currentTheme.secondaryTextColor
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? themeManager.currentTheme.accentColor
                        : themeManager.currentTheme.backgroundColor
                )
                .cornerRadius(20)
        }
    }
}

struct EmptyBadgesView: View {
    let category: UserBadge.BadgeCategory?
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text("No \(category?.rawValue ?? "Badges") Yet")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text("Keep trading and engaging with the community to earn badges!")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}