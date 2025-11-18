//
//  PIPSWalletView.swift
//  Pipflow
//
//  PIPS token wallet interface
//

import SwiftUI

struct PIPSWalletView: View {
    @StateObject private var tokenService = PIPSTokenService.shared
    @State private var selectedTab = 0
    @State private var showDepositSheet = false
    @State private var showTransferSheet = false
    @State private var showStakingSheet = false
    @State private var showTransactionDetail: PIPSTransaction?
    
    var body: some View {
        VStack(spacing: 0) {
            // Wallet Header
            walletHeader
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.Theme.accent, Color.Theme.accent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Tab Selection
            Picker("", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Transactions").tag(1)
                Text("Staking").tag(2)
                Text("Rewards").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Tab Content
            Group {
                switch selectedTab {
                case 0:
                    overviewTab
                case 1:
                    transactionsTab
                case 2:
                    stakingTab
                case 3:
                    rewardsTab
                default:
                    overviewTab
                }
            }
            .frame(maxHeight: .infinity)
        }
        .navigationTitle("PIPS Wallet")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showDepositSheet = true }) {
                    Label("Deposit", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showDepositSheet) {
            DepositView()
        }
        .sheet(isPresented: $showTransferSheet) {
            TransferView()
        }
        .sheet(isPresented: $showStakingSheet) {
            StakingView()
        }
        .sheet(item: $showTransactionDetail) { transaction in
            TransactionDetailView(transaction: transaction)
        }
    }
    
    // MARK: - Wallet Header
    
