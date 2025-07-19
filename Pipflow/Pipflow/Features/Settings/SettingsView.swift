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
    @State private var showSignOutAlert = false
    @State private var showAccountLinking = false
    @State private var showConnectedAccounts = false
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
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
                            
                            Text("JD")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("John Doe")
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.Theme.text)
                            
                            Text("john.doe@example.com")
                                .font(.bodyMedium)
                                .foregroundColor(Color.Theme.text.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Appearance Section
                Section("Appearance") {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        ThemeRowView(
                            theme: theme,
                            isSelected: themeManager.appTheme == theme,
                            action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    themeManager.appTheme = theme
                                }
                            }
                        )
                    }
                }
                
                // Trading Settings
                Section("Trading") {
                    SettingsRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Default Chart Type",
                        value: "Candlestick"
                    )
                    
                    SettingsRow(
                        icon: "clock",
                        title: "Default Timeframe",
                        value: "1H"
                    )
                    
                    Toggle(isOn: .constant(true)) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundColor(Color.Theme.accent)
                            Text("Push Notifications")
                                .foregroundColor(Color.Theme.text)
                        }
                    }
                    .tint(Color.Theme.accent)
                }
                
                // Account Settings
                Section("Account") {
                    SettingsRow(
                        icon: "person.crop.circle",
                        title: "Profile",
                        showChevron: true
                    )
                    
                    SettingsRow(
                        icon: "creditcard",
                        title: "Subscription",
                        value: "Pro",
                        showChevron: true
                    )
                    
                    Button(action: {
                        showConnectedAccounts = true
                    }) {
                        SettingsRow(
                            icon: "link",
                            title: "Trading Accounts",
                            value: tradingService.connectedAccounts.isEmpty ? "None" : "\(tradingService.connectedAccounts.count)",
                            showChevron: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Support
                Section("Support") {
                    SettingsRow(
                        icon: "questionmark.circle",
                        title: "Help Center",
                        showChevron: true
                    )
                    
                    SettingsRow(
                        icon: "doc.text",
                        title: "Terms of Service",
                        showChevron: true
                    )
                    
                    SettingsRow(
                        icon: "hand.raised",
                        title: "Privacy Policy",
                        showChevron: true
                    )
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
            .sheet(isPresented: $showAccountLinking) {
                AccountLinkingView()
            }
            .sheet(isPresented: $showConnectedAccounts) {
                ConnectedAccountsView()
            }
        }
    }
    
    @State private var cancellables = Set<AnyCancellable>()
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
        .environmentObject(AuthService.shared)
}