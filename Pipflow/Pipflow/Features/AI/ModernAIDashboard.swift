//
//  ModernAIDashboard.swift
//  Pipflow
//
//  Redesigned AI Dashboard with clean, modern interface
//

import SwiftUI
import Charts

struct ModernAIDashboard: View {
    @State private var selectedFeature: AIFeature? = nil
    @State private var showingFeatureDetail = false
    @State private var animateCards = false
    @StateObject private var aiEngine = AIAutoTradingEngine.shared
    @StateObject private var signalService = AISignalService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(hex: "0A0A0F")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top Section - Primary Stats
                        primaryStatsSection
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 24)
                        
                        // AI Status Banner
                        aiStatusBanner
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        
                        // Quick Actions
                        quickActionsSection
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                        
                        // Performance Chart
                        performanceChartSection
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                        
                        // Active Strategies
                        activeStrategiesSection
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                        
                        // AI Insights
                        aiInsightsSection
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateCards = true
                }
            }
        }
    }
    
    // MARK: - Primary Stats Section
    private var primaryStatsSection: some View {
        VStack(spacing: 20) {
            // Main Performance Card
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Performance")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("87.3%")
                                .font(.system(size: 42, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("+2.1%")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "00FF88"))
                                .padding(.bottom, 8)
                        }
                        
                        Text("Success Rate • Last 30 days")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Circular Progress
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: 0.873)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "BD00FF"), Color(hex: "0080FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "brain")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "BD00FF"))
                    }
                }
                
                // Sub metrics
                HStack(spacing: 16) {
                    SubMetricView(
                        label: "Today's Signals",
                        value: "24",
                        subtext: "18 profitable",
                        trend: .up
                    )
                    
                    SubMetricView(
                        label: "Active Strategies",
                        value: "5",
                        subtext: "2 running",
                        trend: .neutral
                    )
                    
                    SubMetricView(
                        label: "Avg Return",
                        value: "+4.2%",
                        subtext: "per trade",
                        trend: .up
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }
    
    // MARK: - AI Status Banner
    private var aiStatusBanner: some View {
        HStack(spacing: 12) {
            // Status Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(aiEngine.isActive ? Color(hex: "00FF88") : Color.orange)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(aiEngine.isActive ? Color(hex: "00FF88") : Color.orange)
                            .frame(width: 8, height: 8)
                            .opacity(0.5)
                            .scaleEffect(2)
                            .animation(.easeInOut(duration: 1.5).repeatForever(), value: aiEngine.isActive)
                    )
                
                Text(aiEngine.isActive ? "AI Engine Active" : "AI Engine Paused")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Quick Toggle
            Button(action: { 
                if aiEngine.isActive {
                    aiEngine.stopAutoTrading()
                } else {
                    aiEngine.startAutoTrading()
                }
            }) {
                Text(aiEngine.isActive ? "Pause" : "Activate")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(aiEngine.isActive ? Color(hex: "FF3B30") : Color(hex: "00FF88"))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1C1C1E"))
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AIQuickActionCard(
                        icon: "waveform.path.ecg",
                        title: "Generate Signal",
                        subtitle: "AI market analysis",
                        color: Color(hex: "0080FF"),
                        destination: AnyView(GenerateSignalView())
                    )
                    
                    AIQuickActionCard(
                        icon: "hammer.fill",
                        title: "Build Strategy",
                        subtitle: "Create with prompts",
                        color: Color(hex: "BD00FF"),
                        destination: AnyView(NaturalLanguageStrategyView())
                    )
                    
                    AIQuickActionCard(
                        icon: "play.circle.fill",
                        title: "Auto Trading",
                        subtitle: "Configure automation",
                        color: Color(hex: "00FF88"),
                        destination: AnyView(AIAutoTradingView())
                    )
                    
                    AIQuickActionCard(
                        icon: "clock.arrow.2.circlepath",
                        title: "Backtest",
                        subtitle: "Test strategies",
                        color: Color(hex: "FF9500"),
                        destination: AnyView(BacktestingView())
                    )
                    
                    AIQuickActionCard(
                        icon: "brain.head.profile",
                        title: "Trading Charts",
                        subtitle: "Real-time market data",
                        color: Color(hex: "00CED1"),
                        destination: AnyView(ChartView(symbol: "EURUSD"))
                    )
                    
                }
            }
        }
    }
    
    // MARK: - Performance Chart
    private var performanceChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance Trend")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 16) {
                    AITimeframeButton(label: "1W", isSelected: true)
                    AITimeframeButton(label: "1M", isSelected: false)
                    AITimeframeButton(label: "3M", isSelected: false)
                }
            }
            
            // Chart Container
            VStack {
                Chart {
                    ForEach(mockPerformanceData) { data in
                        LineMark(
                            x: .value("Day", data.day),
                            y: .value("Success", data.successRate)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "BD00FF"), Color(hex: "0080FF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Day", data.day),
                            y: .value("Success", data.successRate)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "BD00FF").opacity(0.1), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 180)
                .chartYScale(domain: 70...95)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.5))
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.5))
                            .font(.system(size: 10))
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.05))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
    
    // MARK: - Active Strategies
    private var activeStrategiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Strategies")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                NavigationLink(destination: PromptPerformanceView()) {
                    Text("View All")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "0080FF"))
                }
            }
            
            VStack(spacing: 12) {
                ActiveStrategyRow(
                    name: "EUR/USD Scalper",
                    status: .running,
                    profit: "+$342.50",
                    winRate: 85,
                    trades: 12
                )
                
                ActiveStrategyRow(
                    name: "Gold Trend Follower",
                    status: .analyzing,
                    profit: "+$128.00",
                    winRate: 78,
                    trades: 6
                )
                
                ActiveStrategyRow(
                    name: "Multi-Asset Portfolio",
                    status: .paused,
                    profit: "-$45.20",
                    winRate: 62,
                    trades: 8
                )
            }
        }
    }
    
    // MARK: - AI Insights
    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Insights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                AIInsightCard(
                    icon: "lightbulb.fill",
                    title: "Market Opportunity",
                    message: "Strong bullish momentum detected in GBPUSD. Consider long positions with 1.2850 as support.",
                    time: "2 min ago",
                    priority: .high
                )
                
                AIInsightCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Risk Alert",
                    message: "Increased volatility expected in crypto markets due to upcoming Fed announcement.",
                    time: "15 min ago",
                    priority: .medium
                )
                
                AIInsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Performance Update",
                    message: "Your AI strategies outperformed manual trades by 23% this week.",
                    time: "1 hour ago",
                    priority: .low
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct SubMetricView: View {
    let label: String
    let value: String
    let subtext: String
    let trend: TrendDirection
    
    enum TrendDirection {
        case up, down, neutral
        
        var color: Color {
            switch self {
            case .up: return Color(hex: "00FF88")
            case .down: return Color(hex: "FF3B30")
            case .neutral: return Color.white.opacity(0.6)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.5))
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(subtext)
                .font(.system(size: 11))
                .foregroundColor(trend.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AIQuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.5))
                        .lineLimit(1)
                }
            }
            .frame(width: 120)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AITimeframeButton: View {
    let label: String
    let isSelected: Bool
    
    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(hex: "0080FF").opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color(hex: "0080FF") : Color.clear, lineWidth: 1)
                    )
            )
    }
}

