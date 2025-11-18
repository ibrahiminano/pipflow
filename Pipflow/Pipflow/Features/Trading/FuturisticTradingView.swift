//
//  FuturisticTradingView.swift
//  Pipflow
//
//  Futuristic Trading Interface
//

import SwiftUI
import Combine

struct FuturisticTradingView: View {
    @StateObject private var viewModel = TradingViewModel()
    @StateObject private var metaAPIService = MetaAPIService.shared
    @StateObject private var webSocketService = MetaAPIWebSocketService.shared
    @StateObject private var marketData = MarketDataService.shared
    @State private var selectedSymbol = "EURUSD"
    @State private var showNewTradeSheet = false
    @State private var showMetaTraderLink = false
    @State private var showAutoTrading = false
    @State private var animateIn = false
    
    let symbols = ["EURUSD", "GBPUSD", "USDJPY", "XAUUSD", "BTCUSD", "ETHUSD"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.deepSpace
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Symbol Selector
                        symbolSelector
                        
                        // Account Connection Banner
                        if !viewModel.hasConnectedAccount {
                            connectionBanner
                        }
                        
                        // Price Display
                        priceDisplay
                        
                        // Trading Actions
                        tradingActions
                        
                        // Chart Section
                        chartSection
                        
                        // AI Auto-Trading
                        aiTradingSection
                        
                        // Open Positions
                        if !metaAPIService.positions.isEmpty {
                            openPositionsSection
                        }
                        
                        // Market Stats
                        marketStatsSection
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
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
        .fullScreenCover(isPresented: $showMetaTraderLink) {
            FuturisticMetaTraderLinkView()
        }
        .sheet(isPresented: $showAutoTrading) {
            NavigationView {
                AIAutoTradingView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            animateIn = true
            marketData.startStreaming(symbols: [selectedSymbol])
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Trading")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.neonCyan, .electricBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Real-time Market Access")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Connection Status
            if webSocketService.connectionState == .connected {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.plasmaGreen)
                        .frame(width: 8, height: 8)
                    Text("Connected")
                        .font(.caption)
                        .foregroundColor(.plasmaGreen)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.plasmaGreen.opacity(0.2))
                )
            }
        }
    }
    
    // MARK: - Symbol Selector
    private var symbolSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(symbols, id: \.self) { symbol in
                    FuturisticSymbolChip(
                        symbol: symbol,
                        isSelected: selectedSymbol == symbol,
                        action: {
                            withAnimation(.spring()) {
                                selectedSymbol = symbol
                                marketData.startStreaming(symbols: [symbol])
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Connection Banner
    private var connectionBanner: some View {
        Button(action: { showMetaTraderLink = true }) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .font(.title2)
                    .foregroundColor(.neonCyan)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect MetaTrader Account")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("Link your MT4/MT5 to start trading")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(
                HolographicCard {
                    LinearGradient(
                        colors: [.neonCyan.opacity(0.3), .electricBlue.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            )
        }
    }
    
    // MARK: - Price Display
    private var priceDisplay: some View {
        HolographicCard {
            VStack(spacing: 20) {
                if let quote = marketData.quotes[selectedSymbol],
                   let change = marketData.priceChanges[selectedSymbol] {
                    // Symbol & Price
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedSymbol)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(symbolDescription)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(marketData.formatPrice(quote.mid, for: selectedSymbol))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.9)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            HStack(spacing: 4) {
                                Image(systemName: change.isPositive ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption)
                                Text("\(change.isPositive ? "+" : "")\(String(format: "%.2f", change.changePercent))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(change.isPositive ? .plasmaGreen : .neonPink)
                        }
                    }
                    
                    // Bid/Ask/Spread
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text("BID")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                            Text(marketData.formatPrice(quote.bid, for: selectedSymbol))
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(.neonPink)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Text("SPREAD")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                            Text(marketData.formatSpread(quote.spread, for: selectedSymbol))
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: 4) {
                            Text("ASK")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                            Text(marketData.formatPrice(quote.ask, for: selectedSymbol))
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(.plasmaGreen)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // Loading state
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .neonCyan))
                        .frame(height: 100)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Trading Actions
    private var tradingActions: some View {
        HStack(spacing: 16) {
            TradeActionButton(
                title: "BUY",
                icon: "arrow.up.circle.fill",
                color: .plasmaGreen,
                action: {
                    viewModel.tradeSide = .buy
                    showNewTradeSheet = true
                }
            )
            
            TradeActionButton(
                title: "SELL",
                icon: "arrow.down.circle.fill",
                color: .neonPink,
                action: {
                    viewModel.tradeSide = .sell
                    showNewTradeSheet = true
                }
            )
        }
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        NavigationLink(destination: ChartView(symbol: selectedSymbol)) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.electricBlue)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.electricBlue.opacity(0.2))
                    )
                    .neonGlow(color: .electricBlue, radius: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("View Advanced Chart")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Technical analysis & indicators")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(
                HolographicCard {
                    Color.clear
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - AI Trading Section
    private var aiTradingSection: some View {
        Button(action: { showAutoTrading = true }) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "brain")
                        .font(.title2)
                        .foregroundColor(.neonPurple)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(Color.neonPurple.opacity(0.2))
                        )
                        .neonGlow(color: .neonPurple, radius: 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Auto-Trading")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(AIAutoTradingEngine.shared.isActive ? "Active • Monitoring Markets" : "Inactive • Tap to Configure")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    if AIAutoTradingEngine.shared.isActive {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.plasmaGreen)
                                .frame(width: 8, height: 8)
                            Text("Running")
                                .font(.caption2)
                                .foregroundColor(.plasmaGreen)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.plasmaGreen.opacity(0.2))
                        )
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                if AIAutoTradingEngine.shared.isActive {
                    HStack(spacing: 24) {
                        MetricDisplay(
                            label: "Trades",
                            value: "\(AIAutoTradingEngine.shared.metrics.totalTrades)",
                            icon: "chart.bar.fill",
                            color: .neonCyan
                        )
                        
                        MetricDisplay(
                            label: "Win Rate",
                            value: String(format: "%.0f%%", AIAutoTradingEngine.shared.metrics.winRate * 100),
                            icon: "percent",
                            color: .electricBlue
                        )
                        
                        MetricDisplay(
                            label: "P&L",
                            value: String(format: "$%.0f", AIAutoTradingEngine.shared.metrics.netProfit),
                            icon: "dollarsign.circle.fill",
                            color: AIAutoTradingEngine.shared.metrics.netProfit >= 0 ? .plasmaGreen : .neonPink
                        )
                    }
                }
            }
            .padding()
            .background(
                HolographicCard {
                    Color.clear
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Open Positions Section
    private var openPositionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Open Positions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: PositionsView()) {
                    Text("View All")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.neonCyan)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(metaAPIService.positions.prefix(3)) { position in
                    FuturisticPositionCard(position: position)
                }
            }
        }
    }
    
    // MARK: - Market Stats Section
    private var marketStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                MarketStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "24h Volume",
                    value: "$2.34B",
                    trend: "+12%",
                    color: .neonCyan
                )
                
                MarketStatCard(
                    icon: "speedometer",
                    title: "Volatility",
                    value: "Medium",
                    trend: "0.8%",
                    color: .electricBlue
                )
            }
        }
    }
    
    private var symbolDescription: String {
        switch selectedSymbol {
        case "EURUSD": return "Euro / US Dollar"
        case "GBPUSD": return "British Pound / US Dollar"
        case "USDJPY": return "US Dollar / Japanese Yen"
        case "XAUUSD": return "Gold / US Dollar"
        case "BTCUSD": return "Bitcoin / US Dollar"
        case "ETHUSD": return "Ethereum / US Dollar"
        default: return "Forex Pair"
        }
    }
}

