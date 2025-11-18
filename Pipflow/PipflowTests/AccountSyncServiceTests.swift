//
//  AccountSyncServiceTests.swift
//  PipflowTests
//
//  Unit tests for account synchronization service
//

import XCTest
import Combine
@testable import Pipflow

class AccountSyncServiceTests: XCTestCase {
    var sut: AccountSyncService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        // Note: AccountSyncService is a singleton
        sut = AccountSyncService.shared
        sut.resetSyncData()
    }
    
    override func tearDown() {
        sut.stopAutoSync()
        sut.resetSyncData()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialSyncStatus() {
        XCTAssertEqual(sut.syncStatus, .idle)
        XCTAssertNil(sut.lastSyncDate)
        XCTAssertEqual(sut.syncProgress, 0.0)
    }
    
    func testDefaultSyncSettings() {
        let settings = sut.syncSettings
        XCTAssertTrue(settings.isAutoSyncEnabled)
        XCTAssertEqual(settings.syncInterval, 30)
        XCTAssertTrue(settings.syncOnAppLaunch)
        XCTAssertTrue(settings.syncOnAccountSwitch)
        XCTAssertFalse(settings.syncPositionsOnly)
    }
    
    // MARK: - Sync Status Tests
    
    func testSyncStatusActive() {
        // Test idle state
        sut.syncStatus = .idle
        XCTAssertFalse(sut.syncStatus.isActive)
        
        // Test syncing state
        sut.syncStatus = .syncing
        XCTAssertTrue(sut.syncStatus.isActive)
        
        // Test completed state
        sut.syncStatus = .completed(Date())
        XCTAssertFalse(sut.syncStatus.isActive)
        
        // Test failed state
        sut.syncStatus = .failed(NSError(domain: "test", code: -1))
        XCTAssertFalse(sut.syncStatus.isActive)
    }
    
    // MARK: - Settings Management Tests
    
    func testUpdateSyncSettings() {
        // Given
        var newSettings = AccountSyncSettings()
        newSettings.isAutoSyncEnabled = false
        newSettings.syncInterval = 60
        newSettings.syncOnAppLaunch = false
        newSettings.syncPositionsOnly = true
        
        // When
        sut.updateSyncSettings(newSettings)
        
        // Then
        XCTAssertFalse(sut.syncSettings.isAutoSyncEnabled)
        XCTAssertEqual(sut.syncSettings.syncInterval, 60)
        XCTAssertFalse(sut.syncSettings.syncOnAppLaunch)
        XCTAssertTrue(sut.syncSettings.syncPositionsOnly)
    }
    
    // MARK: - Time Since Last Sync Tests
    
    func testTimeSinceLastSyncJustNow() {
        // Given
        sut.lastSyncDate = Date()
        
        // When
        let timeSince = sut.timeSinceLastSync
        
        // Then
        XCTAssertEqual(timeSince, "Just now")
    }
    
    func testTimeSinceLastSyncMinutes() {
        // Given
        sut.lastSyncDate = Date().addingTimeInterval(-90) // 1.5 minutes ago
        
        // When
        let timeSince = sut.timeSinceLastSync
        
        // Then
        XCTAssertEqual(timeSince, "1 minute ago")
    }
    
    func testTimeSinceLastSyncHours() {
        // Given
        sut.lastSyncDate = Date().addingTimeInterval(-7200) // 2 hours ago
        
        // When
        let timeSince = sut.timeSinceLastSync
        
        // Then
        XCTAssertEqual(timeSince, "2 hours ago")
    }
    
    func testTimeSinceLastSyncDays() {
        // Given
        sut.lastSyncDate = Date().addingTimeInterval(-86400) // 1 day ago
        
        // When
        let timeSince = sut.timeSinceLastSync
        
        // Then
        XCTAssertEqual(timeSince, "1 day ago")
    }
    
    func testTimeSinceLastSyncNil() {
        // Given
        sut.lastSyncDate = nil
        
        // When
        let timeSince = sut.timeSinceLastSync
        
        // Then
        XCTAssertNil(timeSince)
    }
    
    // MARK: - Should Auto Sync Tests
    
    func testShouldAutoSyncWhenEnabled() {
        // Given
        sut.syncSettings.isAutoSyncEnabled = true
        sut.lastSyncDate = Date().addingTimeInterval(-60) // 1 minute ago
        sut.syncSettings.syncInterval = 30 // 30 seconds
        
        // When
        let shouldSync = sut.shouldAutoSync
        
        // Then
        XCTAssertTrue(shouldSync)
    }
    
    func testShouldNotAutoSyncWhenDisabled() {
        // Given
        sut.syncSettings.isAutoSyncEnabled = false
        
        // When
        let shouldSync = sut.shouldAutoSync
        
        // Then
        XCTAssertFalse(shouldSync)
    }
    
    func testShouldNotAutoSyncWhenRecentlySync() {
        // Given
        sut.syncSettings.isAutoSyncEnabled = true
        sut.lastSyncDate = Date() // Just now
        sut.syncSettings.syncInterval = 30
        
        // When
        let shouldSync = sut.shouldAutoSync
        
        // Then
        XCTAssertFalse(shouldSync)
    }
    
    // MARK: - Sync Account Tests
    
    func testSyncAccountWhenNotConnected() async {
        // Given
        let metaAPIService = MetaAPIService.shared
        metaAPIService.accountId = nil // Not connected
        
        // When
        await sut.syncAccount()
        
        // Then
        if case .failed(let error) = sut.syncStatus {
            XCTAssertTrue(error is TradingError)
        } else {
            XCTFail("Expected failed status")
        }
    }
    
    func testSyncProgressUpdates() async {
        // Given
        let expectation = XCTestExpectation(description: "Progress updates")
        var progressValues: [Double] = []
        
        sut.$syncProgress
            .dropFirst()
            .sink { progress in
                progressValues.append(progress)
                if progress >= 1.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await sut.syncAccount()
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(progressValues.contains(where: { $0 > 0 && $0 < 1 }))
    }
    
    // MARK: - Auto Sync Tests
    
    func testStartAutoSync() {
        // Given
        sut.syncSettings.isAutoSyncEnabled = true
        sut.syncSettings.syncInterval = 1 // 1 second for testing
        
        let expectation = XCTestExpectation(description: "Auto sync triggered")
        
        sut.$syncStatus
            .dropFirst()
            .sink { status in
                if case .syncing = status {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.startAutoSync()
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testStopAutoSync() {
        // Given
        sut.startAutoSync()
        
        // When
        sut.stopAutoSync()
        
        // Then
        // Verify timer is stopped (no crash)
        XCTAssertTrue(true)
    }
    
    // MARK: - Reset Data Tests
    
    func testResetSyncData() {
        // Given
        sut.lastSyncDate = Date()
        sut.syncStatus = .completed(Date())
        sut.syncProgress = 1.0
        
        // When
        sut.resetSyncData()
        
        // Then
        XCTAssertNil(sut.lastSyncDate)
        XCTAssertEqual(sut.syncStatus, .idle)
        XCTAssertEqual(sut.syncProgress, 0.0)
    }
    
    // MARK: - Concurrent Sync Prevention
    
    func testPreventConcurrentSync() async {
        // Given
        sut.syncStatus = .syncing
        
        // When
        await sut.syncAccount()
        
        // Then
        // Should not crash and should still be syncing
        if case .syncing = sut.syncStatus {
            XCTAssertTrue(true)
        } else {
            XCTFail("Status should remain syncing")
        }
    }
}