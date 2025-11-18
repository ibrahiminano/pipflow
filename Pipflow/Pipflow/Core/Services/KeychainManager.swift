//
//  KeychainManager.swift
//  Pipflow
//
//  Secure storage for sensitive data using Keychain
//

import Foundation
import Security

enum KeychainError: LocalizedError {
    case noPassword
    case unexpectedPasswordData
    case unexpectedItemData
    case unhandledError(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .noPassword:
            return "No password found in keychain"
        case .unexpectedPasswordData:
            return "Unexpected password data format"
        case .unexpectedItemData:
            return "Unexpected item data format"
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        }
    }
}

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = Bundle.main.bundleIdentifier ?? "com.pipflow.Pipflow"
    
    private init() {}
    
    // MARK: - Credentials Storage
    
    struct Credentials {
        let email: String
        let password: String
        let refreshToken: String?
    }
    
    func saveCredentials(_ credentials: Credentials) throws {
        // Save email
        try save(credentials.email, for: "user_email")
        
        // Save password
        try save(credentials.password, for: "user_password")
        
        // Save refresh token if available
        if let refreshToken = credentials.refreshToken {
            try save(refreshToken, for: "refresh_token")
        }
        
        // Mark that we have saved credentials
        UserDefaults.standard.set(true, forKey: "has_saved_credentials")
        UserDefaults.standard.set(credentials.email, forKey: "last_logged_email")
    }
    
    func getCredentials() throws -> Credentials? {
        guard UserDefaults.standard.bool(forKey: "has_saved_credentials") else {
            return nil
        }
        
        let email = try get("user_email")
        let password = try get("user_password")
        let refreshToken = try? get("refresh_token")
        
        return Credentials(
            email: email,
            password: password,
            refreshToken: refreshToken
        )
    }
    
    func deleteCredentials() {
        try? delete("user_email")
        try? delete("user_password")
        try? delete("refresh_token")
        
        UserDefaults.standard.set(false, forKey: "has_saved_credentials")
        UserDefaults.standard.removeObject(forKey: "last_logged_email")
    }
    
    // MARK: - Generic Keychain Operations
    
    func save(_ value: String, for key: String) throws {
        let data = Data(value.utf8)
        
        // Check if item exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        
        let status = SecItemAdd(newQuery as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func get(_ key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedPasswordData
        }
        
        return value
    }
    
    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Token Management
    
    func saveAccessToken(_ token: String) throws {
        try save(token, for: "access_token")
    }
    
    func getAccessToken() throws -> String? {
        return try? get("access_token")
    }
    
    func deleteAccessToken() {
        try? delete("access_token")
    }
    
    // MARK: - API Keys
    
    func saveAPIKey(_ key: String, for service: String) throws {
        try save(key, for: "api_key_\(service)")
    }
    
    func getAPIKey(for service: String) throws -> String? {
        return try? get("api_key_\(service)")
    }
    
    // MARK: - OAuth Token Storage
    
    func saveAccessToken(_ token: String, for accountId: String) {
        try? save(token, for: "oauth_access_\(accountId)")
    }
    
    func getAccessToken(for accountId: String) -> String? {
        return try? get("oauth_access_\(accountId)")
    }
    
    func removeAccessToken(for accountId: String) {
        try? delete("oauth_access_\(accountId)")
    }
    
    func saveRefreshToken(_ token: String, for accountId: String) {
        try? save(token, for: "oauth_refresh_\(accountId)")
    }
    
    func getRefreshToken(for accountId: String) -> String? {
        return try? get("oauth_refresh_\(accountId)")
    }
    
    func removeRefreshToken(for accountId: String) {
        try? delete("oauth_refresh_\(accountId)")
    }
}