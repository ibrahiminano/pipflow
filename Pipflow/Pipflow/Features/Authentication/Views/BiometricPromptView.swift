//
//  BiometricPromptView.swift
//  Pipflow
//
//  Custom biometric authentication prompt with fallback options
//

import SwiftUI

struct BiometricPromptView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    let onAuthenticate: () async -> Void
    let onUseFallback: () -> Void
    
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: BiometricService.shared.biometricType.systemImageName)
                .font(.system(size: 80))
                .foregroundColor(themeManager.currentTheme.accentColor)
                .padding(.top, 40)
            
            // Title
            Text("Authenticate to Continue")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            // Message
            Text("Use \(BiometricService.shared.biometricType.displayName) to quickly and securely access your account")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Buttons
            VStack(spacing: 12) {
                // Authenticate button
                Button(action: {
                    Task {
                        await authenticate()
                    }
                }) {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: BiometricService.shared.biometricType.systemImageName)
                            Text("Use \(BiometricService.shared.biometricType.displayName)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isAuthenticating)
                
                // Use password button
                Button(action: {
                    isPresented = false
                    onUseFallback()
                }) {
                    Text("Use Password Instead")
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
                
                // Cancel button
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: 400)
        .background(themeManager.currentTheme.backgroundColor)
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding()
    }
    
    private func authenticate() async {
        isAuthenticating = true
        errorMessage = nil
        
        do {
            try await BiometricService.shared.authenticateForLogin()
            await onAuthenticate()
            isPresented = false
        } catch let error as BiometricError {
            errorMessage = error.localizedDescription
            
            // Auto-dismiss for certain errors
            if case .userCancel = error {
                isPresented = false
            }
        } catch {
            errorMessage = "Authentication failed"
        }
        
        isAuthenticating = false
    }
}

// MARK: - Biometric Setup View
struct BiometricSetupView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var biometricService = BiometricService.shared
    @State private var showingEnablePrompt = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(biometricService.biometricType.displayName)
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text(biometricService.isAvailable ? "Available for quick login" : "Not available on this device")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                if biometricService.isAvailable {
                    Toggle("", isOn: Binding(
                        get: { biometricService.isEnabled },
                        set: { newValue in
                            if newValue {
                                showingEnablePrompt = true
                            } else {
                                biometricService.disableBiometric()
                            }
                        }
                    ))
                    .tint(themeManager.currentTheme.accentColor)
                }
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            // Info text
            if biometricService.isEnabled {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    
                    Text("Your credentials are securely stored in the device keychain and protected by \(biometricService.biometricType.displayName)")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .padding()
                .background(themeManager.currentTheme.accentColor.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showingEnablePrompt) {
            BiometricEnablePromptView(
                isPresented: $showingEnablePrompt,
                errorMessage: $errorMessage
            )
            .environmentObject(themeManager)
        }
    }
}

// MARK: - Enable Prompt
struct BiometricEnablePromptView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    @Binding var errorMessage: String?
    @State private var isEnabling = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.accentColor)
                .padding(.top, 40)
            
            // Title
            Text("Enable \(BiometricService.shared.biometricType.displayName)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            // Message
            VStack(spacing: 16) {
                Text("Authenticate to enable biometric login")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text("Your login credentials will be securely stored in the device keychain")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await enableBiometric()
                    }
                }) {
                    HStack {
                        if isEnabling {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Enable")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isEnabling)
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: 400)
        .background(themeManager.currentTheme.backgroundColor)
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding()
    }
    
    private func enableBiometric() async {
        isEnabling = true
        errorMessage = nil
        
        do {
            try await BiometricService.shared.enableBiometric()
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
            isPresented = false
        }
        
        isEnabling = false
    }
}

#Preview {
    BiometricSetupView()
        .environmentObject(ThemeManager())
}