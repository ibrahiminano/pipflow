//
//  BuildConfiguration.swift
//  Pipflow
//
//  Configuration for different build schemes
//

import Foundation

enum BuildConfiguration {
    case debug
    case staging
    case release
    
    static var current: BuildConfiguration {
        #if DEBUG
        return .debug
        #elseif STAGING
        return .staging
        #else
        return .release
        #endif
    }
    
    var baseURL: String {
        switch self {
        case .debug:
            return "https://dev-api.pipflow.ai"
        case .staging:
            return "https://staging-api.pipflow.ai"
        case .release:
            return "https://api.pipflow.ai"
        }
    }
    
    var metaAPIBaseURL: String {
        switch self {
        case .debug, .staging:
            return "https://mt-provisioning-api-v1.agiliumtrade.agiliumtrade.ai"
        case .release:
            return "https://mt-provisioning-api-v1.agiliumtrade.agiliumtrade.ai"
        }
    }
    
    var metaAPIStreamingURL: String {
        switch self {
        case .debug, .staging:
            return "wss://mt-client-ws-api.new-york.agiliumtrade.ai"
        case .release:
            return "wss://mt-client-ws-api.new-york.agiliumtrade.ai"
        }
    }
    
    var supabaseURL: String {
        switch self {
        case .debug:
            return ProcessInfo.processInfo.environment["SUPABASE_URL_DEV"] ?? "https://vastwouqtdkgksihdwoz.supabase.co"
        case .staging:
            return ProcessInfo.processInfo.environment["SUPABASE_URL_STAGING"] ?? ""
        case .release:
            return ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        }
    }
    
    var supabaseAnonKey: String {
        switch self {
        case .debug:
            return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY_DEV"] ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZhc3R3b3VxdGRrZ2tzaWhkd296Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI5NDE4NjMsImV4cCI6MjA2ODUxNzg2M30._huZbPfSW-Df6DFpKlchNT8KrnN8W3YUWYyEbyKFqNs"
        case .staging:
            return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY_STAGING"] ?? ""
        case .release:
            return ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        }
    }
    
    var shouldEnableLogging: Bool {
        switch self {
        case .debug, .staging:
            return true
        case .release:
            return false
        }
    }
    
    var shouldShowDebugMenu: Bool {
        switch self {
        case .debug:
            return true
        case .staging, .release:
            return false
        }
    }
}

extension BuildConfiguration: CustomStringConvertible {
    var description: String {
        switch self {
        case .debug:
            return "Debug"
        case .staging:
            return "Staging"
        case .release:
            return "Release"
        }
    }
}