//
//  PIPSToken.swift
//  Pipflow
//
//  PIPS Token economy models and types
//

import Foundation

// MARK: - PIPS Token Models

struct PIPSWallet: Codable, Identifiable {
    let id = UUID()
    let userId: String
    var address: String
    var balance: Double
    var pendingBalance: Double
    var lockedBalance: Double
    var totalEarned: Double
    var totalSpent: Double
    var lastUpdated: Date
    var transactions: [PIPSTransaction]
    var stakingInfo: StakingInfo?
}

struct PIPSTransaction: Codable, Identifiable {
    let id = UUID()
    let transactionHash: String
    let type: TransactionType
    let amount: Double
    let fee: Double
    var status: TransactionStatus
    let fromAddress: String?
    let toAddress: String?
    let timestamp: Date
    let description: String
    let category: TransactionCategory
    let metadata: [String: String]?
}

enum TransactionType: String, Codable, CaseIterable {
    case deposit = "deposit"
    case withdrawal = "withdrawal"
    case gasFee = "gas_fee"
    case reward = "reward"
    case purchase = "purchase"
    case transfer = "transfer"
    case stake = "stake"
    case unstake = "unstake"
    case referral = "referral"
}

enum TransactionStatus: String, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case failed = "failed"
    case cancelled = "cancelled"
}

enum TransactionCategory: String, Codable {
    case trading = "trading"
    case signals = "signals"
    case social = "social"
    case education = "education"
    case achievement = "achievement"
    case system = "system"
}

struct StakingInfo: Codable {
    let stakedAmount: Double
    let stakingStartDate: Date
    let lockPeriod: TimeInterval
    let apy: Double
    var rewards: Double
    let tier: StakingTier
}

enum StakingTier: String, Codable, CaseIterable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case diamond = "diamond"
    
    var minimumStake: Double {
        switch self {
        case .bronze: return 1000
        case .silver: return 5000
        case .gold: return 10000
        case .platinum: return 50000
        case .diamond: return 100000
        }
    }
    
    var benefits: StakingBenefits {
        switch self {
        case .bronze:
            return StakingBenefits(
                apy: 5.0,
                feeDiscount: 10,
                signalPriority: false,
                exclusiveFeatures: []
            )
        case .silver:
            return StakingBenefits(
                apy: 8.0,
                feeDiscount: 20,
                signalPriority: false,
                exclusiveFeatures: ["advanced_analytics"]
            )
        case .gold:
            return StakingBenefits(
                apy: 12.0,
                feeDiscount: 30,
                signalPriority: true,
                exclusiveFeatures: ["advanced_analytics", "ai_insights"]
            )
        case .platinum:
            return StakingBenefits(
                apy: 15.0,
                feeDiscount: 40,
                signalPriority: true,
                exclusiveFeatures: ["advanced_analytics", "ai_insights", "vip_support"]
            )
        case .diamond:
            return StakingBenefits(
                apy: 20.0,
                feeDiscount: 50,
                signalPriority: true,
                exclusiveFeatures: ["advanced_analytics", "ai_insights", "vip_support", "exclusive_strategies"]
            )
        }
    }
}

struct StakingBenefits {
    let apy: Double
    let feeDiscount: Int // Percentage
    let signalPriority: Bool
    let exclusiveFeatures: [String]
}

// MARK: - Gas Fee Structure

struct GasFeeStructure {
    static let fees: [OperationType: Double] = [
        .createSignal: 10,
        .copyTrade: 5,
        .executeStrategy: 15,
        .generateAISignal: 25,
        .backtest: 20,
        .optimizeStrategy: 30,
        .shareStrategy: 10,
        .sendMessage: 1,
        .createPost: 2,
        .accessPremiumContent: 5,
        .exportData: 10,
        .apiAccess: 50
    ]
    
    static func getFee(for operation: OperationType, tier: StakingTier? = nil) -> Double {
        let baseFee = fees[operation] ?? 0
        if let tier = tier {
            let discount = Double(tier.benefits.feeDiscount) / 100
            return baseFee * (1 - discount)
        }
        return baseFee
    }
}

enum OperationType: String, CaseIterable {
    case createSignal = "create_signal"
    case copyTrade = "copy_trade"
    case executeStrategy = "execute_strategy"
    case generateAISignal = "generate_ai_signal"
    case backtest = "backtest"
    case optimizeStrategy = "optimize_strategy"
    case shareStrategy = "share_strategy"
    case sendMessage = "send_message"
    case createPost = "create_post"
    case accessPremiumContent = "access_premium_content"
    case exportData = "export_data"
    case apiAccess = "api_access"
    
