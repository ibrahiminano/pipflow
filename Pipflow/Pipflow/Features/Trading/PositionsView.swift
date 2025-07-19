//
//  PositionsView.swift
//  Pipflow
//
//  Created by Claude on 19/07/2025.
//

import SwiftUI

struct PositionsView: View {
    @StateObject private var tradingService = TradingService.shared
    @StateObject private var marketDataService = MarketDataService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedPosition: Position?
    @State private var showingPositionDetail = false
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if tradingService.openPositions.isEmpty {
                    EmptyPositionsView()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Account Summary
                            PositionsAccountSummaryCard()
                            
                            // Positions List
                            VStack(spacing: 12) {
                                ForEach(tradingService.openPositions) { position in
                                    PositionRowView(position: position)
                                        .onTapGesture {
                                            selectedPosition = position
                                            showingPositionDetail = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Positions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshPositions) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
            .sheet(item: $selectedPosition) { position in
                PositionDetailView(position: position)
            }
            .onAppear {
                startAutoRefresh()
            }
            .onDisappear {
                stopAutoRefresh()
            }
        }
    }
    
    private func refreshPositions() {
        Task {
            await tradingService.refreshAccountData()
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            refreshPositions()
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Empty State

struct EmptyPositionsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 80))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("No Open Positions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text("Your open trades will appear here")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Account Summary Card

struct PositionsAccountSummaryCard: View {
    @StateObject private var tradingService = TradingService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var totalProfit: Double {
        tradingService.openPositions.reduce(0) { $0 + $1.profit }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Account Summary")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                if tradingService.activeAccount != nil {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.Theme.success)
                            .frame(width: 8, height: 8)
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(Color.Theme.success)
                    }
                }
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Text(String(format: "$%.2f", tradingService.accountBalance))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Equity")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Text(String(format: "$%.2f", tradingService.accountEquity))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Floating P/L")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Text(String(format: "%+.2f", totalProfit))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(totalProfit >= 0 ? Color.Theme.success : Color.Theme.error)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Position Row

struct PositionRowView: View {
    let position: Position
    @StateObject private var marketDataService = MarketDataService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var currentPrice: Double {
        if let quote = marketDataService.quotes[position.symbol] {
            return quote.mid
        }
        return position.currentPrice
    }
    
    var profit: Double {
        let price = currentPrice
        if position.side == .buy {
            return (price - position.openPrice) * position.volume * 100000 // Assuming standard lot size
        } else {
            return (position.openPrice - price) * position.volume * 100000
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack {
                // Symbol and Side
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(position.symbol)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text(position.side.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(position.side == .buy ? Color.Theme.buy : Color.Theme.sell)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Text("\(String(format: "%.2f", position.volume)) lots")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                // Prices
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.5f", currentPrice))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Open: \(String(format: "%.5f", position.openPrice))")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                // Profit/Loss
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%+.2f", profit))
                        .font(.headline)
                        .foregroundColor(profit >= 0 ? Color.Theme.success : Color.Theme.error)
                    
                    Text("\(String(format: "%+.2f%%", (profit / (position.openPrice * position.volume * 100000)) * 100))")
                        .font(.caption)
                        .foregroundColor(profit >= 0 ? Color.Theme.success : Color.Theme.error)
                }
            }
            .padding()
            
            // SL/TP Bar
            if position.stopLoss != nil || position.takeProfit != nil {
                Divider()
                    .background(themeManager.currentTheme.separatorColor)
                
                HStack {
                    if let sl = position.stopLoss {
                        HStack(spacing: 4) {
                            Text("SL:")
                                .font(.caption2)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            Text(String(format: "%.5f", sl))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.Theme.error)
                        }
                    }
                    
                    if position.stopLoss != nil && position.takeProfit != nil {
                        Text("•")
                            .foregroundColor(themeManager.currentTheme.separatorColor)
                    }
                    
                    if let tp = position.takeProfit {
                        HStack(spacing: 4) {
                            Text("TP:")
                                .font(.caption2)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            Text(String(format: "%.5f", tp))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.Theme.success)
                        }
                    }
                    
                    Spacer()
                    
                    // Time Open
                    Text(timeAgo(from: position.openTime))
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h"
        } else {
            return "\(Int(interval / 86400))d"
        }
    }
}

// MARK: - Position Detail View

struct PositionDetailView: View {
    let position: Position
    @StateObject private var tradingService = TradingService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showingModifySheet = false
    @State private var showingCloseConfirmation = false
    @State private var isClosing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Position Header
                        PositionHeaderView(position: position)
                        
                        // Quick Actions
                        HStack(spacing: 12) {
                            Button(action: {
                                showingModifySheet = true
                            }) {
                                Label("Modify", systemImage: "slider.horizontal.3")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.Theme.accent)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingCloseConfirmation = true
                            }) {
                                Label("Close", systemImage: "xmark.circle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.Theme.error)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Position Details
                        PositionDetailsCard(position: position)
                        
                        // Price Levels
                        PriceLevelsCard(position: position)
                        
                        // Trade Info
                        TradeInfoCard(position: position)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Position Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            .sheet(isPresented: $showingModifySheet) {
                ModifyPositionView(position: position)
            }
            .alert("Close Position", isPresented: $showingCloseConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Close", role: .destructive) {
                    closePosition()
                }
            } message: {
                Text("Are you sure you want to close this position?")
            }
        }
    }
    
    private func closePosition() {
        isClosing = true
        Task {
            do {
                try await tradingService.closePosition(position)
                dismiss()
            } catch {
                // Handle error
                isClosing = false
            }
        }
    }
}