    private var walletHeader: some View {
        VStack(spacing: 16) {
            // Balance
            VStack(spacing: 8) {
                Text("Total Balance")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(Int(tokenService.wallet?.balance ?? 0))")
                        .font(.system(size: 48, weight: .bold))
                    Text("PIPS")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 8)
                }
                .foregroundColor(.white)
                
                // USD Value
                if let stats = tokenService.tokenStats {
                    Text("≈ $\(String(format: "%.2f", (tokenService.wallet?.balance ?? 0) * stats.price))")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                ActionButton(
                    title: "Deposit",
                    icon: "arrow.down.circle",
                    action: { showDepositSheet = true }
                )
                
                ActionButton(
                    title: "Transfer",
                    icon: "arrow.up.arrow.down.circle",
                    action: { showTransferSheet = true }
                )
                
                ActionButton(
                    title: "Stake",
                    icon: "lock.circle",
                    action: { showStakingSheet = true }
                )
            }
            
            // Wallet Address
            if let address = tokenService.wallet?.address {
                HStack {
                    Text(address.prefix(8) + "..." + address.suffix(6))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button(action: {
                        UIPasteboard.general.string = address
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Token Stats
                if let stats = tokenService.tokenStats {
                    TokenStatsCard(stats: stats)
                }
                
                // Balance Breakdown
                if let wallet = tokenService.wallet {
                    BalanceBreakdownCard(wallet: wallet)
                }
                
                // Gas Fee Calculator
                GasFeeCalculatorCard()
                
                // Staking Benefits
                if let tier = tokenService.stakingTier {
                    StakingBenefitsCard(tier: tier)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Transactions Tab
    
    private var transactionsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tokenService.wallet?.transactions ?? []) { transaction in
                    TransactionRow(transaction: transaction)
                        .onTapGesture {
                            showTransactionDetail = transaction
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Staking Tab
    
    private var stakingTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Staking
                if let stakingInfo = tokenService.wallet?.stakingInfo {
                    CurrentStakingCard(stakingInfo: stakingInfo)
                }
                
                // Staking Tiers
                StakingTiersCard()
                
                // Staking Calculator
                StakingCalculatorCard()
            }
            .padding()
        }
    }
    
    // MARK: - Rewards Tab
    
    private var rewardsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Available Rewards
                AvailableRewardsCard()
                
                // Reward History
                RewardHistoryCard(transactions: tokenService.wallet?.transactions ?? [])
                
                // Referral Program
                ReferralProgramCard()
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

struct TokenStatsCard: View {
    let stats: PIPSTokenStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PIPS Token Stats")
                .font(.headline)
            
            VStack(spacing: 12) {
                StatRow(label: "Price", value: "$\(String(format: "%.4f", stats.price))")
                StatRow(label: "24h Change", value: "\(stats.priceChange24h > 0 ? "+" : "")\(String(format: "%.2f", stats.priceChange24h))%", color: stats.priceChange24h > 0 ? .green : .red)
                StatRow(label: "Market Cap", value: "$\(formatNumber(stats.marketCap))")
                StatRow(label: "24h Volume", value: "$\(formatNumber(stats.volume24h))")
                StatRow(label: "Holders", value: formatNumber(Double(stats.holders)))
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(Color.Theme.secondaryText)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct BalanceBreakdownCard: View {
    let wallet: PIPSWallet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Balance Breakdown")
                .font(.headline)
            
            VStack(spacing: 12) {
                BalanceRow(label: "Available", amount: wallet.balance, color: .green)
                BalanceRow(label: "Pending", amount: wallet.pendingBalance, color: .orange)
                BalanceRow(label: "Staked", amount: wallet.lockedBalance, color: .blue)
                Divider()
                BalanceRow(label: "Total Earned", amount: wallet.totalEarned, color: .green)
                BalanceRow(label: "Total Spent", amount: wallet.totalSpent, color: .red)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct BalanceRow: View {
    let label: String
    let amount: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(Color.Theme.secondaryText)
            Spacer()
            Text("\(Int(amount)) PIPS")
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct GasFeeCalculatorCard: View {
    @State private var selectedOperation: OperationType = .createSignal
    @StateObject private var tokenService = PIPSTokenService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gas Fee Calculator")
                .font(.headline)
            
            // Operation Picker
            Picker("Operation", selection: $selectedOperation) {
                ForEach(OperationType.allCases, id: \.self) { operation in
                    Text(operation.displayName).tag(operation)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            // Fee Display
            let (canAfford, baseFee, discountedFee) = tokenService.checkBalance(for: selectedOperation)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Base Fee:")
                    Spacer()
                    Text("\(Int(baseFee)) PIPS")
                        .fontWeight(.medium)
                }
                
                if let tier = tokenService.stakingTier {
                    HStack {
                        Text("Your Discount (\(tier.rawValue.capitalized)):")
                        Spacer()
                        Text("-\(tier.benefits.feeDiscount)%")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Final Fee:")
                        Spacer()
                        Text("\(Int(discountedFee)) PIPS")
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                    }
                }
                
                if !canAfford {
                    Label("Insufficient balance", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct TransactionRow: View {
    let transaction: PIPSTransaction
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: iconForTransaction(transaction))
                .foregroundColor(colorForTransaction(transaction))
                .frame(width: 40, height: 40)
                .background(colorForTransaction(transaction).opacity(0.1))
                .cornerRadius(20)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.timestamp.formatted())
                    .font(.caption)
                    .foregroundColor(Color.Theme.secondaryText)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(transaction.amount > 0 ? "+" : "")\(Int(transaction.amount)) PIPS")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.amount > 0 ? .green : .red)
                
                if transaction.fee > 0 {
                    Text("Fee: \(Int(transaction.fee))")
                        .font(.caption2)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
        }
        .padding()
        .background(Color.Theme.secondary.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func iconForTransaction(_ transaction: PIPSTransaction) -> String {
        switch transaction.type {
        case .deposit: return "arrow.down.circle.fill"
        case .withdrawal: return "arrow.up.circle.fill"
        case .gasFee: return "flame.fill"
        case .reward: return "gift.fill"
        case .purchase: return "cart.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .stake: return "lock.fill"
        case .unstake: return "lock.open.fill"
        case .referral: return "person.2.fill"
        }
    }
    
    private func colorForTransaction(_ transaction: PIPSTransaction) -> Color {
        switch transaction.type {
        case .deposit, .reward, .referral, .unstake:
            return .green
        case .withdrawal, .gasFee, .purchase, .stake:
            return .red
        case .transfer:
            return .blue
        }
    }
}

#Preview {
    PIPSWalletView()
        .preferredColorScheme(.dark)
}