//
//  FuturisticDashboardView.swift
//  Pipflow
//
//  Next-Generation AI Trading Interface
//

import SwiftUI
import Charts

struct FuturisticDashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedMetric = 0
    @State private var showAICommand = false
    @State private var rotationAngle = 0.0
    @State private var pulseAnimation = false
    @State private var dataStreamAnimation = false
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            // Neural Network Background
            NeuralNetworkBackground()
                .opacity(0.3)
            
            // Main Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Holographic Header
                    holographicHeader
                    
                    // AI Command Center
                    aiCommandCenter
                    
                    // Quantum Portfolio Display
                    quantumPortfolioCard
                    
                    // Live Data Stream
                    liveDataStream
                    
                    // Holographic Chart
                    holographicChart
                    
                    // Trading Matrix
                    tradingMatrix
                    
                    // Neural Insights
                    neuralInsights
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            
            // Floating AI Assistant
            floatingAIAssistant
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Holographic Header
    
    var holographicHeader: some View {
        ZStack {
            // Background effect
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: [Color.neonCyan, Color.electricBlue, Color.neonPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .holographicShimmer()
            
            VStack(spacing: 20) {
                // User Greeting with typing animation
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundColor(.neonCyan)
                        .neonGlow()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Neural Trading System Active")
                            .font(.caption)
                            .foregroundColor(.neonCyan)
                        
                        Text("Welcome back, Commander")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Holographic Profile
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.neonCyan, .electricBlue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(rotationAngle))
                        
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                
                // System Status
                HStack(spacing: 20) {
                    StatusIndicator(
                        label: "AI Engine",
                        status: "OPTIMAL",
                        color: .plasmaGreen
                    )
                    
                    StatusIndicator(
                        label: "Market Scan",
                        status: "ACTIVE",
                        color: .neonCyan
                    )
                    
                    StatusIndicator(
                        label: "Risk Shield",
                        status: "ARMED",
                        color: .electricBlue
                    )
                }
            }
            .padding(24)
        }
        .frame(height: 180)
    }
    
    // MARK: - AI Command Center
    
    var aiCommandCenter: some View {
        HolographicCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(.neonPurple)
                        .neonGlow(color: .neonPurple)
                    
                    Text("AI Command Center")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    PulsingDot(color: .plasmaGreen)
                }
                
                Text("\"Show me high probability trades for today\"")
                    .font(.subheadline)
                    .foregroundColor(.neonCyan)
                    .italic()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.neonCyan.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neonCyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                
                HStack(spacing: 12) {
                    CommandChip(title: "Scan Markets", icon: "radar")
                    CommandChip(title: "Risk Analysis", icon: "shield.lefthalf.filled")
                    CommandChip(title: "AI Predict", icon: "brain")
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Quantum Portfolio Card
    
    var quantumPortfolioCard: some View {
        HolographicCard {
            VStack(spacing: 24) {
                // Portfolio Value with animation
                VStack(spacing: 8) {
                    Text("Quantum Portfolio Value")
                        .font(.subheadline)
                        .foregroundColor(.neonCyan)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        AnimatedNumberComponent(
                            value: 158749.32,
                            format: "%.2f"
                        )
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.neonCyan, .electricBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .neonGlow(color: .neonCyan, radius: 5)
                    }
                    
                    // Profit indicator
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .foregroundColor(.plasmaGreen)
                        
                        Text("+$2,847.50")
                            .font(.headline)
                            .foregroundColor(.plasmaGreen)
                        
                        Text("+1.83%")
                            .font(.subheadline)
                            .foregroundColor(.plasmaGreen.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.plasmaGreen.opacity(0.2))
                            )
                    }
                }
                
                // Quantum Metrics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    QuantumMetric(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Win Rate",
                        value: "73.5%",
                        trend: .up,
                        color: .plasmaGreen
                    )
                    
                    QuantumMetric(
                        icon: "bolt.circle",
                        title: "Active Trades",
                        value: "8",
                        trend: .neutral,
                        color: .electricBlue
                    )
                    
                    QuantumMetric(
                        icon: "shield.checkered",
                        title: "Risk Score",
                        value: "Low",
                        trend: .down,
                        color: .neonCyan
                    )
                    
                    QuantumMetric(
                        icon: "cpu",
                        title: "AI Confidence",
                        value: "92%",
                        trend: .up,
                        color: .neonPurple
                    )
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Live Data Stream
    
    var liveDataStream: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Live Data Stream", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                LiveIndicator()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(["EUR/USD", "BTC/USD", "AAPL", "GOLD"], id: \.self) { symbol in
                        DataStreamCard(
                            symbol: symbol,
                            price: Double.random(in: 1000...50000),
                            change: Double.random(in: -5...5)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Holographic Chart
    
    var holographicChart: some View {
        HolographicCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Neural Pattern Recognition")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Time selector with animation
                    FuturisticTimeframePicker(selection: .constant("1D"))
                }
                
                // 3D-style chart
                ZStack {
                    // Grid background
                    FuturisticEffects.circuitPattern()
                        .opacity(0.3)
                    
                    // Chart
                    Chart(viewModel.chartData) { dataPoint in
                        AreaMark(
                            x: .value("Time", dataPoint.time),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.neonCyan.opacity(0.6),
                                    Color.electricBlue.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        LineMark(
                            x: .value("Time", dataPoint.time),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(Color.neonCyan)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .shadow(color: .neonCyan, radius: 5)
                    }
                    .frame(height: 250)
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
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Trading Matrix
    
    var tradingMatrix: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Trading Matrix", systemImage: "square.grid.3x3")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Real-time")
                    .font(.caption)
                    .foregroundColor(.plasmaGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.plasmaGreen.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.plasmaGreen.opacity(0.5), lineWidth: 1)
                            )
                    )
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    MatrixCell(
                        symbol: ["EUR/USD", "GBP/USD", "USD/JPY", "BTC/USD", "ETH/USD", "XAU/USD"][index],
                        trend: Bool.random() ? .up : .down
                    )
                }
            }
        }
    }
    
    // MARK: - Neural Insights
    
    var neuralInsights: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Neural Network Insights", systemImage: "brain")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(.neonPurple)
                    .neonGlow(color: .neonPurple, radius: 5)
            }
            
            VStack(spacing: 12) {
                NeuralInsightCard(
                    type: .opportunity,
                    title: "High Probability Setup Detected",
                    description: "EUR/USD showing convergence pattern with 87% success rate",
                    action: "Execute Trade"
                )
                
                NeuralInsightCard(
                    type: .warning,
                    title: "Risk Alert: Market Volatility",
                    description: "Unusual volume spike detected in crypto markets",
                    action: "View Analysis"
                )
                
                NeuralInsightCard(
                    type: .prediction,
                    title: "AI Prediction: Gold Rally",
                    description: "Neural network predicts 3.2% upside in next 48 hours",
                    action: "Set Alert"
                )
            }
        }
    }
    
    // MARK: - Floating AI Assistant
    
    var floatingAIAssistant: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: { showAICommand.toggle() }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.neonPurple, .electricBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .neonGlow(color: .neonPurple, radius: 15)
                        
                        Image(systemName: "brain")
                            .font(.title2)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(pulseAnimation ? 5 : -5))
                    }
                }
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: false)) {
            dataStreamAnimation = true
        }
    }
}

