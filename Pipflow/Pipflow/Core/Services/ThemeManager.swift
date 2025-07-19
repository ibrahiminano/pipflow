//
//  ThemeManager.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case black = "Black"
    case orange = "Orange"
    case blue = "Blue"
    case purple = "Purple"
    case green = "Green"
    
    var displayName: String {
        rawValue
    }
    
    var primaryColor: Color {
        switch self {
        case .black:
            return Color(red: 0.33, green: 0.44, blue: 0.59)
        case .orange:
            return Color(red: 0.96, green: 0.64, blue: 0.18) // Vibrant orange color
        case .blue:
            return Color(red: 0.224, green: 0.478, blue: 0.996)
        case .purple:
            return Color(red: 0.576, green: 0.435, blue: 0.831)
        case .green:
            return Color(red: 0.298, green: 0.686, blue: 0.314)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .black:
            return [Color.black, Color.gray.opacity(0.8)]
        case .orange:
            return [Color(red: 0.96, green: 0.64, blue: 0.18), 
                    Color(red: 0.98, green: 0.78, blue: 0.35)] // Vibrant orange gradient
        case .blue:
            return [Color(red: 0.224, green: 0.478, blue: 0.996), 
                    Color(red: 0.424, green: 0.678, blue: 1.0)]
        case .purple:
            return [Color(red: 0.576, green: 0.435, blue: 0.831), 
                    Color(red: 0.776, green: 0.635, blue: 0.931)]
        case .green:
            return [Color(red: 0.345, green: 0.729, blue: 0.478), 
                    Color(red: 0.545, green: 0.829, blue: 0.678)]
        }
    }
    
    var icon: String {
        switch self {
        case .black:
            return "moon.fill"
        case .orange:
            return "sun.max.fill"
        case .blue:
            return "drop.fill"
        case .purple:
            return "sparkles"
        case .green:
            return "leaf.fill"
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var appTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(appTheme.rawValue, forKey: "selected_theme")
            updateAppearance()
        }
    }
    
    var currentTheme: Theme {
        switch appTheme {
        case .black:
            return .black
        case .orange:
            return .orange
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .green:
            return .green
        }
    }
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selected_theme") ?? AppTheme.black.rawValue
        self.appTheme = AppTheme(rawValue: savedTheme) ?? .black
        updateAppearance()
    }
    
    private func updateAppearance() {
        // Update the accent color dynamically
        UIView.appearance().tintColor = UIColor(appTheme.primaryColor)
    }
}

// Theme-aware color extensions
extension Color {
    struct DynamicTheme {
        @ObservedObject private static var themeManager = ThemeManager.shared
        
        static var primary: Color {
            themeManager.appTheme.primaryColor
        }
        
        static var gradientStart: Color {
            themeManager.appTheme.gradientColors.first ?? .black
        }
        
        static var gradientEnd: Color {
            themeManager.appTheme.gradientColors.last ?? .gray
        }
        
        static var gradientColors: [Color] {
            themeManager.appTheme.gradientColors
        }
    }
}