//
//  SymbolPerformanceList.swift
//  Pipflow
//
//  List of symbol performance metrics
//

import SwiftUI

struct SymbolPerformanceList: View {
    let symbols: [SymbolPerformance]
    @State private var sortBy: SortOption = .profit
    @State private var showAll = false
    
    enum SortOption: String, CaseIterable {
        case profit = "Profit"
        case trades = "Trades"
        case winRate = "Win Rate"
        
        var icon: String {
            switch self {
            case .profit: return "dollarsign.circle"
            case .trades: return "number"
            case .winRate: return "percent"
            }
        }
    }
    
    private var sortedSymbols: [SymbolPerformance] {
        switch sortBy {
        case .profit:
            return symbols.sorted { $0.totalProfit > $1.totalProfit }
        case .trades:
            return symbols.sorted { $0.tradeCount > $1.tradeCount }
        case .winRate:
            return symbols.sorted { $0.winRate > $1.winRate }
        }
    }
    
    private var displayedSymbols: [SymbolPerformance] {
        showAll ? sortedSymbols : Array(sortedSymbols.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Sort Options
            HStack {
                Text("Symbol Performance")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: { sortBy = option }) {
                            Label(option.rawValue, systemImage: option.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortBy.rawValue)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(Color.Theme.accent)
                }
            }
            
            // Symbol List
            ForEach(displayedSymbols) { symbol in
                SymbolPerformanceRow(symbol: symbol)
                
                if symbol.id != displayedSymbols.last?.id {
                    Divider()
                        .background(Color.Theme.divider)
                }
            }
            
            // Show More/Less Button
            if symbols.count > 3 {
                Button(action: { withAnimation { showAll.toggle() } }) {
                    HStack {
                        Text(showAll ? "Show Less" : "Show All (\(symbols.count))")
                            .font(.caption)
                        Image(systemName: showAll ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(Color.Theme.accent)
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
}

struct SymbolPerformanceRow: View {
    let symbol: SymbolPerformance
    
    private var profitColor: Color {
        symbol.totalProfit >= 0 ? Color.Theme.success : Color.Theme.error
    }
    
    private var winRateColor: Color {
        if symbol.winRate >= 0.6 {
            return Color.Theme.success
        } else if symbol.winRate >= 0.5 {
            return Color.Theme.warning
        } else {
            return Color.Theme.error
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Symbol
            VStack(alignment: .leading, spacing: 4) {
                Text(symbol.symbol)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                Text("\(symbol.tradeCount) trades")
                    .font(.caption)
                    .foregroundColor(Color.Theme.secondaryText)
            }
            
            Spacer()
            
            // Metrics
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(symbol.totalProfit))
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(profitColor)
                
                HStack(spacing: 8) {
                    Label("\(Int(symbol.winRate * 100))%", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(winRateColor)
                    
                    Text("Avg: \(formatCurrency(symbol.averageProfit))")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}