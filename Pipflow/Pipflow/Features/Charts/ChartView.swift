//
//  ChartView.swift
//  Pipflow
//
//  Created by Claude on 19/07/2025.
//

import SwiftUI
import Charts
import Combine

struct ChartView: View {
    let symbol: String
    @StateObject private var viewModel: ChartViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTimeframe: ChartTimeframe = .h1
    @State private var selectedChartType: ChartType = .candlestick
    @State private var showingIndicators = false
    @State private var selectedIndicators: Set<ChartIndicator> = []
    @State private var showingDrawingTools = false
    @State private var isFullScreen = false
    
    // AI Features
    @State private var showAIFeatures = false
    @State private var selectedAIFeatures: Set<AIChartFeature> = [.signals]
    @State private var showingAISettings = false
    @State private var aiAnalysisResult: AIChartAnalysis?
    
    init(symbol: String) {
        self.symbol = symbol
        self._viewModel = StateObject(wrappedValue: ChartViewModel(symbol: symbol))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Close Button
                    HStack {
                        Spacer()
                        Button(action: {
                            ChartPresentationManager.shared.dismissChart()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .padding()
                    }
                    
                    // Price Header
                    ChartHeaderView(
                        symbol: symbol,
                        currentPrice: viewModel.currentPrice,
                        priceChange: viewModel.priceChange,
                        priceChangePercent: viewModel.priceChangePercent
                    )
                    
                    // Timeframe Selector
                    TimeframeSelectorView(selectedTimeframe: $selectedTimeframe)
                        .onChange(of: selectedTimeframe) { _, newTimeframe in
                            viewModel.changeTimeframe(to: newTimeframe)
                            if showAIFeatures {
                                viewModel.refreshAIAnalysis()
                            }
                        }
                    
                    // AI Features Toggle Bar
                    if showAIFeatures {
                        AIFeatureToggleBar(
                            selectedFeatures: $selectedAIFeatures,
                            onSettingsTapped: { showingAISettings = true }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    
                    // Main Chart
                    ZStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.currentTheme.accentColor))
                                .scaleEffect(1.5)
                        } else {
                            ChartContentView(
                                candles: viewModel.candles,
                                chartType: selectedChartType,
                                indicators: selectedIndicators,
                                viewModel: viewModel,
                                aiAnalysis: showAIFeatures ? viewModel.aiAnalysis : nil,
                                selectedAIFeatures: selectedAIFeatures
                            )
                            
                            // AI Overlay Components
                            if showAIFeatures {
                                AIChartOverlay(
                                    analysis: viewModel.aiAnalysis,
                                    selectedFeatures: selectedAIFeatures,
                                    candles: viewModel.candles
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(themeManager.currentTheme.backgroundColor)
                    
                    // AI Commentary Panel
                    if showAIFeatures && selectedAIFeatures.contains(.commentary) {
                        AICommentaryPanel(analysis: viewModel.aiAnalysis)
                            .frame(height: 120)
                            .padding(.horizontal)
                    }
                    
                    // Chart Tools Bar
                    ChartToolsBar(
                        selectedChartType: $selectedChartType,
                        showingIndicators: $showingIndicators,
                        showingDrawingTools: $showingDrawingTools,
                        isFullScreen: $isFullScreen,
                        showAIFeatures: $showAIFeatures
                    )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingIndicators) {
                IndicatorsSelectionView(selectedIndicators: $selectedIndicators)
            }
            .sheet(isPresented: $showingDrawingTools) {
                DrawingToolsView()
            }
            .sheet(isPresented: $showingAISettings) {
                AIChartSettingsView(
                    selectedFeatures: $selectedAIFeatures,
                    viewModel: viewModel
                )
            }
            .fullScreenCover(isPresented: $isFullScreen) {
                FullScreenChartView(
                    symbol: symbol,
                    selectedTimeframe: $selectedTimeframe,
                    selectedChartType: $selectedChartType,
                    selectedIndicators: $selectedIndicators,
                    isFullScreen: $isFullScreen,
                    showAIFeatures: showAIFeatures,
                    selectedAIFeatures: selectedAIFeatures
                )
            }
        }
        .onAppear {
            if showAIFeatures {
                viewModel.startAIAnalysis()
            }
        }
    }
}

// MARK: - Chart Header

struct ChartHeaderView: View {
    let symbol: String
    let currentPrice: Double
    let priceChange: Double
    let priceChangePercent: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(symbol)
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    HStack(spacing: 8) {
                        Text(String(format: "%.5f", currentPrice))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        HStack(spacing: 4) {
                            Image(systemName: priceChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                            Text(String(format: "%.5f", abs(priceChange)))
                                .font(.subheadline)
                            Text(String(format: "(%.2f%%)", priceChangePercent))
                                .font(.subheadline)
                        }
                        .foregroundColor(priceChange >= 0 ? Color.Theme.success : Color.Theme.error)
                    }
                }
                
                Spacer()
                
                // Market Status
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.Theme.success)
                        .frame(width: 8, height: 8)
                    Text("Market Open")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            .padding()
            
            Divider()
                .background(themeManager.currentTheme.separatorColor)
        }
    }
}

