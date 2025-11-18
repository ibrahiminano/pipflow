//
//  CopyTradingView.swift
//  Pipflow
//
//  Copy trading interface for following expert traders
//

import SwiftUI
import Combine

struct CopyTradingView: View {
    @StateObject private var viewModel = CopyTradingViewModel()
    @StateObject private var mirroringService = TradeMirroringService.shared
    @State private var showingTraderDetail = false
    @State private var selectedTrader: Trader?
    @State private var showingCopySettings = false
    @State private var searchText = ""
    @State private var selectedFilter = CopyTraderFilter.all
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Copy Trading Performance Summary
                if !mirroringService.activeSessions.isEmpty {
                    CopyTradingPerformanceCard(mirroringService: mirroringService)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Search and Filters
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(CopyTraderFilter.allCases, id: \.self) { filter in
                                CopyFilterChip(
                                    title: filter.displayName,
                                    isSelected: selectedFilter == filter,
                                    action: { selectedFilter = filter }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                
                // Traders List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Currently Copying Section
                        if !viewModel.copiedTraders.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Currently Copying")
                                    .font(.headline)
                                    .foregroundColor(Color.Theme.text)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.copiedTraders) { trader in
                                    CopiedTraderCard(
                                        trader: trader,
                                        copyDetails: viewModel.getCopyDetails(for: trader.id),
                                        onManage: {
                                            selectedTrader = trader
                                            showingCopySettings = true
                                        },
                                        onStop: {
                                            viewModel.stopCopying(trader)
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            
                            Divider()
                                .padding(.vertical)
                        }
                        
                        // Available Traders Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Traders to Copy")
                                .font(.headline)
                                .foregroundColor(Color.Theme.text)
                                .padding(.horizontal)
                            
                            ForEach(filteredTraders) { trader in
                                TraderCard(
                                    trader: trader,
                                    isCopying: viewModel.isCopying(trader),
                                    onTap: {
                                        selectedTrader = trader
                                        showingTraderDetail = true
                                    },
                                    onCopy: {
                                        if viewModel.isCopying(trader) {
                                            showingCopySettings = true
                                        } else {
                                            selectedTrader = trader
                                            showingCopySettings = true
                                        }
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await viewModel.refreshTraders()
                }
            }
            .background(Color.Theme.background)
            .navigationTitle("Copy Trading")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedTrader) { trader in
                if showingCopySettings {
                    CopySettingsView(trader: trader) { settings in
                        viewModel.startCopying(trader, with: settings)
                        showingCopySettings = false
                    }
                } else {
                    TraderDetailView(trader: trader)
                }
            }
        }
    }
    
    private var filteredTraders: [Trader] {
        viewModel.availableTraders
            .filter { trader in
                selectedFilter.matches(trader) &&
                (searchText.isEmpty || trader.displayName.localizedCaseInsensitiveContains(searchText))
            }
    }
}

// MARK: - Filter Chip

struct CopyFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : Color.Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.Theme.accent : Color.Theme.cardBackground
                )
                .cornerRadius(20)
        }
    }
}

// MARK: - Trader Card

