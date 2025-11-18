//
//  ContextManager.swift
//  Pipflow
//
//  Context storage and management for AI Prompt Trading
//

import Foundation
import Combine
import SwiftUI

// MARK: - Context Storage Models

struct StoredContext: Codable {
    let promptId: String
    let userId: String
    let context: TradingContext
    let createdDate: Date
    let lastAccessed: Date
    let version: Int
    
    init(promptId: String, userId: String, context: TradingContext) {
        self.promptId = promptId
        self.userId = userId
        self.context = context
        self.createdDate = Date()
        self.lastAccessed = Date()
        self.version = 1
    }
}

struct ContextVersion: Codable {
    let id: String
    let promptId: String
    let context: TradingContext
    let createdDate: Date
    let performanceSnapshot: PromptPerformance?
    let version: Int
    let changeDescription: String
}

// MARK: - Context Manager

@MainActor
class ContextManager: ObservableObject {
    static let shared = ContextManager()
    
    @Published var contexts: [String: StoredContext] = [:]
    @Published var contextVersions: [String: [ContextVersion]] = [:]
    @Published var recentlyAccessed: [StoredContext] = []
    
    private let storage = ContextStorage()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadContexts()
        setupAutoSave()
    }
    
    // MARK: - Context Management
    
    func storeContext(for promptId: String, context: TradingContext, userId: String = "current_user") async {
        let storedContext = StoredContext(promptId: promptId, userId: userId, context: context)
        contexts[promptId] = storedContext
        
        // Create version history entry
        let version = ContextVersion(
            id: UUID().uuidString,
            promptId: promptId,
            context: context,
            createdDate: Date(),
            performanceSnapshot: nil,
            version: 1,
            changeDescription: "Initial context creation"
        )
        
        if contextVersions[promptId] == nil {
            contextVersions[promptId] = []
        }
        contextVersions[promptId]?.append(version)
        
        await storage.saveContext(storedContext)
        updateRecentlyAccessed(storedContext)
        
        print("💾 Stored context for prompt: \(promptId)")
    }
    
    func getContext(for promptId: String) async -> TradingContext? {
        guard let storedContext = contexts[promptId] else {
            // Try loading from storage
            if let loaded = await storage.loadContext(for: promptId) {
                contexts[promptId] = loaded
                updateRecentlyAccessed(loaded)
                return loaded.context
            }
            return nil
        }
        
        // Update last accessed time
        var updatedContext = storedContext
        updatedContext = StoredContext(
            promptId: storedContext.promptId,
            userId: storedContext.userId,
            context: storedContext.context
        )
        contexts[promptId] = updatedContext
        updateRecentlyAccessed(updatedContext)
        
        return storedContext.context
    }
    
    func updateContext(for promptId: String, context: TradingContext, changeDescription: String = "Context updated") async {
        guard let existing = contexts[promptId] else {
            print("❌ Cannot update context: prompt not found")
            return
        }
        
        // Create new version
        let currentVersions = contextVersions[promptId] ?? []
        let newVersionNumber = (currentVersions.last?.version ?? 0) + 1
        
        let newVersion = ContextVersion(
            id: UUID().uuidString,
            promptId: promptId,
            context: context,
            createdDate: Date(),
            performanceSnapshot: PromptTradingEngine.shared.getPromptPerformance(for: promptId),
            version: newVersionNumber,
            changeDescription: changeDescription
        )
        
        // Store version history
        if contextVersions[promptId] == nil {
            contextVersions[promptId] = []
        }
        contextVersions[promptId]?.append(newVersion)
        
        // Keep only last 10 versions
        if let versions = contextVersions[promptId], versions.count > 10 {
            contextVersions[promptId] = Array(versions.suffix(10))
        }
        
        // Update main context
        let updatedContext = StoredContext(promptId: promptId, userId: existing.userId, context: context)
        contexts[promptId] = updatedContext
        
        await storage.saveContext(updatedContext)
        print("🔄 Updated context for prompt: \(promptId) - \(changeDescription)")
    }
    
    func removeContext(for promptId: String) async {
        contexts.removeValue(forKey: promptId)
        contextVersions.removeValue(forKey: promptId)
        recentlyAccessed.removeAll { $0.promptId == promptId }
        
        await storage.deleteContext(for: promptId)
        print("🗑️ Removed context for prompt: \(promptId)")
    }
    
    func duplicateContext(from sourcePromptId: String, to newPromptId: String, userId: String = "current_user") async -> Bool {
        guard let sourceContext = await getContext(for: sourcePromptId) else {
            print("❌ Cannot duplicate context: source not found")
            return false
        }
        
        await storeContext(for: newPromptId, context: sourceContext, userId: userId)
        print("📋 Duplicated context from \(sourcePromptId) to \(newPromptId)")
        return true
    }
    
    // MARK: - Context History & Versioning
    
    func getContextHistory(for promptId: String) -> [ContextVersion] {
        return contextVersions[promptId] ?? []
    }
    
    func revertToVersion(promptId: String, version: Int) async -> Bool {
        guard let versions = contextVersions[promptId],
              let targetVersion = versions.first(where: { $0.version == version }) else {
            print("❌ Cannot revert: version not found")
            return false
        }
        
        await updateContext(
            for: promptId,
            context: targetVersion.context,
            changeDescription: "Reverted to version \(version)"
        )
        
        print("⏪ Reverted context to version \(version) for prompt: \(promptId)")
        return true
    }
    
    func compareVersions(promptId: String, version1: Int, version2: Int) -> ContextComparison? {
        guard let versions = contextVersions[promptId],
              let v1 = versions.first(where: { $0.version == version1 }),
              let v2 = versions.first(where: { $0.version == version2 }) else {
            return nil
        }
        
        return ContextComparison(version1: v1, version2: v2)
    }
    
    // MARK: - Context Analysis & Optimization
    
    func analyzeContextPerformance(for promptId: String) -> ContextAnalysis? {
        guard let versions = contextVersions[promptId] else { return nil }
        
        let versionsWithPerformance = versions.compactMap { version -> (ContextVersion, PromptPerformance)? in
            guard let performance = version.performanceSnapshot else { return nil }
            return (version, performance)
        }
        
        guard !versionsWithPerformance.isEmpty else { return nil }
        
        let bestPerforming = versionsWithPerformance.max { v1, v2 in
            v1.1.totalProfitLoss < v2.1.totalProfitLoss
        }
        
        let worstPerforming = versionsWithPerformance.min { v1, v2 in
            v1.1.totalProfitLoss < v2.1.totalProfitLoss
        }
        
        return ContextAnalysis(
            promptId: promptId,
            totalVersions: versions.count,
            bestPerformingVersion: bestPerforming?.0,
            worstPerformingVersion: worstPerforming?.0,
            averageWinRate: versionsWithPerformance.map { $0.1.winRate }.reduce(0, +) / Double(versionsWithPerformance.count),
            recommendations: generateRecommendations(from: versionsWithPerformance)
        )
    }
    
    func generateOptimizedContext(from promptId: String) async -> TradingContext? {
        guard let analysis = analyzeContextPerformance(for: promptId),
              let bestVersion = analysis.bestPerformingVersion else {
            return nil
        }
        
        // Create optimized context based on best performing version
        var optimizedContext = bestVersion.context
        
        // Apply optimization logic
        optimizedContext = applyOptimizations(to: optimizedContext, based: analysis)
        
        return optimizedContext
    }
    
    // MARK: - Context Templates & Presets
    
    func saveAsTemplate(promptId: String, templateName: String, description: String) async -> ContextTemplate? {
        guard let context = await getContext(for: promptId) else { return nil }
        
        let template = ContextTemplate(
            id: UUID().uuidString,
            name: templateName,
            description: description,
            context: context,
            category: categorizeContext(context),
            tags: generateTags(for: context),
            createdDate: Date(),
            usageCount: 0
        )
        
        await storage.saveTemplate(template)
        print("📋 Saved context template: \(templateName)")
        return template
    }
    
    func loadTemplate(_ templateId: String, for promptId: String) async -> Bool {
        guard let template = await storage.loadTemplate(templateId) else {
            print("❌ Template not found: \(templateId)")
            return false
        }
        
        await storeContext(for: promptId, context: template.context)
        
        // Update template usage count
        var updatedTemplate = template
        updatedTemplate.usageCount += 1
        await storage.saveTemplate(updatedTemplate)
        
        print("📥 Loaded template '\(template.name)' for prompt: \(promptId)")
        return true
    }
    
    // MARK: - Context Search & Discovery
    
    func searchContexts(query: String, userId: String? = nil) -> [StoredContext] {
        let filteredContexts = contexts.values.filter { context in
            if let userId = userId, context.userId != userId { return false }
            
            return context.promptId.localizedCaseInsensitiveContains(query) ||
                   context.context.allowedSymbols.contains { $0.localizedCaseInsensitiveContains(query) }
        }
        
        return Array(filteredContexts).sorted { $0.lastAccessed > $1.lastAccessed }
    }
    
    func getContextsByCategory(_ category: ContextCategory) -> [StoredContext] {
        return contexts.values.filter { context in
            categorizeContext(context.context) == category
        }.sorted { $0.lastAccessed > $1.lastAccessed }
    }
    
    func getContextStatistics() -> ContextStatistics {
        let allContexts = Array(contexts.values)
        
        return ContextStatistics(
            totalContexts: allContexts.count,
            activeContexts: allContexts.filter { isContextActive($0.promptId) }.count,
            avgContextAge: calculateAverageAge(contexts: allContexts),
            mostUsedSymbols: getMostUsedSymbols(contexts: allContexts),
            performanceDistribution: getPerformanceDistribution()
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func loadContexts() {
        Task {
            let loadedContexts = await storage.loadAllContexts()
            await MainActor.run {
                for context in loadedContexts {
                    contexts[context.promptId] = context
                }
                recentlyAccessed = Array(loadedContexts.prefix(10).sorted { $0.lastAccessed > $1.lastAccessed })
            }
        }
    }
    
    private func setupAutoSave() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.saveAllContexts() }
            }
            .store(in: &cancellables)
    }
    
    private func saveAllContexts() async {
        for context in contexts.values {
            await storage.saveContext(context)
        }
    }
    
    private func updateRecentlyAccessed(_ context: StoredContext) {
        recentlyAccessed.removeAll { $0.promptId == context.promptId }
        recentlyAccessed.insert(context, at: 0)
        recentlyAccessed = Array(recentlyAccessed.prefix(10))
    }
    
    private func generateRecommendations(from versionsWithPerformance: [(ContextVersion, PromptPerformance)]) -> [String] {
        var recommendations: [String] = []
        
        // Analyze patterns in successful versions
        let successfulVersions = versionsWithPerformance.filter { $0.1.winRate > 0.6 }
        
        if successfulVersions.count > 1 {
            recommendations.append("Consider using indicators from your most successful trading periods")
        }
        
        if versionsWithPerformance.map({ $0.1.maxDrawdown }).max() ?? 0 > 0.2 {
            recommendations.append("Consider tightening risk management parameters")
        }
        
        return recommendations
    }
    
    private func applyOptimizations(to context: TradingContext, based analysis: ContextAnalysis) -> TradingContext {
        // Apply optimization logic based on analysis
        let adjustedRiskPerTrade = analysis.averageWinRate < 0.5 
            ? min(context.riskPerTrade * 0.8, 0.01) 
            : context.riskPerTrade
        
        // Create new context with optimized values
        return TradingContext(
            capital: context.capital,
            riskPerTrade: adjustedRiskPerTrade,
            maxOpenTrades: context.maxOpenTrades,
            allowedSymbols: context.allowedSymbols,
            excludedSymbols: context.excludedSymbols,
            timeRestrictions: context.timeRestrictions,
            indicators: context.indicators,
            conditions: context.conditions,
            stopLossStrategy: context.stopLossStrategy,
            takeProfitStrategy: context.takeProfitStrategy
        )
    }
    
    private func categorizeContext(_ context: TradingContext) -> ContextCategory {
        if context.indicators.contains(where: { $0.type == .rsi || $0.type == .stochastic }) {
            return .oscillatorBased
        } else if context.indicators.contains(where: { $0.type == .movingAverage }) {
            return .trendFollowing
        } else if context.riskPerTrade > 0.05 {
            return .aggressive
        } else {
            return .conservative
        }
    }
    
    private func generateTags(for context: TradingContext) -> [String] {
        var tags: [String] = []
        
        if context.riskPerTrade <= 0.01 { tags.append("low-risk") }
        if context.riskPerTrade >= 0.05 { tags.append("high-risk") }
        if context.maxOpenTrades <= 3 { tags.append("conservative") }
        if context.indicators.count > 3 { tags.append("technical") }
        if !context.allowedSymbols.isEmpty { tags.append("symbol-specific") }
        
        return tags
    }
    
    private func isContextActive(_ promptId: String) -> Bool {
        return PromptTradingEngine.shared.activePrompts.contains { $0.id == promptId && $0.isActive }
    }
    
    private func calculateAverageAge(contexts: [StoredContext]) -> TimeInterval {
        guard !contexts.isEmpty else { return 0 }
        let totalAge = contexts.map { Date().timeIntervalSince($0.createdDate) }.reduce(0, +)
        return totalAge / Double(contexts.count)
    }
    
    private func getMostUsedSymbols(contexts: [StoredContext]) -> [String] {
        let allSymbols = contexts.flatMap { $0.context.allowedSymbols }
        let symbolCounts = Dictionary(grouping: allSymbols, by: { $0 }).mapValues { $0.count }
        return symbolCounts.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    private func getPerformanceDistribution() -> [String: Int] {
        // This would analyze performance across all contexts
        return ["profitable": 0, "breakeven": 0, "losing": 0]
    }
}

