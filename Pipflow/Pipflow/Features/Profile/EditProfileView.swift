//
//  EditProfileView.swift
//  Pipflow
//
//  Edit profile interface
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileService = UserProfileService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var displayName = ""
    @State private var bio = ""
    @State private var location = ""
    @State private var website = ""
    @State private var selectedTradingStyle: TradingStyle = .dayTrading
    @State private var selectedRiskLevel: RiskLevel = .moderate
    @State private var selectedMarkets: Set<String> = []
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoading = false
    
    let availableMarkets = ["Forex", "Crypto", "Stocks", "Commodities", "Indices"]
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Photo Section
                Section {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            ProfileImageView(
                                profile: profileService.currentUserProfile,
                                size: 100
                            )
                            
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images
                            ) {
                                Text("Change Photo")
                                    .font(.bodyMedium)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
                .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                
                // Basic Information
                Section(header: Text("Basic Information")) {
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        TextEditor(text: $bio)
                            .frame(minHeight: 80)
                            .background(Color.clear)
                    }
                    
                    TextField("Location", text: $location)
                        .textFieldStyle(.plain)
                    
                    TextField("Website", text: $website)
                        .textFieldStyle(.plain)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                
                // Trading Information
                Section(header: Text("Trading Information")) {
                    Picker("Trading Style", selection: $selectedTradingStyle) {
                        ForEach(TradingStyle.allCases, id: \.self) { style in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.rawValue)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            .tag(style)
                        }
                    }
                    
                    Picker("Risk Level", selection: $selectedRiskLevel) {
                        ForEach(RiskLevel.allCases, id: \.self) { level in
                            HStack {
                                Image(systemName: level.icon)
                                    .foregroundColor(level.color)
                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred Markets")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(availableMarkets, id: \.self) { market in
                                MarketSelectionChip(
                                    market: market,
                                    isSelected: selectedMarkets.contains(market),
                                    action: {
                                        if selectedMarkets.contains(market) {
                                            selectedMarkets.remove(market)
                                        } else {
                                            selectedMarkets.insert(market)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView("Saving...")
                                .padding()
                                .background(themeManager.currentTheme.secondaryBackgroundColor)
                                .cornerRadius(12)
                        )
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    private func loadCurrentProfile() {
        guard let profile = profileService.currentUserProfile else { return }
        
        displayName = profile.displayName
        bio = profile.bio ?? ""
        location = profile.location ?? ""
        website = profile.website ?? ""
        selectedTradingStyle = profile.tradingStyle
        selectedRiskLevel = profile.riskLevel
        selectedMarkets = Set(profile.preferredMarkets)
    }
    
    private func saveProfile() {
        isLoading = true
        
        Task {
            do {
                let updates = ProfileUpdates(
                    displayName: displayName,
                    bio: bio.isEmpty ? nil : bio,
                    location: location.isEmpty ? nil : location,
                    website: website.isEmpty ? nil : website,
                    tradingStyle: selectedTradingStyle,
                    riskLevel: selectedRiskLevel,
                    preferredMarkets: Array(selectedMarkets)
                )
                
                try await profileService.updateProfile(updates)
                dismiss()
            } catch {
                print("Error saving profile: \(error)")
            }
            
            isLoading = false
        }
    }
}

// MARK: - Market Selection Chip
struct MarketSelectionChip: View {
    let market: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(market)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(
                    isSelected
                        ? .white
                        : themeManager.currentTheme.textColor
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? themeManager.currentTheme.accentColor
                        : themeManager.currentTheme.backgroundColor
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected
                                ? Color.clear
                                : themeManager.currentTheme.separatorColor,
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Profile Settings View
struct ProfileSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileService = UserProfileService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingPrivacySettings = false
    @State private var showingNotificationSettings = false
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section(header: Text("Account")) {
                    NavigationLink(destination: EditProfileView()) {
                        Label("Edit Profile", systemImage: "person.circle")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Verification", systemImage: "checkmark.seal")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Subscription", systemImage: "crown")
                    }
                }
                .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                
                // Privacy & Security
                Section(header: Text("Privacy & Security")) {
                    Button(action: { showingPrivacySettings = true }) {
                        Label("Privacy Settings", systemImage: "lock")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Blocked Users", systemImage: "person.crop.circle.badge.xmark")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Two-Factor Authentication", systemImage: "lock.shield")
                    }
                }
                .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                
                // Notifications
                Section(header: Text("Notifications")) {
                    Button(action: { showingNotificationSettings = true }) {
                        Label("Notification Preferences", systemImage: "bell")
                    }
                }
                .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                
                // Data & Storage
                Section(header: Text("Data & Storage")) {
                    NavigationLink(destination: EmptyView()) {
                        Label("Data Export", systemImage: "square.and.arrow.down")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Clear Cache", systemImage: "trash")
                    }
                }
                .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                
                // Support
                Section(header: Text("Support")) {
                    NavigationLink(destination: EmptyView()) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                }
                .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                
                // Danger Zone
                Section {
                    Button(action: {}) {
                        Label("Sign Out", systemImage: "arrow.left.square")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {}) {
                        Label("Delete Account", systemImage: "xmark.circle")
                            .foregroundColor(.red)
                    }
                }
                .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPrivacySettings) {
            ProfilePrivacySettingsView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
    }
}

// MARK: - Privacy Settings View
struct ProfilePrivacySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileService = UserProfileService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var settings: PrivacySettings
    
    init() {
        _settings = State(initialValue: UserProfileService.shared.currentUserProfile?.privacy ?? PrivacySettings(
            profileVisibility: .everyone,
            showTradingStats: true,
            showFollowers: true,
            allowDirectMessages: .followersOnly,
            allowCopyTrading: true,
            hideFromSearch: false,
            showOnlineStatus: true
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Visibility")) {
                    Picker("Who can see your profile", selection: $settings.profileVisibility) {
                        ForEach(PrivacySettings.ProfileVisibility.allCases, id: \.self) { visibility in
                            Text(visibility.rawValue).tag(visibility)
                        }
                    }
                    
                    Toggle("Show Trading Stats", isOn: $settings.showTradingStats)
                    Toggle("Show Followers List", isOn: $settings.showFollowers)
                    Toggle("Hide from Search", isOn: $settings.hideFromSearch)
                    Toggle("Show Online Status", isOn: $settings.showOnlineStatus)
                }
                
                Section(header: Text("Communication")) {
                    Picker("Who can message you", selection: $settings.allowDirectMessages) {
                        ForEach(PrivacySettings.MessagePrivacy.allCases, id: \.self) { privacy in
                            Text(privacy.rawValue).tag(privacy)
                        }
                    }
                }
                
                Section(header: Text("Trading")) {
                    Toggle("Allow Copy Trading", isOn: $settings.allowCopyTrading)
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            try await profileService.updatePrivacySettings(settings)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileService = UserProfileService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var settings: NotificationSettings
    
    init() {
        _settings = State(initialValue: UserProfileService.shared.currentUserProfile?.notifications ?? NotificationSettings(
            tradeExecuted: true,
            priceAlerts: true,
            positionUpdates: true,
            marketNews: true,
            newFollower: true,
            mentions: true,
            directMessages: true,
            comments: true,
            likes: false,
            newLessons: true,
            achievementUnlocked: true,
            courseUpdates: false,
            systemUpdates: true,
            promotions: false,
            weeklyReport: true
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trading")) {
                    Toggle("Trade Executed", isOn: $settings.tradeExecuted)
                    Toggle("Price Alerts", isOn: $settings.priceAlerts)
                    Toggle("Position Updates", isOn: $settings.positionUpdates)
                    Toggle("Market News", isOn: $settings.marketNews)
                }
                
                Section(header: Text("Social")) {
                    Toggle("New Follower", isOn: $settings.newFollower)
                    Toggle("Mentions", isOn: $settings.mentions)
                    Toggle("Direct Messages", isOn: $settings.directMessages)
                    Toggle("Comments", isOn: $settings.comments)
                    Toggle("Likes", isOn: $settings.likes)
                }
                
                Section(header: Text("Education")) {
                    Toggle("New Lessons", isOn: $settings.newLessons)
                    Toggle("Achievement Unlocked", isOn: $settings.achievementUnlocked)
                    Toggle("Course Updates", isOn: $settings.courseUpdates)
                }
                
                Section(header: Text("System")) {
                    Toggle("System Updates", isOn: $settings.systemUpdates)
                    Toggle("Promotions", isOn: $settings.promotions)
                    Toggle("Weekly Report", isOn: $settings.weeklyReport)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            try await profileService.updateNotificationSettings(settings)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}