struct TraderCard: View {
    let trader: Trader
    let isCopying: Bool
    let onTap: () -> Void
    let onCopy: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack {
                    // Trader Info
                    HStack(spacing: 12) {
                        // Avatar
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(trader.displayName.prefix(2))
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(trader.isVerified ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(trader.displayName)
                                    .font(.headline)
                                    .foregroundColor(Color.Theme.text)
                                
                                if trader.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text("\(trader.followers) followers")
                                .font(.caption)
                                .foregroundColor(Color.Theme.text.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // Copy Button
                    Button(action: onCopy) {
                        Text(isCopying ? "Managing" : "Copy")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                isCopying ? Color.gray : Color.Theme.accent
                            )
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                Divider()
                    .background(Color.Theme.divider)
                
                // Performance Stats
                HStack {
                    CopyPerformanceStat(
                        label: "Monthly",
                        value: trader.formattedMonthlyReturn,
                        color: trader.monthlyReturn >= 0 ? Color.Theme.success : Color.Theme.error
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.Theme.divider)
                    
                    CopyPerformanceStat(
                        label: "Yearly",
                        value: trader.formattedYearlyReturn,
                        color: trader.yearlyReturn >= 0 ? Color.Theme.success : Color.Theme.error
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.Theme.divider)
                    
                    CopyPerformanceStat(
                        label: "Win Rate",
                        value: "\(Int(trader.winRate * 100))%",
                        color: Color.Theme.text
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.Theme.divider)
                    
                    CopyPerformanceStat(
                        label: "Risk Score",
                        value: "\(trader.riskScore)/10",
                        color: riskScoreColor(trader.riskScore)
                    )
                }
                .padding()
            }
            .background(Color.Theme.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.Theme.shadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    private func riskScoreColor(_ score: Int) -> Color {
        switch score {
        case 1...3:
            return Color.Theme.success
        case 4...6:
            return Color.orange
        default:
            return Color.Theme.error
        }
    }
}

struct CopyPerformanceStat: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.Theme.text.opacity(0.6))
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Copied Trader Card

struct CopiedTraderCard: View {
    let trader: Trader
    let copyDetails: CopyDetails?
    let onManage: () -> Void
    let onStop: () -> Void
    
    @State private var showingStopAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Trader Info
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.Theme.success.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(trader.displayName.prefix(2))
                                .font(.subheadline)
                                .foregroundColor(Color.Theme.success)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trader.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.Theme.text)
                        
                        if let details = copyDetails {
                            Text("Copying since \(details.formattedStartDate)")
                                .font(.caption2)
                                .foregroundColor(Color.Theme.text.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    Button(action: onManage) {
                        Image(systemName: "gearshape")
                            .font(.body)
                            .foregroundColor(Color.Theme.accent)
                    }
                    
                    Button(action: { showingStopAlert = true }) {
                        Image(systemName: "stop.circle")
                            .font(.body)
                            .foregroundColor(Color.Theme.error)
                    }
                }
            }
            
            // Copy Performance
            if let details = copyDetails {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Allocated")
                            .font(.caption2)
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                        Text("$\(details.allocatedAmount, specifier: "%.0f")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("P&L")
                            .font(.caption2)
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                        Text(details.profitLoss >= 0 ? "+$\(details.profitLoss, specifier: "%.2f")" : "-$\(abs(details.profitLoss), specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(details.profitLoss >= 0 ? Color.Theme.success : Color.Theme.error)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Trades")
                            .font(.caption2)
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                        Text("\(details.totalTrades)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color.Theme.success.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.Theme.success, lineWidth: 1)
        )
        .cornerRadius(12)
        .alert("Stop Copying", isPresented: $showingStopAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Stop", role: .destructive) {
                onStop()
            }
        } message: {
            Text("Are you sure you want to stop copying \(trader.displayName)? All open positions will remain but no new trades will be copied.")
        }
    }
}

// MARK: - Copy Settings View

struct CopySettingsView: View {
    let trader: Trader
    let onConfirm: (CopyTradingConfig) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var allocatedAmount = "1000"
    @State private var maxPositions = "10"
    @State private var riskLevel = CopyRiskLevel.medium
    @State private var copyStopLoss = true
    @State private var copyTakeProfit = true
    @State private var proportionalSizing = true
    @State private var maxDrawdown = "20"
    @State private var stopLossPercent = "2"
    @State private var takeProfitPercent = "4"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trader")) {
                    HStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(trader.displayName.prefix(2))
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(trader.displayName)
                                .font(.headline)
                            Text("Monthly: \(trader.formattedMonthlyReturn)")
                                .font(.caption)
                                .foregroundColor(trader.monthlyReturn >= 0 ? Color.Theme.success : Color.Theme.error)
                        }
                        
                        Spacer()
                    }
                }
                
                Section(header: Text("Allocation")) {
                    HStack {
                        Text("Amount to Allocate")
                        Spacer()
                        TextField("1000", text: $allocatedAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("USD")
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                    }
                    
                    HStack {
                        Text("Max Open Positions")
                        Spacer()
                        TextField("10", text: $maxPositions)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }
                
                Section(header: Text("Risk Management")) {
                    Picker("Risk Level", selection: $riskLevel) {
                        ForEach(CopyRiskLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    
                    HStack {
                        Text("Max Drawdown")
                        Spacer()
                        TextField("20", text: $maxDrawdown)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                    }
                    
                    Toggle("Copy Stop Loss", isOn: $copyStopLoss)
                    
                    if copyStopLoss {
                        HStack {
                            Text("Stop Loss")
                            Spacer()
                            TextField("2", text: $stopLossPercent)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("%")
                                .foregroundColor(Color.Theme.text.opacity(0.6))
                        }
                        .padding(.leading, 20)
                    }
                    
                    Toggle("Copy Take Profit", isOn: $copyTakeProfit)
                    
                    if copyTakeProfit {
                        HStack {
                            Text("Take Profit")
                            Spacer()
                            TextField("4", text: $takeProfitPercent)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("%")
                                .foregroundColor(Color.Theme.text.opacity(0.6))
                        }
                        .padding(.leading, 20)
                    }
                    
                    Toggle("Proportional Position Sizing", isOn: $proportionalSizing)
                }
                
                Section(header: Text("Summary")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Est. Position Size")
                            Spacer()
                            Text(estimatedPositionSize)
                                .foregroundColor(Color.Theme.text.opacity(0.6))
                        }
                        
                        HStack {
                            Text("Max Risk per Trade")
                            Spacer()
                            Text(maxRiskPerTrade)
                                .foregroundColor(Color.Theme.text.opacity(0.6))
                        }
                    }
                }
            }
            .navigationTitle("Copy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start Copying") {
                        let settings = CopyTradingConfig(
                            allocatedAmount: Double(allocatedAmount) ?? 1000,
                            maxPositions: Int(maxPositions) ?? 10,
                            riskLevel: riskLevel,
                            copyStopLoss: copyStopLoss,
                            copyTakeProfit: copyTakeProfit,
                            proportionalSizing: proportionalSizing,
                            maxDrawdown: (Double(maxDrawdown) ?? 20) / 100,
                            stopLossPercent: (Double(stopLossPercent) ?? 2) / 100,
                            takeProfitPercent: (Double(takeProfitPercent) ?? 4) / 100
                        )
                        onConfirm(settings)
                        dismiss()
                    }
                    .disabled(allocatedAmount.isEmpty || maxPositions.isEmpty)
                }
            }
        }
    }
    
    private var estimatedPositionSize: String {
        let amount = Double(allocatedAmount) ?? 1000
        let positions = Double(maxPositions) ?? 10
        let size = amount / positions * riskLevel.multiplier
        return "$\(Int(size))"
    }
    
    private var maxRiskPerTrade: String {
        let percentage = riskLevel.riskPercentage
        return "\(percentage)%"
    }
}

