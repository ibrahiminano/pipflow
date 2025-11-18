//
//  BrokerOAuthView.swift
//  Pipflow
//
//  OAuth flow for broker authentication
//

import SwiftUI
import WebKit

struct BrokerOAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BrokerOAuthViewModel
    
    let broker: SupportedBroker
    let onCompletion: (BrokerOAuthResult) -> Void
    
    init(broker: SupportedBroker, onCompletion: @escaping (BrokerOAuthResult) -> Void) {
        self.broker = broker
        self.onCompletion = onCompletion
        self._viewModel = StateObject(wrappedValue: BrokerOAuthViewModel(broker: broker))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(hex: "0F0F0F").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // OAuth Web View or Status
                    if let oauthURL = viewModel.oauthURL {
                        BrokerWebView(
                            url: oauthURL,
                            onNavigationChange: viewModel.handleNavigationChange,
                            onLoadComplete: viewModel.handleLoadComplete
                        )
                        .background(Color.white)
                        .clipShape(BrokerRoundedCorner(radius: 12, corners: [.topLeft, .topRight]))
                    } else {
                        loadingView
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $viewModel.showError) {
                Button("Retry") {
                    viewModel.startOAuthFlow()
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.authResult) { oldValue, newValue in
                if let result = newValue {
                    onCompletion(result)
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.startOAuthFlow()
        }
    }
    
    // MARK: - Components
    
    var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                
                Spacer()
                
                // Security Badge
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption)
                    Text("Secure Connection")
                        .font(.caption)
                }
                .foregroundColor(Color(hex: "00F5A0"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "00F5A0").opacity(0.2))
                .cornerRadius(20)
            }
            
            // Broker Logo and Title
            VStack(spacing: 8) {
                if let logoName = broker.logoName {
                    Image(logoName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                } else {
                    Image(systemName: "building.2.fill")
                        .font(.largeTitle)
                        .foregroundColor(Color(hex: "00F5A0"))
                }
                
                Text("Connect to \(broker.displayName)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Sign in with your broker account")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color(hex: "0F0F0F"))
    }
    
    var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "00F5A0")))
                .scaleEffect(1.5)
            
            Text("Preparing secure connection...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "1A1A2E"))
    }
}

// MARK: - Web View Component

struct BrokerWebView: UIViewRepresentable {
    let url: URL
    let onNavigationChange: (URL) -> Void
    let onLoadComplete: () -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent() // Don't persist cookies
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        
        // Custom user agent
        webView.customUserAgent = "PipflowApp/1.0 (iOS)"
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: BrokerWebView
        
        init(_ parent: BrokerWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                parent.onNavigationChange(url)
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onLoadComplete()
        }
    }
}

// MARK: - View Model

@MainActor
class BrokerOAuthViewModel: ObservableObject {
    @Published var oauthURL: URL?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var authResult: BrokerOAuthResult?
    
    private let broker: SupportedBroker
    private var authCode: String?
    
    init(broker: SupportedBroker) {
        self.broker = broker
    }
    
    func startOAuthFlow() {
        isLoading = true
        
        // Build OAuth URL based on broker
        guard let authURL = buildOAuthURL() else {
            showError(message: "Failed to create authentication URL")
            return
        }
        
        oauthURL = authURL
        isLoading = false
    }
    
    private func buildOAuthURL() -> URL? {
        var components = URLComponents()
        
        switch broker {
        case .icMarkets:
            components.scheme = "https"
            components.host = "secure.icmarkets.com"
            components.path = "/oauth/authorize"
            components.queryItems = [
                URLQueryItem(name: "client_id", value: "pipflow_app"),
                URLQueryItem(name: "redirect_uri", value: "pipflow://oauth/callback"),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "scope", value: "trading account_info market_data"),
                URLQueryItem(name: "state", value: UUID().uuidString)
            ]
            
        case .xm:
            components.scheme = "https"
            components.host = "my.xm.com"
            components.path = "/api/oauth/authorize"
            components.queryItems = [
                URLQueryItem(name: "client_id", value: "pipflow_ios"),
                URLQueryItem(name: "redirect_uri", value: "pipflow://oauth/callback"),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "scope", value: "read trade")
            ]
            
