//
//  SocialTradingServiceV2.swift
//  Pipflow
//
//  Enhanced social trading and strategy sharing service
//

import Foundation
import SwiftUI
import Combine

// MARK: - Social Trading Models

struct SocialSharedStrategy: Identifiable {
    let id = UUID()
    let strategyId: String
    let authorId: String
    let authorName: String
    let authorAvatar: String?
    let authorVerified: Bool
    let strategy: TradingStrategy
    let performance: SocialStrategyPerformance
    let pricing: StrategyPricing
    let description: String
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    var subscriberCount: Int
    var rating: Double
    var reviews: [StrategyReview]
    let isPublic: Bool
}

struct SocialStrategyPerformance {
    let totalReturn: Double
    let monthlyReturn: Double
    let sharpeRatio: Double
    let maxDrawdown: Double
    let winRate: Double
    let totalTrades: Int
    let profitFactor: Double
    let averageHoldTime: TimeInterval
    let consistency: Double
    let riskScore: Double
    let timeActive: TimeInterval
    let lastUpdated: Date
    
    init(
        totalReturn: Double,
        monthlyReturn: Double,
        sharpeRatio: Double,
        maxDrawdown: Double,
        winRate: Double,
        totalTrades: Int,
        profitFactor: Double,
        averageHoldTime: TimeInterval,
        consistency: Double,
        riskScore: Double,
        timeActive: TimeInterval,
        lastUpdated: Date = Date()
    ) {
        self.totalReturn = totalReturn
        self.monthlyReturn = monthlyReturn
        self.sharpeRatio = sharpeRatio
        self.maxDrawdown = maxDrawdown
        self.winRate = winRate
        self.totalTrades = totalTrades
        self.profitFactor = profitFactor
        self.averageHoldTime = averageHoldTime
        self.consistency = consistency
        self.riskScore = riskScore
        self.timeActive = timeActive
        self.lastUpdated = lastUpdated
    }
}

struct StrategyPricing {
    let model: PricingModel
    let monthlyFee: Double?
    let performanceFee: Double?
    let minimumBalance: Double
    let trialPeriod: TimeInterval?
}

enum PricingModel {
    case free
    case subscription
    case performance
    case hybrid
}

struct StrategyReview: Identifiable {
    let id = UUID()
    let reviewerId: String
    let reviewerName: String
    let rating: Int // 1-5
    let comment: String
    let timestamp: Date
    let helpful: Int
    let verified: Bool
}

struct StrategySubscription: Identifiable {
    let id = UUID()
    let userId: String
    let strategyId: String
    let subscribedAt: Date
    var status: SubscriptionStatus
    let copySettings: CopySettings
    var performance: SubscriptionPerformance
}

enum SubscriptionStatus {
    case active
    case paused
    case cancelled
    case trial
}

struct CopySettings {
    let scalingFactor: Double // 0.1 - 10.0
    let maxPositions: Int
    let maxRiskPerTrade: Double
    let allowedSymbols: [String]?
    let stopCopyingOnDrawdown: Double?
    let reverseTrading: Bool
}

struct SubscriptionPerformance {
    let totalReturn: Double
    var copiedTrades: Int
    let successfulTrades: Int
    let totalProfit: Double
    let currentDrawdown: Double
}

struct StrategyLeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let strategy: SocialSharedStrategy
    let score: Double
    let change: Int // Rank change
    let category: LeaderboardCategory
}

enum LeaderboardCategory {
    case overall
    case monthly
    case riskAdjusted
    case consistency
    case popularity
    case newStrategies
}

struct SocialFeedItem: Identifiable {
    let id = UUID()
    let type: FeedItemType
    let authorId: String
    let authorName: String
    let authorAvatar: String?
    let timestamp: Date
    let content: FeedContent
    var likes: Int
    var comments: [FeedComment]
    var isLiked: Bool
}

enum FeedItemType {
    case strategyUpdate
    case tradeIdea
    case marketAnalysis
    case achievement
    case milestone
}

struct FeedContent {
    let title: String
    let body: String
    let images: [String]?
    let strategyId: String?
    let tradeDetails: TradeDetails?
    let achievement: SocialAchievement?
}

struct TradeDetails {
    let symbol: String
    let direction: TradeDirection
    let entry: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let reasoning: String
}

struct SocialAchievement {
    let type: AchievementType
    let title: String
    let description: String
    let icon: String
}

