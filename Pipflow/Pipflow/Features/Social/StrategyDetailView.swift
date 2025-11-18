//
//  StrategyDetailView.swift
//  Pipflow
//
//  Detailed view for a shared strategy
//

import SwiftUI
import Charts

struct StrategyDetailView: View {
    let strategy: SharedStrategy
    @StateObject private var viewModel = StrategyDetailViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showSubscribeSheet = false
    @State private var showReviewSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        StrategyDetailHeader(
                            strategy: strategy,
                            theme: themeManager.currentTheme,
                            onSubscribe: { showSubscribeSheet = true },
                            onFollow: { viewModel.toggleFollow(strategy.authorId) },
                            isFollowing: viewModel.isFollowing
                        )
                        
                        // Performance Overview
                        StrategyPerformanceOverviewCard(
                            performance: strategy.performance,
                            theme: themeManager.currentTheme
                        )
                        
                        // Tab Selection
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                DetailTab(title: "Overview", isSelected: selectedTab == 0) {
                                    selectedTab = 0
                                }
                                DetailTab(title: "Performance", isSelected: selectedTab == 1) {
                                    selectedTab = 1
                                }
                                DetailTab(title: "Reviews", isSelected: selectedTab == 2) {
                                    selectedTab = 2
                                }
                                DetailTab(title: "Settings", isSelected: selectedTab == 3) {
                                    selectedTab = 3
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Tab Content
                        switch selectedTab {
                        case 0:
                            StrategyOverviewTab(
                                strategy: strategy,
                                theme: themeManager.currentTheme
                            )
                        case 1:
                            StrategyPerformanceTab(
                                strategy: strategy,
                                theme: themeManager.currentTheme
                            )
                        case 2:
                            StrategyReviewsTab(
                                strategy: strategy,
                                theme: themeManager.currentTheme,
                                onAddReview: { showReviewSheet = true }
                            )
                        case 3:
                            StrategySettingsTab(
                                strategy: strategy,
                                theme: themeManager.currentTheme
                            )
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(strategy.strategy.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: viewModel.shareStrategy) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { viewModel.reportStrategy(strategy.id.uuidString) }) {
                            Label("Report", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showSubscribeSheet) {
            SubscribeToStrategyView(strategy: strategy)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showReviewSheet) {
            AddReviewView(strategy: strategy)
                .environmentObject(themeManager)
        }
        .onAppear {
            viewModel.loadStrategy(strategy)
        }
    }
}

// MARK: - Header

struct StrategyDetailHeader: View {
    let strategy: SharedStrategy
    let theme: Theme
    let onSubscribe: () -> Void
    let onFollow: () -> Void
    let isFollowing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Author Info
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: strategy.authorImage ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(theme.accentColor)
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(strategy.authorName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.textColor)
                        
                        if strategy.rating > 4.0 {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(theme.accentColor)
                        }
                    }
                    
                    Text("\(strategy.subscribers) subscribers")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                Button(action: onFollow) {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isFollowing ? theme.textColor : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isFollowing ? theme.secondaryBackgroundColor : theme.accentColor)
                        .cornerRadius(20)
                }
            }
            
            // Description
            Text(strategy.strategy.description)
                .font(.system(size: 14))
                .foregroundColor(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(strategy.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(theme.accentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.accentColor.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            
            // Subscribe Button
            Button(action: onSubscribe) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Subscribe to Strategy")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [theme.accentColor, theme.accentColor.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Performance Overview

struct StrategyPerformanceOverviewCard: View {
    let performance: TradingStrategyPerformance
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Performance Overview")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StrategyMetricCard(
                    title: "Total Return",
                    value: String(format: "%.1f%%", performance.totalReturn),
                    icon: "chart.line.uptrend.xyaxis",
                    color: performance.totalReturn > 0 ? .green : .red,
                    theme: theme
                )
                
                StrategyMetricCard(
                    title: "Win Rate",
                    value: String(format: "%.0f%%", performance.winRate * 100),
                    icon: "checkmark.circle",
                    color: .green,
                    theme: theme
                )
                
                StrategyMetricCard(
                    title: "Sharpe Ratio",
                    value: String(format: "%.2f", performance.sharpeRatio),
                    icon: "chart.bar",
                    color: theme.accentColor,
                    theme: theme
                )
                
                StrategyMetricCard(
                    title: "Max Drawdown",
                    value: String(format: "%.1f%%", performance.maxDrawdown * 100),
                    icon: "arrow.down",
                    color: .red,
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct StrategyMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding()
        .background(theme.backgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Tab Components

struct DetailTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(height: 2)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
    }
}

// MARK: - Overview Tab

struct StrategyOverviewTab: View {
    let strategy: SharedStrategy
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 16) {
            // Strategy Details
            StrategyDetailsCard(
                strategy: strategy.strategy,
                theme: theme
            )
            
            // Risk Profile
            RiskProfileCard(
                performance: strategy.performance,
                theme: theme
            )
            
            // Trading Activity
            TradingActivityCard(
                performance: strategy.performance,
                theme: theme
            )
        }
        .padding(.horizontal)
    }
}

struct StrategyDetailsCard: View {
    let strategy: TradingStrategy
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strategy Details")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            StrategyDetailRow(label: "Timeframe", value: strategy.timeframe.rawValue, theme: theme)
            StrategyDetailRow(label: "Max Open Trades", value: "\(strategy.riskManagement.maxOpenTrades)", theme: theme)
            StrategyDetailRow(label: "Stop Loss", value: "\(strategy.riskManagement.stopLossPercent)%", theme: theme)
            StrategyDetailRow(label: "Take Profit", value: "\(strategy.riskManagement.takeProfitPercent)%", theme: theme)
            StrategyDetailRow(label: "Position Size", value: "\(strategy.riskManagement.positionSizePercent)%", theme: theme)
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct StrategyDetailRow: View {
    let label: String
    let value: String
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textColor)
        }
    }
}

