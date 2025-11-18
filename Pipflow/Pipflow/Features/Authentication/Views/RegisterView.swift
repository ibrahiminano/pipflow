//
//  RegisterView.swift
//  Pipflow
//
//  Registration screen for new users
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var focusedField: Field?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false
    
    enum Field {
        case fullName
        case email
        case password
        case confirmPassword
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
                    
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Start your trading journey")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .padding(.top, 20)
                
                // Form Fields
                VStack(spacing: 16) {
                    // Full Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            TextField("Enter your full name", text: $viewModel.fullName)
                                .textFieldStyle(.plain)
                                .textContentType(.name)
                                .focused($focusedField, equals: .fullName)
                                .foregroundColor(themeManager.currentTheme.textColor)
                        }
                        .padding()
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    focusedField == .fullName ? themeManager.currentTheme.accentColor : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        
                        if !viewModel.fullName.isEmpty && !viewModel.isFullNameValid {
                            Text("Name must be at least 2 characters")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
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
                                TextField("Create a password", text: $viewModel.password)
                                    .textFieldStyle(.plain)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .password)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                            } else {
                                SecureField("Create a password", text: $viewModel.password)
                                    .textFieldStyle(.plain)
                                    .textContentType(.newPassword)
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
                        
                        // Password Strength Indicator
                        if !viewModel.password.isEmpty {
                            HStack {
                                Text("Password Strength:")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                
                                Text(viewModel.passwordStrength.description)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(viewModel.passwordStrength.color)
                                
                                Spacer()
                            }
                            
                            // Password Requirements
                            VStack(alignment: .leading, spacing: 4) {
                                PasswordRequirement(
                                    text: "At least 8 characters",
                                    isMet: viewModel.password.count >= 8
                                )
                                PasswordRequirement(
                                    text: "Contains uppercase letter",
                                    isMet: viewModel.password.contains(where: { $0.isUppercase })
                                )
                                PasswordRequirement(
                                    text: "Contains lowercase letter",
                                    isMet: viewModel.password.contains(where: { $0.isLowercase })
                                )
                                PasswordRequirement(
                                    text: "Contains number",
                                    isMet: viewModel.password.contains(where: { $0.isNumber })
                                )
                            }
                        }
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            if showConfirmPassword {
                                TextField("Confirm your password", text: $viewModel.confirmPassword)
                                    .textFieldStyle(.plain)
                                    .focused($focusedField, equals: .confirmPassword)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                            } else {
                                SecureField("Confirm your password", text: $viewModel.confirmPassword)
                                    .textFieldStyle(.plain)
                                    .focused($focusedField, equals: .confirmPassword)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    focusedField == .confirmPassword ? themeManager.currentTheme.accentColor : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        
                        if !viewModel.confirmPassword.isEmpty && !viewModel.isConfirmPasswordValid {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Terms and Conditions
                    HStack {
                        Button(action: { agreedToTerms.toggle() }) {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(agreedToTerms ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryTextColor)
                        }
                        
                        Text("I agree to the ")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        +
                        Text("Terms of Service")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .underline()
                        +
                        Text(" and ")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        +
                        Text("Privacy Policy")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .underline()
                        
                        Spacer()
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
                
                // Register Button
                Button(action: {
                    Task {
                        await viewModel.register()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        viewModel.isRegisterFormValid && agreedToTerms ?
                        themeManager.currentTheme.accentColor :
                        themeManager.currentTheme.accentColor.opacity(0.5)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isRegisterFormValid || !agreedToTerms || viewModel.isLoading)
                .padding(.horizontal)
                
                // Social Sign Up
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
                    
                    // Apple Sign Up
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
                    
                    // Google Sign Up
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
                
                Spacer(minLength: 40)
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .onTapGesture {
            focusedField = nil
        }
    }
}

// MARK: - Password Requirement View
struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isMet ? .green : Color.secondary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? Color.primary : Color.secondary)
                .strikethrough(isMet)
            
            Spacer()
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(ThemeManager())
}