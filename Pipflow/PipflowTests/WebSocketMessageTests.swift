//
//  WebSocketMessageTests.swift
//  PipflowTests
//
//  Unit tests for WebSocket message parsing and handling
//

import XCTest
@testable import Pipflow

class WebSocketMessageTests: XCTestCase {
    var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
    }
    
    override func tearDown() {
        decoder = nil
        super.tearDown()
    }
    
    // MARK: - Message Encoding Tests
    
    func testSubscribeMessageEncoding() throws {
        // Given
        let message = MetaAPISubscribeMessage(accountId: "test-account")
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Then
        XCTAssertEqual(json?["type"] as? String, "subscribe")
        XCTAssertEqual(json?["accountId"] as? String, "test-account")
        XCTAssertEqual(json?["application"] as? String, "Pipflow")
        XCTAssertEqual(json?["instanceIndex"] as? Int, 0)
    }
    
    func testSynchronizeMessageEncoding() throws {
        // Given
        let syncId = UUID().uuidString
        let message = MetaAPISynchronizeMessage(
            accountId: "test-account",
            synchronizationId: syncId,
            host: "pipflow.ios.app"
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Then
        XCTAssertEqual(json?["type"] as? String, "synchronize")
        XCTAssertEqual(json?["accountId"] as? String, "test-account")
        XCTAssertEqual(json?["synchronizationId"] as? String, syncId)
        XCTAssertEqual(json?["keepAlive"] as? Bool, true)
    }
    
    // MARK: - Response Parsing Tests
    
    func testAccountInformationParsing() throws {
        // Given
        let json = """
        {
            "type": "accountInformation",
            "accountId": "test-account",
            "accountInformation": {
                "broker": "ICMarkets",
                "currency": "USD",
                "server": "ICMarkets-Demo",
                "balance": 50000,
                "equity": 52000,
                "margin": 1000,
                "freeMargin": 51000,
                "leverage": 100,
                "marginLevel": 5200,
                "tradeAllowed": true
            }
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(MetaAPIWebSocketResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.type, "accountInformation")
        XCTAssertNotNil(response.accountInformation)
        XCTAssertEqual(response.accountInformation?.balance, 50000)
        XCTAssertEqual(response.accountInformation?.equity, 52000)
        XCTAssertEqual(response.accountInformation?.leverage, 100)
    }
    
    func testPositionsParsing() throws {
        // Given
        let json = """
        {
            "type": "positions",
            "accountId": "test-account",
            "positions": [
                {
                    "id": "1",
                    "type": "POSITION_TYPE_BUY",
                    "symbol": "EURUSD",
                    "time": "2025-07-19T12:00:00.000Z",
                    "openPrice": 1.0850,
                    "volume": 0.1,
                    "swap": 0,
                    "commission": -5,
                    "profit": 250,
                    "currentPrice": 1.0875,
                    "currentTickValue": 1,
                    "stopLoss": 1.0800,
                    "takeProfit": 1.0900
                }
            ]
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(MetaAPIWebSocketResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.type, "positions")
        XCTAssertNotNil(response.positions)
        XCTAssertEqual(response.positions?.count, 1)
        XCTAssertEqual(response.positions?.first?.symbol, "EURUSD")
        XCTAssertEqual(response.positions?.first?.profit, 250)
    }
    
    func testPriceDataParsing() throws {
        // Given
        let json = """
        {
            "type": "prices",
            "accountId": "test-account",
            "symbol": "EURUSD",
            "price": {
                "symbol": "EURUSD",
                "bid": 1.0874,
                "ask": 1.0876,
                "brokerTime": "2025-07-19T15:30:00.000Z",
                "profitTickValue": 1,
                "lossTickValue": 1
            }
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(MetaAPIWebSocketResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.type, "prices")
        XCTAssertEqual(response.symbol, "EURUSD")
        XCTAssertNotNil(response.price)
        XCTAssertEqual(response.price?.bid, 1.0874)
        XCTAssertEqual(response.price?.ask, 1.0876)
    }
    
    func testOrdersParsing() throws {
        // Given
        let json = """
        {
            "type": "orders",
            "accountId": "test-account",
            "orders": [
                {
                    "id": "1",
                    "type": "ORDER_TYPE_BUY_LIMIT",
                    "state": "ORDER_STATE_PLACED",
                    "symbol": "GBPUSD",
                    "time": "2025-07-19T13:00:00.000Z",
                    "openPrice": 1.2650,
                    "volume": 0.05,
                    "stopLoss": 1.2600,
                    "takeProfit": 1.2700
                }
            ]
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(MetaAPIWebSocketResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.type, "orders")
        XCTAssertNotNil(response.orders)
        XCTAssertEqual(response.orders?.count, 1)
        XCTAssertEqual(response.orders?.first?.symbol, "GBPUSD")
        XCTAssertEqual(response.orders?.first?.state, "ORDER_STATE_PLACED")
    }
    
    func testPositionUpdateParsing() throws {
        // Given
        let json = """
        {
            "type": "update",
            "accountId": "test-account",
            "update": [
                {
                    "id": "1",
                    "profit": 300,
                    "currentPrice": 1.0880,
                    "currentTickValue": 1,
                    "equity": 52300,
                    "margin": 1000,
                    "freeMargin": 51300,
                    "marginLevel": 5230
                }
            ]
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(MetaAPIWebSocketResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.type, "update")
        XCTAssertNotNil(response.update)
        XCTAssertEqual(response.update?.first?.profit, 300)
        XCTAssertEqual(response.update?.first?.equity, 52300)
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyPositionsArray() throws {
        // Given
        let json = """
        {
            "type": "positions",
            "accountId": "test-account",
            "positions": []
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(MetaAPIWebSocketResponse.self, from: data)
        
        // Then
        XCTAssertEqual(response.positions?.count, 0)
    }
    
    func testNullMarginLevel() throws {
        // Given
        let json = """
        {
            "type": "accountInformation",
            "accountId": "test-account",
            "accountInformation": {
                "currency": "USD",
                "server": "Test",
                "balance": 1000,
                "equity": 1000,
                "margin": 0,
                "freeMargin": 1000,
                "leverage": 100,
                "marginLevel": null,
                "tradeAllowed": true
            }
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let response = try decoder.decode(MetaAPIWebSocketResponse.self, from: data)
        
        // Then
        XCTAssertNil(response.accountInformation?.marginLevel)
    }
    
    func testSynchronizationMessages() throws {
        // Given
        let startJson = """
        {
            "type": "synchronizationStarted",
            "accountId": "test-account",
            "instanceIndex": 0,
            "synchronizationId": "sync-123"
        }
        """
        
        let endJson = """
        {
            "type": "synchronized",
            "accountId": "test-account",
            "instanceIndex": 0,
            "synchronizationId": "sync-123"
        }
        """
        
        // When
        let startData = startJson.data(using: .utf8)!
        let startResponse = try decoder.decode(MetaAPIWebSocketResponse.self, from: startData)
        
        let endData = endJson.data(using: .utf8)!
        let endResponse = try decoder.decode(MetaAPIWebSocketResponse.self, from: endData)
        
        // Then
        XCTAssertEqual(startResponse.type, "synchronizationStarted")
        XCTAssertEqual(endResponse.type, "synchronized")
        XCTAssertEqual(startResponse.synchronizationId, "sync-123")
        XCTAssertEqual(endResponse.synchronizationId, "sync-123")
    }
}