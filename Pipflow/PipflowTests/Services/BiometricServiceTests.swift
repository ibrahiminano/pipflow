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
    
    var sut: BiometricService!
    var mockLAContext: MockLAContext!
    var mockSupabaseService: MockSupabaseService!
    
    override func setUp() {
        super.setUp()
        
        // Create mocks
        mockLAContext = MockLAContext()
        mockSupabaseService = MockSupabaseService()
        
        // Create system under test
        sut = BiometricService.shared
        
        // Reset state
        sut.isEnabled = false
    }
    
    override func tearDown() {
        sut = nil
        mockLAContext = nil
        mockSupabaseService = nil
        super.tearDown()
    }
    
    // MARK: - Availability Tests
    
    func testCheckBiometricAvailability_WhenAvailable_ShouldReturnTrue() {
        // Given
        mockLAContext.canEvaluatePolicyResult = true
        mockLAContext.biometryType = .faceID
        
        // When
        let isAvailable = sut.isBiometricAvailable
        
        // Then
        XCTAssertTrue(isAvailable)
    }
    
    func testCheckBiometricAvailability_WhenNotAvailable_ShouldReturnFalse() {
        // Given
        mockLAContext.canEvaluatePolicyResult = false
        mockLAContext.biometryType = .none
        
        // When
        let isAvailable = sut.isBiometricAvailable
        
        // Then
        XCTAssertFalse(isAvailable)
    }
    
    func testBiometricType_FaceID_ShouldReturnCorrectType() {
        // Given
        mockLAContext.canEvaluatePolicyResult = true
        mockLAContext.biometryType = .faceID
        
        // When
        let type = sut.biometricType
        
        // Then
        XCTAssertEqual(type, .faceID)
    }
    
    func testBiometricType_TouchID_ShouldReturnCorrectType() {
        // Given
        mockLAContext.canEvaluatePolicyResult = true
        mockLAContext.biometryType = .touchID
        
        // When
        let type = sut.biometricType
        
        // Then
        XCTAssertEqual(type, .touchID)
    }
    
    // MARK: - Authentication Tests
    
    func testAuthenticate_WhenSuccessful_ShouldReturnTrue() async throws {
        // Given
        mockLAContext.canEvaluatePolicyResult = true
        mockLAContext.evaluatePolicyResult = true
        
        // When
        let result = try await sut.authenticate()
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testAuthenticate_WhenFailed_ShouldReturnFalse() async {
        // Given
        mockLAContext.canEvaluatePolicyResult = true
        mockLAContext.evaluatePolicyResult = false
        mockLAContext.evaluatePolicyError = LAError(.authenticationFailed)
        
        // When
        do {
            _ = try await sut.authenticate()
            XCTFail("Authentication should fail")
        } catch {
            // Then
            XCTAssertTrue(error is LAError)
        }
    }
    
    func testAuthenticate_WhenUserCancelled_ShouldThrowError() async {
        // Given
        mockLAContext.canEvaluatePolicyResult = true
        mockLAContext.evaluatePolicyResult = false
        mockLAContext.evaluatePolicyError = LAError(.userCancel)
        
        // When
        do {
            _ = try await sut.authenticate()
            XCTFail("Authentication should be cancelled")
        } catch {
            // Then
            if let laError = error as? LAError {
                XCTAssertEqual(laError.code, .userCancel)
            } else {
                XCTFail("Should throw LAError")
            }
        }
    }
    
    // MARK: - Enable/Disable Tests
    
    func testEnableBiometrics_WhenAvailable_ShouldSucceed() async throws {
        // Given
        mockLAContext.canEvaluatePolicyResult = true
        mockLAContext.evaluatePolicyResult = true
        sut.isEnabled = false
        
        // When
        try await sut.enableBiometrics()
        
        // Then
        XCTAssertTrue(sut.isEnabled)
    }
    
    func testEnableBiometrics_WhenNotAvailable_ShouldFail() async {
        // Given
        mockLAContext.canEvaluatePolicyResult = false
        sut.isEnabled = false
        
        // When
        do {
            try await sut.enableBiometrics()
            XCTFail("Enable should fail when biometrics not available")
        } catch {
            // Then
            XCTAssertFalse(sut.isEnabled)
        }
    }
    
    func testDisableBiometrics_ShouldAlwaysSucceed() async throws {
        // Given
        sut.isEnabled = true
        
        // When
        try await sut.disableBiometrics()
        
        // Then
        XCTAssertFalse(sut.isEnabled)
    }
    
    // MARK: - Settings Update Tests
    
    func testUpdateUserSettings_WhenBiometricsEnabled_ShouldUpdateSupabase() async throws {
        // Given
        sut.isEnabled = true
        let userId = "test-user-123"
        
        // When
        try await sut.updateUserSettings(userId: userId)
        
        // Then
        XCTAssertTrue(mockSupabaseService.updateUserSettingsCalled)
        XCTAssertEqual(mockSupabaseService.lastUpdatedSettings?.biometricEnabled, true)
    }
    
    func testUpdateUserSettings_WhenBiometricsDisabled_ShouldUpdateSupabase() async throws {
        // Given
        sut.isEnabled = false
        let userId = "test-user-123"
        
        // When
        try await sut.updateUserSettings(userId: userId)
        
        // Then
        XCTAssertTrue(mockSupabaseService.updateUserSettingsCalled)
        XCTAssertEqual(mockSupabaseService.lastUpdatedSettings?.biometricEnabled, false)
    }
}

// MARK: - Mock LAContext

class MockLAContext: LAContext {
    var canEvaluatePolicyResult = true
    var canEvaluatePolicyError: Error?
    var evaluatePolicyResult = true
    var evaluatePolicyError: Error?
    var biometryType: LABiometryType = .faceID
    
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        if let canEvaluatePolicyError = canEvaluatePolicyError {
            error?.pointee = canEvaluatePolicyError as NSError
        }
        return canEvaluatePolicyResult
    }
    
    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.main.async {
            reply(self.evaluatePolicyResult, self.evaluatePolicyError)
        }
    }
}

// MARK: - Extended Mock Supabase Service

extension MockSupabaseService {
    var updateUserSettingsCalled = false
    var lastUpdatedSettings: SupabaseUserSettings?
    
    func updateUserSettings(userId: String, settings: SupabaseUserSettings) async throws {
        updateUserSettingsCalled = true
        lastUpdatedSettings = settings
    }
}