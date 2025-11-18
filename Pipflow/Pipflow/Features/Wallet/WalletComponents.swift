//
//  WalletComponents.swift
//  Pipflow
//
//  Supporting components for PIPS wallet
//

import SwiftUI

// MARK: - Staking Views

struct CurrentStakingCard: View {
    let stakingInfo: StakingInfo
    @StateObject private var tokenService = PIPSTokenService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Staking")
                        .font(.headline)
                    Text("\(stakingInfo.tier.rawValue.capitalized) Tier")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.accent)
                }
                
                Spacer()
                
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(Color.Theme.accent)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Staked Amount")
                    Spacer()
                    Text("\(Int(stakingInfo.stakedAmount)) PIPS")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("APY")
                    Spacer()
                    Text("\(stakingInfo.apy, specifier: "%.1f")%")
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Unlock Date")
                    Spacer()
                    Text(stakingInfo.stakingStartDate.addingTimeInterval(stakingInfo.lockPeriod).formatted(date: .abbreviated, time: .omitted))
                        .fontWeight(.medium)
                }
                
                // Accumulated Rewards
                let daysSinceStaking = Date().timeIntervalSince(stakingInfo.stakingStartDate) / 86400
                let rewards = calculateRewards(amount: stakingInfo.stakedAmount, apy: stakingInfo.apy, days: daysSinceStaking)
                
                HStack {
                    Text("Rewards Earned")
                    Spacer()
                    Text("\(Int(rewards)) PIPS")
                        .fontWeight(.bold)
                        .foregroundColor(Color.Theme.accent)
                }
            }
            
            Button(action: claimRewards) {
                Text("Claim Rewards")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private func calculateRewards(amount: Double, apy: Double, days: Double) -> Double {
        let dailyRate = apy / 365 / 100
        return amount * dailyRate * days
    }
    
    private func claimRewards() {
        Task {
            try? await tokenService.claimStakingRewards()
        }
    }
}

struct StakingTiersCard: View {
    @State private var selectedTier: StakingTier = .bronze
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Staking Tiers")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StakingTier.allCases, id: \.self) { tier in
                        TierCard(tier: tier, isSelected: selectedTier == tier)
                            .onTapGesture {
                                selectedTier = tier
                            }
                    }
                }
            }
            
            // Selected Tier Benefits
            VStack(alignment: .leading, spacing: 12) {
                Text("Benefits")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(spacing: 8) {
                    BenefitRow(icon: "percent", text: "\(selectedTier.benefits.apy)% APY")
                    BenefitRow(icon: "tag.fill", text: "\(selectedTier.benefits.feeDiscount)% Fee Discount")
                    if selectedTier.benefits.signalPriority {
                        BenefitRow(icon: "bell.badge.fill", text: "Priority Signals")
                    }
                    ForEach(selectedTier.benefits.exclusiveFeatures, id: \.self) { feature in
                        BenefitRow(icon: "star.fill", text: feature.replacingOccurrences(of: "_", with: " ").capitalized)
                    }
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct TierCard: View {
    let tier: StakingTier
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconForTier(tier))
                .font(.title2)
            
            Text(tier.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(Int(tier.minimumStake))")
                .font(.caption2)
                .foregroundColor(Color.Theme.secondaryText)
        }
        .frame(width: 100, height: 100)
        .background(isSelected ? Color.Theme.accent : Color.Theme.secondary.opacity(0.3))
        .foregroundColor(isSelected ? .white : Color.Theme.text)
        .cornerRadius(12)
    }
    
    private func iconForTier(_ tier: StakingTier) -> String {
        switch tier {
        case .bronze: return "leaf.fill"
        case .silver: return "star.fill"
        case .gold: return "crown.fill"
        case .platinum: return "sparkles"
        case .diamond: return "diamond.fill"
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.Theme.accent)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Color.Theme.text)
            
            Spacer()
        }
    }
}

// MARK: - Rewards Views

