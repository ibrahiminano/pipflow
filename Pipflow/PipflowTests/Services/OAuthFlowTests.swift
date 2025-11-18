//
//  OAuthFlowTests.swift
//  PipflowTests
//
//  Unit tests for OAuth authentication flow
//

import XCTest
import WebKit
@testable import Pipflow

class OAuthFlowTests: XCTestCase {
    
    var sut: BrokerOAuthViewModel!
    var mockWebView: MockWKWebView!
    var mockKeychainManager: MockKeychainManager!
    
    override func setUp() {
        super.setUp()
        
        // Create mocks
        mockWebView = MockWKWebView()
        mockKeychainManager = MockKeychainManager()
        
        // Create system under test
        sut = BrokerOAuthViewModel(broker: .icMarkets)
    }
    
    override func tearDown() {
        sut = nil
        mockWebView = nil
        mockKeychainManager = nil
        super.tearDown()
    }
    
    // MARK: - OAuth URL Construction Tests
    
    func testBuildOAuthURL_ICMarkets_ShouldBeCorrect() {
        // Given
        let broker = SupportedBroker.icMarkets
        let viewModel = BrokerOAuthViewModel(broker: broker)
        
        // When
        viewModel.startOAuthFlow()
        
        // Then
        XCTAssertNotNil(viewModel.oauthURL)
        let url = viewModel.oauthURL!
        XCTAssertEqual(url.host, "secure.icmarkets.com")
        XCTAssertEqual(url.path, "/oauth/authorize")
        XCTAssertTrue(url.absoluteString.contains("client_id=pipflow_app"))
        XCTAssertTrue(url.absoluteString.contains("redirect_uri=pipflow://oauth/callback"))
        XCTAssertTrue(url.absoluteString.contains("response_type=code"))
    }
    
    func testBuildOAuthURL_XM_ShouldBeCorrect() {
        // Given
        let broker = SupportedBroker.xm
        let viewModel = BrokerOAuthViewModel(broker: broker)
        
        // When
        viewModel.startOAuthFlow()
        
        // Then
        XCTAssertNotNil(viewModel.oauthURL)
        let url = viewModel.oauthURL!
        XCTAssertEqual(url.host, "my.xm.com")
        XCTAssertEqual(url.path, "/api/oauth/authorize")
    }
    
    func testBuildOAuthURL_Pepperstone_ShouldBeCorrect() {
        // Given
        let broker = SupportedBroker.pepperstone
        let viewModel = BrokerOAuthViewModel(broker: broker)
        
        // When
        viewModel.startOAuthFlow()
        
        // Then
        XCTAssertNotNil(viewModel.oauthURL)
        let url = viewModel.oauthURL!
        XCTAssertEqual(url.host, "secure.pepperstone.com")
        XCTAssertEqual(url.path, "/oauth2/auth")
    }
    
    // MARK: - OAuth Callback Handling Tests
    
