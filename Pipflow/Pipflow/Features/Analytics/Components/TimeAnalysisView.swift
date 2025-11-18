//
//  TimeAnalysisView.swift
//  Pipflow
//
//  Time-based trading analysis
//

import SwiftUI
import Charts

struct TimeAnalysisView: View {
    let dayDistribution: [DayPerformance]
    let hourDistribution: [HourPerformance]
    @State private var selectedView: TimeView = .day
    
    enum TimeView: String, CaseIterable {
        case day = "By Day"
        case hour = "By Hour"
        
        var icon: String {
            switch self {
            case .day: return "calendar"
            case .hour: return "clock"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Toggle
            HStack {
                Text("Time Analysis")
                    .font(.headline)
                
                Spacer()
                
                Picker("View", selection: $selectedView) {
                    ForEach(TimeView.allCases, id: \.self) { view in
                        Text(view.rawValue)
                            .tag(view)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 160)
            }
            
            // Content based on selected view
            if selectedView == .day {
                dayOfWeekAnalysis
            } else {
                hourlyAnalysis
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Day of Week Analysis
    
    private var dayOfWeekAnalysis: some View {
        VStack(spacing: 12) {
            // Chart
            Chart(dayDistribution) { day in
                BarMark(
                    x: .value("Day", day.dayOfWeek),
                    y: .value("Profit", day.totalProfit)
                )
                .foregroundStyle(day.totalProfit >= 0 ? Color.Theme.success : Color.Theme.error)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.Theme.divider.opacity(0.5))
                    AxisValueLabel(format: .currency(code: "USD"))
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.secondaryText)
                }
            }
            
            // Day Details
            ForEach(dayDistribution) { day in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.dayOfWeek)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(day.tradeCount) trades")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(day.totalProfit))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(day.totalProfit >= 0 ? Color.Theme.success : Color.Theme.error)
                        Text("Win: \(Int(day.winRate * 100))%")
                            .font(.caption)
                            .foregroundColor(day.winRate >= 0.5 ? Color.Theme.success : Color.Theme.error)
                    }
                }
                .padding(.vertical, 4)
                
                if day.id != dayDistribution.last?.id {
                    Divider()
                        .background(Color.Theme.divider)
                }
            }
        }
    }
    
    // MARK: - Hourly Analysis
    
    private var hourlyAnalysis: some View {
        VStack(spacing: 12) {
            // Heat Map
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 6), spacing: 2) {
                ForEach(hourDistribution) { hour in
                    HourCell(hour: hour)
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.Theme.error)
                        .frame(width: 8, height: 8)
                    Text("Loss")
                        .font(.caption2)
                        .foregroundColor(Color.Theme.secondaryText)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.Theme.warning)
                        .frame(width: 8, height: 8)
                    Text("Break Even")
                        .font(.caption2)
                        .foregroundColor(Color.Theme.secondaryText)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.Theme.success)
                        .frame(width: 8, height: 8)
                    Text("Profit")
                        .font(.caption2)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
            .padding(.top, 8)
            
            // Best/Worst Hours
            HStack(spacing: 20) {
                if let bestHour = hourDistribution.max(by: { $0.totalProfit < $1.totalProfit }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best Hour")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                        Text("\(formatHour(bestHour.hour))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("+\(formatCurrency(bestHour.totalProfit))")
                            .font(.caption)
                            .foregroundColor(Color.Theme.success)
                    }
                }
                
                if let worstHour = hourDistribution.min(by: { $0.totalProfit < $1.totalProfit }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Worst Hour")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                        Text("\(formatHour(worstHour.hour))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(formatCurrency(worstHour.totalProfit))")
                            .font(.caption)
                            .foregroundColor(Color.Theme.error)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct HourCell: View {
    let hour: HourPerformance
    
    private var cellColor: Color {
        if hour.totalProfit > 100 {
            return Color.Theme.success
        } else if hour.totalProfit > 0 {
            return Color.Theme.success.opacity(0.6)
        } else if hour.totalProfit > -50 {
            return Color.Theme.warning
        } else {
            return Color.Theme.error
        }
    }
    
    private var textColor: Color {
        if hour.totalProfit > 50 || hour.totalProfit < -50 {
            return .white
        } else {
            return Color.Theme.text
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(hour.hour):00")
                .font(.caption2)
                .fontWeight(.medium)
            Text("\(hour.tradeCount)")
                .font(.caption2)
        }
        .foregroundColor(textColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(cellColor)
        .cornerRadius(4)
    }
}