//
//  TradingView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI
import Combine

struct TradingView: View {
    var body: some View {
        ProfessionalTradingView()
    }
}

// Keep the original TradingView implementation as OldTradingView for reference
struct OldTradingView: View {
    @StateObject private var viewModel = TradingViewModel()
    @StateObject private var metaAPIService = MetaAPIService.shared
    @StateObject private var webSocketService = MetaAPIWebSocketService.shared
    @StateObject private var syncService = AccountSyncService.shared
    @StateObject private var uiStyleManager = UIStyleManager.shared
    @State private var selectedSymbol = "EURUSD"
    @State private var showNewTradeSheet = false
    @State private var showMetaTraderLink = false
    @State private var showAutoTrading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Symbol Selector
                SymbolSelectorView(selectedSymbol: $selectedSymbol)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Account Connection Banner
                        if !viewModel.hasConnectedAccount {
                            Button(action: { showMetaTraderLink = true }) {
                                HStack {
                                    Image(systemName: "link.circle.fill")
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Connect MetaTrader Account")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("Link your MT4/MT5 to start trading")
                                            .font(.caption)
                                            .opacity(0.7)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .opacity(0.5)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "00F5A0").opacity(0.8), Color(hex: "00D9FF").opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        
                        // Chart Button - Made more prominent
                        NavigationLink(destination: ChartView(symbol: selectedSymbol)) {
                            HStack(spacing: 12) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title2)
                                Text("View Chart")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, viewModel.hasConnectedAccount ? 8 : 0)
                        
                        // Price Card
                        PriceCardView(symbol: selectedSymbol)
                            .padding(.horizontal)
                        
                        // Quick Trade Buttons
                        HStack(spacing: 16) {
                            QuickTradeButton(
                                title: "Buy",
                                color: Color.Theme.buy,
                                action: {
                                    viewModel.tradeSide = .buy
                                    showNewTradeSheet = true
                                }
                            )
                            
                            QuickTradeButton(
                                title: "Sell",
                                color: Color.Theme.sell,
                                action: {
                                    viewModel.tradeSide = .sell
                                    showNewTradeSheet = true
                                }
                            )
                        }
                        .padding(.horizontal)
                        
                        // AI Auto-Trading Card
                        AIAutoTradingCard(showAutoTrading: $showAutoTrading)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Open Positions
                        if !metaAPIService.positions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Open Positions")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.Theme.text)
                                    .padding(.horizontal)
                                
                                ForEach(metaAPIService.positions) { position in
                                    PositionCardView(position: position)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Pending Orders
                        if !webSocketService.orders.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pending Orders")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.Theme.text)
                                    .padding(.horizontal)
                                
                                ForEach(webSocketService.orders, id: \.id) { order in
                                    OrderRowView(order: order)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color.Theme.background)
            .navigationTitle("Trading")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if webSocketService.connectionState == .connected {
                        SyncStatusBadge()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Refresh button
                        Button(action: {
                            Task {
                                await syncService.syncAccount()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(syncService.syncStatus.isActive ? .gray : Color.blue)
                        }
                        .disabled(syncService.syncStatus.isActive)
                        
                        // Chart button
                        Button(action: {
                            ChartPresentationManager.shared.presentChart(for: selectedSymbol)
                        }) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(Color.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $showNewTradeSheet) {
                NewTradeView(
                    symbol: selectedSymbol,
                    side: viewModel.tradeSide,
                    onComplete: {
                        showNewTradeSheet = false
                        viewModel.refreshData()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
            }
            .fullScreenCover(isPresented: $showMetaTraderLink) {
                MetaTraderLinkView()
            }
            .sheet(isPresented: $showAutoTrading) {
                NavigationView {
                    AIAutoTradingView()
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Supporting Views

struct AIAutoTradingCard: View {
    @Binding var showAutoTrading: Bool
    @StateObject private var engine = AIAutoTradingEngine.shared
    
    var body: some View {
        Button(action: { 
            print("DEBUG: AI Auto-Trading card tapped")
            showAutoTrading = true 
            print("DEBUG: showAutoTrading set to: \(showAutoTrading)")
        }) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "brain")
                                .font(.title3)
                                .foregroundColor(Color.Theme.accent)
                            
                            Text("AI Auto-Trading")
                                .font(.headline)
                                .foregroundColor(Color.Theme.text)
                        }
                        
                        Text(engine.isActive ? "Active • \(engine.config.mode.rawValue)" : "Inactive")
                            .font(.caption)
                            .foregroundColor(Color.Theme.text.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    if engine.isActive {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(statusColor)
                        }
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color.Theme.text.opacity(0.5))
                    }
                }
                
                if engine.isActive {
                    HStack(spacing: 16) {
                        MetricLabel(
                            label: "Trades",
                            value: "\(engine.metrics.totalTrades)"
                        )
                        
                        MetricLabel(
                            label: "Win Rate",
                            value: String(format: "%.0f%%", engine.metrics.winRate * 100)
                        )
                        
                        MetricLabel(
                            label: "P&L",
                            value: String(format: "$%.0f", engine.metrics.netProfit),
                            color: engine.metrics.netProfit >= 0 ? .green : .red
                        )
                        
                        Spacer()
                    }
                    .font(.caption)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(engine.isActive ? Color.Theme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }
    
    private var statusColor: Color {
        switch engine.state {
        case .analyzing:
            return .blue
        case .executingTrade:
            return .orange
        case .monitoring:
            return .green
        case .paused:
            return .yellow
        default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch engine.state {
        case .analyzing:
            return "Analyzing"
        case .executingTrade:
            return "Trading"
        case .monitoring:
            return "Monitoring"
        case .paused:
            return "Paused"
        default:
            return "Idle"
        }
    }
}

struct MetricLabel: View {
    let label: String
    let value: String
    var color: Color = Color.Theme.text
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundColor(Color.Theme.text.opacity(0.6))
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct SymbolSelectorView: View {
    @Binding var selectedSymbol: String
    let symbols = ["EURUSD", "GBPUSD", "USDJPY", "XAUUSD", "BTCUSD", "ETHUSD"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(symbols, id: \.self) { symbol in
                    TradingSymbolChip(
                        symbol: symbol,
                        isSelected: selectedSymbol == symbol,
                        action: { selectedSymbol = symbol }
                    )
                }
            }
        }
    }
}

struct TradingSymbolChip: View {
    let symbol: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.bodyMedium)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : Color.Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.Theme.cardBackground
                        }
                    }
                )
                .cornerRadius(.smallCornerRadius)
        }
    }
}

struct PriceCardView: View {
    let symbol: String
    @StateObject private var marketData = MarketDataService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            if let quote = marketData.quotes[symbol],
               let change = marketData.priceChanges[symbol] {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(symbol)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        Text(symbolDescription)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(marketData.formatPrice(quote.mid, for: symbol))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        HStack(spacing: 4) {
                            Image(systemName: change.isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                            Text("\(change.isPositive ? "+" : "")\(String(format: "%.2f", change.changePercent))%")
                                .font(.caption)
                        }
                        .foregroundColor(change.isPositive ? Color.Theme.success : Color.Theme.error)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bid")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        Text(marketData.formatPrice(quote.bid, for: symbol))
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.Theme.sell)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Spread")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        Text(marketData.formatSpread(quote.spread, for: symbol))
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Ask")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        Text(marketData.formatPrice(quote.ask, for: symbol))
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.Theme.buy)
                    }
                }
            } else {
                // Loading state
                ProgressView()
                    .frame(height: 100)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(.cornerRadius)
        .shadow(color: Color.Theme.shadow, radius: 4, x: 0, y: 2)
        .onTapGesture {
            ChartPresentationManager.shared.presentChart(for: symbol)
        }
        .onAppear {
            marketData.startStreaming(symbols: [symbol])
        }
    }
    
    var symbolDescription: String {
        switch symbol {
        case "EURUSD": return "Euro / US Dollar"
        case "GBPUSD": return "British Pound / US Dollar"
        case "USDJPY": return "US Dollar / Japanese Yen"
        case "XAUUSD": return "Gold / US Dollar"
        case "BTCUSD": return "Bitcoin / US Dollar"
        case "ETHUSD": return "Ethereum / US Dollar"
        default: return "Forex Major"
        }
    }
}