// MARK: - Models

enum CopyTraderFilter: String, CaseIterable {
    case all = "All"
    case verified = "Verified"
    case lowRisk = "Low Risk"
    case highReturn = "High Return"
    case popular = "Popular"
    
    var displayName: String {
        rawValue
    }
    
    func matches(_ trader: Trader) -> Bool {
        switch self {
        case .all:
            return true
        case .verified:
            return trader.isVerified
        case .lowRisk:
            return trader.riskScore <= 3
        case .highReturn:
            return trader.monthlyReturn >= 10
        case .popular:
            return trader.followers >= 100
        }
    }
}

enum CopyRiskLevel: String, CaseIterable {
    case conservative = "Conservative"
    case medium = "Medium"
    case aggressive = "Aggressive"
    
    var displayName: String {
        rawValue
    }
    
    var multiplier: Double {
        switch self {
        case .conservative: return 0.5
        case .medium: return 1.0
        case .aggressive: return 1.5
        }
    }
    
    var riskPercentage: Int {
        switch self {
        case .conservative: return 1
        case .medium: return 2
        case .aggressive: return 3
        }
    }
}


struct CopyDetails {
    let traderId: String
    let startDate: Date
    let allocatedAmount: Double
    let profitLoss: Double
    let totalTrades: Int
    
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startDate)
    }
}

// MARK: - View Model

