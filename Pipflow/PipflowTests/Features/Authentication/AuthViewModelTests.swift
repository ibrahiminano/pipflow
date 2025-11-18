//
//  AuthViewModelTests.swift
//  PipflowTests
//
//  Unit tests for AuthViewModel
//

import XCTest
import Combine
@testable import Pipflow

@MainActor
class AuthViewModelTests: XCTestCase {
    
    var viewModel: AuthViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = AuthViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Email Validation Tests
    
    func testEmailValidation() {
        // Test valid emails
        let validEmails = [
            "test@example.com",
            "user.name@example.com",
            "user+tag@example.co.uk",
            "user123@test-domain.com"
        ]
        
        for email in validEmails {
            viewModel.email = email
            viewModel.validateEmail()
            XCTAssertTrue(viewModel.isEmailValid, "Email '\(email)' should be valid")
        }
        
        // Test invalid emails
        let invalidEmails = [
            "",
            "notanemail",
            "@example.com",
            "user@",
            "user@.com",
            "user space@example.com",
            "user@example"
        ]
        
        for email in invalidEmails {
            viewModel.email = email
            viewModel.validateEmail()
            XCTAssertFalse(viewModel.isEmailValid, "Email '\(email)' should be invalid")
        }
    }
    
    // MARK: - Password Validation Tests
    
    func testPasswordValidation() {
        // Test valid passwords
        let validPasswords = [
            "Password123!",
            "StrongP@ss1",
            "MySecure#Pass99"
        ]
        
        for password in validPasswords {
            viewModel.password = password
            viewModel.validatePassword()
            XCTAssertTrue(viewModel.isPasswordValid, "Password should be valid")
        }
        
        // Test invalid passwords
        let invalidPasswords = [
            "",
            "short",
            "12345678",
            "password",
            "PASSWORD",
            "Pass123"  // No special character
        ]
        
        for password in invalidPasswords {
            viewModel.password = password
            viewModel.validatePassword()
            XCTAssertFalse(viewModel.isPasswordValid, "Password '\(password)' should be invalid")
        }
    }
    
    // MARK: - Password Strength Tests
    
    func testPasswordStrength() {
        // Weak passwords
        viewModel.password = ""
        XCTAssertEqual(viewModel.passwordStrength, .weak)
        
        viewModel.password = "pass"
        XCTAssertEqual(viewModel.passwordStrength, .weak)
        
        // Medium passwords
        viewModel.password = "password123"
        XCTAssertEqual(viewModel.passwordStrength, .medium)
        
        viewModel.password = "Password"
        XCTAssertEqual(viewModel.passwordStrength, .medium)
        
        // Strong passwords
        viewModel.password = "Password123!"
        XCTAssertEqual(viewModel.passwordStrength, .strong)
        
        viewModel.password = "MyStr0ng#P@ssw0rd"
        XCTAssertEqual(viewModel.passwordStrength, .strong)
    }
    
    // MARK: - Confirm Password Tests
    
    func testConfirmPasswordValidation() {
        viewModel.password = "Password123!"
        
        // Test matching passwords
        viewModel.confirmPassword = "Password123!"
        viewModel.validateConfirmPassword()
        XCTAssertTrue(viewModel.isConfirmPasswordValid)
        
        // Test non-matching passwords
        viewModel.confirmPassword = "Password123"
        viewModel.validateConfirmPassword()
        XCTAssertFalse(viewModel.isConfirmPasswordValid)
        
        // Test empty confirm password
        viewModel.confirmPassword = ""
        viewModel.validateConfirmPassword()
        XCTAssertFalse(viewModel.isConfirmPasswordValid)
    }
    
    // MARK: - Full Name Validation Tests
    
    func testFullNameValidation() {
        // Valid names
        let validNames = [
            "John Doe",
            "Jane Smith",
            "Mary Jane Watson",
            "Jean-Pierre Dupont",
            "María García"
        ]
        
        for name in validNames {
            viewModel.fullName = name
            viewModel.validateFullName()
            XCTAssertTrue(viewModel.isFullNameValid, "Name '\(name)' should be valid")
        }
        
        // Invalid names
        let invalidNames = [
            "",
            " ",
            "J",
            "123",
            "John123"
        ]
        
        for name in invalidNames {
            viewModel.fullName = name
            viewModel.validateFullName()
            XCTAssertFalse(viewModel.isFullNameValid, "Name '\(name)' should be invalid")
        }
    }
    
    // MARK: - Form Validation Tests
    
    func testLoginFormValidation() {
        // Initially invalid
        XCTAssertFalse(viewModel.isLoginFormValid)
        
        // Set valid email
        viewModel.email = "test@example.com"
        viewModel.validateEmail()
        XCTAssertFalse(viewModel.isLoginFormValid)
        
        // Set valid password
        viewModel.password = "Password123!"
        viewModel.validatePassword()
        XCTAssertTrue(viewModel.isLoginFormValid)
        
        // Make email invalid
        viewModel.email = "invalid"
        viewModel.validateEmail()
        XCTAssertFalse(viewModel.isLoginFormValid)
    }
    
    func testRegisterFormValidation() {
        // Initially invalid
        XCTAssertFalse(viewModel.isRegisterFormValid)
        
        // Set all valid fields
        viewModel.email = "test@example.com"
        viewModel.password = "Password123!"
        viewModel.confirmPassword = "Password123!"
        viewModel.fullName = "Test User"
        
        viewModel.validateEmail()
        viewModel.validatePassword()
        viewModel.validateConfirmPassword()
        viewModel.validateFullName()
        
        XCTAssertTrue(viewModel.isRegisterFormValid)
        
        // Make one field invalid
        viewModel.confirmPassword = "WrongPassword"
        viewModel.validateConfirmPassword()
        XCTAssertFalse(viewModel.isRegisterFormValid)
    }
    
    // MARK: - Async Action Tests
    
    func testLoginAction() async {
        // Set valid credentials
        viewModel.email = "test@example.com"
        viewModel.password = "Password123!"
        
        // Perform login
        await viewModel.login()
        
        // Check state after login
        XCTAssertFalse(viewModel.isLoading)
        // In a real test, we'd check if navigation happened or user state changed
    }
    
    func testRegisterAction() async {
        // Set valid registration data
        viewModel.email = "newuser@example.com"
        viewModel.password = "Password123!"
        viewModel.confirmPassword = "Password123!"
        viewModel.fullName = "New User"
        
        // Perform registration
        await viewModel.register()
        
        // Check state after registration
        XCTAssertFalse(viewModel.isLoading)
        // Form should be cleared after successful registration
        XCTAssertTrue(viewModel.email.isEmpty)
        XCTAssertTrue(viewModel.password.isEmpty)
    }
    
    func testForgotPasswordAction() async {
        // Set valid email
        viewModel.resetEmail = "test@example.com"
        viewModel.email = "test@example.com"
        viewModel.validateEmail()
        
        // Perform forgot password
        await viewModel.forgotPassword()
        
        // Check state
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showForgotPassword)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessageDisplay() async {
        // Trigger an error by trying to login with empty credentials
        viewModel.email = ""
        viewModel.password = ""
        
        await viewModel.login()
        
        // Should have an error message
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testLoadingState() {
        let expectation = XCTestExpectation(description: "Loading state should change")
        
        viewModel.$isLoading
            .dropFirst() // Skip initial value
            .sink { isLoading in
                if isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger an action that sets loading
        Task {
            await viewModel.login()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}