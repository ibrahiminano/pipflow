//
//  NotificationPreferencesView.swift
//  Pipflow
//
//  Notification preferences and settings UI
//

import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var notificationService = NotificationService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingQuietHoursSetup = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // General Settings
                GeneralNotificationSettings(preferences: $notificationService.preferences)
                
                // Notification Types
                NotificationTypeSettings(preferences: $notificationService.preferences)
                
                // Quiet Hours
                QuietHoursSettings(
                    preferences: $notificationService.preferences,
                    showingSetup: $showingQuietHoursSetup
                )
                
                // Priority Settings
                PrioritySettings(preferences: $notificationService.preferences)
                
                // Channel Settings
                ChannelSettings(preferences: $notificationService.preferences)
            }
            .padding()
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingQuietHoursSetup) {
            QuietHoursSetupView(preferences: $notificationService.preferences)
        }
    }
}

// MARK: - General Settings
struct GeneralNotificationSettings: View {
    @Binding var preferences: PipflowNotificationPreferences
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General")
                .font(.headline)
            
            VStack(spacing: 0) {
                // Push Notifications
                SettingsToggleRow(
                    icon: "bell.badge",
                    title: "Push Notifications",
                    subtitle: "Receive alerts when app is closed",
                    isOn: $preferences.enablePushNotifications,
                    onChange: { enabled in
                        if enabled && !notificationService.isAuthorized {
                            Task {
                                await notificationService.requestAuthorization()
                            }
                        }
                    }
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // In-App Notifications
                SettingsToggleRow(
                    icon: "app.badge",
                    title: "In-App Notifications",
                    subtitle: "Show alerts while using the app",
                    isOn: $preferences.enableInAppNotifications
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Email Notifications
                SettingsToggleRow(
                    icon: "envelope",
                    title: "Email Notifications",
                    subtitle: "Important updates via email",
                    isOn: $preferences.enableEmailNotifications
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Sound Alerts
                SettingsToggleRow(
                    icon: "speaker.wave.2",
                    title: "Sound Alerts",
                    subtitle: "Play sounds for notifications",
                    isOn: $preferences.enableSoundAlerts
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Vibration
                SettingsToggleRow(
                    icon: "iphone.radiowaves.left.and.right",
                    title: "Vibration",
                    subtitle: "Vibrate for important alerts",
                    isOn: $preferences.enableVibration
                )
            }
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
    }
}

// MARK: - Notification Type Settings
struct NotificationTypeSettings: View {
    @Binding var preferences: PipflowNotificationPreferences
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notification Types")
                .font(.headline)
            
            VStack(spacing: 0) {
                // Price Alerts
                SettingsToggleRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Price Alerts",
                    subtitle: "Get notified when prices reach targets",
                    isOn: $preferences.priceAlerts
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Trade Notifications
                SettingsToggleRow(
                    icon: "arrow.up.arrow.down.circle",
                    title: "Trade Notifications",
                    subtitle: "Updates on trade execution and closure",
                    isOn: $preferences.tradeNotifications
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Signal Alerts
                SettingsToggleRow(
                    icon: "bell.badge",
                    title: "Signal Alerts",
                    subtitle: "AI-generated trading signals",
                    isOn: $preferences.signalAlerts
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // News Alerts
                SettingsToggleRow(
                    icon: "newspaper",
                    title: "News Alerts",
                    subtitle: "Important market news and events",
                    isOn: $preferences.newsAlerts
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Social Notifications
                SettingsToggleRow(
                    icon: "person.2",
                    title: "Social Notifications",
                    subtitle: "Followers, likes, and comments",
                    isOn: $preferences.socialNotifications
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Achievement Notifications
                SettingsToggleRow(
                    icon: "trophy",
                    title: "Achievements",
                    subtitle: "Unlock rewards and milestones",
                    isOn: $preferences.achievementNotifications
                )
                
                Divider()
                    .padding(.leading, 44)
                
                // Marketing Messages
                SettingsToggleRow(
                    icon: "megaphone",
                    title: "Marketing Messages",
                    subtitle: "Promotions and special offers",
                    isOn: $preferences.marketingMessages
                )
            }
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
    }
}

// MARK: - Quiet Hours Settings
struct QuietHoursSettings: View {
    @Binding var preferences: PipflowNotificationPreferences
    @Binding var showingSetup: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    private var quietHoursText: String {
        guard preferences.quietHoursEnabled,
              let start = preferences.quietHoursStart,
              let end = preferences.quietHoursEnd else {
            return "Off"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quiet Hours")
                .font(.headline)
            
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "moon.fill")
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Do Not Disturb")
                                .font(.bodyMedium)
                            
                            Text("Silence non-urgent notifications")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $preferences.quietHoursEnabled)
                        .labelsHidden()
                }
                .padding()
                
                if preferences.quietHoursEnabled {
                    Divider()
                        .padding(.leading, 44)
                    
                    Button(action: { showingSetup = true }) {
                        HStack {
                            Text("Schedule")
                                .font(.bodyMedium)
                            
                            Spacer()
                            
                            Text(quietHoursText)
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .padding()
                        .padding(.leading, 44)
                    }
                }
            }
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
            
            Text("Urgent notifications will still be delivered during quiet hours")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .padding(.horizontal)
        }
    }
}

// MARK: - Priority Settings
struct PrioritySettings: View {
    @Binding var preferences: PipflowNotificationPreferences
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Minimum Priority")
                .font(.headline)
            
            Text("Only show notifications of this priority or higher")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Picker("Priority", selection: $preferences.minimumPriority) {
                ForEach(NotificationPriority.allCases, id: \.self) { priority in
                    HStack {
                        Circle()
                            .fill(priority.color)
                            .frame(width: 8, height: 8)
                        
                        Text(priority.rawValue.capitalized)
                    }
                    .tag(priority)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

// MARK: - Channel Settings
struct ChannelSettings: View {
    @Binding var preferences: PipflowNotificationPreferences
    @EnvironmentObject var themeManager: ThemeManager
    @State private var testChannel: NotificationChannel = .push
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Test Notifications")
                    .font(.headline)
                
                Spacer()
                
                Button(action: sendTestNotification) {
                    Text("Send Test")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.currentTheme.accentColor)
                        .cornerRadius(6)
                }
            }
            
            Picker("Channel", selection: $testChannel) {
                ForEach(NotificationChannel.allCases, id: \.self) { channel in
                    Text(channel.displayName).tag(channel)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private func sendTestNotification() {
        let notification = PipflowNotification(
            type: .systemMessage,
            title: "Test Notification",
            message: "This is a test notification from Pipflow",
            priority: .medium
        )
        
        NotificationService.shared.sendNotification(notification)
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)? = nil
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.bodyMedium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { newValue in
                    onChange?(newValue)
                }
        }
        .padding()
    }
}

// MARK: - Quiet Hours Setup View
struct QuietHoursSetupView: View {
    @Binding var preferences: PipflowNotificationPreferences
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set your quiet hours to silence non-urgent notifications during specific times")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Start Time", systemImage: "moon")
                            .font(.bodyMedium)
                        
                        DatePicker(
                            "",
                            selection: $startTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("End Time", systemImage: "sun.max")
                            .font(.bodyMedium)
                        
                        DatePicker(
                            "",
                            selection: $endTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                    }
                }
                .padding()
                .background(themeManager.currentTheme.secondaryBackgroundColor)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Quiet Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        preferences.quietHoursStart = startTime
                        preferences.quietHoursEnd = endTime
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            startTime = preferences.quietHoursStart ?? Date()
            endTime = preferences.quietHoursEnd ?? Date().addingTimeInterval(28800) // 8 hours later
        }
    }
}

#Preview {
    NavigationView {
        NotificationPreferencesView()
            .environmentObject(ThemeManager())
    }
}