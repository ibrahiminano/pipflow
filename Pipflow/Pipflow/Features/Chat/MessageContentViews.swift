//
//  MessageContentViews.swift
//  Pipflow
//
//  Specialized views for different message content types
//

import SwiftUI

// MARK: - Trading Signal View
struct TradingSignalView: View {
    let signal: TradingSignalContent
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(signal.action == .buy ? .green : .red)
                
                Text("Trading Signal")
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Confidence badge
                Text("\(Int(signal.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        signal.confidence > 0.8 ? Color.green :
                        signal.confidence > 0.6 ? Color.orange : Color.red
                    )
                    .cornerRadius(8)
            }
            
            // Signal details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(signal.symbol)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(signal.action.rawValue.uppercased())
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(signal.action == .buy ? .green : .red)
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Entry")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatPrice(Decimal(signal.entry)))
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stop Loss")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatPrice(Decimal(signal.stopLoss)))
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Take Profit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatPrice(Decimal(signal.takeProfit)))
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                if let analysis = signal.analysis {
                    Text(analysis)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(showDetails ? nil : 2)
                        .onTapGesture {
                            withAnimation {
                                showDetails.toggle()
                            }
                        }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                        Text("Copy Trade")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeManager.currentTheme.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.caption)
                        Text("Analyze")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeManager.currentTheme.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(12)
    }
    
    private func formatPrice(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 5
        return formatter.string(from: value as NSNumber) ?? "\(value)"
    }
}

// MARK: - Media Message View
struct MediaMessageView: View {
    let media: MediaContent
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if media.mimeType.starts(with: "image/") {
                // Image preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.currentTheme.secondaryBackgroundColor)
                        .frame(width: 200, height: 150)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                .onAppear {
                    // Simulate loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isLoading = false
                    }
                }
            } else if media.mimeType.starts(with: "video/") {
                // Video preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black)
                        .frame(width: 200, height: 150)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    if let duration = media.duration {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                            .position(x: 180, y: 130)
                    }
                }
            } else {
                // File attachment
                HStack {
                    Image(systemName: "doc.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(media.caption ?? "File")
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                        
                        Text(formatFileSize(media.size))
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                .padding(8)
                .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
                .cornerRadius(8)
            }
            
            if let caption = media.caption {
                Text(caption)
                    .font(.body)
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Trade Message View
struct TradeMessageView: View {
    let trade: TradeContent
    @EnvironmentObject var themeManager: ThemeManager
    
    private var tradeActionText: String {
        "\(trade.action.rawValue.uppercased()) \(formatVolume(Decimal(trade.volume)))"
    }
    
    private var percentageText: String {
        "\(trade.pnlPercentage >= 0 ? "+" : "")\(String(format: "%.2f", trade.pnlPercentage))%"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(trade.pnl >= 0 ? .green : .red)
                
                Text("Trade Update")
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                
                Spacer()
                
                TradeStatusBadge(status: trade.status)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trade.symbol)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(tradeActionText)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: trade.pnl >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        Text(formatPrice(Decimal(abs(trade.pnl))))
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(trade.pnl >= 0 ? .green : .red)
                    
                    Text(percentageText)
                        .font(.caption)
                        .foregroundColor(trade.pnl >= 0 ? .green : .red)
                }
            }
            
            HStack(spacing: 12) {
                Label("Entry: \(formatPrice(Decimal(trade.entryPrice)))", systemImage: "arrow.right.circle")
                    .font(.caption)
                
                Label("Current: \(formatPrice(Decimal(trade.currentPrice)))", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption)
            }
            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding(12)
        .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(12)
    }
    
    private func formatVolume(_ volume: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: volume as NSNumber) ?? "\(volume)"
    }
    
    private func formatPrice(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSNumber) ?? "$\(value)"
    }
}

