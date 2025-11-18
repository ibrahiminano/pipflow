//
//  UIStyleManager.swift
//  Pipflow
//
//  Manages UI style preferences (Traditional vs Quantum)
//

import SwiftUI
import Combine

enum UIStyle: String, CaseIterable, Codable {
    case traditional = "traditional"
    case premium = "premium"
    case futuristic = "futuristic"
    
    var displayName: String {
        switch self {
        case .traditional:
            return "Traditional"
        case .premium:
            return "Premium"
        case .futuristic:
            return "Futuristic"
        }
    }
    
    var description: String {
        switch self {
        case .traditional:
            return "Classic trading interface"
        case .premium:
            return "Elegant and sophisticated"
        case .futuristic:
            return "Modern sci-fi inspired"
        }
    }
}

@MainActor
class UIStyleManager: ObservableObject {
    static let shared = UIStyleManager()
    
    @Published var currentStyle: UIStyle {
        didSet {
            UserDefaults.standard.set(currentStyle.rawValue, forKey: "ui_style_preference")
        }
    }
    
    private init() {
        let savedStyle = UserDefaults.standard.string(forKey: "ui_style_preference") ?? UIStyle.traditional.rawValue
        self.currentStyle = UIStyle(rawValue: savedStyle) ?? .traditional
    }
    
    func toggleStyle() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            // Cycle through available styles
            switch currentStyle {
            case .traditional:
                currentStyle = .premium
            case .premium:
                currentStyle = .futuristic
            case .futuristic:
                currentStyle = .traditional
            }
        }
    }
}

// Environment key for UI style
struct UIStyleKey: EnvironmentKey {
    static let defaultValue = UIStyle.traditional
}

extension EnvironmentValues {
    var uiStyle: UIStyle {
        get { self[UIStyleKey.self] }
        set { self[UIStyleKey.self] = newValue }
    }
}