//
//  Environment.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

enum AppEnvironment {
    static let isDevelopment = true
    
    // MetaAPI Configuration
    enum MetaAPI {
        static let baseURL = "https://mt-provisioning-api-v1.agiliumtrade.agiliumtrade.ai"
        static let streamingURL = "wss://mt-client-ws-api.new-york.agiliumtrade.ai"
        
        // These should be stored securely - for demo purposes only
        static let accountId = ProcessInfo.processInfo.environment["METAAPI_ACCOUNT_ID"] ?? ""
        static let token = ProcessInfo.processInfo.environment["METAAPI_TOKEN"] ?? ""
        
        static let region = "new-york"
        static let application = "MetaApi"
    }
    
    // Supabase Configuration
    enum Supabase {
        static let url = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        static let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
    }
    
    // OpenAI Configuration
    enum OpenAI {
        static let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        static let model = "gpt-4-turbo"
    }
    
    // Claude Configuration
    enum Claude {
        static let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
        static let model = "claude-3-opus-20240229"
    }
}