//
//  NewTradeView.swift
//  Pipflow
//
//  Trade placement interface
//

import SwiftUI
import Combine

struct NewTradeView: View {
    let symbol: String
    let side: TradeSide
    let onComplete: () -> Void
    
    @StateObject private var executionService = TradeExecutionService.shared
    @StateObject private var webSocketService = MetaAPIWebSocketService.shared
    @StateObject private var metaAPIService = MetaAPIService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var volume = "0.01"
    @State private var stopLossPips = "50"
    @State private var takeProfitPips = "100"
    @State private var useStopLoss = true
    @State private var useTakeProfit = true
    @State private var comment = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    private func getCurrentPrice(for symbol: String, side: TradeSide) -> Double? {
        if let price = webSocketService.getPrice(for: symbol) {
            return side == .buy ? price.ask : price.bid
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Symbol & Price Section
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(symbol)
                                    .font(.system(size: 28, weight: .bold))
                                Text(side == .buy ? "Buy Order" : "Sell Order")
                                    .font(.subheadline)
                                    .foregroundColor(side == .buy ? Color.Theme.buy : Color.Theme.sell)
                            }
                            
                            Spacer()
                            
                            if let price = currentPrice {
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(String(format: "%.5f", price))
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color.Theme.text)
                                    Text("Current Price")
                                        .font(.caption)
                                        .foregroundColor(Color.Theme.text.opacity(0.6))
                                }
                            }
                        }
                        .padding()
                        .background(Color.Theme.cardBackground)
                        .cornerRadius(12)
                    }
                    
                    // Volume Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Volume")
                            .font(.headline)
                            .foregroundColor(Color.Theme.text)
                        
                        VStack(spacing: 16) {
                            HStack {
                                TextField("0.01", text: $volume)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .medium))
                                    .padding()
                                    .background(Color.Theme.surface)
                                    .cornerRadius(8)
                                
                                Text("lots")
                                    .font(.body)
                                    .foregroundColor(Color.Theme.text.opacity(0.6))
                                    .padding(.leading, 8)
                            }
                            
                            // Quick volume buttons
                            HStack(spacing: 12) {
                                ForEach([0.01, 0.1, 0.5, 1.0], id: \.self) { lotSize in
                                    Button(String(format: "%.2f", lotSize)) {
                                        volume = String(format: "%.2f", lotSize)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(volume == String(format: "%.2f", lotSize) ? Color.blue : Color.Theme.surface)
                                    .foregroundColor(volume == String(format: "%.2f", lotSize) ? .white : Color.Theme.text)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color.Theme.cardBackground)
                        .cornerRadius(12)
                    }
                    
                    // Risk Management Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Risk Management")
                            .font(.headline)
                            .foregroundColor(Color.Theme.text)
                        
                        VStack(spacing: 20) {
                            // Stop Loss
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("Stop Loss", isOn: $useStopLoss)
                                    .font(.body)
                                
                                if useStopLoss {
                                    HStack {
                                        TextField("50", text: $stopLossPips)
                                            .keyboardType(.numberPad)
                                            .font(.system(size: 20, weight: .medium))
                                            .padding()
                                            .background(Color.Theme.surface)
                                            .cornerRadius(8)
                                            .frame(width: 100)
                                        
                                        Text("pips")
                                            .font(.body)
                                            .foregroundColor(Color.Theme.text.opacity(0.6))
                                        
                                        Spacer()
                                        
                                        if let sl = calculatedStopLoss {
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("Stop at")
                                                    .font(.caption)
                                                    .foregroundColor(Color.Theme.text.opacity(0.6))
                                                Text(String(format: "%.5f", sl))
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(Color.Theme.error)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Take Profit
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("Take Profit", isOn: $useTakeProfit)
                                    .font(.body)
                                
                                if useTakeProfit {
                                    HStack {
                                        TextField("100", text: $takeProfitPips)
                                            .keyboardType(.numberPad)
                                            .font(.system(size: 20, weight: .medium))
                                            .padding()
                                            .background(Color.Theme.surface)
                                            .cornerRadius(8)
                                            .frame(width: 100)
                                        
                                        Text("pips")
                                            .font(.body)
                                            .foregroundColor(Color.Theme.text.opacity(0.6))
                                        
                                        Spacer()
                                        
                                        if let tp = calculatedTakeProfit {
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("Target at")
                                                    .font(.caption)
                                                    .foregroundColor(Color.Theme.text.opacity(0.6))
                                                Text(String(format: "%.5f", tp))
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(Color.Theme.success)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.Theme.cardBackground)
                        .cornerRadius(12)
                    }
                    
                    // Comment Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comment (Optional)")
                            .font(.headline)
                            .foregroundColor(Color.Theme.text)
                        
                        TextField("Trade comment", text: $comment)
                            .font(.body)
                            .padding()
                            .background(Color.Theme.surface)
                            .cornerRadius(8)
                            .padding()
                            .background(Color.Theme.cardBackground)
                            .cornerRadius(12)
                    }
                    
                    // Summary Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trade Summary")
                            .font(.headline)
                            .foregroundColor(Color.Theme.text)
                        
                        VStack(spacing: 16) {
                            TradeSummaryRow(label: "Direction", value: side == .buy ? "Buy" : "Sell", color: side == .buy ? Color.Theme.buy : Color.Theme.sell)
                            
                            Divider()
                            
                            TradeSummaryRow(label: "Volume", value: "\(volume) lots")
                            
                            if useStopLoss, let sl = calculatedStopLoss {
                                Divider()
                                TradeSummaryRow(label: "Stop Loss", value: String(format: "%.5f", sl), color: Color.Theme.error)
                            }
                            
                            if useTakeProfit, let tp = calculatedTakeProfit {
                                Divider()
                                TradeSummaryRow(label: "Take Profit", value: String(format: "%.5f", tp), color: Color.Theme.success)
                            }
                            
                            if let risk = estimatedRisk {
                                Divider()
                                TradeSummaryRow(label: "Estimated Risk", value: String(format: "$%.2f", risk), color: Color.Theme.error)
                            }
                            
                            if let profit = estimatedProfit {
                                Divider()
                                TradeSummaryRow(label: "Potential Profit", value: String(format: "$%.2f", profit), color: Color.Theme.success)
                            }
                        }
                        .padding()
                        .background(Color.Theme.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("New Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Place Order") {
                        Task {
                            await placeTrade()
                        }
                    }
                    .disabled(executionService.isExecuting || !isValidOrder)
                }
            }
            .alert("Trade Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if executionService.isExecuting {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Placing Order...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(Color.Theme.cardBackground)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentPrice: Double? {
        getCurrentPrice(for: symbol, side: side)
    }
    
    private var calculatedStopLoss: Double? {
        guard useStopLoss, let pips = Int(stopLossPips) else { return nil }
        return executionService.calculateStopLoss(for: symbol, side: side, pips: pips)
    }
    
    private var calculatedTakeProfit: Double? {
        guard useTakeProfit, let pips = Int(takeProfitPips) else { return nil }
        return executionService.calculateTakeProfit(for: symbol, side: side, pips: pips)
    }
    
    private var estimatedRisk: Double? {
        guard useStopLoss,
              let pips = Int(stopLossPips),
              let vol = Double(volume) else { return nil }
        return executionService.estimateProfit(for: symbol, side: side, volume: vol, pips: -pips)
    }
    
    private var estimatedProfit: Double? {
        guard useTakeProfit,
              let pips = Int(takeProfitPips),
              let vol = Double(volume) else { return nil }
        return executionService.estimateProfit(for: symbol, side: side, volume: vol, pips: pips)
    }
    
    private var isValidOrder: Bool {
        guard let vol = Double(volume), vol > 0 else { return false }
        
        if useStopLoss && calculatedStopLoss == nil { return false }
        if useTakeProfit && calculatedTakeProfit == nil { return false }
        
        return true
    }
    
    // MARK: - Methods
    
    private func placeTrade() async {
        guard let vol = Double(volume) else { return }
        
        let request = ExecutionTradeRequest(
            symbol: symbol,
            side: side,
            volume: vol,
            stopLoss: calculatedStopLoss,
            takeProfit: calculatedTakeProfit,
            comment: comment.isEmpty ? nil : comment,
            magicNumber: nil
        )
        
        do {
            let result = try await executionService.executeTrade(request)
            print("Trade executed: \(result.orderId)")
            
            await MainActor.run {
                onComplete()
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Supporting Views

struct TradeSummaryRow: View {
    let label: String
    let value: String
    var color: Color = Color.Theme.text
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color.Theme.text.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
        }
    }
}

struct QuickVolumeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
}

#Preview {
    NewTradeView(
        symbol: "EURUSD",
        side: .buy,
        onComplete: {}
    )
}