//
//  EnhancedSocialFeedView.swift
//  Pipflow
//
//  Enhanced social trading feed with V2 features
//

import SwiftUI

struct EnhancedSocialFeedView: View {
    @StateObject private var viewModel = EnhancedSocialFeedViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showNewPost = false
    @State private var selectedFeedItem: SocialFeedItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Post Button
                        PostButtonComponent(theme: themeManager.currentTheme) {
                            showNewPost = true
                        }
                        
                        // Feed Items
                        if viewModel.feedItems.isEmpty {
                            EmptyStateView(
                                icon: "bubble.left.and.bubble.right",
                                title: "No Posts Yet",
                                description: "Follow traders and strategies to see their updates",
                                theme: themeManager.currentTheme
                            )
                            .padding(.top, 50)
                        } else {
                            ForEach(viewModel.feedItems) { item in
                                EnhancedFeedItemCard(
                                    item: item,
                                    theme: themeManager.currentTheme,
                                    onLike: { viewModel.toggleLike(item.id) },
                                    onComment: { selectedFeedItem = item },
                                    onShare: { viewModel.shareItem(item) }
                                )
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refreshFeed()
                }
            }
            .navigationTitle("Social Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.toggleFilter) {
                        Image(systemName: viewModel.showFollowingOnly ? "person.2.fill" : "person.2")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewPost) {
            NewPostView()
                .environmentObject(themeManager)
        }
        .sheet(item: $selectedFeedItem) { item in
            CommentsView(feedItem: item)
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Enhanced Feed Item Card

struct EnhancedFeedItemCard: View {
    let item: SocialFeedItem
    let theme: Theme
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: item.authorAvatar ?? "person.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(theme.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    Text(formatTimestamp(item.timestamp))
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: feedTypeIcon(item.type))
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(item.content.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textColor)
                
                Text(item.content.body)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textColor)
                    .lineLimit(5)
                
                // Special Content
                if let tradeDetails = item.content.tradeDetails {
                    EnhancedTradeIdeaCard(details: tradeDetails, theme: theme)
                }
                
                if let achievement = item.content.achievement {
                    EnhancedSocialAchievementCard(achievement: achievement, theme: theme)
                }
                
                if let strategyId = item.content.strategyId {
                    StrategyLinkCard(strategyId: strategyId, theme: theme)
                }
            }
            
            // Actions
            HStack(spacing: 24) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: item.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(item.isLiked ? .red : theme.secondaryTextColor)
                        Text("\(item.likes)")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                
                Button(action: onComment) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(theme.secondaryTextColor)
                        Text("\(item.comments.count)")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
            }
            .font(.system(size: 14))
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func feedTypeIcon(_ type: FeedItemType) -> String {
        switch type {
        case .strategyUpdate: return "chart.xyaxis.line"
        case .tradeIdea: return "lightbulb"
        case .marketAnalysis: return "doc.text.magnifyingglass"
        case .achievement: return "trophy"
        case .milestone: return "flag.checkered"
        }
    }
}

// MARK: - Enhanced Trade Idea Card

struct EnhancedTradeIdeaCard: View {
    let details: TradeDetails
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(details.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.textColor)
                
                Image(systemName: details.direction == .long ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(details.direction == .long ? .green : .red)
                
                Text(details.direction == .long ? "LONG" : "SHORT")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(details.direction == .long ? .green : .red)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Entry")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    Text(String(format: "%.5f", details.entry))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textColor)
                }
                
