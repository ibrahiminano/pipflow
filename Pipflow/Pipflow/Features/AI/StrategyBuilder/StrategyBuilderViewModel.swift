//
//  StrategyBuilderViewModel.swift
//  Pipflow
//
//  View model for visual strategy builder
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct StrategyConfig {
    let name: String
    let description: String
    let entryRules: [String]
    let exitRules: [String]
    let riskManagement: StrategyBuilderRiskManagement
    let timeframe: Timeframe
    let symbols: [String]
    let parameters: [String: Any]
}

struct StrategyBuilderRiskManagement {
    let maxRiskPerTrade: Double
    let maxDrawdown: Double
    let maxOpenPositions: Int
    let stopLossMultiplier: Double
    let takeProfitMultiplier: Double
    let useTrailingStop: Bool
}

enum ComponentType: String, Codable, CaseIterable {
    // Entry Conditions
    case priceAction = "Price Action"
    case indicator = "Indicator"
    case pattern = "Pattern"
    case time = "Time Filter"
    case news = "News Event"
    
    // Exit Conditions
    case stopLoss = "Stop Loss"
    case takeProfit = "Take Profit"
    case trailing = "Trailing Stop"
    case timeExit = "Time Exit"
    
    // Risk Management
    case positionSize = "Position Size"
    case maxDrawdown = "Max Drawdown"
    case maxPositions = "Max Positions"
    
    // Logic
    case and = "AND"
    case or = "OR"
    case not = "NOT"
}

struct StrategyComponent: Identifiable, Codable {
    let id: UUID
    let type: ComponentType
    var name: String
    var icon: String
    var position: CGPoint
    var properties: [String: Any] = [:]
    var inputs: [UUID] = []
    var outputs: [UUID] = []
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, icon, position, inputs, outputs
    }
    
    init(type: ComponentType, name: String, icon: String, position: CGPoint = CGPoint(x: 400, y: 300)) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.icon = icon
        self.position = position
    }
}

struct ComponentConnection: Identifiable, Codable {
    let id: UUID
    let fromComponent: UUID
    let toComponent: UUID
    let fromOutput: Int
    let toInput: Int
    
    init(fromComponent: UUID, toComponent: UUID, fromOutput: Int = 0, toInput: Int = 0) {
        self.id = UUID()
        self.fromComponent = fromComponent
        self.toComponent = toComponent
        self.fromOutput = fromOutput
        self.toInput = toInput
    }
}

struct SavedStrategy: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let components: [StrategyComponent]
    let connections: [ComponentConnection]
    let createdAt: Date
    let updatedAt: Date
    
    init(name: String, description: String, components: [StrategyComponent], connections: [ComponentConnection], createdAt: Date, updatedAt: Date) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.components = components
        self.connections = connections
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct StrategyTestResults: Identifiable {
    let id = UUID()
    let totalReturn: Double
    let winRate: Double
    let profitFactor: Double
    let maxDrawdown: Double
    let sharpeRatio: Double
    let totalTrades: Int
    let profitableTrades: Int
    let losingTrades: Int
    let averageWin: Double
    let averageLoss: Double
    let errors: [String]
    let warnings: [String]
}

// MARK: - View Model

