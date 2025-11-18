//
//  SettingsService.swift
//  Pipflow
//
//  Settings management service
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SettingsService: ObservableObject {
    static let shared = SettingsService()
    
    @Published var settings: UserSettings
    
    private let settingsKey = "com.pipflow.userSettings"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Load settings from UserDefaults
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let loadedSettings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = loadedSettings
        } else {
            self.settings = UserSettings()
        }
        
        // Save settings when they change
        $settings
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] settings in
                self?.saveSettings()
            }
            .store(in: &cancellables)
        
        // Apply settings
        applySettings()
    }
    
    // MARK: - Save/Load
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    func resetToDefaults() {
        settings = UserSettings()
        applySettings()
    }
    
    // MARK: - Apply Settings
    private func applySettings() {
        // Apply theme
        ThemeManager.shared.appTheme = settings.appearance.theme
        UIStyleManager.shared.currentStyle = settings.appearance.uiStyle
        
        // Apply font size
        applyFontSize(settings.appearance.fontSize)
        
        // Apply other settings as needed
    }
    
    private func applyFontSize(_ fontSize: FontSize) {
        // In a real app, this would update the dynamic type settings
        let contentSize: UIContentSizeCategory
        switch fontSize {
        case .small:
            contentSize = .small
        case .medium:
            contentSize = .medium
        case .large:
            contentSize = .large
        case .extraLarge:
            contentSize = .extraLarge
        }
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
        }
    }
    
    // MARK: - Export/Import
    func exportSettings() -> URL? {
        let fileName = "pipflow_settings_\(Date().timeIntervalSince1970).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to export settings: \(error)")
            return nil
        }
    }
    
    func importSettings(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let importedSettings = try JSONDecoder().decode(UserSettings.self, from: data)
            settings = importedSettings
            applySettings()
            return true
        } catch {
            print("Failed to import settings: \(error)")
            return false
        }
    }
    
    // MARK: - Backup
    func createBackup() -> Data? {
        try? JSONEncoder().encode(settings)
    }
    
    func restoreBackup(from data: Data) -> Bool {
        do {
            let restoredSettings = try JSONDecoder().decode(UserSettings.self, from: data)
            settings = restoredSettings
            applySettings()
            return true
        } catch {
            print("Failed to restore backup: \(error)")
            return false
        }
    }
    
    // MARK: - Cache Management
    func clearCache() {
        // Clear image cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear temp files
        let tempDirectory = FileManager.default.temporaryDirectory
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            for file in tempFiles {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Failed to clear cache: \(error)")
        }
        
        // Reset cache size
        settings.advanced.cacheSize = 0
    }
    
    func getCacheSize() -> String {
        let cacheSize = URLCache.shared.currentDiskUsage
        return ByteCountFormatter.string(fromByteCount: Int64(cacheSize), countStyle: .file)
    }
}