                if let sl = details.stopLoss {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stop Loss")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        Text(String(format: "%.5f", sl))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                
                if let tp = details.takeProfit {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Take Profit")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        Text(String(format: "%.5f", tp))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            
            if !details.reasoning.isEmpty {
                Text(details.reasoning)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .italic()
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(theme.backgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Social Achievement Card

struct EnhancedSocialAchievementCard: View {
    let achievement: SocialAchievement
    let theme: Theme
    
    var body: some View {
        HStack {
            Image(systemName: achievement.icon)
                .font(.system(size: 32))
                .foregroundColor(achievementColor(achievement.type))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textColor)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    achievementColor(achievement.type).opacity(0.1),
                    achievementColor(achievement.type).opacity(0.05)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
    
    private func achievementColor(_ type: AchievementType) -> Color {
        switch type {
        case .profitMilestone: return .green
        case .winStreak: return .orange
        case .followersReached: return .blue
        case .consistencyAward: return .purple
        case .topPerformer: return .yellow
        }
    }
}

// MARK: - Strategy Link Card

struct StrategyLinkCard: View {
    let strategyId: String
    let theme: Theme
    @StateObject private var viewModel = StrategyLinkViewModel()
    @State private var showStrategyDetail = false
    
    var body: some View {
        if let strategy = viewModel.strategy {
            Button(action: { showStrategyDetail = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(strategy.strategy.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textColor)
                        
                        HStack(spacing: 12) {
                            Label(String(format: "%.1f%%", strategy.performance.totalReturn),
                                  systemImage: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                                .foregroundColor(strategy.performance.totalReturn > 0 ? .green : .red)
                            
                            Label("\(strategy.subscribers)", systemImage: "person.2")
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                .padding()
                .background(theme.backgroundColor)
                .cornerRadius(12)
            }
            .sheet(isPresented: $showStrategyDetail) {
                StrategyDetailView(strategy: strategy)
            }
        }
    }
}

// MARK: - New Post View

struct NewPostView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var postType: FeedItemType = .marketAnalysis
    @State private var title = ""
    @State private var postBody = ""
    @State private var selectedSymbol = "EURUSD"
    @State private var tradeDirection: TradeDirection = .long
    @State private var entry = ""
    @State private var stopLoss = ""
    @State private var takeProfit = ""
    @State private var reasoning = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Post Type") {
                    Picker("Type", selection: $postType) {
                        Text("Market Analysis").tag(FeedItemType.marketAnalysis)
                        Text("Trade Idea").tag(FeedItemType.tradeIdea)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Content") {
                    TextField("Title", text: $title)
                    TextEditor(text: $postBody)
                        .frame(minHeight: 100)
                }
                
                if postType == .tradeIdea {
                    Section("Trade Details") {
                        Picker("Symbol", selection: $selectedSymbol) {
                            ForEach(["EURUSD", "GBPUSD", "USDJPY", "XAUUSD"], id: \.self) { symbol in
                                Text(symbol).tag(symbol)
                            }
                        }
                        
                        Picker("Direction", selection: $tradeDirection) {
                            Text("Long").tag(TradeDirection.long)
                            Text("Short").tag(TradeDirection.short)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        TextField("Entry Price", text: $entry)
                            .keyboardType(.decimalPad)
                        
                        TextField("Stop Loss (Optional)", text: $stopLoss)
                            .keyboardType(.decimalPad)
                        
                        TextField("Take Profit (Optional)", text: $takeProfit)
                            .keyboardType(.decimalPad)
                        
                        TextField("Reasoning", text: $reasoning)
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        postContent()
                        dismiss()
                    }
                    .disabled(title.isEmpty || postBody.isEmpty)
                }
            }
        }
    }
    
    private func postContent() {
        let socialService = SocialTradingServiceV2.shared
        
        if postType == .tradeIdea, let entryPrice = Double(entry) {
            let tradeDetails = TradeDetails(
                symbol: selectedSymbol,
                direction: tradeDirection,
                entry: entryPrice,
                stopLoss: Double(stopLoss),
                takeProfit: Double(takeProfit),
                reasoning: reasoning
            )
            
            socialService.postTradeIdea(tradeDetails, commentary: postBody)
        } else {
            // Post as market analysis
            let feedItem = SocialFeedItem(
                type: .marketAnalysis,
                authorId: "current_user",
                authorName: "Current User",
                authorAvatar: nil,
                timestamp: Date(),
                content: FeedContent(
                    title: title,
                    body: postBody,
                    images: nil,
                    strategyId: nil,
                    tradeDetails: nil,
                    achievement: nil
                ),
                likes: 0,
                comments: [],
                isLiked: false
            )
            
            socialService.socialFeed.insert(feedItem, at: 0)
        }
    }
}

// MARK: - Comments View

struct CommentsView: View {
    let feedItem: SocialFeedItem
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var newComment = ""
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Original Post
                        VStack(alignment: .leading, spacing: 8) {
                            Text(feedItem.content.title)
                                .font(.headline)
                            Text(feedItem.content.body)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(12)
                        
                        // Comments
                        ForEach(feedItem.comments) { comment in
                            CommentView(comment: comment, theme: themeManager.currentTheme)
                        }
                    }
                    .padding()
                }
                
                // Comment Input
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Post") {
                        postComment()
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
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
    
    private func postComment() {
        let socialService = SocialTradingServiceV2.shared
        socialService.commentOnFeedItem(feedItem.id, comment: newComment)
        newComment = ""
    }
}

struct CommentView: View {
    let comment: FeedComment
    let theme: Theme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(theme.secondaryTextColor)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textColor)
                    
                    Text(formatTimestamp(comment.timestamp))
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textColor)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - View Models

@MainActor
class EnhancedSocialFeedViewModel: ObservableObject {
    @Published var feedItems: [SocialFeedItem] = []
    @Published var showFollowingOnly = false
    
    private let socialService = SocialTradingServiceV2.shared
    
    init() {
        loadFeed()
    }
    
    func loadFeed() {
        feedItems = socialService.socialFeed
    }
    
    func refreshFeed() async {
        // Refresh feed
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadFeed()
    }
    
    func toggleLike(_ itemId: UUID) {
        socialService.likeFeedItem(itemId)
        loadFeed()
    }
    
    func shareItem(_ item: SocialFeedItem) {
        // Share functionality
    }
    
    func toggleFilter() {
        showFollowingOnly.toggle()
        
        if showFollowingOnly {
            feedItems = socialService.socialFeed.filter { item in
                socialService.followedAuthors.contains(item.authorId)
            }
        } else {
            loadFeed()
        }
    }
}

@MainActor
class StrategyLinkViewModel: ObservableObject {
    @Published var strategy: SharedStrategy?
    
    func loadStrategy(_ strategyId: String) {
        strategy = SocialTradingServiceV2.shared.marketplace.first { $0.strategyId == strategyId } as? SharedStrategy
    }
}

// MARK: - Post Button Component

struct PostButtonComponent: View {
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "square.and.pencil")
                    .font(.headline)
                Text("Create Post")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}