// MARK: - Timeframe Selector

struct TimeframeSelectorView: View {
    @Binding var selectedTimeframe: ChartTimeframe
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChartTimeframe.allCases, id: \.self) { timeframe in
                    TimeframeButton(
                        timeframe: timeframe,
                        isSelected: selectedTimeframe == timeframe,
                        action: {
                            selectedTimeframe = timeframe
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(themeManager.currentTheme.secondaryBackgroundColor)
    }
}

struct TimeframeButton: View {
    let timeframe: ChartTimeframe
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(timeframe.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            themeManager.currentTheme.backgroundColor
                        }
                    }
                )
                .cornerRadius(8)
        }
    }
}

// MARK: - Chart Content

struct ChartContentView: View {
    let candles: [CandleData]
    let chartType: ChartType
    let indicators: Set<ChartIndicator>
    let viewModel: ChartViewModel
    let aiAnalysis: AIChartAnalysis?
    let selectedAIFeatures: Set<AIChartFeature>
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Chart(candles) { candle in
            switch chartType {
            case .candlestick:
                RectangleMark(
                    x: .value("Time", candle.timestamp),
                    yStart: .value("Low", candle.low),
                    yEnd: .value("High", candle.high),
                    width: 1
                )
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                
                RectangleMark(
                    x: .value("Time", candle.timestamp),
                    yStart: .value("Open", candle.open),
                    yEnd: .value("Close", candle.close),
                    width: 8
                )
                .foregroundStyle(candle.close > candle.open ? Color.Theme.success : Color.Theme.error)
                
            case .line:
                LineMark(
                    x: .value("Time", candle.timestamp),
                    y: .value("Close", candle.close)
                )
                .foregroundStyle(themeManager.currentTheme.accentColor)
                
            case .bar:
                RectangleMark(
                    x: .value("Time", candle.timestamp),
                    yStart: .value("Low", candle.low),
                    yEnd: .value("High", candle.high),
                    width: 1
                )
                .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
                
            case .area:
                AreaMark(
                    x: .value("Time", candle.timestamp),
                    y: .value("Close", candle.close)
                )
                .foregroundStyle(themeManager.currentTheme.accentColor.opacity(0.3))
                
                LineMark(
                    x: .value("Time", candle.timestamp),
                    y: .value("Close", candle.close)
                )
                .foregroundStyle(themeManager.currentTheme.accentColor)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Candlestick Mark

struct CandlestickMark: ChartContent {
    let x: PlottableValue<Date>
    let low: PlottableValue<Double>
    let high: PlottableValue<Double>
    let open: PlottableValue<Double>
    let close: PlottableValue<Double>
    
    var body: some ChartContent {
        RectangleMark(
            x: x,
            yStart: open,
            yEnd: close,
            width: 6
        )
        
        RectangleMark(
            x: x,
            yStart: low,
            yEnd: high,
            width: 1
        )
    }
}

// MARK: - Crosshair View

struct CrosshairView: View {
    let location: CGPoint
    let geometry: GeometryProxy
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Vertical line
            Path { path in
                path.move(to: CGPoint(x: location.x, y: 0))
                path.addLine(to: CGPoint(x: location.x, y: geometry.size.height))
            }
            .stroke(themeManager.currentTheme.secondaryTextColor.opacity(0.5), lineWidth: 1)
            
            // Horizontal line
            Path { path in
                path.move(to: CGPoint(x: 0, y: location.y))
                path.addLine(to: CGPoint(x: geometry.size.width, y: location.y))
            }
            .stroke(themeManager.currentTheme.secondaryTextColor.opacity(0.5), lineWidth: 1)
            
            // Price label
            Text(String(format: "%.5f", priceFromYPosition(location.y)))
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(themeManager.currentTheme.accentColor)
                .cornerRadius(4)
                .position(x: geometry.size.width - 40, y: location.y)
        }
    }
    
    private func priceFromYPosition(_ y: CGFloat) -> Double {
        // This is a simplified calculation - in production, you'd use the actual price scale
        return 1.0850 + (geometry.size.height / 2 - y) * 0.0001
    }
}

// MARK: - Chart Tools Bar

struct ChartToolsBar: View {
    @Binding var selectedChartType: ChartType
    @Binding var showingIndicators: Bool
    @Binding var showingDrawingTools: Bool
    @Binding var isFullScreen: Bool
    @Binding var showAIFeatures: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 20) {
            // Chart Type Menu
            Menu {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Button(action: { selectedChartType = type }) {
                        Label(type.name, systemImage: type.icon)
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: selectedChartType.icon)
                        .font(.system(size: 20))
                    Text("Chart")
                        .font(.caption2)
                }
                .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            // AI Features
            Button(action: { showAIFeatures.toggle() }) {
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(showAIFeatures ? themeManager.currentTheme.accentColor : themeManager.currentTheme.textColor)
                    Text("AI")
                        .font(.caption2)
                        .foregroundColor(showAIFeatures ? themeManager.currentTheme.accentColor : themeManager.currentTheme.textColor)
                }
            }
            
