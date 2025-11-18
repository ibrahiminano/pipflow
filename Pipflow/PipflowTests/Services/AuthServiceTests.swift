//
//  AuthServiceTests.swift
//  PipflowTests
//
//  Unit tests for AuthService
//

import XCTest
@testable import Pipflow

class AuthServiceTests: XCTestCase {
    
    var sut: AuthService!
    var mockSupabaseService: MockSupabaseService!
    var mockBiometricService: MockBiometricService!
    var mockKeychainManager: MockKeychainManager!
    
    override func setUp() {
        super.setUp()
        
        // Create mocks
        mockSupabaseService = MockSupabaseService()
        mockBiometricService = MockBiometricService()
        mockKeychainManager = MockKeychainManager()
        
        // Create system under test
        sut = AuthService.shared
        
        // Inject mocks (in a real app, we'd use dependency injection)
        // For now, we'll test the public interface
    }
    
    override func tearDown() {
        sut = nil
        mockSupabaseService = nil
        mockBiometricService = nil
        mockKeychainManager = nil
        super.tearDown()
    }
    
    // MARK: - Sign In Tests
    
    func testSignIn_WithValidCredentials_ShouldSucceed() async throws {
        // Given
        let email = "test@example.com"
        let password = "ValidPassword123!"
        
        // When
        do {
            try await sut.signIn(email: email, password: password)
            
            // Then
            XCTAssertTrue(sut.isAuthenticated)
            XCTAssertNotNil(sut.currentUser)
            XCTAssertEqual(sut.currentUser?.email, email)
        } catch {
            XCTFail("Sign in should succeed with valid credentials")
        }
    }
    
    func testSignIn_WithInvalidEmail_ShouldFail() async {
        // Given
        let email = "invalid-email"
        let password = "ValidPassword123!"
        
        // When
        do {
            try await sut.signIn(email: email, password: password)
            XCTFail("Sign in should fail with invalid email")
        } catch {
            // Then
            XCTAssertFalse(sut.isAuthenticated)
            XCTAssertNil(sut.currentUser)
        }
    }
    