struct AvailableRewardsCard: View {
    @StateObject private var tokenService = PIPSTokenService.shared
    @State private var claimedRewards: Set<RewardType> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Rewards")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(RewardType.allCases, id: \.self) { rewardType in
                    RewardButton(
                        rewardType: rewardType,
                        amount: RewardSystem.rewards[rewardType] ?? 0,
                        isClaimed: claimedRewards.contains(rewardType),
                        action: {
                            claimReward(rewardType)
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private func claimReward(_ type: RewardType) {
        Task {
            do {
                try await tokenService.claimReward(type)
                claimedRewards.insert(type)
            } catch {
                // Handle error
            }
        }
    }
}

struct RewardButton: View {
    let rewardType: RewardType
    let amount: Double
    let isClaimed: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconForReward(rewardType))
                    .font(.title2)
                
                Text(rewardName(rewardType))
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("+\(Int(amount)) PIPS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.Theme.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isClaimed ? Color.Theme.secondary.opacity(0.3) : Color.Theme.accent.opacity(0.1))
                            .foregroundColor(isClaimed ? Color.Theme.secondaryText : Color.Theme.text)
            .cornerRadius(12)
            .overlay(
                isClaimed ? 
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .padding(8)
                : nil,
                alignment: .topTrailing
            )
        }
        .disabled(isClaimed)
    }
    
    private func iconForReward(_ type: RewardType) -> String {
        switch type {
        case .dailyLogin: return "calendar.badge.clock"
        case .firstTrade: return "chart.line.uptrend.xyaxis"
        case .profitableTrade: return "dollarsign.circle"
        case .winStreak5, .winStreak10: return "flame"
        case .referralSignup, .referralTrade: return "person.2"
        case .shareStrategy: return "square.and.arrow.up"
        case .helpfulReview: return "star"
        case .completeCourse, .passQuiz: return "graduationcap"
        case .achievementUnlock: return "trophy"
        case .leaderboardTop10, .leaderboardTop3, .leaderboardWinner: return "crown"
        }
    }
    
    private func rewardName(_ type: RewardType) -> String {
        switch type {
        case .dailyLogin: return "Daily Login"
        case .firstTrade: return "First Trade"
        case .profitableTrade: return "Profitable Trade"
        case .winStreak5: return "5 Win Streak"
        case .winStreak10: return "10 Win Streak"
        case .referralSignup: return "Referral Signup"
        case .referralTrade: return "Referral Trade"
        case .shareStrategy: return "Share Strategy"
        case .helpfulReview: return "Helpful Review"
        case .completeCourse: return "Complete Course"
        case .passQuiz: return "Pass Quiz"
        case .achievementUnlock: return "Achievement"
        case .leaderboardTop10: return "Top 10"
        case .leaderboardTop3: return "Top 3"
        case .leaderboardWinner: return "Winner"
        }
    }
}

struct RewardHistoryCard: View {
    let transactions: [PIPSTransaction]
    
    var rewardTransactions: [PIPSTransaction] {
        transactions.filter { $0.type == .reward }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reward History")
                    .font(.headline)
                
                Spacer()
                
                Text("Total: \(Int(rewardTransactions.reduce(0) { $0 + $1.amount })) PIPS")
                    .font(.caption)
                    .foregroundColor(Color.Theme.accent)
            }
            