@MainActor
class StrategyBuilderViewModel: ObservableObject {
    @Published var components: [StrategyComponent] = []
    @Published var connections: [ComponentConnection] = []
    @Published var savedStrategies: [SavedStrategy] = []
    @Published var testResults: StrategyTestResults?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let strategyOptimizer = StrategyOptimizer.shared
    private let backtestingEngine = BacktestingEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSavedStrategies()
    }
    
    // MARK: - Component Management
    
    func addComponent(_ type: ComponentType, at position: CGPoint) {
        let component = StrategyComponent(
            type: type,
            name: type.rawValue,
            icon: iconForType(type),
            position: position
        )
        components.append(component)
    }
    
    func removeComponent(_ component: StrategyComponent) {
        // Remove connections
        connections.removeAll { connection in
            connection.fromComponent == component.id || connection.toComponent == component.id
        }
        
        // Remove component
        components.removeAll { $0.id == component.id }
    }
    
    func moveComponent(_ component: StrategyComponent, by offset: CGSize) {
        if let index = components.firstIndex(where: { $0.id == component.id }) {
            components[index].position = CGPoint(
                x: component.position.x + offset.width,
                y: component.position.y + offset.height
            )
        }
    }
    
    func updateComponentProperties(_ component: StrategyComponent, properties: [String: Any]) {
        if let index = components.firstIndex(where: { $0.id == component.id }) {
            components[index].properties = properties
        }
    }
    
    // MARK: - Connection Management
    
    func addConnection(from: UUID, to: UUID, fromOutput: Int = 0, toInput: Int = 0) {
        // Validate connection
        guard from != to else { return }
        guard !connections.contains(where: { $0.fromComponent == from && $0.toComponent == to }) else { return }
        
        let connection = ComponentConnection(
            fromComponent: from,
            toComponent: to,
            fromOutput: fromOutput,
            toInput: toInput
        )
        connections.append(connection)
        
        // Update component connections
        if let fromIndex = components.firstIndex(where: { $0.id == from }) {
            components[fromIndex].outputs.append(to)
        }
        if let toIndex = components.firstIndex(where: { $0.id == to }) {
            components[toIndex].inputs.append(from)
        }
    }
    
    func removeConnection(_ connection: ComponentConnection) {
        connections.removeAll { $0.id == connection.id }
        
        // Update component connections
        if let fromIndex = components.firstIndex(where: { $0.id == connection.fromComponent }) {
            components[fromIndex].outputs.removeAll { $0 == connection.toComponent }
        }
        if let toIndex = components.firstIndex(where: { $0.id == connection.toComponent }) {
            components[toIndex].inputs.removeAll { $0 == connection.fromComponent }
        }
    }
    
    // MARK: - Strategy Management
    
    func saveStrategy(name: String, description: String) {
        let strategy = SavedStrategy(
            name: name,
            description: description,
            components: components,
            connections: connections,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        savedStrategies.append(strategy)
        saveToDisk()
    }
    
    func loadStrategy(_ strategy: SavedStrategy) {
        components = strategy.components
        connections = strategy.connections
    }
    
    func deleteStrategy(_ strategy: SavedStrategy) {
        savedStrategies.removeAll { $0.id == strategy.id }
        saveToDisk()
    }
    
    // MARK: - Testing
    
    func testStrategy(completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        Task {
            do {
                // Convert visual strategy to code
                let strategyCode = generateStrategyCode()
                
                // Create strategy config
                let riskMgmt = parseRiskManagement()
                
                // Convert to TradingStrategy for BacktestingEngine
                let strategy = TradingStrategy(
                    name: "Visual Strategy Test",
                    description: "Testing visual strategy",
                    conditions: [], // TODO: Convert components to conditions
                    riskManagement: RiskManagement(
                        stopLossPercent: riskMgmt.stopLossMultiplier,
                        takeProfitPercent: riskMgmt.takeProfitMultiplier,
                        positionSizePercent: riskMgmt.maxRiskPerTrade,
                        maxOpenTrades: riskMgmt.maxOpenPositions,
                        maxDailyLoss: 5.0,
                        maxDrawdown: riskMgmt.maxDrawdown
                    ),
                    timeframe: .h1
                )
                
                // Create backtest request
                let request = BacktestRequest(
                    strategy: strategy,
                    symbol: "EURUSD", // Use first symbol for now
                    startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
                    endDate: Date(),
                    initialCapital: 10000,
                    riskPerTrade: riskMgmt.maxRiskPerTrade,
                    commission: 0.001,
                    spread: 0.0001
                )
                
                // Run backtest
                let results = try await backtestingEngine.runBacktest(request)
                
                // Convert to test results
                testResults = StrategyTestResults(
                    totalReturn: results.performance.totalReturn,
                    winRate: results.performance.winRate * 100,
                    profitFactor: results.performance.profitFactor,
                    maxDrawdown: results.performance.maxDrawdown,
                    sharpeRatio: results.performance.sharpeRatio,
                    totalTrades: results.performance.numberOfTrades,
                    profitableTrades: Int(Double(results.performance.numberOfTrades) * results.performance.winRate),
                    losingTrades: Int(Double(results.performance.numberOfTrades) * (1 - results.performance.winRate)),
                    averageWin: results.performance.averageWin,
                    averageLoss: results.performance.averageLoss,
                    errors: validateStrategy(),
                    warnings: getStrategyWarnings()
                )
                
                isLoading = false
                completion(true)
            } catch {
                self.error = error
                isLoading = false
                completion(false)
            }
        }
    }
    
    // MARK: - Code Generation
    
    private func generateStrategyCode() -> String {
        var code = """
        // Generated Strategy Code
        class VisualStrategy: TradingStrategy {
            
            func shouldEnter(market: MarketData) -> Bool {
        """
        
        // Generate entry logic
        let entryComponents = components.filter { isEntryComponent($0.type) }
        code += generateLogicCode(for: entryComponents)
        
        code += """
            }
            
            func shouldExit(market: MarketData, position: Position) -> Bool {
        """
        
        // Generate exit logic
        let exitComponents = components.filter { isExitComponent($0.type) }
        code += generateLogicCode(for: exitComponents)
        
        code += """
            }
        }
        """
        
        return code
    }
    
    private func generateLogicCode(for components: [StrategyComponent]) -> String {
        // Simplified code generation
        return """
                // TODO: Implement logic based on components
                return true
        """
    }
    
    // MARK: - Parsing Methods
    
    private func parseEntryRules() -> [String] {
        components
            .filter { isEntryComponent($0.type) }
            .map { component in
                switch component.type {
                case .priceAction:
                    return "Price \(component.properties["condition"] ?? "above") \(component.properties["value"] ?? 0)"
                case .indicator:
                    return "\(component.properties["type"] ?? "RSI") signal"
                case .pattern:
                    return "\(component.properties["patternType"] ?? "Pattern") detected"
                default:
                    return component.name
                }
            }
    }
    
    private func parseExitRules() -> [String] {
        components
            .filter { isExitComponent($0.type) }
            .map { component in
                switch component.type {
                case .stopLoss:
                    return "Stop loss at \(component.properties["value"] ?? 50) pips"
                case .takeProfit:
                    return "Take profit at \(component.properties["value"] ?? 100) pips"
                case .trailing:
                    return "Trailing stop"
                default:
                    return component.name
                }
            }
    }
    
    private func parseRiskManagement() -> StrategyBuilderRiskManagement {
        let riskComponents = components.filter { isRiskComponent($0.type) }
        
        var riskPerTrade = 0.01
        var maxDrawdown = 0.1
        var maxPositions = 3
        
        for component in riskComponents {
            switch component.type {
            case .positionSize:
                if let risk = component.properties["riskPercent"] as? Double {
                    riskPerTrade = risk / 100
                }
            case .maxDrawdown:
                if let dd = component.properties["maxDrawdown"] as? Double {
                    maxDrawdown = dd / 100
                }
            case .maxPositions:
                if let positions = component.properties["maxPositions"] as? Int {
                    maxPositions = positions
                }
            default:
                break
            }
        }
        
        return StrategyBuilderRiskManagement(
            maxRiskPerTrade: riskPerTrade,
            maxDrawdown: maxDrawdown,
            maxOpenPositions: maxPositions,
            stopLossMultiplier: 1.0,
            takeProfitMultiplier: 2.0,
            useTrailingStop: components.contains { $0.type == .trailing }
        )
    }
    
    // MARK: - Validation
    
    private func validateStrategy() -> [String] {
        var errors: [String] = []
        
        // Check for entry conditions
        if !components.contains(where: { isEntryComponent($0.type) }) {
            errors.append("No entry conditions defined")
        }
        
        // Check for exit conditions
        if !components.contains(where: { isExitComponent($0.type) }) {
            errors.append("No exit conditions defined")
        }
        
        // Check for risk management
        if !components.contains(where: { isRiskComponent($0.type) }) {
            errors.append("No risk management rules defined")
        }
        
        // Check for disconnected components
        let connectedComponents = Set(connections.flatMap { [$0.fromComponent, $0.toComponent] })
        let allComponents = Set(components.map { $0.id })
        let disconnected = allComponents.subtracting(connectedComponents)
        
        if !disconnected.isEmpty && components.count > 1 {
            errors.append("\(disconnected.count) component(s) are not connected")
        }
        
        return errors
    }
    
    private func getStrategyWarnings() -> [String] {
        var warnings: [String] = []
        
        // Check for high risk
        if let riskComponent = components.first(where: { $0.type == .positionSize }),
           let risk = riskComponent.properties["riskPercent"] as? Double,
           risk > 2.0 {
            warnings.append("High risk per trade: \(risk)%")
        }
        
        // Check for missing stop loss
        if !components.contains(where: { $0.type == .stopLoss }) {
            warnings.append("No stop loss defined - high risk strategy")
        }
        
        return warnings
    }
    
    // MARK: - Helper Methods
    
    private func iconForType(_ type: ComponentType) -> String {
        switch type {
        case .priceAction: return "chart.line.uptrend.xyaxis"
        case .indicator: return "waveform.path.ecg"
        case .pattern: return "circle.grid.3x3"
        case .time: return "clock"
        case .news: return "newspaper"
        case .stopLoss: return "stop.circle"
        case .takeProfit: return "checkmark.circle"
        case .trailing: return "arrow.triangle.2.circlepath"
        case .timeExit: return "timer"
        case .positionSize: return "percent"
        case .maxDrawdown: return "arrow.down.to.line"
        case .maxPositions: return "number.circle"
        case .and: return "arrow.triangle.merge"
        case .or: return "arrow.triangle.branch"
        case .not: return "exclamationmark.circle"
        }
    }
    
    private func isEntryComponent(_ type: ComponentType) -> Bool {
        switch type {
        case .priceAction, .indicator, .pattern, .time, .news:
            return true
        default:
            return false
        }
    }
    
    private func isExitComponent(_ type: ComponentType) -> Bool {
        switch type {
        case .stopLoss, .takeProfit, .trailing, .timeExit:
            return true
        default:
            return false
        }
    }
    
    private func isRiskComponent(_ type: ComponentType) -> Bool {
        switch type {
        case .positionSize, .maxDrawdown, .maxPositions:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Persistence
    
    private func loadSavedStrategies() {
        // In production, load from CoreData or file system
        // For now, create some sample strategies
        savedStrategies = [
            SavedStrategy(
                name: "RSI Oversold Strategy",
                description: "Buy when RSI < 30, sell when RSI > 70",
                components: [],
                connections: [],
                createdAt: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-2 * 24 * 60 * 60)
            ),
            SavedStrategy(
                name: "Moving Average Crossover",
                description: "Classic MA crossover with risk management",
                components: [],
                connections: [],
                createdAt: Date().addingTimeInterval(-14 * 24 * 60 * 60),
                updatedAt: Date().addingTimeInterval(-5 * 24 * 60 * 60)
            )
        ]
    }
    
    private func saveToDisk() {
        // In production, save to CoreData or file system
        print("Saving strategies to disk...")
    }
}