class CopyTradingViewModel: ObservableObject {
    @Published var availableTraders: [Trader] = []
    @Published var copiedTraders: [Trader] = []
    @Published var copyDetails: [String: CopyDetails] = [:]
    
    init() {
        loadMockData()
    }
    
    func refreshTraders() async {
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            loadMockData()
        }
    }
    
    func startCopying(_ trader: Trader, with settings: CopyTradingConfig) {
        copiedTraders.append(trader)
        copyDetails[trader.id] = CopyDetails(
            traderId: trader.id,
            startDate: Date(),
            allocatedAmount: settings.allocatedAmount,
            profitLoss: 0,
            totalTrades: 0
        )
        
        // Start mirroring with the service
        Task { @MainActor in
            TradeMirroringService.shared.startMirroring(traderId: trader.id, settings: settings)
        }
        
        // Remove from available if copying
        availableTraders.removeAll { $0.id == trader.id }
    }
    
    func stopCopying(_ trader: Trader) {
        copiedTraders.removeAll { $0.id == trader.id }
        copyDetails.removeValue(forKey: trader.id)
        
        // Stop mirroring with the service
        Task { @MainActor in
            TradeMirroringService.shared.stopMirroring(traderId: trader.id)
        }
        
        // Add back to available
        if !availableTraders.contains(where: { $0.id == trader.id }) {
            availableTraders.append(trader)
        }
    }
    
    func isCopying(_ trader: Trader) -> Bool {
        copiedTraders.contains { $0.id == trader.id }
    }
    
    func getCopyDetails(for traderId: String) -> CopyDetails? {
        copyDetails[traderId]
    }
    
    private func loadMockData() {
        availableTraders = [
            createMockTrader(
                id: "1",
                username: "alexthompson",
                displayName: "Alex Thompson",
                bio: "Professional forex trader with 8 years experience",
                monthlyReturn: 0.125,
                winRate: 0.72,
                riskScore: 3,
                followers: 2456,
                isVerified: true
            ),
            createMockTrader(
                id: "2",
                username: "sarahchen",
                displayName: "Sarah Chen",
                bio: "Algorithmic trading specialist",
                monthlyReturn: 0.083,
                winRate: 0.68,
                riskScore: 2,
                followers: 1823,
                isVerified: true
            ),
            createMockTrader(
                id: "3",
                username: "marcusrodriguez",
                displayName: "Marcus Rodriguez",
                bio: "Swing trader focused on major pairs",
                monthlyReturn: 0.157,
                winRate: 0.65,
                riskScore: 5,
                followers: 3211,
                isVerified: false
            )
        ]
    }
    
    private func createMockTrader(
        id: String,
        username: String,
        displayName: String,
        bio: String,
        monthlyReturn: Double,
        winRate: Double,
        riskScore: Int,
        followers: Int,
        isVerified: Bool
    ) -> Trader {
        return Trader(
            id: id,
            username: username,
            displayName: displayName,
            profileImageURL: nil,
            bio: bio,
            isVerified: isVerified,
            isPro: isVerified,
            followers: followers,
            following: Int.random(in: 100...500),
            totalTrades: Int.random(in: 500...2000),
            winRate: winRate,
            profitFactor: Double.random(in: 1.5...3.0),
            averageReturn: monthlyReturn / 30,
            monthlyReturn: monthlyReturn,
            yearlyReturn: monthlyReturn * 12,
            riskScore: riskScore,
            tradingStyle: .dayTrading,
            specialties: ["Forex", "Major Pairs"],
            performance: PerformanceData(
                dailyReturns: Array(repeating: 0, count: 30).map { i in
                    DailyReturn(
                        date: Date().addingTimeInterval(-Double(i) * 86400),
                        returnPercentage: Double.random(in: -5...10),
                        profit: Double.random(in: -500...1000),
                        trades: Int.random(in: 1...10)
                    )
                },
                monthlyReturns: Array(repeating: 0, count: 12).map { i in
                    MonthlyReturn(
                        month: Date().addingTimeInterval(-Double(i) * 2592000),
                        returnPercentage: Double.random(in: -15...30),
                        profit: Double.random(in: -5000...10000),
                        trades: Int.random(in: 50...200),
                        winRate: Double.random(in: 0.5...0.8)
                    )
                },
                drawdownHistory: [],
                equityCurve: []
            ),
            stats: TraderStats(
                totalProfit: Double.random(in: 10000...100000),
                totalLoss: Double.random(in: 5000...50000),
                largestWin: Double.random(in: 1000...10000),
                largestLoss: Double.random(in: 500...5000),
                averageWin: Double.random(in: 100...1000),
                averageLoss: Double.random(in: 50...500),
                averageTradeTime: Double.random(in: 3600...86400),
                profitableDays: Int.random(in: 150...250),
                losingDays: Int.random(in: 50...150),
                tradingDays: 300,
                favoriteSymbols: ["EURUSD", "GBPUSD", "USDJPY"],
                successRateBySymbol: ["EURUSD": 0.72, "GBPUSD": 0.68, "USDJPY": 0.65]
            ),
            joinedDate: Date().addingTimeInterval(-Double.random(in: 31536000...94608000)),
            lastActiveDate: Date()
        )
    }
}