enum AchievementType {
    case profitMilestone
    case winStreak
    case followersReached
    case consistencyAward
    case topPerformer
}

struct FeedComment: Identifiable {
    let id = UUID()
    let authorId: String
    let authorName: String
    let content: String
    let timestamp: Date
}

// MARK: - Social Trading Service

@MainActor
class SocialTradingServiceV2: ObservableObject {
    static let shared = SocialTradingServiceV2()
    
    @Published var marketplace: [SocialSharedStrategy] = []
    @Published var subscriptions: [StrategySubscription] = []
    @Published var leaderboard: [StrategyLeaderboardEntry] = []
    @Published var socialFeed: [SocialFeedItem] = []
    @Published var mySharedStrategies: [SocialSharedStrategy] = []
    @Published var followedAuthors: [String] = []
    
    private let tradingService = TradingService.shared
    private let backtestingEngine = BacktestingEngine.shared
    private let notificationManager = NotificationManager.shared
    
    private var copyTradingTimer: Timer?
    private var feedUpdateTimer: Timer?
    
    init() {
        loadMarketplace()
        startCopyTradingMonitor()
        startFeedUpdates()
    }
    
    // MARK: - Public Methods
    
    func shareStrategy(_ strategy: TradingStrategy, description: String, pricing: StrategyPricing, tags: [String]) async throws -> SocialSharedStrategy {
        // Validate strategy performance
        let performance = try await validateStrategyPerformance(strategy)
        
        guard performance.totalReturn > -10 && performance.winRate > 0.3 else {
            throw SocialTradingError.performanceRequirementsNotMet
        }
        
        let sharedStrategy = SocialSharedStrategy(
            strategyId: strategy.id.uuidString,
            authorId: "current_user", // Would get from auth
            authorName: "Current User",
            authorAvatar: nil,
            authorVerified: false,
            strategy: strategy,
            performance: performance,
            pricing: pricing,
            description: description,
            tags: tags,
            createdAt: Date(),
            updatedAt: Date(),
            subscriberCount: 0,
            rating: 0,
            reviews: [],
            isPublic: true
        )
        
        mySharedStrategies.append(sharedStrategy)
        marketplace.append(sharedStrategy)
        
        // Post to social feed
        postStrategyUpdate(sharedStrategy)
        
        return sharedStrategy
    }
    
    func subscribeToStrategy(_ strategyId: String, settings: CopySettings) async throws -> StrategySubscription {
        guard let strategy = marketplace.first(where: { $0.strategyId == strategyId }) else {
            throw SocialTradingError.strategyNotFound
        }
        
        // Check subscription requirements
        if strategy.pricing.minimumBalance > 0 {
            // Verify user has minimum balance
        }
        
        let subscription = StrategySubscription(
            userId: "current_user",
            strategyId: strategyId,
            subscribedAt: Date(),
            status: strategy.pricing.trialPeriod != nil ? .trial : .active,
            copySettings: settings,
            performance: SubscriptionPerformance(
                totalReturn: 0,
                copiedTrades: 0,
                successfulTrades: 0,
                totalProfit: 0,
                currentDrawdown: 0
            )
        )
        
        subscriptions.append(subscription)
        
        // Send notification
        notificationManager.sendNotification(
            title: "Subscribed to Strategy",
            body: "You are now copying \(strategy.strategy.name)",
            identifier: "subscription_\(strategyId)",
            timeInterval: 1
        )
        
        return subscription
    }
    
    func unsubscribeFromStrategy(_ subscriptionId: UUID) {
        subscriptions.removeAll { $0.id == subscriptionId }
    }
    
