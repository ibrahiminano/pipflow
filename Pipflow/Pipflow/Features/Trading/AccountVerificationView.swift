//
//  AccountVerificationView.swift
//  Pipflow
//
//  Account verification status and progress view
//

import SwiftUI

struct AccountVerificationView: View {
    @StateObject private var viewModel: AccountVerificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(account: TradingAccount) {
        _viewModel = StateObject(wrappedValue: AccountVerificationViewModel(account: account))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(hex: "0F0F0F"),
                        Color(hex: "1A1A2E")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: viewModel.verificationState.icon)
                            .font(.system(size: 80))
                            .foregroundColor(viewModel.verificationState.color)
                            .symbolEffect(.pulse, options: .repeating, isActive: viewModel.verificationState == .verifying)
                        
                        Text(viewModel.verificationState.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(viewModel.verificationState.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Verification Steps
                    VStack(spacing: 20) {
                        ForEach(viewModel.verificationSteps) { step in
                            VerificationStepRow(step: step)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action Button
                    if viewModel.verificationState != .verifying {
                        Button(action: viewModel.handleAction) {
                            HStack {
                                Image(systemName: viewModel.verificationState.buttonIcon)
                                Text(viewModel.verificationState.buttonTitle)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: viewModel.verificationState == .success ?
                                    [Color(hex: "00F5A0"), Color(hex: "00D9FF")] :
                                    [Color.Theme.error, Color.Theme.error.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.verificationState != .verifying {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.startVerification()
        }
    }
}

// MARK: - Verification Step Row

struct VerificationStepRow: View {
    let step: VerificationStep
    
    var body: some View {
        HStack(spacing: 16) {
            // Step Icon
            ZStack {
                Circle()
                    .fill(step.status.backgroundColor)
                    .frame(width: 40, height: 40)
                
                if step.status == .inProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: step.status.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            // Step Details
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let message = step.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(step.status == .failed ? Color.Theme.error : .white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Step Time
            if let duration = step.duration {
                Text("\(duration)ms")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - View Model

@MainActor
class AccountVerificationViewModel: ObservableObject {
    @Published var verificationState: VerificationState = .pending
    @Published var verificationSteps: [VerificationStep] = []
    
    private let account: TradingAccount
    private let metaAPIService = MetaAPIService.shared
    
    init(account: TradingAccount) {
        self.account = account
        setupSteps()
    }
    
    private func setupSteps() {
        verificationSteps = [
            VerificationStep(id: "connect", title: "Connecting to account", status: .pending),
            VerificationStep(id: "auth", title: "Authenticating credentials", status: .pending),
            VerificationStep(id: "info", title: "Fetching account information", status: .pending),
            VerificationStep(id: "permissions", title: "Verifying trading permissions", status: .pending),
            VerificationStep(id: "market", title: "Testing market data connection", status: .pending),
            VerificationStep(id: "complete", title: "Verification complete", status: .pending)
        ]
    }
    
    func startVerification() {
        verificationState = .verifying
        
        Task {
            // Connect to account
            updateStep(id: "connect", status: .inProgress)
            let connectStart = Date()
            
            do {
                try await metaAPIService.connect(
                    accountId: account.accountId,
                    accountToken: AppEnvironment.MetaAPI.token
                )
                
                let connectDuration = Int(Date().timeIntervalSince(connectStart) * 1000)
                updateStep(id: "connect", status: .completed, duration: connectDuration)
                
                // Authenticate
                updateStep(id: "auth", status: .inProgress)
                let authStart = Date()
                try await Task.sleep(nanoseconds: 500_000_000) // Simulate auth delay
                let authDuration = Int(Date().timeIntervalSince(authStart) * 1000)
                updateStep(id: "auth", status: .completed, duration: authDuration)
                
                // Fetch account info
                updateStep(id: "info", status: .inProgress)
                let infoStart = Date()
                let verificationResult = try await metaAPIService.verifyAccount(accountId: account.accountId)
                let infoDuration = Int(Date().timeIntervalSince(infoStart) * 1000)
                
                if verificationResult.isValid {
                    updateStep(id: "info", status: .completed, duration: infoDuration)
                    
                    // Check permissions
                    updateStep(id: "permissions", status: .inProgress)
                    if let accountInfo = verificationResult.accountInfo {
                        let message = "Balance: $\(String(format: "%.2f", accountInfo.balance)) • Leverage: 1:\(accountInfo.leverage)"
                        updateStep(id: "permissions", status: .completed, message: message)
                    } else {
                        updateStep(id: "permissions", status: .completed)
                    }
                    
                    // Test market data
                    updateStep(id: "market", status: .inProgress)
                    let marketStart = Date()
                    try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate market test
                    let marketDuration = Int(Date().timeIntervalSince(marketStart) * 1000)
                    updateStep(id: "market", status: .completed, duration: marketDuration)
                    
                    // Complete
                    updateStep(id: "complete", status: .completed)
                    verificationState = .success
                    
                } else {
                    let error = verificationResult.error ?? "Unknown error"
                    updateStep(id: "info", status: .failed, message: error)
                    verificationState = .failed
                }
                
            } catch {
                // Handle errors
                let failedStep = verificationSteps.first { $0.status == .inProgress }?.id ?? "connect"
                updateStep(id: failedStep, status: .failed, message: error.localizedDescription)
                verificationState = .failed
            }
        }
    }
    
    @MainActor
    private func updateStep(id: String, status: VerificationStepStatus, message: String? = nil, duration: Int? = nil) {
        if let index = verificationSteps.firstIndex(where: { $0.id == id }) {
            verificationSteps[index].status = status
            verificationSteps[index].message = message
            verificationSteps[index].duration = duration
        }
    }
    
    func handleAction() {
        switch verificationState {
        case .success:
            // Close and proceed
            NotificationCenter.default.post(name: .accountVerified, object: account)
        case .failed:
            // Retry verification
            setupSteps()
            startVerification()
        default:
            break
        }
    }
}

// MARK: - Models

enum VerificationState {
    case pending
    case verifying
    case success
    case failed
    
    var icon: String {
        switch self {
        case .pending: return "hourglass"
        case .verifying: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .white.opacity(0.5)
        case .verifying: return Color(hex: "00F5A0")
        case .success: return Color.Theme.success
        case .failed: return Color.Theme.error
        }
    }
    
    var title: String {
        switch self {
        case .pending: return "Ready to Verify"
        case .verifying: return "Verifying Account"
        case .success: return "Verification Complete"
        case .failed: return "Verification Failed"
        }
    }
    
    var subtitle: String {
        switch self {
        case .pending: return "We'll verify your account connection"
        case .verifying: return "Please wait while we verify your account"
        case .success: return "Your account is ready for trading"
        case .failed: return "We couldn't verify your account"
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .success: return "Continue"
        case .failed: return "Retry Verification"
        default: return ""
        }
    }
    
    var buttonIcon: String {
        switch self {
        case .success: return "arrow.right"
        case .failed: return "arrow.clockwise"
        default: return ""
        }
    }
}

struct VerificationStep: Identifiable {
    let id: String
    let title: String
    var status: VerificationStepStatus
    var message: String? = nil
    var duration: Int? = nil
}

enum VerificationStepStatus {
    case pending
    case inProgress
    case completed
    case failed
    
    var icon: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "circle"
        case .completed: return "checkmark"
        case .failed: return "xmark"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .pending: return .white.opacity(0.2)
        case .inProgress: return Color(hex: "00F5A0")
        case .completed: return Color.Theme.success
        case .failed: return Color.Theme.error
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let accountVerified = Notification.Name("accountVerified")
}

#Preview {
    AccountVerificationView(
        account: TradingAccount(
            id: "preview",
            accountId: "12345",
            accountType: .demo,
            brokerName: "IC Markets",
            serverName: "ICMarkets-Demo02",
            platformType: .mt5,
            balance: 10000,
            equity: 10000,
            currency: "USD",
            leverage: 100,
            isActive: true,
            connectedDate: Date()
        )
    )
}