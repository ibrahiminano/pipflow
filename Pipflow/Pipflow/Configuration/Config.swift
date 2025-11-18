//
//  Config.swift
//  Pipflow
//
//  Configuration management for different build schemes
//

import Foundation

enum Config {
    enum BuildScheme {
        case debug
        case staging
        case release
        
        static var current: BuildScheme {
            #if DEBUG
            return .debug
            #elseif STAGING
            return .staging
            #else
            return .release
            #endif
        }
    }
    
    // MARK: - API Keys
    
    static var supabaseURL: String {
        switch BuildScheme.current {
        case .debug:
            return ProcessInfo.processInfo.environment["SUPABASE_URL_DEBUG"] ?? ""
        case .staging:
            return ProcessInfo.processInfo.environment["SUPABASE_URL_STAGING"] ?? ""
        case .release:
            return ProcessInfo.processInfo.environment["SUPABASE_URL_RELEASE"] ?? ""
        }
    }
    
    static var supabaseAnonKey: String {
        switch BuildScheme.current {
        case .debug:
            return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY_DEBUG"] ?? ""
        case .staging:
            return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY_STAGING"] ?? ""
        case .release:
            return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY_RELEASE"] ?? ""
        }
    }
    
    static var metaAPIKey: String {
        switch BuildScheme.current {
        case .debug:
            return ProcessInfo.processInfo.environment["META_API_KEY_DEBUG"] ?? ""
        case .staging:
            return ProcessInfo.processInfo.environment["META_API_KEY_STAGING"] ?? ""
        case .release:
            return ProcessInfo.processInfo.environment["META_API_KEY_RELEASE"] ?? ""
        }
    }
    
    static var metaAPIAccountId: String {
        switch BuildScheme.current {
        case .debug:
            return ProcessInfo.processInfo.environment["META_API_ACCOUNT_ID_DEBUG"] ?? ""
        case .staging:
            return ProcessInfo.processInfo.environment["META_API_ACCOUNT_ID_STAGING"] ?? ""
        case .release:
            return ProcessInfo.processInfo.environment["META_API_ACCOUNT_ID_RELEASE"] ?? ""
        }
    }
    
    static var claudeAPIKey: String {
        switch BuildScheme.current {
        case .debug:
            return ProcessInfo.processInfo.environment["CLAUDE_API_KEY_DEBUG"] ?? ""
        case .staging:
            return ProcessInfo.processInfo.environment["CLAUDE_API_KEY_STAGING"] ?? ""
        case .release:
            return ProcessInfo.processInfo.environment["CLAUDE_API_KEY_RELEASE"] ?? ""
        }
    }
    
    // MARK: - Base URLs
    
    static var metaAPIBaseURL: String {
        switch BuildScheme.current {
        case .debug, .staging:
            return "https://mt-provisioning-api-v1.agiliumtrade.agiliumtrade.ai"
        case .release:
            return "https://mt-provisioning-api-v1.agiliumtrade.agiliumtrade.ai"
        }
    }
    
    static var metaAPISocketURL: String {
        switch BuildScheme.current {
        case .debug, .staging:
            return "wss://mt-client-api-v1.agiliumtrade.agiliumtrade.ai"
        case .release:
            return "wss://mt-client-api-v1.agiliumtrade.agiliumtrade.ai"
        }
    }
    
    // MARK: - Feature Flags
    
    static var isDebugMenuEnabled: Bool {
        return BuildScheme.current == .debug
    }
    
    static var isLoggingEnabled: Bool {
        return BuildScheme.current != .release
    }
    
    static var isMockDataEnabled: Bool {
        return BuildScheme.current == .debug
    }
    
    // MARK: - App Info
    
    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    static var appDisplayName: String {
        return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Pipflow"
    }
}