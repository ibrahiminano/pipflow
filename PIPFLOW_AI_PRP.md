name: "PIPFLOW AI - Product Requirements Proposal"
description: |

## Purpose
A comprehensive native iOS trading application that combines social trading, AI-powered analysis, automated execution, and gamified education to empower retail forex and crypto traders at all skill levels.

## Core Principles
1. **User-First Design**: Intuitive SwiftUI interface following Apple HIG
2. **AI-Native Architecture**: Deep integration of Claude/GPT-4 for analysis and automation
3. **Real-Time Performance**: Sub-second trade execution and live market data
4. **Security & Compliance**: Bank-grade security with proper risk disclosures
5. **Community-Driven**: Social features that foster learning and collaboration

---

## Goal
Build a revolutionary iOS trading platform that democratizes professional-grade trading tools through AI, enabling retail traders to:
- Copy proven strategies with one tap
- Receive AI-generated signals with clear rationale
- Learn through interactive AI tutoring
- Build communities around shared trading interests
- Execute trades automatically with proper risk management

## Why
- **Market Gap**: Existing trading apps lack sophisticated AI integration and social features
- **User Pain Points**: 
  - Information overload without actionable insights
  - Lack of educational resources for beginners
  - No trust in signal providers
  - Complex interfaces that intimidate new traders
- **Business Value**:
  - Subscription revenue from premium AI features
  - Commission from copy trading volume
  - Token economy creates engagement and retention
  - Data insights from aggregated trading patterns

## What
A native iOS app that serves as an AI-powered trading companion, offering:

### Core Trading Features
1. **One-Click Copy Trading**
   - Mirror expert trades via MetaAPI integration
   - Real-time performance tracking
   - Risk-adjusted position sizing
   - Verified trader leaderboards

2. **AI Auto-Trading Engine**
   - 24/7 market analysis using Claude/GPT-4
   - Automated trade execution with TP/SL
   - Natural language trade explanations
   - Customizable risk parameters

3. **AI Signal Generation**
   - Multi-timeframe analysis
   - Entry/Exit/SL/TP recommendations
   - Confidence scoring
   - On-chart annotations via TradingView

4. **MetaTrader Integration**
   - MT4/MT5 account linking
   - Real-time balance/position sync
   - Trade history import
   - Multi-broker support

### Educational & Social Features
5. **Interactive AI Academy**
   - Structured curriculum (Beginner → Expert)
   - AI tutor with contextual Q&A
   - Progress tracking and certifications
   - Interactive quizzes and challenges

6. **Social Trading Community**
   - Live chat rooms and forums
   - Strategy sharing and discussion
   - Performance competitions
   - Mentorship programs

7. **Gamification & Rewards**
   - NUMI token rewards for activities
   - Achievement badges and levels
   - Leaderboards and contests
   - Token-gated premium features

### Advanced Features
8. **Economic Calendar with AI Commentary**
   - Live macro event tracking
   - AI impact analysis
   - Trade suggestions per event
   - Historical event performance

9. **AI Strategy Builder**
   - Natural language → MQL5 code generation
   - In-app backtesting
   - Strategy optimization
   - One-click deployment to MT4/5

10. **AR/VR Trading Experience**
    - ARKit overlay for real-world chart visualization
    - Vision Pro support for immersive trading
    - 3D candlestick manipulation
    - Spatial audio market alerts

### Success Criteria
- [ ] Successfully link and sync MT4/5 accounts via MetaAPI
- [ ] Execute copy trades with <500ms latency
- [ ] Generate accurate AI signals with >60% win rate
- [ ] Support 10K+ concurrent users
- [ ] Achieve 4.5+ App Store rating
- [ ] 40% DAU/MAU ratio
- [ ] <0.1% trade execution errors
- [ ] 99.9% uptime for critical services

## All Needed Context