// MARK: - Copy Trading Performance Card

struct CopyTradingPerformanceCard: View {
    @ObservedObject var mirroringService: TradeMirroringService
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Copy Trading Performance")
                    .font(.headline)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
                
                Text("\(mirroringService.activeSessions.count) Active")
                    .font(.caption)
                    .foregroundColor(Color.Theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.Theme.accent.opacity(0.2))
                    .cornerRadius(12)
            }
            
            // Performance Metrics
            HStack(spacing: 20) {
                CopyTradingPerformanceMetric(
                    title: "Total P&L",
                    value: formatCurrency(mirroringService.totalProfitLoss),
                    color: mirroringService.totalProfitLoss >= 0 ? Color.Theme.success : Color.Theme.error
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.Theme.divider)
                
                CopyTradingPerformanceMetric(
                    title: "Trades",
                    value: "\(mirroringService.totalCopiedTrades)",
                    color: Color.Theme.text
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.Theme.divider)
                
                CopyTradingPerformanceMetric(
                    title: "Win Rate",
                    value: "\(calculateWinRate())%",
                    color: Color.Theme.text
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.Theme.divider)
                
                CopyTradingPerformanceMetric(
                    title: "Active",
                    value: "\(mirroringService.activePositions.count)",
                    color: Color.Theme.accent
                )
            }
            
            // Individual Session Performance
            if mirroringService.activeSessions.count > 1 {
                VStack(spacing: 8) {
                    ForEach(Array(mirroringService.activeSessions.values), id: \.id) { session in
                        SessionPerformanceRow(session: session)
                    }
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.Theme.shadow, radius: 2, x: 0, y: 1)
        .onAppear {
            mirroringService.updateSessionPerformance()
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    private func calculateWinRate() -> Int {
        let sessions = Array(mirroringService.activeSessions.values)
        let totalTrades = sessions.reduce(0) { $0 + $1.totalTrades }
        let successfulTrades = sessions.reduce(0) { $0 + $1.successfulTrades }
        
        guard totalTrades > 0 else { return 0 }
        return Int((Double(successfulTrades) / Double(totalTrades)) * 100)
    }
}

struct CopyTradingPerformanceMetric: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.text.opacity(0.6))
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SessionPerformanceRow: View {
    let session: CopySession
    
    var body: some View {
        HStack {
            Circle()
                .fill(session.isActive ? Color.Theme.success : Color.gray)
                .frame(width: 8, height: 8)
            
            Text("Trader \(session.traderId.prefix(6))")
                .font(.caption)
                .foregroundColor(Color.Theme.text)
            
            Spacer()
            
            Text("$\(session.profitLoss, specifier: "%.2f")")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(session.profitLoss >= 0 ? Color.Theme.success : Color.Theme.error)
            
            Text("(\(session.totalTrades) trades)")
                .font(.caption)
                .foregroundColor(Color.Theme.text.opacity(0.6))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.Theme.background.opacity(0.5))
        .cornerRadius(8)
    }
}

#Preview {
    CopyTradingView()
}