// MARK: - Supporting Views

struct FuturisticSymbolChip: View {
    let symbol: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [.neonCyan.opacity(0.3), .electricBlue.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.white.opacity(0.05)
                        }
                    }
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.neonCyan.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct TradeActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .neonGlow(color: color, radius: 8)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }
}

struct MetricDisplay: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

struct FuturisticPositionCard: View {
    let position: Position
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(position.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(position.type == .buy ? "BUY" : "SELL")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(position.type == .buy ? Color.plasmaGreen : Color.neonPink)
                        )
                }
                
                HStack(spacing: 12) {
                    Text("\(String(format: "%.2f", position.volume)) lots")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("@ \(String(format: "%.5f", position.openPrice))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                let profitDouble = position.unrealizedPL
                let profitPercent = position.unrealizedPLPercent
                
                Text(profitDouble >= 0 ? "+$\(String(format: "%.2f", profitDouble))" : "-$\(String(format: "%.2f", abs(profitDouble)))")
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(profitDouble >= 0 ? .plasmaGreen : .neonPink)
                
                Text("\(profitDouble >= 0 ? "+" : "")\(String(format: "%.2f", profitPercent))%")
                    .font(.caption)
                    .foregroundColor(profitDouble >= 0 ? .plasmaGreen.opacity(0.8) : .neonPink.opacity(0.8))
            }
        }
        .padding()
        .background(
            HolographicCard {
                Color.clear
            }
        )
    }
}

struct MarketStatCard: View {
    let icon: String
    let title: String
    let value: String
    let trend: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .neonGlow(color: color, radius: 4)
                
                Spacer()
                
                Text(trend)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color.opacity(0.8))
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            HolographicCard {
                Color.clear
            }
        )
    }
}

#Preview {
    FuturisticTradingView()
        .preferredColorScheme(.dark)
}