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
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Welcome to Pipflow")
                            .font(.title1)
                            .fontWeight(.bold)
                            .foregroundColor(Color.Theme.text)
                        
                        Text(isSignUp ? "Create your account" : "Sign in to continue")
                            .font(.bodyLarge)
                            .foregroundColor(Color.Theme.text.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(Color.Theme.text)
                            
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.Theme.cardBackground)
                                .cornerRadius(.smallCornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: .smallCornerRadius)
                                        .stroke(Color.Theme.divider, lineWidth: 1)
                                )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(Color.Theme.text)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                        .textContentType(.password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(.password)
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(Color.Theme.text.opacity(0.5))
                                }
                            }
                            .padding()
                            .background(Color.Theme.cardBackground)
                            .cornerRadius(.smallCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: .smallCornerRadius)
                                    .stroke(Color.Theme.divider, lineWidth: 1)
                            )
                        }
                        
                        // Confirm Password (Sign Up only)
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.bodyMedium)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.Theme.text)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.password)
                                    .padding()
                                    .background(Color.Theme.cardBackground)
                                    .cornerRadius(.smallCornerRadius)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: .smallCornerRadius)
                                            .stroke(Color.Theme.divider, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Forgot Password (Sign In only)
                    if !isSignUp {
                        Button(action: {
                            // Handle forgot password
                        }) {
                            Text("Forgot Password?")
                                .font(.bodyMedium)
                                .foregroundColor(Color.Theme.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                    }
                    
                    // Action Button
                    Button(action: {
                        handleAuthentication()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                            }
                        }
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(.cornerRadius)
                        .shadow(color: Color.Theme.shadow, radius: 8, x: 0, y: 4)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    
                    // Social Login
                    VStack(spacing: 16) {
                        HStack {
                            Rectangle()
                                .fill(Color.Theme.divider)
                                .frame(height: 1)
                            
                            Text("or")
                                .font(.bodyMedium)
                                .foregroundColor(Color.Theme.text.opacity(0.5))
                            
                            Rectangle()
                                .fill(Color.Theme.divider)
                                .frame(height: 1)
                        }
                        
                        HStack(spacing: 16) {
                            SocialLoginButton(
                                icon: "apple.logo",
                                title: "Apple",
                                action: {
                                    // Handle Apple login
                                }
                            )
                            
                            SocialLoginButton(
                                icon: "g.circle.fill",
                                title: "Google",
                                action: {
                                    // Handle Google login
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Toggle Sign In/Sign Up
                    HStack {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .font(.bodyMedium)
                            .foregroundColor(Color.Theme.text.opacity(0.7))
                        
                        Button(action: {
                            withAnimation {
                                isSignUp.toggle()
                                clearForm()
                            }
                        }) {
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .font(.bodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.Theme.accent)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Color.Theme.background)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAuthentication() {
        guard validateForm() else { return }
        
        isLoading = true
        
        // Create a mock successful authentication
        let mockUser = User(
            id: UUID(),
            email: email,
            username: "johndoe",
            firstName: "John",
            lastName: "Doe",
            avatarURL: nil,
            tradingAccounts: [],
            walletBalance: 10000,
            tier: .pro,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Mark onboarding as seen
        UserDefaults.standard.set(true, forKey: "has_seen_onboarding")
        
        // Update the auth service directly
        authService.currentUserSubject.send(mockUser)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
        }
    }
    
    private func validateForm() -> Bool {
        if email.isEmpty || password.isEmpty {
            showError(message: "Please fill in all fields")
            return false
        }
        
        if !email.contains("@") {
            showError(message: "Please enter a valid email")
            return false
        }
        
        if password.count < 8 {
            showError(message: "Password must be at least 8 characters")
            return false
        }
        
        if isSignUp && password != confirmPassword {
            showError(message: "Passwords don't match")
            return false
        }
        
        return true
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
    }
}

struct SocialLoginButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
            }
            .foregroundColor(Color.Theme.text)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.Theme.cardBackground)
            .cornerRadius(.smallCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: .smallCornerRadius)
                    .stroke(Color.Theme.divider, lineWidth: 1)
            )
        }
    }
}

#Preview {
    AuthenticationView()
}