struct ActiveStrategyRow: View {
    let name: String
    let status: StrategyStatus
    let profit: String
    let winRate: Int
    let trades: Int
    
    enum StrategyStatus {
        case running, analyzing, paused
        
        var color: Color {
            switch self {
            case .running: return Color(hex: "00FF88")
            case .analyzing: return Color(hex: "0080FF")
            case .paused: return Color.orange
            }
        }
        
        var text: String {
            switch self {
            case .running: return "Running"
            case .analyzing: return "Analyzing"
            case .paused: return "Paused"
            }
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 6, height: 6)
                        
                        Text(status.text)
                            .font(.system(size: 11))
                            .foregroundColor(status.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(status.color.opacity(0.15))
                    )
                }
                
                HStack(spacing: 16) {
                    Label("\(trades) trades", systemImage: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                    
                    Label("\(winRate)% win", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            Text(profit)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(profit.hasPrefix("+") ? Color(hex: "00FF88") : Color(hex: "FF3B30"))
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

struct AIInsightCard: View {
    let icon: String
    let title: String
    let message: String
    let time: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return Color(hex: "FF3B30")
            case .medium: return Color(hex: "FF9500")
            case .low: return Color(hex: "0080FF")
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(priority.color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(time)
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(priority.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Mock Data

struct AIPerformanceData: Identifiable {
    let id = UUID()
    let day: String
    let successRate: Double
}

let mockPerformanceData = [
    AIPerformanceData(day: "Mon", successRate: 82),
    AIPerformanceData(day: "Tue", successRate: 85),
    AIPerformanceData(day: "Wed", successRate: 83),
    AIPerformanceData(day: "Thu", successRate: 88),
    AIPerformanceData(day: "Fri", successRate: 86),
    AIPerformanceData(day: "Sat", successRate: 89),
    AIPerformanceData(day: "Sun", successRate: 87.3)
]

// MARK: - AI Feature Model

struct AIFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
    let destination: AnyView
}

#Preview {
    ModernAIDashboard()
        .preferredColorScheme(.dark)
}