// MARK: - Supporting Models

struct ContextComparison {
    let version1: ContextVersion
    let version2: ContextVersion
    
    var differences: [String] {
        var diffs: [String] = []
        
        if version1.context.capital != version2.context.capital {
            diffs.append("Capital changed from \(version1.context.capital) to \(version2.context.capital)")
        }
        
        if version1.context.riskPerTrade != version2.context.riskPerTrade {
            diffs.append("Risk per trade changed from \(version1.context.riskPerTrade * 100)% to \(version2.context.riskPerTrade * 100)%")
        }
        
        return diffs
    }
}

struct ContextAnalysis {
    let promptId: String
    let totalVersions: Int
    let bestPerformingVersion: ContextVersion?
    let worstPerformingVersion: ContextVersion?
    let averageWinRate: Double
    let recommendations: [String]
}

struct ContextTemplate: Codable {
    let id: String
    let name: String
    let description: String
    let context: TradingContext
    let category: ContextCategory
    let tags: [String]
    let createdDate: Date
    var usageCount: Int
}

enum ContextCategory: String, Codable, CaseIterable {
    case conservative = "Conservative"
    case aggressive = "Aggressive"
    case trendFollowing = "Trend Following"
    case oscillatorBased = "Oscillator Based"
    case scalping = "Scalping"
    case swingTrading = "Swing Trading"
    case custom = "Custom"
}

