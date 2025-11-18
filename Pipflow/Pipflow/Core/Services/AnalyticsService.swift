//
//  AnalyticsService.swift
//  Pipflow
//
//  Service for calculating and managing trading analytics
//

import Foundation
import Combine

@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var currentSummary: AnalyticsSummary?
    @Published var performanceMetrics: [AnalyticsPeriod: AnalyticsPerformanceMetrics] = [:]
    @Published var equityCurve: EquityCurve?
    @Published var tradeDistribution: TradeDistribution?
    @Published var riskAnalysis: RiskAnalysis?
    @Published var journalEntries: [TradeJournalEntry] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let tradingService = TradingService.shared
    private let positionTrackingService = PositionTrackingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Update analytics when positions change
        positionTrackingService.$trackedPositions
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task {
                    await self?.updateCurrentSummary()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadAnalytics(for accountId: UUID, period: AnalyticsPeriod) async {
        isLoading = true
        error = nil
        
        // In production, this would fetch from backend
        // For now, generate mock data
        let metrics = generateMockMetrics(for: accountId, period: period)
        performanceMetrics[period] = metrics
        
        // Load other analytics data
        if equityCurve == nil {
            equityCurve = generateMockEquityCurve()
        }
        
        if tradeDistribution == nil {
            tradeDistribution = generateMockTradeDistribution()
        }
        
        if riskAnalysis == nil {
            riskAnalysis = generateMockRiskAnalysis()
        }
        
        isLoading = false
    }
    
    func updateCurrentSummary() async {
        guard let account = tradingService.activeAccount else { return }
        
        let positions = positionTrackingService.trackedPositions
        let openPositions = positions // All tracked positions are open
        
        // Calculate current metrics
        let currentBalance = account.balance
        let unrealizedPnL = openPositions.reduce(0) { $0 + $1.netPL }
        
        // Calculate daily change (mock for now)
        let dayChange = Double.random(in: -500...500)
        let dayChangePercent = (dayChange / currentBalance) * 100
        
        // Calculate other changes (mock for now)
        let weekChange = Double.random(in: -1500...1500)
        let weekChangePercent = (weekChange / currentBalance) * 100
        let monthChange = Double.random(in: -3000...3000)
        let monthChangePercent = (monthChange / currentBalance) * 100
        
        currentSummary = AnalyticsSummary(
            accountId: UUID(uuidString: account.id) ?? UUID(),
            lastUpdated: Date(),
            currentBalance: currentBalance,
            dayChange: dayChange,
            dayChangePercent: dayChangePercent,
            weekChange: weekChange,
            weekChangePercent: weekChangePercent,
            monthChange: monthChange,
            monthChangePercent: monthChangePercent,
            openPositions: openPositions.count,
            todayTrades: Int.random(in: 0...10),
            todayPnL: dayChange,
            unrealizedPnL: unrealizedPnL
        )
    }
    
    func addJournalEntry(_ entry: TradeJournalEntry) {
        journalEntries.append(entry)
        // In production, save to backend
    }
    
    func updateJournalEntry(_ entry: TradeJournalEntry) {
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index] = entry
            // In production, save to backend
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockMetrics(for accountId: UUID, period: AnalyticsPeriod) -> AnalyticsPerformanceMetrics {
        let endDate = Date()
        let startDate = period.startDate(from: endDate)
        
        return AnalyticsPerformanceMetrics(
            accountId: accountId,
            period: period,
            startDate: startDate,
            endDate: endDate,
            totalReturn: Double.random(in: -20...50),
            monthlyReturn: Double.random(in: -10...20),
            dailyReturn: Double.random(in: -2...2),
            maxDrawdown: Double.random(in: -30...(-5)),
            maxDrawdownDuration: Int.random(in: 5...30),
            totalTrades: Int.random(in: 50...500),
            winningTrades: Int.random(in: 25...300),
            losingTrades: Int.random(in: 25...200),
            winRate: Double.random(in: 0.4...0.7),
            averageWin: Double.random(in: 50...200),
            averageLoss: Double.random(in: -150...(-30)),
            largestWin: Double.random(in: 500...2000),
            largestLoss: Double.random(in: -1000...(-200)),
            profitFactor: Double.random(in: 0.8...2.5),
            expectancy: Double.random(in: -10...50),
            sharpeRatio: Double.random(in: -0.5...2.5),
            sortinoRatio: Double.random(in: -0.3...3.0),
            calmarRatio: Double.random(in: -0.5...2.0),
            standardDeviation: Double.random(in: 5...25),
            downsideDeviation: Double.random(in: 3...15),
            valueAtRisk: Double.random(in: -500...(-100)),
            conditionalValueAtRisk: Double.random(in: -700...(-150)),
            averageTradesPerDay: Double.random(in: 1...10),
            averageHoldingPeriod: TimeInterval.random(in: 3600...86400),
            tradingDays: Int.random(in: 20...250),
            activeDays: Int.random(in: 15...200),
            averagePositionSize: Double.random(in: 0.01...2.0),
            maxConcurrentPositions: Int.random(in: 1...10),
            exposure: Double.random(in: 10...80)
        )
    }
    
    private func generateMockEquityCurve() -> EquityCurve {
        var dataPoints: [EquityDataPoint] = []
        let startBalance = 10000.0
        var currentBalance = startBalance
        var peakBalance = startBalance
        var troughBalance = startBalance
        
        // Generate 30 days of data
        for i in 0..<30 {
            let date = Calendar.current.date(byAdding: .day, value: -30 + i, to: Date())!
            let dailyReturn = Double.random(in: -0.03...0.03)
            let profit = currentBalance * dailyReturn
            currentBalance += profit
            
            if currentBalance > peakBalance {
                peakBalance = currentBalance
            }
            if currentBalance < troughBalance {
                troughBalance = currentBalance
            }
            
            let drawdown = peakBalance > 0 ? ((currentBalance - peakBalance) / peakBalance) * 100 : 0
            
            dataPoints.append(EquityDataPoint(
                timestamp: date,
                balance: currentBalance,
                profit: profit,
                drawdown: drawdown,
                openPositions: Int.random(in: 0...5),
                realizedPnL: profit * 0.8,
                unrealizedPnL: profit * 0.2
            ))
        }
        
        return EquityCurve(
            dataPoints: dataPoints,
            startingBalance: startBalance,
            endingBalance: currentBalance,
            peakBalance: peakBalance,
            troughBalance: troughBalance
        )
    }
    
    private func generateMockTradeDistribution() -> TradeDistribution {
        // Profit distribution
        let profitBuckets = [
            ProfitBucket(range: "-$500+", count: 5, percentage: 5),
            ProfitBucket(range: "-$500 to -$200", count: 10, percentage: 10),
            ProfitBucket(range: "-$200 to -$50", count: 15, percentage: 15),
            ProfitBucket(range: "-$50 to $0", count: 10, percentage: 10),
            ProfitBucket(range: "$0 to $50", count: 20, percentage: 20),
            ProfitBucket(range: "$50 to $200", count: 25, percentage: 25),
            ProfitBucket(range: "$200 to $500", count: 10, percentage: 10),
            ProfitBucket(range: "$500+", count: 5, percentage: 5)
        ]
        
        // Time distribution
        let timeDistribution = [
            TimeDistribution(duration: "< 5 min", count: 50, averageProfit: 15),
            TimeDistribution(duration: "5-30 min", count: 80, averageProfit: 45),
            TimeDistribution(duration: "30 min - 1h", count: 60, averageProfit: 75),
            TimeDistribution(duration: "1h - 4h", count: 40, averageProfit: 120),
            TimeDistribution(duration: "4h - 1d", count: 20, averageProfit: 200),
            TimeDistribution(duration: "> 1d", count: 10, averageProfit: 350)
        ]
        
        // Symbol distribution
        let symbolDistribution = [
            SymbolPerformance(symbol: "EUR/USD", tradeCount: 45, totalProfit: 1250, winRate: 0.65, averageProfit: 27.78),
            SymbolPerformance(symbol: "GBP/USD", tradeCount: 38, totalProfit: 890, winRate: 0.58, averageProfit: 23.42),
            SymbolPerformance(symbol: "USD/JPY", tradeCount: 32, totalProfit: -120, winRate: 0.45, averageProfit: -3.75),
            SymbolPerformance(symbol: "XAU/USD", tradeCount: 28, totalProfit: 1680, winRate: 0.71, averageProfit: 60.00),
            SymbolPerformance(symbol: "BTC/USD", tradeCount: 25, totalProfit: 2340, winRate: 0.68, averageProfit: 93.60)
        ]
        
        // Day of week distribution
        let dayDistribution = [
            DayPerformance(dayOfWeek: "Monday", tradeCount: 42, totalProfit: 580, winRate: 0.62),
            DayPerformance(dayOfWeek: "Tuesday", tradeCount: 48, totalProfit: 920, winRate: 0.65),
            DayPerformance(dayOfWeek: "Wednesday", tradeCount: 51, totalProfit: 1100, winRate: 0.68),
            DayPerformance(dayOfWeek: "Thursday", tradeCount: 46, totalProfit: 450, winRate: 0.58),
            DayPerformance(dayOfWeek: "Friday", tradeCount: 38, totalProfit: -150, winRate: 0.48)
        ]
        
        // Hour distribution
        var hourDistribution: [HourPerformance] = []
        for hour in 0..<24 {
            hourDistribution.append(HourPerformance(
                hour: hour,
                tradeCount: Int.random(in: 5...20),
                totalProfit: Double.random(in: -200...400),
                winRate: Double.random(in: 0.4...0.7)
            ))
        }
        
        return TradeDistribution(
            profitDistribution: profitBuckets,
            timeDistribution: timeDistribution,
            symbolDistribution: symbolDistribution,
            dayOfWeekDistribution: dayDistribution,
            hourDistribution: hourDistribution
        )
    }
    
    private func generateMockRiskAnalysis() -> RiskAnalysis {
        let currentRisk = CurrentRiskMetrics(
            openPositionRisk: Double.random(in: 500...2000),
            totalExposure: Double.random(in: 5000...20000),
            marginUsed: Double.random(in: 1000...5000),
            marginAvailable: Double.random(in: 5000...15000),
            leverage: Double.random(in: 1...10),
            correlatedRisk: Double.random(in: 100...1000),
            worstCaseScenario: Double.random(in: -3000...(-500))
        )
        
        let historicalRisk = HistoricalRiskMetrics(
            averageLeverage: Double.random(in: 2...5),
            maxLeverage: Double.random(in: 5...15),
            averageExposure: Double.random(in: 30...60),
            maxExposure: Double.random(in: 60...90),
            riskAdjustedReturn: Double.random(in: 0.5...2.0),
            maxConsecutiveLosses: Int.random(in: 3...8),
            largestDailyLoss: Double.random(in: -1000...(-200)),
            recoveryTime: Int.random(in: 5...30)
        )
        
        let correlations = [
            SymbolCorrelation(symbol1: "EUR/USD", symbol2: "GBP/USD", correlation: 0.85, period: 30),
            SymbolCorrelation(symbol1: "USD/JPY", symbol2: "EUR/JPY", correlation: 0.72, period: 30),
            SymbolCorrelation(symbol1: "XAU/USD", symbol2: "USD/CHF", correlation: -0.65, period: 30)
        ]
        
        let symbolExposure = [
            SymbolExposure(symbol: "EUR/USD", exposure: 5000, percentage: 25),
            SymbolExposure(symbol: "GBP/USD", exposure: 4000, percentage: 20),
            SymbolExposure(symbol: "XAU/USD", exposure: 6000, percentage: 30),
            SymbolExposure(symbol: "BTC/USD", exposure: 3000, percentage: 15),
            SymbolExposure(symbol: "USD/JPY", exposure: 2000, percentage: 10)
        ]
        
        let sectorExposure = [
            SectorExposure(sector: "Forex Major", exposure: 11000, percentage: 55),
            SectorExposure(sector: "Commodities", exposure: 6000, percentage: 30),
            SectorExposure(sector: "Crypto", exposure: 3000, percentage: 15)
        ]
        
        let currencyExposure = [
            CurrencyExposure(currency: "USD", exposure: 12000, percentage: 60),
            CurrencyExposure(currency: "EUR", exposure: 4000, percentage: 20),
            CurrencyExposure(currency: "GBP", exposure: 2000, percentage: 10),
            CurrencyExposure(currency: "JPY", exposure: 2000, percentage: 10)
        ]
        
        let exposureAnalysis = ExposureAnalysis(
            bySymbol: symbolExposure,
            bySector: sectorExposure,
            byCurrency: currencyExposure,
            concentrationRisk: 0.35
        )
        
        return RiskAnalysis(
            currentRisk: currentRisk,
            historicalRisk: historicalRisk,
            correlations: correlations,
            exposureAnalysis: exposureAnalysis
        )
    }
}