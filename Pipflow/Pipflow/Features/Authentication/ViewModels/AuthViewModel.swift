//
//  AuthViewModel.swift
//  Pipflow
//
//  ViewModel for handling authentication logic
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var fullName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var showForgotPassword = false
    @Published var resetEmail = ""
    
    // MARK: - Validation States
    @Published var isEmailValid = false
    @Published var isPasswordValid = false
    @Published var isConfirmPasswordValid = false
    @Published var isFullNameValid = false
    
    // MARK: - Dependencies
    private let authService: AuthService
    private let biometricService = BiometricService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isLoginFormValid: Bool {
        isEmailValid && isPasswordValid
    }
    
    var isRegisterFormValid: Bool {
        isEmailValid && isPasswordValid && isConfirmPasswordValid && isFullNameValid
    }
    
    var passwordStrength: PasswordStrength {
        guard !password.isEmpty else { return .weak }
        
        var strength = 0
        if password.count >= 8 { strength += 1 }
        if password.contains(where: { $0.isUppercase }) { strength += 1 }
        if password.contains(where: { $0.isLowercase }) { strength += 1 }
        if password.contains(where: { $0.isNumber }) { strength += 1 }
        if password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) { strength += 1 }
        
        switch strength {
        case 0...2: return .weak
        case 3: return .medium
        default: return .strong
        }
    }
    
    // MARK: - Initialization
    init(authService: AuthService = .shared) {
        self.authService = authService
        setupValidation()
        observeAuthState()
    }
    
    // MARK: - Setup
    private func setupValidation() {
        // Email validation
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { email in
                let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
                return emailPredicate.evaluate(with: email)
            }
            .assign(to: &$isEmailValid)
        
        // Password validation
        $password
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { password in
                password.count >= 8
            }
            .assign(to: &$isPasswordValid)
        
        // Confirm password validation
        Publishers.CombineLatest($password, $confirmPassword)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { password, confirmPassword in
                !password.isEmpty && password == confirmPassword
            }
            .assign(to: &$isConfirmPasswordValid)
        
        // Full name validation
        $fullName
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { name in
                name.count >= 2
            }
            .assign(to: &$isFullNameValid)
    }
    
    private func observeAuthState() {
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
    }
    
    // MARK: - Authentication Methods
    func login() async {
        guard isLoginFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signIn(email: email, password: password)
            
            // Save credentials for biometric login if enabled
            if biometricService.isEnabled {
                let credentials = KeychainManager.Credentials(
                    email: email,
                    password: password,
                    refreshToken: nil
                )
                try KeychainManager.shared.saveCredentials(credentials)
            }
            
            clearForm()
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func register() async {
        guard isRegisterFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signUp(
                email: email,
                password: password,
                fullName: fullName
            )
            clearForm()
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func loginWithApple() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signInWithApple()
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func loginWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signInWithGoogle()
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func loginWithBiometric() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First authenticate with biometric
            try await biometricService.authenticateForLogin()
            
            // Get stored credentials from keychain
            guard let credentials = try KeychainManager.shared.getCredentials() else {
                errorMessage = "No saved credentials found. Please login with email and password first"
                isLoading = false
                return
            }
            
            // Login with stored credentials
            email = credentials.email
            password = credentials.password
            
            // Attempt login
            try await authService.signIn(email: email, password: password)
            isAuthenticated = true
            
            // If we have a refresh token, update it
            if let refreshToken = credentials.refreshToken {
                try KeychainManager.shared.save(refreshToken, for: "refresh_token")
            }
        } catch let biometricError as BiometricError {
            errorMessage = biometricError.localizedDescription
        } catch let keychainError as KeychainError {
            errorMessage = keychainError.localizedDescription
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func forgotPassword() async {
        guard isEmailValid else {
            errorMessage = "Please enter a valid email"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(email: resetEmail)
            showForgotPassword = false
            errorMessage = "Password reset email sent. Please check your inbox."
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func logout() async {
        do {
            try await authService.signOut()
            
            // Clear saved credentials
            KeychainManager.shared.deleteCredentials()
            
            // Clear biometric settings if needed
            if !biometricService.isEnabled {
                KeychainManager.shared.deleteAccessToken()
            }
        } catch {
            errorMessage = "Failed to logout: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Methods
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        resetEmail = ""
        errorMessage = nil
    }
    
    private func handleAuthError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.errorDescription ?? authError.localizedDescription
        }
        return error.localizedDescription
    }
}

// MARK: - Supporting Types
enum PasswordStrength {
    case weak
    case medium
    case strong
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    var description: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
}

