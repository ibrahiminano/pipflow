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
    @State private var animatePrice = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color.Theme.background,
                        Color.Theme.background.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section - Symbol & Chart Access
                        VStack(spacing: 16) {
                            // Modern Symbol Selector
                            ModernSymbolSelector(selectedSymbol: $selectedSymbol)
                            
                            // Enhanced Price Display Card
                            EnhancedPriceCard(symbol: selectedSymbol, animatePrice: $animatePrice)
                        }
                        .padding(.top, 8)
                        
                        // Trading Actions Section
                        VStack(spacing: 20) {
                            HStack {
                                Text("Quick Actions")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.Theme.text)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            // Chart Access & Trading Buttons
                            VStack(spacing: 16) {
                                // Professional Chart Button
                                ProfessionalChartButton(symbol: selectedSymbol)
                                
                                // Enhanced Trade Buttons
                                HStack(spacing: 16) {
                                    EnhancedTradeButton(
                                        title: "BUY",
                                        subtitle: "Go Long",
                                        color: Color.Theme.success,
                                        icon: "arrow.up.circle.fill"
                                    ) {
                                        viewModel.tradeSide = .buy
                                        showNewTradeSheet = true
                                    }
                                    
                                    EnhancedTradeButton(
                                        title: "SELL",
                                        subtitle: "Go Short",
                                        color: Color.Theme.error,
                                        icon: "arrow.down.circle.fill"
                                    ) {
                                        viewModel.tradeSide = .sell
                                        showNewTradeSheet = true
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Portfolio Overview
                        if !viewModel.positions.isEmpty || !viewModel.orders.isEmpty {
                            VStack(spacing: 20) {
                                HStack {
                                    Text("Portfolio")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.Theme.text)
                                    Spacer()
                                    
                                    Button(action: {
                                        // Navigate to full portfolio view
                                    }) {
                                        Text("View All")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color.Theme.accent)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Modern Position Cards
                                if !viewModel.positions.isEmpty {
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.positions) { position in
                                            ModernPositionCard(position: position)
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                
                                // Modern Order Cards
                                if !viewModel.orders.isEmpty {
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.orders) { order in
                                            ModernOrderCard(order: order)
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
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
        .onAppear {
            startPriceAnimation()
        }
    }
    
    private func startPriceAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animatePrice.toggle()
        }
    }
}

// MARK: - Modern Symbol Selector

struct ModernSymbolSelector: View {
    @Binding var selectedSymbol: String
    @EnvironmentObject var themeManager: ThemeManager
    
    private let symbols = ["EURUSD", "GBPUSD", "USDJPY", "XAUUSD", "BTCUSD", "ETHUSD"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Markets")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.Theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(symbols, id: \.self) { symbol in
                        ModernSymbolChip(
                            symbol: symbol,
                            isSelected: selectedSymbol == symbol
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedSymbol = symbol
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct ModernSymbolChip: View {
    let symbol: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(symbol)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color.Theme.text)
                
                // Mock price change indicator
                Text("+0.24%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color.Theme.success)
            }
            .frame(width: 80, height: 60)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.Theme.accent, Color.Theme.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.Theme.cardBackground
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: isSelected ? Color.Theme.accent.opacity(0.3) : Color.Theme.shadow,
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Price Card

struct EnhancedPriceCard: View {
    let symbol: String
    @Binding var animatePrice: Bool
    @StateObject private var marketData = MarketDataService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            if let quote = marketData.quotes[symbol],
               let change = marketData.priceChanges[symbol] {
                
                // Header with symbol info
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(symbol)
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundColor(Color.Theme.text)
                            
                            Text(symbolDescription)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(marketData.formatPrice(quote.mid, for: symbol))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color.Theme.text)
                                .scaleEffect(animatePrice ? 1.02 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: animatePrice)
                            
                            HStack(spacing: 6) {
                                Image(systemName: change.isPositive ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 12, weight: .bold))
                                Text("\(change.isPositive ? "+" : "")\(String(format: "%.2f", change.changePercent))%")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(change.isPositive ? Color.Theme.success : Color.Theme.error)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                (change.isPositive ? Color.Theme.success : Color.Theme.error)
                                    .opacity(0.1)
                            )
                            .clipShape(Capsule())
                        }
                    }
                    
                    // Bid/Ask Section
                    HStack(spacing: 0) {
                        // Bid
                        VStack(spacing: 8) {
                            Text("BID")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.Theme.textSecondary)
                            
                            Text(marketData.formatPrice(quote.bid, for: symbol))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color.Theme.sell)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.Theme.sell.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Spread
                        VStack(spacing: 8) {
                            Text("SPREAD")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.Theme.textSecondary)
                            
                            Text(String(format: "%.1f", quote.spread * 10))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color.Theme.text)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        
                        // Ask
                        VStack(spacing: 8) {
                            Text("ASK")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.Theme.textSecondary)
                            
                            Text(marketData.formatPrice(quote.ask, for: symbol))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color.Theme.buy)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.Theme.buy.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(24)
                
            } else {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color.Theme.accent)
                    
                    Text("Loading market data...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.Theme.textSecondary)
                }
                .frame(height: 180)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.Theme.cardBackground)
                .shadow(color: Color.Theme.shadow, radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
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
        default: return "Currency Pair"
        }
    }
}

