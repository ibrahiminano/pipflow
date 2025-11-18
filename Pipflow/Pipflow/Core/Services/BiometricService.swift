//
//  BiometricService.swift
//  Pipflow
//
//  Handles Face ID and Touch ID authentication
//

import Foundation
import LocalAuthentication
import Combine

enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID
}

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancel
    case passcodeNotSet
    case systemCancel
    case lockout
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings"
        case .authenticationFailed:
            return "Biometric authentication failed"
        case .userCancel:
            return "Authentication was cancelled"
        case .passcodeNotSet:
            return "Passcode is not set on this device"
        case .systemCancel:
            return "Authentication was cancelled by the system"
        case .lockout:
            return "Too many failed attempts. Please try again later"
        case .unknown(let message):
            return message
        }
    }
}

class BiometricService: ObservableObject {
    static let shared = BiometricService()
    
    private let context = LAContext()
    private let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
    
    @Published var biometricType: BiometricType = .none
    @Published var isAvailable = false
    @Published var isEnabled = false
    
    private init() {
        checkBiometricAvailability()
        loadBiometricSettings()
    }
    
    // MARK: - Public Methods
    
    func checkBiometricAvailability() {
        var error: NSError?
        
        guard context.canEvaluatePolicy(policy, error: &error) else {
            biometricType = .none
            isAvailable = false
            return
        }
        
        isAvailable = true
        
        switch context.biometryType {
        case .none:
            biometricType = .none
        case .touchID:
            biometricType = .touchID
        case .faceID:
            biometricType = .faceID
        case .opticID:
            biometricType = .opticID
        @unknown default:
            biometricType = .none
        }
    }
    
    func authenticate(reason: String = "Authenticate to access your account") async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Password"
        
        var error: NSError?
        
        guard context.canEvaluatePolicy(policy, error: &error) else {
            throw mapLAError(error)
        }
        
        do {
            let success = try await context.evaluatePolicy(
                policy,
                localizedReason: reason
            )
            
            if !success {
                throw BiometricError.authenticationFailed
            }
        } catch let laError as LAError {
            throw mapLAError(laError as NSError)
        } catch {
            throw BiometricError.unknown(error.localizedDescription)
        }
    }
    
    func enableBiometric() async throws {
        // First, verify biometric is available
        guard isAvailable else {
            throw BiometricError.notAvailable
        }
        
        // Authenticate to enable
        try await authenticate(reason: "Authenticate to enable biometric login")
        
        // Save setting
        UserDefaults.standard.set(true, forKey: "biometric_enabled")
        isEnabled = true
        
        // Update Supabase settings if available
        if let user = SupabaseService.shared.currentUser {
            let settings = SupabaseUserSettings(
                userId: user.id,
                biometricEnabled: true,
                pushNotifications: true,
                emailNotifications: true,
                tradeNotifications: true,
                priceAlerts: true,
                newsAlerts: false,
                darkMode: true,
                autoTradingEnabled: false,
                riskLevel: "medium",
                defaultLeverage: 10,
                defaultOrderType: "market",
                updatedAt: Date()
            )
            try? await SupabaseService.shared.updateUserSettings(settings)
        }
    }
    
    func disableBiometric() {
        UserDefaults.standard.set(false, forKey: "biometric_enabled")
        isEnabled = false
        
        // Update Supabase settings if available
        Task {
            if let user = SupabaseService.shared.currentUser {
                let settings = SupabaseUserSettings(
                    userId: user.id,
                    biometricEnabled: false,
                    pushNotifications: true,
                    emailNotifications: true,
                    tradeNotifications: true,
                    priceAlerts: true,
                    newsAlerts: false,
                    darkMode: true,
                    autoTradingEnabled: false,
                    riskLevel: "medium",
                    defaultLeverage: 10,
                    defaultOrderType: "market",
                    updatedAt: Date()
                )
                try? await SupabaseService.shared.updateUserSettings(settings)
            }
        }
    }
    
    func authenticateForLogin() async throws {
        guard isEnabled else {
            throw BiometricError.notAvailable
        }
        
        try await authenticate(reason: "Log in to Pipflow")
    }
    
    // MARK: - Private Methods
    
    private func loadBiometricSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "biometric_enabled")
    }
    
    private func mapLAError(_ error: NSError?) -> BiometricError {
        guard let error = error else {
            return .unknown("Unknown error")
        }
        
        switch error.code {
        case LAError.authenticationFailed.rawValue:
            return .authenticationFailed
        case LAError.userCancel.rawValue:
            return .userCancel
        case LAError.userFallback.rawValue:
            return .userCancel
        case LAError.systemCancel.rawValue:
            return .systemCancel
        case LAError.passcodeNotSet.rawValue:
            return .passcodeNotSet
        case LAError.biometryNotAvailable.rawValue:
            return .notAvailable
        case LAError.biometryNotEnrolled.rawValue:
            return .notEnrolled
        case LAError.biometryLockout.rawValue:
            return .lockout
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - Extensions

extension BiometricType {
    var displayName: String {
        switch self {
        case .none:
            return "Not Available"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .none:
            return "lock.fill"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .opticID:
            return "opticid"
        }
    }
}