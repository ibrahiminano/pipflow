# Build Schemes Configuration

## Overview
Pipflow uses three build schemes to manage different environments:

### 1. Debug (Development)
- **Purpose**: Local development and testing
- **Features**:
  - Full logging enabled
  - Debug menu visible
  - Mock services available
  - Development API endpoints
  - Compiler optimization disabled for faster builds

### 2. Staging
- **Purpose**: Testing with staging servers
- **Features**:
  - Logging enabled
  - Staging API endpoints
  - Real services (no mocks)
  - Similar to production but with test data

### 3. Release (Production)
- **Purpose**: App Store distribution
- **Features**:
  - Logging disabled
  - Production API endpoints
  - Compiler optimization enabled
  - No debug features

## Usage

### Xcode
1. Select the scheme from the scheme selector (next to the device selector)
2. Build and run as usual

### Command Line
```bash
# Debug build
xcodebuild -scheme Pipflow-Debug -configuration Debug

# Staging build
xcodebuild -scheme Pipflow-Staging -configuration Debug STAGING=1

# Release build
xcodebuild -scheme Pipflow-Release -configuration Release
```

## Environment Variables

Each scheme can use different environment variables:

### Debug
- `SUPABASE_URL_DEV`
- `SUPABASE_ANON_KEY_DEV`
- `METAAPI_ACCOUNT_ID`
- `METAAPI_TOKEN`
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`

### Staging
- `SUPABASE_URL_STAGING`
- `SUPABASE_ANON_KEY_STAGING`
- Same API keys as Debug

### Release
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- Production API keys

## Adding New Configurations

To add new configuration-specific behavior:

1. Update `BuildConfiguration.swift` with new properties
2. Update `Environment.swift` to use the configuration
3. Use conditional compilation if needed:

```swift
#if DEBUG
    // Debug-only code
#elseif STAGING
    // Staging-only code
#else
    // Release code
#endif
```