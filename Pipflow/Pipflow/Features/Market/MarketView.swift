//
//  MarketView.swift
//  Pipflow
//
//  Market overview and watchlist
//

import SwiftUI
import Combine

struct MarketView: View {
    @StateObject private var viewModel = MarketViewModel()
    @StateObject private var marketData = MarketDataService.shared
    @StateObject private var webSocketService = MetaAPIWebSocketService.shared
    @State private var selectedCategory = MarketCategory.all
    @State private var searchText = ""
    @State private var showAddSymbol = false
    @State private var showingAIChart = false
    @State private var selectedSymbolForAI = "EURUSD"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                MarketSearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Category Tabs
                MarketCategoryTabs(selectedCategory: $selectedCategory)
                    .padding(.horizontal)
                
                // Market List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredSymbols) { symbol in
                            MarketRowView(symbol: symbol) {
                                // Navigate to AI-enhanced trading view
                                showAIChart(for: symbol.name)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await viewModel.refreshMarketData()
                }
            }
            .background(Color.Theme.background)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSymbol = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddSymbol) {
                AddSymbolView()
            }
            .sheet(isPresented: $showingAIChart) {
                // Clean TradingView Chart
                ChartView(symbol: selectedSymbolForAI)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            viewModel.startMarketUpdates()
        }
        .onDisappear {
            viewModel.stopMarketUpdates()
        }
    }
    
    private func showAIChart(for symbol: String) {
        selectedSymbolForAI = symbol
        showingAIChart = true
    }
    
    private var filteredSymbols: [MarketSymbol] {
        viewModel.symbols
            .filter { symbol in
                (selectedCategory == .all || symbol.category == selectedCategory) &&
                (searchText.isEmpty || symbol.name.localizedCaseInsensitiveContains(searchText) ||
                 symbol.displayName.localizedCaseInsensitiveContains(searchText))
            }
    }
}

// MARK: - Search Bar

struct MarketSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.Theme.text.opacity(0.6))
            
            TextField("Search symbols", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(Color.Theme.text)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.Theme.text.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.Theme.cardBackground)
        .cornerRadius(10)
    }
}

// MARK: - Category Tabs

enum MarketCategory: String, CaseIterable {
    case all = "All"
    case favorites = "Favorites"
    case forex = "Forex"
    case crypto = "Crypto"
    case indices = "Indices"
    case commodities = "Commodities"
}

struct MarketCategoryTabs: View {
    @Binding var selectedCategory: MarketCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(MarketCategory.allCases, id: \.self) { category in
                    MarketCategoryTab(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct MarketCategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : Color.Theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.Theme.accent : Color.Theme.cardBackground
                )
                .cornerRadius(20)
        }
    }
}

// MARK: - Market Row

