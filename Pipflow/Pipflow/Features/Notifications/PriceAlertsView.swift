//
//  PriceAlertsView.swift
//  Pipflow
//
//  Price alerts management view
//

import SwiftUI

struct PriceAlertsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingNewAlert = false
    @State private var selectedAlert: PriceAlert?
    @State private var showingDeleteConfirmation = false
    @State private var alertToDelete: PriceAlert?
    
    var activeAlerts: [PriceAlert] {
        notificationService.priceAlerts.filter { $0.isActive }
    }
    
    var triggeredAlerts: [PriceAlert] {
        notificationService.priceAlerts.filter { !$0.isActive }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats Card
                PriceAlertStatsCard(
                    activeCount: activeAlerts.count,
                    triggeredCount: triggeredAlerts.count
                )
                
                // Active Alerts
                if !activeAlerts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Alerts")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(activeAlerts) { alert in
                            PriceAlertRow(
                                alert: alert,
                                onEdit: { selectedAlert = alert },
                                onDelete: { confirmDelete(alert) }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Triggered Alerts
                if !triggeredAlerts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Triggered Alerts")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: clearTriggeredAlerts) {
                                Text("Clear All")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        }
                        .padding(.horizontal)
                        
                        ForEach(triggeredAlerts) { alert in
                            PriceAlertRow(
                                alert: alert,
                                onEdit: { },
                                onDelete: { notificationService.deletePriceAlert(alert.id) }
                            )
                            .padding(.horizontal)
                            .opacity(0.7)
                        }
                    }
                }
                
                // Empty State
                if notificationService.priceAlerts.isEmpty {
                    EmptyPriceAlertsView(onCreateAlert: { showingNewAlert = true })
                        .padding(.top, 50)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Price Alerts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewAlert = true }) {
                    Image(systemName: "plus")
                        .font(.body)
                }
            }
        }
        .sheet(isPresented: $showingNewAlert) {
            CreatePriceAlertView()
        }
        .sheet(item: $selectedAlert) { alert in
            EditPriceAlertView(alert: alert)
        }
        .alert("Delete Alert", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let alert = alertToDelete {
                    notificationService.deletePriceAlert(alert.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this price alert?")
        }
    }
    
    private func confirmDelete(_ alert: PriceAlert) {
        alertToDelete = alert
        showingDeleteConfirmation = true
    }
    
    private func clearTriggeredAlerts() {
        for alert in triggeredAlerts {
            notificationService.deletePriceAlert(alert.id)
        }
    }
}

