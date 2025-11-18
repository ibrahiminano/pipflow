//
//  PositionTrackingServiceTests.swift
//  PipflowTests
//
//  Unit tests for Position Tracking Service with P&L calculations
//

import XCTest
import Combine
@testable import Pipflow

class PositionTrackingServiceTests: XCTestCase {
    var sut: PositionTrackingService!
    var mockWebSocketService: MockMetaAPIWebSocketService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockWebSocketService = MockMetaAPIWebSocketService()
        cancellables = Set<AnyCancellable>()
        // Note: PositionTrackingService is a singleton, so we'll test with the shared instance
        sut = PositionTrackingService.shared
    }
    
    override func tearDown() {
        cancellables = nil
        mockWebSocketService = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - P&L Calculation Tests
    
    func testBuyPositionProfitCalculation() {
        // Given
        let position = createTestPosition(
            type: .buy,
            openPrice: 1.0850,
            currentPrice: 1.0875,
            volume: 1.0
        )
        
        // When
        let pl = calculatePL(for: position)
        
        // Then
        XCTAssertEqual(pl.pl, 250, accuracy: 0.01) // (1.0875 - 1.0850) * 1.0 * 100000
        XCTAssertEqual(pl.pips, 25, accuracy: 0.1) // 0.0025 * 10000
    }
    
    func testSellPositionProfitCalculation() {
        // Given
        let position = createTestPosition(
            type: .sell,
            openPrice: 1.2650,
            currentPrice: 1.2625,
            volume: 1.0
        )
        
        // When
        let pl = calculatePL(for: position)
        
        // Then
        XCTAssertEqual(pl.pl, 250, accuracy: 0.01) // (1.2650 - 1.2625) * 1.0 * 100000
        XCTAssertEqual(pl.pips, 25, accuracy: 0.1) // 0.0025 * 10000
    }
    
    func testJPYPairPipsCalculation() {
        // Given
        let position = createTestPosition(
            type: .buy,
            symbol: "USDJPY",
            openPrice: 110.50,
            currentPrice: 110.75,
            volume: 1.0
        )
        
        // When
        let pl = calculatePL(for: position)
        
        // Then
        XCTAssertEqual(pl.pips, 25, accuracy: 0.1) // 0.25 * 100 for JPY pairs
    }
    
    func testPipValueCalculation() {
        // Given - EUR/USD position
        let pipValueEURUSD = calculatePipValue(symbol: "EURUSD", volume: 1.0)
        
        // Then
        XCTAssertEqual(pipValueEURUSD, 10, accuracy: 0.01) // 1.0 * 100000 * 0.0001
        
        // Given - USD/JPY position
        let pipValueUSDJPY = calculatePipValue(symbol: "USDJPY", volume: 1.0)
        
        // Then
        XCTAssertEqual(pipValueUSDJPY, 1000, accuracy: 0.01) // 1.0 * 100000 * 0.01
    }
    
    func testMarginCalculation() {
        // Given
        let margin = calculateMargin(
            symbol: "EURUSD",
            volume: 1.0,
            openPrice: 1.0850,
            leverage: 100
        )
        
        // Then
        XCTAssertEqual(margin, 1085, accuracy: 0.01) // (1.0 * 100000 * 1.0850) / 100
    }
    
    func testRiskRewardRatioCalculation() {
        // Given - Buy position
        let rrBuy = calculateRiskReward(
            type: .buy,
            openPrice: 1.0850,
            stopLoss: 1.0800,
            takeProfit: 1.0950
        )
        
        // Then
        XCTAssertNotNil(rrBuy)
        XCTAssertEqual(rrBuy!, 2.0, accuracy: 0.01) // Reward (100 pips) / Risk (50 pips)
        
        // Given - Sell position
        let rrSell = calculateRiskReward(
            type: .sell,
            openPrice: 1.2650,
            stopLoss: 1.2700,
            takeProfit: 1.2500
        )
        
        // Then
        XCTAssertNotNil(rrSell)
        XCTAssertEqual(rrSell!, 3.0, accuracy: 0.01) // Reward (150 pips) / Risk (50 pips)
    }
    
    func testNetPLCalculation() {
        // Given
        let position = TrackedPosition(
            id: "test1",
            symbol: "EURUSD",
            type: .buy,
            volume: 1.0,
            openPrice: 1.0850,
            openTime: Date(),
            stopLoss: 1.0800,
            takeProfit: 1.0900,
            comment: nil,
            magic: nil,
            currentPrice: 1.0875,
            bid: 1.0874,
            ask: 1.0876,
            unrealizedPL: 250,
            unrealizedPLPercent: 2.3,
            commission: -5,
            swap: -2,
            netPL: 243, // 250 - 5 - 2
            pipValue: 10,
            pipsProfit: 25,
            spread: 0.0002,
            spreadCost: 2,
            marginUsed: 1085,
            riskRewardRatio: 1.0
        )
        
        // Then
        XCTAssertEqual(position.netPL, 243) // Gross P/L - Commission - Swap
    }
    
    // MARK: - Aggregate Metrics Tests
    
    func testWinRateCalculation() {
        // Given
        let positions = [
            createTestPosition(id: "1", unrealizedPL: 100, netPL: 95),
            createTestPosition(id: "2", unrealizedPL: -50, netPL: -55),
            createTestPosition(id: "3", unrealizedPL: 200, netPL: 195),
            createTestPosition(id: "4", unrealizedPL: -25, netPL: -30)
        ]
        
        // When
        let winRate = calculateWinRate(from: positions)
        
        // Then
        XCTAssertEqual(winRate, 50.0) // 2 winning / 4 total * 100
    }
    
    func testAverageWinLossCalculation() {
        // Given
        let positions = [
            createTestPosition(id: "1", netPL: 100),
            createTestPosition(id: "2", netPL: -50),
            createTestPosition(id: "3", netPL: 200),
            createTestPosition(id: "4", netPL: -75)
        ]
        
        // When
        let metrics = calculateAverageWinLoss(from: positions)
        
        // Then
        XCTAssertEqual(metrics.averageWin, 150) // (100 + 200) / 2
        XCTAssertEqual(metrics.averageLoss, 62.5) // (50 + 75) / 2
        XCTAssertEqual(metrics.profitFactor, 2.4, accuracy: 0.01) // 150 / 62.5
    }
    
    // MARK: - Helper Methods
    
    private func createTestPosition(
        id: String = "test1",
        symbol: String = "EURUSD",
        type: TradeType = .buy,
        openPrice: Double = 1.0850,
        currentPrice: Double = 1.0875,
        volume: Double = 1.0,
        unrealizedPL: Double = 0,
        netPL: Double = 0
    ) -> TrackedPosition {
        return TrackedPosition(
            id: id,
            symbol: symbol,
            type: type,
            volume: volume,
            openPrice: openPrice,
            openTime: Date(),
            stopLoss: nil,
            takeProfit: nil,
            comment: nil,
            magic: nil,
            currentPrice: currentPrice,
            bid: currentPrice - 0.0001,
            ask: currentPrice + 0.0001,
            unrealizedPL: unrealizedPL,
            unrealizedPLPercent: 0,
            commission: 0,
            swap: 0,
            netPL: netPL,
            pipValue: 10,
            pipsProfit: 0,
            spread: 0.0002,
            spreadCost: 2,
            marginUsed: 1000,
            riskRewardRatio: nil
        )
    }
    
    private func calculatePL(for position: TrackedPosition) -> (pl: Double, pips: Double) {
        let priceChange = position.type == .buy
            ? position.currentPrice - position.openPrice
            : position.openPrice - position.currentPrice
        
        let pips = position.symbol.contains("JPY")
            ? priceChange * 100
            : priceChange * 10000
        
        let pl = priceChange * position.volume * 100000 // Standard lot size
        
        return (pl, pips)
    }
    
    private func calculatePipValue(symbol: String, volume: Double) -> Double {
        let contractSize = 100000.0
        if symbol.contains("JPY") {
            return volume * contractSize * 0.01
        } else {
            return volume * contractSize * 0.0001
        }
    }
    
    private func calculateMargin(symbol: String, volume: Double, openPrice: Double, leverage: Int) -> Double {
        let contractSize = 100000.0
        let notionalValue = volume * contractSize * openPrice
        return notionalValue / Double(leverage)
    }
    
    private func calculateRiskReward(type: TradeType, openPrice: Double, stopLoss: Double?, takeProfit: Double?) -> Double? {
        guard let sl = stopLoss, let tp = takeProfit else { return nil }
        
        let risk = abs(openPrice - sl)
        let reward = abs(tp - openPrice)
        
        guard risk > 0 else { return nil }
        return reward / risk
    }
    
    private func calculateWinRate(from positions: [TrackedPosition]) -> Double {
        guard !positions.isEmpty else { return 0 }
        let winningPositions = positions.filter { $0.netPL > 0 }
        return Double(winningPositions.count) / Double(positions.count) * 100
    }
    
    private func calculateAverageWinLoss(from positions: [TrackedPosition]) -> (averageWin: Double, averageLoss: Double, profitFactor: Double) {
        let winningPositions = positions.filter { $0.netPL > 0 }
        let losingPositions = positions.filter { $0.netPL < 0 }
        
        let averageWin = winningPositions.isEmpty ? 0 : winningPositions.reduce(0) { $0 + $1.netPL } / Double(winningPositions.count)
        let averageLoss = losingPositions.isEmpty ? 0 : abs(losingPositions.reduce(0) { $0 + $1.netPL } / Double(losingPositions.count))
        let profitFactor = averageLoss > 0 ? averageWin / averageLoss : 0
        
        return (averageWin, averageLoss, profitFactor)
    }
}

// MARK: - Mock MetaAPIWebSocketService

class MockMetaAPIWebSocketService: ObservableObject {
    @Published var positions: [PositionData] = []
    @Published var prices: [String: PriceData] = [:]
    @Published var accountInfo: AccountInformation?
    
    func simulatePositionUpdate(_ positions: [PositionData]) {
        self.positions = positions
    }
    
    func simulatePriceUpdate(symbol: String, bid: Double, ask: Double) {
        prices[symbol] = PriceData(
            symbol: symbol,
            bid: bid,
            ask: ask,
            brokerTime: Date().ISO8601Format(),
            profitTickValue: 1,
            lossTickValue: 1
        )
    }
}