// MARK: - Professional Chart Button

struct ProfessionalChartButton: View {
    let symbol: String
    
    var body: some View {
        Button(action: {
            ChartPresentationManager.shared.presentChart(for: symbol)
        }) {
            HStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Charts")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Technical analysis & indicators")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        Color.Theme.accent,
                        Color.Theme.accent.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.Theme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Trade Button

struct EnhancedTradeButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Position Card

struct ModernPositionCard: View {
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
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text(position.symbol)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color.Theme.text)
                        
                        Text(position.side.rawValue.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(position.side == .buy ? Color.Theme.buy : Color.Theme.sell)
                            .clipShape(Capsule())
                    }
                    
                    Text("\(String(format: "%.2f", position.volume)) lots")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.Theme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(String(format: "%+.2f USD", profit))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(profit >= 0 ? Color.Theme.success : Color.Theme.error)
                    
                    Text(String(format: "%.5f", currentPrice))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.Theme.textSecondary)
                }
            }
            
            // Progress bar for P&L
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.Theme.separator.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(profit >= 0 ? Color.Theme.success : Color.Theme.error)
                        .frame(width: min(abs(profit) / 100 * geometry.size.width, geometry.size.width), height: 4)
                }
                .clipShape(Capsule())
            }
            .frame(height: 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.cardBackground)
                .shadow(color: Color.Theme.shadow, radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Modern Order Card

struct ModernOrderCard: View {
    let order: PendingOrder
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text(order.symbol)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color.Theme.text)
                        
                        Text(order.type.rawValue.replacingOccurrences(of: "_", with: " "))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.Theme.warning)
                            .clipShape(Capsule())
                    }
                    
                    Text("\(String(format: "%.2f", order.volume)) lots @ \(String(format: "%.5f", order.price))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.Theme.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    // Cancel order action
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color.Theme.error)
                        .clipShape(Circle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Theme.cardBackground)
                .shadow(color: Color.Theme.shadow, radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - View Model (unchanged)

class TradingViewModel: ObservableObject {
    @Published var positions: [Position] = []
    @Published var orders: [PendingOrder] = []
    @Published var tradeSide: TradeSide = .buy
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMockData()
    }
    
    func refreshData() {
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

// MARK: - Models (unchanged)

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
    
    enum OrderType: String {
        case buyLimit = "BUY_LIMIT"
        case sellLimit = "SELL_LIMIT"
        case buyStop = "BUY_STOP"
        case sellStop = "SELL_STOP"
    }
}

#Preview {
    TradingView()
        .environmentObject(ThemeManager.shared)
}