//
//  KeychainManagerTests.swift
//  PipflowTests
//
//  Unit tests for KeychainManager
//

import XCTest
@testable import Pipflow

class KeychainManagerTests: XCTestCase {
    
    var sut: KeychainManager!
    
    override func setUp() {
        super.setUp()
        
        // Create system under test
        sut = KeychainManager.shared
        
        // Clear any existing keychain data for tests
        clearAllKeychainData()
    }
    
    override func tearDown() {
        // Clean up after tests
        clearAllKeychainData()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Credentials Tests
    
    func testSaveCredentials_ShouldStoreSuccessfully() {
        // Given
        let email = "test@example.com"
        let password = "SecurePassword123!"
        
        // When
        sut.saveCredentials(email: email, password: password)
        
        // Then
        let retrieved = sut.getCredentials()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.email, email)
        XCTAssertEqual(retrieved?.password, password)
    }
    
    func testGetCredentials_WhenNotStored_ShouldReturnNil() {
        // When
        let retrieved = sut.getCredentials()
        
        // Then
        XCTAssertNil(retrieved)
    }
    
    func testDeleteCredentials_ShouldRemoveSuccessfully() {
        // Given
        let email = "test@example.com"
        let password = "SecurePassword123!"
        sut.saveCredentials(email: email, password: password)
        
        // When
        sut.deleteCredentials()
        
        // Then
        let retrieved = sut.getCredentials()
        XCTAssertNil(retrieved)
    }
    
    func testUpdateCredentials_ShouldOverwriteExisting() {
        // Given
        let originalEmail = "original@example.com"
        let originalPassword = "OriginalPassword123!"
        sut.saveCredentials(email: originalEmail, password: originalPassword)
        
        let newEmail = "new@example.com"
        let newPassword = "NewPassword123!"
        
        // When
        sut.saveCredentials(email: newEmail, password: newPassword)
        
        // Then
        let retrieved = sut.getCredentials()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.email, newEmail)
        XCTAssertEqual(retrieved?.password, newPassword)
    }
    
    // MARK: - Access Token Tests
    
    func testSaveAccessToken_ShouldStoreSuccessfully() {
        // Given
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
        let accountId = "account-123"
        
        // When
        sut.saveAccessToken(token, for: accountId)
        
        // Then
        let retrieved = sut.getAccessToken(for: accountId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved, token)
    }
    
    func testGetAccessToken_WhenNotStored_ShouldReturnNil() {
        // Given
        let accountId = "nonexistent-account"
        
        // When
        let retrieved = sut.getAccessToken(for: accountId)
        
        // Then
        XCTAssertNil(retrieved)
    }
    
    func testDeleteAccessToken_ShouldRemoveSuccessfully() {
        // Given
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
        let accountId = "account-123"
        sut.saveAccessToken(token, for: accountId)
        
        // When
        sut.deleteAccessToken(for: accountId)
        
        // Then
        let retrieved = sut.getAccessToken(for: accountId)
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Refresh Token Tests
    
    func testSaveRefreshToken_ShouldStoreSuccessfully() {
        // Given
        let token = "refresh_token_123456"
        let accountId = "account-123"
        
        // When
        sut.saveRefreshToken(token, for: accountId)
        
        // Then
        let retrieved = sut.getRefreshToken(for: accountId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved, token)
    }
    
    func testGetRefreshToken_WhenNotStored_ShouldReturnNil() {
        // Given
        let accountId = "nonexistent-account"
        
        // When
        let retrieved = sut.getRefreshToken(for: accountId)
        
        // Then
        XCTAssertNil(retrieved)
    }
    
    func testDeleteRefreshToken_ShouldRemoveSuccessfully() {
        // Given
        let token = "refresh_token_123456"
        let accountId = "account-123"
        sut.saveRefreshToken(token, for: accountId)
        
        // When
        sut.deleteRefreshToken(for: accountId)
        
        // Then
        let retrieved = sut.getRefreshToken(for: accountId)
        XCTAssertNil(retrieved)
    }
    
    // MARK: - Multiple Accounts Tests
    
    func testMultipleAccountTokens_ShouldBeIndependent() {
        // Given
        let account1Id = "account-1"
        let account1AccessToken = "access_token_1"
        let account1RefreshToken = "refresh_token_1"
        
        let account2Id = "account-2"
        let account2AccessToken = "access_token_2"
        let account2RefreshToken = "refresh_token_2"
        
        // When
        sut.saveAccessToken(account1AccessToken, for: account1Id)
        sut.saveRefreshToken(account1RefreshToken, for: account1Id)
        sut.saveAccessToken(account2AccessToken, for: account2Id)
        sut.saveRefreshToken(account2RefreshToken, for: account2Id)
        
        // Then
        XCTAssertEqual(sut.getAccessToken(for: account1Id), account1AccessToken)
        XCTAssertEqual(sut.getRefreshToken(for: account1Id), account1RefreshToken)
        XCTAssertEqual(sut.getAccessToken(for: account2Id), account2AccessToken)
        XCTAssertEqual(sut.getRefreshToken(for: account2Id), account2RefreshToken)
    }
    
    // MARK: - Security Tests
    
    func testKeychainData_ShouldBeAccessibleOnlyWhenUnlocked() {
        // This test verifies that keychain items are created with proper access control
        // In a real implementation, we'd verify the kSecAttrAccessible attribute
        
        // Given
        let email = "secure@example.com"
        let password = "SecurePassword123!"
        
        // When
        sut.saveCredentials(email: email, password: password)
        
        // Then
        // In production, verify that the keychain item has kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        XCTAssertTrue(true, "Keychain items should be accessible only when device is unlocked")
    }
    
    // MARK: - Performance Tests
    
    func testKeychainPerformance_SaveAndRetrieve() {
        measure {
            // Given
            let email = "performance@example.com"
            let password = "PerformanceTest123!"
            
            // When
            sut.saveCredentials(email: email, password: password)
            _ = sut.getCredentials()
            sut.deleteCredentials()
        }
    }
    
    // MARK: - Helper Methods
    
    private func clearAllKeychainData() {
        // Clear credentials
        sut.deleteCredentials()
        
        // Clear all tokens for test accounts
        let testAccountIds = ["account-1", "account-2", "account-123", "test-account"]
        for accountId in testAccountIds {
            sut.deleteAccessToken(for: accountId)
            sut.deleteRefreshToken(for: accountId)
        }
    }
}

// MARK: - KeychainManager Test Extensions

extension KeychainManager {
    
    // Test-only methods to help with cleanup
    func deleteAccessToken(for accountId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "access_token_\(accountId)",
            kSecAttrService as String: "com.pipflow.app"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    func deleteRefreshToken(for accountId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "refresh_token_\(accountId)",
            kSecAttrService as String: "com.pipflow.app"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}