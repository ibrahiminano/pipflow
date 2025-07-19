//
//  SocialTradingService.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

class SocialTradingService: ObservableObject {
    static let shared = SocialTradingService()
    
    @Published var topTraders: [Trader] = []
    @Published var followedTraders: [Trader] = []
    @Published var socialFeed: [SocialPost] = []
    @Published var isLoadingTraders = false
    @Published var isLoadingFeed = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMockData()
        startFeedUpdates()
    }
    
    // MARK: - Trader Discovery
    
    func loadTopTraders(filter: TraderFilter = .all) {
        isLoadingTraders = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.topTraders = self?.generateMockTraders() ?? []
            self?.isLoadingTraders = false
        }
    }
    
    func searchTraders(query: String) -> [Trader] {
        guard !query.isEmpty else { return topTraders }
        
        return topTraders.filter { trader in
            trader.username.localizedCaseInsensitiveContains(query) ||
            trader.displayName.localizedCaseInsensitiveContains(query) ||
            trader.specialties.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // MARK: - Following/Copying
    
    func followTrader(_ trader: Trader) {
        if !followedTraders.contains(where: { $0.id == trader.id }) {
            followedTraders.append(trader)
            
            // Post to feed
            let post = SocialPost(
                id: UUID().uuidString,
                type: .follow,
                traderId: "current_user",
                traderName: "You",
                traderImage: nil,
                timestamp: Date(),
                content: "Started following \(trader.displayName)",
                trade: nil,
                performance: nil,
                likes: 0,
                comments: 0,
                isLiked: false
            )
            socialFeed.insert(post, at: 0)
        }
    }
    
    func unfollowTrader(_ trader: Trader) {
        followedTraders.removeAll { $0.id == trader.id }
    }
    
    func startCopyTrading(trader: Trader, settings: CopyTradingSettings) {
        // In production, this would connect to copy trading engine
        print("Starting copy trading for \(trader.username) with settings: \(settings)")
        
        let post = SocialPost(
            id: UUID().uuidString,
            type: .startedCopying,
            traderId: "current_user",
            traderName: "You",
            traderImage: nil,
            timestamp: Date(),
            content: "Started copying \(trader.displayName)'s trades",
            trade: nil,
            performance: nil,
            likes: 0,
            comments: 0,
            isLiked: false
        )
        socialFeed.insert(post, at: 0)
    }
    
    func stopCopyTrading(trader: Trader) {
        print("Stopping copy trading for \(trader.username)")
    }
    
    // MARK: - Social Feed
    
    func loadSocialFeed() {
        isLoadingFeed = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.socialFeed = self?.generateMockSocialFeed() ?? []
            self?.isLoadingFeed = false
        }
    }
    
    private func startFeedUpdates() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.addRandomFeedPost()
            }
            .store(in: &cancellables)
    }
    
    private func addRandomFeedPost() {
        guard let randomTrader = topTraders.randomElement() else { return }
        
        let postTypes: [SocialPostType] = [.trade, .analysis, .performance]
        let postType = postTypes.randomElement() ?? .trade
        
        let post = createMockPost(for: randomTrader, type: postType)
        socialFeed.insert(post, at: 0)
        
        // Keep feed size manageable
        if socialFeed.count > 50 {
            socialFeed = Array(socialFeed.prefix(50))
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func loadMockData() {
        topTraders = generateMockTraders()
        socialFeed = generateMockSocialFeed()
        
        // Simulate some followed traders
        if topTraders.count > 3 {
            followedTraders = Array(topTraders.prefix(3))
        }
    }
    
    private func generateMockTraders() -> [Trader] {
        let traders = [
            Trader(
                id: "1",
                username: "alextrader",
                displayName: "Alex Thompson",
                profileImageURL: nil,
                bio: "Professional forex trader with 10+ years experience. Specializing in major pairs and gold.",
                isVerified: true,
                isPro: true,
                followers: 15420,
                following: 89,
                totalTrades: 3847,
                winRate: 0.73,
                profitFactor: 2.3,
                averageReturn: 0.023,
                monthlyReturn: 0.156,
                yearlyReturn: 0.87,
                riskScore: 4,
                tradingStyle: .swingTrading,
                specialties: ["EURUSD", "GBPUSD", "XAUUSD"],
                performance: createMockPerformance(),
                stats: createMockStats(),
                joinedDate: Date().addingTimeInterval(-365 * 24 * 60 * 60),
                lastActiveDate: Date()
            ),
            Trader(
                id: "2",
                username: "cryptoqueen",
                displayName: "Sarah Chen",
                profileImageURL: nil,
                bio: "Crypto specialist. Focus on BTC, ETH, and emerging altcoins. Risk management is key.",
                isVerified: true,
                isPro: false,
                followers: 8932,
                following: 234,
                totalTrades: 2156,
                winRate: 0.68,
                profitFactor: 1.9,
                averageReturn: 0.018,
                monthlyReturn: 0.124,
                yearlyReturn: 0.65,
                riskScore: 7,
                tradingStyle: .dayTrading,
                specialties: ["BTCUSD", "ETHUSD", "Altcoins"],
                performance: createMockPerformance(),
                stats: createMockStats(),
                joinedDate: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                lastActiveDate: Date()
            ),
            Trader(
                id: "3",
                username: "scalpermaster",
                displayName: "Marcus Rodriguez",
                profileImageURL: nil,
                bio: "High-frequency scalper. Quick profits, tight stops. 100+ trades per day.",
                isVerified: false,
                isPro: true,
                followers: 5421,
                following: 12,
                totalTrades: 28934,
                winRate: 0.62,
                profitFactor: 1.4,
                averageReturn: 0.003,
                monthlyReturn: 0.089,
                yearlyReturn: 0.42,
                riskScore: 8,
                tradingStyle: .scalping,
                specialties: ["EURUSD", "USDJPY", "Indices"],
                performance: createMockPerformance(),
                stats: createMockStats(),
                joinedDate: Date().addingTimeInterval(-90 * 24 * 60 * 60),
                lastActiveDate: Date()
            ),
            Trader(
                id: "4",
                username: "trendmaster",
                displayName: "James Wilson",
                profileImageURL: nil,
                bio: "Position trader focusing on long-term trends. Patience pays.",
                isVerified: true,
                isPro: true,
                followers: 12890,
                following: 156,
                totalTrades: 892,
                winRate: 0.71,
                profitFactor: 3.1,
                averageReturn: 0.045,
                monthlyReturn: 0.098,
                yearlyReturn: 0.78,
                riskScore: 3,
                tradingStyle: .positionTrading,
                specialties: ["Commodities", "Indices", "Forex Majors"],
                performance: createMockPerformance(),
                stats: createMockStats(),
                joinedDate: Date().addingTimeInterval(-730 * 24 * 60 * 60),
                lastActiveDate: Date().addingTimeInterval(-3600)
            ),
            Trader(
                id: "5",
                username: "aitrader",
                displayName: "Neural Capital",
                profileImageURL: nil,
                bio: "AI-powered trading algorithms. Data-driven decisions, emotion-free execution.",
                isVerified: true,
                isPro: true,
                followers: 23456,
                following: 0,
                totalTrades: 15678,
                winRate: 0.69,
                profitFactor: 2.1,
                averageReturn: 0.015,
                monthlyReturn: 0.112,
                yearlyReturn: 0.58,
                riskScore: 5,
                tradingStyle: .algorithmic,
                specialties: ["All Markets", "AI Signals", "Quant"],
                performance: createMockPerformance(),
                stats: createMockStats(),
                joinedDate: Date().addingTimeInterval(-456 * 24 * 60 * 60),
                lastActiveDate: Date()
            )
        ]
        
        return traders
    }
    
    private func createMockPerformance() -> PerformanceData {
        var dailyReturns: [DailyReturn] = []
        var equityCurve: [EquityPoint] = []
        var balance = 10000.0
        
        for i in 0..<30 {
            let date = Date().addingTimeInterval(Double(-i * 24 * 60 * 60))
            let returnPct = Double.random(in: -0.03...0.05)
            let profit = balance * returnPct
            balance += profit
            
            dailyReturns.append(DailyReturn(
                date: date,
                returnPercentage: returnPct,
                profit: profit,
                trades: Int.random(in: 5...50)
            ))
            
            equityCurve.append(EquityPoint(
                date: date,
                balance: balance,
                equity: balance
            ))
        }
        
        return PerformanceData(
            dailyReturns: dailyReturns.reversed(),
            monthlyReturns: [],
            drawdownHistory: [],
            equityCurve: equityCurve.reversed()
        )
    }
    
    private func createMockStats() -> TraderStats {
        return TraderStats(
            totalProfit: Double.random(in: 50000...200000),
            totalLoss: Double.random(in: 20000...80000),
            largestWin: Double.random(in: 5000...15000),
            largestLoss: Double.random(in: 2000...8000),
            averageWin: Double.random(in: 200...800),
            averageLoss: Double.random(in: 100...400),
            averageTradeTime: Double.random(in: 3600...86400),
            profitableDays: Int.random(in: 150...250),
            losingDays: Int.random(in: 50...100),
            tradingDays: 300,
            favoriteSymbols: ["EURUSD", "GBPUSD", "XAUUSD"],
            successRateBySymbol: [
                "EURUSD": 0.72,
                "GBPUSD": 0.68,
                "XAUUSD": 0.75
            ]
        )
    }
    
    private func generateMockSocialFeed() -> [SocialPost] {
        var posts: [SocialPost] = []
        
        for trader in topTraders {
            // Add 2-3 posts per trader
            for _ in 0..<Int.random(in: 2...3) {
                let postType = SocialPostType.allCases.randomElement() ?? .trade
                posts.append(createMockPost(for: trader, type: postType))
            }
        }
        
        return posts.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func createMockPost(for trader: Trader, type: SocialPostType) -> SocialPost {
        let timestamp = Date().addingTimeInterval(Double.random(in: -86400...0))
        
        var content: String
        var trade: SocialTradeInfo?
        var performance: SocialPerformanceInfo?
        
        switch type {
        case .trade:
            let symbols = ["EURUSD", "GBPUSD", "XAUUSD", "BTCUSD"]
            let symbol = symbols.randomElement() ?? "EURUSD"
            let side = TradeSide.allCases.randomElement() ?? .buy
            let profit = Double.random(in: -500...1000)
            
            content = "Closed \(side.rawValue.uppercased()) position on \(symbol)"
            trade = SocialTradeInfo(
                symbol: symbol,
                side: side,
                volume: Double.random(in: 0.01...1.0),
                entryPrice: 1.0850,
                exitPrice: 1.0870,
                profit: profit,
                profitPercentage: profit / 10000,
                duration: "2h 34m"
            )
            
        case .analysis:
            let analyses = [
                "EURUSD showing strong resistance at 1.0900. Watch for breakout.",
                "Gold forming a bullish flag pattern. Target: $2,700",
                "Bitcoin consolidating above $100k. Accumulation phase.",
                "Market sentiment turning bearish. Risk-off mode activated.",
                "Major NFP release tomorrow. Expecting volatility spike."
            ]
            content = analyses.randomElement() ?? ""
            
        case .performance:
            let period = ["week", "month", "quarter"].randomElement() ?? "month"
            let returnPct = Double.random(in: -5...20)
            content = "Portfolio performance update"
            performance = SocialPerformanceInfo(
                period: period,
                returnPercentage: returnPct,
                trades: Int.random(in: 20...200),
                winRate: Double.random(in: 0.6...0.8),
                profitFactor: Double.random(in: 1.2...3.0)
            )
            
        case .follow:
            content = "Started following @\(topTraders.randomElement()?.username ?? "trader")"
            
        case .milestone:
            let milestones = [
                "Reached 10,000 followers! Thank you for your trust.",
                "1000 consecutive profitable days!",
                "New all-time high in portfolio equity.",
                "Celebrating 5 years of profitable trading."
            ]
            content = milestones.randomElement() ?? ""
            
        case .education:
            let tips = [
                "Trading Tip: Always use stop losses. Capital preservation is key.",
                "Risk Management 101: Never risk more than 2% per trade.",
                "Psychology matters: Stay disciplined and stick to your plan.",
                "Market Analysis: Understanding support and resistance levels."
            ]
            content = tips.randomElement() ?? ""
            
        case .startedCopying:
            content = "Started copying trades from @\(topTraders.randomElement()?.username ?? "trader")"
        }
        
        return SocialPost(
            id: UUID().uuidString,
            type: type,
            traderId: trader.id,
            traderName: trader.displayName,
            traderImage: trader.profileImageURL,
            timestamp: timestamp,
            content: content,
            trade: trade,
            performance: performance,
            likes: Int.random(in: 0...500),
            comments: Int.random(in: 0...50),
            isLiked: Bool.random()
        )
    }
}

// MARK: - Social Post Model

struct SocialPost: Identifiable {
    let id: String
    let type: SocialPostType
    let traderId: String
    let traderName: String
    let traderImage: String?
    let timestamp: Date
    let content: String
    let trade: SocialTradeInfo?
    let performance: SocialPerformanceInfo?
    var likes: Int
    var comments: Int
    var isLiked: Bool
}

enum SocialPostType: CaseIterable {
    case trade
    case analysis
    case performance
    case follow
    case milestone
    case education
    case startedCopying
}

struct SocialTradeInfo {
    let symbol: String
    let side: TradeSide
    let volume: Double
    let entryPrice: Double
    let exitPrice: Double
    let profit: Double
    let profitPercentage: Double
    let duration: String
}

struct SocialPerformanceInfo {
    let period: String
    let returnPercentage: Double
    let trades: Int
    let winRate: Double
    let profitFactor: Double
}

// MARK: - Trader Filter

enum TraderFilter: String, CaseIterable {
    case all = "All"
    case topPerformers = "Top Performers"
    case mostFollowed = "Most Followed"
    case verified = "Verified"
    case lowRisk = "Low Risk"
    case recentlyActive = "Active Now"
    
    func apply(to traders: [Trader]) -> [Trader] {
        switch self {
        case .all:
            return traders
        case .topPerformers:
            return traders.sorted { $0.yearlyReturn > $1.yearlyReturn }
        case .mostFollowed:
            return traders.sorted { $0.followers > $1.followers }
        case .verified:
            return traders.filter { $0.isVerified }
        case .lowRisk:
            return traders.filter { $0.riskScore <= 3 }
        case .recentlyActive:
            let oneHourAgo = Date().addingTimeInterval(-3600)
            return traders.filter { $0.lastActiveDate > oneHourAgo }
        }
    }
}