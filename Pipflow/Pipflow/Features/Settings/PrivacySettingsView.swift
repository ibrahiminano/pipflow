//
//  PrivacySettingsView.swift
//  Pipflow
//
//  Privacy and data settings management
//

import SwiftUI

struct PrivacySettingsView: View {
    @StateObject private var settingsService = SettingsService.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var biometricService = BiometricService.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var shareAnalytics: Bool
    @State private var shareCrashReports: Bool
    @State private var shareUsageData: Bool
    @State private var sharePerformance: Bool
    @State private var publicProfile: Bool
    @State private var showOnlineStatus: Bool
    @State private var allowDirectMessages: Bool
    @State private var hideBalances: Bool
    @State private var requireBiometric: Bool
    @State private var biometricForTrades: Bool
    @State private var encryptLocalData: Bool
    @State private var encryptCloudData: Bool
    @State private var requireBiometricForTrades: Bool
    @State private var dataRetentionDays: Int
    @State private var retentionDays: Int
    @State private var retentionDaysText: String
    
    @State private var showSaveAlert = false
    @State private var showExportDataAlert = false
    @State private var showClearCacheAlert = false
    @State private var showDeleteAccountAlert = false
    
    init() {
        let privacy = SettingsService.shared.settings.privacy
        
        _shareAnalytics = State(initialValue: privacy.shareAnalytics)
        _shareCrashReports = State(initialValue: false)
        _shareUsageData = State(initialValue: false)
        _sharePerformance = State(initialValue: privacy.sharePerformance)
        _publicProfile = State(initialValue: privacy.publicProfile)
        _showOnlineStatus = State(initialValue: privacy.showOnlineStatus)
        _allowDirectMessages = State(initialValue: privacy.allowDirectMessages)
        _hideBalances = State(initialValue: privacy.hideBalances)
        _requireBiometric = State(initialValue: false)
        _biometricForTrades = State(initialValue: false)
        _encryptLocalData = State(initialValue: false)
        _encryptCloudData = State(initialValue: false)
        _requireBiometricForTrades = State(initialValue: privacy.requireBiometricForTrades)
        _dataRetentionDays = State(initialValue: privacy.dataRetentionDays)
        _retentionDays = State(initialValue: privacy.dataRetentionDays)
        _retentionDaysText = State(initialValue: String(privacy.dataRetentionDays))
    }
    
    var body: some View {
        NavigationView {
            List {
                dataSharingSection
                biometricSection
                encryptionSection
                dataRetentionSection
                permissionsSection
                deleteAccountSection
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Privacy Settings Updated", isPresented: $showSaveAlert) {
                Button("OK") {}
            } message: {
                Text("Your privacy settings have been saved successfully.")
            }
        }
    }
    
    private var dataSharingSection: some View {
        Section {
            Toggle(isOn: $shareAnalytics) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Share Analytics", systemImage: "chart.bar.xaxis")
                    Text("Help improve Pipflow by sharing anonymous usage data")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
            
            Toggle(isOn: $sharePerformance) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Share Trading Performance", systemImage: "chart.line.uptrend.xyaxis")
                    Text("Contribute to community insights with anonymous performance data")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
        } header: {
            Text("Data Sharing")
        } footer: {
            Text("Your personal information is never shared. Only aggregated, anonymous data is used.")
        }
    }
    
    private var biometricSection: some View {
        Section {
            Toggle(isOn: $publicProfile) {
                Label("Public Profile", systemImage: "person.circle")
            }
            
            Toggle(isOn: $showOnlineStatus) {
                Label("Show Online Status", systemImage: "circle.fill")
            }
            .disabled(!publicProfile)
            
            Toggle(isOn: $allowDirectMessages) {
                Label("Allow Direct Messages", systemImage: "message")
            }
            .disabled(!publicProfile)
        } header: {
            Text("Social Privacy")
        } footer: {
            Text(publicProfile ? "Other traders can view your profile and trading statistics" : "Your profile is private and not visible to other traders")
        }
    }
    
    private var encryptionSection: some View {
        Section {
            Toggle(isOn: $hideBalances) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Hide Balances", systemImage: "eye.slash")
                    Text("Replace balance amounts with ••••")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
            
            if biometricService.isAvailable {
                Toggle(isOn: $requireBiometricForTrades) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Require Biometric for Trades", systemImage: "faceid")
                        Text("Additional security for trade execution")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                }
                .disabled(!biometricService.isEnabled)
            }
        } header: {
            Text("Security")
        } footer: {
            if !biometricService.isEnabled && biometricService.isAvailable {
                Text("Enable biometric authentication in settings to use this feature")
            }
        }
    }
    
    private var dataRetentionSection: some View {
        Section {
            HStack {
                Label("Data Retention", systemImage: "clock.arrow.circlepath")
                Spacer()
                TextField("365", text: $retentionDaysText)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .onChange(of: retentionDaysText) { newValue in
                        if let value = Int(newValue), value > 0 {
                            dataRetentionDays = value
                        }
                    }
                Text("days")
                    .foregroundColor(Color.Theme.secondaryText)
            }
            
            Button(action: { showExportDataAlert = true }) {
                Label("Export My Data", systemImage: "square.and.arrow.up")
                    .foregroundColor(Color.Theme.accent)
            }
            
            Button(action: { showClearCacheAlert = true }) {
                HStack {
                    Label("Clear Cache", systemImage: "trash")
                    Spacer()
                    Text(settingsService.getCacheSize())
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
            .foregroundColor(Color.Theme.accent)
        } header: {
            Text("Data Management")
        } footer: {
            Text("Trade history older than retention period will be automatically removed")
        }
    }
    
    private var permissionsSection: some View {
        Section {
            NavigationLink(destination: Text("App Permissions")) {
                Label("App Permissions", systemImage: "checkmark.shield")
            }
            
            NavigationLink(destination: Text("Location Settings")) {
                Label("Location Settings", systemImage: "location")
            }
            
            NavigationLink(destination: Text("Camera & Microphone")) {
                Label("Camera & Microphone", systemImage: "camera")
            }
        } header: {
            Text("Permissions")
        }
    }
    
    private var deleteAccountSection: some View {
        Section {
            Button(action: {
                showDeleteAccountAlert = true
            }) {
                Label("Delete Account", systemImage: "trash")
                    .foregroundColor(.red)
            }
        } header: {
            Text("Danger Zone")
                .foregroundColor(.red)
        } footer: {
            Text("⚠️ This action is permanent and cannot be undone. All your data will be deleted.")
                .foregroundColor(.red)
        }
        .alert("Export Data", isPresented: $showExportDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Export") {
                exportUserData()
            }
        } message: {
            Text("Your data will be exported in JSON format and available for download.")
        }
        .alert("Clear Cache", isPresented: $showClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                settingsService.clearCache()
            }
        } message: {
            Text("This will clear all cached data including images and temporary files.")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you absolutely sure? This action cannot be undone. All your data, trading history, and settings will be permanently deleted.")
        }
    }
    
    private func saveSettings() {
        // Save privacy settings
        showSaveAlert = true
    }
    
    private func exportUserData() {
        // Export user data functionality
    }
    
    private func deleteAccount() {
        // In a real app, this would trigger account deletion
        Task {
            do {
                try await authService.deleteAccount()
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - BiometricService Extension
extension BiometricService {
    var biometricTypeString: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .none:
            return "Biometrics"
        @unknown default:
            return "Biometrics"
        }
    }
}

#Preview {
    PrivacySettingsView()
}