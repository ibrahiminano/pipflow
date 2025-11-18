//
//  AuthenticationView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI
import Combine

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isSignUp = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isSignUp {
                    RegisterView()
                        .environmentObject(themeManager)
                } else {
                    LoginView()
                        .environmentObject(themeManager)
                }
                
                // Toggle Sign In/Sign Up
                HStack {
                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                        }
                    }) {
                        Text(isSignUp ? "Sign In" : "Sign Up")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(themeManager.currentTheme.backgroundColor)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthService.shared)
        .environmentObject(ThemeManager())
}