struct MarketRowView: View {
    let symbol: MarketSymbol
    let onTap: () -> Void
    @StateObject private var webSocketService = MetaAPIWebSocketService.shared
    @State private var isFavorite = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack {
                    // Symbol Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(symbol.name)
                                .font(.headline)
                                .foregroundColor(Color.Theme.text)
                            
                            if symbol.category == .crypto {
                                Image(systemName: "bitcoinsign.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(Color.orange)
                            }
                        }
                        
                        Text(symbol.displayName)
                            .font(.caption)
                            .foregroundColor(Color.Theme.text.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Price & Change
                    VStack(alignment: .trailing, spacing: 4) {
                        if let price = currentPrice {
                            Text(formatPrice(price))
                                .font(.headline)
                                .foregroundColor(Color.Theme.text)
                        } else {
                            Text("--")
                                .font(.headline)
                                .foregroundColor(Color.Theme.text.opacity(0.3))
                        }
                        
                        if let change = symbol.priceChange {
                            HStack(spacing: 4) {
                                Image(systemName: change.isPositive ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption2)
                                Text("\(change.isPositive ? "+" : "")\(String(format: "%.2f", change.changePercent))%")
                                    .font(.caption)
                            }
                            .foregroundColor(change.isPositive ? Color.Theme.success : Color.Theme.error)
                        }
                    }
                    
                    // Favorite Button
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.body)
                            .foregroundColor(isFavorite ? Color.yellow : Color.Theme.text.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                // Spread & 24h Stats
                if symbol.showDetails {
                    Divider()
                        .background(Color.Theme.divider)
                    
                    HStack {
                        MarketStatItem(label: "Spread", value: formatSpread(symbol))
                        
                        Divider()
                            .frame(height: 30)
                            .background(Color.Theme.divider)
                        
                        MarketStatItem(label: "24h High", value: formatPrice(symbol.high24h ?? 0))
                        
                        Divider()
                            .frame(height: 30)
                            .background(Color.Theme.divider)
                        
                        MarketStatItem(label: "24h Low", value: formatPrice(symbol.low24h ?? 0))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }
            .background(Color.Theme.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.Theme.shadow, radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .onAppear {
            isFavorite = MarketViewModel.shared.isFavorite(symbol.name)
        }
    }
    
    private var currentPrice: Double? {
        if let wsPrice = webSocketService.getPrice(for: symbol.name) {
            return (wsPrice.bid + wsPrice.ask) / 2
        }
        return symbol.currentPrice
    }
    
    private func formatPrice(_ price: Double) -> String {
        let decimals = symbol.category == .forex ? 5 : 2
        return String(format: "%.\(decimals)f", price)
    }
    
    private func formatSpread(_ symbol: MarketSymbol) -> String {
        if let wsPrice = webSocketService.getPrice(for: symbol.name) {
            let spread = wsPrice.ask - wsPrice.bid
            let pips = symbol.category == .forex ? spread * 10000 : spread
            return String(format: "%.1f", pips)
        }
        return "--"
    }
    
    private func toggleFavorite() {
        MarketViewModel.shared.toggleFavorite(symbol.name)
        isFavorite.toggle()
    }
}

struct MarketStatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.Theme.text.opacity(0.6))
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.Theme.text)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Symbol View

struct AddSymbolView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedSymbols: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack {
                MarketSearchBar(text: $searchText)
                    .padding()
                
