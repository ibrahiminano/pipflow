//
//  TradingView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI
import Combine

struct TradingView: View {
    @StateObject private var viewModel = TradingViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedSymbol = "EURUSD"
    @State private var showNewTradeSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.Theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Symbol Selector
                    SymbolSelectorView(selectedSymbol: $selectedSymbol)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    ScrollView {
                        VStack(spacing: .sectionSpacing) {
                            // Chart Button - Made more prominent
                            Button(action: {
                                ChartPresentationManager.shared.presentChart(for: selectedSymbol)
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.title2)
                                    Text("View Chart")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(
                                        colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(.cornerRadius)
                                .shadow(color: Color.Theme.shadow, radius: 4, x: 0, y: 2)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
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
                        
                        // Open Positions
                        if !viewModel.positions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Open Positions")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.Theme.text)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.positions) { position in
                                    PositionCardView(position: position)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Pending Orders
                        if !viewModel.orders.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pending Orders")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.Theme.text)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.orders) { order in
                                    OrderCardView(order: order)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        ChartPresentationManager.shared.presentChart(for: selectedSymbol)
                    }) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(Color.blue)
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
            }
        }
    }
}

// MARK: - Supporting Views

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
                        
                        Text(position.side.rawValue.uppercased())
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(position.side == .buy ? Color.Theme.buy : Color.Theme.sell)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    .foregroundColor(Color.Theme.text)
                    
                    Text("\(position.volume, specifier: "%.2f") lots @ \(position.openPrice, specifier: "%.5f")")
                        .font(.caption)
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(position.profit >= 0 ? "+$\(position.profit, specifier: "%.2f")" : "-$\(abs(position.profit), specifier: "%.2f")")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(position.profit >= 0 ? Color.Theme.success : Color.Theme.error)
                    
                    Text("\(position.profit >= 0 ? "+" : "")\(position.profitPercentage, specifier: "%.2f")%")
                        .font(.caption)
                        .foregroundColor(position.profit >= 0 ? Color.Theme.success : Color.Theme.error)
                }
            }
            
            HStack {
                Label("SL: \(position.stopLoss ?? 0, specifier: "%.5f")", systemImage: "shield")
                    .font(.caption)
                    .foregroundColor(Color.Theme.error)
                
                Spacer()
                
                Label("TP: \(position.takeProfit ?? 0, specifier: "%.5f")", systemImage: "target")
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

// MARK: - View Model

class TradingViewModel: ObservableObject {
    @Published var positions: [Position] = []
    @Published var orders: [PendingOrder] = []
    @Published var tradeSide: TradeSide = .buy
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load mock data for demonstration
        loadMockData()
    }
    
    func refreshData() {
        // Refresh positions and orders
        loadMockData()
    }
    
    private func loadMockData() {
        positions = [
            Position(
                id: "1",
                symbol: "EURUSD",
                side: .buy,
                volume: 0.1,
                openPrice: 1.0850,
                currentPrice: 1.0854,
                profit: 4.0,
                profitPercentage: 0.04,
                stopLoss: 1.0820,
                takeProfit: 1.0880,
                openTime: Date()
            )
        ]
        
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

struct Position: Identifiable {
    let id: String
    let symbol: String
    let side: TradeSide
    let volume: Double
    let openPrice: Double
    let currentPrice: Double
    let profit: Double
    let profitPercentage: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let openTime: Date
    let swap: Double = 0
    let commission: Double = 0
    let magicNumber: Int? = nil
    let comment: String? = nil
    
    var netProfit: Double {
        profit - commission - swap
    }
}

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