    func pauseSubscription(_ subscriptionId: UUID) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscriptionId }) {
            subscriptions[index].status = .paused
        }
    }
    
    func resumeSubscription(_ subscriptionId: UUID) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscriptionId }) {
            subscriptions[index].status = .active
        }
    }
    
    func rateStrategy(_ strategyId: String, rating: Int, comment: String) {
        guard let index = marketplace.firstIndex(where: { $0.strategyId == strategyId }) else { return }
        
        let review = StrategyReview(
            reviewerId: "current_user",
            reviewerName: "Current User",
            rating: rating,
            comment: comment,
            timestamp: Date(),
            helpful: 0,
            verified: true
        )
        
        marketplace[index].reviews.append(review)
        
        // Recalculate average rating
        let totalRating = marketplace[index].reviews.reduce(0) { $0 + $1.rating }
        marketplace[index].rating = Double(totalRating) / Double(marketplace[index].reviews.count)
    }
    
    func searchStrategies(query: String, filters: StrategyFilters) -> [SocialSharedStrategy] {
        var results = marketplace
        
        // Apply search query
        if !query.isEmpty {
            results = results.filter { strategy in
                strategy.strategy.name.localizedCaseInsensitiveContains(query) ||
                strategy.description.localizedCaseInsensitiveContains(query) ||
                strategy.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
                strategy.authorName.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Apply filters
        if let minReturn = filters.minReturn {
            results = results.filter { $0.performance.totalReturn >= minReturn }
        }
        
        if let maxDrawdown = filters.maxDrawdown {
            results = results.filter { $0.performance.maxDrawdown <= maxDrawdown }
        }
        
        if let minWinRate = filters.minWinRate {
            results = results.filter { $0.performance.winRate >= minWinRate }
        }
        
        if let pricingModel = filters.pricingModel {
            results = results.filter { $0.pricing.model == pricingModel }
        }
        
        if let tags = filters.tags, !tags.isEmpty {
            results = results.filter { strategy in
                tags.allSatisfy { tag in strategy.tags.contains(tag) }
            }
        }
        
        // Apply sorting
        switch filters.sortBy {
        case .performance:
            results.sort { $0.performance.totalReturn > $1.performance.totalReturn }
        case .rating:
            results.sort { $0.rating > $1.rating }
        case .subscribers:
            results.sort { $0.subscriberCount > $1.subscriberCount }
        case .newest:
            results.sort { $0.createdAt > $1.createdAt }
        case .riskAdjusted:
            results.sort { $0.performance.sharpeRatio > $1.performance.sharpeRatio }
        }
        
        return results
    }
    
    func updateLeaderboard(category: LeaderboardCategory) {
        var entries: [StrategyLeaderboardEntry] = []
        
        let strategies = marketplace.filter { $0.isPublic }
        
        switch category {
        case .overall:
            let sorted = strategies.sorted { calculateOverallScore($0) > calculateOverallScore($1) }
            entries = sorted.enumerated().map { index, strategy in
                StrategyLeaderboardEntry(
                    rank: index + 1,
                    strategy: strategy,
                    score: calculateOverallScore(strategy),
                    change: 0, // Would track historical changes
                    category: category
                )
            }
            
        case .monthly:
            let sorted = strategies.sorted { $0.performance.monthlyReturn > $1.performance.monthlyReturn }
            entries = sorted.enumerated().map { index, strategy in
                StrategyLeaderboardEntry(
                    rank: index + 1,
                    strategy: strategy,
                    score: strategy.performance.monthlyReturn,
                    change: 0,
                    category: category
                )
            }
            
        case .riskAdjusted:
            let sorted = strategies.sorted { $0.performance.sharpeRatio > $1.performance.sharpeRatio }
            entries = sorted.enumerated().map { index, strategy in
                StrategyLeaderboardEntry(
                    rank: index + 1,
                    strategy: strategy,
                    score: strategy.performance.sharpeRatio,
                    change: 0,
                    category: category
                )
            }
            
        case .consistency:
            let sorted = strategies.sorted { $0.performance.consistency > $1.performance.consistency }
            entries = sorted.enumerated().map { index, strategy in
                StrategyLeaderboardEntry(
                    rank: index + 1,
                    strategy: strategy,
                    score: strategy.performance.consistency,
                    change: 0,
                    category: category
                )
            }
            
        case .popularity:
            let sorted = strategies.sorted { $0.subscriberCount > $1.subscriberCount }
            entries = sorted.enumerated().map { index, strategy in
                StrategyLeaderboardEntry(
                    rank: index + 1,
                    strategy: strategy,
                    score: Double(strategy.subscriberCount),
                    change: 0,
                    category: category
                )
            }
            
        case .newStrategies:
            let recent = strategies.filter { $0.createdAt > Date().addingTimeInterval(-30 * 24 * 3600) }
            let sorted = recent.sorted { calculateOverallScore($0) > calculateOverallScore($1) }
            entries = sorted.enumerated().map { index, strategy in
                StrategyLeaderboardEntry(
                    rank: index + 1,
                    strategy: strategy,
                    score: calculateOverallScore(strategy),
                    change: 0,
                    category: category
                )
            }
        }
        
        leaderboard = Array(entries.prefix(100)) // Top 100
    }
    
    func postTradeIdea(_ idea: TradeDetails, commentary: String) {
        let feedItem = SocialFeedItem(
            type: .tradeIdea,
            authorId: "current_user",
            authorName: "Current User",
            authorAvatar: nil,
            timestamp: Date(),
            content: FeedContent(
                title: "\(idea.symbol) Trade Idea",
                body: commentary,
                images: nil,
                strategyId: nil,
                tradeDetails: idea,
                achievement: nil
            ),
            likes: 0,
            comments: [],
            isLiked: false
        )
        
        socialFeed.insert(feedItem, at: 0)
    }
    
    func likeFeedItem(_ itemId: UUID) {
        if let index = socialFeed.firstIndex(where: { $0.id == itemId }) {
            socialFeed[index].isLiked = !socialFeed[index].isLiked
            socialFeed[index].likes += socialFeed[index].isLiked ? 1 : -1
        }
    }
    
    func commentOnFeedItem(_ itemId: UUID, comment: String) {
        if let index = socialFeed.firstIndex(where: { $0.id == itemId }) {
            let newComment = FeedComment(
                authorId: "current_user",
                authorName: "Current User",
                content: comment,
                timestamp: Date()
            )
            socialFeed[index].comments.append(newComment)
        }
    }
    
    func followAuthor(_ authorId: String) {
        if !followedAuthors.contains(authorId) {
            followedAuthors.append(authorId)
        }
    }
    
    func unfollowAuthor(_ authorId: String) {
        followedAuthors.removeAll { $0 == authorId }
    }
    
    // MARK: - Private Methods
    
    private func loadMarketplace() {
        // Load demo strategies
        marketplace = generateDemoStrategies()
    }
    
    private func startCopyTradingMonitor() {
        copyTradingTimer?.invalidate()
        
        copyTradingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task {
                await self.checkForNewTradesToCopy()
            }
        }
    }
    
    private func startFeedUpdates() {
        feedUpdateTimer?.invalidate()
        
        feedUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await self.updateSocialFeed()
            }
        }
        
        // Initial feed
        Task {
            await updateSocialFeed()
        }
    }
    
    private func checkForNewTradesToCopy() async {
        for subscription in subscriptions where subscription.status == .active {
            // Check if strategy has new trades to copy
            // This would integrate with real-time trade monitoring
            
            // For demo, simulate occasional trades
            if Double.random(in: 0...1) < 0.1 {
                await copyTrade(subscription: subscription)
            }
        }
    }
    
    private func copyTrade(subscription: StrategySubscription) async {
        guard marketplace.first(where: { $0.strategyId == subscription.strategyId }) != nil else { return }
        
        // Apply copy settings
        let scaledVolume = 0.01 * subscription.copySettings.scalingFactor
        
        // Check risk limits
        if let maxRisk = subscription.copySettings.stopCopyingOnDrawdown,
           subscription.performance.currentDrawdown > maxRisk {
            // Auto-pause subscription
            pauseSubscription(subscription.id)
            return
        }
        
        // Simulate trade copy
        // In real implementation, would execute actual trade
        
        // Update subscription performance
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index].performance.copiedTrades += 1
        }
    }
    
    private func validateStrategyPerformance(_ strategy: TradingStrategy) async throws -> SocialStrategyPerformance {
        // Run backtest to validate performance
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-90 * 24 * 3600) // 90 days
        
        let request = BacktestRequest(
            strategy: strategy,
            symbol: "EURUSD",
            startDate: startDate,
            endDate: endDate,
            initialCapital: 10000,
            riskPerTrade: 0.02,
            commission: 0.001,
            spread: 0.0001
        )
        
        let result = try await backtestingEngine.runBacktest(request)
        
        return SocialStrategyPerformance(
            totalReturn: result.performance.totalReturn,
            monthlyReturn: result.performance.totalReturn / 3, // Approximate
            sharpeRatio: result.performance.sharpeRatio,
            maxDrawdown: result.performance.maxDrawdown,
            winRate: result.performance.winRate,
            totalTrades: result.performance.numberOfTrades,
            profitFactor: result.performance.profitFactor,
            averageHoldTime: 3600, // Demo value
            consistency: calculateConsistency(result),
            riskScore: calculateRiskScore(result),
            timeActive: endDate.timeIntervalSince(startDate),
            lastUpdated: Date()
        )
    }
    
    private func calculateConsistency(_ backtest: BacktestResult) -> Double {
        // Calculate consistency based on monthly returns variance
        // For demo, return value between 0-1
        return 0.7 + Double.random(in: -0.2...0.2)
    }
    
    private func calculateRiskScore(_ backtest: BacktestResult) -> Double {
        // Calculate risk score based on multiple factors
        let drawdownScore = min(backtest.performance.maxDrawdown * 2, 1.0)
        let volatilityScore = 0.5 // Would calculate from returns
        let leverageScore = 0.3 // Would check position sizing
        
        return (drawdownScore + volatilityScore + leverageScore) / 3
    }
    
    private func calculateOverallScore(_ strategy: SocialSharedStrategy) -> Double {
        let performanceScore = strategy.performance.totalReturn
        let riskAdjustedScore = strategy.performance.sharpeRatio * 10
        let popularityScore = Double(strategy.subscriberCount) / 100
        let ratingScore = strategy.rating * 20
        
        return (performanceScore + riskAdjustedScore + popularityScore + ratingScore) / 4
    }
    
    private func postStrategyUpdate(_ strategy: SocialSharedStrategy) {
        let feedItem = SocialFeedItem(
            type: .strategyUpdate,
            authorId: strategy.authorId,
            authorName: strategy.authorName,
            authorAvatar: strategy.authorAvatar,
            timestamp: Date(),
            content: FeedContent(
                title: "New Strategy: \(strategy.strategy.name)",
                body: strategy.description,
                images: nil,
                strategyId: strategy.strategyId,
                tradeDetails: nil,
                achievement: nil
            ),
            likes: 0,
            comments: [],
            isLiked: false
        )
        
        socialFeed.insert(feedItem, at: 0)
    }
    
    private func updateSocialFeed() async {
        // Generate feed updates from followed authors and subscribed strategies
        
        // Add achievement posts
        checkForAchievements()
        
        // Add market analysis from top traders
        if Double.random(in: 0...1) < 0.3 {
            addMarketAnalysisPost()
        }
    }
    
    private func checkForAchievements() {
        // Check for user achievements
        let achievements: [(AchievementType, String, String)] = [
            (.profitMilestone, "Profit Milestone", "Reached $10,000 in total profits!"),
            (.winStreak, "Win Streak", "10 winning trades in a row!"),
            (.consistencyAward, "Consistency Award", "Profitable for 30 consecutive days!")
        ]
        
        if Double.random(in: 0...1) < 0.1 {
            let achievement = achievements.randomElement()!
            
            let feedItem = SocialFeedItem(
                type: .achievement,
                authorId: "current_user",
                authorName: "Current User",
                authorAvatar: nil,
                timestamp: Date(),
                content: FeedContent(
                    title: achievement.1,
                    body: achievement.2,
                    images: nil,
                    strategyId: nil,
                    tradeDetails: nil,
                    achievement: SocialAchievement(
                        type: achievement.0,
                        title: achievement.1,
                        description: achievement.2,
                        icon: "trophy"
                    )
                ),
                likes: 0,
                comments: [],
                isLiked: false
            )
            
            socialFeed.insert(feedItem, at: 0)
        }
    }
    
    private func addMarketAnalysisPost() {
        let analyses = [
            ("EURUSD Outlook", "Strong support at 1.0850, expecting bullish momentum if we break above 1.0920. Key resistance at 1.0980."),
            ("Market Volatility Alert", "VIX showing signs of expansion. Consider reducing position sizes or tightening stops."),
            ("Fed Decision Impact", "Markets pricing in 25bp hike. Watch for USD strength across major pairs.")
        ]
        
        let analysis = analyses.randomElement()!
        
        let feedItem = SocialFeedItem(
            type: .marketAnalysis,
            authorId: "top_trader_1",
            authorName: "Top Trader",
            authorAvatar: "person.circle",
            timestamp: Date(),
            content: FeedContent(
                title: analysis.0,
                body: analysis.1,
                images: nil,
                strategyId: nil,
                tradeDetails: nil,
                achievement: nil
            ),
            likes: Int.random(in: 5...50),
            comments: [],
            isLiked: false
        )
        
        socialFeed.insert(feedItem, at: 0)
    }
    
    private func generateDemoStrategies() -> [SocialSharedStrategy] {
        let strategies = [
            ("Trend Master Pro", "Advanced trend following system with dynamic position sizing", 45.2, 0.12, 1.8),
            ("Scalping Bot 3000", "High-frequency scalping with AI-powered entry signals", 28.5, 0.08, 2.2),
            ("Risk Parity Portfolio", "Balanced multi-asset strategy with risk parity allocation", 22.3, 0.15, 1.5),
            ("Mean Reversion Alpha", "Statistical arbitrage using mean reversion signals", 35.7, 0.10, 1.6),
            ("Breakout Hunter", "Momentum-based breakout strategy with volatility filters", 52.1, 0.18, 1.9)
        ]
        
        return strategies.enumerated().map { index, data in
            let strategy = TradingStrategy(
                name: data.0,
                description: data.1,
                conditions: [],
                riskManagement: RiskManagement(
                    stopLossPercent: 2,
                    takeProfitPercent: 4,
                    positionSizePercent: 2,
                    maxOpenTrades: 3
                ),
                timeframe: .h1
            )
            
            return SocialSharedStrategy(
                strategyId: UUID().uuidString,
                authorId: "author_\(index)",
                authorName: "Trader \(index + 1)",
                authorAvatar: nil,
                authorVerified: index < 2,
                strategy: strategy,
                performance: SocialStrategyPerformance(
                    totalReturn: data.2,
                    monthlyReturn: data.2 / 3,
                    sharpeRatio: data.4,
                    maxDrawdown: data.3,
                    winRate: 0.55 + Double.random(in: -0.1...0.15),
                    totalTrades: Int.random(in: 100...500),
                    profitFactor: 1.3 + Double.random(in: -0.2...0.5),
                    averageHoldTime: Double.random(in: 3600...86400),
                    consistency: 0.7 + Double.random(in: -0.1...0.2),
                    riskScore: 0.3 + Double.random(in: -0.1...0.3),
                    timeActive: Double.random(in: 30...365) * 24 * 3600,
                    lastUpdated: Date()
                ),
                pricing: StrategyPricing(
                    model: index == 0 ? .free : (index % 2 == 0 ? .subscription : .performance),
                    monthlyFee: index % 2 == 0 ? Double.random(in: 50...200) : nil,
                    performanceFee: index % 2 == 1 ? Double.random(in: 0.1...0.3) : nil,
                    minimumBalance: Double.random(in: 1000...10000),
                    trialPeriod: index > 2 ? 7 * 24 * 3600 : nil
                ),
                description: data.1,
                tags: ["forex", "automated", index < 2 ? "verified" : "community"],
                createdAt: Date().addingTimeInterval(-Double.random(in: 1...90) * 24 * 3600),
                updatedAt: Date(),
                subscriberCount: Int.random(in: 10...1000),
                rating: 3.5 + Double.random(in: 0...1.5),
                reviews: [],
                isPublic: true
            )
        }
    }
}