        case .pepperstone:
            components.scheme = "https"
            components.host = "secure.pepperstone.com"
            components.path = "/oauth2/auth"
            components.queryItems = [
                URLQueryItem(name: "client_id", value: "pipflow"),
                URLQueryItem(name: "redirect_uri", value: "pipflow://oauth/callback"),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "scope", value: "account trading")
            ]
            
        case .oanda:
            components.scheme = "https"
            components.host = "api-fxtrade.oanda.com"
            components.path = "/v3/oauth/authorize"
            components.queryItems = [
                URLQueryItem(name: "client_id", value: "pipflow_mobile"),
                URLQueryItem(name: "redirect_uri", value: "pipflow://oauth/callback"),
                URLQueryItem(name: "response_type", value: "code")
            ]
            
        case .fxcm:
            // FXCM uses a different flow - direct API token
            return URL(string: "https://tradingstation.fxcm.com/api-token-request?app=pipflow")
            
        default:
            return nil
        }
        
        return components.url
    }
    
    func handleNavigationChange(_ url: URL) {
        // Check if this is our redirect URL
        if url.scheme == "pipflow" && url.host == "oauth" && url.path == "/callback" {
            handleOAuthCallback(url)
        }
    }
    
    private func handleOAuthCallback(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            showError(message: "Invalid callback URL")
            return
        }
        
        // Check for error
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            let errorDescription = queryItems.first(where: { $0.name == "error_description" })?.value ?? "Authentication failed"
            showError(message: "\(error): \(errorDescription)")
            return
        }
        
        // Get authorization code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            showError(message: "No authorization code received")
            return
        }
        
        authCode = code
        exchangeCodeForTokens(code: code)
    }
    
    private func exchangeCodeForTokens(code: String) {
        Task {
            do {
                // In a real app, this would call your backend to exchange the code
                // For now, simulate the exchange
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                // Create mock tokens
                let accessToken = "mock_access_token_\(UUID().uuidString)"
                let refreshToken = "mock_refresh_token_\(UUID().uuidString)"
                
                // Get account info
                let accountInfo = BrokerAccountInfo(
                    accountId: "123456",
                    accountName: "Demo Account",
                    serverName: broker.defaultServer,
                    platform: .mt5,
                    leverage: 100,
                    balance: 10000.0,
                    currency: "USD"
                )
                
                authResult = BrokerOAuthResult(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    accountInfo: accountInfo,
                    broker: broker
                )
                
            } catch {
                showError(message: "Failed to complete authentication: \(error.localizedDescription)")
            }
        }
    }
    
    func handleLoadComplete() {
        // Web page loaded
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        isLoading = false
    }
}

// MARK: - Models

enum SupportedBroker: String, CaseIterable {
    case icMarkets = "IC Markets"
    case xm = "XM"
    case pepperstone = "Pepperstone"
    case oanda = "OANDA"
    case fxcm = "FXCM"
    case avatrade = "AvaTrade"
    case fbs = "FBS"
    case hotforex = "HotForex"
    
    var displayName: String {
        rawValue
    }
    
    var logoName: String? {
        // Return asset name if broker logos are added to Assets
        nil
    }
    
    var defaultServer: String {
        switch self {
        case .icMarkets: return "ICMarkets-Live06"
        case .xm: return "XMGlobal-Real 25"
        case .pepperstone: return "Pepperstone-Edge01"
        case .oanda: return "OANDA-v20Live"
        case .fxcm: return "FXCM-USDReal01"
        case .avatrade: return "AvaTrade-Live1"
        case .fbs: return "FBS-Real"
        case .hotforex: return "HotForex-Live2"
        }
    }
    
    var supportsOAuth: Bool {
        switch self {
        case .icMarkets, .xm, .pepperstone, .oanda:
            return true
        default:
            return false
        }
    }
}

struct BrokerOAuthResult: Equatable {
    let accessToken: String
    let refreshToken: String
    let accountInfo: BrokerAccountInfo
    let broker: SupportedBroker
}

enum MTAccountPlatform: String, Codable {
    case mt4 = "MT4"
    case mt5 = "MT5"
}

struct BrokerAccountInfo: Equatable {
    let accountId: String
    let accountName: String
    let serverName: String
    let platform: MTAccountPlatform
    let leverage: Int
    let balance: Double
    let currency: String
}

// MARK: - Helpers

// Using different name to avoid conflicts
struct BrokerRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    BrokerOAuthView(broker: .icMarkets) { result in
        print("OAuth completed: \(result)")
    }
}