//
//  MarketplaceView.swift
//  Pipflow
//
//  Strategy marketplace and discovery interface
//

import SwiftUI
import Charts

struct MarketplaceView: View {
    @StateObject private var viewModel = MarketplaceViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showFilters = false
    @State private var selectedStrategy: SharedStrategy?
    @State private var showStrategyDetail = false
    
    let categories = ["All", "Trending", "Top Rated", "New", "Free", "Premium"]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    MarketplaceSearchBar(
                        searchText: $searchText,
                        showFilters: $showFilters,
                        theme: themeManager.currentTheme
                    )
                    
                    // Category Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(categories, id: \.self) { category in
                                MarketplaceCategoryTab(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    theme: themeManager.currentTheme
                                ) {
                                    selectedCategory = category
                                    viewModel.filterByCategory(category)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    
                    // Strategy Grid
                    ScrollView {
                        if viewModel.isLoading {
                            ProgressView("Loading strategies...")
                                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                                .padding(.top, 50)
                        } else if viewModel.filteredStrategies.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "No Strategies Found",
                                description: "Try adjusting your search or filters",
                                theme: themeManager.currentTheme
                            )
                            .padding(.top, 50)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(viewModel.filteredStrategies) { strategy in
                                    StrategyCard(
                                        strategy: strategy,
                                        theme: themeManager.currentTheme
                                    ) {
                                        selectedStrategy = strategy
                                        showStrategyDetail = true
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Strategy Marketplace")
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
                        Button(action: { viewModel.sortBy(.performance) }) {
                            Label("Sort by Performance", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        Button(action: { viewModel.sortBy(.rating) }) {
                            Label("Sort by Rating", systemImage: "star")
                        }
                        Button(action: { viewModel.sortBy(.subscribers) }) {
                            Label("Sort by Popularity", systemImage: "person.3")
                        }
                        Button(action: { viewModel.sortBy(.newest) }) {
                            Label("Sort by Newest", systemImage: "clock")
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            MarketplaceFilters(viewModel: viewModel)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showStrategyDetail) {
            if let strategy = selectedStrategy {
                StrategyDetailView(strategy: strategy)
                    .environmentObject(themeManager)
            }
        }
        .onChange(of: searchText) { newValue in
            viewModel.searchStrategies(query: newValue)
        }
    }
}

// MARK: - Search Bar

struct MarketplaceSearchBar: View {
    @Binding var searchText: String
    @Binding var showFilters: Bool
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(theme.secondaryTextColor)
                
                TextField("Search strategies...", text: $searchText)
                    .foregroundColor(theme.textColor)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
            .padding()
            .background(theme.secondaryBackgroundColor)
            .cornerRadius(12)
            
            Button(action: { showFilters = true }) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(theme.accentColor)
                    .padding()
                    .background(theme.secondaryBackgroundColor)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Category Tab

struct MarketplaceCategoryTab: View {
    let title: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? theme.accentColor : theme.secondaryBackgroundColor)
                .cornerRadius(20)
        }
    }
}

// MARK: - Strategy Card

struct StrategyCard: View {
    let strategy: SharedStrategy
    let theme: Theme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: strategy.authorImage ?? "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(theme.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strategy.strategy.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textColor)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Text(strategy.authorName)
                                .font(.caption)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                }
                
                // Performance Metrics
                VStack(spacing: 8) {
                    MarketplacePerformanceRow(
                        label: "Return",
                        value: String(format: "%.1f%%", strategy.performance.totalReturn),
                        isPositive: strategy.performance.totalReturn > 0,
                        theme: theme
                    )
                    
                    MarketplacePerformanceRow(
                        label: "Win Rate",
                        value: String(format: "%.0f%%", strategy.performance.winRate * 100),
                        isPositive: true,
                        theme: theme
                    )
                    
                    MarketplacePerformanceRow(
                        label: "Sharpe",
                        value: String(format: "%.2f", strategy.performance.sharpeRatio),
                        isPositive: strategy.performance.sharpeRatio > 1,
                        theme: theme
                    )
                }
                
                Divider()
                
                // Footer
                HStack {
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", strategy.rating))
                            .font(.caption)
                            .foregroundColor(theme.textColor)
                    }
                    
                    Spacer()
                    
                    // Subscribers
                    HStack(spacing: 2) {
                        Image(systemName: "person.2")
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        Text("\(strategy.subscribers)")
                            .font(.caption)
                            .foregroundColor(theme.textColor)
                    }
                    
                    Spacer()
                    
                    // Pricing
                    Text(strategy.price == 0 ? "Free" : "$\(Int(strategy.price))/mo")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(strategy.price == 0 ? .green : theme.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(strategy.price == 0 ? Color.green.opacity(0.2) : theme.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(theme.secondaryBackgroundColor)
            .cornerRadius(16)
        }
    }
}

struct MarketplacePerformanceRow: View {
    let label: String
    let value: String
    let isPositive: Bool
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? .green : .red)
        }
    }
}