### Documentation & References
```yaml
# MUST READ - Core Documentation
- url: https://metaapi.cloud/docs/
  why: MetaAPI REST endpoints for MT4/5 integration
  sections: 
    - Account Management API
    - Trading API
    - Market Data API
    - Historical Data API
  
- url: https://developer.apple.com/documentation/swiftui
  why: SwiftUI components and best practices
  critical: Navigation, State Management, Animations
  
- url: https://supabase.com/docs/reference/ios
  why: Database and authentication
  sections:
    - Swift SDK installation
    - Realtime subscriptions
    - Row Level Security
    
- url: https://www.tradingview.com/mobile-sdk/
  why: Charting integration
  critical: iOS SDK initialization and event handling

- url: https://developer.apple.com/documentation/arkit
  why: AR features implementation
  sections: AR overlays, object tracking

- docfile: Context-Engineering-Intro/CLAUDE.md
  why: Project conventions and AI coding guidelines

- docfile: Context-Engineering-Intro/INITIAL.md
  why: Original vision and feature specifications
```

### Current Codebase Structure
```bash
Pipflow/
├── Pipflow.xcodeproj/
├── Pipflow/
│   ├── Assets.xcassets/
│   │   ├── AccentColor.colorset/
│   │   ├── GrayBackground.colorset/
│   │   ├── GraySecondary.colorset/
│   │   └── GrayText.colorset/
│   ├── ContentView.swift
│   ├── PipflowApp.swift
│   └── Theme.swift
```

### Desired Codebase Structure
```bash
Pipflow/
├── Pipflow.xcodeproj/
├── Pipflow/
│   ├── App/
│   │   ├── PipflowApp.swift          # Main app entry
│   │   └── AppDelegate.swift         # App lifecycle
│   ├── Core/
│   │   ├── Models/                   # Data models
│   │   │   ├── User.swift
│   │   │   ├── Trade.swift
│   │   │   ├── Signal.swift
│   │   │   └── Strategy.swift
│   │   ├── Services/                 # Business logic
│   │   │   ├── MetaAPIService.swift  # MT4/5 integration
│   │   │   ├── AIService.swift       # Claude/GPT integration
│   │   │   ├── AuthService.swift     # Supabase auth
│   │   │   └── TradingService.swift  # Trade execution
│   │   ├── Networking/               # API clients
│   │   │   ├── APIClient.swift
│   │   │   ├── WebSocketManager.swift
│   │   │   └── Endpoints.swift
│   │   └── Extensions/               # Swift extensions
│   ├── Features/
│   │   ├── Onboarding/              # User onboarding flow
│   │   ├── Dashboard/               # Main dashboard
│   │   ├── Trading/                 # Trading interface
│   │   │   ├── CopyTrading/
│   │   │   ├── AutoTrading/
│   │   │   └── ManualTrading/
│   │   ├── Signals/                 # AI signals
│   │   ├── Academy/                 # Educational content
│   │   ├── Social/                  # Community features
│   │   ├── Portfolio/               # Portfolio management
│   │   └── Settings/                # App settings
│   ├── UI/
│   │   ├── Components/              # Reusable UI components
│   │   ├── Theme/                   # Theming and styling
│   │   └── Modifiers/               # Custom view modifiers
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   ├── Localizable.strings      # Localization
│   │   └── Info.plist
│   └── Support/
│       ├── Configuration/           # App configuration
│       └── Utilities/               # Helper functions
├── PipflowTests/                    # Unit tests
├── PipflowUITests/                  # UI tests
└── Packages/                        # Swift packages
    └── PipflowKit/                  # Shared business logic
```

### Known Implementation Challenges
```swift
// CRITICAL: MetaAPI iOS Integration
// No native SDK - must use REST API directly
// Bearer token authentication required
// Rate limits: 1000 requests/minute

// GOTCHA: TradingView iOS SDK
// Requires license key
// WebView fallback for unsupported features
// Custom indicators need JavaScript bridge

// PATTERN: Supabase Realtime
// Must enable replication for tables
// Connection drops need reconnection logic
// Row Level Security affects subscriptions

// SECURITY: API Key Storage
// Use iOS Keychain for sensitive data
// Never store keys in UserDefaults
// Implement certificate pinning for API calls
```

## Implementation Blueprint

### Phase 1: Foundation (Weeks 1-4)
```yaml
Task 1 - Project Setup:
  - Configure Xcode project with proper signing
  - Add Swift Package dependencies:
    - Supabase iOS SDK
    - Alamofire for networking
    - SwiftUI components library
  - Setup SwiftLint and SwiftFormat
  - Create base folder structure

Task 2 - Authentication:
  CREATE Features/Auth/:
    - LoginView.swift
    - RegisterView.swift  
    - AuthViewModel.swift
  INTEGRATE Supabase Auth:
    - Email/password authentication
    - Social login (Apple, Google)
    - Biometric authentication setup

Task 3 - Core Services:
  CREATE Core/Services/APIClient.swift:
    - Generic REST client with Codable
    - Bearer token injection
    - Error handling and retry logic
  CREATE Core/Services/MetaAPIService.swift:
    - Account linking endpoints
    - Trading operations
    - Market data streaming
```

