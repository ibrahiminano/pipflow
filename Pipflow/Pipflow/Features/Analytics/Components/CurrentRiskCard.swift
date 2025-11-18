//
//  CurrentRiskCard.swift
//  Pipflow
//
//  Current risk metrics display
//

import SwiftUI

struct CurrentRiskCard: View {
    let risk: CurrentRiskMetrics
    @State private var showDetails = false
    
    private var leverageColor: Color {
        if risk.leverage < 5 {
            return Color.Theme.success
        } else if risk.leverage < 10 {
            return Color.Theme.warning
        } else {
            return Color.Theme.error
        }
    }
    
    private var marginUtilization: Double {
        guard (risk.marginUsed + risk.marginAvailable) > 0 else { return 0 }
        return (risk.marginUsed / (risk.marginUsed + risk.marginAvailable)) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Current Risk", systemImage: "exclamationmark.shield")
                    .font(.headline)
                Spacer()
                Button(action: { showDetails.toggle() }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
            
            // Main Risk Indicators
            HStack(spacing: 16) {
                RiskIndicator(
                    title: "Leverage",
                    value: String(format: "%.1fx", risk.leverage),
                    progress: risk.leverage / 20, // Max 20x for visualization
                    color: leverageColor
                )
                
                RiskIndicator(
                    title: "Exposure",
                    value: formatCurrency(risk.totalExposure),
                    progress: risk.totalExposure / 50000, // Assuming 50k max for visualization
                    color: Color.Theme.accent
                )
            }
            
            // Margin Status
            VStack(spacing: 8) {
                HStack {
                    Text("Margin Utilization")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                    Spacer()
                    Text("\(marginUtilization, specifier: "%.1f")%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.Theme.divider)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(marginUtilization > 80 ? Color.Theme.error : Color.Theme.accent)
                            .frame(width: geometry.size.width * (marginUtilization / 100))
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("Used: \(formatCurrency(risk.marginUsed))")
                        .font(.caption2)
                        .foregroundColor(Color.Theme.secondaryText)
                    Spacer()
                    Text("Available: \(formatCurrency(risk.marginAvailable))")
                        .font(.caption2)
                        .foregroundColor(Color.Theme.secondaryText)
                }
            }
            
            if showDetails {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.Theme.divider)
                    
                    RiskDetailRow(
                        title: "Open Position Risk",
                        value: formatCurrency(risk.openPositionRisk),
                        icon: "chart.line.downtrend.xyaxis"
                    )
                    
                    RiskDetailRow(
                        title: "Correlated Risk",
                        value: formatCurrency(risk.correlatedRisk),
                        icon: "link"
                    )
                    
                    RiskDetailRow(
                        title: "Worst Case Scenario",
                        value: formatCurrency(risk.worstCaseScenario),
                        icon: "exclamationmark.triangle",
                        valueColor: Color.Theme.error
                    )
                }
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(16)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct RiskIndicator: View {
    let title: String
    let value: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.Theme.divider)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RiskDetailRow: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = Color.Theme.text
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
    }
}