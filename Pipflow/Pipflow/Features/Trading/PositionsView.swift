//
//  PositionsView.swift
//  Pipflow
//
//  Real-time positions dashboard with live P&L tracking
//

import SwiftUI
import Combine

struct PositionsView: View {
    @StateObject private var trackingService = PositionTrackingService.shared
    @StateObject private var webSocketService = MetaAPIWebSocketService.shared
    @State private var selectedFilter: PositionFilter = .all
    @State private var showingPositionDetail: TrackedPosition?
    @State private var animateValues = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.Theme.background
                    .ignoresSafeArea()
                
                if trackingService.trackedPositions.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary Card
                            PositionSummaryCard()
                                .padding(.horizontal)
                            
                            // Filter Tabs
                            filterTabs
                            
                            // Positions List
                            positionsList
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Positions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    connectionStatusView
                }
            }
            .sheet(item: $showingPositionDetail) { position in
                PositionDetailView(position: position)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateValues = true
            }
        }
    }
    
    // MARK: - Components
    
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(Color.Theme.secondaryText.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Open Positions")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.Theme.text)
                
                Text("Your active trades will appear here")
                    .font(.body)
                    .foregroundColor(Color.Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PositionFilter.allCases, id: \.self) { filter in
                    FilterTab(
                        title: filter.title,
                        count: countForFilter(filter),
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    var positionsList: some View {
        VStack(spacing: 12) {
            ForEach(filteredPositions) { position in
                EnhancedPositionRow(position: position, animateValues: animateValues)
                    .onTapGesture {
                        showingPositionDetail = position
                    }
            }
        }
        .padding(.horizontal)
    }
    
    var connectionStatusView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(webSocketService.connectionState == .connected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(webSocketService.connectionState == .connected ? "Live" : "Offline")
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.Theme.cardBackground)
        .cornerRadius(20)
    }
    
    // MARK: - Helpers
    
    var filteredPositions: [TrackedPosition] {
        switch selectedFilter {
        case .all:
            return trackingService.trackedPositions
        case .profitable:
            return trackingService.trackedPositions.filter { $0.netPL > 0 }
        case .losing:
            return trackingService.trackedPositions.filter { $0.netPL < 0 }
        case .buy:
            return trackingService.trackedPositions.filter { $0.type == .buy }
        case .sell:
            return trackingService.trackedPositions.filter { $0.type == .sell }
        }
    }
    
    func countForFilter(_ filter: PositionFilter) -> Int {
        switch filter {
        case .all:
            return trackingService.trackedPositions.count
        case .profitable:
            return trackingService.trackedPositions.filter { $0.netPL > 0 }.count
        case .losing:
            return trackingService.trackedPositions.filter { $0.netPL < 0 }.count
        case .buy:
            return trackingService.trackedPositions.filter { $0.type == .buy }.count
        case .sell:
            return trackingService.trackedPositions.filter { $0.type == .sell }.count
        }
    }
}

// MARK: - Position Filter

enum PositionFilter: String, CaseIterable {
    case all = "All"
    case profitable = "Profit"
    case losing = "Loss"
    case buy = "Buy"
    case sell = "Sell"
    
    var title: String {
        rawValue
    }
}

// MARK: - Filter Tab

struct FilterTab: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.black.opacity(0.2) : Color.white.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? Color.Theme.accent : Color.Theme.text)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.Theme.accent.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.Theme.accent : Color.Theme.secondaryText.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Enhanced Position Row