            // Indicators
            Button(action: { showingIndicators = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20))
                    Text("Indicators")
                        .font(.caption2)
                }
                .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            // Drawing Tools
            Button(action: { showingDrawingTools = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "pencil.tip")
                        .font(.system(size: 20))
                    Text("Draw")
                        .font(.caption2)
                }
                .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            Spacer()
            
            // Fullscreen
            Button(action: { isFullScreen = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 20))
                    Text("Expand")
                        .font(.caption2)
                }
                .foregroundColor(themeManager.currentTheme.textColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
    }
}

// MARK: - Full Screen Chart

struct FullScreenChartView: View {
    let symbol: String
    @Binding var selectedTimeframe: ChartTimeframe
    @Binding var selectedChartType: ChartType
    @Binding var selectedIndicators: Set<ChartIndicator>
    @Binding var isFullScreen: Bool
    @Binding var showAIFeatures: Bool
    @Binding var selectedAIFeatures: Set<AIChartFeature>
    @StateObject private var viewModel: ChartViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    init(symbol: String, selectedTimeframe: Binding<ChartTimeframe>, selectedChartType: Binding<ChartType>, selectedIndicators: Binding<Set<ChartIndicator>>, isFullScreen: Binding<Bool>, showAIFeatures: Binding<Bool>, selectedAIFeatures: Binding<Set<AIChartFeature>>) {
        self.symbol = symbol
        self._selectedTimeframe = selectedTimeframe
        self._selectedChartType = selectedChartType
        self._selectedIndicators = selectedIndicators
        self._isFullScreen = isFullScreen
        self._showAIFeatures = showAIFeatures
        self._selectedAIFeatures = selectedAIFeatures
        self._viewModel = StateObject(wrappedValue: ChartViewModel(symbol: symbol))
    }
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    ChartHeaderView(
                        symbol: symbol,
                        currentPrice: viewModel.currentPrice,
                        priceChange: viewModel.priceChange,
                        priceChangePercent: viewModel.priceChangePercent
                    )
                    
                    Button(action: {
                        isFullScreen = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    .padding()
                }
                
                // Chart in landscape
                ChartContentView(
                    candles: viewModel.candles,
                    chartType: selectedChartType,
                    indicators: selectedIndicators,
                    viewModel: viewModel,
                    aiAnalysis: showAIFeatures ? viewModel.aiAnalysis : nil,
                    selectedAIFeatures: selectedAIFeatures
                )
                .rotationEffect(.degrees(90))
                .frame(width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.width)
            }
        }
    }
}

// MARK: - Indicators Selection

