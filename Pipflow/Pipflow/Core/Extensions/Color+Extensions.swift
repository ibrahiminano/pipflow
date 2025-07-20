//
//  Color+Extensions.swift
//  Pipflow
//
//  Created by Claude on 19/07/2025.
//

import SwiftUI

extension Color {
    struct Theme {
        // Core theme colors
        static var accent: Color {
            ThemeManager.shared.appTheme.primaryColor
        }
        
        static var gradientStart: Color {
            ThemeManager.shared.appTheme.gradientColors.first ?? .blue
        }
        
        static var gradientEnd: Color {
            ThemeManager.shared.appTheme.gradientColors.last ?? .purple
        }
        
        // Background colors
        static var background: Color {
            ThemeManager.shared.currentTheme.backgroundColor
        }
        
        static var cardBackground: Color {
            ThemeManager.shared.currentTheme.secondaryBackgroundColor
        }
        
        // Text colors
        static var text: Color {
            ThemeManager.shared.currentTheme.textColor
        }
        
        static var textSecondary: Color {
            ThemeManager.shared.currentTheme.secondaryTextColor
        }
        
        // Trading specific colors
        static var buy: Color {
            Color(red: 0.298, green: 0.686, blue: 0.314) // Green
        }
        
        static var sell: Color {
            Color(red: 0.863, green: 0.196, blue: 0.184) // Red
        }
        
        static var success: Color {
            Color(red: 0.298, green: 0.686, blue: 0.314) // Green
        }
        
        static var error: Color {
            Color(red: 0.863, green: 0.196, blue: 0.184) // Red
        }
        
        static var warning: Color {
            Color(red: 0.961, green: 0.643, blue: 0.188) // Orange
        }
        
        // Shadow and separator
        static var shadow: Color {
            Color.black.opacity(0.15)
        }
        
        static var separator: Color {
            Color.gray.opacity(0.3)
        }
    }
}

// Additional corner radius and spacing constants
extension CGFloat {
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
}

// Font extensions for consistency
extension Font {
    static let bodyLarge = Font.system(size: 16, weight: .medium)
    static let captionLarge = Font.system(size: 14, weight: .regular)
}