### Phase 2: Trading Features (Weeks 5-8)
```yaml
Task 4 - MetaTrader Integration:
  IMPLEMENT MT4/5 account linking:
    - OAuth flow with MetaAPI
    - Account verification
    - Balance/position sync
  CREATE real-time position tracking:
    - WebSocket connection
    - Position update handling
    - P&L calculations

Task 5 - Copy Trading:
  CREATE trader discovery interface:
    - Performance metrics display
    - Risk score calculation
    - Filtering and sorting
  IMPLEMENT copy logic:
    - Trade mirroring service
    - Position scaling
    - Risk management rules

Task 6 - AI Signal Generation:
  INTEGRATE AI services:
    - Claude API for analysis
    - Prompt engineering for signals
    - Response parsing
  CREATE signal UI:
    - Signal cards with details
    - Confidence indicators
    - One-tap execution
```

### Phase 3: AI & Social Features (Weeks 9-12)
```yaml
Task 7 - AI Auto-Trading:
  CREATE AI trading engine:
    - Market analysis loop
    - Decision making logic
    - Trade execution pipeline
  IMPLEMENT safety controls:
    - Max position limits
    - Drawdown protection
    - Manual override

Task 8 - Academy & Education:
  CREATE content management:
    - Lesson structure
    - Progress tracking
    - Quiz engine
  IMPLEMENT AI tutor:
    - Context-aware Q&A
    - Personalized learning paths
    - Interactive examples

Task 9 - Social Features:
  CREATE community infrastructure:
    - Chat rooms with moderation
    - User profiles
    - Following system
  IMPLEMENT real-time messaging:
    - WebSocket chat
    - Push notifications
    - Message persistence
```

### Phase 4: Advanced Features (Weeks 13-16)
```yaml
Task 10 - AR Trading:
  INTEGRATE ARKit:
    - 3D chart rendering
    - Gesture recognition
    - Spatial anchoring
  CREATE AR overlays:
    - Price levels
    - Trading indicators
    - Portfolio visualization

Task 11 - Strategy Builder:
  IMPLEMENT code generation:
    - Natural language parsing
    - MQL5 template system
    - Syntax validation
  CREATE testing framework:
    - Backtesting engine
    - Performance metrics
    - Optimization tools

Task 12 - Token Economy:
  CREATE NUMI token system:
    - Wallet integration
    - Reward distribution
    - Token transactions
  IMPLEMENT gamification:
    - Achievement system
    - Leaderboards
    - Challenges
```

### Data Models
```swift
// Core Trading Models
struct User: Codable {
    let id: UUID
    let email: String
    let username: String
    let tradingAccounts: [TradingAccount]
    let walletBalance: Decimal
    let tier: UserTier
}

struct TradingAccount: Codable {
    let id: UUID
    let platform: TradingPlatform // MT4, MT5
    let accountId: String
    let broker: String
    let balance: Decimal
    let equity: Decimal
    let margin: Decimal
}

struct Trade: Codable {
    let id: UUID
    let accountId: UUID
    let symbol: String
    let type: TradeType
    let volume: Decimal
    let openPrice: Decimal
    let closePrice: Decimal?
    let stopLoss: Decimal?
    let takeProfit: Decimal?
    let profit: Decimal?
    let status: TradeStatus
    let openTime: Date
    let closeTime: Date?
}

struct Signal: Codable {
    let id: UUID
    let symbol: String
    let action: SignalAction
    let entry: Decimal
    let stopLoss: Decimal
    let takeProfit: [Decimal]
    let confidence: Double
    let rationale: String
    let generatedAt: Date
    let expiresAt: Date
}

struct Strategy: Codable {
    let id: UUID
    let name: String
    let description: String
    let authorId: UUID
    let performance: StrategyPerformance
    let riskScore: Int
    let monthlyReturn: Decimal
    let maxDrawdown: Decimal
    let subscribers: Int
}
```

## Validation Loop

