//
//  ModernSocialHub.swift
//  Pipflow
//
//  Revolutionary Social Trading Interface with Real-Time Features
//

import SwiftUI
import Charts

// MARK: - Date Extension
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

struct ModernSocialHub: View {
    @StateObject private var socialService = EnhancedSocialTradingService.shared
    @StateObject private var chatService = ChatService.shared
    @StateObject private var forumService = ForumService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedTab = 0
    @State private var showingTraderDetail = false
    @State private var selectedTrader: Trader?
    @State private var showingNewPost = false
    @State private var animateContent = false
    @State private var pulseAnimation = false
    @State private var rotationAngle = 0.0
    
    @Namespace private var animation
    
    // Mock data for properties that don't exist in services
    private var mockLiveFeed: [TradingActivity] {
        let feedPosts = Array(socialService.socialFeed.prefix(10))
        var activities: [TradingActivity] = []
        
        for post in feedPosts {
            guard let trade = post.trade else { continue }
            
            let activity = TradingActivity(
                traderId: post.traderId,
                traderName: post.traderName,
                traderAvatar: post.traderImage,
                symbol: trade.symbol,
                action: trade.side == .buy ? "BUY" : "SELL",
                entryPrice: trade.entryPrice,
                exitPrice: trade.exitPrice,
                profit: trade.profit > 0 ? "+$\(String(format: "%.2f", trade.profit))" : "-$\(String(format: "%.2f", abs(trade.profit)))",
                returnPercentage: "\(trade.profit > 0 ? "+" : "")\(String(format: "%.1f", trade.profitPercentage))%",
                timestamp: post.timestamp,
                likes: post.likes,
                comments: post.comments,
                isFollowing: socialService.followedTraders.contains { $0.id == post.traderId }
            )
            activities.append(activity)
        }
        
        return activities
    }
    
    private var mockTradingRooms: [TradingRoom] {
        [
            TradingRoom(name: "Forex", icon: "dollarsign.circle", color: .green, activeUsers: 234, description: "Major currency pairs"),
            TradingRoom(name: "Crypto", icon: "bitcoinsign.circle", color: .orange, activeUsers: 567, description: "Digital assets"),
            TradingRoom(name: "Stocks", icon: "chart.line.uptrend.xyaxis", color: .blue, activeUsers: 189, description: "Equity markets"),
            TradingRoom(name: "Gold", icon: "cube.fill", color: .yellow, activeUsers: 123, description: "Precious metals")
        ]
    }
    
    private var mockRecentChats: [Chat] {
        []
    }
    
