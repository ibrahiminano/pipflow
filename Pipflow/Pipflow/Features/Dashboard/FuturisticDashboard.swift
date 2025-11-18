//
//  FuturisticDashboard.swift
//  Pipflow
//
//  Ultra-modern, addictive dashboard with stunning animations
//

import SwiftUI
import Charts

struct FuturisticDashboard: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTimeframe = "24H"
    @State private var animateIn = false
    @State private var pulseAnimation = false
    
    let timeframes = ["1H", "24H", "7D", "1M", "1Y"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Simple dark background
                Color.deepSpace
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Portfolio Value Card
                        portfolioCard
                        
                        // Quick Stats Grid
                        quickStatsGrid
                        
                        // Quick Actions
                        quickActions
                        
                        // Active Positions
                        activePositions
                        
                        // AI Insights
                        aiInsights
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            animateIn = true
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Spacer()
            
            // Notification Bell with Badge
            ZStack(alignment: .topTrailing) {
                Button(action: {}) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                
                Circle()
                    .fill(Color.neonPink)
                    .frame(width: 12, height: 12)
                    .offset(x: -8, y: 8)
            }
        }
    }
    
    // MARK: - Portfolio Card
    private var portfolioCard: some View {
        VStack(spacing: 16) {
            // Balance Display
            VStack(spacing: 4) {
                Text("Total Balance")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                Text("$125,847.56")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Today's Performance
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                    Text("+$2,341.23")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.plasmaGreen)
                    Text("+1.89%")
                        .font(.caption2)
                        .foregroundColor(.plasmaGreen.opacity(0.8))
                }
                
                VStack(spacing: 2) {
                    Text("This Week")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                    Text("+$8,234.56")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.plasmaGreen)
                    Text("+6.72%")
                        .font(.caption2)
                        .foregroundColor(.plasmaGreen.opacity(0.8))
                }
            }
            
            // Timeframe Selector
            HStack(spacing: 0) {
                ForEach(timeframes, id: \.self) { timeframe in
                    TimeframeButton(
                        title: timeframe,
                        isSelected: selectedTimeframe == timeframe
                    ) {
                        withAnimation(.spring()) {
                            selectedTimeframe = timeframe
                        }
                    }
                }
            }
            .background(Color.white.opacity(0.03))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            HolographicCard {
                Color.clear
            }
        )
    }
    
    // MARK: - Quick Stats Grid
    private var quickStatsGrid: some View {
        HStack(spacing: 16) {
            FuturisticStatCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Win Rate",
                value: "68.5%",
                trend: "+5.2%",
                color: .neonCyan
            )
            
            FuturisticStatCard(
                icon: "bolt.fill",
                title: "Active Trades",
                value: "12",
                trend: "3 pending",
                color: .neonPurple
            )
        }
    }
    
    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    NavigationLink(destination: TradingView()) {
                        FuturisticActionCard(
                            icon: "plus.circle.fill",
                            title: "New Trade",
                            color: .neonCyan
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    
                    NavigationLink(destination: GenerateSignalView()) {
                        FuturisticActionCard(
                            icon: "bell.fill",
                            title: "AI Signals",
                            color: .neonPurple
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: CopyTradingView()) {
                        FuturisticActionCard(
                            icon: "person.2.fill",
                            title: "Copy Trade",
                            color: .plasmaGreen
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: AcademyView()) {
                        FuturisticActionCard(
                            icon: "graduationcap.fill",
                            title: "Academy",
                            color: .neonPink
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: PIPSWalletView()) {
                        FuturisticActionCard(
                            icon: "creditcard.fill",
                            title: "Wallet",
                            color: .electricBlue
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: SettingsView()) {
                        FuturisticActionCard(
                            icon: "gearshape.fill",
                            title: "Settings",
                            color: .neonCyan
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: NotificationsView()) {
                        FuturisticActionCard(
                            icon: "bell.badge.fill",
                            title: "Alerts",
                            color: .neonPurple
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Active Positions
    private var activePositions: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Positions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Text("View All")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.neonCyan)
                }
            }
            
            VStack(spacing: 12) {
                DashboardPositionRow(
                    symbol: "EUR/USD",
                    type: "Buy",
                    volume: 0.10,
                    profit: 234.56,
                    percentage: 2.34
                )
                
                DashboardPositionRow(
                    symbol: "BTC/USD",
                    type: "Buy",
                    volume: 0.05,
                    profit: 1567.89,
                    percentage: 4.56
                )
                
                DashboardPositionRow(
                    symbol: "GBP/USD",
                    type: "Sell",
                    volume: 0.08,
                    profit: -123.45,
                    percentage: -1.23
                )
            }
        }
    }
    
    // MARK: - AI Insights
    private var aiInsights: some View {
        HolographicCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sparkle")
                        .font(.body)
                        .foregroundColor(.neonPurple)
                    
                    Text("AI Insights")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Live")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.plasmaGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.plasmaGreen.opacity(0.2))
                        )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    InsightRow(
                        icon: "arrow.up.circle.fill",
                        text: "Strong bullish momentum detected on EUR/USD",
                        color: .plasmaGreen
                    )
                    
                    InsightRow(
                        icon: "exclamationmark.triangle.fill",
                        text: "Risk level increasing on GBP/USD position",
                        color: .neonPink
                    )
                    
                    InsightRow(
                        icon: "lightbulb.fill",
                        text: "Consider taking profits on BTC position",
                        color: .electricBlue
                    )
                }
            }
            .padding(24)
        }
    }
    
}

// MARK: - Supporting Views

struct TimeframeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    isSelected ? AnyView(
                        LinearGradient(
                            colors: [.neonCyan.opacity(0.3), .electricBlue.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ) : AnyView(Color.clear)
                )
        }
    }
}

struct FuturisticStatCard: View {
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
                .font(.title2)
                .fontWeight(.semibold)
                .monospacedDigit()
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

struct DashboardPositionRow: View {
    let symbol: String
    let type: String
    let volume: Double
    let profit: Double
    let percentage: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(symbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Text(type.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(type == "Buy" ? .plasmaGreen : .neonPink)
                    
                    Text("• \(String(format: "%.2f", volume)) lots")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(profit >= 0 ? "+$\(String(format: "%.2f", profit))" : "-$\(String(format: "%.2f", abs(profit)))")
                    .font(.system(size: 15, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(profit >= 0 ? .plasmaGreen : .neonPink)
                
                Text("\(percentage >= 0 ? "+" : "")\(String(format: "%.2f", percentage))%")
                    .font(.system(size: 11))
                    .foregroundColor(profit >= 0 ? .plasmaGreen.opacity(0.8) : .neonPink.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            HolographicCard {
                Color.clear
            }
        )
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
            
            Spacer()
        }
    }
}

struct FuturisticActionCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
                .neonGlow(color: color, radius: 3)
            
            Text(title)
                .font(.system(size: 11))
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(width: 72)
    }
}

// MARK: - Animated Number
struct AnimatedNumber: View {
    let value: Double
    let format: String
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text(String(format: format, displayValue))
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    displayValue = value
                }
            }
    }
}

#Preview {
    FuturisticDashboard()
        .preferredColorScheme(.dark)
}