// MARK: - Position Header

struct PositionHeaderView: View {
    let position: Position
    @StateObject private var marketDataService = MarketDataService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
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
    
    var body: some View {
        VStack(spacing: 16) {
            // Symbol and Side
            HStack {
                Text(position.symbol)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text(position.side.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(position.side == .buy ? Color.Theme.buy : Color.Theme.sell)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // Profit/Loss
            VStack(spacing: 8) {
                Text(String(format: "%+.2f USD", profit))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(profit >= 0 ? Color.Theme.success : Color.Theme.error)
                
                Text(String(format: "%+.2f%%", (profit / (position.openPrice * position.volume * 100000)) * 100))
                    .font(.headline)
                    .foregroundColor(profit >= 0 ? Color.Theme.success : Color.Theme.error)
            }
            
            // Current Price
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Text(String(format: "%.5f", currentPrice))
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                Image(systemName: position.side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(position.side == .buy ? Color.Theme.buy : Color.Theme.sell)
                
                VStack(spacing: 4) {
                    Text("Open")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    Text(String(format: "%.5f", position.openPrice))
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Position Details Card

struct PositionDetailsCard: View {
    let position: Position
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Position Details")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            VStack(spacing: 12) {
                DetailRow(label: "Volume", value: String(format: "%.2f lots", position.volume))
                DetailRow(label: "Commission", value: String(format: "$%.2f", position.commission))
                DetailRow(label: "Swap", value: String(format: "$%.2f", position.swap))
                DetailRow(label: "Net Profit", value: String(format: "$%.2f", position.netProfit), color: position.netProfit >= 0 ? Color.Theme.success : Color.Theme.error)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Price Levels Card

struct PriceLevelsCard: View {
    let position: Position
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Levels")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            VStack(spacing: 12) {
                if let sl = position.stopLoss {
                    HStack {
                        Label("Stop Loss", systemImage: "shield.fill")
                            .font(.subheadline)
                            .foregroundColor(Color.Theme.error)
                        
                        Spacer()
                        
                        Text(String(format: "%.5f", sl))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                } else {
                    HStack {
                        Label("Stop Loss", systemImage: "shield")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Spacer()
                        
                        Text("Not Set")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                if let tp = position.takeProfit {
                    HStack {
                        Label("Take Profit", systemImage: "target")
                            .font(.subheadline)
                            .foregroundColor(Color.Theme.success)
                        
                        Spacer()
                        
                        Text(String(format: "%.5f", tp))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                } else {
                    HStack {
                        Label("Take Profit", systemImage: "target")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Spacer()
                        
                        Text("Not Set")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Trade Info Card

struct TradeInfoCard: View {
    let position: Position
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trade Information")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            VStack(spacing: 12) {
                DetailRow(label: "Position ID", value: position.id)
                DetailRow(label: "Open Time", value: formatDate(position.openTime))
                if let magic = position.magicNumber {
                    DetailRow(label: "Magic Number", value: String(magic))
                }
                if let comment = position.comment {
                    DetailRow(label: "Comment", value: comment)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views

struct DetailRow: View {
    let label: String
    let value: String
    var color: Color?
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color ?? themeManager.currentTheme.textColor)
        }
    }
}

// MARK: - Modify Position View

struct ModifyPositionView: View {
    let position: Position
    @StateObject private var tradingService = TradingService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var stopLoss: String = ""
    @State private var takeProfit: String = ""
    @State private var isModifying = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Position Info
                    HStack {
                        Text(position.symbol)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text(position.side.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(position.side == .buy ? Color.Theme.buy : Color.Theme.sell)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Stop Loss
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stop Loss")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        TextField("Enter stop loss price", text: $stopLoss)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Text("Current: \(position.stopLoss != nil ? String(format: "%.5f", position.stopLoss!) : "Not Set")")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    .padding(.horizontal)
                    
                    // Take Profit
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Take Profit")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        TextField("Enter take profit price", text: $takeProfit)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Text("Current: \(position.takeProfit != nil ? String(format: "%.5f", position.takeProfit!) : "Not Set")")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Modify Button
                    Button(action: modifyPosition) {
                        HStack {
                            if isModifying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(isModifying ? "Modifying..." : "Modify Position")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .disabled(isModifying)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Modify Position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            .onAppear {
                if let sl = position.stopLoss {
                    stopLoss = String(format: "%.5f", sl)
                }
                if let tp = position.takeProfit {
                    takeProfit = String(format: "%.5f", tp)
                }
            }
        }
    }
    
    private func modifyPosition() {
        isModifying = true
        
        let sl = stopLoss.isEmpty ? nil : Double(stopLoss)
        let tp = takeProfit.isEmpty ? nil : Double(takeProfit)
        
        Task {
            do {
                try await tradingService.modifyPosition(position, stopLoss: sl, takeProfit: tp)
                dismiss()
            } catch {
                // Handle error
                isModifying = false
            }
        }
    }
}

#Preview {
    PositionsView()
        .environmentObject(ThemeManager.shared)
}