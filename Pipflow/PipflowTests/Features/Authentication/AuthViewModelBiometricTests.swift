//
//  AuthViewModelBiometricTests.swift
//  PipflowTests
//
//  Unit tests for AuthViewModel biometric authentication
//

import XCTest
import Combine
@testable import Pipflow

class AuthViewModelBiometricTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    var mockAuthService: MockAuthService!
    var mockBiometricService: MockBiometricService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        mockAuthService = MockAuthService()
        mockBiometricService = MockBiometricService()
        
        // Create view model with mocks
        viewModel = AuthViewModel()
        
        // Clean up keychain
        KeychainManager.shared.deleteCredentials()
        
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
        mockBiometricService = nil
        cancellables = nil
        KeychainManager.shared.deleteCredentials()
        super.tearDown()
    }
    
    // MARK: - Biometric Login Tests
    
    func testBiometricLoginWithSavedCredentials() async {
        // Given
        let credentials = KeychainManager.Credentials(
            email: "test@example.com",
            password: "password123",
            refreshToken: "refresh_token"
        )
        try? KeychainManager.shared.saveCredentials(credentials)
        
        mockBiometricService.isEnabled = true
        mockBiometricService.shouldSucceed = true
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.loginWithBiometric()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.email, credentials.email)
        XCTAssertEqual(viewModel.password, credentials.password)
    }
    
    func testBiometricLoginWithoutSavedCredentials() async {
        // Given
        mockBiometricService.isEnabled = true
        mockBiometricService.shouldSucceed = true
        
        // When
        await viewModel.loginWithBiometric()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.errorMessage, "No saved credentials found. Please login with email and password first")
    }
    
    func testBiometricLoginWithAuthenticationFailure() async {
        // Given
        let credentials = KeychainManager.Credentials(
            email: "test@example.com",
            password: "password123",
            refreshToken: nil
        )
        try? KeychainManager.shared.saveCredentials(credentials)
        
        mockBiometricService.isEnabled = true
        mockBiometricService.shouldSucceed = false
        mockBiometricService.errorToThrow = BiometricError.authenticationFailed
        
        // When
        await viewModel.loginWithBiometric()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.errorMessage, BiometricError.authenticationFailed.localizedDescription)
    }
    
    func testBiometricLoginSavesRefreshToken() async {
        // Given
        let credentials = KeychainManager.Credentials(
            email: "test@example.com",
            password: "password123",
            refreshToken: "new_refresh_token"
        )
        try? KeychainManager.shared.saveCredentials(credentials)
        
        mockBiometricService.isEnabled = true
        mockBiometricService.shouldSucceed = true
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.loginWithBiometric()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        let savedToken = try? KeychainManager.shared.get("refresh_token")
        XCTAssertEqual(savedToken, "new_refresh_token")
    }
    
    // MARK: - Regular Login with Biometric Save Tests
    
    func testRegularLoginSavesCredentialsWhenBiometricEnabled() async {
        // Given
        mockBiometricService.isEnabled = true
        mockAuthService.shouldSucceed = true
        
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        
        let savedCredentials = try? KeychainManager.shared.getCredentials()
        XCTAssertNotNil(savedCredentials)
        XCTAssertEqual(savedCredentials?.email, "test@example.com")
        XCTAssertEqual(savedCredentials?.password, "password123")
    }
    
    func testRegularLoginDoesNotSaveCredentialsWhenBiometricDisabled() async {
        // Given
        mockBiometricService.isEnabled = false
        mockAuthService.shouldSucceed = true
        
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When
        await viewModel.login()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        
        let savedCredentials = try? KeychainManager.shared.getCredentials()
        XCTAssertNil(savedCredentials)
    }
    
    // MARK: - Logout Tests
    
    func testLogoutClearsKeychainCredentials() async {
        // Given
        let credentials = KeychainManager.Credentials(
            email: "test@example.com",
            password: "password123",
            refreshToken: nil
        )
        try? KeychainManager.shared.saveCredentials(credentials)
        try? KeychainManager.shared.saveAccessToken("access_token")
        
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.logout()
        
        // Then
        let savedCredentials = try? KeychainManager.shared.getCredentials()
        XCTAssertNil(savedCredentials)
    }
    
    func testLogoutPreservesAccessTokenWhenBiometricEnabled() async {
        // Given
        mockBiometricService.isEnabled = true
        try? KeychainManager.shared.saveAccessToken("access_token")
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.logout()
        
        // Then
        let accessToken = try? KeychainManager.shared.getAccessToken()
        XCTAssertNotNil(accessToken)
    }
    
    // MARK: - Error Handling Tests
    
    func testBiometricLoginHandlesKeychainError() async {
        // Given - No credentials saved, so getCredentials will throw
        mockBiometricService.isEnabled = true
        mockBiometricService.shouldSucceed = true
        
        // When
        await viewModel.loginWithBiometric()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testBiometricLoginHandlesNetworkError() async {
        // Given
        let credentials = KeychainManager.Credentials(
            email: "test@example.com",
            password: "password123",
            refreshToken: nil
        )
        try? KeychainManager.shared.saveCredentials(credentials)
        
        mockBiometricService.isEnabled = true
        mockBiometricService.shouldSucceed = true
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = NSError(domain: "Network", code: -1, userInfo: nil)
        
        // When
        await viewModel.loginWithBiometric()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Authentication failed") ?? false)
    }
}

// MARK: - Mock Services

class MockBiometricService: ObservableObject {
    @Published var isEnabled = false
    @Published var isAvailable = true
    var biometricType: BiometricType = .faceID
    
    var shouldSucceed = true
    var errorToThrow: Error?
    
    func authenticateForLogin() async throws {
        if !shouldSucceed {
            throw errorToThrow ?? BiometricError.authenticationFailed
        }
    }
    
    func enableBiometric() async throws {
        if !shouldSucceed {
            throw errorToThrow ?? BiometricError.notAvailable
        }
        isEnabled = true
    }
    
    func disableBiometric() {
        isEnabled = false
    }
}

class MockAuthService: ObservableObject {
    var shouldSucceed = true
    var errorToThrow: Error?
    @Published var currentUser: User?
    
    func signIn(email: String, password: String) async throws {
        if !shouldSucceed {
            throw errorToThrow ?? NSError(domain: "Auth", code: -1, userInfo: nil)
        }
        currentUser = User(
            id: UUID(),
            email: email,
            username: "testuser",
            fullName: "Test User",
            createdAt: Date()
        )
    }
    
    func signOut() async throws {
        if !shouldSucceed {
            throw errorToThrow ?? NSError(domain: "Auth", code: -1, userInfo: nil)
        }
        currentUser = nil
    }
}