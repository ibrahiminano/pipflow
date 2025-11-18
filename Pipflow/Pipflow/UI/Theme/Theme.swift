import SwiftUI

struct Theme {
    let name: String
    let backgroundColor: Color
    let secondaryBackgroundColor: Color
    let accentColor: Color
    let textColor: Color
    let secondaryTextColor: Color
    let separatorColor: Color
    let shadowColor: Color
    
    static let black = Theme(
        name: "Black",
        backgroundColor: Color(red: 0.0, green: 0.0, blue: 0.0), // Pure black
        secondaryBackgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1), // Dark gray
        accentColor: Color.accentColor,
        textColor: Color.white,
        secondaryTextColor: Color.white.opacity(0.7),
        separatorColor: Color.gray.opacity(0.2),
        shadowColor: Color.black.opacity(0.3)
    )
    
    static let orange = Theme(
        name: "Orange",
        backgroundColor: Color(UIColor.systemBackground),
        secondaryBackgroundColor: Color(UIColor.secondarySystemBackground),
        accentColor: Color(red: 0.96, green: 0.64, blue: 0.18), // Vibrant orange color
        textColor: Color(UIColor.label),
        secondaryTextColor: Color(UIColor.secondaryLabel),
        separatorColor: Color(UIColor.separator),
        shadowColor: Color.black.opacity(0.1)
    )
    
    static let blue = Theme(
        name: "Blue",
        backgroundColor: Color(UIColor.systemBackground),
        secondaryBackgroundColor: Color(UIColor.secondarySystemBackground),
        accentColor: Color(red: 0.224, green: 0.478, blue: 0.996),
        textColor: Color(UIColor.label),
        secondaryTextColor: Color(UIColor.secondaryLabel),
        separatorColor: Color(UIColor.separator),
        shadowColor: Color.black.opacity(0.1)
    )
    
    static let purple = Theme(
        name: "Purple",
        backgroundColor: Color(UIColor.systemBackground),
        secondaryBackgroundColor: Color(UIColor.secondarySystemBackground),
        accentColor: Color(red: 0.576, green: 0.435, blue: 0.831),
        textColor: Color(UIColor.label),
        secondaryTextColor: Color(UIColor.secondaryLabel),
        separatorColor: Color(UIColor.separator),
        shadowColor: Color.black.opacity(0.1)
    )
    
    static let green = Theme(
        name: "Green",
        backgroundColor: Color(UIColor.systemBackground),
        secondaryBackgroundColor: Color(UIColor.secondarySystemBackground),
        accentColor: Color(red: 0.298, green: 0.686, blue: 0.314),
        textColor: Color(UIColor.label),
        secondaryTextColor: Color(UIColor.secondaryLabel),
        separatorColor: Color(UIColor.separator),
        shadowColor: Color.black.opacity(0.1)
    )
}

extension Color {
    struct Theme {
        // Dynamic colors based on selected theme
        static var background: Color {
            ThemeManager.shared.currentTheme.backgroundColor
        }
        
        static var secondary: Color {
            ThemeManager.shared.currentTheme.secondaryBackgroundColor
        }
        
        static var secondaryBackground: Color {
            ThemeManager.shared.currentTheme.secondaryBackgroundColor
        }
        
        static var text: Color {
            ThemeManager.shared.currentTheme.textColor
        }
        
        static var secondaryText: Color {
            ThemeManager.shared.currentTheme.secondaryTextColor
        }
        
        // Dynamic accent color based on selected theme
        static var accent: Color {
            ThemeManager.shared.appTheme.primaryColor
        }
        
        // Additional modern colors (theme independent)
        static let success = Color(red: 0.22, green: 0.80, blue: 0.50)
        static let error = Color(red: 0.95, green: 0.35, blue: 0.35)
        static let warning = Color(red: 0.98, green: 0.75, blue: 0.18)
        static let info = Color(red: 0.32, green: 0.62, blue: 0.96)
        
        // Trading specific colors
        static let buy = Color(red: 0.22, green: 0.80, blue: 0.50)
        static let sell = Color(red: 0.95, green: 0.35, blue: 0.35)
        
        // Dynamic gradient colors based on theme
        static var gradientStart: Color {
            ThemeManager.shared.appTheme.gradientColors.first ?? Color.black
        }
        
        static var gradientEnd: Color {
            ThemeManager.shared.appTheme.gradientColors.last ?? Color.gray
        }
        
        // Dynamic surface colors
        static var cardBackground: Color {
            ThemeManager.shared.currentTheme.secondaryBackgroundColor
        }
        
        static var surface: Color {
            ThemeManager.shared.currentTheme.secondaryBackgroundColor
        }
        
        static var divider: Color {
            ThemeManager.shared.currentTheme.separatorColor
        }
        
        static var shadow: Color {
            ThemeManager.shared.currentTheme.shadowColor
        }
        
        static var inputBackground: Color {
            ThemeManager.shared.currentTheme.secondaryBackgroundColor.opacity(0.5)
        }
    }
}

// Modern corner radius and spacing constants
extension CGFloat {
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 12
    static let largeCornerRadius: CGFloat = 24
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24
}

// Modern text styles
extension Font {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
}