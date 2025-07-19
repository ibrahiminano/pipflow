# Pipflow CI/CD Workflows

This directory contains GitHub Actions workflows for automated testing, building, and deployment of the Pipflow iOS trading app.

## 🔄 Available Workflows

### 1. iOS CI/CD Pipeline (`ios-ci.yml`)
**Triggers:** Push/PR to main/develop branches affecting iOS code
- **Code Quality**: SwiftLint analysis and code formatting checks
- **Build & Test**: Xcode build and unit testing on multiple simulators
- **Security Scan**: Detects hardcoded secrets and security issues
- **Coverage**: Generates code coverage reports
- **Artifacts**: Build results, test reports, coverage data

### 2. Trading Bot Testing & Simulation (`trading-bot-testing.yml`)
**Triggers:** 
- Push/PR affecting trading/AI services
- Daily at 6 AM UTC (market pre-open)
- Manual dispatch with custom parameters

**Features:**
- **Strategy Validation**: Validates trading strategy configurations
- **Market Data Simulation**: Downloads real forex data for backtesting
- **AI Signal Generation**: ML-based signal generation simulation
- **Backtesting**: Complete trading strategy backtesting
- **Risk Analysis**: Comprehensive risk management analysis
- **Reporting**: Detailed simulation reports with charts

**Parameters:**
- `simulation_duration`: Hours to simulate (default: 24)
- `trading_pair`: Forex pair to test (EUR/USD, GBP/USD, etc.)
- `strategy_type`: Trading strategy (ai_signals, technical_analysis, etc.)

### 3. iOS App Deployment (`ios-deploy.yml`)
**Triggers:**
- Version tags (v*)
- Manual dispatch

**Stages:**
- **Prepare Build**: Version management and environment setup
- **Build iOS**: Archive creation and app building
- **Quality Checks**: App size analysis and security scanning
- **Release Notes**: Automated changelog generation
- **GitHub Release**: Creates releases for tagged versions
- **Deployment Notification**: Summary and next steps

### 4. Code Quality & Security (`code-quality.yml`)
**Triggers:**
- Push/PR to main/develop
- Weekly schedule (Monday 2 AM UTC)

**Checks:**
- **Linting**: SwiftLint analysis with auto-correction
- **Security Scan**: Secrets detection and dependency analysis
- **Code Metrics**: File counts, complexity analysis, TODO tracking

## 📊 Workflow Outputs

### Artifacts Generated
- **Build artifacts**: iOS app builds, archives
- **Test results**: Unit test reports, coverage data
- **Trading reports**: Backtesting results, performance charts
- **Analysis reports**: Code metrics, security scans
- **Release assets**: Release notes, build information

### Retention Policies
- **Build artifacts**: 30 days
- **Test results**: 30 days
- **Trading simulations**: 90 days
- **Release assets**: 90 days
- **Code metrics**: 30 days

## 🚀 Manual Workflow Execution

### Running Trading Bot Simulation
```bash
# Via GitHub UI: Actions → Trading Bot Testing & Simulation → Run workflow
# Or via GitHub CLI:
gh workflow run trading-bot-testing.yml \
  -f simulation_duration=48 \
  -f trading_pair="EUR/USD" \
  -f strategy_type="ai_signals"
```

### Running iOS Deployment
```bash
# Via GitHub UI: Actions → iOS App Deployment → Run workflow
# Or via GitHub CLI:
gh workflow run ios-deploy.yml \
  -f environment=staging \
  -f build_type=adhoc
```

## 🔧 Configuration Requirements

### Secrets (if needed for production)
- `APPLE_ID`: Apple Developer account email
- `APPLE_PASSWORD`: App-specific password
- `TEAM_ID`: Apple Developer Team ID
- `SIGNING_CERTIFICATE`: iOS distribution certificate
- `PROVISIONING_PROFILE`: iOS provisioning profile

### Environment Variables
- `XCODE_VERSION`: Xcode version for builds (default: 15.1)
- `IOS_VERSION`: iOS simulator version (default: 17.2)
- `DEFAULT_BALANCE`: Trading simulation starting balance
- `MAX_RISK_PERCENT`: Maximum risk per trade

## 📈 Monitoring & Notifications

### Status Badges
Add these to your README.md:
```markdown
![iOS CI](https://github.com/ibrahiminano/pipflow/workflows/iOS%20CI%2FCD%20Pipeline/badge.svg)
![Trading Bot](https://github.com/ibrahiminano/pipflow/workflows/Trading%20Bot%20Testing%20%26%20Simulation/badge.svg)
![Code Quality](https://github.com/ibrahiminano/pipflow/workflows/Code%20Quality%20%26%20Security/badge.svg)
```

### Workflow Results
- **Success**: All checks pass, artifacts available for download
- **Failure**: Check workflow logs for specific error details
- **Warnings**: Review quality checks and risk analysis reports

## 🛠 Development Workflow

### Feature Development
1. Create feature branch from `develop`
2. Develop and test locally
3. Push branch → triggers code quality checks
4. Create PR → triggers full CI pipeline
5. Merge to `develop` → triggers all workflows
6. Release: Create tag → triggers deployment

### Trading Strategy Testing
1. Modify trading algorithms in `/Core/Services/AI/` or `/Core/Services/Trading/`
2. Push changes → triggers trading bot simulation
3. Review simulation reports in workflow artifacts
4. Iterate based on risk analysis recommendations

### Production Deployment
1. Tag release: `git tag v1.0.0 && git push origin v1.0.0`
2. Deployment workflow automatically triggered
3. Download build artifacts from GitHub Actions
4. Manual TestFlight upload and App Store submission

## 📝 Best Practices

### Code Quality
- Keep SwiftLint warnings to minimum
- Maintain test coverage above 70%
- Regular dependency updates
- Follow Swift style guidelines

### Trading Simulations
- Run simulations before major trading logic changes
- Monitor risk metrics carefully
- Test multiple market conditions
- Validate AI signal accuracy

### Security
- Never commit API keys or secrets
- Regular security scans
- Use environment variables for configuration
- Monitor dependency vulnerabilities

## 🔗 Related Documentation
- [Xcode Build Settings](https://developer.apple.com/documentation/xcode)
- [GitHub Actions](https://docs.github.com/en/actions)
- [SwiftLint Configuration](https://realm.github.io/SwiftLint/)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)

---
*Last updated: $(date +%Y-%m-%d)* 