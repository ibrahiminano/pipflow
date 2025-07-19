//
//  AuthEndpoint.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

enum AuthEndpoint: APIEndpoint {
    case signIn(email: String, password: String)
    case signUp(email: String, password: String)
    case resetPassword(email: String)
    case getCurrentUser(token: String)
    case refreshToken(refreshToken: String)
    case signOut(token: String)
    
    var baseURL: String {
        // Replace with your Supabase project URL
        "https://your-project.supabase.co"
    }
    
    var path: String {
        switch self {
        case .signIn:
            return "/auth/v1/token?grant_type=password"
        case .signUp:
            return "/auth/v1/signup"
        case .resetPassword:
            return "/auth/v1/recover"
        case .getCurrentUser:
            return "/auth/v1/user"
        case .refreshToken:
            return "/auth/v1/token?grant_type=refresh_token"
        case .signOut:
            return "/auth/v1/logout"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .signIn, .signUp, .resetPassword, .refreshToken, .signOut:
            return .post
        case .getCurrentUser:
            return .get
        }
    }
    
    var headers: [String: String]? {
        var headers = [String: String]()
        headers["apikey"] = "your-anon-key" // Replace with your Supabase anon key
        
        switch self {
        case .getCurrentUser(let token), .signOut(let token):
            headers["Authorization"] = "Bearer \(token)"
        default:
            break
        }
        
        return headers
    }
    
    var parameters: [String: Any]? {
        return nil
    }
    
    var body: Data? {
        let encoder = JSONEncoder()
        
        switch self {
        case .signIn(let email, let password):
            let body = [
                "email": email,
                "password": password
            ]
            return try? JSONSerialization.data(withJSONObject: body)
            
        case .signUp(let email, let password):
            let body = [
                "email": email,
                "password": password
            ]
            return try? JSONSerialization.data(withJSONObject: body)
            
        case .resetPassword(let email):
            let body = [
                "email": email
            ]
            return try? JSONSerialization.data(withJSONObject: body)
            
        case .refreshToken(let refreshToken):
            let body = [
                "refresh_token": refreshToken
            ]
            return try? JSONSerialization.data(withJSONObject: body)
            
        default:
            return nil
        }
    }
}