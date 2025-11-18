//
//  TradeHistoryView.swift
//  Pipflow
//
//  AI Auto-trading history view
//

import SwiftUI
import Charts

struct TradeHistoryView: View {
    let trades: [CompletedTrade]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeframe: HistoryTimeframe = .week
    @State private var selectedTrade: CompletedTrade?
    
    var filteredTrades: [CompletedTrade] {
        let cutoffDate = selectedTimeframe.cutoffDate
        return trades.filter { $0.closeTime >= cutoffDate }
    }
    
    var statistics: TradeStatistics {
        TradeStatistics(trades: filteredTrades)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Timeframe Selector
                    TimeframePicker(selectedTimeframe: $selectedTimeframe)
                        .padding(.horizontal)
                    
                    // Statistics Overview
                    StatisticsOverview(statistics: statistics)
                        .padding(.horizontal)
                    
                    // Profit Chart
                    if !filteredTrades.isEmpty {
                        ProfitChart(trades: filteredTrades)
                            .padding(.horizontal)
                    }
                    
                    // Trade List
                    TradeListSection(
                        trades: filteredTrades,
                        selectedTrade: $selectedTrade
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.Theme.background)
            .navigationTitle("Trade History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTrade) { trade in
                TradeDetailView(trade: trade)
            }
        }
    }
}

enum HistoryTimeframe: String, CaseIterable {
    case day = "24H"
    case week = "7D"
    case month = "30D"
    case all = "All"
    
    var cutoffDate: Date {
        let calendar = Calendar.current
        switch self {
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        case .all:
            return Date.distantPast
        }
    }
}

struct TimeframePicker: View {
    @Binding var selectedTimeframe: HistoryTimeframe
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(HistoryTimeframe.allCases, id: \.self) { timeframe in
                Button(action: { selectedTimeframe = timeframe }) {
                    Text(timeframe.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : Color.Theme.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTimeframe == timeframe ? Color.Theme.accent : Color.Theme.surface)
                        )
                }
            }
        }
    }
}

struct TradeStatistics {
    let trades: [CompletedTrade]
    
    var totalTrades: Int { trades.count }
    var winningTrades: Int { trades.filter { $0.isWin }.count }
    var losingTrades: Int { trades.filter { !$0.isWin }.count }
    
    var winRate: Double {
        guard totalTrades > 0 else { return 0 }
        return Double(winningTrades) / Double(totalTrades)
    }
    
    var totalProfit: Double {
        trades.filter { $0.isWin }.reduce(0) { $0 + $1.profit }
    }
    
    var totalLoss: Double {
        trades.filter { !$0.isWin }.reduce(0) { $0 + abs($1.profit) }
    }
    
    var netProfit: Double { totalProfit - totalLoss }
    
    var profitFactor: Double {
        guard totalLoss > 0 else { return totalProfit > 0 ? Double.infinity : 0 }
        return totalProfit / totalLoss
    }
    
    var averageWin: Double {
        guard winningTrades > 0 else { return 0 }
        return totalProfit / Double(winningTrades)
    }
    
    var averageLoss: Double {
        guard losingTrades > 0 else { return 0 }
        return totalLoss / Double(losingTrades)
    }
    
    var averageRRRatio: Double {
        guard averageLoss > 0 else { return 0 }
        return averageWin / averageLoss
    }
}

struct StatisticsOverview: View {
    let statistics: TradeStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Stats
            HStack(spacing: 16) {
                TradeHistoryStatCard(
                    title: "Total Trades",
                    value: "\(statistics.totalTrades)",
                    color: Color.Theme.accent
                )
                
                TradeHistoryStatCard(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", statistics.winRate * 100),
                    color: statistics.winRate >= 0.5 ? .green : .orange
                )
                
                TradeHistoryStatCard(
                    title: "Net P&L",
                    value: String(format: "$%.2f", statistics.netProfit),
                    color: statistics.netProfit >= 0 ? .green : .red
                )
            }
            
            // Secondary Stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SecondaryStatCard(
                    title: "Profit Factor",
                    value: String(format: "%.2f", statistics.profitFactor)
                )
                
                SecondaryStatCard(
                    title: "Avg Win",
                    value: String(format: "$%.2f", statistics.averageWin)
                )
                
                SecondaryStatCard(
                    title: "Avg Loss",
                    value: String(format: "$%.2f", statistics.averageLoss)
                )
                
                SecondaryStatCard(
                    title: "Avg RR",
                    value: String(format: "%.2f", statistics.averageRRRatio)
                )
            }
        }
    }
}