    func testHandleOAuthCallback_WithValidCode_ShouldSucceed() {
        // Given
        let callbackURL = URL(string: "pipflow://oauth/callback?code=test_auth_code_123&state=abc123")!
        
        // When
        sut.handleNavigationChange(callbackURL)
        
        // Then
        // Wait for async token exchange
        let expectation = XCTestExpectation(description: "Token exchange")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertNotNil(self.sut.authResult)
            XCTAssertEqual(self.sut.authResult?.broker, .icMarkets)
            XCTAssertTrue(self.sut.authResult?.accessToken.contains("mock_access_token") ?? false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testHandleOAuthCallback_WithError_ShouldFail() {
        // Given
        let callbackURL = URL(string: "pipflow://oauth/callback?error=access_denied&error_description=User%20denied%20access")!
        
        // When
        sut.handleNavigationChange(callbackURL)
        
        // Then
        XCTAssertTrue(sut.showError)
        XCTAssertTrue(sut.errorMessage.contains("access_denied"))
        XCTAssertNil(sut.authResult)
    }
    
    func testHandleOAuthCallback_WithoutCode_ShouldFail() {
        // Given
        let callbackURL = URL(string: "pipflow://oauth/callback?state=abc123")!
        
        // When
        sut.handleNavigationChange(callbackURL)
        
        // Then
        XCTAssertTrue(sut.showError)
        XCTAssertTrue(sut.errorMessage.contains("No authorization code"))
        XCTAssertNil(sut.authResult)
    }
    
    // MARK: - Token Storage Tests
    
    func testOAuthSuccess_ShouldStoreTokensInKeychain() {
        // Given
        let account = TradingAccount(
            id: "test-123",
            accountId: "123456",
            accountType: .real,
            brokerName: "IC Markets",
            serverName: "ICMarkets-Live06",
            platformType: .mt5,
            balance: 10000,
            equity: 10000,
            currency: "USD",
            leverage: 100,
            isActive: true,
            connectedDate: Date()
        )
        
        let oauthResult = BrokerOAuthResult(
            accessToken: "test_access_token",
            refreshToken: "test_refresh_token",
            accountInfo: BrokerAccountInfo(
                accountId: "123456",
                accountName: "Test Account",
                serverName: "ICMarkets-Live06",
                platform: .mt5,
                leverage: 100,
                balance: 10000,
                currency: "USD"
            ),
            broker: .icMarkets
        )
        
        // When
        mockKeychainManager.saveAccessToken(oauthResult.accessToken, for: account.id)
        mockKeychainManager.saveRefreshToken(oauthResult.refreshToken, for: account.id)
        
        // Then
        XCTAssertEqual(mockKeychainManager.getAccessToken(for: account.id), oauthResult.accessToken)
        XCTAssertEqual(mockKeychainManager.getRefreshToken(for: account.id), oauthResult.refreshToken)
    }
    
    // MARK: - WebView Navigation Tests
    
    func testWebViewNavigation_ToExternalSite_ShouldAllow() {
        // Given
        let navigationAction = MockWKNavigationAction(url: URL(string: "https://secure.icmarkets.com/login")!)
        
        // When
        var decision: WKNavigationActionPolicy?
        let webView = BrokerWebView(
            url: URL(string: "https://secure.icmarkets.com/oauth/authorize")!,
            onNavigationChange: { _ in },
            onLoadComplete: { }
        )
        
        let coordinator = webView.makeCoordinator()
        coordinator.webView(mockWebView, decidePolicyFor: navigationAction) { policy in
            decision = policy
        }
        
        // Then
        XCTAssertEqual(decision, .allow)
    }
    
    func testWebViewNavigation_ToCallbackURL_ShouldIntercept() {
        // Given
        let callbackURL = URL(string: "pipflow://oauth/callback?code=123")!
        let navigationAction = MockWKNavigationAction(url: callbackURL)
        var interceptedURL: URL?
        
        // When
        let webView = BrokerWebView(
            url: URL(string: "https://secure.icmarkets.com/oauth/authorize")!,
            onNavigationChange: { url in
                interceptedURL = url
            },
            onLoadComplete: { }
        )
        
        let coordinator = webView.makeCoordinator()
        coordinator.webView(mockWebView, decidePolicyFor: navigationAction) { _ in }
        
        // Then
        XCTAssertEqual(interceptedURL, callbackURL)
    }
    
    // MARK: - Error Handling Tests
    
    func testOAuthFlow_NetworkError_ShouldShowError() {
        // Given
        sut.showError = false
        
        // When
        sut.showError(message: "Network connection failed")
        
        // Then
        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.errorMessage, "Network connection failed")
        XCTAssertFalse(sut.isLoading)
    }
    
    func testOAuthFlow_InvalidBroker_ShouldReturnNilURL() {
        // Given
        let unsupportedBroker = SupportedBroker.avatrade // Doesn't support OAuth
        let viewModel = BrokerOAuthViewModel(broker: unsupportedBroker)
        
        // When
        viewModel.startOAuthFlow()
        
        // Then
        XCTAssertNil(viewModel.oauthURL)
        XCTAssertTrue(viewModel.showError)
    }
}

// MARK: - Mock WebView

class MockWKWebView: WKWebView {
    var loadedRequest: URLRequest?
    
    override func load(_ request: URLRequest) -> WKNavigation? {
        loadedRequest = request
        return nil
    }
}

class MockWKNavigationAction: WKNavigationAction {
    private let _request: URLRequest
    
    init(url: URL) {
        self._request = URLRequest(url: url)
        super.init()
    }
    
    override var request: URLRequest {
        return _request
    }
}

// MARK: - BrokerOAuthViewModel Extensions for Testing

extension BrokerOAuthViewModel {
    func showError(message: String) {
        errorMessage = message
        showError = true
        isLoading = false
    }
}