struct QuickTradeButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: title == "Buy" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.title3)
                Text(title)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(.cornerRadius)
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

struct PositionCardView: View {
    let position: Position
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(position.symbol)
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                        
                        Text(position.type == .buy ? "BUY" : "SELL")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(position.type == .buy ? Color.Theme.buy : Color.Theme.sell)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    .foregroundColor(Color.Theme.text)
                    
                    Text("\(String(format: "%.2f", position.volume)) lots @ \(String(format: "%.5f", position.openPrice))")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    let profitDouble = position.unrealizedPL
                    let profitPercent = position.unrealizedPLPercent
                    
                    Text(profitDouble >= 0 ? "+$\(String(format: "%.2f", profitDouble))" : "-$\(String(format: "%.2f", abs(profitDouble)))")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(profitDouble >= 0 ? Color.Theme.success : Color.Theme.error)
                    
                    Text("\(profitDouble >= 0 ? "+" : "")\(String(format: "%.2f", profitPercent))%")
                        .font(.caption)
                        .foregroundColor(profitDouble >= 0 ? Color.Theme.success : Color.Theme.error)
                }
            }
            
            HStack {
                let slDouble = position.stopLoss ?? 0
                let tpDouble = position.takeProfit ?? 0
                
                Label("SL: \(String(format: "%.5f", slDouble))", systemImage: "shield")
                    .font(.caption)
                    .foregroundColor(Color.Theme.error)
                
                Spacer()
                
                Label("TP: \(String(format: "%.5f", tpDouble))", systemImage: "target")
                    .font(.caption)
                    .foregroundColor(Color.Theme.success)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(.cornerRadius)
    }
}

