//
//  AuthService.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation
import Combine

enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case weakPassword
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyExists:
            return "Email already exists"
        case .weakPassword:
            return "Password is too weak"
        case .networkError:
            return "Network connection error"
        case .unknown(let message):
            return message
        }
    }
}

protocol AuthServiceProtocol {
    var currentUser: AnyPublisher<User?, Never> { get }
    var isAuthenticated: AnyPublisher<Bool, Never> { get }
    
    func signIn(email: String, password: String) -> AnyPublisher<User, AuthError>
    func signUp(email: String, password: String) -> AnyPublisher<User, AuthError>
    func signOut() -> AnyPublisher<Void, Never>
    func resetPassword(email: String) -> AnyPublisher<Void, AuthError>
    func getCurrentUser() -> AnyPublisher<User?, AuthError>
}

class AuthService: ObservableObject, AuthServiceProtocol {
    static let shared = AuthService()
    
    @Published var currentUserSubject = CurrentValueSubject<User?, Never>(nil)
    private let apiClient: APIClientProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var currentUser: AnyPublisher<User?, Never> {
        currentUserSubject.eraseToAnyPublisher()
    }
    
    var isAuthenticated: AnyPublisher<Bool, Never> {
        currentUser
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
        loadStoredUser()
    }
    
    func signIn(email: String, password: String) -> AnyPublisher<User, AuthError> {
        let endpoint = AuthEndpoint.signIn(email: email, password: password)
        
        return apiClient.request(endpoint)
            .map { (response: AuthResponse) in
                // Store tokens securely
                self.storeTokens(response.tokens)
                
                // Update current user
                let user = response.user
                self.currentUserSubject.send(user)
                self.storeUser(user)
                
                return user
            }
            .mapError { apiError in
                self.mapAPIError(apiError)
            }
            .eraseToAnyPublisher()
    }
    
    func signUp(email: String, password: String) -> AnyPublisher<User, AuthError> {
        let endpoint = AuthEndpoint.signUp(email: email, password: password)
        
        return apiClient.request(endpoint)
            .map { (response: AuthResponse) in
                // Store tokens securely
                self.storeTokens(response.tokens)
                
                // Update current user
                let user = response.user
                self.currentUserSubject.send(user)
                self.storeUser(user)
                
                return user
            }
            .mapError { apiError in
                self.mapAPIError(apiError)
            }
            .eraseToAnyPublisher()
    }
    
    func signOut() -> AnyPublisher<Void, Never> {
        return Future { promise in
            // Clear stored tokens and user data
            self.clearStoredTokens()
            self.clearStoredUser()
            
            // Update current user
            self.currentUserSubject.send(nil)
            
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func resetPassword(email: String) -> AnyPublisher<Void, AuthError> {
        let endpoint = AuthEndpoint.resetPassword(email: email)
        
        return apiClient.requestWithoutResponse(endpoint)
            .mapError { apiError in
                self.mapAPIError(apiError)
            }
            .eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> AnyPublisher<User?, AuthError> {
        guard let storedTokens = getStoredTokens() else {
            return Just(nil)
                .setFailureType(to: AuthError.self)
                .eraseToAnyPublisher()
        }
        
        let endpoint = AuthEndpoint.getCurrentUser(token: storedTokens.accessToken)
        
        return apiClient.request(endpoint)
            .map { (user: User) in
                self.currentUserSubject.send(user)
                self.storeUser(user)
                return user
            }
            .mapError { apiError in
                // If token is invalid, clear stored data
                if case .unauthorized = apiError {
                    self.clearStoredTokens()
                    self.clearStoredUser()
                    self.currentUserSubject.send(nil)
                }
                return self.mapAPIError(apiError)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func loadStoredUser() {
        // Check if user is stored locally and load
        if let userData = UserDefaults.standard.data(forKey: "stored_user"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUserSubject.send(user)
            
            // Validate session in background
            getCurrentUser()
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
    }
    
    private func storeUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "stored_user")
        }
    }
    
    private func clearStoredUser() {
        UserDefaults.standard.removeObject(forKey: "stored_user")
    }
    
    private func storeTokens(_ tokens: AuthTokens) {
        // Store in Keychain for security
        let keychain = KeychainWrapper()
        keychain.set(tokens.accessToken, forKey: "access_token")
        keychain.set(tokens.refreshToken, forKey: "refresh_token")
    }
    
    private func getStoredTokens() -> AuthTokens? {
        let keychain = KeychainWrapper()
        
        guard let accessToken = keychain.string(forKey: "access_token"),
              let refreshToken = keychain.string(forKey: "refresh_token") else {
            return nil
        }
        
        return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
    
    private func clearStoredTokens() {
        let keychain = KeychainWrapper()
        keychain.removeObject(forKey: "access_token")
        keychain.removeObject(forKey: "refresh_token")
    }
    
    private func mapAPIError(_ apiError: APIError) -> AuthError {
        switch apiError {
        case .unauthorized:
            return .invalidCredentials
        case .serverError(let code, _):
            switch code {
            case 404:
                return .userNotFound
            case 409:
                return .emailAlreadyExists
            case 422:
                return .weakPassword
            default:
                return .networkError
            }
        case .networkError:
            return .networkError
        default:
            return .unknown(apiError.localizedDescription)
        }
    }
}

// MARK: - Response Models

private struct AuthResponse: Decodable {
    let user: User
    let tokens: AuthTokens
}

private struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - Keychain Wrapper

private class KeychainWrapper {
    func set(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func string(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    func removeObject(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}