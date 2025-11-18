//
//  PremiumDashboardView.swift
//  Pipflow
//
//  Futuristic AI Trading Dashboard
//

import SwiftUI
import Charts

struct PremiumDashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTimeframe = "1D"
    @State private var showNewTrade = false
    @State private var animateBalance = false
    @State private var selectedMetric = 0
    @State private var showAIInsight = false
    @State private var animateChart = false
    @Namespace private var animation
    
    let timeframes = ["1M", "5M", "15M", "1H", "4H", "1D"]
    let metrics = ["Portfolio", "P&L", "Win Rate", "Volume"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Background
                GlassTheme.darkGradientBackground()
                    .ignoresSafeArea()
                
                // Subtle Particle Effect
                ParticleEmitterView()
                    .opacity(0.2)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Custom Navigation Header
                        customHeader
                        
                        // AI Assistant Banner
                        aiAssistantBanner
                        
                        // Hero Balance Display
                        heroBalanceCard
                        
                        // Animated Metrics
                        metricsCarousel
                        
                        // Performance Chart with Gradient
                        performanceChart
                        
                        // AI Trading Insights
                        aiTradingInsights
                        
                        // Quick Actions Grid
                        quickActionsGrid
                        
                        // Live Positions with Animation
                        livePositionsSection
                        
                        // Market Opportunities
                        marketOpportunities
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showNewTrade) {
            NewTradeView(
                symbol: "EUR/USD",
                side: .buy,
                onComplete: {}
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateBalance = true
                animateChart = true
            }
        }
    }
    
    // MARK: - Custom Header
    
    var customHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Alex Thompson")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "bell.badge")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .overlay(
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            )
                    }
                }
                
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.top, 60)
    }
    
    // MARK: - AI Assistant Banner
    
    var aiAssistantBanner: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Animated AI Icon
                ZStack {
                    Circle()
                        .fill(GlassTheme.accentGradient())
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "brain")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .scaleEffect(animateBalance ? 1.2 : 1.0)
                        .opacity(animateBalance ? 0 : 1)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: animateBalance)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Market Analysis")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("3 high-probability setups detected")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Button(action: { showAIInsight.toggle() }) {
                    Text("View")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Hero Balance Card
    
    var heroBalanceCard: some View {
        GlassCard {
            VStack(spacing: 24) {
                // Balance Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Portfolio Value")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                            
                            AnimatedNumberComponent(
                                value: 158749.32,
                                format: "%.2f"
                            )
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        }
                        
                        // Daily Change
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                            
                            Text("+$2,847.50")
                                .font(.callout)
                                .fontWeight(.semibold)
                            
                            Text("(+1.83%)")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        .foregroundColor(Color(hex: "00F5A0"))
                    }
                    
                    Spacer()
                    
                    // Mini Chart
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("24h")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Progress Bars
                VStack(spacing: 12) {
                    ProgressIndicator(
                        title: "Today's Target",
                        value: 0.73,
                        color: Color(hex: "00F5A0")
                    )
                    
                    ProgressIndicator(
                        title: "Risk Utilized",
                        value: 0.42,
                        color: Color(hex: "3A86FF")
                    )
                }
            }
        }
    }
    
    // MARK: - Metrics Carousel
    
    var metricsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                PremiumMetricCard(
                    title: "Win Rate",
                    value: "73.5%",
                    change: "+2.3%",
                    icon: "chart.line.uptrend.xyaxis",
                    gradient: GlassTheme.profitGradient()
                )
                
                PremiumMetricCard(
                    title: "Profit Factor",
                    value: "2.47",
                    change: "+0.15",
                    icon: "dollarsign.circle",
                    gradient: GlassTheme.accentGradient()
                )
                
                PremiumMetricCard(
                    title: "Avg. Trade",
                    value: "$847",
                    change: "+12%",
                    icon: "chart.bar",
                    gradient: LinearGradient(
                        colors: [Color(hex: "FF006E"), Color(hex: "8338EC")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                PremiumMetricCard(
                    title: "Active Trades",
                    value: "8",
                    change: "Live",
                    icon: "bolt.circle",
                    gradient: LinearGradient(
                        colors: [Color(hex: "FFB700"), Color(hex: "FF6B00")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
    }
    
    // MARK: - Performance Chart
    
    var performanceChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Chart Header
                HStack {
                    Text("Performance")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Timeframe Selector
                    HStack(spacing: 0) {
                        ForEach(timeframes, id: \.self) { timeframe in
                            Button(action: { selectedTimeframe = timeframe }) {
                                Text(timeframe)
                                    .font(.caption)
                                    .fontWeight(selectedTimeframe == timeframe ? .semibold : .regular)
                                    .foregroundColor(selectedTimeframe == timeframe ? .black : .white.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedTimeframe == timeframe ?
                                        Color.white : Color.clear
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                
                // Actual Chart
                if animateChart {
                    Chart {
                        ForEach(viewModel.chartData) { dataPoint in
                            AreaMark(
                                x: .value("Time", dataPoint.time),
                                y: .value("Value", dataPoint.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "00F5A0").opacity(0.6),
                                        Color(hex: "00F5A0").opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            LineMark(
                                x: .value("Time", dataPoint.time),
                                y: .value("Value", dataPoint.value)
                            )
                            .foregroundStyle(Color(hex: "00F5A0"))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine()
                                .foregroundStyle(Color.white.opacity(0.1))
                            AxisValueLabel()
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }
    
    // MARK: - AI Trading Insights
    
    var aiTradingInsights: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("AI Insights", systemImage: "brain")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Powered by GPT-4")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    InsightCard(
                        title: "EUR/USD Opportunity",
                        description: "Strong bullish momentum detected. RSI oversold on 4H timeframe.",
                        confidence: 0.87,
                        action: "BUY",
                        gradient: GlassTheme.profitGradient()
                    )
                    
                    InsightCard(
                        title: "Risk Alert: GBP/JPY",
                        description: "Approaching major resistance. Consider taking profits.",
                        confidence: 0.72,
                        action: "CAUTION",
                        gradient: LinearGradient(
                            colors: [Color(hex: "FFB700"), Color(hex: "FF6B00")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    InsightCard(
                        title: "Gold Setup Forming",
                        description: "Triangle pattern completion expected. Watch for breakout.",
                        confidence: 0.91,
                        action: "WATCH",
                        gradient: GlassTheme.accentGradient()
                    )
                }
            }
        }
    }
    
    // MARK: - Quick Actions Grid
    
    var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                QuickActionCard(
                    icon: "arrow.up.arrow.down",
                    title: "New Trade",
                    subtitle: "Execute instantly",
                    gradient: GlassTheme.accentGradient(),
                    action: { showNewTrade = true }
                )
                
                QuickActionCard(
                    icon: "doc.text.magnifyingglass",
                    title: "AI Signals",
                    subtitle: "12 new signals",
                    gradient: LinearGradient(
                        colors: [Color(hex: "3A86FF"), Color(hex: "7F5AF0")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    action: {}
                )
                
                QuickActionCard(
                    icon: "person.2.fill",
                    title: "Copy Trading",
                    subtitle: "Follow experts",
                    gradient: LinearGradient(
                        colors: [Color(hex: "FF006E"), Color(hex: "8338EC")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    action: {}
                )
                
                QuickActionCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Analytics",
                    subtitle: "Performance stats",
                    gradient: GlassTheme.profitGradient(),
                    action: {}
                )
            }
        }
    }
    
    // MARK: - Live Positions
    
    var livePositionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Live Positions", systemImage: "bolt.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            VStack(spacing: 12) {
                LivePositionCard(
                    symbol: "EUR/USD",
                    type: .buy,
                    volume: 0.5,
                    entryPrice: 1.0845,
                    currentPrice: 1.0867,
                    profit: 110.50,
                    profitPercent: 2.03
                )
                
                LivePositionCard(
                    symbol: "BTC/USD",
                    type: .buy,
                    volume: 0.02,
                    entryPrice: 98450,
                    currentPrice: 99200,
                    profit: 750.00,
                    profitPercent: 0.76
                )
            }
        }
    }
    
    // MARK: - Market Opportunities
    
    var marketOpportunities: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Market Scanner", systemImage: "radar")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                PulsingView {
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "00F5A0"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(hex: "00F5A0").opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(["USD/JPY", "GBP/USD", "XAU/USD", "EUR/GBP"], id: \.self) { pair in
                        MarketOpportunityCard(
                            symbol: pair,
                            signal: "Strong Buy",
                            pattern: "Breakout",
                            timeframe: "4H"
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct PremiumMetricCard: View {
    let title: String
    let value: String
    let change: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(gradient)
                    
                    Spacer()
                    
                    Text(change)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "00F5A0"))
                }
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(width: 140)
    }
}

struct ProgressIndicator: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * value, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct InsightCard: View {
    let title: String
    let description: String
    let confidence: Double
    let action: String
    let gradient: LinearGradient
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(action)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(gradient)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "brain")
                            .font(.caption)
                        Text("\(Int(confidence * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                
                Button(action: {}) {
                    HStack {
                        Text("Execute Trade")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .frame(width: 280)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            GlassCard {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(gradient)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LivePositionCard: View {
    let symbol: String
    let type: TradeSide
    let volume: Double
    let entryPrice: Double
    let currentPrice: Double
    let profit: Double
    let profitPercent: Double
    
    var body: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(symbol)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(type == .buy ? "BUY" : "SELL")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(type == .buy ? Color(hex: "00F5A0") : Color(hex: "FF4757"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                (type == .buy ? Color(hex: "00F5A0") : Color(hex: "FF4757"))
                                    .opacity(0.2)
                            )
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Entry")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text(String(format: "%.5f", entryPrice))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text(String(format: "%.5f", currentPrice))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Volume")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text(String(format: "%.2f", volume))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.2f", profit))
                        .font(.headline)
                        .foregroundColor(profit >= 0 ? Color(hex: "00F5A0") : Color(hex: "FF4757"))
                    
                    HStack(spacing: 4) {
                        Image(systemName: profit >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(String(format: "%.2f%%", profitPercent))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(profit >= 0 ? Color(hex: "00F5A0") : Color(hex: "FF4757"))
                }
            }
        }
    }
}

struct MarketOpportunityCard: View {
    let symbol: String
    let signal: String
    let pattern: String
    let timeframe: String
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(symbol)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    ShimmeringView {
                        Image(systemName: "sparkle")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                HStack(spacing: 8) {
                    Label(pattern, systemImage: "chart.xyaxis.line")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(timeframe)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Text(signal)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "00F5A0"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "00F5A0").opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .frame(width: 160)
    }
}

// MARK: - Preview

#Preview {
    PremiumDashboardView()
}