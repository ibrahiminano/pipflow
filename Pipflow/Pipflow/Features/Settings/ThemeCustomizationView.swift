//
//  ThemeCustomizationView.swift
//  Pipflow
//
//  Theme and appearance customization settings
//

import SwiftUI

struct ThemeCustomizationView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var uiStyleManager = UIStyleManager.shared
    @StateObject private var settingsService = SettingsService.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTheme: AppTheme
    @State private var selectedUIStyle: UIStyle
    @State private var selectedAccentColor: AccentColor
    @State private var selectedFontSize: FontSize
    @State private var showAnimations: Bool
    @State private var reducedMotion: Bool
    @State private var highContrast: Bool
    
    init() {
        let appearance = SettingsService.shared.settings.appearance
        _selectedTheme = State(initialValue: appearance.theme)
        _selectedUIStyle = State(initialValue: appearance.uiStyle)
        _selectedAccentColor = State(initialValue: appearance.accentColor)
        _selectedFontSize = State(initialValue: appearance.fontSize)
        _showAnimations = State(initialValue: appearance.showAnimations)
        _reducedMotion = State(initialValue: appearance.reducedMotion)
        _highContrast = State(initialValue: appearance.highContrast)
    }
    
    private var availableThemes: [AppTheme] {
        [AppTheme.black, AppTheme.purple, AppTheme.blue, AppTheme.orange, AppTheme.green]
    }
    
    var body: some View {
        NavigationView {
            List {
                // Theme Selection
                Section {
                    ForEach(availableThemes, id: \.self) { theme in
                        ThemeRowView(
                            theme: theme,
                            isSelected: selectedTheme == theme,
                            action: {
                                selectedTheme = theme
                                applyChanges()
                            }
                        )
                    }
                } header: {
                    Text("Theme")
                } footer: {
                    Text("Choose your preferred app theme")
                }
                
                // UI Style Selection
                Section {
                    ForEach(UIStyle.allCases, id: \.self) { style in
                        UIStyleRowView(
                            style: style,
                            isSelected: selectedUIStyle == style,
                            action: {
                                selectedUIStyle = style
                                applyChanges()
                            }
                        )
                    }
                } header: {
                    Text("UI Style")
                } footer: {
                    Text("Select the interface style that suits you best")
                }
                
                // Accent Color
                Section("Accent Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(AccentColor.allCases.filter { $0 != .custom }, id: \.self) { color in
                            AccentColorButton(
                                color: color,
                                isSelected: selectedAccentColor == color,
                                action: {
                                    selectedAccentColor = color
                                    applyChanges()
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Font Size
                Section("Text Size") {
                    VStack(spacing: 12) {
                        Picker("Font Size", selection: $selectedFontSize) {
                            ForEach(FontSize.allCases, id: \.self) { size in
                                Text(size.rawValue.capitalized)
                                    .tag(size)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedFontSize) { _ in
                            applyChanges()
                        }
                        
                        Text("The quick brown fox jumps over the lazy dog")
                            .font(.system(size: 16 * selectedFontSize.scale))
                            .foregroundColor(Color.Theme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.Theme.cardBackground)
                            .cornerRadius(8)
                    }
                }
                
                // Accessibility
                Section("Accessibility") {
                    Toggle("Show Animations", isOn: $showAnimations)
                        .onChange(of: showAnimations) { _ in
                            applyChanges()
                        }
                    
                    Toggle("Reduce Motion", isOn: $reducedMotion)
                        .onChange(of: reducedMotion) { _ in
                            applyChanges()
                        }
                    
                    Toggle("High Contrast", isOn: $highContrast)
                        .onChange(of: highContrast) { _ in
                            applyChanges()
                        }
                }
                
                // Preview Section
                Section("Preview") {
                    VStack(spacing: 16) {
                        // Sample Card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("EUR/USD")
                                    .font(.headline)
                                Text("1.0856")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("+0.45%")
                                    .font(.subheadline)
                                    .foregroundColor(Color.Theme.success)
                                Text("↑ 0.0048")
                                    .font(.caption)
                                    .foregroundColor(Color.Theme.secondaryText)
                            }
                        }
                        .padding()
                        .background(Color.Theme.cardBackground)
                        .cornerRadius(12)
                        
                        // Sample Buttons
                        HStack(spacing: 12) {
                            Button(action: {}) {
                                Text("Buy")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.Theme.success)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {}) {
                                Text("Sell")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.Theme.error)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveChanges()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func applyChanges() {
        // Apply theme changes immediately for preview
        themeManager.appTheme = selectedTheme
        uiStyleManager.currentStyle = selectedUIStyle
    }
    
    private func saveChanges() {
        // Save to settings
        settingsService.settings.appearance.theme = selectedTheme
        settingsService.settings.appearance.uiStyle = selectedUIStyle
        settingsService.settings.appearance.accentColor = selectedAccentColor
        settingsService.settings.appearance.fontSize = selectedFontSize
        settingsService.settings.appearance.showAnimations = showAnimations
        settingsService.settings.appearance.reducedMotion = reducedMotion
        settingsService.settings.appearance.highContrast = highContrast
    }
}

struct UIStyleRowView: View {
    let style: UIStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: style.icon)
                    .font(.title3)
                    .foregroundColor(Color.Theme.accent)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.displayName)
                        .font(.bodyLarge)
                        .foregroundColor(Color.Theme.text)
                    
                    Text(style.description)
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color.Theme.accent)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AccentColorButton: View {
    let color: AccentColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 44, height: 44)
                
                if isSelected {
                    Circle()
                        .stroke(Color.Theme.text, lineWidth: 3)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - UIStyle Extension
extension UIStyle {
    var icon: String {
        switch self {
        case .traditional:
            return "rectangle.grid.2x2"
        case .premium:
            return "crown"
        case .futuristic:
            return "sparkles"
        }
    }
}

#Preview {
    ThemeCustomizationView()
}