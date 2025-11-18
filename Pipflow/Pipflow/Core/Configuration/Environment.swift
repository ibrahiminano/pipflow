//
//  Environment.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import Foundation

enum AppEnvironment {
    static let configuration = BuildConfiguration.current
    static var isDevelopment: Bool {
        configuration == .debug
    }
    
    // MetaAPI Configuration
    enum MetaAPI {
        static var baseURL: String {
            configuration.metaAPIBaseURL
        }
        
        static var streamingURL: String {
            configuration.metaAPIStreamingURL
        }
        
        // These should be stored securely - for demo purposes only
        static let accountId = ProcessInfo.processInfo.environment["METAAPI_ACCOUNT_ID"] ?? "7a664389-76bc-4a1b-806d-b0ab32255714"
        static let token = ProcessInfo.processInfo.environment["METAAPI_TOKEN"] ?? "eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiJiYjI1NmUxYmRjOGQwYzA2MTUxZDg4ZjliNDAzMmFjYSIsImFjY2Vzc1J1bGVzIjpbeyJpZCI6InRyYWRpbmctYWNjb3VudC1tYW5hZ2VtZW50LWFwaSIsIm1ldGhvZHMiOlsidHJhZGluZy1hY2NvdW50LW1hbmFnZW1lbnQtYXBpOnJlc3Q6cHVibGljOio6KiJdLCJyb2xlcyI6WyJyZWFkZXIiLCJ3cml0ZXIiXSwicmVzb3VyY2VzIjpbIio6JFVTRVJfSUQkOioiXX0seyJpZCI6Im1ldGFhcGktcmVzdC1hcGkiLCJtZXRob2RzIjpbIm1ldGFhcGktYXBpOnJlc3Q6cHVibGljOio6KiJdLCJyb2xlcyI6WyJyZWFkZXIiLCJ3cml0ZXIiXSwicmVzb3VyY2VzIjpbIio6JFVTRVJfSUQkOioiXX0seyJpZCI6Im1ldGFhcGktcnBjLWFwaSIsIm1ldGhvZHMiOlsibWV0YWFwaS1hcGk6d3M6cHVibGljOio6KiJdLCJyb2xlcyI6WyJyZWFkZXIiLCJ3cml0ZXIiXSwicmVzb3VyY2VzIjpbIio6JFVTRVJfSUQkOioiXX0seyJpZCI6Im1ldGFhcGktcmVhbC10aW1lLXN0cmVhbWluZy1hcGkiLCJtZXRob2RzIjpbIm1ldGFhcGktYXBpOndzOnB1YmxpYzoqOioiXSwicm9sZXMiOlsicmVhZGVyIiwid3JpdGVyIl0sInJlc291cmNlcyI6WyIqOiRVU0VSX0lEJDoqIl19LHsiaWQiOiJtZXRhc3RhdHMtYXBpIiwibWV0aG9kcyI6WyJtZXRhc3RhdHMtYXBpOnJlc3Q6cHVibGljOio6KiJdLCJyb2xlcyI6WyJyZWFkZXIiLCJ3cml0ZXIiXSwicmVzb3VyY2VzIjpbIio6JFVTRVJfSUQkOioiXX0seyJpZCI6InJpc2stbWFuYWdlbWVudC1hcGkiLCJtZXRob2RzIjpbInJpc2stbWFuYWdlbWVudC1hcGk6cmVzdDpwdWJsaWM6KjoqIl0sInJvbGVzIjpbInJlYWRlciIsIndyaXRlciJdLCJyZXNvdXJjZXMiOlsiKjokVVNFUl9JRCQ6KiJdfSx7ImlkIjoiY29weWZhY3RvcnktYXBpIiwibWV0aG9kcyI6WyJjb3B5ZmFjdG9yeS1hcGk6cmVzdDpwdWJsaWM6KjoqIl0sInJvbGVzIjpbInJlYWRlciIsIndyaXRlciJdLCJyZXNvdXJjZXMiOlsiKjokVVNFUl9JRCQ6KiJdfSx7ImlkIjoibXQtbWFuYWdlci1hcGkiLCJtZXRob2RzIjpbIm10LW1hbmFnZXItYXBpOnJlc3Q6ZGVhbGluZzoqOioiLCJtdC1tYW5hZ2VyLWFwaTpyZXN0OnB1YmxpYzoqOioiXSwicm9sZXMiOlsicmVhZGVyIiwid3JpdGVyIl0sInJlc291cmNlcyI6WyIqOiRVU0VSX0lEJDoqIl19LHsiaWQiOiJiaWxsaW5nLWFwaSIsIm1ldGhvZHMiOlsiYmlsbGluZy1hcGk6cmVzdDpwdWJsaWM6KjoqIl0sInJvbGVzIjpbInJlYWRlciJdLCJyZXNvdXJjZXMiOlsiKjokVVNFUl9JRCQ6KiJdfV0sImlnbm9yZVJhdGVMaW1pdHMiOmZhbHNlLCJ0b2tlbklkIjoiMjAyMTAyMTMiLCJpbXBlcnNvbmF0ZWQiOmZhbHNlLCJyZWFsVXNlcklkIjoiYmIyNTZlMWJkYzhkMGMwNjE1MWQ4OGY5YjQwMzJhY2EiLCJpYXQiOjE3NTI3NjEyOTYsImV4cCI6MTc2NzEyNTI5Nn0.akuwZmxIgbIyHdHUVYbDEXaSlNxiP6bmXCQkPI6Acy6BCjy1pgpD7BWDbhlHDuxfNvn6vJItXwNObIS9irtzvkAAt5H1B28QOzAYoqTFF29Dmmh0PP97awn4D-laBEPzc-qxbpRzQ58tB-VKk-6KZYfsOJz7FjuKHVg7u4luCSRaI7eoSHM1WuHRV_gk8OdvKQIzMdWJEttwdHeFhvJM3D_RgONYDCetnGcdE9QUrw5CEdJuP7nVBCzB3dI0RojxmS71935j98SalkNzyz9pIBeI5l6Z0Y2dD_uwyoGwBJIfEswedELdzCZy_NGNRFHqaEkvdg5wwTGrocMIYMVzu7LHLxV0CvEf2O6c9Hj-kfL3u-6NQZmnEcr47jrhla3G4Gh9mvn0ZdwEV1mLM9tj6kWWdST5JLdohZDij6llgJkjh0IjfhLQ-qzDvUndEfPB-SiM2m0x6UMt3dTWl_NM9p5BkB9ItDVZ-_Ah5JNTxJil-gRr0M95O0NTdDqm8VhAFDlRnFKOirh_Y61ZVkoRuq1VLYqEFiACsjnDemG0P3iUcwqMyYgEW46_eat7ZuFssBUWMftS8RkB2CueRVtqP6Cpi2ZZX2gMfUHBu4Qdv9DMyKBPJ_cVg8WdVXS2zqDYe3_O_pIy70pfaBLDXtRyoAyGkgjunNPxNrEiLcwKMcQ"
        
        static let region = "new-york"
        static let application = "MetaApi"
    }
    
    // Supabase Configuration
    enum Supabase {
        static var url: String {
            configuration.supabaseURL
        }
        
        static var anonKey: String {
            configuration.supabaseAnonKey
        }
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