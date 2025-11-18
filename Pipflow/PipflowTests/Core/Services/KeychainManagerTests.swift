//
//  KeychainManagerTests.swift
//  PipflowTests
//
//  Unit tests for KeychainManager
//

import XCTest
@testable import Pipflow

class KeychainManagerTests: XCTestCase {
    
    var keychainManager: KeychainManager!
    
    override func setUp() {
        super.setUp()
        keychainManager = KeychainManager.shared
        
        // Clean up any existing test data
        keychainManager.deleteCredentials()
        keychainManager.deleteAccessToken()
    }
    
    override func tearDown() {
        // Clean up after tests
        keychainManager.deleteCredentials()
        keychainManager.deleteAccessToken()
        super.tearDown()
    }
    
    // MARK: - Credentials Tests
    
    func testSaveAndRetrieveCredentials() throws {
        // Given
        let credentials = KeychainManager.Credentials(
            email: "test@example.com",
            password: "TestPassword123!",
            refreshToken: "test_refresh_token"
        )
        
        // When
        try keychainManager.saveCredentials(credentials)
        let retrievedCredentials = try keychainManager.getCredentials()
        
        // Then
        XCTAssertNotNil(retrievedCredentials)
        XCTAssertEqual(retrievedCredentials?.email, credentials.email)
        XCTAssertEqual(retrievedCredentials?.password, credentials.password)
        XCTAssertEqual(retrievedCredentials?.refreshToken, credentials.refreshToken)
    }
    
    func testGetCredentialsWhenNoneExist() throws {
        // When
        let credentials = try keychainManager.getCredentials()
        
        // Then
        XCTAssertNil(credentials)
    }
    
    func testDeleteCredentials() throws {
        // Given
        let credentials = KeychainManager.Credentials(
            email: "test@example.com",
            password: "TestPassword123!",
            refreshToken: nil
        )
        try keychainManager.saveCredentials(credentials)
        
        // When
        keychainManager.deleteCredentials()
        let retrievedCredentials = try keychainManager.getCredentials()
        
        // Then
        XCTAssertNil(retrievedCredentials)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "has_saved_credentials"))
    }
    
    func testCredentialsWithoutRefreshToken() throws {
        // Given
        let credentials = KeychainManager.Credentials(
            email: "test@example.com",
            password: "TestPassword123!",
            refreshToken: nil
        )
        
        // When
        try keychainManager.saveCredentials(credentials)
        let retrievedCredentials = try keychainManager.getCredentials()
        
        // Then
        XCTAssertNotNil(retrievedCredentials)
        XCTAssertNil(retrievedCredentials?.refreshToken)
    }
    
    // MARK: - Generic Storage Tests
    
    func testSaveAndGetString() throws {
        // Given
        let key = "test_key"
        let value = "test_value"
        
        // When
        try keychainManager.save(value, for: key)
        let retrievedValue = try keychainManager.get(key)
        
        // Then
        XCTAssertEqual(retrievedValue, value)
    }
    
    func testUpdateExistingValue() throws {
        // Given
        let key = "test_key"
        let originalValue = "original"
        let updatedValue = "updated"
        
        // When
        try keychainManager.save(originalValue, for: key)
        try keychainManager.save(updatedValue, for: key)
        let retrievedValue = try keychainManager.get(key)
        
        // Then
        XCTAssertEqual(retrievedValue, updatedValue)
    }
    
    func testDeleteString() throws {
        // Given
        let key = "test_key"
        let value = "test_value"
        try keychainManager.save(value, for: key)
        
        // When
        try keychainManager.delete(key)
        
        // Then
        XCTAssertThrowsError(try keychainManager.get(key)) { error in
            XCTAssertTrue(error is KeychainError)
            if let keychainError = error as? KeychainError {
                switch keychainError {
                case .noPassword:
                    break // Expected
                default:
                    XCTFail("Expected noPassword error, got \(keychainError)")
                }
            }
        }
    }
    
    // MARK: - Access Token Tests
    
    func testSaveAndGetAccessToken() throws {
        // Given
        let token = "test_access_token_12345"
        
        // When
        try keychainManager.saveAccessToken(token)
        let retrievedToken = try keychainManager.getAccessToken()
        
        // Then
        XCTAssertEqual(retrievedToken, token)
    }
    
    func testDeleteAccessToken() throws {
        // Given
        let token = "test_access_token"
        try keychainManager.saveAccessToken(token)
        
        // When
        keychainManager.deleteAccessToken()
        let retrievedToken = try keychainManager.getAccessToken()
        
        // Then
        XCTAssertNil(retrievedToken)
    }
    
    // MARK: - API Key Tests
    
    func testSaveAndGetAPIKey() throws {
        // Given
        let service = "openai"
        let apiKey = "sk-test-key-12345"
        
        // When
        try keychainManager.saveAPIKey(apiKey, for: service)
        let retrievedKey = try keychainManager.getAPIKey(for: service)
        
        // Then
        XCTAssertEqual(retrievedKey, apiKey)
    }
    
    func testMultipleAPIKeys() throws {
        // Given
        let openAIKey = "sk-openai-12345"
        let metaAPIKey = "meta-api-key-67890"
        
        // When
        try keychainManager.saveAPIKey(openAIKey, for: "openai")
        try keychainManager.saveAPIKey(metaAPIKey, for: "metaapi")
        
        let retrievedOpenAI = try keychainManager.getAPIKey(for: "openai")
        let retrievedMetaAPI = try keychainManager.getAPIKey(for: "metaapi")
        
        // Then
        XCTAssertEqual(retrievedOpenAI, openAIKey)
        XCTAssertEqual(retrievedMetaAPI, metaAPIKey)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyStringStorage() throws {
        // Given
        let key = "empty_key"
        let value = ""
        
        // When
        try keychainManager.save(value, for: key)
        let retrievedValue = try keychainManager.get(key)
        
        // Then
        XCTAssertEqual(retrievedValue, value)
    }
    
    func testLongStringStorage() throws {
        // Given
        let key = "long_key"
        let value = String(repeating: "a", count: 10000)
        
        // When
        try keychainManager.save(value, for: key)
        let retrievedValue = try keychainManager.get(key)
        
        // Then
        XCTAssertEqual(retrievedValue, value)
    }
    
    func testSpecialCharactersInValue() throws {
        // Given
        let key = "special_key"
        let value = "!@#$%^&*()_+-={}[]|\\:\";<>?,./~`"
        
        // When
        try keychainManager.save(value, for: key)
        let retrievedValue = try keychainManager.get(key)
        
        // Then
        XCTAssertEqual(retrievedValue, value)
    }
}

// MARK: - Performance Tests
extension KeychainManagerTests {
    
    func testSavePerformance() throws {
        measure {
            do {
                for i in 0..<100 {
                    try keychainManager.save("value_\(i)", for: "key_\(i)")
                }
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
    
    func testRetrievePerformance() throws {
        // Setup
        for i in 0..<100 {
            try keychainManager.save("value_\(i)", for: "perf_key_\(i)")
        }
        
        // Measure
        measure {
            do {
                for i in 0..<100 {
                    _ = try keychainManager.get("perf_key_\(i)")
                }
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
}