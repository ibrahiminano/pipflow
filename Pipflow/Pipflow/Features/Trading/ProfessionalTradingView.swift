//
//  ProfessionalTradingView.swift
//  Pipflow
//
//  Clean, Professional Trading Interface
//

import SwiftUI
import Combine

struct ProfessionalTradingView: View {
    @StateObject private var viewModel = TradingViewModel()
    @StateObject private var metaAPIService = MetaAPIService.shared
    @StateObject private var webSocketService = MetaAPIWebSocketService.shared
    @StateObject private var marketData = MarketDataService.shared
    @State private var selectedSymbol = "EURUSD"
    @State private var showNewTradeSheet = false
    @State private var showMetaTraderLink = false
    @State private var showAutoTrading = false
    @State private var isChartFullScreen = false
    
    let symbols = ["EURUSD", "GBPUSD", "USDJPY", "XAUUSD", "BTCUSD", "ETHUSD"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(hex: "0A0A0F")
                    .ignoresSafeArea()
                
                if isChartFullScreen {
                    // Fullscreen chart
                    fullScreenChart
                } else {
                    // Normal view
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header with balance
                            headerSection
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            
                            // Symbol Pills
                            symbolSelector
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            
                            // Extended chart with integrated buttons - NO HORIZONTAL PADDING
                            VStack(spacing: 0) {
                                // TradingView Chart
                                tradingViewChart
                                
                                // Quick Actions overlapping with chart
                                quickActions
                                    .padding(.horizontal)
                                    .padding(.top, -50) // Increased overlap
                            }
                            
                            // AI Auto-Trading (instead of features section)
                            aiAutoTradingCard
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            // Positions (if any)
                            if !metaAPIService.positions.isEmpty {
                                positionsSection
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                            }
                        }
                        .padding(.bottom, 20) // Reduced from 100
                    }
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
        }
        .onAppear {
            marketData.startStreaming(symbols: [selectedSymbol])
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Account Balance
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Balance")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Text("$125,847.56")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Connection Status
                if webSocketService.connectionState == .connected {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "00FF88"))
                            .frame(width: 6, height: 6)
                        Text("Live")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "00FF88"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "00FF88").opacity(0.1))
                    )
                } else {
                    Button(action: { showMetaTraderLink = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                            Text("Connect MT4/MT5 Account")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "0080FF"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "0080FF"), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Symbol Selector
    private var symbolSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(symbols, id: \.self) { symbol in
                    SymbolPill(
                        symbol: symbol,
                        isSelected: selectedSymbol == symbol,
                        action: {
                            selectedSymbol = symbol
                            marketData.startStreaming(symbols: [symbol])
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - TradingView Chart
    private var tradingViewChart: some View {
        VStack(spacing: 0) { // Removed spacing
            // Chart Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedSymbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(symbolDescription)
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                
                Spacer()
                
                // Price & Change
                if let quote = marketData.quotes[selectedSymbol],
                   let change = marketData.priceChanges[selectedSymbol] {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(marketData.formatPrice(quote.mid, for: selectedSymbol))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Image(systemName: change.isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10))
                            Text("\(change.isPositive ? "+" : "")\(String(format: "%.2f", change.changePercent))%")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(change.isPositive ? Color(hex: "00FF88") : Color(hex: "FF3B30"))
                    }
                }
                
                // Expand button
                Button(action: { isChartFullScreen = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.6))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.05))
                        )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4) // Reduced padding
            
            // Clean TradingView Chart - Extended height
            ChartView(symbol: selectedSymbol)
                .frame(height: 820) // Increased even more
                .cornerRadius(0) // Removed corner radius for edge-to-edge
        }
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        HStack(spacing: 12) {
            ProfessionalTradeButton(
                title: "BUY",
                icon: "arrow.up",
                color: Color(hex: "00FF88"),
                action: {
                    viewModel.tradeSide = .buy
                    showNewTradeSheet = true
                }
            )
            
            ProfessionalTradeButton(
                title: "SELL",
                icon: "arrow.down",
                color: Color(hex: "FF3B30"),
                action: {
                    viewModel.tradeSide = .sell
                    showNewTradeSheet = true
                }
            )
        }
    }
    
    // MARK: - AI Auto-Trading Card
    private var aiAutoTradingCard: some View {
        Button(action: { showAutoTrading = true }) {
            FeatureRow(
                icon: "cpu.fill",
                title: "AI Auto-Trading",
                subtitle: AIAutoTradingEngine.shared.isActive ? "Active • Monitoring markets" : "Configure automated strategies",
                iconColor: Color(hex: "BD00FF"),
                badge: AIAutoTradingEngine.shared.isActive ? "Active" : nil
            )
        }
    }
    
    // MARK: - Fullscreen Chart
    private var fullScreenChart: some View {
        ZStack {
            // Fullscreen TradingView chart
            ChartView(symbol: selectedSymbol)
                .ignoresSafeArea()
            
            // Overlay controls
            VStack {
                // Top controls
                HStack {
                    // Symbol selector
                    symbolSelector
                        .padding(.leading)
                    
                    Spacer()
                    
                    // Close button
                    Button(action: { isChartFullScreen = false }) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.trailing)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Bottom trading buttons
                quickActions
                    .padding(.horizontal)
                    .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Positions Section
    private var positionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Open Positions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: PositionsView()) {
                    Text("View All")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0080FF"))
                }
            }
            
            VStack(spacing: 12) {
                ForEach(metaAPIService.positions.prefix(3)) { position in
                    PositionRow(position: position)
                }
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
        default: return ""
        }
    }
}

// MARK: - Supporting Views

struct SymbolPill: View {
    let symbol: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color(hex: "0080FF").opacity(0.2) : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color(hex: "0080FF") : Color.clear, lineWidth: 1)
                        )
                )
        }
    }
}

struct ProfessionalTradeButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    // Blur background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                    
                    // Color overlay
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.85))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color, lineWidth: 1)
            )
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    var badge: String? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.1))
                )
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            // Badge or Arrow
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "00FF88"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "00FF88").opacity(0.1))
                    )
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.3))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

struct PositionRow: View {
    let position: Position
    
    var body: some View {
        HStack {
            // Symbol & Type
            VStack(alignment: .leading, spacing: 4) {
                Text(position.symbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(position.type == .buy ? "BUY" : "SELL")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(position.type == .buy ? Color(hex: "00FF88") : Color(hex: "FF3B30"))
                    
                    Text("\(String(format: "%.2f", position.volume)) lots")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // P&L
            VStack(alignment: .trailing, spacing: 4) {
                let profit = position.unrealizedPL
                let profitPercent = position.unrealizedPLPercent
                
                Text(profit >= 0 ? "+$\(String(format: "%.2f", profit))" : "-$\(String(format: "%.2f", abs(profit)))")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(profit >= 0 ? Color(hex: "00FF88") : Color(hex: "FF3B30"))
                
                Text("\(profit >= 0 ? "+" : "")\(String(format: "%.2f", profitPercent))%")
                    .font(.system(size: 11))
                    .foregroundColor((profit >= 0 ? Color(hex: "00FF88") : Color(hex: "FF3B30")).opacity(0.8))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ProfessionalTradingView()
        .preferredColorScheme(.dark)
}