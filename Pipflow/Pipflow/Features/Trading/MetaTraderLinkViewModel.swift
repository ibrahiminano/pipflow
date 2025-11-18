//
//  MetaTraderLinkViewModel.swift
//  Pipflow
//
//  ViewModel for MetaTrader Account Linking
//

import Foundation
import Combine

@MainActor
class MetaTraderLinkViewModel: ObservableObject {
    @Published var selectedPlatform: TradingPlatform = .mt5
    @Published var login = ""
    @Published var password = ""
    @Published var server = ""
    @Published var accountType: MTAccountType = .demo
    @Published var isConnecting = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var connectionSuccess = false
    @Published var connectedAccount: TradingAccount?
    
    private let metaAPIService = MetaAPIService.shared
    private let tradingService = TradingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var isFormValid: Bool {
        !login.isEmpty && !password.isEmpty && !server.isEmpty
    }
    
    func connectAccount() {
        guard isFormValid else { return }
        
        isConnecting = true
        errorMessage = ""
        
        // Set MetaAPI token from environment
        metaAPIService.setAuthToken(AppEnvironment.MetaAPI.token)
        
        metaAPIService.linkAccount(
            login: login,
            password: password,
            server: server,
            platform: selectedPlatform
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isConnecting = false
                
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            },
            receiveValue: { [weak self] account in
                self?.handleSuccessfulConnection(account)
            }
        )
        .store(in: &cancellables)
    }
    
    private func handleError(_ error: APIError) {
        showError = true
        
        switch error {
        case .unauthorized:
            errorMessage = "Invalid login credentials. Please check your account number and password."
        case .serverError(_, let message):
            if message?.contains("server") == true {
                errorMessage = "Server not found. Please check the server name."
            } else if message?.contains("password") == true {
                errorMessage = "Invalid password. Please try again."
            } else {
                errorMessage = message ?? "Connection failed. Please try again."
            }
        case .networkError:
            errorMessage = "Network error. Please check your internet connection."
        default:
            errorMessage = "Failed to connect account. Please try again."
        }
    }
    
    private func handleSuccessfulConnection(_ account: TradingAccount) {
        // Set the connected account for verification
        connectedAccount = account
        connectionSuccess = true
        
        // The verification will be handled by the AccountVerificationView
    }
    
    func storeConnectedAccount(_ account: TradingAccount) {
        // Store in UserDefaults or local database
        var connectedAccounts = getStoredAccounts()
        
        // Check if account already exists
        if !connectedAccounts.contains(where: { $0.accountId == account.accountId }) {
            connectedAccounts.append(account)
            
            if let encoded = try? JSONEncoder().encode(connectedAccounts) {
                UserDefaults.standard.set(encoded, forKey: "connected_trading_accounts")
            }
        }
    }
    
    private func getStoredAccounts() -> [TradingAccount] {
        guard let data = UserDefaults.standard.data(forKey: "connected_trading_accounts"),
              let accounts = try? JSONDecoder().decode([TradingAccount].self, from: data) else {
            return []
        }
        return accounts
    }
    
    // Demo Account Helper
    func fillDemoCredentials() {
        selectedPlatform = .mt5
        login = "5021056"
        password = "demo123"
        server = "ICMarkets-Demo02"
        accountType = .demo
    }
}

// MARK: - Account Type
enum MTAccountType: String, CaseIterable {
    case demo = "Demo"
    case real = "Real"
}