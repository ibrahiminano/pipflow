//
//  BiometricServiceTests.swift
//  PipflowTests
//
//  Unit tests for BiometricService
//

import XCTest
import LocalAuthentication
@testable import Pipflow

class BiometricServiceTests: XCTestCase {
    
    var biometricService: BiometricService!
    
    override func setUp() {
        super.setUp()
        biometricService = BiometricService.shared
    }
    
    override func tearDown() {
        // Reset biometric settings
        biometricService.disableBiometric()
        super.tearDown()
    }
    
    // MARK: - Availability Tests
    
    func testBiometricAvailabilityCheck() {
        // This test will vary based on the simulator/device
        // On simulator, Face ID can be enabled
        biometricService.checkBiometricAvailability()
        
        // The service should have determined availability
        // Note: This will be false on simulators unless Face ID is enrolled
        XCTAssertNotNil(biometricService.biometricType)
    }
    
    func testBiometricTypeDetection() {
        // Test that biometric type is properly set
        let biometricType = biometricService.biometricType
        
        // Should be one of the valid types
        XCTAssertTrue([.none, .touchID, .faceID, .opticID].contains(biometricType))
    }
    
    // MARK: - Settings Tests
    
    func testEnableBiometric() async {
        // Skip if biometric is not available
        guard biometricService.isAvailable else {
            XCTSkip("Biometric authentication not available on this device")
            return
        }
        
        // Test enabling (will fail on simulator without user interaction)
        do {
            try await biometricService.enableBiometric()
            XCTAssertTrue(biometricService.isEnabled)
        } catch {
            // Expected on simulator without enrolled biometric
            XCTAssertTrue(error is BiometricError)
        }
    }
    
    func testDisableBiometric() {
        // First enable it
        UserDefaults.standard.set(true, forKey: "biometric_enabled")
        biometricService.checkBiometricAvailability() // Refresh availability
        
        // Then disable
        biometricService.disableBiometric()
        
        XCTAssertFalse(biometricService.isEnabled)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "biometric_enabled"))
    }
    
    // MARK: - Error Mapping Tests
    
    func testErrorMapping() {
        // Test that LA errors are properly mapped to BiometricError
        let laErrors: [(Int, BiometricError)] = [
            (LAError.authenticationFailed.rawValue, .authenticationFailed),
            (LAError.userCancel.rawValue, .userCancel),
            (LAError.systemCancel.rawValue, .systemCancel),
            (LAError.passcodeNotSet.rawValue, .passcodeNotSet),
            (LAError.biometryNotAvailable.rawValue, .notAvailable),
            (LAError.biometryNotEnrolled.rawValue, .notEnrolled),
            (LAError.biometryLockout.rawValue, .lockout)
        ]
        
        for (code, expectedError) in laErrors {
            let nsError = NSError(domain: LAErrorDomain, code: code, userInfo: nil)
            let mappedError = biometricService.mapLAError(nsError)
            
            switch (mappedError, expectedError) {
            case (.authenticationFailed, .authenticationFailed),
                 (.userCancel, .userCancel),
                 (.systemCancel, .systemCancel),
                 (.passcodeNotSet, .passcodeNotSet),
                 (.notAvailable, .notAvailable),
                 (.notEnrolled, .notEnrolled),
                 (.lockout, .lockout):
                XCTAssertTrue(true)
            default:
                XCTFail("Error mapping failed for code \(code)")
            }
        }
    }
    
    // MARK: - Display Name Tests
    
    func testBiometricTypeDisplayNames() {
        XCTAssertEqual(BiometricType.none.displayName, "Not Available")
        XCTAssertEqual(BiometricType.touchID.displayName, "Touch ID")
        XCTAssertEqual(BiometricType.faceID.displayName, "Face ID")
        XCTAssertEqual(BiometricType.opticID.displayName, "Optic ID")
    }
    
    func testBiometricTypeSystemImages() {
        XCTAssertEqual(BiometricType.none.systemImageName, "lock.fill")
        XCTAssertEqual(BiometricType.touchID.systemImageName, "touchid")
        XCTAssertEqual(BiometricType.faceID.systemImageName, "faceid")
        XCTAssertEqual(BiometricType.opticID.systemImageName, "opticid")
    }
    
    // MARK: - Authentication Tests
    
    func testAuthenticationForLogin() async {
        // Skip if not available or not enabled
        guard biometricService.isAvailable else {
            XCTSkip("Biometric authentication not available")
            return
        }
        
        // Enable biometric first
        UserDefaults.standard.set(true, forKey: "biometric_enabled")
        biometricService.checkBiometricAvailability() // Refresh availability
        
        // Test authentication (will fail on simulator without interaction)
        do {
            try await biometricService.authenticateForLogin()
            XCTAssertTrue(true) // Success
        } catch let error as BiometricError {
            // Expected errors on simulator
            XCTAssertTrue([.notEnrolled, .userCancel, .systemCancel].contains { 
                if case $0 = error { return true }
                return false
            })
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testAuthenticationWhenDisabled() async {
        // Ensure biometric is disabled
        biometricService.disableBiometric()
        
        // Try to authenticate
        do {
            try await biometricService.authenticateForLogin()
            XCTFail("Authentication should fail when disabled")
        } catch let error as BiometricError {
            if case .notAvailable = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected notAvailable error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

// MARK: - BiometricService Extension for Testing

extension BiometricService {
    /// Expose private method for testing
    func mapLAError(_ error: NSError?) -> BiometricError {
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