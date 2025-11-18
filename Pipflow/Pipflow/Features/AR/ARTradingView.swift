//
//  ARTradingView.swift
//  Pipflow
//
//  AR Trading visualization interface
//

import SwiftUI
import RealityKit
import ARKit

struct ARTradingView: View {
    @StateObject private var arService = ARTradingService.shared
    @State private var showSettings = false
    @State private var showSymbolPicker = false
    @State private var showHelp = false
    @State private var isRecording = false
    
    var body: some View {
        ZStack {
            // AR View
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
            
            // Overlay UI
            VStack {
                // Top Bar
                ARTopBar(
                    arService: arService,
                    showSettings: $showSettings,
                    showSymbolPicker: $showSymbolPicker,
                    showHelp: $showHelp
                )
                
                Spacer()
                
                // Bottom Controls
                ARBottomControls(
                    arService: arService,
                    isRecording: $isRecording
                )
            }
            .padding()
            
            // Session State Indicator
            if arService.sessionState != .tracking {
                ARSessionStateView(state: arService.sessionState)
            }
        }
        .sheet(isPresented: $showSettings) {
            ARSettingsView(settings: $arService.settings)
        }
        .sheet(isPresented: $showSymbolPicker) {
            ARSymbolPickerView(selectedSymbol: $arService.selectedSymbol)
        }
        .sheet(isPresented: $showHelp) {
            ARHelpView()
        }
    }
}

// MARK: - AR View Container
struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Start AR session
        ARTradingService.shared.startARSession(in: arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update AR view if needed
    }
}

// MARK: - Top Bar
struct ARTopBar: View {
    @ObservedObject var arService: ARTradingService
    @Binding var showSettings: Bool
    @Binding var showSymbolPicker: Bool
    @Binding var showHelp: Bool
    
