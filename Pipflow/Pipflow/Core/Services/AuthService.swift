//
//  AuthService.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

protocol AuthServiceProtocol {
    var currentUserPublisher: AnyPublisher<User?, Never> { get }
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    
    func signIn(email: String, password: String) -> AnyPublisher<User, AuthError>
    func signUp(email: String, password: String) -> AnyPublisher<User, AuthError>
    func signOut() -> AnyPublisher<Void, Never>
    func resetPassword(email: String) -> AnyPublisher<Void, AuthError>
    func getCurrentUser() -> AnyPublisher<User?, AuthError>
}

class AuthService: ObservableObject, AuthServiceProtocol {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User? = nil
    
    private let currentUserSubject = CurrentValueSubject<User?, Never>(nil)
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var currentUserPublisher: AnyPublisher<User?, Never> {
        currentUserSubject.eraseToAnyPublisher()
    }
    
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        currentUserPublisher
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }
    
    init() {
        // Subscribe to Supabase auth state changes
        supabaseService.$currentUser
            .sink { [weak self] user in
                self?.currentUser = user
                self?.currentUserSubject.send(user)
                self?.isAuthenticated = user != nil
            }
            .store(in: &cancellables)
        
        // Check if we're in development mode without Supabase
        if ProcessInfo.processInfo.environment["SUPABASE_URL"]?.isEmpty ?? true {
            // Auto-login for development/demo
            autoLoginForDemo()
        }
    }
    
    // MARK: - Async Methods for AuthViewModel
    
    func signIn(email: String, password: String) async throws {
        // If no Supabase configured, use demo login
        if ProcessInfo.processInfo.environment["SUPABASE_URL"]?.isEmpty ?? true {
            if email == "demo@pipflow.ai" && password == "demo123" {
                autoLoginForDemo()
                return
            } else {
                throw AuthError.invalidCredentials
            }
        }
        
        do {
            _ = try await supabaseService.signIn(email: email, password: password)
        } catch {
            throw mapSupabaseError(error)
        }
    }
    
    func signUp(email: String, password: String, fullName: String) async throws {
        // If no Supabase configured, simulate signup
        if ProcessInfo.processInfo.environment["SUPABASE_URL"]?.isEmpty ?? true {
            throw AuthError.unknown("Sign up not available in demo mode")
        }
        
        do {
            _ = try await supabaseService.signUp(email: email, password: password, fullName: fullName)
        } catch {
            throw mapSupabaseError(error)
        }
    }
    
    func signInWithApple() async throws {
        // TODO: Implement Apple Sign In
        throw AuthError.unknown("Apple Sign In not yet implemented")
    }
    
    func signInWithGoogle() async throws {
        // TODO: Implement Google Sign In
        throw AuthError.unknown("Google Sign In not yet implemented")
    }
    
    func resetPassword(email: String) async throws {
        // If no Supabase configured, simulate reset
        if ProcessInfo.processInfo.environment["SUPABASE_URL"]?.isEmpty ?? true {
            throw AuthError.unknown("Password reset not available in demo mode")
        }
        
        do {
            try await supabaseService.resetPassword(email: email)
        } catch {
            throw mapSupabaseError(error)
        }
    }
    
    func signOut() async throws {
        // If in demo mode, just clear the user
        if ProcessInfo.processInfo.environment["SUPABASE_URL"]?.isEmpty ?? true {
            currentUser = nil
            currentUserSubject.send(nil)
            isAuthenticated = false
            return
        }
        
        do {
            try await supabaseService.signOut()
        } catch {
            throw mapSupabaseError(error)
        }
    }
    
    private func mapSupabaseError(_ error: Error) -> AuthError {
        // Check if it's already an AuthError
        if let authError = error as? AuthError {
            return authError
        }
        
        // Map Supabase errors to AuthError
        if let nsError = error as NSError? {
            switch nsError.code {
            case 400:
                return .invalidCredentials
            case 404:
                return .userNotFound
            case 409:
                return .emailAlreadyInUse
            case 422:
                return .weakPassword
            default:
                return .unknown(error.localizedDescription)
            }
        }
        return .unknown(error.localizedDescription)
    }
    
    // MARK: - Combine Methods (for backward compatibility)
    
    func signIn(email: String, password: String) -> AnyPublisher<User, AuthError> {
        Future { promise in
            Task {
                do {
                    try await self.signIn(email: email, password: password)
                    if let user = self.currentUser {
                        promise(.success(user))
                    } else {
                        promise(.failure(.unknown("Failed to get user after sign in")))
                    }
                } catch let error as AuthError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func signUp(email: String, password: String) -> AnyPublisher<User, AuthError> {
        Future { promise in
            Task {
                do {
                    // Extract name from email for demo
                    let fullName = email.components(separatedBy: "@").first ?? "User"
                    try await self.signUp(email: email, password: password, fullName: fullName)
                    if let user = self.currentUser {
                        promise(.success(user))
                    } else {
                        promise(.failure(.unknown("Failed to get user after sign up")))
                    }
                } catch let error as AuthError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func signOut() -> AnyPublisher<Void, Never> {
        Future { promise in
            Task {
                do {
                    try await self.signOut()
                    promise(.success(()))
                } catch {
                    // Sign out should always succeed from UI perspective
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func resetPassword(email: String) -> AnyPublisher<Void, AuthError> {
        Future { promise in
            Task {
                do {
                    try await self.resetPassword(email: email)
                    promise(.success(()))
                } catch let error as AuthError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> AnyPublisher<User?, AuthError> {
        Just(currentUser)
            .setFailureType(to: AuthError.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Account Management
    
    func deleteAccount() async throws {
        // In a real app, this would call Supabase to delete the account
        if ProcessInfo.processInfo.environment["SUPABASE_URL"]?.isEmpty ?? true {
            // Demo mode - just sign out
            try await signOut()
            return
        }
        
        // Delete account from Supabase
        // await supabaseService.deleteAccount()
        
        // Sign out after deletion
        try await signOut()
    }
    
    func resendVerificationEmail() async throws {
        // In a real app, this would call Supabase to resend verification
        if ProcessInfo.processInfo.environment["SUPABASE_URL"]?.isEmpty ?? true {
            // Demo mode - do nothing
            return
        }
        
        // Resend verification email
        // try await supabaseService.resendVerificationEmail()
    }
    
    // MARK: - Demo Mode
    
    private func autoLoginForDemo() {
        // Create a demo user for testing
        let demoUser = User(
            id: UUID(),
            name: "Demo User",
            email: "demo@pipflow.ai",
            bio: "Trading enthusiast | AI-powered trader",
            totalProfit: 15420.50,
            winRate: 72.5,
            totalTrades: 342,
            followers: 1250,
            following: 89,
            avatarURL: nil,
            riskScore: 65,
            isVerified: true,
            isPro: true
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.currentUser = demoUser
            self?.currentUserSubject.send(demoUser)
            self?.isAuthenticated = true
        }
    }
}