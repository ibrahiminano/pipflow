//
//  ChallengeDetailView.swift
//  Pipflow
//
//  Trading challenge detail and participation view
//

import SwiftUI

struct ChallengeDetailView: View {
    let challenge: TradingChallenge
    @StateObject private var tokenService = PIPSTokenService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showJoinConfirmation = false
    @State private var isJoining = false
    @State private var selectedTab = 0
    @State private var userParticipant: ChallengeParticipant?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard
                    
                    // Action Buttons
                    if challenge.status == .upcoming || challenge.status == .active {
                        actionButtons
                    }
                    
                    // Tab Selection
                    Picker("", selection: $selectedTab) {
                        Text("Overview").tag(0)
                        Text("Rules").tag(1)
                        Text("Leaderboard").tag(2)
                        if userParticipant != nil {
                            Text("My Stats").tag(3)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Tab Content
                    Group {
                        switch selectedTab {
                        case 0:
                            overviewTab
                        case 1:
                            rulesTab
                        case 2:
                            leaderboardTab
                        case 3:
                            if userParticipant != nil {
                                myStatsTab
                            }
                        default:
                            overviewTab
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(challenge.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: { dismiss() })
                }
            }
        }
        .alert("Join Challenge", isPresented: $showJoinConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Join (\(Int(challenge.entryFee)) PIPS)", role: .destructive) {
                joinChallenge()
            }
        } message: {
            Text("Entry fee of \(Int(challenge.entryFee)) PIPS will be deducted from your wallet. Are you sure you want to join?")
        }
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        VStack(spacing: 20) {
            // Challenge Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.Theme.accent, Color.Theme.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: iconForCategory(challenge.category))
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            // Prize Pool
            VStack(spacing: 8) {
                Text("Prize Pool")
                    .font(.headline)
                    .foregroundColor(Color.Theme.secondaryText)
                
                Text("\(Int(challenge.prizePool)) PIPS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.Theme.accent)
                
                if let stats = tokenService.tokenStats {
                    Text("≈ $\(String(format: "%.2f", challenge.prizePool * stats.price))")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
            
            // Status & Time
            HStack(spacing: 20) {
                VStack {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    StatusBadge(status: challenge.status)
                }
                
                VStack {
                    Text("Participants")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Text("\(challenge.participants.count)")
                        .font(.headline)
                }
                
                VStack {
                    Text(challenge.status == .upcoming ? "Starts In" : "Ends In")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Text(timeString(for: challenge.status == .upcoming ? challenge.startDate : challenge.endDate))
                        .font(.headline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.Theme.cardBackground)
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if let participant = userParticipant {
                // Already joined
                Button(action: {}) {
                    Label("Joined", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(true)
                .buttonStyle(.borderedProminent)
                
                Button(action: { selectedTab = 3 }) {
                    Label("View Stats", systemImage: "chart.line.uptrend.xyaxis")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else if challenge.status == .upcoming {
                Button(action: { showJoinConfirmation = true }) {
                    HStack {
                        if isJoining {
                            ProgressView()
                        } else {
                            Label("Join Challenge", systemImage: "plus.circle.fill")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isJoining || !canAffordEntry())
                
                if !canAffordEntry() {
                    Text("Insufficient PIPS")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Description
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.headline)
                
                Text(challenge.description)
                    .font(.body)
                    .foregroundColor(Color.Theme.secondaryText)
            }
            .padding(.horizontal)
            
            // Prize Distribution
            VStack(alignment: .leading, spacing: 12) {
                Text("Prize Distribution")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    PrizeRow(position: "1st Place", amount: challenge.prizePool * 0.5)
                    PrizeRow(position: "2nd Place", amount: challenge.prizePool * 0.3)
                    PrizeRow(position: "3rd Place", amount: challenge.prizePool * 0.2)
                }
                .padding()
                .background(Color.Theme.secondary.opacity(0.3))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Timeline
            VStack(alignment: .leading, spacing: 12) {
                Text("Timeline")
                    .font(.headline)
                
                VStack(spacing: 16) {
                    TimelineRow(
                        title: "Registration Opens",
                        date: challenge.startDate.addingTimeInterval(-86400 * 7),
                        isCompleted: true
                    )
                    
                    TimelineRow(
                        title: "Challenge Starts",
                        date: challenge.startDate,
                        isCompleted: challenge.status != .upcoming
                    )
                    
                    TimelineRow(
                        title: "Challenge Ends",
                        date: challenge.endDate,
                        isCompleted: challenge.status == .completed
                    )
                    
                    TimelineRow(
                        title: "Winners Announced",
                        date: challenge.endDate.addingTimeInterval(3600),
                        isCompleted: challenge.status == .completed
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Rules Tab
    
    private var rulesTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Trading Rules
            VStack(alignment: .leading, spacing: 16) {
                Text("Trading Rules")
                    .font(.headline)
                
                RuleCard(
                    icon: "chart.bar",
                    title: "Minimum Trades",
                    value: "\(challenge.rules.minimumTrades)"
                )
                
                RuleCard(
                    icon: "arrow.down.circle",
                    title: "Maximum Drawdown",
                    value: "\(Int(challenge.rules.maximumDrawdown))%"
                )
                
                if let profitTarget = challenge.rules.profitTarget {
                    RuleCard(
                        icon: "arrow.up.circle",
                        title: "Profit Target",
                        value: "\(Int(profitTarget))%"
                    )
                }
                
                RuleCard(
                    icon: "dollarsign.circle",
                    title: "Starting Balance",
                    value: "$\(Int(challenge.rules.startingBalance))"
                )
                
                if let symbols = challenge.rules.allowedSymbols {
                    RuleCard(
                        icon: "list.bullet",
                        title: "Allowed Symbols",
                        value: symbols.joined(separator: ", ")
                    )
                }
            }
            .padding(.horizontal)
            
            // General Rules
            VStack(alignment: .leading, spacing: 12) {
                Text("General Rules")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    RuleBullet(text: "All trades must be closed before challenge ends")
                    RuleBullet(text: "No hedging or arbitrage allowed")
                    RuleBullet(text: "Maximum leverage 1:100")
                    RuleBullet(text: "Automated trading allowed with restrictions")
                    RuleBullet(text: "Winners verified within 24 hours")
                }
                .padding()
                .background(Color.Theme.secondary.opacity(0.3))
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Leaderboard Tab
    
    private var leaderboardTab: some View {
        VStack(spacing: 16) {
            if challenge.participants.isEmpty {
                Text("No participants yet")
                    .font(.headline)
                    .foregroundColor(Color.Theme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ForEach(challenge.participants.sorted { $0.currentRank < $1.currentRank }) { participant in
                    ChallengeLeaderboardRow(participant: participant, rank: participant.currentRank)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - My Stats Tab
    
    private var myStatsTab: some View {
        VStack(spacing: 20) {
            if let participant = userParticipant {
                // Performance Card
                VStack(spacing: 16) {
                    HStack {
                        Text("Your Performance")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("Rank #\(participant.currentRank)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.Theme.accent)
                    }
                    
                    VStack(spacing: 12) {
                        PerformanceRow(
                            label: "Total Return",
                            value: "\(participant.performance.totalReturn > 0 ? "+" : "")\(String(format: "%.2f", participant.performance.totalReturn))%",
                            color: participant.performance.totalReturn > 0 ? .green : .red
                        )
                        
                        PerformanceRow(
                            label: "Win Rate",
                            value: "\(Int(participant.performance.winRate))%",
                            color: participant.performance.winRate > 50 ? .green : .orange
                        )
                        
                        PerformanceRow(
                            label: "Total Trades",
                            value: "\(participant.performance.totalTrades)"
                        )
                        
                        PerformanceRow(
                            label: "Current Drawdown",
                            value: "\(String(format: "%.2f", participant.performance.currentDrawdown))%",
                            color: .orange
                        )
                        
                        PerformanceRow(
                            label: "Best Trade",
                            value: "+$\(Int(participant.performance.bestTrade))",
                            color: .green
                        )
                        
                        PerformanceRow(
                            label: "Worst Trade",
                            value: "-$\(Int(abs(participant.performance.worstTrade)))",
                            color: .red
                        )
                    }
                }
                .padding()
                .background(Color.Theme.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Trade History would go here
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func canAffordEntry() -> Bool {
        (tokenService.wallet?.balance ?? 0) >= challenge.entryFee
    }
    
    private func joinChallenge() {
        isJoining = true
        
        Task {
            do {
                // Deduct entry fee
                await tokenService.executeOperation(.accessPremiumContent) { result in
                    switch result {
                    case .success:
                        // Create participant
                        userParticipant = ChallengeParticipant(
                            userId: tokenService.wallet?.userId ?? "",
                            username: "You",
                            joinedAt: Date(),
                            currentRank: challenge.participants.count + 1,
                            performance: ChallengePerformance(
                                totalReturn: 0,
                                winRate: 0,
                                totalTrades: 0,
                                currentDrawdown: 0,
                                bestTrade: 0,
                                worstTrade: 0
                            ),
                            pipsWon: 0
                        )
                        isJoining = false
                        selectedTab = 3 // Switch to My Stats
                    case .failure:
                        isJoining = false
                    }
                }
            }
        }
    }
    
    private func timeString(for date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        let days = Int(abs(interval) / 86400)
        let hours = Int((abs(interval).truncatingRemainder(dividingBy: 86400)) / 3600)
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "Soon"
        }
    }
    
    private func iconForCategory(_ category: ChallengeCategory) -> String {
        switch category {
        case .scalping: return "hare"
        case .dayTrading: return "sun.max"
        case .swingTrading: return "waveform.path.ecg"
        case .riskManagement: return "shield"
        case .profitability: return "chart.line.uptrend.xyaxis"
        case .consistency: return "checkmark.seal"
        }
    }
}

// MARK: - Supporting Views

struct PrizeRow: View {
    let position: String
    let amount: Double
    
    var body: some View {
        HStack {
            Text(position)
                .font(.subheadline)
                .foregroundColor(Color.Theme.text)
            
            Spacer()
            
            Text("\(Int(amount)) PIPS")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.Theme.accent)
        }
    }
}

struct TimelineRow: View {
    let title: String
    let date: Date
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(isCompleted ? Color.green : Color.Theme.divider, lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(date.formatted())
                    .font(.caption)
                    .foregroundColor(Color.Theme.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct RuleCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.Theme.accent)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.Theme.accent)
        }
        .padding()
        .background(Color.Theme.secondary.opacity(0.3))
        .cornerRadius(8)
    }
}

struct RuleBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.Theme.accent)
                .frame(width: 6, height: 6)
                .offset(y: 6)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Color.Theme.text)
        }
    }
}

struct ChallengeLeaderboardRow: View {
    let participant: ChallengeParticipant
    let rank: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(colorForRank(rank))
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    Label("\(Int(participant.performance.winRate))%", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Label("\(participant.performance.totalTrades)", systemImage: "arrow.up.arrow.down")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
            
            Spacer()
            
            // Performance
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(participant.performance.totalReturn > 0 ? "+" : "")\(String(format: "%.2f", participant.performance.totalReturn))%")
                    .font(.headline)
                    .foregroundColor(participant.performance.totalReturn > 0 ? .green : .red)
                
                if rank <= 3 && participant.pipsWon > 0 {
                    Text("+\(Int(participant.pipsWon)) PIPS")
                        .font(.caption)
                        .foregroundColor(Color.Theme.accent)
                }
            }
        }
        .padding()
        .background(Color.Theme.secondary.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func colorForRank(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color.Theme.accent
        }
    }
}

struct PerformanceRow: View {
    let label: String
    let value: String
    var color: Color = Color.Theme.text
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.Theme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

#Preview {
    ChallengeDetailView(
        challenge: TradingChallenge(
            name: "Scalping Master",
            description: "Achieve 50 profitable scalp trades in 7 days",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 7),
            entryFee: 100,
            prizePool: 5000,
            rules: ChallengeRules(
                minimumTrades: 50,
                allowedSymbols: ["EUR/USD", "GBP/USD", "USD/JPY"],
                maximumDrawdown: 10,
                profitTarget: nil,
                duration: 86400 * 7,
                startingBalance: 10000
            ),
            participants: [],
            status: .active,
            category: .scalping
        )
    )
    .preferredColorScheme(.dark)
}