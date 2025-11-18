# Biometric Authentication Setup

## Overview
Pipflow supports Face ID and Touch ID authentication for quick and secure access to the app.

## Implementation Details

### 1. BiometricService
Located at: `Core/Services/BiometricService.swift`

Features:
- Detects available biometric type (Face ID, Touch ID, Optic ID)
- Handles authentication flow
- Manages user preferences
- Provides error handling

### 2. UI Integration

#### Login Screen
- Shows biometric login button when enabled
- Falls back to password authentication
- Located at: `Features/Authentication/Views/LoginView.swift`

#### Settings Screen
- Toggle to enable/disable biometric authentication
- Shows current biometric type
- Located at: `Features/Settings/SettingsView.swift`

### 3. Required Info.plist Keys

Add these to your Info.plist (or in Xcode project settings):

```xml
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to quickly and securely access your Pipflow account</string>
```

## Setup Instructions

1. **In Xcode:**
   - Select your project in the navigator
   - Select the app target
   - Go to the "Info" tab
   - Add a new row with key: `NSFaceIDUsageDescription`
   - Set value: `Use Face ID to quickly and securely access your Pipflow account`

2. **Testing on Simulator:**
   - Face ID can be tested on iPhone simulators
   - Go to Device > Face ID > Enrolled to enable
   - Use Device > Face ID > Matching Face to simulate successful authentication

3. **Testing on Device:**
   - Requires a physical device with Face ID or Touch ID
   - Must have biometric data enrolled in Settings

## Security Considerations

1. **Credential Storage:**
   - Currently shows a placeholder message
   - In production, implement secure credential storage using Keychain
   - Never store passwords in UserDefaults

2. **Fallback Authentication:**
   - Always provide password option as fallback
   - Handle biometric lockout scenarios

3. **Privacy:**
   - Biometric data never leaves the device
   - Only authentication result is returned

## Future Enhancements

1. **Secure Credential Storage:**
   ```swift
   // Store encrypted credentials in Keychain after first login
   KeychainWrapper.standard.set(encryptedCredentials, forKey: "user_credentials")
   ```

2. **Auto-login with Biometric:**
   - Store refresh token securely
   - Authenticate with biometric on app launch
   - Refresh session automatically

3. **Multi-factor Authentication:**
   - Combine biometric with PIN/password
   - Add time-based restrictions

## Error Handling

The BiometricService handles these error cases:
- Biometric not available
- Biometric not enrolled
- Authentication failed
- User cancelled
- System cancelled
- Too many attempts (lockout)

## Testing Checklist

- [ ] Enable Face ID in Settings
- [ ] Test successful authentication
- [ ] Test failed authentication
- [ ] Test cancellation
- [ ] Test with biometric disabled
- [ ] Test on devices without biometric
- [ ] Verify error messages are user-friendly