// MARK: - View Model

@MainActor
class MarketplaceViewModel: ObservableObject {
    @Published var strategies: [SharedStrategy] = []
    @Published var filteredStrategies: [SharedStrategy] = []
    @Published var isLoading = false
    @Published var filters = StrategyFilters()
    
    private let socialService = SocialTradingServiceV2.shared
    
    init() {
        loadStrategies()
    }
    
    func loadStrategies() {
        isLoading = true
        
        // Load from social service and convert
        strategies = socialService.marketplace.map { $0.toSharedStrategy() }
        filteredStrategies = strategies
        
        isLoading = false
    }
    
    func searchStrategies(query: String) {
        let socialStrategies = socialService.searchStrategies(query: query, filters: filters)
        filteredStrategies = socialStrategies.map { $0.toSharedStrategy() }
    }
    
    func filterByCategory(_ category: String) {
        switch category {
        case "All":
            filteredStrategies = strategies
        case "Trending":
            filteredStrategies = strategies.filter { $0.subscribers > 100 }
        case "Top Rated":
            filteredStrategies = strategies.filter { $0.rating >= 4.0 }
        case "New":
            let cutoff = Date().addingTimeInterval(-7 * 24 * 3600)
            filteredStrategies = strategies.filter { $0.publishedAt > cutoff }
        case "Free":
            filteredStrategies = strategies.filter { $0.price == 0 }
        case "Premium":
            filteredStrategies = strategies.filter { $0.price > 0 }
        default:
            filteredStrategies = strategies
        }
    }
    
    func sortBy(_ option: StrategySortOption) {
        filters.sortBy = option
        let socialStrategies = socialService.searchStrategies(query: "", filters: filters)
        filteredStrategies = socialStrategies.map { $0.toSharedStrategy() }
    }
    
    func applyFilters(_ newFilters: StrategyFilters) {
        filters = newFilters
        let socialStrategies = socialService.searchStrategies(query: "", filters: filters)
        filteredStrategies = socialStrategies.map { $0.toSharedStrategy() }
    }
}

// MARK: - Marketplace Filters View

struct MarketplaceFilters: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var minReturn: String = ""
    @State private var maxDrawdown: String = ""
    @State private var minWinRate: String = ""
    @State private var selectedPricingModel: PricingModel?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Performance Filters")) {
                    HStack {
                        Text("Min Return (%)")
                        TextField("0", text: $minReturn)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Max Drawdown (%)")
                        TextField("100", text: $maxDrawdown)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Min Win Rate (%)")
                        TextField("0", text: $minWinRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Pricing Model")) {
                    Picker("Model", selection: $selectedPricingModel) {
                        Text("All").tag(nil as PricingModel?)
                        Text("Free").tag(PricingModel.free as PricingModel?)
                        Text("Subscription").tag(PricingModel.subscription as PricingModel?)
                        Text("Performance").tag(PricingModel.performance as PricingModel?)
                        Text("Hybrid").tag(PricingModel.hybrid as PricingModel?)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Filter Strategies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        var filters = StrategyFilters()
                        
                        if let minReturnValue = Double(minReturn) {
                            filters.minReturn = minReturnValue
                        }
                        
                        if let maxDrawdownValue = Double(maxDrawdown) {
                            filters.maxDrawdown = maxDrawdownValue / 100
                        }
                        
                        if let minWinRateValue = Double(minWinRate) {
                            filters.minWinRate = minWinRateValue / 100
                        }
                        
                        filters.pricingModel = selectedPricingModel
                        filters.sortBy = viewModel.filters.sortBy
                        
                        viewModel.applyFilters(filters)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}