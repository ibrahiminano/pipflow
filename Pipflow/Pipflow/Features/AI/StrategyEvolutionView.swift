//
//  StrategyEvolutionView.swift
//  Pipflow
//
//  Strategy evolution tracking and visualization
//

import SwiftUI
import Charts

struct StrategyEvolutionView: View {
    let history: [StrategyEvolution]
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedStrategy: String?
    @State private var showingDetails = false
    
    private var groupedHistory: [String: [StrategyEvolution]] {
        Dictionary(grouping: history) { $0.strategyId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Strategy Evolution")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showingDetails = true }) {
                    Label("Details", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            
            // Evolution Timeline
            if let selectedId = selectedStrategy,
               let evolutions = groupedHistory[selectedId] {
                EvolutionTimeline(evolutions: evolutions)
                    .frame(height: 200)
                    .padding(.vertical)
            } else {
                // Strategy Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(groupedHistory.keys), id: \.self) { strategyId in
                            EvolutionStrategyCard(
                                strategyId: strategyId,
                                evolutions: groupedHistory[strategyId] ?? [],
                                isSelected: selectedStrategy == strategyId,
                                action: {
                                    withAnimation {
                                        selectedStrategy = strategyId
                                    }
                                }
                            )
                        }
                    }
                }
            }
            
            // Recent Changes
            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Changes")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    ForEach(history.prefix(3)) { evolution in
                        EvolutionChangeCard(evolution: evolution)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetails) {
            EvolutionDetailsView(history: history)
        }
    }
}

struct EvolutionTimeline: View {
    let evolutions: [StrategyEvolution]
    @EnvironmentObject var themeManager: ThemeManager
    
    private var performanceData: [PerformancePoint] {
        var cumulativePerformance = 0.0
        return evolutions.enumerated().map { index, evolution in
            cumulativePerformance += evolution.performanceChange
            return PerformancePoint(
                date: evolution.timestamp,
                performance: cumulativePerformance,
                version: evolution.version
            )
        }
    }
    
    var body: some View {
        Chart(performanceData) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Performance", point.performance)
            )
            .foregroundStyle(themeManager.currentTheme.accentColor)
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Date", point.date),
                y: .value("Performance", point.performance)
            )
            .foregroundStyle(themeManager.currentTheme.accentColor)
            .symbolSize(100)
            .annotation(position: .top) {
                Text("v\(point.version)")
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let value = value.as(Double.self) {
                        Text("\(Int(value * 100))%")
                    }
                }
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .foregroundStyle(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    struct PerformancePoint: Identifiable {
        let id = UUID()
        let date: Date
        let performance: Double
        let version: Int
    }
}

struct EvolutionStrategyCard: View {
    let strategyId: String
    let evolutions: [StrategyEvolution]
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    private var latestVersion: Int {
        evolutions.map { $0.version }.max() ?? 1
    }
    
    private var totalPerformanceChange: Double {
        evolutions.map { $0.performanceChange }.reduce(0, +)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : themeManager.currentTheme.accentColor)
                    
                    Spacer()
                    
                    Text("v\(latestVersion)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : themeManager.currentTheme.secondaryTextColor)
                }
                