            if rewardTransactions.isEmpty {
                Text("No rewards earned yet")
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(rewardTransactions.prefix(5)) { transaction in
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(Color.Theme.accent)
                            
                            Text(transaction.description)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("+\(Int(transaction.amount))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Transfer View

struct TransferView: View {
    @StateObject private var tokenService = PIPSTokenService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var recipientAddress = ""
    @State private var amount = ""
    @State private var isProcessing = false
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Balance Display
                VStack(spacing: 8) {
                    Text("Available Balance")
                        .font(.headline)
                        .foregroundColor(Color.Theme.secondaryText)
                    
                    Text("\(Int(tokenService.wallet?.balance ?? 0)) PIPS")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.Theme.cardBackground)
                .cornerRadius(16)
                
                // Transfer Form
                VStack(spacing: 16) {
                    // Recipient Address
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipient Address")
                            .font(.headline)
                        
                        TextField("0x...", text: $recipientAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.headline)
                        
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Fee Info
                    HStack {
                        Text("Transfer Fee")
                            .foregroundColor(Color.Theme.secondaryText)
                        Spacer()
                        Text("2.5 PIPS")
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color.Theme.secondary.opacity(0.3))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Transfer Button
                Button(action: { showConfirmation = true }) {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Text("Transfer")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.Theme.accent)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(recipientAddress.isEmpty || amount.isEmpty || isProcessing)
            }
            .padding()
            .navigationTitle("Transfer PIPS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: { dismiss() })
                }
            }
        }
        .alert("Confirm Transfer", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Transfer", role: .destructive) {
                performTransfer()
            }
        } message: {
            Text("Transfer \(amount) PIPS to \(recipientAddress.prefix(8))...?")
        }
    }
    
    private func performTransfer() {
        isProcessing = true
        
        Task {
            do {
                try await tokenService.transfer(to: recipientAddress, amount: Double(amount) ?? 0)
                dismiss()
            } catch {
                // Handle error
                isProcessing = false
            }
        }
    }
}

// MARK: - Staking View

struct StakingView: View {
    @StateObject private var tokenService = PIPSTokenService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var amount = ""
    @State private var selectedPeriod: StakingPeriod = .days30
    @State private var isProcessing = false
    
    enum StakingPeriod: CaseIterable {
        case days30
        case days90
        case days180
        case days365
        
        var days: Int {
            switch self {
            case .days30: return 30
            case .days90: return 90
            case .days180: return 180
            case .days365: return 365
            }
        }
        
        var displayName: String {
            switch self {
            case .days30: return "30 Days"
            case .days90: return "90 Days"
            case .days180: return "180 Days"
            case .days365: return "1 Year"
            }
        }
        
        var multiplier: Double {
            switch self {
            case .days30: return 1.0
            case .days90: return 1.2
            case .days180: return 1.5
            case .days365: return 2.0
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Staking Calculator
                StakingCalculatorCard()
                
                // Period Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Lock Period")
                        .font(.headline)
                    
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(StakingPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Amount Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount to Stake")
                        .font(.headline)
                    
                    TextField("0", text: $amount)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Available: \(Int(tokenService.wallet?.balance ?? 0)) PIPS")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
                
                // Projected Returns
                if let amountDouble = Double(amount), amountDouble > 0 {
                    projectectedReturnsView(amount: amountDouble)
                }
                
                Spacer()
                
                // Stake Button
                Button(action: performStaking) {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Text("Stake PIPS")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.Theme.accent)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(amount.isEmpty || isProcessing)
            }
            .padding()
            .navigationTitle("Stake PIPS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: { dismiss() })
                }
            }
        }
    }
    
