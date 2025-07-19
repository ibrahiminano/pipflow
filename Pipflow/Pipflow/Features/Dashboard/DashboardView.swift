//
//  DashboardView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Account Summary Card
                    AccountSummaryCard()
                        .padding(.horizontal)
                    
                    // Quick Actions
                    QuickActionsSection()
                        .padding(.horizontal)
                    
                    // Active Positions
                    ActivePositionsSection()
                    
                    // Recent Signals
                    RecentSignalsSection()
                }
                .padding(.vertical)
            }
            .background(Color.Theme.background)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct AccountSummaryCard: View {
    @StateObject private var tradingService = TradingService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Balance section with gradient background
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Balance")
                    .font(.bodyMedium)
                    .foregroundColor(Color.white.opacity(0.8))
                
                Text(String(format: "$%.2f", tradingService.accountBalance))
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(.cornerRadius)
            
            // Stats section
            HStack(spacing: .spacing) {
                StatCard(
                    title: "Today's P&L",
                    value: "+$250.00",
                    valueColor: Color.Theme.success,
                    icon: "arrow.up.right"
                )
                
                StatCard(
                    title: "Win Rate",
                    value: "68%",
                    valueColor: Color.Theme.accent,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let valueColor: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(valueColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(.smallCornerRadius)
    }
}

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(Color.Theme.text)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Trade",
                    color: .green
                )
                
                QuickActionButton(
                    icon: "doc.text.magnifyingglass",
                    title: "Signals",
                    color: .blue
                )
                
                QuickActionButton(
                    icon: "person.2.fill",
                    title: "Copy",
                    color: .orange
                )
                
                QuickActionButton(
                    icon: "graduationcap.fill",
                    title: "Learn",
                    color: .purple
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.Theme.text)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color.Theme.cardBackground)
        .cornerRadius(.cornerRadius)
        .shadow(color: Color.Theme.shadow, radius: 4, x: 0, y: 2)
    }
}

struct ActivePositionsSection: View {
    @StateObject private var tradingService = TradingService.shared
    @StateObject private var marketDataService = MarketDataService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Positions")
                    .font(.headline)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
                
                NavigationLink(destination: PositionsView()) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.accent)
                }
            }
            .padding(.horizontal)
            
            if tradingService.openPositions.isEmpty {
                Text("No open positions")
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tradingService.openPositions.prefix(3)) { position in
                            PositionCard(position: position)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct PositionCard: View {
    let position: Position
    @StateObject private var marketDataService = MarketDataService.shared
    
    var currentPrice: Double {
        if let quote = marketDataService.quotes[position.symbol] {
            return quote.mid
        }
        return position.currentPrice
    }
    
    var profit: Double {
        let price = currentPrice
        if position.side == .buy {
            return (price - position.openPrice) * position.volume * 100000
        } else {
            return (position.openPrice - price) * position.volume * 100000
        }
    }
    
    var profitPercentage: Double {
        guard position.openPrice > 0 else { return 0 }
        let pips = position.side == .buy ? currentPrice - position.openPrice : position.openPrice - currentPrice
        return (pips / position.openPrice) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(position.symbol)
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.Theme.text)
                    
                    Text(String(format: "%.2f lot", position.volume))
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
                
                Spacer()
                
                Text(position.side.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((position.side == .buy ? Color.Theme.buy : Color.Theme.sell).opacity(0.15))
                    .foregroundColor(position.side == .buy ? Color.Theme.buy : Color.Theme.sell)
                    .cornerRadius(.smallCornerRadius)
            }
            
            Divider()
                .background(Color.Theme.divider)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("P&L")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                    Text(String(format: "%+.2f", profit))
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(profit >= 0 ? Color.Theme.success : Color.Theme.error)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Return")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                    HStack(spacing: 4) {
                        Image(systemName: profit >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(String(format: "%+.2f%%", profitPercentage))
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(profit >= 0 ? Color.Theme.success : Color.Theme.error)
                }
            }
        }
        .padding()
        .frame(width: 220)
        .background(Color.Theme.cardBackground)
        .cornerRadius(.cornerRadius)
        .shadow(color: Color.Theme.shadow, radius: 4, x: 0, y: 2)
    }
}

struct RecentSignalsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Signals")
                    .font(.headline)
                    .foregroundColor(Color.Theme.text)
                
                Spacer()
                
                Button(action: {}) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(Color.Theme.accent)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    SignalRow()
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct SignalRow: View {
    var body: some View {
        HStack(spacing: 16) {
            // Signal type indicator
            ZStack {
                Circle()
                    .fill(Color.Theme.sell.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color.Theme.sell)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("GBP/USD")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.Theme.text)
                
                HStack(spacing: 8) {
                    Text("SELL @ 1.2650")
                        .font(.bodyMedium)
                        .foregroundColor(Color.Theme.text.opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(Color.Theme.text.opacity(0.4))
                    
                    Text("5 min ago")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.5))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.Theme.success)
                        .frame(width: 8, height: 8)
                    Text("High")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.Theme.success)
                }
                
                Text("85%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.Theme.accent)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(.cornerRadius)
        .shadow(color: Color.Theme.shadow, radius: 3, x: 0, y: 1)
    }
}

#Preview {
    DashboardView()
}