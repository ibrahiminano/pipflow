//
//  ProfileStrategiesView.swift
//  Pipflow
//
//  Shared strategies tab for user profile
//

import SwiftUI

struct ProfileStrategiesView: View {
    let userId: UUID
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedFilter = "All"
    
    let filters = ["All", "Active", "Profitable", "Free", "Premium"]
    
    // Mock strategies
    let strategies = [
        ProfileStrategy(
            id: UUID(),
            name: "Trend Following Pro",
            description: "Advanced trend following strategy using multiple timeframes",
            type: .manual,
            winRate: 0.68,
            monthlyReturn: 0.15,
            subscribers: 234,
            price: 49.99,
            rating: 4.5
        ),
        ProfileStrategy(
            id: UUID(),
            name: "Scalping Master",
            description: "High-frequency scalping on major pairs",
            type: .automated,
            winRate: 0.72,
            monthlyReturn: 0.12,
            subscribers: 156,
            price: 0,
            rating: 4.2
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Filter Options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FilterChip(
                                title: filter,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Strategies List
                if strategies.isEmpty {
                    EmptyStrategiesView()
                        .padding(.top, 50)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(strategies) { strategy in
                            ProfileStrategyCard(strategy: strategy)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Profile Strategy Model
struct ProfileStrategy: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let type: StrategyType
    let winRate: Double
    let monthlyReturn: Double
    let subscribers: Int
    let price: Double
    let rating: Double
    
    enum StrategyType {
        case manual
        case automated
        case signals
        
        var icon: String {
            switch self {
            case .manual: return "hand.raised"
            case .automated: return "cpu"
            case .signals: return "bell.badge"
            }
        }
        
        var label: String {
            switch self {
            case .manual: return "Manual"
            case .automated: return "Automated"
            case .signals: return "Signals"
            }
        }
    }
}

// MARK: - Profile Strategy Card
struct ProfileStrategyCard: View {
    let strategy: ProfileStrategy
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(strategy.name)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        if strategy.price == 0 {
                            Text("FREE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(strategy.description)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Type Icon
                Image(systemName: strategy.type.icon)
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            // Stats
            HStack(spacing: 20) {
                StatItem(
                    label: "Win Rate",
                    value: "\(Int(strategy.winRate * 100))%",
                    color: .green
                )
                
                StatItem(
                    label: "Monthly",
                    value: "+\(Int(strategy.monthlyReturn * 100))%",
                    color: .green
                )
                
                StatItem(
                    label: "Subscribers",
                    value: "\(strategy.subscribers)",
                    color: themeManager.currentTheme.accentColor
                )
                
                Spacer()
                
                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text(String(format: "%.1f", strategy.rating))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
            
            Divider()
                .background(themeManager.currentTheme.separatorColor)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("View Details")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text(strategy.price > 0 ? "$\(Int(strategy.price))/mo" : "Copy")
                    }
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(themeManager.currentTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            ProfileStrategyDetailView(strategy: strategy)
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Profile Strategy Detail View
struct ProfileStrategyDetailView: View {
    let strategy: ProfileStrategy
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Strategy Info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(strategy.type.label, systemImage: strategy.type.icon)
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            
                            Spacer()
                            
                            if strategy.price == 0 {
                                Text("FREE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            } else {
                                Text("$\(Int(strategy.price))/month")
                                    .font(.bodyMedium)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                            }
                        }
                        
                        Text(strategy.description)
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                    
                    // Performance Chart placeholder
                    Rectangle()
                        .fill(themeManager.currentTheme.secondaryBackgroundColor)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            Text("Performance Chart")
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        )
                    
                    // Detailed Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Strategy Statistics")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        VStack(spacing: 12) {
                            DetailStatRow(label: "Win Rate", value: "\(Int(strategy.winRate * 100))%")
                            DetailStatRow(label: "Monthly Return", value: "+\(Int(strategy.monthlyReturn * 100))%")
                            DetailStatRow(label: "Active Subscribers", value: "\(strategy.subscribers)")
                            DetailStatRow(label: "Rating", value: "\(strategy.rating)/5.0")
                            DetailStatRow(label: "Risk Level", value: "Moderate")
                            DetailStatRow(label: "Avg. Trade Duration", value: "2-3 days")
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                    
                    // Subscribe Button
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text(strategy.price > 0 ? "Subscribe for $\(Int(strategy.price))/mo" : "Copy Strategy")
                        }
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(themeManager.currentTheme.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle(strategy.name)
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
}

struct DetailStatRow: View {
    let label: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.textColor)
        }
    }
}

// MARK: - Supporting Views
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(
                    isSelected
                        ? .white
                        : themeManager.currentTheme.secondaryTextColor
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? themeManager.currentTheme.accentColor
                        : themeManager.currentTheme.backgroundColor
                )
                .cornerRadius(20)
        }
    }
}

struct EmptyStrategiesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text("No Strategies Shared")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text("This trader hasn't shared any strategies yet.")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}