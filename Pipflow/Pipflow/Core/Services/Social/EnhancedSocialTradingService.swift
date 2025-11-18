//
//  EnhancedSocialTradingService.swift
//  Pipflow
//
//  Enhanced social trading service with real-time WebSocket integration
//

import Foundation
import Combine

@MainActor
class EnhancedSocialTradingService: ObservableObject {
    static let shared = EnhancedSocialTradingService()
    
    // MARK: - Published Properties
    
    @Published var topTraders: [Trader] = []
    @Published var followedTraders: [Trader] = []
    @Published var copiedTraders: [Trader] = []
    @Published var socialFeed: [SocialPost] = []
    @Published var traderPerformanceUpdates: [String: TraderPerformanceUpdate] = [:]
    @Published var isLoadingTraders = false
    @Published var isLoadingFeed = false
    
    // MARK: - Services
    
    private let webSocketService = MetaAPIWebSocketService.shared
    private let positionTrackingService = PositionTrackingService.shared
    private let tradeMirroringService = TradeMirroringService.shared
    private let riskCalculator = RiskScoreCalculator()
    private let performanceAnalyzer = TraderPerformanceAnalyzer()
    
    private var cancellables = Set<AnyCancellable>()
    private var traderPositions: [String: [TrackedPosition]] = [:]
    
    // MARK: - Initialization
    
