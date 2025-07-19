//
//  SocialFeedView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI

struct SocialFeedView: View {
    @StateObject private var socialService = SocialTradingService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedFilter: TraderFilter = .all
    @State private var showingTraderDetail = false
    @State private var selectedTrader: Trader?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Traders Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Top Traders")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Spacer()
                            
                            NavigationLink(destination: TopTradersView()) {
                                Text("See All")
                                    .font(.footnote)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Horizontal scroll of top traders
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(socialService.topTraders.prefix(5)) { trader in
                                    TraderCardCompact(trader: trader)
                                        .onTapGesture {
                                            selectedTrader = trader
                                            showingTraderDetail = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    Divider()
                        .background(themeManager.currentTheme.separatorColor)
                    
                    // Social Feed
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(socialService.socialFeed) { post in
                                SocialPostView(post: post)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                
                                Divider()
                                    .background(themeManager.currentTheme.separatorColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedTrader) { trader in
                TraderDetailView(trader: trader)
            }
        }
    }
}

// MARK: - Trader Card Compact

struct TraderCardCompact: View {
    let trader: Trader
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Profile Image
            Circle()
                .fill(LinearGradient(
                    colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(trader.displayName.prefix(2))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(trader.isVerified ? Color.blue : Color.clear, lineWidth: 2)
                )
            
            VStack(spacing: 4) {
                Text(trader.displayName.split(separator: " ").first ?? "")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .lineLimit(1)
                
                Text(trader.formattedMonthlyReturn)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(trader.monthlyReturn >= 0 ? Color.Theme.success : Color.Theme.error)
                
                Text("\(trader.followers) followers")
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Social Post View

struct SocialPostView: View {
    let post: SocialPost
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(post.traderName.prefix(2))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.traderName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text(timeAgo(from: post.timestamp))
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            // Content
            Text(post.content)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            // Trade Info (if applicable)
            if let trade = post.trade {
                SocialTradeInfoCard(trade: trade)
            }
            
            // Performance Info (if applicable)
            if let performance = post.performance {
                PerformanceInfoCard(performance: performance)
            }
            
            // Interactions
            HStack(spacing: 24) {
                Button(action: {
                    isLiked.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : themeManager.currentTheme.secondaryTextColor)
                        Text("\(post.likes + (isLiked ? 1 : 0))")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Text("\(post.comments)")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Trade Info Card

struct SocialTradeInfoCard: View {
    let trade: SocialTradeInfo
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trade.symbol)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(trade.side.rawValue.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(trade.side == .buy ? Color.Theme.buy : Color.Theme.sell)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Text("\(trade.volume, specifier: "%.2f") lots")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                HStack {
                    Text("Duration: \(trade.duration)")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(trade.profit >= 0 ? "+$\(trade.profit, specifier: "%.2f")" : "-$\(abs(trade.profit), specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(trade.profit >= 0 ? Color.Theme.success : Color.Theme.error)
                
                Text("\(trade.profitPercentage >= 0 ? "+" : "")\(trade.profitPercentage * 100, specifier: "%.2f")%")
                    .font(.caption)
                    .foregroundColor(trade.profit >= 0 ? Color.Theme.success : Color.Theme.error)
            }
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
        .cornerRadius(8)
    }
}

// MARK: - Performance Info Card

struct PerformanceInfoCard: View {
    let performance: SocialPerformanceInfo
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Last \(performance.period)")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Spacer()
                
                Text("\(performance.returnPercentage >= 0 ? "+" : "")\(performance.returnPercentage, specifier: "%.2f")%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(performance.returnPercentage >= 0 ? Color.Theme.success : Color.Theme.error)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trades")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Text("\(performance.trades)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Win Rate")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Text("\(performance.winRate * 100, specifier: "%.1f")%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Profit Factor")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Text("\(performance.profitFactor, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
        .cornerRadius(8)
    }
}

#Preview {
    SocialFeedView()
        .environmentObject(ThemeManager.shared)
}