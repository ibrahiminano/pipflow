//
//  EquityCurveChart.swift
//  Pipflow
//
//  Chart component for displaying equity curve
//

import SwiftUI
import Charts

struct AnalyticsEquityCurveChart: View {
    let equityCurve: EquityCurve
    @State private var selectedDataPoint: EquityDataPoint?
    @State private var showDrawdown = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Equity Curve")
                        .font(.headline)
                    Text("Total Return: \(equityCurve.totalReturn, specifier: "%.2f")%")
                        .font(.caption)
                        .foregroundColor(equityCurve.totalReturn >= 0 ? Color.Theme.success : Color.Theme.error)
                }
                
                Spacer()
                
                Toggle("Drawdown", isOn: $showDrawdown)
                    .toggleStyle(SwitchToggleStyle(tint: Color.Theme.accent))
                    .scaleEffect(0.8)
            }
            
            // Chart
            Chart(equityCurve.dataPoints) { dataPoint in
                // Equity Line
                LineMark(
                    x: .value("Date", dataPoint.timestamp),
                    y: .value("Balance", dataPoint.balance)
                )
                .foregroundStyle(Color.Theme.accent)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                // Area under curve
                AreaMark(
                    x: .value("Date", dataPoint.timestamp),
                    y: .value("Balance", dataPoint.balance)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.Theme.accent.opacity(0.3), Color.Theme.accent.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Drawdown overlay
                if showDrawdown && dataPoint.drawdown < 0 {
                    BarMark(
                        x: .value("Date", dataPoint.timestamp),
                        y: .value("Balance", dataPoint.balance)
                    )
                    .foregroundStyle(Color.Theme.error.opacity(0.3))
                }
                
                // Selected point
                if let selected = selectedDataPoint, selected.id == dataPoint.id {
                    PointMark(
                        x: .value("Date", dataPoint.timestamp),
                        y: .value("Balance", dataPoint.balance)
                    )
                    .foregroundStyle(Color.Theme.accent)
                    .symbolSize(100)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.Theme.divider.opacity(0.5))
                    AxisTick()
                        .foregroundStyle(Color.Theme.divider)
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(.caption)
                        .foregroundStyle(Color.Theme.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.Theme.divider.opacity(0.5))
                    AxisTick()
                        .foregroundStyle(Color.Theme.divider)
                    AxisValueLabel(format: .currency(code: "USD"))
                        .font(.caption)
                        .foregroundStyle(Color.Theme.secondaryText)
                }
            }
            .chartBackground { _ in
                Rectangle()
                    .fill(Color.Theme.background.opacity(0.5))
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            let plotFrame = proxy.plotAreaFrame
                            let xPosition = location.x - geometry[plotFrame].origin.x
                            if let date: Date = proxy.value(atX: xPosition) {
                                selectedDataPoint = equityCurve.dataPoints.min(by: {
                                    abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date))
                                })
                            }
                        }
                }
            }
            
            // Selected point details
            if let selected = selectedDataPoint {
                selectedPointDetails(selected)
            }
            
            // Statistics
            HStack(spacing: 20) {
                EquityStatItem(
                    title: "Peak",
                    value: formatCurrency(equityCurve.peakBalance),
                    color: Color.Theme.success
                )
                
                EquityStatItem(
                    title: "Drawdown",
                    value: String(format: "%.2f%%", equityCurve.maxDrawdown),
                    color: Color.Theme.error
                )
                
                EquityStatItem(
                    title: "Current",
                    value: formatCurrency(equityCurve.endingBalance),
                    color: Color.Theme.accent
                )
            }
            .padding(.top, 8)
        }
    }
    
    private func selectedPointDetails(_ point: EquityDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(point.timestamp, format: .dateTime.day().month().year())
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            HStack(spacing: 16) {
                EquityDetailItem(label: "Balance", value: formatCurrency(point.balance))
                EquityDetailItem(label: "P&L", value: formatCurrency(point.profit), color: point.profit >= 0 ? .green : .red)
                EquityDetailItem(label: "Drawdown", value: String(format: "%.2f%%", point.drawdown), color: .orange)
                EquityDetailItem(label: "Positions", value: "\(point.openPositions)")
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct EquityStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct EquityDetailItem: View {
    let label: String
    let value: String
    var color: Color = Color.Theme.text
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.Theme.secondaryText)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}