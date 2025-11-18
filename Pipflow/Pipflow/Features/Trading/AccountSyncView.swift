//
//  AccountSyncView.swift
//  Pipflow
//
//  Account synchronization UI component
//

import SwiftUI

struct AccountSyncView: View {
    @StateObject private var syncService = AccountSyncService.shared
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Sync Status Card
            SyncStatusCard(
                syncStatus: syncService.syncStatus,
                lastSyncTime: syncService.timeSinceLastSync,
                syncProgress: syncService.syncProgress,
                onRefresh: {
                    Task {
                        await syncService.syncAccount()
                    }
                },
                onSettings: {
                    showSettings = true
                }
            )
        }
        .sheet(isPresented: $showSettings) {
            SyncSettingsView()
        }
    }
}

struct SyncStatusCard: View {
    let syncStatus: SyncStatus
    let lastSyncTime: String?
    let syncProgress: Double
    let onRefresh: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Account Sync")
                        .font(.headline)
                        .foregroundColor(Color.Theme.text)
                    
                    if let lastSync = lastSyncTime {
                        Text("Last synced \(lastSync)")
                            .font(.caption)
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                    } else {
                        Text("Never synced")
                            .font(.caption)
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onSettings) {
                        Image(systemName: "gearshape")
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                    }
                    
                    Button(action: onRefresh) {
                        HStack(spacing: 6) {
                            if case .syncing = syncStatus {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Sync")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .disabled(syncStatus.isActive)
                }
            }
            
            // Progress bar for syncing state
            if case .syncing = syncStatus {
                VStack(spacing: 8) {
                    ProgressView(value: syncProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                    
                    Text(getSyncStatusText())
                        .font(.caption2)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
            }
            
            // Error state
            if case .failed(let error) = syncStatus {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text("Sync failed: \(error.localizedDescription)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
    }
    
    private func getSyncStatusText() -> String {
        let percentage = Int(syncProgress * 100)
        
        switch syncProgress {
        case 0..<0.2:
            return "Connecting..."
        case 0.2..<0.4:
            return "Syncing account info... \(percentage)%"
        case 0.4..<0.6:
            return "Syncing positions... \(percentage)%"
        case 0.6..<0.8:
            return "Syncing orders... \(percentage)%"
        case 0.8..<1.0:
            return "Finalizing... \(percentage)%"
        default:
            return "Complete"
        }
    }
}

struct SyncSettingsView: View {
    @StateObject private var syncService = AccountSyncService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var settings: AccountSyncSettings = AccountSyncSettings()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Auto Sync")) {
                    Toggle("Enable Auto Sync", isOn: $settings.isAutoSyncEnabled)
                    
                    if settings.isAutoSyncEnabled {
                        HStack {
                            Text("Sync Interval")
                            Spacer()
                            Picker("", selection: $settings.syncInterval) {
                                Text("30 sec").tag(TimeInterval(30))
                                Text("1 min").tag(TimeInterval(60))
                                Text("5 min").tag(TimeInterval(300))
                                Text("15 min").tag(TimeInterval(900))
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }
                
                Section(header: Text("Sync Triggers")) {
                    Toggle("Sync on App Launch", isOn: $settings.syncOnAppLaunch)
                    Toggle("Sync on Account Switch", isOn: $settings.syncOnAccountSwitch)
                }
                
                Section(header: Text("Sync Options")) {
                    Toggle("Positions Only Mode", isOn: $settings.syncPositionsOnly)
                        .onChange(of: settings.syncPositionsOnly) { newValue in
                            if newValue {
                                // Show explanation
                            }
                        }
                    
                    if settings.syncPositionsOnly {
                        Text("Only positions will be synced. Orders and history will be skipped for faster sync.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        syncService.resetSyncData()
                        dismiss()
                    }) {
                        Text("Reset Sync Data")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Sync Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        syncService.updateSyncSettings(settings)
                        dismiss()
                    }
                }
            }
            .onAppear {
                settings = syncService.syncSettings
            }
        }
    }
}

// MARK: - Sync Status Badge

struct SyncStatusBadge: View {
    @StateObject private var syncService = AccountSyncService.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            if case .syncing = syncService.syncStatus {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.Theme.text))
                    .scaleEffect(0.6)
            } else {
                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch syncService.syncStatus {
        case .idle:
            return .gray
        case .syncing:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var statusText: String {
        switch syncService.syncStatus {
        case .idle:
            return "Not synced"
        case .syncing:
            return "Syncing..."
        case .completed:
            return "Synced"
        case .failed:
            return "Failed"
        }
    }
}

#Preview {
    VStack {
        AccountSyncView()
            .padding()
        
        Spacer()
    }
    .background(Color.Theme.background)
}

#Preview("Sync Settings") {
    SyncSettingsView()
}