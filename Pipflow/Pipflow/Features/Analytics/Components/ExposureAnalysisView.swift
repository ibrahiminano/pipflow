//
//  ExposureAnalysisView.swift
//  Pipflow
//
//  Exposure analysis visualization
//

import SwiftUI
import Charts

struct ExposureAnalysisView: View {
    let exposure: ExposureAnalysis
    @State private var selectedTab: ExposureTab = .symbol
    
    enum ExposureTab: String, CaseIterable {
        case symbol = "Symbol"
        case sector = "Sector"
        case currency = "Currency"
        
        var icon: String {
            switch self {
            case .symbol: return "chart.pie"
            case .sector: return "square.grid.2x2"
            case .currency: return "dollarsign.circle"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Concentration Risk
            HStack {
                Text("Exposure Analysis")
                    .font(.headline)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Concentration Risk")
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.secondaryText)
                    Text("\(exposure.concentrationRisk * 100, specifier: "%.0f")%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(concentrationRiskColor)
                }
            }
            
            // Tab Selection
            HStack(spacing: 0) {
                ForEach(ExposureTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Color.Theme.accent : Color.clear)
                        .foregroundColor(selectedTab == tab ? .white : Color.Theme.text)
                    }
                }
            }
            .background(Color.Theme.secondary)
            .cornerRadius(8)
            
            // Content based on selected tab
            switch selectedTab {
            case .symbol:
                symbolExposureView
            case .sector:
                sectorExposureView
            case .currency:
                currencyExposureView
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private var concentrationRiskColor: Color {
        if exposure.concentrationRisk < 0.3 {
            return Color.Theme.success
        } else if exposure.concentrationRisk < 0.5 {
            return Color.Theme.warning
        } else {
            return Color.Theme.error
        }
    }
    
    // MARK: - Symbol Exposure View
    
    private var symbolExposureView: some View {
        VStack(spacing: 12) {
            // Pie Chart
            if !exposure.bySymbol.isEmpty {
                Chart(exposure.bySymbol) { item in
                    SectorMark(
                        angle: .value("Exposure", item.percentage),
                        innerRadius: .ratio(0.6)
                    )
                    .foregroundStyle(by: .value("Symbol", item.symbol))
                    .opacity(0.8)
                }
                .frame(height: 200)
                .chartBackground { _ in
                    Text("\(exposure.bySymbol.count)\nSymbols")
                        .font(.caption)
                        .foregroundStyle(Color.Theme.secondaryText)
                }
            }
            
            // List
            ForEach(exposure.bySymbol) { item in
                ExposureRow(
                    title: item.symbol,
                    value: formatCurrency(item.exposure),
                    percentage: item.percentage
                )
            }
        }
    }
    
    // MARK: - Sector Exposure View
    
    private var sectorExposureView: some View {
        VStack(spacing: 12) {
            ForEach(exposure.bySector) { item in
                VStack(spacing: 8) {
                    HStack {
                        Text(item.sector)
                            .font(.caption)
                            .foregroundColor(Color.Theme.text)
                        Spacer()
                        Text("\(item.percentage, specifier: "%.0f")%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.Theme.divider)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForSector(item.sector))
                                .frame(width: geometry.size.width * (item.percentage / 100))
                        }
                    }
                    .frame(height: 20)
                    .overlay(
                        Text(formatCurrency(item.exposure))
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8),
                        alignment: .leading
                    )
                }
            }
        }
    }
    
    // MARK: - Currency Exposure View
    
    private var currencyExposureView: some View {
        VStack(spacing: 12) {
            // Bar Chart
            Chart(exposure.byCurrency) { item in
                BarMark(
                    x: .value("Currency", item.currency),
                    y: .value("Exposure", item.exposure)
                )
                .foregroundStyle(colorForCurrency(item.currency))
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(Color.Theme.divider.opacity(0.5))
                    AxisValueLabel(format: .currency(code: "USD"))
                        .font(.caption2)
                        .foregroundStyle(Color.Theme.secondaryText)
                }
            }
            
            // List
            ForEach(exposure.byCurrency) { item in
                ExposureRow(
                    title: item.currency,
                    value: formatCurrency(item.exposure),
                    percentage: item.percentage,
                    icon: "dollarsign.circle"
                )
            }
        }
    }
    
    private func colorForSector(_ sector: String) -> Color {
        switch sector {
        case "Forex Major": return Color.Theme.accent
        case "Commodities": return Color.Theme.warning
        case "Crypto": return Color.Theme.info
        default: return Color.Theme.secondary
        }
    }
    
    private func colorForCurrency(_ currency: String) -> Color {
        switch currency {
        case "USD": return Color.Theme.success
        case "EUR": return Color.Theme.info
        case "GBP": return Color.Theme.warning
        case "JPY": return Color.Theme.error
        default: return Color.Theme.secondary
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct ExposureRow: View {
    let title: String
    let value: String
    let percentage: Double
    var icon: String? = nil
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color.Theme.accent)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.text)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(percentage, specifier: "%.1f")%")
                    .font(.caption2)
                    .foregroundColor(Color.Theme.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}