struct OrderCardView: View {
    let order: PendingOrder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(order.symbol)
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                    
                    Text(order.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.Theme.warning)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .foregroundColor(Color.Theme.text)
                
                Text("\(order.volume, specifier: "%.2f") lots @ \(order.price, specifier: "%.5f")")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: {
                // Cancel order
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color.Theme.error.opacity(0.8))
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(.cornerRadius)
    }
}

struct OrderRowView: View {
    let order: OrderData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(order.symbol)
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                    
                    Text(order.type.replacingOccurrences(of: "ORDER_TYPE_", with: ""))
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.Theme.warning)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                .foregroundColor(Color.Theme.text)
                
                Text("\(order.volume, specifier: "%.2f") lots @ \(order.openPrice, specifier: "%.5f")")
                    .font(.caption)
                    .foregroundColor(Color.Theme.text.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(order.state)
                    .font(.caption2)
                    .foregroundColor(Color.Theme.warning)
                if let currentPrice = order.currentPrice {
                    Text("Current: \(currentPrice, specifier: "%.5f")")
                        .font(.caption2)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(.cornerRadius)
    }
}

// MARK: - View Model

class TradingViewModel: ObservableObject {
    @Published var positions: [Position] = []
    @Published var orders: [PendingOrder] = []
    @Published var tradeSide: TradeSide = .buy
    @Published var hasConnectedAccount = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check for connected accounts
        checkConnectedAccounts()
        // Load mock data for demonstration
        loadMockData()
    }
    
    private func checkConnectedAccounts() {
        // Check if user has any connected trading accounts
        if let data = UserDefaults.standard.data(forKey: "connected_trading_accounts"),
           let accounts = try? JSONDecoder().decode([TradingAccount].self, from: data),
           !accounts.isEmpty {
            hasConnectedAccount = true
        }
    }
    
    func refreshData() {
        // Refresh positions and orders
        loadMockData()
    }
    
    private func loadMockData() {
        // Create mock tracked position
        let mockPosition = TrackedPosition(
            id: "1",
            symbol: "EURUSD",
            type: .buy,
            volume: 0.1,
            openPrice: 1.0850,
            openTime: Date(),
            stopLoss: 1.0820,
            takeProfit: 1.0880,
            comment: nil,
            magic: nil,
            currentPrice: 1.0854,
            bid: 1.0853,
            ask: 1.0855,
            unrealizedPL: 4.0,
            unrealizedPLPercent: 0.37,
            commission: 0,
            swap: 0,
            netPL: 4.0,
            pipValue: 10,
            pipsProfit: 4,
            spread: 0.0002,
            spreadCost: 2,
            marginUsed: 108.50,
            riskRewardRatio: 1.0
        )
        positions = [mockPosition]
        
        orders = [
            PendingOrder(
                id: "1",
                symbol: "GBPUSD",
                type: .buyLimit,
                volume: 0.05,
                price: 1.2700,
                stopLoss: 1.2650,
                takeProfit: 1.2750,
                createdAt: Date()
            )
        ]
    }
}

// MARK: - Models

struct PendingOrder: Identifiable {
    let id: String
    let symbol: String
    let type: OrderType
    let volume: Double
    let price: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let createdAt: Date
}

enum OrderType {
    case buyLimit, sellLimit, buyStop, sellStop
    
    var displayName: String {
        switch self {
        case .buyLimit: return "Buy Limit"
        case .sellLimit: return "Sell Limit"
        case .buyStop: return "Buy Stop"
        case .sellStop: return "Sell Stop"
        }
    }
}

class PriceDataManager: ObservableObject {
    static let shared = PriceDataManager()
    
    @Published var prices: [String: SymbolPrice] = [:]
    
    struct SymbolPrice {
        let bid: Double
        let ask: Double
        let change: Double
        let changePercent: Double
    }
}

#Preview {
    TradingView()
}