// MARK: - Stats Card
struct PriceAlertStatsCard: View {
    let activeCount: Int
    let triggeredCount: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                icon: "bell",
                value: "\(activeCount)",
                label: "Active",
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                icon: "checkmark.circle",
                value: "\(triggeredCount)",
                label: "Triggered",
                color: .green
            )
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    struct StatItem: View {
        let icon: String
        let value: String
        let label: String
        let color: Color
        @EnvironmentObject var themeManager: ThemeManager
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(label)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Price Alert Row
struct PriceAlertRow: View {
    let alert: PriceAlert
    let onEdit: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Symbol
                Text(alert.symbol)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Status
                if alert.isActive {
                    Label("Active", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Triggered", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            // Condition
            HStack(spacing: 4) {
                Image(systemName: alert.condition.icon)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                
                Text(alert.condition.description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Text(formatPrice(alert.targetPrice))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            // Additional Info
            HStack {
                if let note = alert.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let triggeredAt = alert.triggeredAt {
                    Text("Triggered \(triggeredAt.relative())")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                } else {
                    Text("Created \(alert.createdAt.relative())")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            // Actions
            if alert.isActive {
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                    
                    Divider()
                        .frame(height: 12)
                    
                    Button(action: onDelete) {
                        Label("Delete", systemImage: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
        .cornerRadius(12)
    }
    
    private func formatPrice(_ price: Double) -> String {
        if price < 10 {
            return String(format: "%.5f", price)
        } else if price < 1000 {
            return String(format: "%.2f", price)
        } else {
            return String(format: "%.0f", price)
        }
    }
}

// MARK: - Create Price Alert View
struct CreatePriceAlertView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var notificationService = NotificationService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var symbol = ""
    @State private var condition: PriceAlertCondition = .above
    @State private var targetPrice = ""
    @State private var note = ""
    @State private var expiresIn = 0 // 0 = never
    
    private let expiryOptions = [
        (0, "Never"),
        (1, "1 Day"),
        (7, "1 Week"),
        (30, "1 Month")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Symbol Input
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Symbol", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.bodyMedium)
                        
                        TextField("EUR/USD, GBP/USD, etc.", text: $symbol)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                    }
                    
                    // Condition Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Condition", systemImage: "arrow.up.arrow.down")
                            .font(.bodyMedium)
                        
                        Picker("Condition", selection: $condition) {
                            ForEach(PriceAlertCondition.allCases, id: \.self) { condition in
                                Label(condition.description, systemImage: condition.icon)
                                    .tag(condition)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(8)
                    }
                    
                    // Target Price
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Target Price", systemImage: "dollarsign.circle")
                            .font(.bodyMedium)
                        
                        TextField("0.00000", text: $targetPrice)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Note (Optional)", systemImage: "note.text")
                            .font(.bodyMedium)
                        
                        TextField("e.g., Resistance level", text: $note)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Expiry
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Expires", systemImage: "clock")
                            .font(.bodyMedium)
                        
                        Picker("Expiry", selection: $expiresIn) {
                            ForEach(expiryOptions, id: \.0) { days, label in
                                Text(label).tag(days)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Info
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        
                        Text("You'll receive a notification when the price meets your condition")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    .padding()
                    .background(themeManager.currentTheme.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("New Price Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createAlert()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !symbol.isEmpty && Double(targetPrice) != nil
    }
    
    private func createAlert() {
        guard let price = Double(targetPrice) else { return }
        
        let expiresAt: Date? = expiresIn > 0 ? Date().addingTimeInterval(TimeInterval(expiresIn * 86400)) : nil
        
        let alert = PriceAlert(
            symbol: symbol.uppercased(),
            condition: condition,
            targetPrice: price,
            expiresAt: expiresAt,
            note: note.isEmpty ? nil : note
        )
        
        notificationService.createPriceAlert(alert)
        dismiss()
    }
}

// MARK: - Edit Price Alert View
struct EditPriceAlertView: View {
    let alert: PriceAlert
    @Environment(\.dismiss) var dismiss
    @StateObject private var notificationService = NotificationService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var targetPrice: String
    @State private var note: String
    @State private var isActive: Bool
    
    init(alert: PriceAlert) {
        self.alert = alert
        self._targetPrice = State(initialValue: String(format: "%.5f", alert.targetPrice))
        self._note = State(initialValue: alert.note ?? "")
        self._isActive = State(initialValue: alert.isActive)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Symbol (Read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Symbol", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.bodyMedium)
                        
                        Text(alert.symbol)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
                            .cornerRadius(8)
                    }
                    
                    // Condition (Read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Condition", systemImage: alert.condition.icon)
                            .font(.bodyMedium)
                        
                        Text(alert.condition.description)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
                            .cornerRadius(8)
                    }
                    
                    // Target Price
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Target Price", systemImage: "dollarsign.circle")
                            .font(.bodyMedium)
                        
                        TextField("0.00000", text: $targetPrice)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Note", systemImage: "note.text")
                            .font(.bodyMedium)
                        
                        TextField("e.g., Resistance level", text: $note)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Active Toggle
                    HStack {
                        Label("Active", systemImage: "bell")
                            .font(.bodyMedium)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isActive)
                            .labelsHidden()
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Edit Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        Double(targetPrice) != nil
    }
    
    private func saveChanges() {
        guard let price = Double(targetPrice) else { return }
        
        let updatedAlert = PriceAlert(
            id: alert.id,
            symbol: alert.symbol,
            condition: alert.condition,
            targetPrice: price,
            isActive: isActive,
            createdAt: alert.createdAt,
            triggeredAt: alert.triggeredAt,
            expiresAt: alert.expiresAt,
            note: note.isEmpty ? nil : note
        )
        
        notificationService.updatePriceAlert(updatedAlert)
        dismiss()
    }
}

// MARK: - Empty State
struct EmptyPriceAlertsView: View {
    let onCreateAlert: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text("No Price Alerts")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Create price alerts to get notified when your favorite instruments reach specific price levels")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: onCreateAlert) {
                Label("Create Alert", systemImage: "plus")
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(themeManager.currentTheme.accentColor)
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    NavigationView {
        PriceAlertsView()
            .environmentObject(ThemeManager())
    }
}