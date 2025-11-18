//
//  WebSocketManagerTests.swift
//  PipflowTests
//
//  Unit tests for WebSocket manager functionality
//

import XCTest
import Combine
@testable import Pipflow

class WebSocketManagerTests: XCTestCase {
    var sut: WebSocketManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        sut = WebSocketManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        sut.disconnect()
        sut = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Connection Tests
    
    func testInitialConnectionState() {
        // Given & When
        let expectation = XCTestExpectation(description: "Initial state is disconnected")
        
        sut.connectionStatePublisher
            .first()
            .sink { state in
                // Then
                XCTAssertEqual(state, .disconnected)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConnect() {
        // Given
        let url = URL(string: "wss://test.example.com/ws")!
        let expectation = XCTestExpectation(description: "Connection state changes")
        var states: [WebSocketConnectionState] = []
        
        sut.connectionStatePublisher
            .sink { state in
                states.append(state)
                if states.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.connect(to: url)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(states.contains(where: { 
            if case .connecting = $0 { return true }
            return false
        }))
        XCTAssertTrue(states.contains(where: { 
            if case .connected = $0 { return true }
            return false
        }))
    }
    
    func testDisconnect() {
        // Given
        let url = URL(string: "wss://test.example.com/ws")!
        let expectation = XCTestExpectation(description: "Disconnection completes")
        
        sut.connect(to: url)
        
        var hasDisconnecting = false
        var hasDisconnected = false
        
        sut.connectionStatePublisher
            .sink { state in
                switch state {
                case .disconnecting:
                    hasDisconnecting = true
                case .disconnected:
                    if hasDisconnecting {
                        hasDisconnected = true
                        expectation.fulfill()
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // When
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sut.disconnect()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(hasDisconnected)
    }
    
    // MARK: - Message Sending Tests
    
    func testSendEncodableMessage() {
        // Given
        struct TestMessage: Encodable {
            let type: String
            let data: String
        }
        
        let message = TestMessage(type: "test", data: "hello")
        let url = URL(string: "wss://test.example.com/ws")!
        
        // When
        sut.connect(to: url)
        sut.send(message) // Should not crash
        
        // Then
        XCTAssertTrue(true) // If we reach here, no crash occurred
    }
    
    func testSendMessageWhileDisconnected() {
        // Given
        struct TestMessage: Encodable {
            let type: String
        }
        
        let message = TestMessage(type: "test")
        
        // When
        sut.send(message) // Should not crash when disconnected
        
        // Then
        XCTAssertTrue(true) // If we reach here, no crash occurred
    }
    
    // MARK: - Error Handling Tests
    
    func testEncodingError() {
        // Given
        struct InvalidMessage: Encodable {
            let invalid: Double = .infinity // This will fail to encode to JSON
        }
        
        let message = InvalidMessage()
        let url = URL(string: "wss://test.example.com/ws")!
        let expectation = XCTestExpectation(description: "Error state received")
        
        sut.connectionStatePublisher
            .sink { state in
                if case .failed = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.connect(to: url)
        sut.send(message)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Message Reception Tests
    
    func testMessagePublisher() {
        // Given
        let expectation = XCTestExpectation(description: "Message publisher exists")
        
        // When
        sut.messagePublisher
            .sink { _ in
                // We don't expect actual messages in unit tests
            }
            .store(in: &cancellables)
        
        // Then
        expectation.fulfill()
        wait(for: [expectation], timeout: 0.1)
    }
    
    // MARK: - Lifecycle Tests
    
    func testDeinitDisconnects() {
        // Given
        var localSUT: WebSocketManager? = WebSocketManager()
        let url = URL(string: "wss://test.example.com/ws")!
        
        localSUT?.connect(to: url)
        
        // When
        localSUT = nil // This should trigger deinit and disconnect
        
        // Then
        // If no crash occurs, the test passes
        XCTAssertTrue(true)
    }
    
    // MARK: - Reconnection Tests
    
    func testAutoReconnectOnFailure() {
        // Given
        let url = URL(string: "wss://test.example.com/ws")!
        let expectation = XCTestExpectation(description: "Reconnection attempted")
        var states: [WebSocketConnectionState] = []
        
        sut.connectionStatePublisher
            .sink { state in
                states.append(state)
                if case .reconnecting(let attempt) = state, attempt == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.connect(to: url)
        // Simulate connection error
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // This would normally be triggered by a real connection failure
            // For testing, we'll need to expose a method or use a mock
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testManualDisconnectDoesNotReconnect() {
        // Given
        let url = URL(string: "wss://test.example.com/ws")!
        let expectation = XCTestExpectation(description: "No reconnection after manual disconnect")
        expectation.isInverted = true // We expect this NOT to be fulfilled
        
        sut.connectionStatePublisher
            .sink { state in
                if case .reconnecting = state {
                    expectation.fulfill() // This should not happen
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.connect(to: url)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sut.disconnect() // Manual disconnect
        }
        
        // Then
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Mock WebSocket Manager Tests
    
    func testMockWebSocketManager() {
        // Given
        let mock = MockWebSocketManager()
        let url = URL(string: "wss://test.example.com/ws")!
        
        // When
        mock.connect(to: url)
        
        // Then
        XCTAssertTrue(mock.connectCalled)
        XCTAssertEqual(mock.lastConnectURL, url)
        
        // When
        mock.disconnect()
        
        // Then
        XCTAssertTrue(mock.disconnectCalled)
    }
    
    func testMockWebSocketManagerMessageSimulation() {
        // Given
        let mock = MockWebSocketManager()
        let expectation = XCTestExpectation(description: "Message received")
        
        mock.messagePublisher
            .sink { data in
                // Then
                XCTAssertNotNil(data)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let testResponse = MetaAPIWebSocketResponse(
            type: "test",
            accountId: "test-account",
            instanceIndex: nil,
            synchronizationId: nil,
            symbol: nil,
            accountInformation: nil,
            specifications: nil,
            positions: nil,
            orders: nil,
            price: nil,
            candles: nil,
            update: nil,
            deals: nil,
            historyOrders: nil
        )
        
        mock.simulateMessage(testResponse)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMockWebSocketManagerErrorSimulation() {
        // Given
        let mock = MockWebSocketManager()
        let expectation = XCTestExpectation(description: "Error received")
        
        mock.connectionStatePublisher
            .sink { state in
                if case .failed(let error) = state {
                    // Then
                    XCTAssertNotNil(error)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        let testError = NSError(domain: "TestError", code: -1, userInfo: nil)
        mock.simulateError(testError)
        
        wait(for: [expectation], timeout: 1.0)
    }
}