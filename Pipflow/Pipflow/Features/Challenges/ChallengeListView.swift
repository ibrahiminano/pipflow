//
//  ChallengeListView.swift
//  Pipflow
//
//  Trading challenges list interface
//

import SwiftUI

struct ChallengeListView: View {
    @StateObject private var tokenService = PIPSTokenService.shared
    @State private var selectedCategory: ChallengeCategory? = nil
    @State private var showingChallengeDetail: TradingChallenge?
    @State private var challenges: [TradingChallenge] = []
    
    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(ChallengeCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    title: category.displayName,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Active Challenges
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Active Challenges")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(filteredChallenges(status: .active)) { challenge in
                                ChallengeCard(challenge: challenge)
                                    .onTapGesture {
                                        showingChallengeDetail = challenge
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Upcoming Challenges
                    if !filteredChallenges(status: .upcoming).isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Upcoming Challenges")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(filteredChallenges(status: .upcoming)) { challenge in
                                    ChallengeCard(challenge: challenge)
                                        .onTapGesture {
                                            showingChallengeDetail = challenge
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Completed Challenges
                    if !filteredChallenges(status: .completed).isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Winners")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(filteredChallenges(status: .completed).prefix(3)) { challenge in
                                    CompletedChallengeCard(challenge: challenge)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        .navigationTitle("Trading Challenges")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $showingChallengeDetail) { challenge in
            ChallengeDetailView(challenge: challenge)
        }
        .onAppear {
            loadChallenges()
        }
    }
    
    private func filteredChallenges(status: ChallengeStatus) -> [TradingChallenge] {
        let statusFiltered = challenges.filter { $0.status == status }
        
        if let category = selectedCategory {
            return statusFiltered.filter { $0.category == category }
        }
        
        return statusFiltered
    }
    
    private func loadChallenges() {
        // Mock challenges
        challenges = [
            TradingChallenge(
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
                participants: generateMockParticipants(),
                status: .active,
                category: .scalping
            ),
            TradingChallenge(
                name: "Risk Management Pro",
                description: "Trade for 30 days without exceeding 5% drawdown",
                startDate: Date().addingTimeInterval(86400 * 3),
                endDate: Date().addingTimeInterval(86400 * 33),
                entryFee: 200,
                prizePool: 10000,
                rules: ChallengeRules(
                    minimumTrades: 20,
                    allowedSymbols: nil,
                    maximumDrawdown: 5,
                    profitTarget: 10,
                    duration: 86400 * 30,
                    startingBalance: 50000
                ),
                participants: [],
                status: .upcoming,
                category: .riskManagement
            ),
            TradingChallenge(
                name: "Consistency Champion",
                description: "Achieve 20 consecutive profitable days",
                startDate: Date().addingTimeInterval(-86400 * 20),
                endDate: Date().addingTimeInterval(-86400 * 1),
                entryFee: 150,
                prizePool: 7500,
                rules: ChallengeRules(
                    minimumTrades: 40,
                    allowedSymbols: nil,
                    maximumDrawdown: 15,
                    profitTarget: nil,
                    duration: 86400 * 20,
                    startingBalance: 25000
                ),
                participants: generateMockParticipants(),
                status: .completed,
                category: .consistency
            )
        ]
    }
    
    private func generateMockParticipants() -> [ChallengeParticipant] {
        return (0..<10).map { index in
            ChallengeParticipant(
                userId: "user\(index)",
                username: "Trader\(index)",
                joinedAt: Date().addingTimeInterval(-Double.random(in: 0...86400)),
                currentRank: index + 1,
                performance: ChallengePerformance(
                    totalReturn: Double.random(in: -5...25),
                    winRate: Double.random(in: 40...80),
                    totalTrades: Int.random(in: 10...100),
                    currentDrawdown: Double.random(in: 0...10),
                    bestTrade: Double.random(in: 100...1000),
                    worstTrade: -Double.random(in: 50...500)
                ),
                pipsWon: index < 3 ? Double((3 - index) * 1000) : 0
            )
        }
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.Theme.accent : Color.Theme.secondary.opacity(0.3))
                .foregroundColor(isSelected ? .white : Color.Theme.text)
                .cornerRadius(20)
        }
    }
}

struct ChallengeCard: View {
    let challenge: TradingChallenge
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.name)
                        .font(.headline)
                    
                    Text(challenge.category.displayName)
                        .font(.caption)
                        .foregroundColor(Color.Theme.accent)
                }
                
                Spacer()
                
                StatusBadge(status: challenge.status)
            }
            
            // Description
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(Color.Theme.secondaryText)
                .lineLimit(2)
            
            // Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prize Pool")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    
                    Text("\(Int(challenge.prizePool)) PIPS")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.Theme.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Entry Fee")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    
                    Text("\(Int(challenge.entryFee)) PIPS")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Participants")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    
                    Text("\(challenge.participants.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // Time Remaining
            if challenge.status == .active {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(Color.Theme.warning)
                    
                    Text(timeRemaining(until: challenge.endDate))
                        .font(.caption)
                        .foregroundColor(Color.Theme.warning)
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private func timeRemaining(until date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        let days = Int(interval / 86400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
        
        if days > 0 {
            return "\(days) days, \(hours) hours remaining"
        } else if hours > 0 {
            return "\(hours) hours remaining"
        } else {
            return "Ending soon"
        }
    }
}

struct CompletedChallengeCard: View {
    let challenge: TradingChallenge
    
    var topParticipants: [ChallengeParticipant] {
        challenge.participants.sorted { $0.currentRank < $1.currentRank }.prefix(3).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(challenge.name)
                    .font(.headline)
                
                Spacer()
                
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            // Winners
            VStack(spacing: 8) {
                ForEach(topParticipants) { participant in
                    HStack {
                        Text("#\(participant.currentRank)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(colorForRank(participant.currentRank))
                            .frame(width: 30)
                        
                        Text(participant.username)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(participant.pipsWon)) PIPS")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.Theme.accent)
                    }
                }
            }
            .padding()
            .background(Color.Theme.secondary.opacity(0.3))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private func colorForRank(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return Color.Theme.text
        }
    }
}

struct StatusBadge: View {
    let status: ChallengeStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(colorForStatus(status).opacity(0.2))
            .foregroundColor(colorForStatus(status))
            .cornerRadius(12)
    }
    
    private func colorForStatus(_ status: ChallengeStatus) -> Color {
        switch status {
        case .upcoming: return .blue
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

// MARK: - Extensions

extension ChallengeCategory {
    var displayName: String {
        switch self {
        case .scalping: return "Scalping"
        case .dayTrading: return "Day Trading"
        case .swingTrading: return "Swing Trading"
        case .riskManagement: return "Risk Management"
        case .profitability: return "Profitability"
        case .consistency: return "Consistency"
        }
    }
}

#Preview {
    ChallengeListView()
        .preferredColorScheme(.dark)
}