// MARK: - View Model

@MainActor
class StrategyDetailViewModel: ObservableObject {
    @Published var isFollowing = false
    @Published var performanceData: [PerformancePoint] = []
    
    private let socialService = SocialTradingServiceV2.shared
    
    func loadStrategy(_ strategy: SharedStrategy) {
        // Check if following
        isFollowing = socialService.followedAuthors.contains(strategy.authorId)
        
        // Load performance data
        generatePerformanceData()
    }
    
    func toggleFollow(_ authorId: String) {
        if isFollowing {
            socialService.unfollowAuthor(authorId)
        } else {
            socialService.followAuthor(authorId)
        }
        isFollowing.toggle()
    }
    
    func shareStrategy() {
        // Share functionality
    }
    
    func reportStrategy(_ strategyId: String) {
        // Report functionality
    }
    
    private func generatePerformanceData() {
        // Generate demo performance data
        performanceData = (0..<30).map { day in
            PerformancePoint(
                date: Date().addingTimeInterval(-Double(29 - day) * 24 * 3600),
                value: 10000 + Double.random(in: -500...1000) * Double(day) / 10
            )
        }
    }
}

struct PerformancePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// Additional cards for other tabs...

// MARK: - Performance Tab

struct StrategyPerformanceTab: View {
    let strategy: SharedStrategy
    let theme: Theme
    @StateObject private var viewModel = PerformanceTabViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // Performance Chart
            StrategyPerformanceChartCard(
                data: viewModel.performanceData,
                theme: theme
            )
            
            // Key Metrics
            KeyMetricsCard(
                performance: strategy.performance,
                theme: theme
            )
            
            // Monthly Breakdown
            MonthlyBreakdownCard(
                months: viewModel.monthlyData,
                theme: theme
            )
        }
        .padding(.horizontal)
        .onAppear {
            viewModel.loadPerformanceData(for: strategy)
        }
    }
}

struct StrategyPerformanceChartCard: View {
    let data: [PerformancePoint]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Chart")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            // Simple line representation
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundColor)
                    .frame(height: 200)
                
                Text("Chart View")
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct KeyMetricsCard: View {
    let performance: TradingStrategyPerformance
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StrategyMetricItem(title: "Total Trades", value: "\(performance.totalTrades)", theme: theme)
                StrategyMetricItem(title: "Profit Factor", value: String(format: "%.2f", performance.profitFactor), theme: theme)
                StrategyMetricItem(title: "Avg Hold Time", value: formatTime(performance.averageHoldTime), theme: theme)
                StrategyMetricItem(title: "Win Rate", value: String(format: "%.0f%%", performance.winRate * 100), theme: theme)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        return hours < 24 ? "\(hours)h" : "\(hours/24)d"
    }
}

