//
//  LeaderboardView.swift
//  Pipflow
//
//  Strategy and trader leaderboard
//

import SwiftUI
import Charts

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: LeaderboardCategory = .overall
    @State private var selectedTimeframe = "All Time"
    @State private var showStrategyDetail = false
    @State private var selectedStrategy: SharedStrategy?
    
    let timeframes = ["All Time", "This Month", "This Week", "Today"]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                                LeaderboardCategoryChip(
                                    title: categoryTitle(category),
                                    isSelected: selectedCategory == category,
                                    theme: themeManager.currentTheme
                                ) {
                                    selectedCategory = category
                                    viewModel.updateLeaderboard(category: category)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Timeframe Selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(timeframes, id: \.self) { timeframe in
                            Text(timeframe).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    // Leaderboard List
                    if viewModel.isLoading {
                        ProgressView("Loading leaderboard...")
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                            .padding(.top, 50)
                    } else if viewModel.leaderboard.isEmpty {
                        EmptyStateView(
                            icon: "chart.bar.xaxis",
                            title: "No Data Available",
                            description: "Check back later for leaderboard updates",
                            theme: themeManager.currentTheme
                        )
                        .padding(.top, 50)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                // Top 3
                                if viewModel.leaderboard.count >= 3 {
                                    Top3View(
                                        entries: Array(viewModel.leaderboard.prefix(3)),
                                        theme: themeManager.currentTheme
                                    ) { strategy in
                                        selectedStrategy = strategy
                                        showStrategyDetail = true
                                    }
                                }
                                
                                // Rest of leaderboard
                                ForEach(Array(viewModel.leaderboard.dropFirst(3))) { entry in
                                    LeaderboardRow(
                                        entry: entry,
                                        theme: themeManager.currentTheme
                                    ) {
                                        selectedStrategy = entry.strategy.toSharedStrategy()
                                        showStrategyDetail = true
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.refreshLeaderboard) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showStrategyDetail) {
            if let strategy = selectedStrategy {
                StrategyDetailView(strategy: strategy)
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            viewModel.updateLeaderboard(category: selectedCategory)
        }
    }
    
    private func categoryTitle(_ category: LeaderboardCategory) -> String {
        switch category {
        case .overall: return "Overall"
        case .monthly: return "Monthly"
        case .riskAdjusted: return "Risk Adjusted"
        case .consistency: return "Consistency"
        case .popularity: return "Popularity"
        case .newStrategies: return "New Stars"
        }
    }
}

// MARK: - Top 3 View

struct Top3View: View {
    let entries: [StrategyLeaderboardEntry]
    let theme: Theme
    let onSelect: (SharedStrategy) -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // 2nd Place
            if entries.count > 1 {
                Top3Card(
                    entry: entries[1],
                    rank: 2,
                    height: 120,
                    theme: theme,
                    onTap: { onSelect(entries[1].strategy.toSharedStrategy()) }
                )
            }
            
            // 1st Place
            if entries.count > 0 {
                Top3Card(
                    entry: entries[0],
                    rank: 1,
                    height: 140,
                    theme: theme,
                    onTap: { onSelect(entries[0].strategy.toSharedStrategy()) }
                )
            }
            
            // 3rd Place
            if entries.count > 2 {
                Top3Card(
                    entry: entries[2],
                    rank: 3,
                    height: 100,
                    theme: theme,
                    onTap: { onSelect(entries[2].strategy.toSharedStrategy()) }
                )
            }
        }
        .padding(.vertical)
    }
}

struct Top3Card: View {
    let entry: StrategyLeaderboardEntry
    let rank: Int
    let height: CGFloat
    let theme: Theme
    let onTap: () -> Void
    
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.7)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Crown/Medal
                Image(systemName: rank == 1 ? "crown.fill" : "medal.fill")
                    .font(.system(size: 24))
                    .foregroundColor(rankColor)
                
                // Author Avatar
                Image(systemName: entry.strategy.authorAvatar ?? "person.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(theme.accentColor)
                
                // Strategy Name
                Text(entry.strategy.strategy.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Score
                Text(formatScore(entry.score, category: entry.category))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.accentColor)
                
                // Rank Change
                if entry.change != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: entry.change > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10))
                        Text("\(abs(entry.change))")
                            .font(.caption2)
                    }
                    .foregroundColor(entry.change > 0 ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .padding()
            .background(theme.secondaryBackgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(rankColor, lineWidth: 2)
            )
        }
    }
    
    private func formatScore(_ score: Double, category: LeaderboardCategory) -> String {
        switch category {
        case .overall, .monthly:
            return String(format: "%.1f%%", score)
        case .riskAdjusted:
            return String(format: "%.2f", score)
        case .consistency:
            return String(format: "%.0f%%", score * 100)
        case .popularity:
            return "\(Int(score))"
        case .newStrategies:
            return String(format: "%.1f", score)
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: StrategyLeaderboardEntry
    let theme: Theme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Rank
                ZStack {
                    Circle()
                        .fill(theme.secondaryBackgroundColor)
                        .frame(width: 40, height: 40)
                    
                    Text("\(entry.rank)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.textColor)
                }
                
                // Strategy Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.strategy.strategy.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    HStack(spacing: 8) {
                        Text(entry.strategy.authorName)
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        
                        if entry.strategy.authorVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(theme.accentColor)
                        }
                    }
                }
                
                Spacer()
                
                // Score & Change
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatScore(entry.score, category: entry.category))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textColor)
                    
                    if entry.change != 0 {
                        HStack(spacing: 2) {
                            Image(systemName: entry.change > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10))
                            Text("\(abs(entry.change))")
                                .font(.caption)
                        }
                        .foregroundColor(entry.change > 0 ? .green : .red)
                    }
                }
            }
            .padding()
            .background(theme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
    }
    
    private func formatScore(_ score: Double, category: LeaderboardCategory) -> String {
        switch category {
        case .overall, .monthly:
            return String(format: "%.1f%%", score)
        case .riskAdjusted:
            return String(format: "%.2f", score)
        case .consistency:
            return String(format: "%.0f%%", score * 100)
        case .popularity:
            return "\(Int(score))"
        case .newStrategies:
            return String(format: "%.1f", score)
        }
    }
}

// MARK: - Category Chip

struct LeaderboardCategoryChip: View {
    let title: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? theme.accentColor : theme.secondaryBackgroundColor)
                .cornerRadius(20)
        }
    }
}

// MARK: - View Model

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var leaderboard: [StrategyLeaderboardEntry] = []
    @Published var isLoading = false
    
    private let socialService = SocialTradingServiceV2.shared
    
    func updateLeaderboard(category: LeaderboardCategory) {
        isLoading = true
        
        // Update leaderboard in service
        socialService.updateLeaderboard(category: category)
        
        // Get updated leaderboard
        leaderboard = socialService.leaderboard
        
        isLoading = false
    }
    
    func refreshLeaderboard() {
        if let currentCategory = leaderboard.first?.category {
            updateLeaderboard(category: currentCategory)
        }
    }
}

// MARK: - Extensions

extension LeaderboardCategory: CaseIterable {
    static var allCases: [LeaderboardCategory] {
        return [.overall, .monthly, .riskAdjusted, .consistency, .popularity, .newStrategies]
    }
}