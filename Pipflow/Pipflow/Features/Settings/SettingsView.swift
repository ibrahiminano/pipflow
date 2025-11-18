//
//  SettingsView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var tradingService = TradingService.shared
    @StateObject private var uiStyleManager = UIStyleManager.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var settingsService = SettingsService.shared
    @StateObject private var tokenService = PIPSTokenService.shared
    
    @State private var showSignOutAlert = false
    @State private var showAccountLinking = false
    @State private var showConnectedAccounts = false
    
    // New Sheet States
    @State private var showingAccountManagement = false
    @State private var showingGeneralPreferences = false
    @State private var showingThemeCustomization = false
    @State private var showingTradingPreferences = false
    @State private var showingNotificationPreferences = false
    @State private var showingPrivacySettings = false
    @State private var showingAbout = false
    @State private var showingARTrading = false
    @State private var showingStrategyBuilder = false
    @State private var showingPIPSWallet = false
    @State private var showingChallenges = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    Button(action: { showingAccountManagement = true }) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                
                                Text(initials)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(authService.currentUser?.name ?? "User")
                                    .font(.bodyLarge)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.Theme.text)
                                
                                Text(authService.currentUser?.email ?? "")
                                    .font(.bodyMedium)
                                    .foregroundColor(Color.Theme.text.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color.Theme.text.opacity(0.3))
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // General Settings
                Section("General") {
                    Button(action: { showingGeneralPreferences = true }) {
                        SettingsRow(
                            icon: "globe",
                            title: "Language & Region",
                            value: settingsService.settings.general.language.displayName,
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showingThemeCustomization = true }) {
                        SettingsRow(
                            icon: "paintbrush",
                            title: "Appearance",
                            value: themeManager.appTheme.displayName,
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showingNotificationPreferences = true }) {
                        SettingsRow(
                            icon: "bell.badge",
                            title: "Notifications",
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Trading Settings
                Section("Trading") {
                    Button(action: { showingTradingPreferences = true }) {
                        SettingsRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Trading Preferences",
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showConnectedAccounts = true }) {
                        SettingsRow(
                            icon: "link",
                            title: "Connected Accounts",
                            value: tradingService.connectedAccounts.isEmpty ? "None" : "\(tradingService.connectedAccounts.count)",
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // PIPS Wallet
                    NavigationLink(destination: PIPSWalletView()) {
                        SettingsRow(
                            icon: "bitcoinsign.circle.fill",
                            title: "PIPS Wallet",
                            value: formatPIPSBalance(),
                            showChevron: true
                        )
                    }
                    
                    // Trading Challenges
                    NavigationLink(destination: ChallengeListView()) {
                        SettingsRow(
                            icon: "trophy.fill",
                            title: "Trading Challenges",
                            value: "Win PIPS",
                            showChevron: true
                        )
                    }
                }
                
                // Privacy & Security
                Section("Privacy & Security") {
                    // Temporarily removed BiometricSetupView to fix rendering issue
                    
                    Button(action: { showingPrivacySettings = true }) {
                        SettingsRow(
                            icon: "hand.raised",
                            title: "Privacy & Data",
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Advanced Features moved here
                    Button(action: { showingARTrading = true }) {
                        SettingsRow(
                            icon: "cube",
                            title: "AR Trading",
                            value: "Beta",
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showingStrategyBuilder = true }) {
                        SettingsRow(
                            icon: "cpu",
                            title: "Strategy Builder",
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Support & About
                Section("Support") {
                    Button(action: { showingAbout = true }) {
                        SettingsRow(
                            icon: "info.circle",
                            title: "About",
                            value: "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")",
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Sign Out
                Section {
                    Button(action: {
                        showSignOutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.medium)
                                .foregroundColor(Color.Theme.error)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                        .sink(receiveValue: { _ in })
                        .store(in: &cancellables)
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            // New Sheets
            .sheet(isPresented: $showingAccountManagement) {
                AccountManagementView()
            }
            .sheet(isPresented: $showingGeneralPreferences) {
                GeneralPreferencesView()
            }
            .sheet(isPresented: $showingThemeCustomization) {
                ThemeCustomizationView()
            }
            .sheet(isPresented: $showingTradingPreferences) {
                TradingPreferencesView()
            }
            .sheet(isPresented: $showingNotificationPreferences) {
                NotificationPreferencesView()
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .fullScreenCover(isPresented: $showingARTrading) {
                ARTradingView()
            }
            .sheet(isPresented: $showingStrategyBuilder) {
                StrategyBuilderView()
            }
            .sheet(isPresented: $showingPIPSWallet) {
                PIPSWalletView()
            }
            .sheet(isPresented: $showingChallenges) {
                ChallengeListView()
            }
            // Existing Sheets
            .sheet(isPresented: $showAccountLinking) {
                AccountLinkingView()
            }
            .sheet(isPresented: $showConnectedAccounts) {
                NavigationView {
                    ConnectedAccountsView()
                }
            }
        }
    }
    
    @State private var cancellables = Set<AnyCancellable>()
    
    private var initials: String {
        let name = authService.currentUser?.name ?? authService.currentUser?.email ?? "U"
        let components = name.components(separatedBy: " ")
        
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
    
    private func formatPIPSBalance() -> String {
        let balance = tokenService.wallet?.balance ?? 0
        return "\(Int(balance)) PIPS"
    }
}

struct ThemeRowView: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: theme.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: theme.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                Text(theme.displayName)
                    .font(.bodyLarge)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.primaryColor)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var showChevron: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.Theme.accent)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(Color.Theme.text)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.bodyMedium)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.3))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}