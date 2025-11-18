//
//  Settings.swift
//  Pipflow
//
//  Settings models and preferences
//

import Foundation
import SwiftUI

// MARK: - User Settings
struct UserSettings: Codable {
    var general: GeneralSettings
    var trading: TradingSettings
    var appearance: AppearanceSettings
    var notifications: PipflowNotificationPreferences
    var privacy: UserPrivacySettings
    var advanced: AdvancedSettings
    
    init() {
        self.general = GeneralSettings()
        self.trading = TradingSettings()
        self.appearance = AppearanceSettings()
        self.notifications = PipflowNotificationPreferences()
        self.privacy = UserPrivacySettings()
        self.advanced = AdvancedSettings()
    }
}

// MARK: - General Settings
struct GeneralSettings: Codable {
    var language: AppLanguage
    var currency: Currency
    var timezone: TimeZone
    var dateFormat: DateFormat
    var numberFormat: NumberFormat
    
    init() {
        self.language = .english
        self.currency = .usd
        self.timezone = TimeZone.current
        self.dateFormat = .medium
        self.numberFormat = .decimal
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case japanese = "ja"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        }
    }
}

enum Currency: String, CaseIterable, Codable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case aud = "AUD"
    case cad = "CAD"
    case chf = "CHF"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .aud: return "A$"
        case .cad: return "C$"
        case .chf: return "CHF"
        }
    }
    
    var displayName: String {
        switch self {
        case .usd: return "US Dollar"
        case .eur: return "Euro"
        case .gbp: return "British Pound"
        case .jpy: return "Japanese Yen"
        case .aud: return "Australian Dollar"
        case .cad: return "Canadian Dollar"
        case .chf: return "Swiss Franc"
        }
    }
}

enum DateFormat: String, CaseIterable, Codable {
    case short = "short"
    case medium = "medium"
    case long = "long"
    case custom = "custom"
    
    var example: String {
        let date = Date()
        let formatter = DateFormatter()
        
        switch self {
        case .short:
            formatter.dateStyle = .short
            formatter.timeStyle = .short
        case .medium:
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
        case .long:
            formatter.dateStyle = .long
            formatter.timeStyle = .medium
        case .custom:
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
        }
        
        return formatter.string(from: date)
    }
}

enum NumberFormat: String, CaseIterable, Codable {
    case decimal = "decimal"
    case comma = "comma"
    case space = "space"
    
    var example: String {
        switch self {
        case .decimal: return "1,234.56"
        case .comma: return "1.234,56"
        case .space: return "1 234.56"
        }
    }
}

// MARK: - Trading Settings
struct TradingSettings: Codable {
    var defaultLotSize: Double
    var defaultStopLoss: Double // in pips
    var defaultTakeProfit: Double // in pips
    var maxRiskPerTrade: Double // percentage
    var maxOpenTrades: Int
    var defaultTimeframe: Timeframe
    var defaultChartType: TradingChartType
    var showTradeConfirmation: Bool
    var enableOneTapTrading: Bool
    var autoCalculatePositionSize: Bool
    var riskRewardRatio: Double
    
    init() {
        self.defaultLotSize = 0.01
        self.defaultStopLoss = 50
        self.defaultTakeProfit = 100
        self.maxRiskPerTrade = 2.0
        self.maxOpenTrades = 5
        self.defaultTimeframe = .h1
        self.defaultChartType = .candlestick
        self.showTradeConfirmation = true
        self.enableOneTapTrading = false
        self.autoCalculatePositionSize = true
        self.riskRewardRatio = 2.0
    }
}

enum TradingChartType: String, CaseIterable, Codable {
    case candlestick = "candlestick"
    case line = "line"
    case bar = "bar"
    case area = "area"
    case heikinAshi = "heikin_ashi"
    
    var displayName: String {
        switch self {
        case .candlestick: return "Candlestick"
        case .line: return "Line"
        case .bar: return "Bar"
        case .area: return "Area"
        case .heikinAshi: return "Heikin Ashi"
        }
    }
    
    var icon: String {
        switch self {
        case .candlestick: return "chart.bar"
        case .line: return "chart.line.uptrend.xyaxis"
        case .bar: return "chart.bar.xaxis"
        case .area: return "waveform.path"
        case .heikinAshi: return "chart.bar.doc.horizontal"
        }
    }
}

// MARK: - Appearance Settings
struct AppearanceSettings: Codable {
    var theme: AppTheme
    var uiStyle: UIStyle
    var accentColor: AccentColor
    var fontSize: FontSize
    var showAnimations: Bool
    var reducedMotion: Bool
    var highContrast: Bool
    
    init() {
        self.theme = .black
        self.uiStyle = .traditional
        self.accentColor = .blue
        self.fontSize = .medium
        self.showAnimations = true
        self.reducedMotion = false
        self.highContrast = false
    }
}

enum AccentColor: String, CaseIterable, Codable {
    case blue = "blue"
    case green = "green"
    case purple = "purple"
    case orange = "orange"
    case pink = "pink"
    case red = "red"
    case yellow = "yellow"
    case custom = "custom"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .pink: return .pink
        case .red: return .red
        case .yellow: return .yellow
        case .custom: return Color.Theme.accent
        }
    }
}

enum FontSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extra_large"
    
    var scale: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        }
    }
}

// MARK: - Privacy Settings
struct UserPrivacySettings: Codable {
    var shareAnalytics: Bool
    var sharePerformance: Bool
    var publicProfile: Bool
    var showOnlineStatus: Bool
    var allowDirectMessages: Bool
    var hideBalances: Bool
    var requireBiometricForTrades: Bool
    var dataRetentionDays: Int
    
    init() {
        self.shareAnalytics = true
        self.sharePerformance = false
        self.publicProfile = false
        self.showOnlineStatus = true
        self.allowDirectMessages = true
        self.hideBalances = false
        self.requireBiometricForTrades = false
        self.dataRetentionDays = 365
    }
}

// MARK: - Advanced Settings
struct AdvancedSettings: Codable {
    var developerMode: Bool
    var showDebugInfo: Bool
    var enableBetaFeatures: Bool
    var cacheSize: Int // in MB
    var autoBackup: Bool
    var backupFrequency: BackupFrequency
    var exportFormat: ExportFormat
    var apiRateLimit: Int
    
    init() {
        self.developerMode = false
        self.showDebugInfo = false
        self.enableBetaFeatures = false
        self.cacheSize = 100
        self.autoBackup = true
        self.backupFrequency = .weekly
        self.exportFormat = .csv
        self.apiRateLimit = 60
    }
}

enum BackupFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case never = "never"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .never: return "Never"
        }
    }
}

enum ExportFormat: String, CaseIterable, Codable {
    case csv = "csv"
    case json = "json"
    case excel = "excel"
    case pdf = "pdf"
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .excel: return "Excel"
        case .pdf: return "PDF"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .csv: return ".csv"
        case .json: return ".json"
        case .excel: return ".xlsx"
        case .pdf: return ".pdf"
        }
    }
}