    var body: some View {
        ZStack {
            // Futuristic Background
            NeuralNetworkBackground()
                .opacity(0.2)
            
            // Main Content
            VStack(spacing: 0) {
                // Holographic Header
                holographicHeader
                
                // Custom Tab Bar
                modernTabBar
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    socialFeedTab
                        .tag(0)
                    
                    topTradersTab
                        .tag(1)
                    
                    communityHubTab
                        .tag(2)
                    
                    messagesTab
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            // Floating Action Button
            floatingActionButton
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startAnimations()
            loadInitialData()
        }
        .sheet(item: $selectedTrader) { trader in
            TraderDetailView(trader: trader)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingNewPost) {
            CreatePostView()
                .environmentObject(themeManager)
        }
    }
    
    // MARK: - Helper Functions
    
    private func getRoomColor(for type: ChatRoomType) -> Color {
        switch type {
        case .direct: return .electricBlue
        case .group: return .neonCyan
        case .channel: return .plasmaGreen
        case .support: return .neonPurple
        case .aiAssistant: return .neonPink
        }
    }
    
    private func getAuthorName(for authorId: UUID) -> String {
        // In a real app, this would look up the user
        return "User\(authorId.hashValue % 100)"
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Holographic Header
    
    var holographicHeader: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: [Color.neonCyan, Color.electricBlue, Color.neonPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .holographicShimmer()
            
            VStack(spacing: 16) {
                // Title and Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Social Trading Network")
                            .font(.caption)
                            .foregroundColor(.neonCyan)
                        
                        Text("Community Hub")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Live Indicators
                    HStack(spacing: 16) {
                        LiveStatusIndicator(
                            count: socialService.topTraders.count,
                            label: "Online",
                            color: .plasmaGreen
                        )
                        
                        LiveStatusIndicator(
                            count: Int.random(in: 150...300),
                            label: "Active",
                            color: .electricBlue
                        )
                    }
                }
                
                // Quick Stats
                HStack(spacing: 20) {
                    QuickStat(
                        icon: "person.2.fill",
                        value: "\(socialService.topTraders.count)",
                        label: "Top Traders"
                    )
                    
                    QuickStat(
                        icon: "chart.line.uptrend.xyaxis",
                        value: "87%",
                        label: "Success Rate"
                    )
                    
                    QuickStat(
                        icon: "bitcoinsign.circle.fill",
                        value: "$2.4M",
                        label: "Volume Today"
                    )
                    
                    QuickStat(
                        icon: "message.fill",
                        value: "\(chatService.unreadCount)",
                        label: "Messages"
                    )
                }
            }
            .padding(24)
        }
        .frame(height: 150)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Modern Tab Bar
    
    var modernTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: { 
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 6) {
                        ZStack {
                            if selectedTab == index {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [tabs[index].2, tabs[index].2.opacity(0.3)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 45, height: 45)
                                    .blur(radius: 10)
                            }
                            
                            Image(systemName: tabs[index].1)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == index ? tabs[index].2 : Color.white.opacity(0.5))
                                .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                        }
                        
                        Text(tabs[index].0)
                            .font(.caption2)
                            .foregroundColor(selectedTab == index ? tabs[index].2 : Color.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    let tabs = [
        ("Feed", "house.fill", Color.neonCyan),
        ("Traders", "chart.line.uptrend.xyaxis", Color.electricBlue),
        ("Community", "bubble.left.and.bubble.right.fill", Color.neonPurple),
        ("Messages", "envelope.fill", Color.plasmaGreen)
    ]
    
    // MARK: - Social Feed Tab
    
    var socialFeedTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Live Trading Activity
                liveTradingActivity
                
                // Social Feed Posts
                ForEach(socialService.socialFeed) { post in
                    SocialPostCard(post: post, onTraderTap: { trader in
                        selectedTrader = trader
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Live Trading Activity
    
    var liveTradingActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Live Trading Activity", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                LiveIndicator()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mockLiveFeed.prefix(5)) { trade in
                        LiveTradeCard(trade: trade)
                    }
                }
            }
        }
    }
    
    // MARK: - Top Traders Tab
    
    var topTradersTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Leaderboard Header
                leaderboardHeader
                
                // Top 3 Traders Podium
                topTradersPodium
                