    var body: some View {
        HStack {
            // Symbol Selector
            Button(action: { showSymbolPicker = true }) {
                HStack {
                    Text(arService.selectedSymbol)
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Chart Type
            HStack(spacing: 4) {
                ForEach(ARChartType.allCases, id: \.self) { type in
                    Button(action: { arService.settings.chartType = type }) {
                        Image(systemName: type.icon)
                            .font(.system(size: 20))
                            .foregroundColor(arService.settings.chartType == type ? .white : .gray)
                            .frame(width: 40, height: 40)
                            .background(
                                arService.settings.chartType == type ?
                                Color.Theme.accent : Color.clear
                            )
                            .cornerRadius(8)
                    }
                }
            }
            .padding(4)
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
            
            Spacer()
            
            // Settings & Help
            HStack(spacing: 12) {
                Button(action: { showHelp = true }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
        }
    }
}

// MARK: - Bottom Controls
struct ARBottomControls: View {
    @ObservedObject var arService: ARTradingService
    @Binding var isRecording: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Performance Metrics
            HStack {
                MetricBadge(
                    icon: "speedometer",
                    value: "\(arService.performanceMetrics.fps) FPS",
                    color: arService.performanceMetrics.fps >= 30 ? .green : .orange
                )
                
                MetricBadge(
                    icon: "antenna.radiowaves.left.and.right",
                    value: "Tracking",
                    color: arService.sessionState == .tracking ? .green : .orange
                )
                
                MetricBadge(
                    icon: "cube",
                    value: "\(arService.performanceMetrics.anchorCount)",
                    color: .blue
                )
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                // Reset
                Button(action: { arService.resetARSession() }) {
                    VStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                        Text("Reset")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
                
                // Record
                Button(action: { isRecording.toggle() }) {
                    VStack {
                        Image(systemName: isRecording ? "record.circle.fill" : "record.circle")
                            .font(.title2)
                            .foregroundColor(isRecording ? .red : .white)
                        Text("Record")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
                
                // Screenshot
                Button(action: captureScreenshot) {
                    VStack {
                        Image(systemName: "camera")
                            .font(.title2)
                        Text("Capture")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                }
                
                // Trade
                Button(action: showTradePanel) {
                    VStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title2)
                        Text("Trade")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.Theme.accent)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
        )
    }
    
    private func captureScreenshot() {
        // Capture AR screenshot
    }
    
    private func showTradePanel() {
        // Show trading panel
    }
}

// MARK: - Metric Badge
struct MetricBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Session State View
struct ARSessionStateView: View {
    let state: ARSessionState
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconForState)
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text(messageForState)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if case .limited(let reason) = state {
                Text(reasonMessage(for: reason))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
        )
        .padding()
    }
    
    private var iconForState: String {
        switch state {
        case .initializing:
            return "hourglass"
        case .ready:
            return "checkmark.circle"
        case .tracking:
            return "checkmark.circle.fill"
        case .limited:
            return "exclamationmark.triangle"
        case .failed:
            return "xmark.circle"
        }
    }
    
    private var messageForState: String {
        switch state {
        case .initializing:
            return "Initializing AR Session..."
        case .ready:
            return "Ready to Start"
        case .tracking:
            return "Tracking"
        case .limited:
            return "Limited Tracking"
        case .failed:
            return "AR Session Failed"
        }
    }
    
    private func reasonMessage(for reason: ARCamera.TrackingState.Reason) -> String {
        switch reason {
        case .excessiveMotion:
            return "Move slower for better tracking"
        case .insufficientFeatures:
            return "Point at an area with more detail"
        case .initializing:
            return "Initializing tracking..."
        case .relocalizing:
            return "Relocalizing..."
        @unknown default:
            return "Unknown tracking issue"
        }
    }
}

// MARK: - Settings View
struct ARSettingsView: View {
    @Binding var settings: ARVisualizationSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Visualization") {
                    Toggle("Show Grid", isOn: $settings.showGrid)
                    Toggle("Show Indicators", isOn: $settings.showIndicators)
                    
                    HStack {
                        Text("Animation Speed")
                        Slider(value: $settings.animationSpeed, in: 0.1...2.0)
                            .accentColor(Color.Theme.accent)
                    }
                    
                    HStack {
                        Text("Scale")
                        Slider(value: $settings.scale, in: 0.5...2.0)
                            .accentColor(Color.Theme.accent)
                    }
                    
                    HStack {
                        Text("Opacity")
                        Slider(value: $settings.opacity, in: 0.3...1.0)
                            .accentColor(Color.Theme.accent)
                    }
                }
                
                Section("Color Scheme") {
                    ForEach(ARColorScheme.allCases, id: \.self) { scheme in
                        HStack {
                            Text(scheme.rawValue)
                            Spacer()
                            if settings.colorScheme == scheme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.Theme.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settings.colorScheme = scheme
                        }
                    }
                }
                
                Section("Performance") {
                    Toggle("High Quality Mode", isOn: .constant(true))
                    Toggle("Enable Shadows", isOn: .constant(false))
                    Toggle("Environment Mapping", isOn: .constant(true))
                }
            }
            .navigationTitle("AR Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Symbol Picker
struct ARSymbolPickerView: View {
    @Binding var selectedSymbol: String
    @Environment(\.dismiss) var dismiss
    
    let symbols = ["EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCHF", "NZDUSD", "USDCAD"]
    
    var body: some View {
        NavigationView {
            List(symbols, id: \.self) { symbol in
                HStack {
                    Text(symbol)
                        .font(.headline)
                    Spacer()
                    if selectedSymbol == symbol {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color.Theme.accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSymbol = symbol
                    dismiss()
                }
            }
            .navigationTitle("Select Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Help View
struct ARHelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HelpSection(
                        title: "Getting Started",
                        icon: "hand.tap",
                        description: "Tap on any flat surface to place a trading chart in your space."
                    )
                    
                    HelpSection(
                        title: "Gestures",
                        icon: "hand.draw",
                        items: [
                            "Tap: Place chart",
                            "Pinch: Scale chart",
                            "Rotate: Turn chart",
                            "Long Press: Quick trade"
                        ]
                    )
                    
                    HelpSection(
                        title: "Chart Types",
                        icon: "chart.bar.xaxis",
                        items: [
                            "Candlestick: Traditional price chart",
                            "Line: Simple trend visualization",
                            "Volume: Trading volume bars",
                            "Heatmap: Market sentiment grid",
                            "3D Portfolio: Spatial portfolio view"
                        ]
                    )
                    
                    HelpSection(
                        title: "Tips",
                        icon: "lightbulb",
                        items: [
                            "Use in well-lit areas for best tracking",
                            "Place charts on stable surfaces",
                            "Adjust scale for comfortable viewing",
                            "Use record feature to save sessions"
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle("AR Trading Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct HelpSection: View {
    let title: String
    let icon: String
    var description: String? = nil
    var items: [String]? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color.Theme.accent)
                Text(title)
                    .font(.headline)
            }
            
            if let description = description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.text.opacity(0.8))
            }
            
            if let items = items {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Circle()
                                .fill(Color.Theme.accent)
                                .frame(width: 6, height: 6)
                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(Color.Theme.text.opacity(0.8))
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
    }
}

#Preview {
    ARTradingView()
}