    func testSignIn_WithEmptyPassword_ShouldFail() async {
        // Given
        let email = "test@example.com"
        let password = ""
        
        // When
        do {
            try await sut.signIn(email: email, password: password)
            XCTFail("Sign in should fail with empty password")
        } catch {
            // Then
            XCTAssertFalse(sut.isAuthenticated)
            XCTAssertNil(sut.currentUser)
        }
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUp_WithValidData_ShouldSucceed() async throws {
        // Given
        let email = "newuser@example.com"
        let password = "ValidPassword123!"
        let name = "Test User"
        
        // When
        do {
            try await sut.signUp(email: email, password: password, name: name)
            
            // Then
            XCTAssertTrue(sut.isAuthenticated)
            XCTAssertNotNil(sut.currentUser)
            XCTAssertEqual(sut.currentUser?.email, email)
            XCTAssertEqual(sut.currentUser?.name, name)
        } catch {
            XCTFail("Sign up should succeed with valid data")
        }
    }
    
    func testSignUp_WithWeakPassword_ShouldFail() async {
        // Given
        let email = "newuser@example.com"
        let password = "weak"
        let name = "Test User"
        
        // When
        do {
            try await sut.signUp(email: email, password: password, name: name)
            XCTFail("Sign up should fail with weak password")
        } catch {
            // Then
            XCTAssertFalse(sut.isAuthenticated)
            XCTAssertNil(sut.currentUser)
        }
    }
    
    // MARK: - Biometric Authentication Tests
    
    func testSignInWithBiometrics_WhenEnabled_ShouldSucceed() async throws {
        // Given - First sign in normally
        let email = "test@example.com"
        let password = "ValidPassword123!"
        try await sut.signIn(email: email, password: password)
        
        // Enable biometrics
        sut.isBiometricEnabled = true
        
        // Sign out
        sut.signOut()
        
        // When
        do {
            try await sut.signInWithBiometrics()
            
            // Then
            XCTAssertTrue(sut.isAuthenticated)
            XCTAssertNotNil(sut.currentUser)
        } catch {
            XCTFail("Biometric sign in should succeed when enabled")
        }
    }
    
    func testSignInWithBiometrics_WhenDisabled_ShouldFail() async {
        // Given
        sut.isBiometricEnabled = false
        
        // When
        do {
            try await sut.signInWithBiometrics()
            XCTFail("Biometric sign in should fail when disabled")
        } catch {
            // Then
            XCTAssertFalse(sut.isAuthenticated)
            XCTAssertNil(sut.currentUser)
        }
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut_ShouldClearUserData() async throws {
        // Given - Sign in first
        let email = "test@example.com"
        let password = "ValidPassword123!"
        try await sut.signIn(email: email, password: password)
        
        // When
        sut.signOut()
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isBiometricEnabled)
    }
    
    // MARK: - Password Reset Tests
    
    func testResetPassword_WithValidEmail_ShouldSucceed() async throws {
        // Given
        let email = "test@example.com"
        
        // When
        do {
            try await sut.resetPassword(email: email)
            // Then - No exception thrown means success
            XCTAssertTrue(true)
        } catch {
            XCTFail("Password reset should succeed with valid email")
        }
    }
    
    func testResetPassword_WithInvalidEmail_ShouldFail() async {
        // Given
        let email = "invalid-email"
        
        // When
        do {
            try await sut.resetPassword(email: email)
            XCTFail("Password reset should fail with invalid email")
        } catch {
            // Then - Exception thrown means validation worked
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - Demo Mode Tests
    
    func testSignIn_InDemoMode_ShouldSucceed() async throws {
        // Given - Ensure we're in demo mode by not having Supabase configured
        let email = "demo@pipflow.ai"
        let password = "demo123"
        
        // When
        do {
            try await sut.signIn(email: email, password: password)
            
            // Then
            XCTAssertTrue(sut.isAuthenticated)
            XCTAssertNotNil(sut.currentUser)
            XCTAssertEqual(sut.currentUser?.email, email)
        } catch {
            XCTFail("Demo sign in should succeed")
        }
    }
}

// MARK: - Mock Services

class MockSupabaseService {
    var signInCalled = false
    var signUpCalled = false
    var signOutCalled = false
    var resetPasswordCalled = false
    
    var shouldSucceed = true
    var mockUser: User?
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        signInCalled = true
        
        if !shouldSucceed {
            throw AuthError.invalidCredentials
        }
        
        let user = User(
            id: UUID().uuidString,
            email: email,
            name: "Test User",
            avatarUrl: nil,
            isVerified: true,
            createdAt: Date(),
            bio: nil,
            location: nil,
            tradingExperience: .intermediate,
            preferredMarkets: [],
            riskTolerance: .medium,
            monthlyTarget: 1000,
            isPublicProfile: false,
            followersCount: 0,
            followingCount: 0,
            totalTrades: 0,
            winRate: 0,
            averageProfit: 0,
            reputation: 0
        )
        
        return AuthResponse(
            user: user,
            session: Session(
                id: UUID().uuidString,
                userId: user.id,
                accessToken: "mock_token",
                refreshToken: "mock_refresh",
                expiresAt: Date().addingTimeInterval(3600)
            )
        )
    }
    
    func signUp(email: String, password: String, metadata: [String: Any]?) async throws -> AuthResponse {
        signUpCalled = true
        
        if !shouldSucceed {
            throw AuthError.weakPassword
        }
        
        return try await signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        signOutCalled = true
    }
    
    func resetPassword(email: String) async throws {
        resetPasswordCalled = true
        
        if !email.contains("@") {
            throw AuthError.invalidEmail
        }
    }
}

class MockBiometricService {
    var isAvailable = true
    var isEnabled = false
    var authenticateCalled = false
    
    func authenticate() async throws -> Bool {
        authenticateCalled = true
        
        if !isAvailable {
            throw BiometricError.notAvailable
        }
        
        if !isEnabled {
            throw BiometricError.notEnabled
        }
        
        return true
    }
}

class MockKeychainManager {
    var storedCredentials: [String: String] = [:]
    
    func saveCredentials(email: String, password: String) {
        storedCredentials["email"] = email
        storedCredentials["password"] = password
    }
    
    func getCredentials() -> (email: String, password: String)? {
        guard let email = storedCredentials["email"],
              let password = storedCredentials["password"] else {
            return nil
        }
        return (email, password)
    }
    
    func deleteCredentials() {
        storedCredentials.removeAll()
    }
}

// MARK: - Test Errors

enum BiometricError: Error {
    case notAvailable
    case notEnabled
    case authenticationFailed
}