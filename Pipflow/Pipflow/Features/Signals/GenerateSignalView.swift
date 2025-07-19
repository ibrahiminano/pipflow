//
//  GenerateSignalView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI
import Combine

struct GenerateSignalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var viewModel = GenerateSignalViewModel()
    
    @State private var selectedSymbol = "EURUSD"
    @State private var selectedTimeframe = "H1"
    @State private var selectedProvider: AIProvider = .claude
    @State private var includeNews = false
    
    let symbols = ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "BTCUSD", "ETHUSD", "XAUUSD"]
    let timeframes = ["M5", "M15", "M30", "H1", "H4", "D1"]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Card
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundColor(themeManager.currentTheme.accentColor)
                                .padding(.top)
                            
                            Text("Generate AI Signal")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Text("Our AI will analyze market conditions and provide trading recommendations")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.bottom)
                        
                        // Configuration Section
                        VStack(alignment: .leading, spacing: 20) {
                            // Symbol Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Symbol", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(symbols, id: \.self) { symbol in
                                            SymbolChip(
                                                symbol: symbol,
                                                isSelected: selectedSymbol == symbol,
                                                theme: themeManager.currentTheme
                                            ) {
                                                selectedSymbol = symbol
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Timeframe Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Timeframe", systemImage: "clock")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(timeframes, id: \.self) { timeframe in
                                            TimeframeChip(
                                                timeframe: timeframe,
                                                isSelected: selectedTimeframe == timeframe,
                                                theme: themeManager.currentTheme
                                            ) {
                                                selectedTimeframe = timeframe
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // AI Provider Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Label("AI Provider", systemImage: "cpu")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                
                                HStack(spacing: 12) {
                                    ProviderButton(
                                        provider: .claude,
                                        isSelected: selectedProvider == .claude,
                                        theme: themeManager.currentTheme
                                    ) {
                                        selectedProvider = .claude
                                    }
                                    
                                    ProviderButton(
                                        provider: .openai,
                                        isSelected: selectedProvider == .openai,
                                        theme: themeManager.currentTheme
                                    ) {
                                        selectedProvider = .openai
                                    }
                                }
                            }
                            
                            // Additional Options
                            VStack(alignment: .leading, spacing: 16) {
                                Toggle(isOn: $includeNews) {
                                    Label("Include News Analysis", systemImage: "newspaper")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .tint(themeManager.currentTheme.accentColor)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Generate Button
                        Button(action: generateSignal) {
                            if viewModel.isGenerating {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Analyzing...")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.currentTheme.accentColor.opacity(0.6))
                                )
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                    Text("Generate Signal")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    themeManager.currentTheme.accentColor,
                                                    themeManager.currentTheme.accentColor.opacity(0.8)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                            }
                        }
                        .disabled(viewModel.isGenerating)
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private func generateSignal() {
        viewModel.generateSignal(
            symbol: selectedSymbol,
            timeframe: selectedTimeframe,
            provider: selectedProvider,
            includeNews: includeNews
        ) {
            dismiss()
        }
    }
}

// MARK: - Generate Signal View Model

class GenerateSignalViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let aiSignalService = AISignalService.shared
    
    func generateSignal(
        symbol: String,
        timeframe: String,
        provider: AIProvider,
        includeNews: Bool,
        onComplete: @escaping () -> Void
    ) {
        isGenerating = true
        
        // In production, fetch real market data
        let marketData = MarketData(
            currentPrice: getLatestPrice(for: symbol),
            high24h: getLatestPrice(for: symbol) * 1.005,
            low24h: getLatestPrice(for: symbol) * 0.995,
            volume24h: 1000000,
            priceChange24h: 0.25,
            bid: getLatestPrice(for: symbol) * 0.9999,
            ask: getLatestPrice(for: symbol) * 1.0001,
            spread: 0.0002
        )
        
        let technicalIndicators = TechnicalIndicators(
            rsi: Double.random(in: 30...70),
            macd: MACDIndicator(
                macd: Double.random(in: -0.002...0.002),
                signal: Double.random(in: -0.001...0.001),
                histogram: Double.random(in: -0.0005...0.0005)
            ),
            movingAverages: MovingAverages(
                ma20: getLatestPrice(for: symbol) * Double.random(in: 0.998...1.002),
                ma50: getLatestPrice(for: symbol) * Double.random(in: 0.995...1.005),
                ma200: getLatestPrice(for: symbol) * Double.random(in: 0.99...1.01)
            ),
            support: getLatestPrice(for: symbol) * 0.99,
            resistance: getLatestPrice(for: symbol) * 1.01,
            trend: [TrendDirection.bullish, .bearish, .neutral].randomElement()!
        )
        
        var news: [NewsItem]? = nil
        if includeNews {
            news = [
                NewsItem(
                    title: "Market shows signs of recovery",
                    summary: "Technical indicators suggest potential reversal",
                    sentiment: 0.6,
                    timestamp: Date()
                )
            ]
        }
        
        aiSignalService.generateSignal(
            for: symbol,
            timeframe: timeframe,
            marketData: marketData,
            technicalIndicators: technicalIndicators,
            recentNews: news,
            provider: provider
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isGenerating = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                } else {
                    DispatchQueue.main.async {
                        onComplete()
                    }
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
    }
    
    private func getLatestPrice(for symbol: String) -> Double {
        // Mock prices for demo
        switch symbol {
        case "EURUSD": return 1.0850
        case "GBPUSD": return 1.2750
        case "USDJPY": return 155.50
        case "AUDUSD": return 0.6550
        case "BTCUSD": return 98500
        case "ETHUSD": return 3850
        case "XAUUSD": return 2650
        default: return 1.0
        }
    }
}

// MARK: - Supporting Views

struct SymbolChip: View {
    let symbol: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? theme.accentColor : theme.secondaryBackgroundColor)
                )
        }
    }
}

struct TimeframeChip: View {
    let timeframe: String
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(timeframe)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : theme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? theme.accentColor : theme.secondaryBackgroundColor)
                )
        }
    }
}

struct ProviderButton: View {
    let provider: AIProvider
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: provider == .claude ? "brain" : "sparkles.square.filled.on.square")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? theme.accentColor : theme.secondaryTextColor)
                
                Text(provider == .claude ? "Claude" : "GPT-4")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.secondaryBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

#Preview {
    GenerateSignalView()
        .environmentObject(ThemeManager())
}