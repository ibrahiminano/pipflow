//
//  PIPSTokenService.swift
//  Pipflow
//
//  Service for managing PIPS token operations
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PIPSTokenService: ObservableObject {
    static let shared = PIPSTokenService()
    
    // MARK: - Published Properties
    
    @Published var wallet: PIPSWallet?
    @Published var isLoading = false
    @Published var transactions: [PIPSTransaction] = []
    @Published var tokenStats: PIPSTokenStats?
    @Published var exchangeRates: [SupportedCrypto: Double] = [:]
    @Published var pendingOperations: [PendingOperation] = []
    @Published var stakingTier: StakingTier?
    
    // MARK: - Private Properties
    
    private let supabaseService = SupabaseService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    struct PendingOperation {
        let id = UUID()
        let type: OperationType
        let fee: Double
        let status: OperationStatus
    }
    
    enum OperationStatus {
        case pending
        case awaitingPayment
        case processing
        case completed
        case failed
    }
    
    // MARK: - Initialization
    
    private init() {
        setupSubscriptions()
        startRateRefresh()
        loadMockData()
        
        // Initialize demo wallet immediately
        Task {
            await loadWallet(for: "demo-user")
        }
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        authService.$currentUser
            .sink { [weak self] user in
                if let userId = user?.id {
                    Task {
                        await self?.loadWallet(for: userId.uuidString)
                    }
                } else {
                    self?.wallet = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func startRateRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await self.refreshExchangeRates()
            }
        }
    }
    
    // MARK: - Wallet Operations
    
    func loadWallet(for userId: String) async {
        print("PIPSTokenService: Loading wallet for user: \(userId)")
        isLoading = true
        
        // In production, load from blockchain/database
        // For now, create mock wallet
        wallet = PIPSWallet(
            userId: userId,
            address: generateWalletAddress(),
            balance: 1000, // Starting balance
            pendingBalance: 0,
            lockedBalance: 0,
            totalEarned: 250,
            totalSpent: 50,
            lastUpdated: Date(),
            transactions: [],
            stakingInfo: nil
        )
        
        print("PIPSTokenService: Wallet created with balance: \(wallet?.balance ?? 0)")
        
        await loadTransactionHistory()
        isLoading = false
    }
    
    func createWallet() async throws {
        guard let userId = authService.currentUser?.id else {
            throw TokenError.userNotAuthenticated
        }
        
        let address = generateWalletAddress()
        
        wallet = PIPSWallet(
            userId: userId.uuidString,
            address: address,
            balance: 100, // Welcome bonus
            pendingBalance: 0,
            lockedBalance: 0,
            totalEarned: 100,
            totalSpent: 0,
            lastUpdated: Date(),
            transactions: [
                PIPSTransaction(
                    transactionHash: generateTransactionHash(),
                    type: .reward,
                    amount: 100,
                    fee: 0,
                    status: .confirmed,
                    fromAddress: "SYSTEM",
                    toAddress: address,
                    timestamp: Date(),
                    description: "Welcome bonus",
                    category: .system,
                    metadata: ["type": "welcome_bonus"]
                )
            ],
            stakingInfo: nil
        )
    }
    
    // MARK: - Token Operations
    
    func checkBalance(for operation: OperationType) -> (canAfford: Bool, fee: Double, discountedFee: Double) {
        let baseFee = GasFeeStructure.getFee(for: operation)
        let discountedFee = GasFeeStructure.getFee(for: operation, tier: stakingTier)
        let canAfford = (wallet?.balance ?? 0) >= discountedFee
        
        return (canAfford, baseFee, discountedFee)
    }
    
    func executeOperation(_ operation: OperationType, completion: @escaping (Result<PIPSTransaction, Error>) -> Void) async {
        guard let wallet = wallet else {
            completion(.failure(TokenError.walletNotFound))
            return
        }
        
        let (canAfford, _, fee) = checkBalance(for: operation)
        
        guard canAfford else {
            completion(.failure(TokenError.insufficientBalance))
            return
        }
        
        // Create transaction
        let transaction = PIPSTransaction(
            transactionHash: generateTransactionHash(),
            type: .gasFee,
            amount: -fee,
            fee: fee,
            status: .pending,
            fromAddress: wallet.address,
            toAddress: "GAS_FEE_COLLECTOR",
            timestamp: Date(),
            description: operation.displayName,
            category: categorizeOperation(operation),
            metadata: ["operation": operation.rawValue]
        )
        
        // Add to pending
        pendingOperations.append(PendingOperation(
            type: operation,
            fee: fee,
            status: .processing
        ))
        
        // Simulate processing
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Update balance
        self.wallet?.balance -= fee
        self.wallet?.totalSpent += fee
        self.wallet?.transactions.append(transaction)
        
        // Update transaction status
        if var updatedTransaction = self.wallet?.transactions.last {
            updatedTransaction.status = .confirmed
            completion(.success(updatedTransaction))
        }
        
        // Remove from pending
        pendingOperations.removeAll { $0.type == operation }
    }
    
    // MARK: - Deposit Operations
    
    func depositCrypto(_ crypto: SupportedCrypto, amount: Double) async throws -> CryptoDeposit {
        guard amount >= crypto.minimumDeposit else {
            throw TokenError.amountBelowMinimum
        }
        
        let exchangeRate = exchangeRates[crypto] ?? 1.0
        let pipsAmount = amount * exchangeRate
        let depositAddress = generateDepositAddress(for: crypto)
        
        return CryptoDeposit(
            cryptocurrency: crypto,
            amount: amount,
            exchangeRate: exchangeRate,
            pipsAmount: pipsAmount,
            depositAddress: depositAddress,
            minimumDeposit: crypto.minimumDeposit,
            networkFee: calculateNetworkFee(crypto, amount: amount),
            confirmations: requiredConfirmations(for: crypto)
        )
    }
    
    func confirmDeposit(_ deposit: CryptoDeposit, transactionHash: String) async throws {
        guard var wallet = wallet else {
            throw TokenError.walletNotFound
        }
        
        let transaction = PIPSTransaction(
            transactionHash: transactionHash,
            type: .deposit,
            amount: deposit.pipsAmount,
            fee: 0,
            status: .pending,
            fromAddress: nil,
            toAddress: wallet.address,
            timestamp: Date(),
            description: "Deposit \(deposit.amount) \(deposit.cryptocurrency.rawValue)",
            category: .system,
            metadata: [
                "crypto": deposit.cryptocurrency.rawValue,
                "amount": String(deposit.amount),
                "rate": String(deposit.exchangeRate)
            ]
        )
        
        wallet.pendingBalance += deposit.pipsAmount
        wallet.transactions.append(transaction)
        self.wallet = wallet
        
        // Simulate confirmation delay
        try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
        
        // Confirm transaction
        self.wallet?.pendingBalance -= deposit.pipsAmount
        self.wallet?.balance += deposit.pipsAmount
        self.wallet?.totalEarned += deposit.pipsAmount
        
        if let index = self.wallet?.transactions.firstIndex(where: { $0.transactionHash == transactionHash }) {
            self.wallet?.transactions[index].status = .confirmed
        }
    }
    
    // MARK: - Staking Operations
    
    func stake(amount: Double, period: TimeInterval) async throws {
        guard let wallet = wallet else {
            throw TokenError.walletNotFound
        }
        
        guard wallet.balance >= amount else {
            throw TokenError.insufficientBalance
        }
        
        // Determine tier
        let tier = StakingTier.allCases.reversed().first { amount >= $0.minimumStake } ?? .bronze
        
        let stakingInfo = StakingInfo(
            stakedAmount: amount,
            stakingStartDate: Date(),
            lockPeriod: period,
            apy: tier.benefits.apy,
            rewards: 0,
            tier: tier
        )
        
        self.wallet?.balance -= amount
        self.wallet?.lockedBalance += amount
        self.wallet?.stakingInfo = stakingInfo
        self.stakingTier = tier
        
        // Create staking transaction
        let transaction = PIPSTransaction(
            transactionHash: generateTransactionHash(),
            type: .stake,
            amount: -amount,
            fee: 0,
            status: .confirmed,
            fromAddress: wallet.address,
            toAddress: "STAKING_CONTRACT",
            timestamp: Date(),
            description: "Stake \(amount) PIPS for \(Int(period / 86400)) days",
            category: .system,
            metadata: ["tier": tier.rawValue]
        )
        
        self.wallet?.transactions.append(transaction)
    }
    
    func claimStakingRewards() async throws {
        guard var stakingInfo = wallet?.stakingInfo else {
            throw TokenError.noActiveStaking
        }
        
        let daysSinceStaking = Date().timeIntervalSince(stakingInfo.stakingStartDate) / 86400
        let rewards = calculateStakingRewards(
            amount: stakingInfo.stakedAmount,
            apy: stakingInfo.apy,
            days: daysSinceStaking
        )
        
        wallet?.balance += rewards
        stakingInfo.rewards = 0
        wallet?.stakingInfo = stakingInfo
        
        let transaction = PIPSTransaction(
            transactionHash: generateTransactionHash(),
            type: .reward,
            amount: rewards,
            fee: 0,
            status: .confirmed,
            fromAddress: "STAKING_CONTRACT",
            toAddress: wallet?.address ?? "",
            timestamp: Date(),
            description: "Staking rewards",
            category: .system,
            metadata: ["days": String(Int(daysSinceStaking))]
        )
        
        wallet?.transactions.append(transaction)
    }
    
    // MARK: - Reward Operations
    
    func claimReward(_ type: RewardType) async throws {
        guard let reward = RewardSystem.rewards[type] else {
            throw TokenError.invalidReward
        }
        
        wallet?.balance += reward
        wallet?.totalEarned += reward
        
        let transaction = PIPSTransaction(
            transactionHash: generateTransactionHash(),
            type: .reward,
            amount: reward,
            fee: 0,
            status: .confirmed,
            fromAddress: "REWARD_POOL",
            toAddress: wallet?.address ?? "",
            timestamp: Date(),
            description: type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
            category: .achievement,
            metadata: ["reward_type": type.rawValue]
        )
        
        wallet?.transactions.append(transaction)
    }
    
    // MARK: - Transfer Operations
    
    func transfer(to address: String, amount: Double) async throws {
        guard let wallet = wallet else {
            throw TokenError.walletNotFound
        }
        
        let transferFee = 2.5 // PIPS
        let totalAmount = amount + transferFee
        
        guard wallet.balance >= totalAmount else {
            throw TokenError.insufficientBalance
        }
        
        self.wallet?.balance -= totalAmount
        self.wallet?.totalSpent += amount
        
        let transaction = PIPSTransaction(
            transactionHash: generateTransactionHash(),
            type: .transfer,
            amount: -amount,
            fee: transferFee,
            status: .confirmed,
            fromAddress: wallet.address,
            toAddress: address,
            timestamp: Date(),
            description: "Transfer to \(address.prefix(8))...",
            category: .system,
            metadata: nil
        )
        
        self.wallet?.transactions.append(transaction)
    }
    
    // MARK: - Private Helpers
    
    private func loadTransactionHistory() async {
        // In production, load from blockchain/database
        // For now, generate mock transactions
        transactions = generateMockTransactions()
        wallet?.transactions = transactions
    }
    
    private func refreshExchangeRates() async {
        // In production, fetch from exchange APIs
        // For now, use mock rates
        exchangeRates = [
            .bitcoin: 0.00002,     // 1 BTC = 50,000 PIPS
            .ethereum: 0.0003,     // 1 ETH = 3,333 PIPS
            .usdt: 1.0,           // 1 USDT = 1 PIPS
            .usdc: 1.0,           // 1 USDC = 1 PIPS
            .bnb: 0.003,          // 1 BNB = 333 PIPS
            .sol: 0.02,           // 1 SOL = 50 PIPS
            .matic: 1.2           // 1 MATIC = 0.83 PIPS
        ]
    }
    
    private func generateWalletAddress() -> String {
        let characters = "0123456789ABCDEF"
        let length = 40
        return "0x" + String((0..<length).map { _ in characters.randomElement()! })
    }
    
    private func generateTransactionHash() -> String {
        let characters = "0123456789abcdef"
        let length = 64
        return "0x" + String((0..<length).map { _ in characters.randomElement()! })
    }
    
    private func generateDepositAddress(for crypto: SupportedCrypto) -> String {
        switch crypto {
        case .bitcoin:
            return "bc1q" + String((0..<38).map { _ in "0123456789abcdefghijklmnopqrstuvwxyz".randomElement()! })
        case .ethereum, .usdt, .usdc, .bnb, .matic:
            return generateWalletAddress()
        case .sol:
            return String((0..<44).map { _ in "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".randomElement()! })
        }
    }
    
    private func calculateNetworkFee(_ crypto: SupportedCrypto, amount: Double) -> Double {
        switch crypto {
        case .bitcoin: return 0.00001
        case .ethereum: return 0.001
        case .usdt, .usdc: return 1.0
        case .bnb: return 0.001
        case .sol: return 0.00025
        case .matic: return 0.01
        }
    }
    
    private func requiredConfirmations(for crypto: SupportedCrypto) -> Int {
        switch crypto {
        case .bitcoin: return 3
        case .ethereum: return 12
        case .usdt, .usdc: return 12
        case .bnb: return 15
        case .sol: return 30
        case .matic: return 128
        }
    }
    
    private func calculateStakingRewards(amount: Double, apy: Double, days: Double) -> Double {
        let dailyRate = apy / 365 / 100
        return amount * dailyRate * days
    }
    
    private func categorizeOperation(_ operation: OperationType) -> TransactionCategory {
        switch operation {
        case .createSignal, .copyTrade, .executeStrategy, .generateAISignal, .backtest, .optimizeStrategy:
            return .trading
        case .shareStrategy, .sendMessage, .createPost:
            return .social
        case .accessPremiumContent:
            return .education
        case .exportData, .apiAccess:
            return .system
        }
    }
    
    private func generateMockTransactions() -> [PIPSTransaction] {
        return [
            PIPSTransaction(
                transactionHash: generateTransactionHash(),
                type: .reward,
                amount: 100,
                fee: 0,
                status: .confirmed,
                fromAddress: "SYSTEM",
                toAddress: wallet?.address ?? "",
                timestamp: Date().addingTimeInterval(-86400 * 7),
                description: "Welcome bonus",
                category: .system,
                metadata: nil
            ),
            PIPSTransaction(
                transactionHash: generateTransactionHash(),
                type: .gasFee,
                amount: -10,
                fee: 10,
                status: .confirmed,
                fromAddress: wallet?.address ?? "",
                toAddress: "GAS_FEE_COLLECTOR",
                timestamp: Date().addingTimeInterval(-86400 * 5),
                description: "Create Trading Signal",
                category: .trading,
                metadata: nil
            ),
            PIPSTransaction(
                transactionHash: generateTransactionHash(),
                type: .reward,
                amount: 50,
                fee: 0,
                status: .confirmed,
                fromAddress: "REWARD_POOL",
                toAddress: wallet?.address ?? "",
                timestamp: Date().addingTimeInterval(-86400 * 3),
                description: "First Trade",
                category: .achievement,
                metadata: nil
            )
        ]
    }
    
    private func loadMockData() {
        tokenStats = PIPSTokenStats(
            totalSupply: 1_000_000_000,
            circulatingSupply: 250_000_000,
            price: 0.01,
            marketCap: 2_500_000,
            volume24h: 150_000,
            priceChange24h: 2.5,
            holders: 15_000,
            transactions24h: 25_000,
            burnedTokens: 10_000_000
        )
    }
}

// MARK: - Token Errors

enum TokenError: LocalizedError {
    case userNotAuthenticated
    case walletNotFound
    case insufficientBalance
    case invalidReward
    case amountBelowMinimum
    case noActiveStaking
    case transactionFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated"
        case .walletNotFound:
            return "Wallet not found"
        case .insufficientBalance:
            return "Insufficient PIPS balance"
        case .invalidReward:
            return "Invalid reward type"
        case .amountBelowMinimum:
            return "Amount below minimum required"
        case .noActiveStaking:
            return "No active staking found"
        case .transactionFailed:
            return "Transaction failed"
        case .networkError:
            return "Network error occurred"
        }
    }
}