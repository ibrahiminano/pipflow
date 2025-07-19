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
                                viewModel: viewModel
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(themeManager.currentTheme.backgroundColor)
                    
                    // Chart Tools Bar
                    ChartToolsBar(
                        selectedChartType: $selectedChartType,
                        showingIndicators: $showingIndicators,
                        showingDrawingTools: $showingDrawingTools,
                        isFullScreen: $isFullScreen
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
            .fullScreenCover(isPresented: $isFullScreen) {
                FullScreenChartView(
                    symbol: symbol,
                    selectedTimeframe: $selectedTimeframe,
                    selectedChartType: $selectedChartType,
                    selectedIndicators: $selectedIndicators,
                    isFullScreen: $isFullScreen
                )
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
    @ObservedObject var viewModel: ChartViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedCandle: CandleData?
    @State private var dragLocation: CGPoint?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main Chart
                Chart(candles) { candle in
                    switch chartType {
                    case .candlestick:
                        CandlestickMark(
                            x: .value("Time", candle.timestamp),
                            low: .value("Low", candle.low),
                            high: .value("High", candle.high),
                            open: .value("Open", candle.open),
                            close: .value("Close", candle.close)
                        )
                        .foregroundStyle(candle.close > candle.open ? Color.Theme.success : Color.Theme.error)
                        
                    case .line:
                        LineMark(
                            x: .value("Time", candle.timestamp),
                            y: .value("Price", candle.close)
                        )
                        .foregroundStyle(Color.Theme.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                    case .bar:
                        RectangleMark(
                            x: .value("Time", candle.timestamp),
                            yStart: .value("Low", candle.low),
                            yEnd: .value("High", candle.high)
                        )
                        .foregroundStyle(candle.close > candle.open ? Color.Theme.success : Color.Theme.error)
                        
                    case .area:
                        AreaMark(
                            x: .value("Time", candle.timestamp),
                            y: .value("Price", candle.close)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.Theme.accent.opacity(0.5), Color.Theme.accent.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        LineMark(
                            x: .value("Time", candle.timestamp),
                            y: .value("Price", candle.close)
                        )
                        .foregroundStyle(Color.Theme.accent)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(formatAxisDate(date))
                                    .font(.caption2)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(themeManager.currentTheme.separatorColor.opacity(0.3))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisValueLabel {
                            if let price = value.as(Double.self) {
                                Text(String(format: "%.5f", price))
                                    .font(.caption2)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(themeManager.currentTheme.separatorColor.opacity(0.3))
                    }
                }
                .frame(height: geometry.size.height)
                
                // Crosshair overlay
                if let location = dragLocation {
                    CrosshairView(location: location, geometry: geometry)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragLocation = value.location
                    }
                    .onEnded { _ in
                        dragLocation = nil
                    }
            )
        }
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 20) {
            // Chart Type
            Menu {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedChartType = type
                    }) {
                        Label(type.name, systemImage: type.icon)
                    }
                }
            } label: {
                Image(systemName: selectedChartType.icon)
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            // Indicators
            Button(action: {
                showingIndicators = true
            }) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            // Drawing Tools
            Button(action: {
                showingDrawingTools = true
            }) {
                Image(systemName: "pencil.tip")
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
            
            Spacer()
            
            // Fullscreen
            Button(action: {
                isFullScreen = true
            }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
    }
}

// MARK: - Full Screen Chart

struct FullScreenChartView: View {
    let symbol: String
    @Binding var selectedTimeframe: ChartTimeframe
    @Binding var selectedChartType: ChartType
    @Binding var selectedIndicators: Set<ChartIndicator>
    @Binding var isFullScreen: Bool
    @StateObject private var viewModel: ChartViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    init(symbol: String, selectedTimeframe: Binding<ChartTimeframe>, selectedChartType: Binding<ChartType>, selectedIndicators: Binding<Set<ChartIndicator>>, isFullScreen: Binding<Bool>) {
        self.symbol = symbol
        self._selectedTimeframe = selectedTimeframe
        self._selectedChartType = selectedChartType
        self._selectedIndicators = selectedIndicators
        self._isFullScreen = isFullScreen
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
                    viewModel: viewModel
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