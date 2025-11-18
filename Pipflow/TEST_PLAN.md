# Pipflow Test Plan

## Overview
This document outlines the testing strategy for the Pipflow iOS application.

## Test Structure

```
PipflowTests/
├── Core/
│   └── Services/
│       ├── AuthServiceTests.swift
│       ├── BiometricServiceTests.swift
│       ├── SupabaseServiceTests.swift
│       └── MetaAPIServiceTests.swift
├── Features/
│   └── Authentication/
│       ├── AuthViewModelTests.swift
│       └── LoginViewTests.swift
└── PipflowTests.swift
```

## Test Categories

### 1. Unit Tests

#### Core Services
- **AuthServiceTests**: Tests authentication logic, token management, and state
- **BiometricServiceTests**: Tests Face ID/Touch ID integration
- **SupabaseServiceTests**: Tests database and auth backend integration
- **MetaAPIServiceTests**: Tests trading API integration

#### ViewModels
- **AuthViewModelTests**: Tests form validation, user input handling
- **DashboardViewModelTests**: Tests data aggregation and calculations
- **TradingViewModelTests**: Tests trading logic and risk calculations

### 2. Integration Tests
- Authentication flow (login → dashboard)
- Trading flow (market data → order execution)
- Social features (follow trader → copy trades)

### 3. UI Tests
- Login/Register forms
- Navigation flows
- Theme switching
- Biometric authentication UI

## Running Tests

### In Xcode
1. Select the test target
2. Press `Cmd+U` to run all tests
3. Or click the diamond next to individual tests

### Command Line
```bash
# Run all tests
xcodebuild test -scheme Pipflow-Debug -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test class
xcodebuild test -scheme Pipflow-Debug -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:PipflowTests/AuthServiceTests

# With coverage
xcodebuild test -scheme Pipflow-Debug -destination 'platform=iOS Simulator,name=iPhone 16' -enableCodeCoverage YES
```

## Test Data

### Mock Users
- `test@example.com` / `TestPassword123!` - Regular user
- `premium@example.com` / `PremiumPass123!` - Premium user
- `trader@example.com` / `TraderPass123!` - Professional trader

### Mock Trading Accounts
- Demo Account: Balance $10,000
- Live Account: Balance $50,000
- Copy Trading Account: Following 3 traders

## Coverage Goals
- Core Services: 80%+ coverage
- ViewModels: 70%+ coverage
- UI Components: 50%+ coverage

## CI/CD Integration

Tests are automatically run on:
- Pull requests
- Commits to main branch
- Nightly builds

## Best Practices

1. **Test Naming**: Use descriptive names
   ```swift
   func testSignInWithValidCredentialsSucceeds()
   func testSignUpWithExistingEmailFails()
   ```

2. **Arrange-Act-Assert**: Structure tests clearly
   ```swift
   // Arrange
   let email = "test@example.com"
   
   // Act
   try await authService.signIn(email: email, password: password)
   
   // Assert
   XCTAssertTrue(authService.isAuthenticated)
   ```

3. **Async Testing**: Use proper async/await
   ```swift
   func testAsyncOperation() async throws {
       let result = try await service.performOperation()
       XCTAssertNotNil(result)
   }
   ```

4. **Mock Dependencies**: Use protocols for testability
   ```swift
   protocol APIClientProtocol {
       func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
   }
   ```

## Known Issues

1. **Biometric Tests**: Require user interaction on simulator
2. **Network Tests**: Should use URLProtocol for mocking
3. **Keychain Tests**: May fail on simulator first run

## Future Improvements

1. Add snapshot testing for UI components
2. Implement performance tests for critical paths
3. Add stress tests for real-time features
4. Create automated UI tests with XCUITest
5. Add mutation testing for better coverage

## Debugging Tests

### Common Issues
1. **"No such module"**: Clean build folder and rebuild
2. **Async timeout**: Increase expectation timeout
3. **Keychain errors**: Reset simulator
4. **Biometric unavailable**: Enable Face ID in simulator

### Useful Commands
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset simulator
xcrun simctl erase all

# Enable Face ID
Device → Face ID → Enrolled
```