struct StrategyMetricItem: View {
    let title: String
    let value: String
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MonthlyBreakdownCard: View {
    let months: [MonthlyPerformance]
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Breakdown")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            ForEach(months) { month in
                HStack {
                    Text(month.name)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", month.returnPercentage))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(month.returnPercentage > 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Reviews Tab

struct StrategyReviewsTab: View {
    let strategy: SharedStrategy
    let theme: Theme
    let onAddReview: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Rating Summary
            RatingSummaryCard(
                rating: strategy.rating,
                reviewCount: strategy.reviews,
                theme: theme
            )
            
            // Add Review Button
            Button(action: onAddReview) {
                HStack {
                    Image(systemName: "star")
                    Text("Write a Review")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.accentColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(theme.secondaryBackgroundColor)
                .cornerRadius(12)
            }
            
            // Reviews List
            if strategy.reviews == 0 {
                Text("No reviews yet")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .padding(.vertical, 20)
            } else {
                Text("\\(strategy.reviews) reviews")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                    .padding(.vertical, 20)
            }
        }
        .padding(.horizontal)
    }
}

struct RatingSummaryCard: View {
    let rating: Double
    let reviewCount: Int
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(format: "%.1f", rating))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(theme.textColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text("\(reviewCount) reviews")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct ReviewCard: View {
    let review: StrategyReview
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(review.reviewerName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textColor)
                
                if review.verified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(theme.accentColor)
                }
                
                Spacer()
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Text(review.comment)
                .font(.system(size: 14))
                .foregroundColor(theme.textColor)
            
            HStack {
                Text(formatDate(review.timestamp))
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup")
                        Text("\(review.helpful)")
                    }
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(theme.backgroundColor)
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Settings Tab

struct StrategySettingsTab: View {
    let strategy: SharedStrategy
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Strategy Parameters
            StrategyParametersCard(
                strategy: strategy.strategy,
                theme: theme
            )
            
            // Trading Hours
            StrategyTradingHoursCard(theme: theme)
            
            // Risk Limits
            StrategyRiskLimitsCard(
                strategy: strategy.strategy,
                theme: theme
            )
        }
        .padding(.horizontal)
    }
}

struct StrategyParametersCard: View {
    let strategy: TradingStrategy
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strategy Parameters")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            StrategyDetailRow(label: "Timeframe", value: strategy.timeframe.rawValue, theme: theme)
            StrategyDetailRow(label: "Entry Conditions", value: "\(strategy.conditions.count) rules", theme: theme)
            StrategyDetailRow(label: "Risk per Trade", value: "\(strategy.riskManagement.positionSizePercent)%", theme: theme)
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct StrategyTradingHoursCard: View {
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trading Hours")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            Text("24/5 - All Forex Sessions")
                .font(.system(size: 14))
                .foregroundColor(theme.textColor)
            
            Text("Strategy operates during all major trading sessions")
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct StrategyRiskLimitsCard: View {
    let strategy: TradingStrategy
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Limits")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            StrategyDetailRow(label: "Max Daily Loss", value: "5%", theme: theme)
            StrategyDetailRow(label: "Max Weekly Loss", value: "10%", theme: theme)
            StrategyDetailRow(label: "Max Monthly Loss", value: "20%", theme: theme)
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

// MARK: - Supporting View Models

@MainActor
class PerformanceTabViewModel: ObservableObject {
    @Published var performanceData: [PerformancePoint] = []
    @Published var monthlyData: [MonthlyPerformance] = []
    
    func loadPerformanceData(for strategy: SharedStrategy) {
        // Generate demo data
        performanceData = (0..<30).map { day in
            PerformancePoint(
                date: Date().addingTimeInterval(-Double(29 - day) * 24 * 3600),
                value: 10000 + strategy.performance.totalReturn * 100 * Double(day) / 30
            )
        }
        
        monthlyData = [
            MonthlyPerformance(id: UUID(), name: "January", returnPercentage: 12.5),
            MonthlyPerformance(id: UUID(), name: "February", returnPercentage: 8.3),
            MonthlyPerformance(id: UUID(), name: "March", returnPercentage: 15.7)
        ]
    }
}

struct MonthlyPerformance: Identifiable {
    let id: UUID
    let name: String
    let returnPercentage: Double
}

// MARK: - Risk Profile Card

struct RiskProfileCard: View {
    let performance: TradingStrategyPerformance
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Profile")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Max Drawdown")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    Spacer()
                    Text("\(performance.maxDrawdown, specifier: "%.1f")%")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(performance.maxDrawdown > -20 ? .green : .red)
                }
                
                HStack {
                    Text("Sharpe Ratio")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                    Spacer()
                    Text("\(performance.sharpeRatio, specifier: "%.2f")")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(performance.sharpeRatio > 1 ? .green : .orange)
                }
            }
            
            Text("Average Hold Time: \(Int(performance.averageHoldTime / 3600)) hours")
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}


struct TradingActivityCard: View {
    let performance: TradingStrategyPerformance
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trading Activity")
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            StrategyDetailRow(label: "Total Trades", value: "\(performance.totalTrades)", theme: theme)
            StrategyDetailRow(label: "Profit Factor", value: String(format: "%.2f", performance.profitFactor), theme: theme)
            StrategyDetailRow(label: "Avg Hold Time", value: formatTimeInterval(performance.averageHoldTime), theme: theme)
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        if hours < 24 {
            return "\(hours)h"
        } else {
            return "\(hours / 24)d"
        }
    }
}

// MARK: - Add Review View

struct AddReviewView: View {
    let strategy: SharedStrategy
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var rating = 5
    @State private var comment = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Your Rating") {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { rating = star }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Your Review") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 100)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Strategy: \(strategy.strategy.name)")
                            .font(.caption)
                        Text("Author: \(strategy.authorName)")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitReview()
                        dismiss()
                    }
                    .disabled(comment.isEmpty)
                }
            }
        }
    }
    
    private func submitReview() {
        SocialTradingServiceV2.shared.rateStrategy(
            strategy.id.uuidString,
            rating: rating,
            comment: comment
        )
    }
}