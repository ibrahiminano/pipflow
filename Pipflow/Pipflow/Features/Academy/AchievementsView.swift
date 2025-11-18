//
//  AchievementsView.swift
//  Pipflow
//
//  View for displaying user achievements and badges
//

import SwiftUI

struct AchievementsView: View {
    let achievements: [Achievement]
    let userAchievements: Set<UUID>
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var showingAchievementDetail: Achievement?
    
    var categories: [AchievementCategory?] {
        [nil] + AchievementCategory.allCases
    }
    
    var filteredAchievements: [Achievement] {
        if let selectedCategory = selectedCategory {
            return achievements.filter { $0.category == selectedCategory }
        } else {
            return achievements
        }
    }
    
    var unlockedCount: Int {
        achievements.filter { userAchievements.contains($0.id) }.count
    }
    
    var progressPercentage: Int {
        guard !achievements.isEmpty else { return 0 }
        return (unlockedCount * 100) / achievements.count
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Achievement Stats
            AcademyAchievementStatsView(
                totalAchievements: achievements.count,
                unlockedAchievements: unlockedCount,
                progressPercentage: progressPercentage,
                totalPoints: calculateTotalPoints()
            )
            .padding(.horizontal)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        CategoryFilterButton(
                            title: formatCategory(category),
                            isSelected: selectedCategory == category,
                            action: {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Achievement Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementCard(
                            achievement: achievement,
                            isUnlocked: userAchievements.contains(achievement.id),
                            onTap: {
                                showingAchievementDetail = achievement
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .sheet(item: $showingAchievementDetail) { achievement in
            AchievementDetailView(
                achievement: achievement,
                isUnlocked: userAchievements.contains(achievement.id)
            )
            .environmentObject(themeManager)
        }
    }
    
    private func calculateTotalPoints() -> Int {
        achievements
            .filter { userAchievements.contains($0.id) }
            .reduce(0) { $0 + $1.points }
    }
    
    private func formatCategory(_ category: AchievementCategory?) -> String {
        guard let category = category else {
            return "All"
        }
        return category.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Achievement Stats View
struct AcademyAchievementStatsView: View {
    let totalAchievements: Int
    let unlockedAchievements: Int
    let progressPercentage: Int
    let totalPoints: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Achievements")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("\(unlockedAchievements) of \(totalAchievements) unlocked")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(
                            themeManager.currentTheme.secondaryBackgroundColor,
                            lineWidth: 8
                        )
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progressPercentage) / 100)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    themeManager.currentTheme.accentColor,
                                    themeManager.currentTheme.accentColor.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progressPercentage)
                    
                    Text("\(progressPercentage)%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
            
            // Points Display
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                Text("\(totalPoints)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text("Total Points")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Spacer()
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bodyMedium)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryBackgroundColor
                )
                .cornerRadius(20)
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            isUnlocked
                                ? LinearGradient(
                                    colors: [
                                        colorForRarity(achievement.rarity),
                                        colorForRarity(achievement.rarity).opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        themeManager.currentTheme.secondaryBackgroundColor,
                                        themeManager.currentTheme.secondaryBackgroundColor
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: achievement.icon)
                        .font(.title)
                        .foregroundColor(isUnlocked ? .white : themeManager.currentTheme.secondaryTextColor)
                    
                    if !isUnlocked {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                
                // Title
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Points
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(isUnlocked ? .yellow : .gray)
                    Text("\(achievement.points)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isUnlocked ? themeManager.currentTheme.textColor : themeManager.currentTheme.secondaryTextColor)
                }
                
                // Rarity
                Text(achievement.rarity.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isUnlocked ? colorForRarity(achievement.rarity) : themeManager.currentTheme.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isUnlocked ? colorForRarity(achievement.rarity).opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorForRarity(_ rarity: AchievementRarity) -> Color {
        switch rarity {
        case .common:
            return .gray
        case .uncommon:
            return .green
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return .orange
        }
    }
}

// MARK: - Achievement Detail View
struct AchievementDetailView: View {
    let achievement: Achievement
    let isUnlocked: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Achievement Icon
                    ZStack {
                        Circle()
                            .fill(
                                isUnlocked
                                    ? LinearGradient(
                                        colors: [
                                            colorForRarity(achievement.rarity),
                                            colorForRarity(achievement.rarity).opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [
                                            themeManager.currentTheme.secondaryBackgroundColor,
                                            themeManager.currentTheme.secondaryBackgroundColor
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: achievement.icon)
                            .font(.system(size: 50))
                            .foregroundColor(isUnlocked ? .white : themeManager.currentTheme.secondaryTextColor)
                        
                        if !isUnlocked {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Title and Description
                    VStack(spacing: 12) {
                        Text(achievement.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .multilineTextAlignment(.center)
                        
                        Text(achievement.description)
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Stats
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.title3)
                                    .foregroundColor(.yellow)
                                Text("\(achievement.points)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                            }
                            Text("Points")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        VStack(spacing: 4) {
                            Text(achievement.rarity.rawValue.capitalized)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(colorForRarity(achievement.rarity))
                            Text("Rarity")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    
                    // Progress or Unlock Condition
                    if !isUnlocked {
                        VStack(spacing: 12) {
                            Text("How to Unlock")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Text(getUnlockHint(for: achievement))
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(themeManager.currentTheme.secondaryBackgroundColor)
                                .cornerRadius(12)
                        }
                    } else if let dateEarned = achievement.dateEarned {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            
                            Text("Unlocked on \(formatDate(dateEarned))")
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    
                    // Share Button (if unlocked)
                    if isUnlocked {
                        Button(action: shareAchievement) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Achievement")
                            }
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.currentTheme.accentColor)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
    }
    
    private func colorForRarity(_ rarity: AchievementRarity) -> Color {
        switch rarity {
        case .common:
            return .gray
        case .uncommon:
            return .green
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return .orange
        }
    }
    
    private func getUnlockHint(for achievement: Achievement) -> String {
        switch achievement.category {
        case .learning:
            return "Complete courses and lessons to unlock this achievement"
        case .trading:
            return "Make successful trades to unlock this achievement"
        case .social:
            return "Engage with the community to unlock this achievement"
        case .streak:
            return "Maintain a consistent learning streak to unlock this achievement"
        case .practice:
            return "Complete practice exercises to unlock this achievement"
        case .mastery:
            return "Master advanced trading concepts to unlock this achievement"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func shareAchievement() {
        // Implement share functionality
    }
}

#Preview {
    AchievementsView(
        achievements: [
            Achievement(
                id: UUID(),
                title: "First Steps",
                description: "Complete your first lesson",
                icon: "graduationcap.fill",
                category: .learning,
                requirement: .completeCourses(count: 1),
                points: 10,
                rarity: .common
            ),
            Achievement(
                id: UUID(),
                title: "Trading Master",
                description: "Execute 100 successful trades",
                icon: "chart.line.uptrend.xyaxis",
                category: .trading,
                requirement: .completeCourses(count: 5),
                points: 100,
                rarity: .legendary
            )
        ],
        userAchievements: [UUID()]
    )
    .environmentObject(ThemeManager())
}