### Level 1: Build & Lint
```bash
# SwiftLint checks
swiftlint --fix
swiftlint

# Build for iOS
xcodebuild -project Pipflow.xcodeproj -scheme Pipflow -sdk iphonesimulator build

# Run SwiftFormat
swiftformat .
```

### Level 2: Unit Tests
```swift
// Test MetaAPI Integration
func testAccountLinking() async throws {
    let service = MetaAPIService()
    let account = try await service.linkAccount(
        login: "12345",
        password: "demo",
        server: "ICMarkets-Demo"
    )
    XCTAssertNotNil(account.id)
    XCTAssertEqual(account.platform, .MT4)
}

// Test AI Signal Generation  
func testSignalGeneration() async throws {
    let aiService = AIService()
    let signal = try await aiService.generateSignal(
        symbol: "EURUSD",
        timeframe: .H1
    )
    XCTAssertNotNil(signal.entry)
    XCTAssertGreaterThan(signal.confidence, 0.5)
}

// Test Copy Trading Logic
func testTradeCopying() async throws {
    let copyService = CopyTradingService()
    let trade = Trade(symbol: "GBPUSD", volume: 0.1, type: .buy)
    let copiedTrade = try await copyService.copyTrade(
        trade,
        scalingFactor: 0.5
    )
    XCTAssertEqual(copiedTrade.volume, 0.05)
}
```

### Level 3: UI Tests
```swift
// Test Onboarding Flow
func testUserOnboarding() throws {
    let app = XCUIApplication()
    app.launch()
    
    // Welcome screen
    XCTAssertTrue(app.staticTexts["Welcome to Pipflow"].exists)
    app.buttons["Get Started"].tap()
    
    // Registration
    app.textFields["Email"].tap()
    app.textFields["Email"].typeText("test@example.com")
    app.secureTextFields["Password"].tap()
    app.secureTextFields["Password"].typeText("SecurePass123!")
    app.buttons["Create Account"].tap()
    
    // Verify dashboard appears
    XCTAssertTrue(app.navigationBars["Dashboard"].waitForExistence(timeout: 5))
}
```

### Level 4: Integration Tests
```bash
# Test MetaAPI connection
curl -X POST https://mt-client-api-v1.london.agiliumtrade.ai/users/current/accounts \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "login": "12345",
    "password": "password",
    "name": "Test Account",
    "server": "ICMarkets-Demo",
    "platform": "mt4"
  }'

# Expected: {"id": "account-id", "state": "DEPLOYED"}
```

## Security & Compliance Checklist
- [ ] API keys stored in iOS Keychain
- [ ] Certificate pinning implemented
- [ ] Biometric authentication enabled
- [ ] Data encryption at rest
- [ ] Secure WebSocket connections
- [ ] Risk disclaimers displayed
- [ ] Terms of Service acceptance
- [ ] Privacy policy compliance
- [ ] PCI compliance for payments
- [ ] App Transport Security configured

## Performance Requirements
- [ ] App launch time < 2 seconds
- [ ] Trade execution < 500ms
- [ ] Signal generation < 3 seconds
- [ ] Chart rendering @ 60 FPS
- [ ] Offline mode for viewing
- [ ] Background sync capability
- [ ] Memory usage < 200MB
- [ ] Battery optimization
- [ ] Network retry logic
- [ ] Graceful degradation

## Success Metrics
- **User Acquisition**: 10K downloads in first month
- **Activation Rate**: 60% complete onboarding
- **Retention**: 40% DAU/MAU ratio
- **Trading Volume**: $1M daily volume within 3 months
- **AI Accuracy**: >60% profitable signals
- **Copy Trading**: 30% of users follow at least one trader
- **Education**: Average 3 lessons completed per user
- **Revenue**: $50K MRR within 6 months
- **App Rating**: 4.5+ stars with 1000+ reviews
- **Support**: <2 hour response time

---

## Anti-Patterns to Avoid
- ❌ Storing sensitive data in UserDefaults
- ❌ Synchronous network calls on main thread
- ❌ Hardcoded API endpoints
- ❌ Unencrypted local storage
- ❌ Missing error handling for trades
- ❌ Infinite retry loops
- ❌ Memory leaks from observers
- ❌ Force unwrapping optionals
- ❌ Ignoring App Store guidelines
- ❌ Poor offline experience