// MARK: - Supporting Types

enum SocialTradingError: Error {
    case strategyNotFound
    case performanceRequirementsNotMet
    case subscriptionLimitReached
    case insufficientBalance
}

// MARK: - Conversion Extension

extension SocialSharedStrategy {
    func toSharedStrategy() -> SharedStrategy {
        return SharedStrategy(
            id: UUID(uuidString: strategyId) ?? UUID(),
            strategy: strategy,
            authorId: authorId,
            authorName: authorName,
            authorImage: authorAvatar,
            price: pricing.monthlyFee ?? 0,
            subscribers: subscriberCount,
            rating: rating,
            reviews: reviews.count,
            performance: TradingStrategyPerformance(
                totalReturn: performance.totalReturn,
                monthlyReturn: performance.monthlyReturn,
                winRate: performance.winRate,
                profitFactor: performance.profitFactor,
                sharpeRatio: performance.sharpeRatio,
                maxDrawdown: performance.maxDrawdown,
                totalTrades: performance.totalTrades,
                averageHoldTime: performance.averageHoldTime,
                lastUpdated: performance.lastUpdated
            ),
            isPublic: isPublic,
            tags: tags,
            publishedAt: createdAt
        )
    }
}

struct StrategyFilters {
    var minReturn: Double?
    var maxDrawdown: Double?
    var minWinRate: Double?
    var pricingModel: PricingModel?
    var tags: [String]?
    var sortBy: StrategySortOption = .performance
}

enum StrategySortOption {
    case performance
    case rating
    case subscribers
    case newest
    case riskAdjusted
}