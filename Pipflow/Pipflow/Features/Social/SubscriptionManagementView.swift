//
//  SubscriptionManagementView.swift
//  Pipflow
//
//  Manage strategy subscriptions and copy settings
//

import SwiftUI

struct SubscriptionManagementView: View {
    @StateObject private var viewModel = SubscriptionManagementViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSubscription: StrategySubscription?
    @State private var showEditSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.subscriptions.isEmpty {
                    EmptyStateView(
                        icon: "doc.on.doc",
                        title: "No Active Subscriptions",
                        description: "Subscribe to strategies from the marketplace to start copy trading",
                        theme: themeManager.currentTheme
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Summary Card
                            SubscriptionSummaryCard(
                                subscriptions: viewModel.subscriptions,
                                theme: themeManager.currentTheme
                            )
                            
                            // Active Subscriptions
                            ForEach(viewModel.subscriptions) { subscription in
                                SubscriptionCard(
                                    subscription: subscription,
                                    strategy: viewModel.getStrategy(for: subscription),
                                    theme: themeManager.currentTheme,
                                    onEdit: {
                                        selectedSubscription = subscription
                                        showEditSettings = true
                                    },
                                    onPause: {
                                        viewModel.toggleSubscription(subscription)
                                    },
                                    onDelete: {
                                        viewModel.unsubscribe(subscription)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: MarketplaceView()) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .sheet(item: $selectedSubscription) { subscription in
            EditCopySettingsView(
                subscription: subscription,
                onSave: { updatedSettings in
                    viewModel.updateCopySettings(subscription, settings: updatedSettings)
                }
            )
            .environmentObject(themeManager)
        }
    }
}

// MARK: - Summary Card

struct SubscriptionSummaryCard: View {
    let subscriptions: [StrategySubscription]
    let theme: Theme
    
    var activeCount: Int {
        subscriptions.filter { $0.status == .active }.count
    }
    
    var totalReturn: Double {
        subscriptions.reduce(0) { $0 + $1.performance.totalReturn }
    }
    
    var totalProfit: Double {
        subscriptions.reduce(0) { $0 + $1.performance.totalProfit }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Portfolio Overview")
                .font(.headline)
                .foregroundColor(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                SubscriptionSummaryMetric(
                    title: "Active",
                    value: "\(activeCount)",
                    icon: "checkmark.circle",
                    color: .green,
                    theme: theme
                )
                
                SubscriptionSummaryMetric(
                    title: "Total Return",
                    value: String(format: "%.1f%%", totalReturn),
                    icon: "chart.line.uptrend.xyaxis",
                    color: totalReturn > 0 ? .green : .red,
                    theme: theme
                )
                
                SubscriptionSummaryMetric(
                    title: "Profit",
                    value: String(format: "$%.0f", totalProfit),
                    icon: "dollarsign.circle",
                    color: totalProfit > 0 ? .green : .red,
                    theme: theme
                )
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

struct SubscriptionSummaryMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.textColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Subscription Card

struct SubscriptionCard: View {
    let subscription: StrategySubscription
    let strategy: SharedStrategy?
    let theme: Theme
    let onEdit: () -> Void
    let onPause: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(strategy?.strategy.name ?? "Unknown Strategy")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    HStack(spacing: 8) {
                        SubscriptionStatusBadge(status: subscription.status, theme: theme)
                        
                        if let strategy = strategy {
                            Text("by \(strategy.authorName)")
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit Settings", systemImage: "slider.horizontal.3")
                    }
                    
                    Button(action: onPause) {
                        Label(
                            subscription.status == .active ? "Pause" : "Resume",
                            systemImage: subscription.status == .active ? "pause.circle" : "play.circle"
                        )
                    }
                    
                    Divider()
                    
                    Button(action: { showDeleteAlert = true }) {
                        Label("Unsubscribe", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            .padding()
            
            Divider()
                .background(theme.separatorColor)
            
            // Performance
            HStack(spacing: 20) {
                SubscriptionPerformanceMetric(
                    label: "Return",
                    value: String(format: "%.1f%%", subscription.performance.totalReturn),
                    isPositive: subscription.performance.totalReturn > 0,
                    theme: theme
                )
                
                SubscriptionPerformanceMetric(
                    label: "Trades Copied",
                    value: "\(subscription.performance.copiedTrades)",
                    isPositive: true,
                    theme: theme
                )
                
                SubscriptionPerformanceMetric(
                    label: "Success Rate",
                    value: String(format: "%.0f%%", 
                        subscription.performance.copiedTrades > 0 
                            ? Double(subscription.performance.successfulTrades) / Double(subscription.performance.copiedTrades) * 100 
                            : 0
                    ),
                    isPositive: true,
                    theme: theme
                )
            }
            .padding()
            
            Divider()
                .background(theme.separatorColor)
            
            // Copy Settings Summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Copy Settings")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                HStack(spacing: 16) {
                    CopySettingItem(
                        label: "Scale",
                        value: String(format: "%.1fx", subscription.copySettings.scalingFactor),
                        theme: theme
                    )
                    
                    CopySettingItem(
                        label: "Max Positions",
                        value: "\(subscription.copySettings.maxPositions)",
                        theme: theme
                    )
                    
                    if let maxDrawdown = subscription.copySettings.stopCopyingOnDrawdown {
                        CopySettingItem(
                            label: "Stop Loss",
                            value: String(format: "%.0f%%", maxDrawdown * 100),
                            theme: theme
                        )
                    }
                    
                    if subscription.copySettings.reverseTrading {
                        CopySettingItem(
                            label: "Mode",
                            value: "Reverse",
                            theme: theme
                        )
                    }
                }
            }
            .padding()
        }
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
        .alert("Unsubscribe", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unsubscribe", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to unsubscribe from this strategy? This action cannot be undone.")
        }
    }
}

struct SubscriptionStatusBadge: View {
    let status: SubscriptionStatus
    let theme: Theme
    
    var statusColor: Color {
        switch status {
        case .active: return .green
        case .paused: return .orange
        case .cancelled: return .red
        case .trial: return .blue
        }
    }
    
    var statusText: String {
        switch status {
        case .active: return "Active"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        case .trial: return "Trial"
        }
    }
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }
}

struct SubscriptionPerformanceMetric: View {
    let label: String
    let value: String
    let isPositive: Bool
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isPositive ? theme.textColor : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CopySettingItem: View {
    let label: String
    let value: String
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryTextColor)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.textColor)
        }
    }
}

// MARK: - View Model

@MainActor
class SubscriptionManagementViewModel: ObservableObject {
    @Published var subscriptions: [StrategySubscription] = []
    
    private let socialService = SocialTradingServiceV2.shared
    
    init() {
        loadSubscriptions()
    }
    
    func loadSubscriptions() {
        subscriptions = socialService.subscriptions
    }
    
    func getStrategy(for subscription: StrategySubscription) -> SharedStrategy? {
        return socialService.marketplace.first { $0.strategyId == subscription.strategyId } as? SharedStrategy
    }
    
    func toggleSubscription(_ subscription: StrategySubscription) {
        if subscription.status == .active {
            socialService.pauseSubscription(subscription.id)
        } else {
            socialService.resumeSubscription(subscription.id)
        }
        loadSubscriptions()
    }
    
    func unsubscribe(_ subscription: StrategySubscription) {
        socialService.unsubscribeFromStrategy(subscription.id)
        loadSubscriptions()
    }
    
    func updateCopySettings(_ subscription: StrategySubscription, settings: CopySettings) {
        // Update copy settings
        // In real implementation, would update the subscription with new settings
        loadSubscriptions()
    }
}