    private init() {
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Monitor position updates from WebSocket
        positionTrackingService.$trackedPositions
            .sink { [weak self] positions in
                self?.updateTraderPerformance(with: positions)
            }
            .store(in: &cancellables)
        
        // Monitor copy trading sessions
        tradeMirroringService.$activeSessions
            .sink { [weak self] sessions in
                self?.updateCopiedTraders(from: sessions)
            }
            .store(in: &cancellables)
        
        // Real-time feed updates
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRealTimeFeed()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadTopTraders(filter: TraderFilter = .all) async {
        isLoadingTraders = true
        
        do {
            // In production, this would fetch from API
            let traders = await fetchTradersFromAPI()
            
            // Calculate real-time risk scores
            for trader in traders {
                let positions = traderPositions[trader.id] ?? []
                let _ = riskCalculator.calculateRiskScore(for: trader, positions: positions)
                // Note: Would need to make Trader mutable or create a new instance to update risk score
            }
            
            topTraders = filter.apply(to: traders)
            isLoadingTraders = false
            
        } catch {
            print("Failed to load traders: \(error)")
            isLoadingTraders = false
        }
    }
    
    func getTraderPerformanceAnalysis(trader: Trader) -> TraderPerformanceAnalysis {
        let positions = traderPositions[trader.id] ?? []
        return performanceAnalyzer.analyzePerformance(
            trader: trader,
            positions: positions,
            historicalData: trader.performance
        )
    }
    
    func getRiskAnalysis(for trader: Trader) -> TraderRiskAnalysis {
        let positions = traderPositions[trader.id] ?? []
        return riskCalculator.calculateDetailedRiskAnalysis(for: trader, positions: positions)
    }
    
    func followTrader(_ trader: Trader) {
        guard !followedTraders.contains(where: { $0.id == trader.id }) else { return }
        
        followedTraders.append(trader)
        subscribeToTraderUpdates(traderId: trader.id)
        
        // Create social post
        let post = createFollowPost(trader: trader)
        socialFeed.insert(post, at: 0)
    }
    
    func unfollowTrader(_ trader: Trader) {
        followedTraders.removeAll { $0.id == trader.id }
        unsubscribeFromTraderUpdates(traderId: trader.id)
    }
    
    func startCopyTrading(trader: Trader, settings: CopyTradingConfig) {
        // Use the trade mirroring service
        tradeMirroringService.startMirroring(traderId: trader.id, settings: settings)
        
        if !copiedTraders.contains(where: { $0.id == trader.id }) {
            copiedTraders.append(trader)
        }
        
        // Create social post
        let post = createCopyTradingPost(trader: trader)
        socialFeed.insert(post, at: 0)
    }
    
    func stopCopyTrading(trader: Trader) {
        tradeMirroringService.stopMirroring(traderId: trader.id)
        copiedTraders.removeAll { $0.id == trader.id }
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() {
        Task {
            await loadTopTraders()
            loadSocialFeed()
        }
    }
    
    private func fetchTradersFromAPI() async -> [Trader] {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // In production, this would be a real API call
        return SocialTradingService.shared.topTraders
    }
    
    private func updateTraderPerformance(with positions: [TrackedPosition]) {
        // Group positions by trader (in real implementation)
        // For now, simulate performance updates
        
        for trader in topTraders {
            let update = TraderPerformanceUpdate(
                traderId: trader.id,
                timestamp: Date(),
                openPositions: Int.random(in: 0...10),
                dailyPL: Double.random(in: -500...1000),
                dailyPLPercent: Double.random(in: -5...10),
                currentDrawdown: Double.random(in: 0...0.2),
                updatedWinRate: trader.winRate + Double.random(in: -0.02...0.02)
            )
            
            traderPerformanceUpdates[trader.id] = update
        }
    }
    
    private func updateCopiedTraders(from sessions: [String: CopySession]) {
        // Update copied traders list based on active sessions
        copiedTraders = topTraders.filter { trader in
            sessions.keys.contains(trader.id)
        }
    }
    
    private func subscribeToTraderUpdates(traderId: String) {
        // In production, subscribe to trader's WebSocket channel
        print("Subscribed to updates for trader: \(traderId)")
    }
    
    private func unsubscribeFromTraderUpdates(traderId: String) {
        // In production, unsubscribe from trader's WebSocket channel
        print("Unsubscribed from updates for trader: \(traderId)")
    }
    
    private func updateRealTimeFeed() {
        // Add real-time updates to feed
        guard let randomTrader = topTraders.randomElement() else { return }
        
        if let performanceUpdate = traderPerformanceUpdates[randomTrader.id],
           performanceUpdate.dailyPL != 0 {
            
            let post = SocialPost(
                id: UUID().uuidString,
                type: .trade,
                traderId: randomTrader.id,
                traderName: randomTrader.displayName,
                traderImage: randomTrader.profileImageURL,
                timestamp: Date(),
                content: "Closed position with \(performanceUpdate.dailyPL > 0 ? "profit" : "loss")",
                trade: SocialTradeInfo(
                    symbol: ["EURUSD", "GBPUSD", "XAUUSD"].randomElement() ?? "EURUSD",
                    side: TradeSide.allCases.randomElement() ?? .buy,
                    volume: Double.random(in: 0.01...1.0),
                    entryPrice: 1.0850,
                    exitPrice: 1.0870,
                    profit: performanceUpdate.dailyPL,
                    profitPercentage: performanceUpdate.dailyPLPercent / 100,
                    duration: "\(Int.random(in: 1...24))h \(Int.random(in: 0...59))m"
                ),
                performance: nil,
                likes: 0,
                comments: 0,
                shares: 0,
                isLiked: false
            )
            
            socialFeed.insert(post, at: 0)
            
            // Keep feed size manageable
            if socialFeed.count > 100 {
                socialFeed = Array(socialFeed.prefix(100))
            }
        }
    }
    
    private func loadSocialFeed() {
        isLoadingFeed = true
        
        // Use existing social feed
        socialFeed = SocialTradingService.shared.socialFeed
        isLoadingFeed = false
    }
    
    // MARK: - Helper Methods
    
    private func createFollowPost(trader: Trader) -> SocialPost {
        return SocialPost(
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
            shares: 0,
            isLiked: false
        )
    }
    
    private func createCopyTradingPost(trader: Trader) -> SocialPost {
        return SocialPost(
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
            shares: 0,
            isLiked: false
        )
    }
}

// MARK: - Performance Update Model

struct TraderPerformanceUpdate {
    let traderId: String
    let timestamp: Date
    let openPositions: Int
    let dailyPL: Double
    let dailyPLPercent: Double
    let currentDrawdown: Double
    let updatedWinRate: Double
}

// MARK: - Performance Analyzer

class TraderPerformanceAnalyzer {
    
    func analyzePerformance(
        trader: Trader,
        positions: [TrackedPosition],
        historicalData: PerformanceData
    ) -> TraderPerformanceAnalysis {
        
        // Calculate real-time metrics
        let currentPL = positions.reduce(0) { $0 + $1.netPL }
        let totalVolume = positions.reduce(0) { $0 + $1.volume }
        let averagePositionSize = positions.isEmpty ? 0 : totalVolume / Double(positions.count)
        
        // Symbol distribution
        var symbolCounts: [String: Int] = [:]
        for position in positions {
            symbolCounts[position.symbol, default: 0] += 1
        }
        
        // Calculate trading frequency
        let recentTrades = historicalData.dailyReturns.suffix(30)
        let averageDailyTrades = recentTrades.isEmpty ? 0 :
            Double(recentTrades.reduce(0) { $0 + $1.trades }) / Double(recentTrades.count)
        
        // Performance consistency
        let monthlyReturns = historicalData.monthlyReturns.map { $0.returnPercentage }
        let positiveMonths = monthlyReturns.filter { $0 > 0 }.count
        let consistencyScore = monthlyReturns.isEmpty ? 0 :
            Double(positiveMonths) / Double(monthlyReturns.count)
        
        // Best and worst periods
        let bestMonth = historicalData.monthlyReturns.max { $0.returnPercentage < $1.returnPercentage }
        let worstMonth = historicalData.monthlyReturns.min { $0.returnPercentage < $1.returnPercentage }
        
        return TraderPerformanceAnalysis(
            currentOpenPositions: positions.count,
            currentPL: currentPL,
            averagePositionSize: averagePositionSize,
            symbolDistribution: symbolCounts,
            averageDailyTrades: averageDailyTrades,
            consistencyScore: consistencyScore,
            bestMonthReturn: bestMonth?.returnPercentage ?? 0,
            worstMonthReturn: worstMonth?.returnPercentage ?? 0,
            currentMonthReturn: calculateCurrentMonthReturn(historicalData: historicalData),
            projectedMonthlyReturn: projectMonthlyReturn(
                currentPL: currentPL,
                daysInMonth: getDaysInCurrentMonth()
            )
        )
    }
    
    private func calculateCurrentMonthReturn(historicalData: PerformanceData) -> Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let currentMonthReturns = historicalData.dailyReturns.filter { dailyReturn in
            let month = Calendar.current.component(.month, from: dailyReturn.date)
            let year = Calendar.current.component(.year, from: dailyReturn.date)
            return month == currentMonth && year == currentYear
        }
        
        return currentMonthReturns.reduce(0) { $0 + $1.returnPercentage }
    }
    
    private func projectMonthlyReturn(currentPL: Double, daysInMonth: Int) -> Double {
        let dayOfMonth = Calendar.current.component(.day, from: Date())
        guard dayOfMonth > 0 else { return 0 }
        
        let dailyAverage = currentPL / Double(dayOfMonth)
        return dailyAverage * Double(daysInMonth)
    }
    
    private func getDaysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: Date())
        return range?.count ?? 30
    }
}

// MARK: - Performance Analysis Model

struct TraderPerformanceAnalysis {
    let currentOpenPositions: Int
    let currentPL: Double
    let averagePositionSize: Double
    let symbolDistribution: [String: Int]
    let averageDailyTrades: Double
    let consistencyScore: Double
    let bestMonthReturn: Double
    let worstMonthReturn: Double
    let currentMonthReturn: Double
    let projectedMonthlyReturn: Double
    
    var topTradedSymbols: [(symbol: String, count: Int)] {
        symbolDistribution.sorted { $0.value > $1.value }
            .prefix(3)
            .map { ($0.key, $0.value) }
    }
    
    var diversificationScore: Double {
        guard !symbolDistribution.isEmpty else { return 0 }
        let uniqueSymbols = symbolDistribution.count
        return min(1.0, Double(uniqueSymbols) / 10.0)
    }
}