//
//  TopTradersView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI

struct TopTradersView: View {
    @StateObject private var socialService = SocialTradingService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedFilter: TraderFilter = .all
    @State private var searchText = ""
    @State private var showingTraderDetail = false
    @State private var selectedTrader: Trader?
    
    var filteredTraders: [Trader] {
        let filtered = selectedFilter.apply(to: socialService.topTraders)
        
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { trader in
                trader.username.localizedCaseInsensitiveContains(searchText) ||
                trader.displayName.localizedCaseInsensitiveContains(searchText) ||
                trader.specialties.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    TextField("Search traders...", text: $searchText)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                .padding()
                .background(themeManager.currentTheme.secondaryBackgroundColor)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TraderFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                theme: themeManager.currentTheme
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
                // Traders List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTraders) { trader in
                            TraderRowView(trader: trader)
                                .onTapGesture {
                                    selectedTrader = trader
                                    showingTraderDetail = true
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle("Top Traders")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedTrader) { trader in
            TraderDetailView(trader: trader)
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            theme.secondaryBackgroundColor
                        }
                    }
                )
                .cornerRadius(20)
        }
    }
}

// MARK: - Trader Row View

struct TraderRowView: View {
    let trader: Trader
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var socialService = SocialTradingService.shared
    
    var isFollowing: Bool {
        socialService.followedTraders.contains { $0.id == trader.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Profile Image
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(trader.displayName.prefix(2))
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(trader.isVerified ? Color.blue : Color.clear, lineWidth: 2)
                    )
                
                // Trader Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(trader.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        if trader.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        if trader.isPro {
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("@\(trader.username)")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(trader.followers)")
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption2)
                            Text(trader.formattedWinRate)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text(trader.tradingStyle.rawValue)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text(trader.formattedMonthlyReturn)
                        .font(.headline)
                        .foregroundColor(trader.monthlyReturn >= 0 ? Color.Theme.success : Color.Theme.error)
                    
                    Text("Monthly")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    // Follow Button
                    Button(action: {
                        if isFollowing {
                            socialService.unfollowTrader(trader)
                        } else {
                            socialService.followTrader(trader)
                        }
                    }) {
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(isFollowing ? themeManager.currentTheme.textColor : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Group {
                                    if isFollowing {
                                        themeManager.currentTheme.secondaryBackgroundColor
                                    } else {
                                        LinearGradient(
                                            colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isFollowing ? themeManager.currentTheme.separatorColor : Color.clear, lineWidth: 1)
                            )
                    }
                }
            }
            .padding()
            
            // Bio
            if !trader.bio.isEmpty {
                Text(trader.bio)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
            
            // Performance Preview
            HStack(spacing: 16) {
                PerformanceStat(
                    title: "Win Rate",
                    value: trader.formattedWinRate,
                    color: Color.Theme.success
                )
                
                PerformanceStat(
                    title: "Profit Factor",
                    value: String(format: "%.2f", trader.profitFactor),
                    color: Color.Theme.accent
                )
                
                PerformanceStat(
                    title: "Risk Level",
                    value: trader.riskLevel.rawValue,
                    color: trader.riskLevel.color
                )
                
                PerformanceStat(
                    title: "Yearly",
                    value: trader.formattedYearlyReturn,
                    color: trader.yearlyReturn >= 0 ? Color.Theme.success : Color.Theme.error
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Performance Stat

struct PerformanceStat: View {
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        TopTradersView()
            .environmentObject(ThemeManager.shared)
    }
}