struct ContextStatistics {
    let totalContexts: Int
    let activeContexts: Int
    let avgContextAge: TimeInterval
    let mostUsedSymbols: [String]
    let performanceDistribution: [String: Int]
}

// MARK: - Context Storage (Persistent Storage)

class ContextStorage {
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let contextsDirectory: URL
    private let templatesDirectory: URL
    
    init() {
        contextsDirectory = documentsPath.appendingPathComponent("PromptContexts")
        templatesDirectory = documentsPath.appendingPathComponent("ContextTemplates")
        
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(at: contextsDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: templatesDirectory, withIntermediateDirectories: true)
    }
    
    func saveContext(_ context: StoredContext) async {
        let fileURL = contextsDirectory.appendingPathComponent("\(context.promptId).json")
        
        do {
            let data = try JSONEncoder().encode(context)
            try data.write(to: fileURL)
        } catch {
            print("❌ Failed to save context: \(error)")
        }
    }
    
    func loadContext(for promptId: String) async -> StoredContext? {
        let fileURL = contextsDirectory.appendingPathComponent("\(promptId).json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(StoredContext.self, from: data)
        } catch {
            print("❌ Failed to load context: \(error)")
            return nil
        }
    }
    
    func loadAllContexts() async -> [StoredContext] {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: contextsDirectory, includingPropertiesForKeys: nil)
            var contexts: [StoredContext] = []
            
            for file in files where file.pathExtension == "json" {
                if let data = try? Data(contentsOf: file),
                   let context = try? JSONDecoder().decode(StoredContext.self, from: data) {
                    contexts.append(context)
                }
            }
            
            return contexts
        } catch {
            print("❌ Failed to load contexts: \(error)")
            return []
        }
    }
    
    func deleteContext(for promptId: String) async {
        let fileURL = contextsDirectory.appendingPathComponent("\(promptId).json")
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func saveTemplate(_ template: ContextTemplate) async {
        let fileURL = templatesDirectory.appendingPathComponent("\(template.id).json")
        
        do {
            let data = try JSONEncoder().encode(template)
            try data.write(to: fileURL)
        } catch {
            print("❌ Failed to save template: \(error)")
        }
    }
    
    func loadTemplate(_ templateId: String) async -> ContextTemplate? {
        let fileURL = templatesDirectory.appendingPathComponent("\(templateId).json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(ContextTemplate.self, from: data)
        } catch {
            print("❌ Failed to load template: \(error)")
            return nil
        }
    }
}