                Text("Strategy \(strategyId.prefix(8))...")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                
                HStack(spacing: 4) {
                    Image(systemName: totalPerformanceChange >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    
                    Text("\(totalPerformanceChange >= 0 ? "+" : "")\(Int(totalPerformanceChange))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(isSelected ? .white : (totalPerformanceChange >= 0 ? .green : .red))
                
                Text("\(evolutions.count) iterations")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : themeManager.currentTheme.secondaryTextColor)
            }
            .padding()
            .frame(width: 140)
            .background(
                isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryBackgroundColor
            )
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct EvolutionChangeCard: View {
    let evolution: StrategyEvolution
    @EnvironmentObject var themeManager: ThemeManager
    @State private var expanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Version \(evolution.version)")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        TriggerBadge(trigger: evolution.trigger)
                    }
                    
                    Text(evolution.timestamp.relative())
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: evolution.performanceChange >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                    
                    Text("\(evolution.performanceChange >= 0 ? "+" : "")\(Int(evolution.performanceChange))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(evolution.performanceChange >= 0 ? .green : .red)
                
                Button(action: { withAnimation { expanded.toggle() } }) {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(evolution.changes, id: \.parameter) { change in
                        HStack {
                            Text(change.parameter)
                                .font(.caption2)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text(String(format: "%.2f", change.oldValue))
                                    .font(.caption2)
                                    .strikethrough()
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                
                                Text(String(format: "%.2f", change.newValue))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.currentTheme.textColor)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(8)
    }
}

struct TriggerBadge: View {
    let trigger: EvolutionTrigger
    @EnvironmentObject var themeManager: ThemeManager
    
    private var config: (icon: String, color: Color) {
        switch trigger {
        case .manual:
            return ("hand.tap", .blue)
        case .scheduled:
            return ("clock", .green)
        case .performanceDrop:
            return ("exclamationmark.triangle", .red)
        case .marketRegimeChange:
            return ("chart.line.flattrend.xyaxis", .orange)
        case .mlRecommendation:
            return ("brain", .purple)
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: config.icon)
                .font(.caption2)
            
            Text(trigger.displayName)
                .font(.caption2)
        }
        .foregroundColor(config.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(config.color.opacity(0.2))
        .cornerRadius(4)
    }
}

// MARK: - Evolution Details View
struct EvolutionDetailsView: View {
    let history: [StrategyEvolution]
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedMetric = "Performance"
    
    let metrics = ["Performance", "Win Rate", "Drawdown", "Sharpe Ratio"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Metric Selector
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(metrics, id: \.self) { metric in
                            Text(metric).tag(metric)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Evolution Chart
                    EvolutionMetricChart(
                        history: history,
                        metric: selectedMetric
                    )
                    .frame(height: 300)
                    .padding()
                    
                    // Parameter Changes Over Time
                    ParameterEvolutionView(history: history)
                        .padding()
                    
                    // Trigger Analysis
                    TriggerAnalysisView(history: history)
                        .padding()
                }
            }
            .navigationTitle("Evolution Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EvolutionMetricChart: View {
    let history: [StrategyEvolution]
    let metric: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Chart(history) { evolution in
            LineMark(
                x: .value("Version", evolution.version),
                y: .value(metric, getMetricValue(evolution, metric: metric))
            )
            .foregroundStyle(by: .value("Strategy", evolution.strategyId))
            
            PointMark(
                x: .value("Version", evolution.version),
                y: .value(metric, getMetricValue(evolution, metric: metric))
            )
            .foregroundStyle(by: .value("Strategy", evolution.strategyId))
        }
        .chartLegend(position: .bottom)
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
    
    private func getMetricValue(_ evolution: StrategyEvolution, metric: String) -> Double {
        // In a real implementation, these would come from actual data
        switch metric {
        case "Performance":
            return evolution.performanceChange
        case "Win Rate":
            return Double.random(in: 40...70)
        case "Drawdown":
            return Double.random(in: 5...20)
        case "Sharpe Ratio":
            return Double.random(in: 0.5...2.5)
        default:
            return 0
        }
    }
}

struct ParameterEvolutionView: View {
    let history: [StrategyEvolution]
    @EnvironmentObject var themeManager: ThemeManager
    
    private var allParameters: Set<String> {
        Set(history.flatMap { $0.changes.map { $0.parameter } })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parameter Evolution")
                .font(.headline)
            
            ForEach(Array(allParameters), id: \.self) { parameter in
                ParameterTimelineView(
                    parameter: parameter,
                    history: history
                )
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct ParameterTimelineView: View {
    let parameter: String
    let history: [StrategyEvolution]
    @EnvironmentObject var themeManager: ThemeManager
    
    private var parameterChanges: [(version: Int, value: Double)] {
        var changes: [(Int, Double)] = []
        for evolution in history {
            if let change = evolution.changes.first(where: { $0.parameter == parameter }) {
                changes.append((evolution.version, change.newValue))
            }
        }
        return changes
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(parameter)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            HStack(spacing: 12) {
                ForEach(parameterChanges, id: \.version) { version, value in
                    VStack(spacing: 4) {
                        Text("v\(version)")
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Text(String(format: "%.2f", value))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    if version != parameterChanges.last?.version {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
        }
    }
}

struct TriggerAnalysisView: View {
    let history: [StrategyEvolution]
    @EnvironmentObject var themeManager: ThemeManager
    
    private var triggerCounts: [(trigger: EvolutionTrigger, count: Int, avgPerformance: Double)] {
        let grouped = Dictionary(grouping: history) { $0.trigger }
        return grouped.map { trigger, evolutions in
            let avgPerf = evolutions.map { $0.performanceChange }.reduce(0, +) / Double(evolutions.count)
            return (trigger, evolutions.count, avgPerf)
        }.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimization Triggers")
                .font(.headline)
            
            ForEach(triggerCounts, id: \.trigger) { trigger, count, avgPerformance in
                HStack {
                    TriggerBadge(trigger: trigger)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(count) times")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 2) {
                            Image(systemName: avgPerformance >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption2)
                            Text("\(avgPerformance >= 0 ? "+" : "")\(Int(avgPerformance))% avg")
                                .font(.caption2)
                        }
                        .foregroundColor(avgPerformance >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Extensions
extension EvolutionTrigger {
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .scheduled: return "Scheduled"
        case .performanceDrop: return "Performance"
        case .marketRegimeChange: return "Market"
        case .mlRecommendation: return "AI"
        }
    }
}