                // Traders List
                VStack(spacing: 12) {
                    ForEach(Array(socialService.topTraders.enumerated()), id: \.element.id) { index, trader in
                        TopTraderRow(
                            trader: trader,
                            rank: index + 1,
                            onTap: {
                                selectedTrader = trader
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Leaderboard Header
    
    var leaderboardHeader: some View {
        HolographicCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This Month's Leaders")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Follow and copy the best performers")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Filter Button
                    Menu {
                        Button("This Week") {}
                        Button("This Month") {}
                        Button("All Time") {}
                    } label: {
                        HStack(spacing: 4) {
                            Text("Monthly")
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.neonCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.neonCyan.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.neonCyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Stats Overview
                HStack(spacing: 20) {
                    LeaderboardStat(
                        value: "$45.2M",
                        label: "Total Profit",
                        icon: "dollarsign.circle"
                    )
                    
                    LeaderboardStat(
                        value: "2,847",
                        label: "Total Trades",
                        icon: "arrow.left.arrow.right"
                    )
                    
                    LeaderboardStat(
                        value: "78.4%",
                        label: "Avg Win Rate",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Top Traders Podium
    
    var topTradersPodium: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if socialService.topTraders.count > 1 {
                // 2nd Place
                PodiumPlace(
                    trader: socialService.topTraders[1],
                    rank: 2,
                    height: 120,
                    color: .gray,
                    onTap: { selectedTrader = socialService.topTraders[1] }
                )
            }
            
            if socialService.topTraders.count > 0 {
                // 1st Place
                PodiumPlace(
                    trader: socialService.topTraders[0],
                    rank: 1,
                    height: 150,
                    color: .yellow,
                    onTap: { selectedTrader = socialService.topTraders[0] }
                )
            }
            
            if socialService.topTraders.count > 2 {
                // 3rd Place
                PodiumPlace(
                    trader: socialService.topTraders[2],
                    rank: 3,
                    height: 100,
                    color: Color(red: 0.72, green: 0.45, blue: 0.20),
                    onTap: { selectedTrader = socialService.topTraders[2] }
                )
            }
        }
        .padding(.top, 40)
    }
    
    // MARK: - Community Hub Tab
    
    var communityHubTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Community Stats
                communityStatsCard
                
                // Trending Topics
                trendingTopicsSection
                
                // Recent Discussions
                recentDiscussionsSection
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Community Stats Card
    
    var communityStatsCard: some View {
        HolographicCard {
            VStack(spacing: 20) {
                HStack {
                    Text("Community Activity")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    PulsingDot(color: .plasmaGreen)
                }
                
                HStack(spacing: 16) {
                    CommunityMetric(
                        icon: "person.2.fill",
                        value: "\(socialService.topTraders.count)",
                        label: "Active Now",
                        color: .plasmaGreen
                    )
                    
                    CommunityMetric(
                        icon: "bubble.left.and.bubble.right.fill",
                        value: "342",
                        label: "Discussions",
                        color: .electricBlue
                    )
                    
                    CommunityMetric(
                        icon: "heart.fill",
                        value: "1.2K",
                        label: "Reactions",
                        color: .neonPink
                    )
                    
                    CommunityMetric(
                        icon: "star.fill",
                        value: "89",
                        label: "Featured",
                        color: .neonPurple
                    )
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Trending Topics Section
    
    var trendingTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Trending Topics", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all topics
                }
                .font(.caption)
                .foregroundColor(.neonCyan)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(forumService.trendingTopics) { topic in
                        TrendingTopicCard(topic: topic)
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Discussions Section
    
    var recentDiscussionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Discussions")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(Array(forumService.posts.values.flatMap { $0 }.prefix(10))) { post in
                    DiscussionCard(post: post)
                }
            }
        }
    }
    
    // MARK: - Messages Tab
    
    var messagesTab: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Message Stats
                messageStatsCard
                
                // Active Conversations
                activeConversationsSection
                
                // Chat Rooms
                chatRoomsSection
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Message Stats Card
    
    var messageStatsCard: some View {
        HolographicCard {
            HStack(spacing: 20) {
                // Unread Messages
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.neonCyan.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Text("\(chatService.unreadCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.neonCyan)
                    }
                    
                    Text("Unread")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Active Chats
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.electricBlue.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Text("\(chatService.activeChats.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.electricBlue)
                    }
                    
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // New Message Button
                Button(action: { showingNewPost = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Compose")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 80)
                    .background(
                        LinearGradient(
                            colors: [Color.neonPurple, Color.electricBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Active Conversations Section
    
    var activeConversationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Conversations")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(chatService.recentChats) { chat in
                    ConversationRow(chat: chat)
                }
            }
        }
    }
    
    // MARK: - Chat Rooms Section
    
    var chatRoomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Trading Rooms", systemImage: "person.3.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Browse All") {}
                    .font(.caption)
                    .foregroundColor(.neonCyan)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(mockTradingRooms) { room in
                    ChatRoomCard(room: room)
                }
            }
        }
    }
    
    // MARK: - Floating Action Button
    
    var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Menu {
                    Button(action: { showingNewPost = true }) {
                        Label("New Post", systemImage: "square.and.pencil")
                    }
                    
                    Button(action: {}) {
                        Label("Start Trade", systemImage: "arrow.left.arrow.right")
                    }
                    
                    Button(action: {}) {
                        Label("Share Signal", systemImage: "waveform")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.neonPurple, .electricBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .neonGlow(color: .neonPurple, radius: 15)
                        
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(pulseAnimation ? 90 : 0))
                    }
                }
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Helper Methods
    
    private func startAnimations() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        withAnimation(.easeOut(duration: 0.6)) {
            animateContent = true
        }
    }
    
    private func loadInitialData() {
        // Data is loaded automatically by services
    }
}

// MARK: - Supporting Components

struct LiveStatusIndicator: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: 8)
                        .opacity(0.3)
                        .scaleEffect(2)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: true)
                )
            
            VStack(alignment: .leading, spacing: 0) {
                Text("\(count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

struct QuickStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.neonCyan)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct LiveTradeCard: View {
    let trade: TradingActivity
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Trader Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.neonCyan, Color.electricBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(trade.traderName.prefix(2).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Trade Info
            VStack(spacing: 4) {
                Text(trade.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 2) {
                    Image(systemName: trade.action == "BUY" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 10))
                    Text(trade.action)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(trade.action == "BUY" ? .plasmaGreen : .neonPink)
                
                Text(trade.returnPercentage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(trade.isProfit ? .plasmaGreen : .neonPink)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            trade.isProfit ? Color.plasmaGreen.opacity(0.3) : Color.neonPink.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isAnimating ? 1.05 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct SocialPostCard: View {
    let post: SocialPost
    let onTraderTap: (Trader) -> Void
    @State private var isLiked = false
    @State private var showingComments = false
    
    var body: some View {
        HolographicCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.neonCyan, Color.electricBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        if let avatarURL = post.traderImage {
                            AsyncImage(url: URL(string: avatarURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } placeholder: {
                                Text(post.traderName.prefix(2).uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text(post.traderName.prefix(2).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .onTapGesture {
                        // onTraderTap(post.trader)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(post.traderName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if post.type == .milestone {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.neonCyan)
                            }
                        }
                        
                        Text(post.timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Performance Badge
                    if let performance = post.performance {
                        PerformanceBadge(performance: performance.returnPercentage * 100)
                    }
                }
                
                // Content
                Text(post.content)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Trade Details (if applicable)
                if let trade = post.trade {
                    TradeInfoView(trade: trade)
                }
                
                
                // Interaction Bar
                HStack(spacing: 24) {
                    // Like
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) {
                            isLiked.toggle()
                            // In a real app, this would update the like count via the service
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .neonPink : .white.opacity(0.5))
                            Text("\(post.likes)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    // Comment
                    Button(action: { showingComments.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(post.comments)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    // Share
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.turn.up.right")
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(post.shares)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    // Copy Trade
                    if post.trade != nil {
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color.neonCyan, Color.electricBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showingComments) {
            PostCommentsView(post: post)
        }
    }
}

struct PerformanceBadge: View {
    let performance: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: performance > 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10))
            Text("\(String(format: "%.1f", abs(performance)))%")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(performance > 0 ? .plasmaGreen : .neonPink)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((performance > 0 ? Color.plasmaGreen : Color.neonPink).opacity(0.2))
        )
    }
}

struct TradeInfoView: View {
    let trade: SocialTradeInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(trade.symbol, systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(trade.side.rawValue.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(trade.side == .buy ? .plasmaGreen : .neonPink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((trade.side == .buy ? Color.plasmaGreen : Color.neonPink).opacity(0.2))
                    )
            }
            
            HStack(spacing: 16) {
                DetailItem(label: "Entry", value: String(format: "%.5f", trade.entryPrice))
                DetailItem(label: "Exit", value: String(format: "%.5f", trade.exitPrice))
                DetailItem(label: "P/L", value: String(format: "$%.2f", trade.profit))
                DetailItem(label: "Return", value: String(format: "%.1f%%", trade.profitPercentage * 100))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

struct TradeDetailsView: View {
    let details: TradeDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(details.symbol, systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(details.direction.rawValue.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(details.direction == .long ? .plasmaGreen : .neonPink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((details.direction == .long ? Color.plasmaGreen : Color.neonPink).opacity(0.2))
                    )
            }
            
            HStack(spacing: 16) {
                DetailItem(label: "Entry", value: String(format: "%.5f", details.entry))
                if let stopLoss = details.stopLoss {
                    DetailItem(label: "SL", value: String(format: "%.5f", stopLoss))
                }
                if let takeProfit = details.takeProfit {
                    DetailItem(label: "TP", value: String(format: "%.5f", takeProfit))
                }
                DetailItem(label: "Info", value: String(details.reasoning.prefix(20)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct LeaderboardStat: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.neonCyan)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct PodiumPlace: View {
    let trader: Trader
    let rank: Int
    let height: CGFloat
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Trader Info
            Button(action: onTap) {
                VStack(spacing: 8) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(color, lineWidth: 3)
                            )
                        
                        Text(trader.displayName.prefix(2).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Name
                    Text(trader.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Stats
                    Text("\(String(format: "%.1f", trader.winRate))% Win")
                        .font(.system(size: 12))
                        .foregroundColor(.plasmaGreen)
                }
            }
            
            // Podium
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 100, height: height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(color.opacity(0.5), lineWidth: 2)
                    )
                
                Text("\(rank)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct TopTraderRow: View {
    let trader: Trader
    let rank: Int
    let onTap: () -> Void
    @StateObject private var socialService = EnhancedSocialTradingService.shared
    
    var body: some View {
        Button(action: onTap) {
            HolographicCard {
                HStack(spacing: 16) {
                    // Rank
                    Text("#\(rank)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 40)
                    
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.neonCyan, Color.electricBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Text(trader.displayName.prefix(2).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(trader.displayName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if trader.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.neonCyan)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            StatChip(value: "\(String(format: "%.1f", trader.winRate))%", label: "Win")
                            StatChip(value: trader.monthlyReturn > 0 ? "+\(String(format: "%.1f", trader.monthlyReturn * 100))%" : "\(String(format: "%.1f", trader.monthlyReturn * 100))%", label: "Return")
                            StatChip(value: "\(trader.followers)", label: "Followers")
                        }
                    }
                    
                    Spacer()
                    
                    // Follow Button
                    Button(action: {}) {
                        Text(socialService.followedTraders.contains { $0.id == trader.id } ? "Following" : "Follow")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(socialService.followedTraders.contains { $0.id == trader.id } ? .white : .black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                socialService.followedTraders.contains { $0.id == trader.id } ?
                                AnyView(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                ) :
                                AnyView(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.neonCyan, Color.electricBlue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                            )
                    }
                }
                .padding(16)
            }
        }
    }
}

struct StatChip: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct CommunityMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct TrendingTopicCard: View {
    let topic: ForumTopic
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                
                Text("#\(topic.rank)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            Text(topic.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            HStack(spacing: 8) {
                Label("\(topic.postsCount)", systemImage: "bubble.left")
                Label("\(topic.viewsCount)", systemImage: "eye")
            }
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct DiscussionCard: View {
    let post: ForumPost
    
    var body: some View {
        HolographicCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Author
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.neonPurple.opacity(0.3))
                                .frame(width: 32, height: 32)
                            
                            Text("U\(post.authorId.hashValue % 100)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.neonPurple)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("User\(post.authorId.hashValue % 100)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(post.createdAt.timeAgoDisplay())
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    // Category
                    Text(post.category)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.neonPurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.neonPurple.opacity(0.2))
                        )
                }
                
                // Title
                Text(post.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Preview
                Text(post.preview)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                
                // Stats
                HStack(spacing: 16) {
                    Label("\(post.replies)", systemImage: "bubble.left")
                    Label("\(post.likes)", systemImage: "heart")
                    Label("\(post.views)", systemImage: "eye")
                    
                    Spacer()
                    
                    if post.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.neonCyan)
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
        }
    }
}

struct ConversationRow: View {
    let chat: Chat
    
    var body: some View {
        HolographicCard {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.plasmaGreen, Color.neonCyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    if chat.isGroup {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    } else {
                        Text(chat.participants.first?.name.prefix(2).uppercased() ?? "")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Online indicator
                    if chat.isOnline {
                        Circle()
                            .fill(Color.plasmaGreen)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: 18, y: 18)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(chat.isGroup ? chat.groupName ?? "Group Chat" : chat.participants.first?.name ?? "")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(chat.lastMessageTime)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    HStack {
                        if chat.lastMessage.isFromMe {
                            Text("You: ")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Text(chat.lastMessage.preview)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if chat.unreadCount > 0 {
                            Text("\(chat.unreadCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.neonCyan)
                                )
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
        }
    }
}

struct ChatRoomCard: View {
    let room: TradingRoom
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [room.color, room.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: room.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            // Name
            Text(room.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Active Users
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.plasmaGreen)
                    .frame(width: 6, height: 6)
                
                Text("\(room.activeUsers)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.neonCyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ModernSocialHub()
        .environmentObject(ThemeManager())
}