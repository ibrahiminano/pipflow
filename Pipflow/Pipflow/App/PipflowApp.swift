//
//  PipflowApp.swift
//  Pipflow
//
//  Created by inano on 18/07/2025.
//

import SwiftUI
import Combine

@main
struct PipflowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(themeManager)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isAuthenticated = true // Bypass auth for demo
    @State private var hasSeenOnboarding = true // Bypass onboarding for demo
    
    var body: some View {
        Group {
            if isAuthenticated {
                ContentView()
            } else if hasSeenOnboarding {
                AuthenticationView()
            } else {
                OnboardingView()
            }
        }
        .onReceive(authService.isAuthenticated) { authenticated in
            // Commented out for demo - keeping isAuthenticated = true
            // withAnimation(.easeInOut(duration: 0.5)) {
            //     isAuthenticated = authenticated
            // }
        }
        .onAppear {
            // Check if user has seen onboarding
            hasSeenOnboarding = UserDefaults.standard.bool(forKey: "has_seen_onboarding")
            
            // Auto-login if tokens exist
            authService.getCurrentUser()
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}