// MARK: - Poll Message View
struct PollMessageView: View {
    let poll: PollContent
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedOptions: Set<UUID> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                
                Text("Poll")
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let expiresAt = poll.expiresAt {
                    Text("Ends \(expiresAt.relative())")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            Text(poll.question)
                .font(.body)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                ForEach(poll.options) { option in
                    PollOptionView(
                        option: option,
                        totalVotes: poll.totalVotes,
                        isSelected: selectedOptions.contains(option.id) || poll.userVote?.contains(option.id) ?? false,
                        hasVoted: poll.userVote != nil,
                        onTap: {
                            if poll.allowMultiple {
                                if selectedOptions.contains(option.id) {
                                    selectedOptions.remove(option.id)
                                } else {
                                    selectedOptions.insert(option.id)
                                }
                            } else {
                                selectedOptions = [option.id]
                            }
                        }
                    )
                }
            }
            
            if poll.userVote == nil && !selectedOptions.isEmpty {
                Button(action: {}) {
                    Text("Vote")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(themeManager.currentTheme.accentColor)
                        .cornerRadius(8)
                }
            }
            
            Text("\(poll.totalVotes) votes")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding(12)
        .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(12)
    }
}

struct PollOptionView: View {
    let option: PollOption
    let totalVotes: Int
    let isSelected: Bool
    let hasVoted: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    private var percentage: Int {
        guard totalVotes > 0 else { return 0 }
        return Int((Double(option.votes) / Double(totalVotes)) * 100)
    }
    
    var body: some View {
        Button(action: hasVoted ? {} : onTap) {
            ZStack(alignment: .leading) {
                // Background fill showing percentage
                if hasVoted {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                            .frame(width: geometry.size.width * CGFloat(percentage) / 100)
                    }
                }
                
                HStack {
                    if !hasVoted {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.body)
                            .foregroundColor(isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Text(option.text)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
                    
                    if hasVoted {
                        Text("\(percentage)%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected && !hasVoted ? themeManager.currentTheme.accentColor : themeManager.currentTheme.separatorColor,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(hasVoted)
    }
}

// MARK: - System Message View
struct SystemMessageView: View {
    let system: SystemMessageContent
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconForType(system.type))
                .font(.caption)
            
            Text(system.text)
                .font(.caption)
        }
        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(12)
    }
    
    private func iconForType(_ type: SystemMessageType) -> String {
        switch type {
        case .userJoined, .userAdded:
            return "person.badge.plus"
        case .userLeft, .userRemoved:
            return "person.badge.minus"
        case .roomCreated:
            return "plus.bubble"
        case .roomUpdated:
            return "pencil.circle"
        case .adminPromoted, .adminDemoted:
            return "person.circle"
        }
    }
}

// MARK: - Achievement Message View
struct AchievementMessageView: View {
    let achievement: AchievementContent
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text(achievement.icon)
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    achievement.rarity.color.opacity(0.2),
                    achievement.rarity.color.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.rarity.color, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// MARK: - Status Badge
struct TradeStatusBadge: View {
    let status: TradeStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending:
            return .orange
        case .open:
            return .blue
        case .closed:
            return .gray
        case .cancelled:
            return .red
        }
    }
}

// MARK: - Supporting Views
struct AttachmentOptionsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let options = [
        ("photo", "Photo"),
        ("camera", "Camera"),
        ("doc", "Document"),
        ("chart.line.uptrend.xyaxis", "Trading Signal"),
        ("location", "Location")
    ]
    
    var body: some View {
        HStack(spacing: 24) {
            ForEach(options, id: \.0) { icon, title in
                VStack(spacing: 8) {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        )
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                .onTapGesture {
                    // Handle attachment option
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
    }
}

struct EmojiPickerView: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    let emojis = ["👍", "❤️", "😂", "😮", "😢", "😡", "🎯", "🚀", "💪", "🙏", "👏", "🔥"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            onSelect(emoji)
                            dismiss()
                        }) {
                            Text(emoji)
                                .font(.largeTitle)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Date Extension
extension Date {
    func relative() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}