//
//  AuthServiceTests.swift
//  PipflowTests
//
//  Unit tests for AuthService
//

import XCTest
import Combine
@testable import Pipflow

class AuthServiceTests: XCTestCase {
    
    var authService: AuthService!
    var mockSupabaseService: MockSupabaseService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        authService = AuthService.shared
        mockSupabaseService = MockSupabaseService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Sign In Tests
    
    func testSignInSuccess() async throws {
        // Given
        let email = "test@example.com"
        let password = "TestPassword123!"
        
        // When
        do {
            try await authService.signIn(email: email, password: password)
            
            // Then
            XCTAssertTrue(authService.isAuthenticated)
            XCTAssertNotNil(authService.currentUser)
            XCTAssertEqual(authService.currentUser?.email, email)
        } catch {
            XCTFail("Sign in should succeed but failed with error: \(error)")
        }
    }
    
    func testSignInWithInvalidEmail() async {
        // Given
        let email = "invalid-email"
        let password = "TestPassword123!"
        
        // When/Then
        do {
            try await authService.signIn(email: email, password: password)
            XCTFail("Sign in should fail with invalid email")
        } catch let error as AuthError {
            XCTAssertEqual(error, AuthError.invalidEmail)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testSignInWithEmptyPassword() async {
        // Given
        let email = "test@example.com"
        let password = ""
        
        // When/Then
        do {
            try await authService.signIn(email: email, password: password)
            XCTFail("Sign in should fail with empty password")
        } catch let error as AuthError {
            XCTAssertTrue(error.localizedDescription.contains("password"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpSuccess() async throws {
        // Given
        let email = "newuser@example.com"
        let password = "NewPassword123!"
        let fullName = "Test User"
        
        // When
        do {
            try await authService.signUp(email: email, password: password, fullName: fullName)
            
            // Then
            XCTAssertTrue(authService.isAuthenticated)
            XCTAssertNotNil(authService.currentUser)
            XCTAssertEqual(authService.currentUser?.email, email)
        } catch {
            XCTFail("Sign up should succeed but failed with error: \(error)")
        }
    }
    
    func testSignUpWithExistingEmail() async {
        // Given
        let email = "existing@example.com"
        let password = "TestPassword123!"
        let fullName = "Test User"
        
        // First create a user
        try? await authService.signUp(email: email, password: password, fullName: fullName)
        
        // When/Then - Try to create another user with same email
        do {
            try await authService.signUp(email: email, password: password, fullName: fullName)
            XCTFail("Sign up should fail with existing email")
        } catch let error as AuthError {
            XCTAssertTrue(error.localizedDescription.contains("already"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testSignUpWithWeakPassword() async {
        // Given
        let email = "test@example.com"
        let password = "weak"
        let fullName = "Test User"
        
        // When/Then
        do {
            try await authService.signUp(email: email, password: password, fullName: fullName)
            XCTFail("Sign up should fail with weak password")
        } catch let error as AuthError {
            XCTAssertTrue(error.localizedDescription.contains("weak") || error.localizedDescription.contains("password"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut() async throws {
        // Given - Sign in first
        let email = "test@example.com"
        let password = "TestPassword123!"
        try await authService.signIn(email: email, password: password)
        
        XCTAssertTrue(authService.isAuthenticated)
        
        // When
        try await authService.signOut()
        
        // Then
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }
    
    // MARK: - Password Reset Tests
    
    func testResetPassword() async throws {
        // Given
        let email = "test@example.com"
        
        // When
        do {
            try await authService.resetPassword(email: email)
            // Then - Should complete without error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Reset password should succeed but failed with error: \(error)")
        }
    }
    
    func testResetPasswordWithInvalidEmail() async {
        // Given
        let email = "invalid-email"
        
        // When/Then
        do {
            try await authService.resetPassword(email: email)
            XCTFail("Reset password should fail with invalid email")
        } catch {
            XCTAssertTrue(true)
        }
    }
    
    // MARK: - State Management Tests
    
    func testAuthenticationStatePublisher() {
        // Given
        let expectation = XCTestExpectation(description: "Auth state should change")
        var receivedStates: [Bool] = []
        
        authService.$isAuthenticated
            .sink { isAuthenticated in
                receivedStates.append(isAuthenticated)
                if receivedStates.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        Task {
            try? await authService.signIn(email: "test@example.com", password: "TestPassword123!")
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedStates.last, true)
    }
}

// MARK: - Mock Supabase Service

class MockSupabaseService {
    var shouldFailSignIn = false
    var shouldFailSignUp = false
    var mockUsers: [String: (email: String, password: String, fullName: String)] = [:]
    
    func signIn(email: String, password: String) async throws -> SupabaseAuthSession {
        if shouldFailSignIn {
            throw APIError.custom("Sign in failed")
        }
        
        guard mockUsers[email] != nil else {
            throw APIError.custom("Invalid credentials")
        }
        
        let authUser = SupabaseAuthUser(
            id: UUID(),
            email: email,
            userMetadata: [:]
        )
        
        return SupabaseAuthSession(
            accessToken: "mock_token",
            refreshToken: "mock_refresh",
            user: authUser
        )
    }
    
    func signUp(email: String, password: String, fullName: String) async throws -> SupabaseAuthResponse {
        if shouldFailSignUp {
            throw APIError.custom("Sign up failed")
        }
        
        if mockUsers[email] != nil {
            throw APIError.custom("Email already in use")
        }
        
        mockUsers[email] = (email, password, fullName)
        
        let authUser = SupabaseAuthUser(
            id: UUID(),
            email: email,
            userMetadata: ["full_name": fullName]
        )
        
        let session = SupabaseAuthSession(
            accessToken: "mock_token",
            refreshToken: "mock_refresh",
            user: authUser
        )
        
        return SupabaseAuthResponse(user: authUser, session: session)
    }
}