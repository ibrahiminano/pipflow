//
//  AIDashboard.swift
//  Pipflow
//
//  AI Dashboard - Central hub for all AI features
//

import SwiftUI

struct AIDashboard: View {
    var body: some View {
        ModernAIDashboard()
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.neonPurple, .electricBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Intelligent Trading at Your Fingertips")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - AI Stats Section
    private var aiStatsSection: some View {
        HStack(spacing: 16) {
            AIStatCard(
                icon: "brain",
                title: "AI Accuracy",
                value: "87.3%",
                trend: "+2.1%",
                color: .neonPurple
            )
            
            AIStatCard(
                icon: "bolt.circle.fill",
                title: "Signals Today",
                value: "24",
                trend: "18 profitable",
                color: .plasmaGreen
            )
        }
    }
    
    // MARK: - AI Features Grid
    private var aiFeaturesGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Features")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                AIFeatureCard(
                    icon: "waveform.path.ecg",
                    title: "AI Signals",
                    description: "Real-time market signals",
                    color: .neonCyan,
                    destination: AnyView(GenerateSignalView())
                )
                
                AIFeatureCard(
                    icon: "hammer.fill",
                    title: "Prompt Builder",
                    description: "Create AI strategies",
                    color: .electricBlue,
                    destination: AnyView(PromptBuilderView())
                )
                
                AIFeatureCard(
                    icon: "play.circle.fill",
                    title: "AI Auto-Trading",
                    description: "Automated execution",
                    color: .plasmaGreen,
                    destination: AnyView(AIAutoTradingView())
                )
                
                AIFeatureCard(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Strategy Builder",
                    description: "Visual strategy design",
                    color: .neonPink,
                    destination: AnyView(StrategyBuilderView())
                )
                
                AIFeatureCard(
                    icon: "clock.arrow.2.circlepath",
                    title: "Backtesting",
                    description: "Test your strategies",
                    color: .neonPurple,
                    destination: AnyView(BacktestingView())
                )
                
                AIFeatureCard(
                    icon: "sparkles",
                    title: "AI Optimization",
                    description: "Enhance performance",
                    color: .electricBlue,
                    destination: AnyView(StrategyOptimizationView())
                )
            }
        }
    }
    
    // MARK: - Active Operations Section
    private var activeOperationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active AI Operations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Circle()
                    .fill(Color.plasmaGreen)
                    .frame(width: 6, height: 6)
                
                Text("Running")
                    .font(.caption2)
                    .foregroundColor(.plasmaGreen)
            }
            
            VStack(spacing: 12) {
                ActiveOperationRow(
                    title: "EUR/USD Signal Monitor",
                    status: "Analyzing",
                    progress: 0.7,
                    color: .neonCyan
                )
                
                ActiveOperationRow(
                    title: "Portfolio Optimization",
                    status: "Processing",
                    progress: 0.45,
                    color: .electricBlue
                )
                
                ActiveOperationRow(
                    title: "Risk Analysis",
                    status: "Calculating",
                    progress: 0.85,
                    color: .neonPurple
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
    
    // MARK: - Performance Metrics
    private var performanceMetricsSection: some View {
        HolographicCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI Performance Metrics")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    AIMetricItem(
                        label: "Signal Success",
                        value: "82%",
                        icon: "checkmark.circle.fill",
                        color: .plasmaGreen
                    )
                    
                    AIMetricItem(
                        label: "Avg. Return",
                        value: "+4.2%",
                        icon: "arrow.up.right.circle.fill",
                        color: .neonCyan
                    )
                    
                    AIMetricItem(
                        label: "Risk Score",
                        value: "Low",
                        icon: "shield.fill",
                        color: .electricBlue
                    )
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Supporting Views

struct AIStatCard: View {
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

struct AIFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let destination: AnyView
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                    .neonGlow(color: color, radius: 3)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                HolographicCard {
                    Color.clear
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActiveOperationRow: View {
    let title: String
    let status: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct AIMetricItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AIDashboard()
        .preferredColorScheme(.dark)
}