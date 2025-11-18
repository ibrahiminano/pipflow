//
//  TradingServiceIntegrationTests.swift
//  PipflowTests
//
//  Integration tests for TradingService with WebSocket and MetaAPI
//

import XCTest
import Combine
@testable import Pipflow

class TradingServiceIntegrationTests: XCTestCase {
    var sut: TradingService!
    var mockMetaAPIService: MockMetaAPIService!
    var mockWebSocketService: MockMetaAPIWebSocketService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockMetaAPIService = MockMetaAPIService()
        mockWebSocketService = MockMetaAPIWebSocketService()
        cancellables = Set<AnyCancellable>()
        // Note: TradingService is a singleton
        sut = TradingService.shared
    }
    
    override func tearDown() {
        cancellables = nil
        mockWebSocketService = nil
        mockMetaAPIService = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testConnectAccountIntegration() async throws {
        // Given
        let credentials = MetaAPICredentials(
            accountId: "test-account-123",
            accountToken: "test-token",
            accountType: "demo",
            brokerName: "Test Broker",
            serverName: "Test-Demo",
            serverType: "mt5"
        )
        
        let expectation = XCTestExpectation(description: "Account connected")
        
        sut.$connectionStatus
            .sink { status in
                if case .connected = status {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        try await sut.connectAccount(credentials: credentials)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(sut.activeAccount)
        XCTAssertEqual(sut.activeAccount?.accountId, credentials.accountId)
        XCTAssertEqual(sut.connectedAccounts.count, 1)
    }
    
    func testDisconnectAccountIntegration() {
        // Given
        let account = TradingAccount(
            id: "test-id",
            accountId: "test-account-123",
            accountType: .demo,
            brokerName: "Test Broker",
            serverName: "Test-Demo",
            platformType: .mt5,
            balance: 10000,
            equity: 10000,
            currency: "USD",
            leverage: 100,
            isActive: true,
            connectedDate: Date()
        )
        
        // Manually add account for testing
        sut.connectedAccounts.append(account)
        sut.activeAccount = account
        sut.connectionStatus = .connected
        
        // When
        sut.disconnectAccount(account)
        
        // Then
        XCTAssertTrue(sut.connectedAccounts.isEmpty)
        XCTAssertNil(sut.activeAccount)
        XCTAssertEqual(sut.connectionStatus, .disconnected)
    }
    
    // MARK: - Real-time Data Tests
    
    func testWebSocketPositionUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "Positions updated")
        
        sut.$openPositions
            .dropFirst()
            .sink { positions in
                XCTAssertEqual(positions.count, 2)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When - Simulate WebSocket position update
        let positions = [
            PositionData(
                id: "pos1",
                type: "POSITION_TYPE_BUY",
                symbol: "EURUSD",
                magic: nil,
                time: "2025-07-19T12:00:00.000Z",
                brokerTime: nil,
                openPrice: 1.0850,
                volume: 1.0,
                swap: 0,
                commission: -5,
                profit: 250,
                currentPrice: 1.0875,
                currentTickValue: 1,
                stopLoss: 1.0800,
                takeProfit: 1.0900,
                comment: nil
            ),
            PositionData(
                id: "pos2",
                type: "POSITION_TYPE_SELL",
                symbol: "GBPUSD",
                magic: nil,
                time: "2025-07-19T13:00:00.000Z",
                brokerTime: nil,
                openPrice: 1.2650,
                volume: 0.5,
                swap: 0,
                commission: -2.5,
                profit: -125,
                currentPrice: 1.2675,
                currentTickValue: 1,
                stopLoss: 1.2700,
                takeProfit: 1.2600,
                comment: nil
            )
        ]
        
        mockWebSocketService.simulatePositionUpdate(positions)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testWebSocketAccountInfoUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "Account info updated")
        
        var updateCount = 0
        sut.$accountBalance
            .sink { balance in
                if balance > 0 {
                    updateCount += 1
                    if updateCount >= 2 { // Initial + update
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)
        
        // When - Simulate WebSocket account update
        mockWebSocketService.accountInfo = AccountInformation(
            broker: "Test Broker",
            currency: "USD",
            server: "Test-Server",
            balance: 50000,
            equity: 52000,
            margin: 1000,
            freeMargin: 51000,
            leverage: 100,
            marginLevel: 5200,
            tradeAllowed: true
        )
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(sut.accountBalance, 50000)
        XCTAssertEqual(sut.accountEquity, 52000)
    }
    
    // MARK: - Trading Operations Tests
    
    func testOpenPositionIntegration() async throws {
        // Given
        sut.connectionStatus = .connected
        
        // When
        try await sut.openPosition(
            symbol: "EURUSD",
            side: .buy,
            volume: 1.0,
            stopLoss: 1.0800,
            takeProfit: 1.0900
        )
        
        // Then
        // Verify that MetaAPIService was called correctly
        XCTAssertTrue(mockMetaAPIService.openPositionCalled)
    }
    
    func testClosePositionIntegration() async throws {
        // Given
        sut.connectionStatus = .connected
        let position = TrackedPosition(
            id: "pos1",
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
            swap: 0,
            netPL: 245,
            pipValue: 10,
            pipsProfit: 25,
            spread: 0.0002,
            spreadCost: 2,
            marginUsed: 1085,
            riskRewardRatio: 1.0
        )
        
        // When
        try await sut.closePosition(position)
        
        // Then
        XCTAssertTrue(mockMetaAPIService.closePositionCalled)
    }
    
    func testModifyPositionIntegration() async throws {
        // Given
        sut.connectionStatus = .connected
        let position = TrackedPosition(
            id: "pos1",
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
            swap: 0,
            netPL: 245,
            pipValue: 10,
            pipsProfit: 25,
            spread: 0.0002,
            spreadCost: 2,
            marginUsed: 1085,
            riskRewardRatio: 1.0
        )
        
        // When
        try await sut.modifyPosition(position, stopLoss: 1.0825, takeProfit: 1.0925)
        
        // Then
        XCTAssertTrue(mockMetaAPIService.modifyPositionCalled)
    }
    
    // MARK: - Error Handling Tests
    
    func testOpenPositionWhenDisconnected() async {
        // Given
        sut.connectionStatus = .disconnected
        
        // When/Then
        do {
            try await sut.openPosition(
                symbol: "EURUSD",
                side: .buy,
                volume: 1.0
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TradingError, .notConnected)
        }
    }
    
    func testSwitchAccountReconnection() async {
        // Given
        let account1 = TradingAccount(
            id: "account1",
            accountId: "acc1",
            accountType: .demo,
            brokerName: "Broker1",
            serverName: "Server1",
            platformType: .mt5,
            balance: 10000,
            equity: 10000,
            currency: "USD",
            leverage: 100,
            isActive: true,
            connectedDate: Date()
        )
        
        let account2 = TradingAccount(
            id: "account2",
            accountId: "acc2",
            accountType: .demo,
            brokerName: "Broker2",
            serverName: "Server2",
            platformType: .mt5,
            balance: 20000,
            equity: 20000,
            currency: "USD",
            leverage: 200,
            isActive: true,
            connectedDate: Date()
        )
        
        sut.connectedAccounts = [account1, account2]
        sut.activeAccount = account1
        
        // When
        await sut.switchAccount(account2)
        
        // Then
        XCTAssertEqual(sut.activeAccount?.id, account2.id)
    }
}

// MARK: - Extended Mock MetaAPIService

extension MockMetaAPIService {
    var openPositionCalled: Bool { false } // Would need to be implemented in actual mock
    var closePositionCalled: Bool { false }
    var modifyPositionCalled: Bool { false }
}