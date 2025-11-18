//
//  MarketWatchView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI
import Combine

struct MarketWatchView: View {
    @StateObject private var marketData = MarketDataService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedCategory = "All"
    
    let categories = ["All", "Forex", "Crypto", "Commodities"]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                MarketWatchCategoryChip(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    theme: themeManager.currentTheme
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    
                    // Market Quotes List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSymbols, id: \.self) { symbol in
                                if let quote = marketData.quotes[symbol] {
                                    Button(action: {
                                        ChartPresentationManager.shared.presentChart(for: symbol)
                                    }) {
                                        MarketQuoteRow(
                                            symbol: symbol,
                                            quote: quote,
                                            priceChange: marketData.priceChanges[symbol],
                                            theme: themeManager.currentTheme
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Market Watch")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                marketData.startStreaming(symbols: marketData.supportedSymbols)
            }
            .onDisappear {
                marketData.stopStreaming()
            }
        }
    }
    
    var filteredSymbols: [String] {
        switch selectedCategory {
        case "Forex":
            return ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCAD"]
        case "Crypto":
            return ["BTCUSD", "ETHUSD"]
        case "Commodities":
            return ["XAUUSD", "XAGUSD", "USOIL"]
        default:
            return marketData.supportedSymbols
        }
    }
}

// MARK: - Market Quote Row

struct MarketQuoteRow: View {
    let symbol: String
    let quote: MarketQuote
    let priceChange: PriceChange?
    let theme: Theme
    
    var body: some View {
        HStack {
            // Symbol Info
            VStack(alignment: .leading, spacing: 4) {
                Text(symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textColor)
                
                Text(symbolDescription)
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
            
            // Price Info
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    // Bid/Ask Prices
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatPrice(quote.bid))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.Theme.sell)
                        
                        Text("Bid")
                            .font(.system(size: 10))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                    
                    Rectangle()
                        .fill(theme.separatorColor)
                        .frame(width: 1, height: 30)
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatPrice(quote.ask))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.Theme.buy)
                        
                        Text("Ask")
                            .font(.system(size: 10))
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
                
                // Price Change
                if let change = priceChange {
                    HStack(spacing: 4) {
                        Image(systemName: change.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10))
                        
                        Text("\(change.changeValue >= 0 ? "+" : "")\(formatPrice(change.changeValue))")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text("(\(String(format: "%.2f", change.changePercent))%)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(change.isPositive ? Color.Theme.success : Color.Theme.error)
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    var symbolDescription: String {
        switch symbol {
        case "EURUSD": return "Euro / US Dollar"
        case "GBPUSD": return "British Pound / US Dollar"
        case "USDJPY": return "US Dollar / Japanese Yen"
        case "AUDUSD": return "Australian Dollar / US Dollar"
        case "USDCAD": return "US Dollar / Canadian Dollar"
        case "BTCUSD": return "Bitcoin / US Dollar"
        case "ETHUSD": return "Ethereum / US Dollar"
        case "XAUUSD": return "Gold / US Dollar"
        case "XAGUSD": return "Silver / US Dollar"
        case "USOIL": return "Crude Oil"
        default: return symbol
        }
    }
    
    func formatPrice(_ price: Double) -> String {
        MarketDataService.shared.formatPrice(price, for: symbol)
    }
}

// MARK: - Category Chip

struct MarketWatchCategoryChip: View {
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
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? theme.accentColor : theme.secondaryBackgroundColor)
                )
        }
    }
}

// MARK: - Live Price Header

struct LivePriceHeader: View {
    let symbol: String
    @ObservedObject var marketData = MarketDataService.shared
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 8) {
            if let quote = marketData.quotes[symbol],
               let change = marketData.priceChanges[symbol] {
                
                // Current Price
                Text(marketData.formatPrice(quote.mid, for: symbol))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(theme.textColor)
                
                // Price Change
                HStack(spacing: 8) {
                    Image(systemName: change.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 14))
                    
                    Text("\(change.changeValue >= 0 ? "+" : "")\(marketData.formatPrice(change.changeValue, for: symbol))")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("(\(String(format: "%.2f", change.changePercent))%)")
                        .font(.system(size: 16))
                }
                .foregroundColor(change.isPositive ? Color.Theme.success : Color.Theme.error)
                
                // Spread
                HStack {
                    Text("Spread:")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryTextColor)
                    
                    Text(marketData.formatSpread(quote.spread, for: symbol))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textColor)
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(16)
    }
}

#Preview {
    MarketWatchView()
        .environmentObject(ThemeManager.shared)
}