                List(availableSymbols, id: \.self) { symbol in
                    HStack {
                        Text(symbol)
                            .foregroundColor(Color.Theme.text)
                        
                        Spacer()
                        
                        if selectedSymbols.contains(symbol) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.Theme.success)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedSymbols.contains(symbol) {
                            selectedSymbols.remove(symbol)
                        } else {
                            selectedSymbols.insert(symbol)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Add Symbols")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        MarketViewModel.shared.addSymbols(Array(selectedSymbols))
                        dismiss()
                    }
                    .disabled(selectedSymbols.isEmpty)
                }
            }
        }
    }
    
    private var availableSymbols: [String] {
        let allSymbols = [
            "EURUSD", "GBPUSD", "USDJPY", "USDCHF", "USDCAD", "AUDUSD", "NZDUSD",
            "BTCUSD", "ETHUSD", "XRPUSD", "LTCUSD", "BCHUSD",
            "US30", "US500", "NAS100", "UK100", "GER40",
            "XAUUSD", "XAGUSD", "USOIL", "UKOIL"
        ]
        
        let existingSymbols = MarketViewModel.shared.symbols.map { $0.name }
        let available = allSymbols.filter { !existingSymbols.contains($0) }
        
        if searchText.isEmpty {
            return available
        } else {
            return available.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

// MARK: - Market Symbol Model

struct MarketSymbol: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let category: MarketCategory
    var currentPrice: Double?
    var priceChange: PriceChange?
    var high24h: Double?
    var low24h: Double?
    var showDetails: Bool = false
}

struct PriceChange {
    let changeValue: Double
    let changePercent: Double
    
    var isPositive: Bool {
        changeValue >= 0
    }
}

// MARK: - Market View Model

class MarketViewModel: ObservableObject {
    static let shared = MarketViewModel()
    
    @Published var symbols: [MarketSymbol] = []
    @Published var favoriteSymbols: Set<String> = []
    
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSymbols()
        loadFavorites()
    }
    
    func startMarketUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.updatePrices()
        }
    }
    
    func stopMarketUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func refreshMarketData() async {
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            updatePrices()
        }
    }
    
    func toggleFavorite(_ symbol: String) {
        if favoriteSymbols.contains(symbol) {
            favoriteSymbols.remove(symbol)
        } else {
            favoriteSymbols.insert(symbol)
        }
        saveFavorites()
    }
    
    func isFavorite(_ symbol: String) -> Bool {
        favoriteSymbols.contains(symbol)
    }
    
    func addSymbols(_ symbols: [String]) {
        for symbol in symbols {
            let marketSymbol = createMarketSymbol(for: symbol)
            self.symbols.append(marketSymbol)
        }
    }
    
    private func loadSymbols() {
        symbols = [
            MarketSymbol(name: "EURUSD", displayName: "Euro / US Dollar", category: .forex, currentPrice: 1.0854),
            MarketSymbol(name: "GBPUSD", displayName: "British Pound / US Dollar", category: .forex, currentPrice: 1.2687),
            MarketSymbol(name: "USDJPY", displayName: "US Dollar / Japanese Yen", category: .forex, currentPrice: 157.32),
            MarketSymbol(name: "BTCUSD", displayName: "Bitcoin / US Dollar", category: .crypto, currentPrice: 106543.21),
            MarketSymbol(name: "ETHUSD", displayName: "Ethereum / US Dollar", category: .crypto, currentPrice: 3854.67),
            MarketSymbol(name: "XAUUSD", displayName: "Gold / US Dollar", category: .commodities, currentPrice: 2654.32),
            MarketSymbol(name: "US500", displayName: "S&P 500 Index", category: .indices, currentPrice: 6125.43)
        ]
        
        // Add mock price changes
        for i in 0..<symbols.count {
            let changePercent = Double.random(in: -3...3)
            let changeValue = (symbols[i].currentPrice ?? 0) * changePercent / 100
            symbols[i].priceChange = PriceChange(changeValue: changeValue, changePercent: changePercent)
            symbols[i].high24h = (symbols[i].currentPrice ?? 0) * 1.02
            symbols[i].low24h = (symbols[i].currentPrice ?? 0) * 0.98
        }
    }
    
    private func createMarketSymbol(for name: String) -> MarketSymbol {
        let category: MarketCategory
        let displayName: String
        
        switch name {
        case let s where s.contains("USD") || s.contains("EUR") || s.contains("GBP") || s.contains("JPY"):
            category = .forex
            displayName = name
        case let s where s.contains("BTC") || s.contains("ETH") || s.contains("XRP"):
            category = .crypto
            displayName = name.replacingOccurrences(of: "USD", with: " / US Dollar")
        case let s where s.contains("XAU") || s.contains("XAG") || s.contains("OIL"):
            category = .commodities
            displayName = name
        default:
            category = .indices
            displayName = name
        }
        
        return MarketSymbol(name: name, displayName: displayName, category: category)
    }
    
    private func updatePrices() {
        // Simulate price updates
        for i in 0..<symbols.count {
            let oldPrice = symbols[i].currentPrice ?? 100
            let change = Double.random(in: -0.5...0.5) / 100
            let newPrice = oldPrice * (1 + change)
            
            symbols[i].currentPrice = newPrice
            
            let changeValue = newPrice - oldPrice
            let changePercent = (changeValue / oldPrice) * 100
            symbols[i].priceChange = PriceChange(changeValue: changeValue, changePercent: changePercent)
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: "favoriteSymbols"),
           let favorites = try? JSONDecoder().decode(Set<String>.self, from: data) {
            favoriteSymbols = favorites
        }
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteSymbols) {
            UserDefaults.standard.set(data, forKey: "favoriteSymbols")
        }
    }
}

#Preview {
    MarketView()
}