    private func projectectedReturnsView(amount: Double) -> some View {
        let tier = StakingTier.allCases.reversed().first { amount >= $0.minimumStake } ?? .bronze
        let apy = tier.benefits.apy * selectedPeriod.multiplier
        let returns = amount * (apy / 100) * (Double(selectedPeriod.days) / 365)
        
        return VStack(spacing: 12) {
            HStack {
                Text("Tier")
                Spacer()
                Text(tier.rawValue.capitalized)
                    .fontWeight(.medium)
                    .foregroundColor(Color.Theme.accent)
            }
            
            HStack {
                Text("APY")
                Spacer()
                Text("\(apy, specifier: "%.1f")%")
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("Projected Returns")
                Spacer()
                Text("+\(Int(returns)) PIPS")
                    .fontWeight(.bold)
                    .foregroundColor(Color.Theme.accent)
            }
        }
        .padding()
        .background(Color.Theme.secondary.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func performStaking() {
        guard let amountDouble = Double(amount) else { return }
        
        isProcessing = true
        
        Task {
            do {
                try await tokenService.stake(amount: amountDouble, period: TimeInterval(selectedPeriod.days * 86400))
                dismiss()
            } catch {
                // Handle error
                isProcessing = false
            }
        }
    }
}

struct StakingCalculatorCard: View {
    @State private var testAmount = "10000"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Staking Calculator")
                .font(.headline)
            
            TextField("Test Amount", text: $testAmount)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let amount = Double(testAmount) {
                VStack(spacing: 12) {
                    ForEach(StakingTier.allCases, id: \.self) { tier in
                        if amount >= tier.minimumStake {
                            HStack {
                                Text(tier.rawValue.capitalized)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(tier.benefits.apy)% APY")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct StakingBenefitsCard: View {
    let tier: StakingTier
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Staking Benefits")
                    .font(.headline)
                
                Spacer()
                
                Text(tier.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.Theme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            VStack(spacing: 12) {
                BenefitRow(icon: "percent", text: "\(tier.benefits.apy)% APY")
                BenefitRow(icon: "tag.fill", text: "\(tier.benefits.feeDiscount)% Gas Fee Discount")
                if tier.benefits.signalPriority {
                    BenefitRow(icon: "bell.badge.fill", text: "Priority Signal Access")
                }
                ForEach(tier.benefits.exclusiveFeatures, id: \.self) { feature in
                    BenefitRow(icon: "star.fill", text: feature.replacingOccurrences(of: "_", with: " ").capitalized)
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct ReferralProgramCard: View {
    @State private var referralCode = "PIPS2025"
    @State private var showCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Referral Program")
                        .font(.headline)
                    Text("Earn 100 PIPS per referral")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundColor(Color.Theme.accent)
            }
            
            // Referral Code
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Referral Code")
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.secondaryText)
                
                HStack {
                    Text(referralCode)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(action: {
                        UIPasteboard.general.string = referralCode
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopied = false
                        }
                    }) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(Color.Theme.accent)
                    }
                }
                .padding()
                .background(Color.Theme.inputBackground)
                .cornerRadius(8)
            }
            
            // Stats
            HStack {
                VStack {
                    Text("5")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Referrals")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Text("500")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.Theme.accent)
                    Text("PIPS Earned")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct TransactionDetailView: View {
    let transaction: PIPSTransaction
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: iconForTransaction(transaction))
                            .font(.system(size: 60))
                            .foregroundColor(colorForTransaction(transaction))
                        
                        Text("\(transaction.amount > 0 ? "+" : "")\(Int(transaction.amount)) PIPS")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(transaction.amount > 0 ? .green : .red)
                        
                        Text(transaction.description)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    // Details
                    VStack(spacing: 16) {
                        DetailRow(label: "Type", value: transaction.type.rawValue.capitalized)
                        DetailRow(label: "Status", value: transaction.status.rawValue.capitalized, color: colorForStatus(transaction.status))
                        DetailRow(label: "Date", value: transaction.timestamp.formatted())
                        DetailRow(label: "Transaction Hash", value: transaction.transactionHash, isMonospace: true)
                        
                        if transaction.fee > 0 {
                            DetailRow(label: "Gas Fee", value: "\(Int(transaction.fee)) PIPS")
                        }
                        
                        if let from = transaction.fromAddress {
                            DetailRow(label: "From", value: from, isMonospace: true)
                        }
                        
                        if let to = transaction.toAddress {
                            DetailRow(label: "To", value: to, isMonospace: true)
                        }
                        
                        if let metadata = transaction.metadata {
                            ForEach(Array(metadata.keys), id: \.self) { key in
                                DetailRow(label: key.capitalized, value: metadata[key] ?? "")
                            }
                        }
                    }
                    .padding()
                    .background(Color.Theme.cardBackground)
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: { dismiss() })
                }
            }
        }
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
    
    private func colorForStatus(_ status: TransactionStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var color: Color = .primary
    var isMonospace: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Text(value)
                .font(isMonospace ? .system(.body, design: .monospaced) : .body)
                .foregroundColor(color)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}