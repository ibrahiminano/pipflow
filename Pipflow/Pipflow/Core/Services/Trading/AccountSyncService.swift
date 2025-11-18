//
//  AccountSyncService.swift
//  Pipflow
//
//  Manages account synchronization and auto-refresh
//

import Foundation
import Combine
import UIKit

// MARK: - Sync Settings

struct AccountSyncSettings {
    var isAutoSyncEnabled: Bool = true
    var syncInterval: TimeInterval = 30 // seconds
    var syncOnAppLaunch: Bool = true
    var syncOnAccountSwitch: Bool = true
    var syncPositionsOnly: Bool = false
}

// MARK: - Sync Status

enum SyncStatus {
    case idle
    case syncing
    case completed(Date)
    case failed(Error)
    
    var isActive: Bool {
        if case .syncing = self { return true }
        return false
    }
}

// MARK: - Account Sync Service

@MainActor
class AccountSyncService: ObservableObject {
    static let shared = AccountSyncService()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var syncProgress: Double = 0.0
    @Published var syncSettings = AccountSyncSettings()
    
    private let metaAPIService = MetaAPIService.shared
    private let webSocketService = MetaAPIWebSocketService.shared
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSyncSettings()
        setupAutoSync()
        observeAppLifecycle()
    }
    
    // MARK: - Public Methods
    
    func syncAccount(accountId: String? = nil) async {
        guard syncStatus.isActive == false else {
            print("Sync already in progress")
            return
        }
        
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            // Get account ID
            let targetAccountId = accountId ?? metaAPIService.currentAccountId
            guard let accountId = targetAccountId else {
                throw TradingError.notConnected
            }
            
            // Step 1: Sync account information (20%)
            syncProgress = 0.2
            if let token = metaAPIService.currentAuthToken {
                _ = try await withCheckedThrowingContinuation { continuation in
                    metaAPIService.getAccountInfo(accountId: accountId)
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    continuation.resume(throwing: error)
                                }
                            },
                            receiveValue: { account in
                                continuation.resume(returning: account)
                            }
                        )
                        .store(in: &self.cancellables)
                }
            }
            
            // Step 2: Sync positions (40%)
            syncProgress = 0.4
            try await metaAPIService.fetchPositions()
            
            // Step 3: Sync pending orders (60%)
            syncProgress = 0.6
            if !syncSettings.syncPositionsOnly {
                // Trigger WebSocket to refresh orders
                webSocketService.subscribeToMarketData(symbols: getActiveSymbols())
            }
            
            // Step 4: Sync account metrics (80%)
            syncProgress = 0.8
            try await metaAPIService.fetchAccountInfo()
            
            // Step 5: Complete sync (100%)
            syncProgress = 1.0
            lastSyncDate = Date()
            syncStatus = .completed(Date())
            
            // Save last sync date
            UserDefaults.standard.set(lastSyncDate, forKey: "lastAccountSyncDate")
            
        } catch {
            syncStatus = .failed(error)
            print("Account sync failed: \(error)")
        }
    }
    
    func startAutoSync() {
        guard syncSettings.isAutoSyncEnabled else { return }
        
        stopAutoSync()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncSettings.syncInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.syncAccount()
            }
        }
    }
    
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    func resetSyncData() {
        lastSyncDate = nil
        syncStatus = .idle
        syncProgress = 0.0
        UserDefaults.standard.removeObject(forKey: "lastAccountSyncDate")
    }
    
    // MARK: - Settings Management
    
    func updateSyncSettings(_ settings: AccountSyncSettings) {
        self.syncSettings = settings
        saveSyncSettings()
        
        if settings.isAutoSyncEnabled {
            startAutoSync()
        } else {
            stopAutoSync()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAutoSync() {
        if syncSettings.isAutoSyncEnabled {
            startAutoSync()
        }
        
        // Load last sync date
        if let date = UserDefaults.standard.object(forKey: "lastAccountSyncDate") as? Date {
            lastSyncDate = date
        }
    }
    
    private func observeAppLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { _ in
                Task { @MainActor in
                    if self.syncSettings.syncOnAppLaunch {
                        await self.syncAccount()
                    }
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { _ in
                self.stopAutoSync()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { _ in
                self.stopAutoSync()
            }
            .store(in: &cancellables)
    }
    
    private func getActiveSymbols() -> [String] {
        var symbols = Set<String>()
        
        // Add symbols from open positions
        for position in metaAPIService.positions {
            symbols.insert(position.symbol)
        }
        
        // Add symbols from pending orders
        for order in webSocketService.orders {
            symbols.insert(order.symbol)
        }
        
        // Add default symbols if none found
        if symbols.isEmpty {
            symbols = ["EURUSD", "GBPUSD", "USDJPY"]
        }
        
        return Array(symbols)
    }
    
    private func loadSyncSettings() {
        if let data = UserDefaults.standard.data(forKey: "accountSyncSettings"),
           let settings = try? JSONDecoder().decode(AccountSyncSettings.self, from: data) {
            self.syncSettings = settings
        }
    }
    
    private func saveSyncSettings() {
        if let data = try? JSONEncoder().encode(syncSettings) {
            UserDefaults.standard.set(data, forKey: "accountSyncSettings")
        }
    }
}

// MARK: - Convenience Methods

extension AccountSyncService {
    var timeSinceLastSync: String? {
        guard let lastSync = lastSyncDate else { return nil }
        
        let interval = Date().timeIntervalSince(lastSync)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
    
    var shouldAutoSync: Bool {
        guard syncSettings.isAutoSyncEnabled else { return false }
        
        if let lastSync = lastSyncDate {
            return Date().timeIntervalSince(lastSync) >= syncSettings.syncInterval
        }
        
        return true
    }
}

// MARK: - Make Sync Settings Codable

extension AccountSyncSettings: Codable {}