struct IndicatorsSelectionView: View {
    @Binding var selectedIndicators: Set<ChartIndicator>
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                List {
                    ForEach(ChartIndicator.allCases, id: \.self) { indicator in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(indicator.name)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                                Text(indicator.description)
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            if selectedIndicators.contains(indicator) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.Theme.success)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedIndicators.contains(indicator) {
                                selectedIndicators.remove(indicator)
                            } else {
                                selectedIndicators.insert(indicator)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Indicators")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
    }
}

// MARK: - Drawing Tools

struct DrawingToolsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    let drawingTools = [
        ("Trend Line", "line.diagonal"),
        ("Horizontal Line", "minus"),
        ("Vertical Line", "line.vertical"),
        ("Fibonacci Retracement", "percent"),
        ("Rectangle", "rectangle"),
        ("Text", "textformat")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(drawingTools, id: \.0) { tool in
                            VStack(spacing: 8) {
                                Image(systemName: tool.1)
                                    .font(.title2)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                                    .frame(width: 60, height: 60)
                                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                                    .cornerRadius(12)
                                
                                Text(tool.0)
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                            }
                            .onTapGesture {
                                // Handle tool selection
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Drawing Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
    }
}

// MARK: - View Model

class ChartViewModel: ObservableObject {
    @Published var candles: [CandleData] = []
    @Published var currentPrice: Double = 0
    @Published var priceChange: Double = 0
    @Published var priceChangePercent: Double = 0
    @Published var isLoading = false
    
    // AI Analysis Properties
    @Published var aiAnalysis: AIChartAnalysis?
    private var aiAnalysisTimer: Timer?
    
    private let symbol: String
    private var cancellables = Set<AnyCancellable>()
    private var priceUpdateTimer: Timer?
    
    init(symbol: String) {
        self.symbol = symbol
        loadChartData()
        startPriceUpdates()
    }
    
    func changeTimeframe(to timeframe: ChartTimeframe) {
        loadChartData(timeframe: timeframe)
    }
    
    func startAIAnalysis() {
        aiAnalysisTimer?.invalidate()
        aiAnalysisTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.refreshAIAnalysis()
        }
    }
    
    func refreshAIAnalysis() {
        // In a real app, this would call an AI service to analyze the current candles
        // For now, we'll simulate a comprehensive analysis
        
        let currentPrice = self.currentPrice
        let highPrice = candles.map { $0.high }.max() ?? currentPrice
        let lowPrice = candles.map { $0.low }.min() ?? currentPrice
        
        // Generate support and resistance levels
        let supportLevels = [
            PriceLevel(price: currentPrice * 0.98, strength: 0.8, touches: 3, lastTested: Date()),
            PriceLevel(price: currentPrice * 0.96, strength: 0.6, touches: 2, lastTested: Date().addingTimeInterval(-3600)),
            PriceLevel(price: currentPrice * 0.94, strength: 0.4, touches: 1, lastTested: Date().addingTimeInterval(-7200))
        ]
        
        let resistanceLevels = [
            PriceLevel(price: currentPrice * 1.02, strength: 0.7, touches: 4, lastTested: Date()),
            PriceLevel(price: currentPrice * 1.04, strength: 0.5, touches: 2, lastTested: Date().addingTimeInterval(-1800)),
            PriceLevel(price: currentPrice * 1.06, strength: 0.3, touches: 1, lastTested: Date().addingTimeInterval(-5400))
        ]
        
        // Generate patterns
        let patterns = [
            ChartPattern(
                type: .triangle,
                startIndex: max(0, candles.count - 20),
                endIndex: candles.count - 1,
                confidence: 0.75,
                description: "Ascending triangle pattern detected"
            )
        ]
        
        // Generate AI signals
        let signals = [
            AISignal(
                type: .buy,
                price: currentPrice * 0.995,
                confidence: 0.82,
                reason: "Strong support level with bullish momentum",
                timestamp: Date()
            )
        ]
        
        // Generate risk zones
        let riskZones = [
            RiskZone(
                startPrice: currentPrice * 1.05,
                endPrice: currentPrice * 1.08,
                riskLevel: .high,
                reason: "Major resistance cluster"
            ),
            RiskZone(
                startPrice: currentPrice * 0.92,
                endPrice: currentPrice * 0.95,
                riskLevel: .medium,
                reason: "Potential support breakdown zone"
            )
        ]
        
        // Generate price prediction
        let prediction = PricePrediction(
            timeHorizon: 30,
            predictedPrice: currentPrice * 1.015,
            upperBound: currentPrice * 1.025,
            lowerBound: currentPrice * 1.005,
            confidence: 0.68
        )
        
        // Generate trend analysis
        let trendAnalysis = TrendAnalysis(
            shortTerm: .bullish,
            mediumTerm: .neutral,
            longTerm: .bullish,
            strength: 0.72,
            momentum: 0.65
        )
        
        // Generate market commentary
        let marketCommentary = """
        The \(symbol) pair is showing bullish momentum in the short term with price testing resistance at \(String(format: "%.5f", currentPrice * 1.02)). \
        Strong support has formed at \(String(format: "%.5f", currentPrice * 0.98)) with multiple successful tests. \
        An ascending triangle pattern suggests potential breakout above current levels. \
        Risk management recommended above \(String(format: "%.5f", currentPrice * 1.05)) due to major resistance cluster.
        """
        
        let analysis = AIChartAnalysis(
            patterns: patterns,
            supportLevels: supportLevels,
            resistanceLevels: resistanceLevels,
            predictions: prediction,
            riskZones: riskZones,
            signals: signals,
            trendAnalysis: trendAnalysis,
            marketCommentary: marketCommentary,
            timestamp: Date()
        )
        
        aiAnalysis = analysis
    }
    
    private func loadChartData(timeframe: ChartTimeframe = .h1) {
        isLoading = true
        
        // Generate mock candle data
        var mockCandles: [CandleData] = []
        let basePrice = 1.0850
        let now = Date()
        
        for i in 0..<100 {
            let timestamp = now.addingTimeInterval(-Double(i) * timeframe.interval)
            let randomChange = Double.random(in: -0.0010...0.0010)
            let open = basePrice + randomChange
            let close = open + Double.random(in: -0.0005...0.0005)
            let high = max(open, close) + Double.random(in: 0...0.0003)
            let low = min(open, close) - Double.random(in: 0...0.0003)
            let volume = Double.random(in: 1000...50000)
            
            mockCandles.append(CandleData(
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
        }
        
        candles = mockCandles.reversed()
        
        if let lastCandle = candles.last, let firstCandle = candles.first {
            currentPrice = lastCandle.close
            priceChange = lastCandle.close - firstCandle.close
            priceChangePercent = (priceChange / firstCandle.close) * 100
        }
        
        isLoading = false
    }
    
    private func startPriceUpdates() {
        priceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateCurrentPrice()
        }
    }
    
    private func updateCurrentPrice() {
        let randomChange = Double.random(in: -0.0001...0.0001)
        currentPrice += randomChange
        
        if let firstCandle = candles.first {
            priceChange = currentPrice - firstCandle.close
            priceChangePercent = (priceChange / firstCandle.close) * 100
        }
    }
    
    deinit {
        priceUpdateTimer?.invalidate()
        aiAnalysisTimer?.invalidate()
    }
}

// MARK: - Models

struct CandleData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

enum ChartTimeframe: String, CaseIterable {
    case m1 = "1M"
    case m5 = "5M"
    case m15 = "15M"
    case m30 = "30M"
    case h1 = "1H"
    case h4 = "4H"
    case d1 = "1D"
    case w1 = "1W"
    case mn = "1MN"
    
    var interval: TimeInterval {
        switch self {
        case .m1: return 60
        case .m5: return 300
        case .m15: return 900
        case .m30: return 1800
        case .h1: return 3600
        case .h4: return 14400
        case .d1: return 86400
        case .w1: return 604800
        case .mn: return 2592000
        }
    }
}

enum ChartType: String, CaseIterable {
    case candlestick = "Candlestick"
    case line = "Line"
    case bar = "Bar"
    case area = "Area"
    
    var name: String { rawValue }
    
    var icon: String {
        switch self {
        case .candlestick: return "chart.xyaxis.line"
        case .line: return "chart.line.uptrend.xyaxis"
        case .bar: return "chart.bar.fill"
        case .area: return "waveform.path.ecg"
        }
    }
}

enum ChartIndicator: String, CaseIterable {
    case sma = "SMA"
    case ema = "EMA"
    case macd = "MACD"
    case rsi = "RSI"
    case bollinger = "Bollinger Bands"
    case stochastic = "Stochastic"
    case atr = "ATR"
    case volume = "Volume"
    
    var name: String { rawValue }
    
    var description: String {
        switch self {
        case .sma: return "Simple Moving Average"
        case .ema: return "Exponential Moving Average"
        case .macd: return "Moving Average Convergence Divergence"
        case .rsi: return "Relative Strength Index"
        case .bollinger: return "Bollinger Bands"
        case .stochastic: return "Stochastic Oscillator"
        case .atr: return "Average True Range"
        case .volume: return "Volume Indicator"
        }
    }
}

#Preview {
    ChartView(symbol: "EURUSD")
        .environmentObject(ThemeManager.shared)
}