struct EnhancedPositionRow: View {
    let position: TrackedPosition
    let animateValues: Bool
    @State private var previousPL: Double = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // Symbol and Type
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(position.symbol)
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.Theme.text)
                    
                    TypeBadge(type: position.type)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Vol:")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                        Text(String(format: "%.2f", position.volume))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.Theme.text)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Open:")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                        Text(String(format: "%.5f", position.openPrice))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.Theme.text)
                    }
                }
            }
            
            Spacer()
            
            // P&L and Pips
            VStack(alignment: .trailing, spacing: 4) {
                // P&L with animation
                HStack(spacing: 4) {
                    if position.netPL != previousPL && animateValues {
                        Image(systemName: position.netPL > previousPL ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10))
                            .foregroundColor(position.netPL > previousPL ? Color.Theme.success : Color.Theme.error)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Text(formatCurrency(position.netPL))
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(position.netPL >= 0 ? Color.Theme.success : Color.Theme.error)
                        .animation(.easeInOut(duration: 0.3), value: position.netPL)
                }
                
                HStack(spacing: 8) {
                    // Percentage
                    Text(String(format: "%.2f%%", position.unrealizedPLPercent))
                        .font(.caption)
                        .foregroundColor(position.netPL >= 0 ? Color.Theme.success : Color.Theme.error)
                    
                    // Pips
                    HStack(spacing: 2) {
                        Text(String(format: "%.1f", abs(position.pipsProfit)))
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("pips")
                            .font(.caption)
                    }
                    .foregroundColor(Color.Theme.secondaryText)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.Theme.secondaryText.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            previousPL = position.netPL
        }
        .onChange(of: position.netPL) { oldValue, newValue in
            previousPL = oldValue
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Type Badge

struct TypeBadge: View {
    let type: TrackedPosition.PositionType
    
    var body: some View {
        Text(type == .buy ? "BUY" : "SELL")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(type == .buy ? Color.Theme.success : Color.Theme.error)
            )
    }
}

// MARK: - Position Detail View

struct PositionDetailView: View {
    let position: TrackedPosition
    @Environment(\.dismiss) private var dismiss
    @State private var showingModifyView = false
    @State private var showingCloseConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with current P&L
                    headerSection
                    
                    // Position Details
                    detailsSection
                    
                    // Risk Management
                    riskSection
                    
                    // Performance Metrics
                    performanceSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .background(Color.Theme.background)
            .navigationTitle(position.symbol)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    var headerSection: some View {
        VStack(spacing: 16) {
            // Current P&L
            VStack(spacing: 8) {
                Text("Net P&L")
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.secondaryText)
                
                Text(formatCurrency(position.netPL))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(position.netPL >= 0 ? Color.Theme.success : Color.Theme.error)
                
                HStack(spacing: 16) {
                    Label(String(format: "%.2f%%", position.unrealizedPLPercent), systemImage: "percent")
                    Label(String(format: "%.1f pips", position.pipsProfit), systemImage: "chart.line.uptrend.xyaxis")
                }
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            }
            
            // Current Price
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bid")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Text(String(format: "%.5f", position.bid))
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ask")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Text(String(format: "%.5f", position.ask))
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Spread")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Text(String(format: "%.1f", position.spread * 10000))
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color.Theme.cardBackground)
            .cornerRadius(8)
        }
    }
    
    var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Position Details")
                .font(.headline)
            
            VStack(spacing: 0) {
                PositionDetailRow(label: "Type", value: position.type == .buy ? "Buy" : "Sell")
                PositionDetailRow(label: "Volume", value: String(format: "%.2f lots", position.volume))
                PositionDetailRow(label: "Open Price", value: String(format: "%.5f", position.openPrice))
                PositionDetailRow(label: "Open Time", value: formatDate(position.openTime))
                PositionDetailRow(label: "Duration", value: "\(position.durationInMinutes) min")
                
                if let comment = position.comment, !comment.isEmpty {
                    PositionDetailRow(label: "Comment", value: comment)
                }
                
                if let magic = position.magic {
                    PositionDetailRow(label: "Magic", value: String(magic))
                }
            }
            .background(Color.Theme.cardBackground)
            .cornerRadius(8)
        }
    }
    
    var riskSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Management")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Stop Loss
                RiskLevelCard(
                    title: "Stop Loss",
                    price: position.stopLoss,
                    pips: position.stopLoss.map { sl in
                        abs((position.type == .buy ? position.openPrice - sl : sl - position.openPrice) * 10000)
                    },
                    isProfit: false
                )
                
                // Take Profit
                RiskLevelCard(
                    title: "Take Profit",
                    price: position.takeProfit,
                    pips: position.takeProfit.map { tp in
                        abs((position.type == .buy ? tp - position.openPrice : position.openPrice - tp) * 10000)
                    },
                    isProfit: true
                )
                
                // Risk/Reward Ratio
                if let ratio = position.riskRewardRatio {
                    HStack {
                        Label("Risk/Reward Ratio", systemImage: "chart.xyaxis.line")
                            .font(.subheadline)
                            .foregroundColor(Color.Theme.secondaryText)
                        
                        Spacer()
                        
                        Text(String(format: "1:%.2f", ratio))
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(ratio >= 2 ? Color.Theme.success : Color.Theme.warning)
                    }
                    .padding()
                    .background(Color.Theme.cardBackground)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.headline)
            
            HStack(spacing: 16) {
                PositionMetricCard(
                    title: "Max Profit",
                    value: formatCurrency(position.maxProfit),
                    color: Color.Theme.success
                )
                
                PositionMetricCard(
                    title: "Max Loss",
                    value: formatCurrency(position.maxLoss),
                    color: Color.Theme.error
                )
            }
            
            HStack(spacing: 16) {
                PositionMetricCard(
                    title: "Commission",
                    value: formatCurrency(position.commission),
                    color: Color.Theme.secondaryText
                )
                
                PositionMetricCard(
                    title: "Swap",
                    value: formatCurrency(position.swap),
                    color: Color.Theme.secondaryText
                )
            }
        }
    }
    
    var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: { showingModifyView = true }) {
                Label("Modify", systemImage: "slider.horizontal.3")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.Theme.accent.opacity(0.2))
                    .foregroundColor(Color.Theme.accent)
                    .cornerRadius(8)
            }
            
            Button(action: { showingCloseConfirmation = true }) {
                Label("Close", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.Theme.error.opacity(0.2))
                    .foregroundColor(Color.Theme.error)
                    .cornerRadius(8)
            }
        }
        .alert("Close Position", isPresented: $showingCloseConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Close", role: .destructive) {
                // Close position
                dismiss()
            }
        } message: {
            Text("Are you sure you want to close this position?\n\nCurrent P&L: \(formatCurrency(position.netPL))")
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Helper Components

struct PositionDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.Theme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.Theme.text)
        }
        .padding()
    }
}

struct RiskLevelCard: View {
    let title: String
    let price: Double?
    let pips: Double?
    let isProfit: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.secondaryText)
                
                if let price = price {
                    Text(String(format: "%.5f", price))
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                } else {
                    Text("Not Set")
                        .font(.bodyMedium)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
            
            Spacer()
            
            if let pips = pips {
                Text(String(format: "%.1f pips", pips))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isProfit ? Color.Theme.success : Color.Theme.error)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(8)
    }
}

struct PositionMetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Text(value)
                .font(.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(8)
    }
}

#Preview {
    PositionsView()
}