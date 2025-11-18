//
//  TradeExecutionServiceTests.swift
//  PipflowTests
//
//  Unit tests for trade execution service
//

import XCTest
import Combine
@testable import Pipflow

class TradeExecutionServiceTests: XCTestCase {
    var sut: TradeExecutionService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        sut = TradeExecutionService.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        sut = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Trade Request Validation Tests
    
    func testTradeRequestValidation_ValidRequest() {
        // Given
        let request = ExecutionTradeRequest(
            symbol: "EURUSD",
            side: .buy,
            volume: 0.1,
            stopLoss: 1.0800,
            takeProfit: 1.0900,
            comment: "Test",
            magicNumber: 12345
        )
        
        // When
        let result = request.validate
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(true)
        case .failure:
            XCTFail("Valid request should not fail")
        }
    }
    
    func testTradeRequestValidation_InvalidSymbol() {
        // Given
        let request = ExecutionTradeRequest(
            symbol: "",
            side: .buy,
            volume: 0.1,
            stopLoss: nil,
            takeProfit: nil,
            comment: nil,
            magicNumber: nil
        )
        
        // When
        let result = request.validate
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with invalid symbol")
        case .failure(let error):
            XCTAssertEqual(error, .invalidSymbol)
        }
    }
    
    func testTradeRequestValidation_InvalidVolume() {
        // Given
        let request = ExecutionTradeRequest(
            symbol: "EURUSD",
            side: .buy,
            volume: 0,
            stopLoss: nil,
            takeProfit: nil,
            comment: nil,
            magicNumber: nil
        )
        
        // When
        let result = request.validate
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with invalid volume")
        case .failure(let error):
            XCTAssertEqual(error, .invalidVolume)
        }
    }
    
    func testTradeRequestValidation_InvalidStopLossBuy() {
        // Given
        let request = ExecutionTradeRequest(
            symbol: "EURUSD",
            side: .buy,
            volume: 0.1,
            stopLoss: 1.0900,  // SL above TP
            takeProfit: 1.0800,
            comment: nil,
            magicNumber: nil
        )
        
        // When
        let result = request.validate
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with invalid stop loss")
        case .failure(let error):
            XCTAssertEqual(error, .invalidStopLoss)
        }
    }
    
    func testTradeRequestValidation_InvalidStopLossSell() {
        // Given
        let request = ExecutionTradeRequest(
            symbol: "EURUSD",
            side: .sell,
            volume: 0.1,
            stopLoss: 1.0800,  // SL below TP
            takeProfit: 1.0900,
            comment: nil,
            magicNumber: nil
        )
        
        // When
        let result = request.validate
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with invalid stop loss")
        case .failure(let error):
            XCTAssertEqual(error, .invalidStopLoss)
        }
    }
    
    // MARK: - Price Calculation Tests
    
    func testCalculateStopLossBuy() {
        // Given
        let symbol = "EURUSD"
        let side = TradeSide.buy
        let pips = 50
        
        // When (assuming current price is not available in test)
        let stopLoss = sut.calculateStopLoss(for: symbol, side: side, pips: pips)
        
        // Then
        XCTAssertNil(stopLoss) // Should be nil without WebSocket price
    }
    
    func testCalculateTakeProfitBuy() {
        // Given
        let symbol = "EURUSD"
        let side = TradeSide.buy
        let pips = 100
        
        // When
        let takeProfit = sut.calculateTakeProfit(for: symbol, side: side, pips: pips)
        
        // Then
        XCTAssertNil(takeProfit) // Should be nil without WebSocket price
    }
    
    func testEstimateProfit() {
        // Given
        let symbol = "EURUSD"
        let side = TradeSide.buy
        let volume = 0.1
        let pips = 50
        
        // When
        let profit = sut.estimateProfit(for: symbol, side: side, volume: volume, pips: pips)
        
        // Then
        XCTAssertEqual(profit, 50.0) // 0.1 lot * 100000 * 50 * 0.0001
    }
    
    func testEstimateProfitJPY() {
        // Given
        let symbol = "USDJPY"
        let side = TradeSide.buy
        let volume = 0.1
        let pips = 50
        
        // When
        let profit = sut.estimateProfit(for: symbol, side: side, volume: volume, pips: pips)
        
        // Then
        XCTAssertEqual(profit, 500.0) // 0.1 lot * 100000 * 50 * 0.01
    }
    
    // MARK: - Execution State Tests
    
    func testInitialExecutionState() {
        XCTAssertFalse(sut.isExecuting)
        XCTAssertNil(sut.lastExecutionResult)
        XCTAssertNil(sut.executionError)
        XCTAssertTrue(sut.pendingOrders.isEmpty)
    }
    
    // MARK: - Trade Execution Tests
    
    func testExecuteTradeNotConnected() async throws {
        // Given
        let metaAPIService = MetaAPIService.shared
        metaAPIService.isConnected = false
        
        let request = ExecutionTradeRequest(
            symbol: "EURUSD",
            side: .buy,
            volume: 0.1,
            stopLoss: nil,
            takeProfit: nil,
            comment: nil,
            magicNumber: nil
        )
        
        // When & Then
        do {
            _ = try await sut.executeTrade(request)
            XCTFail("Should throw not connected error")
        } catch TradingError.notConnected {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testQuickBuy() async throws {
        // Given
        let symbol = "EURUSD"
        let volume = 0.1
        let metaAPIService = MetaAPIService.shared
        metaAPIService.isConnected = false // Force error
        
        // When & Then
        do {
            _ = try await sut.quickBuy(symbol: symbol, volume: volume)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testQuickSell() async throws {
        // Given
        let symbol = "EURUSD"
        let volume = 0.1
        let metaAPIService = MetaAPIService.shared
        metaAPIService.isConnected = false // Force error
        
        // When & Then
        do {
            _ = try await sut.quickSell(symbol: symbol, volume: volume)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Position Management Tests
    
    func testClosePositionNotConnected() async throws {
        // Given
        let metaAPIService = MetaAPIService.shared
        metaAPIService.isConnected = false
        
        // When & Then
        do {
            try await sut.closePosition("position-id")
            XCTFail("Should throw not connected error")
        } catch TradingError.notConnected {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testModifyPositionNotConnected() async throws {
        // Given
        let metaAPIService = MetaAPIService.shared
        metaAPIService.isConnected = false
        
        // When & Then
        do {
            try await sut.modifyPosition("position-id", stopLoss: 1.0800, takeProfit: 1.0900)
            XCTFail("Should throw not connected error")
        } catch TradingError.notConnected {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Error Description Tests
    
    func testTradeValidationErrorDescriptions() {
        XCTAssertEqual(TradeValidationError.invalidSymbol.errorDescription, "Invalid trading symbol")
        XCTAssertEqual(TradeValidationError.invalidVolume.errorDescription, "Invalid trade volume")
        XCTAssertEqual(TradeValidationError.invalidStopLoss.errorDescription, "Stop loss must be below take profit for buy orders")
        XCTAssertEqual(TradeValidationError.invalidTakeProfit.errorDescription, "Take profit must be above stop loss for buy orders")
        XCTAssertEqual(TradeValidationError.insufficientMargin.errorDescription, "Insufficient margin for this trade")
        XCTAssertEqual(TradeValidationError.marketClosed.errorDescription, "Market is closed for this symbol")
    }
    
    // MARK: - Execution Flow Tests
    
    func testExecutionStateChanges() async {
        // Given
        let expectation = XCTestExpectation(description: "Execution state changes")
        var stateChanges: [Bool] = []
        
        sut.$isExecuting
            .sink { isExecuting in
                stateChanges.append(isExecuting)
                if stateChanges.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        let request = ExecutionTradeRequest(
            symbol: "EURUSD",
            side: .buy,
            volume: 0.1,
            stopLoss: nil,
            takeProfit: nil,
            comment: nil,
            magicNumber: nil
        )
        
        Task {
            do {
                _ = try await sut.executeTrade(request)
            } catch {
                // Expected to fail
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(stateChanges.contains(true))
        XCTAssertTrue(stateChanges.contains(false))
    }
}