struct TradeHistoryStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.text.opacity(0.6))
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Theme.surface)
        )
    }
}

struct SecondaryStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.text.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.Theme.text)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.Theme.background)
        )
    }
}

struct ProfitChart: View {
    let trades: [CompletedTrade]
    
    var cumulativeProfitData: [(date: Date, profit: Double)] {
        var cumulative: Double = 0
        var data: [(Date, Double)] = []
        
        for trade in trades.sorted(by: { $0.closeTime < $1.closeTime }) {
            cumulative += trade.profit
            data.append((trade.closeTime, cumulative))
        }
        
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cumulative Profit")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            Chart(cumulativeProfitData, id: \.date) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Profit", item.profit)
                )
                .foregroundStyle(item.profit >= 0 ? Color.green : Color.red)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Profit", item.profit)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            (item.profit >= 0 ? Color.green : Color.red).opacity(0.3),
                            (item.profit >= 0 ? Color.green : Color.red).opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct TradeListSection: View {
    let trades: [CompletedTrade]
    @Binding var selectedTrade: CompletedTrade?
    
    var sortedTrades: [CompletedTrade] {
        trades.sorted { $0.closeTime > $1.closeTime }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trades")
                    .font(.headline)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
                
                Text("\(trades.count)")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
            
            if trades.isEmpty {
                TradeHistoryEmptyStateView()
            } else {
                ForEach(sortedTrades) { trade in
                    TradeHistoryRow(trade: trade)
                        .onTapGesture {
                            selectedTrade = trade
                        }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct TradeHistoryRow: View {
    let trade: CompletedTrade
    
    var body: some View {
        HStack {
            // Symbol and Side
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trade.symbol)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.Theme.text)
                    
                    Text(trade.side.rawValue)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(trade.side == .buy ? Color.green : Color.red)
                        )
                }
                
                HStack(spacing: 8) {
                    Text("\(String(format: "%.2f", trade.volume)) lots")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                    
                    Text("•")
                        .foregroundColor(Color.Theme.text.opacity(0.3))
                    
                    Text(trade.closeTime, style: .time)
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Profit
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", trade.profit))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(trade.isWin ? .green : .red)
                
                Text("\(Int(trade.pips)) pips")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
    }
}

struct TradeHistoryEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.largeTitle)
                .foregroundColor(Color.Theme.text.opacity(0.3))
            
            Text("No trades yet")
                .font(.subheadline)
                .foregroundColor(Color.Theme.text.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct TradeDetailView: View {
    let trade: CompletedTrade
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    TradeDetailHeader(trade: trade)
                    
                    // Trade Info
                    TradeInfoSection(trade: trade)
                    
                    // Price Levels
                    PriceLevelsSection(trade: trade)
                    
                    // Performance
                    PerformanceSection(trade: trade)
                }
                .padding()
            }
            .background(Color.Theme.background)
            .navigationTitle("Trade Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TradeDetailHeader: View {
    let trade: CompletedTrade
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(trade.symbol)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.Theme.text)
                
                Text(trade.side.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(trade.side == .buy ? Color.green : Color.red)
                    )
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profit/Loss")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                    
                    Text(String(format: "$%.2f", trade.profit))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(trade.isWin ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Pips")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                    
                    Text("\(Int(trade.pips))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.Theme.text)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct TradeInfoSection: View {
    let trade: CompletedTrade
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trade Information")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            InfoRow(label: "Volume", value: String(format: "%.2f lots", trade.volume))
            InfoRow(label: "Open Time", value: trade.openTime.formatted())
            InfoRow(label: "Close Time", value: trade.closeTime.formatted())
            InfoRow(label: "Duration", value: formatDuration(trade.duration))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct PriceLevelsSection: View {
    let trade: CompletedTrade
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Levels")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            InfoRow(label: "Open Price", value: String(format: "%.5f", trade.openPrice))
            InfoRow(label: "Close Price", value: String(format: "%.5f", trade.closePrice))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct PerformanceSection: View {
    let trade: CompletedTrade
    
    var profitPercentage: Double {
        let investment = trade.volume * trade.openPrice * 100000 // Simplified
        return (trade.profit / investment) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            InfoRow(
                label: "Result",
                value: trade.isWin ? "Win" : "Loss",
                valueColor: trade.isWin ? .green : .red
            )
            
            InfoRow(
                label: "Return",
                value: String(format: "%.2f%%", profitPercentage),
                valueColor: profitPercentage >= 0 ? .green : .red
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.surface)
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color.Theme.text
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.Theme.text.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

#Preview {
    TradeHistoryView(trades: [])
}