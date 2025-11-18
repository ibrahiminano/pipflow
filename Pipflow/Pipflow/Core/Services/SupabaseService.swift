//
//  SupabaseService.swift
//  Pipflow
//
//  Handles all Supabase interactions including auth, database, and storage
//

import Foundation
import Combine

// Temporary types until Supabase is properly integrated
struct Session {
    let user: AuthUser
    let accessToken: String
}

struct AuthUser {
    let id: UUID
}

struct AuthResponse {
    let user: AuthUser?
    let session: Session?
}

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentUser: User?
    @Published var session: Session?
    
    // Mock data storage for now
    private var mockUsers: [String: SupabaseUserProfile] = [:]
    
    private init() {
        // Check if we have environment variables
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
           !url.isEmpty, !key.isEmpty {
            print("✅ Supabase environment variables found - ready for integration")
        } else {
            print("⚠️ Supabase environment variables missing - using mock mode")
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, fullName: String) async throws -> AuthResponse {
        // Mock implementation until Supabase is integrated
        if mockUsers[email] != nil {
            throw AuthError.emailAlreadyInUse
        }
        
        let userId = UUID()
        let profile = SupabaseUserProfile(
            id: userId,
            email: email,
            fullName: fullName,
            bio: nil,
            totalProfit: 0,
            winRate: 0,
            totalTrades: 0,
            followers: 0,
            following: 0,
            avatarUrl: nil,
            riskScore: 50,
            isVerified: false,
            isPro: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockUsers[email] = profile
        
        let user = AuthUser(id: userId)
        let session = Session(user: user, accessToken: "mock-token-\(userId)")
        
        self.session = session
        self.currentUser = User(from: profile)
        
        return AuthResponse(user: user, session: session)
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        // Mock implementation
        guard let profile = mockUsers[email] else {
            throw AuthError.userNotFound
        }
        
        let user = AuthUser(id: profile.id)
        let session = Session(user: user, accessToken: "mock-token-\(profile.id)")
        
        self.session = session
        self.currentUser = User(from: profile)
        
        return AuthResponse(user: user, session: session)
    }
    
    func signOut() async throws {
        session = nil
        currentUser = nil
    }
    
    func resetPassword(email: String) async throws {
        // Mock implementation
        if mockUsers[email] == nil {
            throw AuthError.userNotFound
        }
        print("Password reset email sent to \(email)")
    }
    
    func updatePassword(newPassword: String) async throws {
        guard session != nil else {
            throw AuthError.missingClient
        }
        print("Password updated successfully")
    }
    
    // MARK: - User Profile Methods
    
    func fetchUserProfile(userId: UUID) async {
        // Mock implementation
        if let profile = mockUsers.values.first(where: { $0.id == userId }) {
            await MainActor.run {
                self.currentUser = User(from: profile)
            }
        }
    }
    
    func createUserProfile(userId: UUID, email: String, fullName: String) async throws {
        let profile = SupabaseUserProfile(
            id: userId,
            email: email,
            fullName: fullName,
            bio: nil,
            totalProfit: 0,
            winRate: 0,
            totalTrades: 0,
            followers: 0,
            following: 0,
            avatarUrl: nil,
            riskScore: 50,
            isVerified: false,
            isPro: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockUsers[email] = profile
    }
    
    func updateUserProfile(_ profile: SupabaseUserProfile) async throws {
        mockUsers[profile.email] = profile
        if profile.id == currentUser?.id {
            await MainActor.run {
                self.currentUser = User(from: profile)
            }
        }
    }
    
    // MARK: - Settings Methods
    
    func getUserSettings(userId: UUID) async throws -> SupabaseUserSettings {
        // Return default settings for now
        return SupabaseUserSettings(
            userId: userId,
            biometricEnabled: false,
            pushNotifications: true,
            emailNotifications: true,
            tradeNotifications: true,
            priceAlerts: true,
            newsAlerts: false,
            darkMode: true,
            autoTradingEnabled: false,
            riskLevel: "medium",
            defaultLeverage: 10,
            defaultOrderType: "market",
            updatedAt: Date()
        )
    }
    
    func updateUserSettings(_ settings: SupabaseUserSettings) async throws {
        // Mock implementation
        print("Settings updated")
    }
    
    // MARK: - Trading Methods
    
    func getTradingAccounts(userId: UUID) async throws -> [SupabaseTradingAccount] {
        // Return empty array for now
        return []
    }
    
    func createTradingAccount(_ account: SupabaseTradingAccount) async throws {
        print("Trading account created")
    }
    
    func getTrades(accountId: UUID, limit: Int = 50) async throws -> [SupabaseTrade] {
        // Return empty array for now
        return []
    }
    
    func createTrade(_ trade: SupabaseTrade) async throws {
        print("Trade created")
    }
    
    // MARK: - AI Signals Methods
    
    func getAISignals(limit: Int = 20) async throws -> [SupabaseAISignal] {
        // Return empty array for now
        return []
    }
    
    func createAISignal(_ signal: SupabaseAISignal) async throws {
        print("AI signal created")
    }
    
    // MARK: - Helper Methods
    
    var isAuthenticated: Bool {
        session != nil
    }
    
    func getAccessToken() async throws -> String {
        guard let session = session else {
            throw AuthError.missingClient
        }
        return session.accessToken
    }
}

// MARK: - Supabase Models

struct SupabaseUserProfile: Codable {
    let id: UUID
    let email: String
    let fullName: String
    let bio: String?
    let totalProfit: Double
    let winRate: Double
    let totalTrades: Int
    let followers: Int
    let following: Int
    let avatarUrl: String?
    let riskScore: Int
    let isVerified: Bool
    let isPro: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case bio
        case totalProfit = "total_profit"
        case winRate = "win_rate"
        case totalTrades = "total_trades"
        case followers
        case following
        case avatarUrl = "avatar_url"
        case riskScore = "risk_score"
        case isVerified = "is_verified"
        case isPro = "is_pro"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseUserSettings: Codable {
    let userId: UUID
    let biometricEnabled: Bool
    let pushNotifications: Bool
    let emailNotifications: Bool
    let tradeNotifications: Bool
    let priceAlerts: Bool
    let newsAlerts: Bool
    let darkMode: Bool
    let autoTradingEnabled: Bool
    let riskLevel: String
    let defaultLeverage: Int
    let defaultOrderType: String
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case biometricEnabled = "biometric_enabled"
        case pushNotifications = "push_notifications"
        case emailNotifications = "email_notifications"
        case tradeNotifications = "trade_notifications"
        case priceAlerts = "price_alerts"
        case newsAlerts = "news_alerts"
        case darkMode = "dark_mode"
        case autoTradingEnabled = "auto_trading_enabled"
        case riskLevel = "risk_level"
        case defaultLeverage = "default_leverage"
        case defaultOrderType = "default_order_type"
        case updatedAt = "updated_at"
    }
}

struct SupabaseTradingAccount: Codable {
    let id: UUID
    let userId: UUID
    let accountNumber: String
    let broker: String
    let accountType: String
    let currency: String
    let balance: Double
    let equity: Double
    let margin: Double
    let freeMargin: Double
    let marginLevel: Double?
    let isActive: Bool
    let metaApiAccountId: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case accountNumber = "account_number"
        case broker
        case accountType = "account_type"
        case currency
        case balance
        case equity
        case margin
        case freeMargin = "free_margin"
        case marginLevel = "margin_level"
        case isActive = "is_active"
        case metaApiAccountId = "metaapi_account_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseTrade: Codable {
    let id: UUID
    let accountId: UUID
    let symbol: String
    let orderType: String
    let side: String
    let volume: Double
    let openPrice: Double
    let closePrice: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let profit: Double?
    let commission: Double?
    let swap: Double?
    let status: String
    let openedAt: Date
    let closedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case accountId = "account_id"
        case symbol
        case orderType = "order_type"
        case side
        case volume
        case openPrice = "open_price"
        case closePrice = "close_price"
        case stopLoss = "stop_loss"
        case takeProfit = "take_profit"
        case profit
        case commission
        case swap
        case status
        case openedAt = "opened_at"
        case closedAt = "closed_at"
        case createdAt = "created_at"
    }
}

struct SupabaseAISignal: Codable {
    let id: UUID
    let generatedBy: UUID?
    let symbol: String
    let action: String
    let entryPrice: Double
    let stopLoss: Double
    let takeProfit: Double
    let confidence: Double
    let reasoning: String
    let timeframe: String
    let expiresAt: Date
    let status: String
    let actualOutcome: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case generatedBy = "generated_by"
        case symbol
        case action
        case entryPrice = "entry_price"
        case stopLoss = "stop_loss"
        case takeProfit = "take_profit"
        case confidence
        case reasoning
        case timeframe
        case expiresAt = "expires_at"
        case status
        case actualOutcome = "actual_outcome"
        case createdAt = "created_at"
    }
}

// MARK: - User Extension

extension User {
    init(from profile: SupabaseUserProfile) {
        self.id = profile.id
        self.name = profile.fullName
        self.email = profile.email
        self.bio = profile.bio ?? ""
        self.totalProfit = profile.totalProfit
        self.winRate = profile.winRate
        self.totalTrades = profile.totalTrades
        self.followers = profile.followers
        self.following = profile.following
        self.avatarURL = profile.avatarUrl
        self.riskScore = profile.riskScore
        self.isVerified = profile.isVerified
        self.isPro = profile.isPro
    }
}

// MARK: - Custom Errors

enum AuthError: LocalizedError {
    case missingClient
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case invalidEmail
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .missingClient:
            return "Supabase client not initialized"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyInUse:
            return "Email is already registered"
        case .weakPassword:
            return "Password is too weak"
        case .networkError:
            return "Network error occurred"
        case .invalidEmail:
            return "Invalid email format"
        case .unknown(let message):
            return message
        }
    }
}