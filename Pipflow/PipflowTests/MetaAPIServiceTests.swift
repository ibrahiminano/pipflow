//
//  MetaAPIServiceTests.swift
//  PipflowTests
//
//  Unit tests for MetaAPI service integration
//

import XCTest
import Combine
@testable import Pipflow

class MetaAPIServiceTests: XCTestCase {
    var sut: MetaAPIService!
    var mockAPIClient: MockAPIClient!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        // Note: MetaAPIService is a singleton, so we need to test through its interface
        sut = MetaAPIService.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Link Account Tests
    
    func testLinkAccountSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Link account completes")
        let login = "12345"
        let password = "password"
        let server = "ICMarkets-Demo"
        let platform = TradingPlatform.mt5
        
        // When
        sut.linkAccount(login: login, password: password, server: server, platform: platform)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail")
                    }
                },
                receiveValue: { account in
                    // Then
                    XCTAssertNotNil(account)
                    XCTAssertEqual(account.serverName, server)
                    XCTAssertEqual(account.platformType, platform)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testLinkAccountFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Link account fails")
        let login = ""  // Invalid login
        let password = "password"
        let server = "ICMarkets-Demo"
        let platform = TradingPlatform.mt5
        
        // When
        sut.linkAccount(login: login, password: password, server: server, platform: platform)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        // Then
                        XCTAssertNotNil(error)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Should not receive value")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Get Positions Tests
    
    func testGetPositionsSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Get positions completes")
        let accountId = "test-account-id"
        sut.setAuthToken("test-token")
        
        // When
        sut.getPositions(accountId: accountId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail")
                    }
                },
                receiveValue: { trades in
                    // Then
                    XCTAssertNotNil(trades)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Place Order Tests
    
    func testPlaceOrderSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Place order completes")
        let accountId = "test-account-id"
        let order = MetaAPIOrderRequest(
            symbol: "EURUSD",
            actionType: "ORDER_TYPE_BUY",
            volume: 0.1,
            stopLoss: 1.0800,
            takeProfit: 1.0900,
            comment: "Test order"
        )
        sut.setAuthToken("test-token")
        
        // When
        sut.placeOrder(accountId: accountId, order: order)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail")
                    }
                },
                receiveValue: { trade in
                    // Then
                    XCTAssertNotNil(trade)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - WebSocket Integration Tests
    
    func testWebSocketConnection() {
        // Given
        let expectation = XCTestExpectation(description: "WebSocket connects")
        sut.setAuthToken("test-token")
        
        // Monitor connection state
        sut.$isWebSocketConnected
            .dropFirst()
            .sink { isConnected in
                if isConnected {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.startWebSocketConnection(accountId: "test-account", authToken: "test-token")
        
        // Then - Wait for connection (this would be mocked in real tests)
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Account Info Tests
    
    func testFetchAccountInfo() async throws {
        // Given
        sut.setAuthToken("test-token")
        sut.accountId = "test-account"
        
        // When
        try await sut.fetchAccountInfo()
        
        // Then
        XCTAssertNotNil(sut.accountInfo)
        XCTAssertEqual(sut.accountInfo?.balance, 10000.0)
    }
    
    // MARK: - Position Management Tests
    
    func testOpenPosition() async throws {
        // Given
        sut.setAuthToken("test-token")
        sut.accountId = "test-account"
        
        // When & Then - Should not throw
        try await sut.openPosition(
            symbol: "EURUSD",
            side: .buy,
            volume: 0.1,
            stopLoss: 1.0800,
            takeProfit: 1.0900
        )
    }
    
    func testClosePosition() async throws {
        // Given
        sut.setAuthToken("test-token")
        sut.accountId = "test-account"
        
        // When & Then - Should not throw
        try await sut.closePosition(positionId: "test-position-id")
    }
    
    func testModifyPosition() async throws {
        // Given
        sut.setAuthToken("test-token")
        sut.accountId = "test-account"
        
        // When & Then - Should not throw
        try await sut.modifyPosition(
            positionId: "test-position-id",
            stopLoss: 1.0750,
            takeProfit: 1.0950
        )
    }
    
    // MARK: - Real-time Data Tests
    
    func testSubscribeToRealTimeData() {
        // Given
        let symbols = ["EURUSD", "GBPUSD", "USDJPY"]
        
        // When
        sut.subscribeToRealTimeData(symbols: symbols)
        
        // Then - Should not crash
        XCTAssertTrue(true)
    }
    
    func testGetCurrentPrice() {
        // Given
        let symbol = "EURUSD"
        
        // When
        let price = sut.getCurrentPrice(for: symbol)
        
        // Then
        XCTAssertNil(price) // Should be nil before WebSocket connection
    }
    
    // MARK: - Candles Tests
    
    func testGetCandlesSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Get candles completes")
        let accountId = "test-account-id"
        let symbol = "EURUSD"
        let timeframe = "1h"
        let startTime = Date().addingTimeInterval(-86400) // 1 day ago
        let limit = 100
        sut.setAuthToken("test-token")
        
        // When
        sut.getCandles(accountId: accountId, symbol: symbol, timeframe: timeframe, startTime: startTime, limit: limit)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Should not fail")
                    }
                },
                receiveValue: { candles in
                    // Then
                    XCTAssertNotNil(candles)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testNotConnectedError() async {
        // Given
        sut.accountId = nil // No account connected
        
        // When & Then
        do {
            try await sut.openPosition(symbol: "EURUSD", side: .buy, volume: 0.1, stopLoss: nil, takeProfit: nil)
            XCTFail("Should throw error")
        } catch TradingError.notConnected {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}