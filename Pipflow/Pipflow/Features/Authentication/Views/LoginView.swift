//
//  LoginView.swift
//  Pipflow
//
//  Login screen for user authentication
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var focusedField: Field?
    @State private var showPassword = false
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Sign in to continue trading")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .padding(.top, 40)
                
                // Form Fields
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            TextField("Enter your email", text: $viewModel.email)
                                .textFieldStyle(.plain)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .focused($focusedField, equals: .email)
                                .foregroundColor(themeManager.currentTheme.textColor)
                        }
                        .padding()
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    focusedField == .email ? themeManager.currentTheme.accentColor : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        
                        if !viewModel.email.isEmpty && !viewModel.isEmailValid {
                            Text("Please enter a valid email")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            if showPassword {
                                TextField("Enter your password", text: $viewModel.password)
                                    .textFieldStyle(.plain)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                            } else {
                                SecureField("Enter your password", text: $viewModel.password)
                                    .textFieldStyle(.plain)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    focusedField == .password ? themeManager.currentTheme.accentColor : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button(action: { viewModel.showForgotPassword = true }) {
                            Text("Forgot Password?")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Login Button
                Button(action: {
                    Task {
                        await viewModel.login()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        viewModel.isLoginFormValid ?
                        themeManager.currentTheme.accentColor :
                        themeManager.currentTheme.accentColor.opacity(0.5)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isLoginFormValid || viewModel.isLoading)
                .padding(.horizontal)
                
                // Social Login
                VStack(spacing: 16) {
                    HStack {
                        Rectangle()
                            .fill(themeManager.currentTheme.separatorColor)
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .padding(.horizontal, 8)
                        
                        Rectangle()
                            .fill(themeManager.currentTheme.separatorColor)
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    
                    // Apple Sign In
                    Button(action: {
                        Task {
                            await viewModel.loginWithApple()
                        }
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Continue with Apple")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.currentTheme.textColor)
                        .foregroundColor(themeManager.currentTheme.backgroundColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Google Sign In
                    Button(action: {
                        Task {
                            await viewModel.loginWithGoogle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Continue with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager.currentTheme.separatorColor, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
                
                // Biometric Login (if available)
                if BiometricService.shared.isAvailable && BiometricService.shared.isEnabled {
                    Button(action: {
                        Task {
                            await viewModel.loginWithBiometric()
                        }
                    }) {
                        HStack {
                            Image(systemName: BiometricService.shared.biometricType.systemImageName)
                                .font(.title2)
                            Text("Login with \(BiometricService.shared.biometricType.displayName)")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.currentTheme.accentColor.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(themeManager.currentTheme.accentColor, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .onTapGesture {
            focusedField = nil
        }
        .sheet(isPresented: $viewModel.showForgotPassword) {
            ForgotPasswordView(viewModel: viewModel)
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    
                    Text("Reset Password")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Enter your email and we'll send you a reset link")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        TextField("Enter your email", text: $viewModel.resetEmail)
                            .textFieldStyle(.plain)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Error/Success Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(errorMessage.contains("sent") ? .green : .red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Send Reset Email Button
                Button(action: {
                    Task {
                        await viewModel.forgotPassword()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Send Reset Email")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.resetEmail.isEmpty || viewModel.isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(themeManager.currentTheme.accentColor)
            )
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(ThemeManager())
}