// MARK: - Supporting Components

struct StatusIndicator: View {
    let label: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .blur(radius: 4)
                    )
                
                Text(status)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

struct PulsingDot: View {
    let color: Color
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(scale)
                    .opacity(2 - scale)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1).repeatForever(autoreverses: false)) {
                    scale = 2
                }
            }
    }
}

struct CommandChip: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct QuantumMetric: View {
    let icon: String
    let title: String
    let value: String
    let trend: Trend
    let color: Color
    
    enum Trend {
        case up, down, neutral
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 4) {
                    Text(value)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if trend != .neutral {
                        Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                            .foregroundColor(trend == .up ? .plasmaGreen : .red)
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct LiveIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.plasmaGreen)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(Color.plasmaGreen, lineWidth: 1)
                        .scaleEffect(isAnimating ? 2 : 1)
                        .opacity(isAnimating ? 0 : 1)
                )
            
            Text("LIVE")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.plasmaGreen)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct DataStreamCard: View {
    let symbol: String
    let price: Double
    let change: Double
    @State private var isFlashing = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(symbol)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
            
            Text(String(format: "$%.2f", price))
                .font(.headline)
                .foregroundColor(.white)
                .monospacedDigit()
            
            HStack(spacing: 4) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2)
                
                Text(String(format: "%.2f%%", abs(change)))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(change >= 0 ? .plasmaGreen : .red)
        }
        .frame(width: 100)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            change >= 0 ? Color.plasmaGreen.opacity(0.5) : Color.red.opacity(0.5),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isFlashing ? 1.05 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                isFlashing = true
            }
        }
    }
}

struct FuturisticTimeframePicker: View {
    @Binding var selection: String
    let timeframes = ["1M", "5M", "15M", "1H", "4H", "1D", "1W"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(["1H", "4H", "1D"], id: \.self) { timeframe in
                Button(action: { selection = timeframe }) {
                    Text(timeframe)
                        .font(.caption)
                        .fontWeight(selection == timeframe ? .bold : .medium)
                        .foregroundColor(selection == timeframe ? .black : .white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selection == timeframe ?
                            AnyView(
                                Capsule()
                                    .fill(Color.neonCyan)
                            ) :
                            AnyView(Color.clear)
                        )
                }
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct MatrixCell: View {
    let symbol: String
    let trend: Trend
    @State private var isHovering = false
    
    enum Trend {
        case up, down
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(symbol)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Image(systemName: trend == .up ? "arrow.up.right.square.fill" : "arrow.down.right.square.fill")
                .font(.title2)
                .foregroundColor(trend == .up ? .plasmaGreen : .red)
                .symbolEffect(.pulse, value: isHovering)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            trend == .up ? Color.plasmaGreen.opacity(0.3) : Color.red.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
    }
}

struct NeuralInsightCard: View {
    let type: InsightType
    let title: String
    let description: String
    let action: String
    
    enum InsightType {
        case opportunity, warning, prediction
        
        var color: Color {
            switch self {
            case .opportunity: return .plasmaGreen
            case .warning: return .neonPink
            case .prediction: return .electricBlue
            }
        }
        
        var icon: String {
            switch self {
            case .opportunity: return "star.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .prediction: return "waveform.path.ecg"
            }
        }
    }
    
    var body: some View {
        HolographicCard {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: type.icon)
                    .font(.title)
                    .foregroundColor(type.color)
                    .neonGlow(color: type.color, radius: 10)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Action Button
                QuantumButton(title: action, action: {})
                    .frame(width: 120)
            }
            .padding(20)
        }
    }
}

// MARK: - Preview

#Preview {
    FuturisticDashboardView()
}