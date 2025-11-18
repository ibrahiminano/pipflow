//
//  SafetyControlComponents.swift
//  Pipflow
//
//  Supporting components for Safety Control features
//

import SwiftUI

// MARK: - Safety Alerts Tab

struct SafetyAlertsTab: View {
    let alerts: [SafetyAlert]
    let theme: Theme
    @State private var filter: SafetyAlertSeverity?
    
    var filteredAlerts: [SafetyAlert] {
        if let filter = filter {
            return alerts.filter { $0.severity == filter }
        }
        return alerts
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterPill(
                            title: "All",
                            count: alerts.count,
                            isSelected: filter == nil,
                            color: theme.accentColor
                        ) {
                            filter = nil
                        }
                        
                        FilterPill(
                            title: "Emergency",
                            count: alerts.filter { $0.severity == .emergency }.count,
                            isSelected: filter == .emergency,
                            color: .purple
                        ) {
                            filter = .emergency
                        }
                        
                        FilterPill(
                            title: "Critical",
                            count: alerts.filter { $0.severity == .critical }.count,
                            isSelected: filter == .critical,
                            color: .red
                        ) {
                            filter = .critical
                        }
                        
                        FilterPill(
                            title: "Warning",
                            count: alerts.filter { $0.severity == .warning }.count,
                            isSelected: filter == .warning,
                            color: .orange
                        ) {
                            filter = .warning
                        }
                        
                        FilterPill(
                            title: "Info",
                            count: alerts.filter { $0.severity == .info }.count,
                            isSelected: filter == .info,
                            color: .blue
                        ) {
                            filter = .info
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Alerts List
                if filteredAlerts.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "No Alerts",
                        description: "All systems are operating normally",
                        theme: theme
                    )
                    .padding(.top, 50)
                } else {
                    ForEach(filteredAlerts) { alert in
                        AlertCard(alert: alert, theme: theme)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct AlertCard: View {
    let alert: SafetyAlert
    let theme: Theme
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Severity Indicator
                Circle()
                    .fill(alert.severity.color)
                    .frame(width: 12, height: 12)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.type.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    Text(alert.message)
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryTextColor)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    HStack {
                        Text(formatTime(alert.timestamp))
                            .font(.caption)
                            .foregroundColor(theme.secondaryTextColor)
                        
                        Spacer()
                        
                        if alert.message.count > 100 {
                            Button(action: { isExpanded.toggle() }) {
                                Text(isExpanded ? "Show Less" : "Show More")
                                    .font(.caption)
                                    .foregroundColor(theme.accentColor)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Action Button
            if let action = alert.action {
                Button(action: action.execute) {
                    HStack {
                        Image(systemName: action.type.icon)
                        Text(action.description)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(alert.severity.color)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Approvals Tab

struct ApprovalsTab: View {
    let approvals: [ApprovalRequest]
    let theme: Theme
    let onApprove: (UUID, String?) -> Void
    let onReject: (UUID, String) -> Void
    
    @State private var selectedApproval: ApprovalRequest?
    @State private var showRejectReason = false
    @State private var rejectReason = ""
    
    var pendingApprovals: [ApprovalRequest] {
        approvals.filter { $0.status == .pending }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats
                HStack(spacing: 20) {
                    ApprovalStat(
                        title: "Pending",
                        count: approvals.filter { $0.status == .pending }.count,
                        color: .orange,
                        theme: theme
                    )
                    
                    ApprovalStat(
                        title: "Approved",
                        count: approvals.filter { $0.status == .approved }.count,
                        color: .green,
                        theme: theme
                    )
                    
                    ApprovalStat(
                        title: "Rejected",
                        count: approvals.filter { $0.status == .rejected }.count,
                        color: .red,
                        theme: theme
                    )
                }
                .padding(.horizontal)
                
                // Pending Approvals
                if pendingApprovals.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.shield",
                        title: "No Pending Approvals",
                        description: "All trades are within safe parameters",
                        theme: theme
                    )
                    .padding(.top, 50)
                } else {
                    ForEach(pendingApprovals) { approval in
                        ApprovalCard(
                            approval: approval,
                            theme: theme,
                            onApprove: {
                                onApprove(approval.id, nil)
                            },
                            onReject: {
                                selectedApproval = approval
                                showRejectReason = true
                            }
                        )
                    }
                }
                
                // History Section
                if !approvals.filter({ $0.status != .pending }).isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Approval History")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                            .padding(.horizontal)
                        
                        ForEach(approvals.filter { $0.status != .pending }) { approval in
                            ApprovalHistoryCard(approval: approval, theme: theme)
                        }
                    }
                    .padding(.top)
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showRejectReason) {
            RejectReasonView(
                reason: $rejectReason,
                theme: theme,
                onSubmit: {
                    if let approval = selectedApproval {
                        onReject(approval.id, rejectReason)
                        showRejectReason = false
                        rejectReason = ""
                    }
                },
                onCancel: {
                    showRejectReason = false
                    rejectReason = ""
                }
            )
        }
    }
}

struct ApprovalCard: View {
    let approval: ApprovalRequest
    let theme: Theme
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(approval.trade.type.rawValue) \(approval.trade.symbol)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    Text(approval.reason)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                RiskScoreBadge(score: approval.riskScore, theme: theme)
            }
            
            // Trade Details
            HStack(spacing: 20) {
                SafetyTradeDetail(label: "Size", value: String(format: "%.2f", approval.trade.volume))
                SafetyTradeDetail(label: "Price", value: String(format: "%.5f", approval.trade.price ?? 0.0))
                SafetyTradeDetail(label: "Value", value: String(format: "$%.0f", approval.trade.volume * 100000 * (approval.trade.price ?? 0.0)))
            }
            .font(.caption)
            .foregroundColor(theme.secondaryTextColor)
            
            Divider()
                .background(theme.separatorColor)
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onReject) {
                    Text("Reject")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: onApprove) {
                    Text("Approve")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ApprovalStat: View {
    let title: String
    let count: Int
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Anomalies Tab

struct AnomaliesTab: View {
    let anomalies: [TradingAnomalyReport]
    let theme: Theme
    @State private var selectedType: AnomalyType?
    
    var filteredAnomalies: [TradingAnomalyReport] {
        if let type = selectedType {
            return anomalies.filter { $0.anomalyType == type }
        }
        return anomalies
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary Stats
                AnomalySummary(anomalies: anomalies, theme: theme)
                
                // Filter by Type
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        AnomalyTypeFilter(
                            type: nil,
                            title: "All",
                            isSelected: selectedType == nil,
                            count: anomalies.count,
                            theme: theme
                        ) {
                            selectedType = nil
                        }
                        
                        ForEach(AnomalyType.allCases, id: \.self) { type in
                            AnomalyTypeFilter(
                                type: type,
                                title: type.title,
                                isSelected: selectedType == type,
                                count: anomalies.filter { $0.anomalyType == type }.count,
                                theme: theme
                            ) {
                                selectedType = type
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Anomaly List
                if filteredAnomalies.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "No Anomalies Detected",
                        description: "Trading patterns are normal",
                        theme: theme
                    )
                    .padding(.top, 50)
                } else {
                    ForEach(filteredAnomalies) { anomaly in
                        AnomalyCard(anomaly: anomaly, theme: theme)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct AnomalyCard: View {
    let anomaly: TradingAnomalyReport
    let theme: Theme
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: anomaly.anomalyType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(confidenceColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(anomaly.anomalyType.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textColor)
                    
                    Text(formatTime(anomaly.timestamp))
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
                
                Spacer()
                
                ConfidenceBadge(confidence: anomaly.confidence, theme: theme)
            }
            
            // Description
            Text(anomaly.description)
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryTextColor)
            
            // Recommendation
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                Text(anomaly.recommendation)
                    .font(.caption)
                    .foregroundColor(theme.textColor)
            }
            .padding(8)
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
            
            // Affected Trades
            if !anomaly.affectedTrades.isEmpty {
                Button(action: { showDetails.toggle() }) {
                    HStack {
                        Text("\(anomaly.affectedTrades.count) affected trades")
                            .font(.caption)
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    }
                    .foregroundColor(theme.accentColor)
                }
                
                if showDetails {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(anomaly.affectedTrades.prefix(3)) { trade in
                            HStack {
                                Text("\(trade.type.rawValue) \(trade.symbol)")
                                    .font(.caption)
                                Spacer()
                                Text(String(format: "%.2f lots", Double(truncating: trade.volume as NSNumber)))
                                    .font(.caption)
                            }
                            .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                    .padding(8)
                    .background(theme.backgroundColor)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var confidenceColor: Color {
        if anomaly.confidence > 0.8 { return .red }
        if anomaly.confidence > 0.5 { return .orange }
        return .yellow
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Safety Settings Tab

struct SafetySettingsTab: View {
    @Binding var settings: SafetySettings
    let theme: Theme
    @State private var showTradingHours = false
    @State private var showBlacklistSymbols = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Risk Limits Section
                SettingsSection(title: "Risk Limits", theme: theme) {
                    SettingRow(
                        title: "Daily Loss Limit",
                        value: String(format: "$%.0f", settings.dailyLossLimit),
                        theme: theme
                    )
                    
                    SettingRow(
                        title: "Max Drawdown",
                        value: String(format: "%.0f%%", settings.maxDrawdownLimit * 100),
                        theme: theme
                    )
                    
                    SettingRow(
                        title: "Approval Threshold",
                        value: String(format: "$%.0f", settings.requireApprovalAbove),
                        theme: theme
                    )
                }
                
                // Position Limits Section
                SettingsSection(title: "Position Limits", theme: theme) {
                    SettingRow(
                        title: "Max Open Positions",
                        value: "\(settings.maxOpenPositions)",
                        theme: theme
                    )
                    
                    SettingRow(
                        title: "Max Leverage",
                        value: String(format: "%.0fx", settings.maxLeverageAllowed),
                        theme: theme
                    )
                }
                
                // Safety Features Section
                SettingsSection(title: "Safety Features", theme: theme) {
                    ToggleRow(
                        title: "Emergency Stop Enabled",
                        isOn: $settings.emergencyStopEnabled,
                        theme: theme
                    )
                    
                    ToggleRow(
                        title: "Anomaly Detection",
                        isOn: $settings.anomalyDetectionEnabled,
                        theme: theme
                    )
                    
                    ToggleRow(
                        title: "Sandbox Mode",
                        isOn: $settings.sandboxModeEnabled,
                        theme: theme
                    )
                }
                
                // Advanced Settings
                SettingsSection(title: "Advanced", theme: theme) {
                    Button(action: { showTradingHours = true }) {
                        HStack {
                            Text("Trading Hours")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(theme.textColor)
                    }
                    
                    Divider()
                        .background(theme.separatorColor)
                    
                    Button(action: { showBlacklistSymbols = true }) {
                        HStack {
                            Text("Symbol Restrictions")
                            Spacer()
                            Text("\(settings.blacklistedSymbols.count)")
                                .foregroundColor(theme.secondaryTextColor)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(theme.textColor)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showTradingHours) {
            TradingHoursSettings(tradingHours: $settings.allowedTradingHours)
                .environmentObject(ThemeManager.shared)
        }
        .sheet(isPresented: $showBlacklistSymbols) {
            SymbolRestrictionsView(
                blacklisted: $settings.blacklistedSymbols,
                whitelisted: $settings.whitelistedSymbols
            )
            .environmentObject(ThemeManager.shared)
        }
    }
}

// MARK: - Supporting Components

struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if count > 0 {
                    Text("(\(count))")
                }
            }
            .font(.caption)
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : color.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(theme.separatorColor)
            
            Text(title)
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            Text(description)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct RiskScoreBadge: View {
    let score: Double
    let theme: Theme
    
    var color: Color {
        if score > 70 { return .red }
        if score > 50 { return .orange }
        return .green
    }
    
    var body: some View {
        Text(String(format: "%.0f", score))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(12)
    }
}

struct SafetyTradeDetail: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct ApprovalHistoryCard: View {
    let approval: ApprovalRequest
    let theme: Theme
    
    var statusColor: Color {
        switch approval.status {
        case .approved: return .green
        case .rejected: return .red
        case .expired: return .gray
        case .pending: return .orange
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(approval.trade.type.rawValue) \(approval.trade.symbol)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textColor)
                
                if let notes = approval.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(approval.status.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
                
                if let approvedAt = approval.approvedAt {
                    Text(formatTime(approvedAt))
                        .font(.caption2)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(theme.backgroundColor)
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct RejectReasonView: View {
    @Binding var reason: String
    let theme: Theme
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Provide a reason for rejecting this trade")
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                    .padding(.top)
                
                TextEditor(text: $reason)
                    .padding(8)
                    .background(theme.secondaryBackgroundColor)
                    .cornerRadius(8)
                    .frame(minHeight: 100)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reject Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit", action: onSubmit)
                        .disabled(reason.isEmpty)
                }
            }
        }
    }
}

struct AnomalySummary: View {
    let anomalies: [TradingAnomalyReport]
    let theme: Theme
    
    var highConfidenceCount: Int {
        anomalies.filter { $0.confidence > 0.8 }.count
    }
    
    var recentCount: Int {
        let cutoff = Date().addingTimeInterval(-3600) // Last hour
        return anomalies.filter { $0.timestamp > cutoff }.count
    }
    
    var body: some View {
        HStack(spacing: 20) {
            SummaryMetric(
                title: "Total",
                value: "\(anomalies.count)",
                icon: "exclamationmark.triangle",
                color: .orange,
                theme: theme
            )
            
            SummaryMetric(
                title: "High Confidence",
                value: "\(highConfidenceCount)",
                icon: "exclamationmark.circle.fill",
                color: .red,
                theme: theme
            )
            
            SummaryMetric(
                title: "Recent (1h)",
                value: "\(recentCount)",
                icon: "clock",
                color: theme.accentColor,
                theme: theme
            )
        }
        .padding(.horizontal)
    }
}

struct SummaryMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: Theme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct AnomalyTypeFilter: View {
    let type: AnomalyType?
    let title: String
    let isSelected: Bool
    let count: Int
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let type = type {
                    Image(systemName: type.icon)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 20))
                }
                
                Text(title)
                    .font(.caption)
                
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .foregroundColor(isSelected ? .white : theme.textColor)
            .frame(width: 80, height: 80)
            .background(isSelected ? theme.accentColor : theme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: Double
    let theme: Theme
    
    var color: Color {
        if confidence > 0.8 { return .red }
        if confidence > 0.5 { return .orange }
        return .yellow
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge")
                .font(.caption)
            Text(String(format: "%.0f%%", confidence * 100))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let theme: Theme
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(theme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
    }
}

struct SettingRow: View {
    let title: String
    let value: String
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.accentColor)
        }
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let theme: Theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(theme.textColor)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

// MARK: - Additional Sheets

struct TradingHoursSettings: View {
    @Binding var tradingHours: TradingHours
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Implementation for trading hours configuration
                Text("Trading Hours Configuration")
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
            .navigationTitle("Trading Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SymbolRestrictionsView: View {
    @Binding var blacklisted: [String]
    @Binding var whitelisted: [String]
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Implementation for symbol restrictions
                Text("Symbol Restrictions Configuration")
                    .foregroundColor(themeManager.currentTheme.textColor)
            }
            .navigationTitle("Symbol Restrictions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Extensions

extension SafetyAlertType {
    var title: String {
        switch self {
        case .dailyLossLimit: return "Daily Loss Limit"
        case .drawdownLimit: return "Drawdown Limit"
        case .anomalyDetected: return "Anomaly Detected"
        case .unusualVolume: return "Unusual Volume"
        case .highLeverage: return "High Leverage"
        case .restrictedTime: return "Restricted Time"
        case .blacklistedSymbol: return "Blacklisted Symbol"
        case .emergencyStop: return "Emergency Stop"
        }
    }
}

extension SafetyAction.ActionType {
    var icon: String {
        switch self {
        case .pauseTrading: return "pause.circle"
        case .closeAllPositions: return "xmark.circle"
        case .reducePositionSize: return "minus.circle"
        case .switchToPaperTrading: return "doc.circle"
        case .requireManualApproval: return "hand.raised.circle"
        }
    }
}

extension AnomalyType: CaseIterable {
    static var allCases: [AnomalyType] {
        return [.unusualTradeSize, .abnormalFrequency, .suspiciousPattern, .deviationFromStrategy, .technicalGlitch]
    }
    
    var title: String {
        switch self {
        case .unusualTradeSize: return "Trade Size"
        case .abnormalFrequency: return "Frequency"
        case .suspiciousPattern: return "Pattern"
        case .deviationFromStrategy: return "Deviation"
        case .technicalGlitch: return "Technical"
        }
    }
    
    var icon: String {
        switch self {
        case .unusualTradeSize: return "chart.bar"
        case .abnormalFrequency: return "speedometer"
        case .suspiciousPattern: return "eye"
        case .deviationFromStrategy: return "arrow.uturn.left"
        case .technicalGlitch: return "exclamationmark.triangle"
        }
    }
}

extension ApprovalStatus {
    var title: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .expired: return "Expired"
        }
    }
}