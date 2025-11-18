//
//  ARTradingService.swift
//  Pipflow
//
//  Service for managing AR trading visualizations
//

import Foundation
import ARKit
import RealityKit
import Combine
import SwiftUI

@MainActor
class ARTradingService: NSObject, ObservableObject {
    static let shared = ARTradingService()
    
    // MARK: - Published Properties
    @Published var sessionState: ARSessionState = .initializing
    @Published var chartData: ARChartData?
    @Published var settings = ARVisualizationSettings()
    @Published var performanceMetrics = ARPerformanceMetrics(
        fps: 60,
        trackingQuality: 1.0,
        anchorCount: 0,
        meshVertexCount: 0,
        cpuUsage: 0,
        memoryUsage: 0
    )
    @Published var selectedSymbol: String = "EURUSD"
    @Published var isRecording = false
    @Published var activeAnchors: [ARAnchor] = []
    
    // MARK: - AR Components
    private var arView: ARView?
    private var chartAnchor: AnchorEntity?
    private var chartEntities: [Entity] = []
    private var indicatorEntities: [Entity] = []
    
    // MARK: - Services
    private let marketDataService = MarketDataService.shared
    private let tradingService = TradingService.shared
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    private override init() {
        super.init()
        setupSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Subscribe to market data updates
        marketDataService.$quotes
            .sink { [weak self] _ in
                self?.updateChartData()
            }
            .store(in: &cancellables)
        
        // Subscribe to settings changes
        $settings
            .sink { [weak self] _ in
                self?.updateVisualization()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - AR Session Management
    
    func startARSession(in arView: ARView) {
        self.arView = arView
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        arView.session.delegate = self
        arView.session.run(configuration)
        
        // Setup gestures
        setupGestures(for: arView)
        
        // Start update timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
        }
        
        sessionState = .ready
    }
    
    func pauseARSession() {
        arView?.session.pause()
        updateTimer?.invalidate()
    }
    
    func resetARSession() {
        chartEntities.forEach { $0.removeFromParent() }
        indicatorEntities.forEach { $0.removeFromParent() }
        chartEntities.removeAll()
        indicatorEntities.removeAll()
        chartAnchor = nil
        
        if let arView = arView {
            startARSession(in: arView)
        }
    }
    
    // MARK: - Chart Creation
    
    func createChart(at anchor: ARAnchor) {
        guard let arView = arView else { return }
        
        // Create anchor entity
        let anchorEntity = AnchorEntity(world: SIMD3<Float>(0, 0, -1))
        self.chartAnchor = anchorEntity
        
        // Load market data
        loadMarketData { [weak self] chartData in
            guard let self = self, let data = chartData else { return }
            
            self.chartData = data
            
            // Create chart based on type
            switch self.settings.chartType {
            case .candlestick:
                self.createCandlestickChart(data: data, at: anchorEntity)
            case .line:
                self.createLineChart(data: data, at: anchorEntity)
            case .volume:
                self.createVolumeChart(data: data, at: anchorEntity)
            case .heatmap:
                self.createHeatmapChart(data: data, at: anchorEntity)
            case .portfolio3D:
                self.createPortfolio3D(at: anchorEntity)
            }
            
            // Add to scene
            arView.scene.addAnchor(anchorEntity)
        }
    }
    
    private func createCandlestickChart(data: ARChartData, at anchor: AnchorEntity) {
        let chartWidth: Float = 0.3
        let chartHeight: Float = 0.2
        let candleWidth: Float = chartWidth / Float(min(data.candles.count, 50))
        
        // Calculate price range
        let prices = data.candles.flatMap { [$0.high, $0.low] }
        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 1
        let priceRange = maxPrice - minPrice
        
        // Create candles
        for (index, candle) in data.candles.suffix(50).enumerated() {
            let x = Float(index) * candleWidth - chartWidth / 2
            
            // Create candle body
            let bodyHeight = Float(abs(candle.close - candle.open) / priceRange) * chartHeight
            let bodyY = Float((max(candle.open, candle.close) - minPrice) / priceRange) * chartHeight
            
            let bodyMesh = MeshResource.generateBox(
                width: candleWidth * 0.8,
                height: max(bodyHeight, 0.001),
                depth: 0.01
            )
            
            let bodyColor = candle.close > candle.open ? 
                settings.colorScheme.bullishColor : 
                settings.colorScheme.bearishColor
            
            let bodyMaterial = SimpleMaterial(
                color: bodyColor,
                isMetallic: false
            )
            
            let bodyEntity = ModelEntity(mesh: bodyMesh, materials: [bodyMaterial])
            bodyEntity.position = SIMD3(x, bodyY - chartHeight / 2, 0)
            
            // Create wick
            let wickHeight = Float((candle.high - candle.low) / priceRange) * chartHeight
            let wickY = Float((candle.high - minPrice) / priceRange) * chartHeight
            
            let wickMesh = MeshResource.generateBox(
                width: candleWidth * 0.2,
                height: wickHeight,
                depth: 0.005
            )
            
            let wickEntity = ModelEntity(mesh: wickMesh, materials: [bodyMaterial])
            wickEntity.position = SIMD3(x, wickY - chartHeight / 2 - wickHeight / 2, 0)
            
            anchor.addChild(bodyEntity)
            anchor.addChild(wickEntity)
            
            chartEntities.append(bodyEntity)
            chartEntities.append(wickEntity)
        }
        
        // Add price labels
        addPriceLabels(minPrice: minPrice, maxPrice: maxPrice, at: anchor)
        
        // Add grid if enabled
        if settings.showGrid {
            addGrid(width: chartWidth, height: chartHeight, at: anchor)
        }
        
        // Add indicators if enabled
        if settings.showIndicators {
            addIndicators(data: data, at: anchor)
        }
    }
    
    private func createLineChart(data: ARChartData, at anchor: AnchorEntity) {
        // Implementation for line chart
        // Similar structure but using line segments instead of candles
    }
    
    private func createVolumeChart(data: ARChartData, at anchor: AnchorEntity) {
        // Implementation for volume chart
        // Bar chart showing trading volumes
    }
    
    private func createHeatmapChart(data: ARChartData, at anchor: AnchorEntity) {
        // Implementation for heatmap
        // Color-coded grid showing market sentiment
    }
    
    private func createPortfolio3D(at anchor: AnchorEntity) {
        // Create 3D visualization of portfolio
        let positions = PositionTrackingService.shared.trackedPositions
        let radius: Float = 0.2
        
        for (index, position) in positions.enumerated() {
            let angle = Float(index) * (2.0 * .pi / Float(positions.count))
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            
            // Create sphere for each position
            let size = Float(position.volume) * 0.05
            let mesh = MeshResource.generateSphere(radius: size)
            
            let color = position.unrealizedPL > 0 ? 
                settings.colorScheme.bullishColor : 
                settings.colorScheme.bearishColor
            
            let material = SimpleMaterial(color: color, isMetallic: true)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.position = SIMD3(x, 0, z)
            
            anchor.addChild(entity)
            chartEntities.append(entity)
            
            // Add symbol label
            // Note: Text in AR requires TextMesh which isn't available in RealityKit
            // Would need to create custom text geometry
        }
    }
    
    // MARK: - Helper Methods
    
    private func addPriceLabels(minPrice: Double, maxPrice: Double, at anchor: AnchorEntity) {
        // Add price level indicators
        // Note: Creating text in AR requires custom implementation
    }
    
    private func addGrid(width: Float, height: Float, at anchor: AnchorEntity) {
        let gridMaterial = SimpleMaterial(
            color: UIColor.gray.withAlphaComponent(0.3),
            isMetallic: false
        )
        
        // Horizontal lines
        for i in 0...5 {
            let y = Float(i) * height / 5 - height / 2
            let mesh = MeshResource.generateBox(
                width: width,
                height: 0.001,
                depth: 0.001
            )
            let entity = ModelEntity(mesh: mesh, materials: [gridMaterial])
            entity.position = SIMD3(0, y, -0.01)
            anchor.addChild(entity)
            chartEntities.append(entity)
        }
        
        // Vertical lines
        for i in 0...10 {
            let x = Float(i) * width / 10 - width / 2
            let mesh = MeshResource.generateBox(
                width: 0.001,
                height: height,
                depth: 0.001
            )
            let entity = ModelEntity(mesh: mesh, materials: [gridMaterial])
            entity.position = SIMD3(x, 0, -0.01)
            anchor.addChild(entity)
            chartEntities.append(entity)
        }
    }
    
    private func addIndicators(data: ARChartData, at anchor: AnchorEntity) {
        // Add technical indicators as overlays
        for indicator in data.indicators {
            // Create line visualization for indicator
        }
    }
    
    // MARK: - Gesture Handling
    
    private func setupGestures(for arView: ARView) {
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        arView.addGestureRecognizer(longPressGesture)
        
        // Pinch gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // Rotation gesture
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        
        let location = gesture.location(in: arView)
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
        
        if let firstResult = results.first {
            createChart(at: ARAnchor(transform: firstResult.worldTransform))
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        // Handle long press for trading actions
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let chartAnchor = chartAnchor else { return }
        
        if gesture.state == .changed {
            let scale = Float(gesture.scale)
            chartAnchor.scale *= SIMD3(repeating: scale)
            gesture.scale = 1.0
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let chartAnchor = chartAnchor else { return }
        
        if gesture.state == .changed {
            let rotation = Float(gesture.rotation)
            chartAnchor.orientation *= simd_quatf(angle: rotation, axis: SIMD3(0, 1, 0))
            gesture.rotation = 0
        }
    }
    
    // MARK: - Data Loading
    
    private func loadMarketData(completion: @escaping (ARChartData?) -> Void) {
        // Mock data for now
        let candles = (0..<50).map { i in
            let base = 1.1000 + Double(i) * 0.0001
            return ARCandle(
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                open: base,
                high: base + Double.random(in: 0...0.0010),
                low: base - Double.random(in: 0...0.0010),
                close: base + Double.random(in: -0.0005...0.0005),
                volume: Int.random(in: 1000...10000)
            )
        }
        
        let chartData = ARChartData(
            symbol: selectedSymbol,
            candles: candles,
            indicators: [],
            currentPrice: candles.first?.close ?? 0,
            change: 0.0012,
            changePercent: 0.11
        )
        
        completion(chartData)
    }
    
    private func updateChartData() {
        // Update chart with new market data
    }
    
    private func updateVisualization() {
        // Update visualization based on settings changes
    }
    
    private func updatePerformanceMetrics() {
        // Update performance metrics
        let anchorCount = arView?.scene.anchors.count ?? 0
        let fps = Int(arView?.renderOptions.contains(.disableMotionBlur) ?? false ? 60 : 30)
        
        performanceMetrics = ARPerformanceMetrics(
            fps: fps,
            trackingQuality: 1.0,
            anchorCount: anchorCount,
            meshVertexCount: 0,
            cpuUsage: 0,
            memoryUsage: 0
        )
    }
}

// MARK: - ARSessionDelegate
extension ARTradingService: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { @MainActor in
            // Update tracking state
            switch frame.camera.trackingState {
            case .normal:
                sessionState = .tracking
            case .limited(let reason):
                sessionState = .limited(reason: reason)
            case .notAvailable:
                sessionState = .initializing
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            sessionState = .failed(error: error)
        }
    }
}

// MARK: - AR Candle Model
struct ARCandle {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
}