    var displayName: String {
        switch self {
        case .createSignal: return "Create Trading Signal"
        case .copyTrade: return "Copy Trade"
        case .executeStrategy: return "Execute Strategy"
        case .generateAISignal: return "Generate AI Signal"
        case .backtest: return "Run Backtest"
        case .optimizeStrategy: return "Optimize Strategy"
        case .shareStrategy: return "Share Strategy"
        case .sendMessage: return "Send Message"
        case .createPost: return "Create Post"
        case .accessPremiumContent: return "Access Premium Content"
        case .exportData: return "Export Data"
        case .apiAccess: return "API Access"
        }
    }
}

// MARK: - Reward System

struct RewardSystem {
    static let rewards: [RewardType: Double] = [
        .dailyLogin: 5,
        .firstTrade: 50,
        .profitableTrade: 10,
        .winStreak5: 25,
        .winStreak10: 50,
        .referralSignup: 100,
        .referralTrade: 20,
        .shareStrategy: 15,
        .helpfulReview: 10,
        .completeCourse: 30,
        .passQuiz: 15,
        .achievementUnlock: 20,
        .leaderboardTop10: 100,
        .leaderboardTop3: 500,
        .leaderboardWinner: 1000
    ]
}

enum RewardType: String, CaseIterable {
    case dailyLogin
    case firstTrade
    case profitableTrade
    case winStreak5
    case winStreak10
    case referralSignup
    case referralTrade
    case shareStrategy
    case helpfulReview
    case completeCourse
    case passQuiz
    case achievementUnlock
    case leaderboardTop10
    case leaderboardTop3
    case leaderboardWinner
}

// MARK: - Crypto Integration

struct CryptoDeposit {
    let cryptocurrency: SupportedCrypto
    let amount: Double
    let exchangeRate: Double
    let pipsAmount: Double
    let depositAddress: String
    let minimumDeposit: Double
    let networkFee: Double
    let confirmations: Int
}

enum SupportedCrypto: String, CaseIterable {
    case bitcoin = "BTC"
    case ethereum = "ETH"
    case usdt = "USDT"
    case usdc = "USDC"
    case bnb = "BNB"
    case sol = "SOL"
    case matic = "MATIC"
    
    var displayName: String {
        switch self {
        case .bitcoin: return "Bitcoin"
        case .ethereum: return "Ethereum"
        case .usdt: return "Tether (USDT)"
        case .usdc: return "USD Coin"
        case .bnb: return "BNB"
        case .sol: return "Solana"
        case .matic: return "Polygon"
        }
    }
    
    var minimumDeposit: Double {
        switch self {
        case .bitcoin: return 0.0001
        case .ethereum: return 0.001
        case .usdt, .usdc: return 10
        case .bnb: return 0.01
        case .sol: return 0.1
        case .matic: return 10
        }
    }
}

// MARK: - Token Statistics

struct PIPSTokenStats {
    let totalSupply: Double
    let circulatingSupply: Double
    let price: Double
    let marketCap: Double
    let volume24h: Double
    let priceChange24h: Double
    let holders: Int
    let transactions24h: Int
    let burnedTokens: Double
}

// MARK: - Challenge System

struct TradingChallenge: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let startDate: Date
    let endDate: Date
    let entryFee: Double // In PIPS
    let prizePool: Double // In PIPS
    let rules: ChallengeRules
    let participants: [ChallengeParticipant]
    let status: ChallengeStatus
    let category: ChallengeCategory
}

struct ChallengeRules {
    let minimumTrades: Int
    let allowedSymbols: [String]?
    let maximumDrawdown: Double
    let profitTarget: Double?
    let duration: TimeInterval
    let startingBalance: Double
}

struct ChallengeParticipant: Identifiable {
    let id = UUID()
    let userId: String
    let username: String
    let joinedAt: Date
    var currentRank: Int
    var performance: ChallengePerformance
    var pipsWon: Double
}

struct ChallengePerformance {
    let totalReturn: Double
    let winRate: Double
    let totalTrades: Int
    let currentDrawdown: Double
    let bestTrade: Double
    let worstTrade: Double
}

enum ChallengeStatus: String {
    case upcoming
    case active
    case completed
    case cancelled
}

enum ChallengeCategory: String, CaseIterable {
    case scalping
    case dayTrading
    case swingTrading
    case riskManagement
    case profitability
    case consistency
}