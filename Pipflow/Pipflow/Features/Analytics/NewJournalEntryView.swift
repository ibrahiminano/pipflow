//
//  NewJournalEntryView.swift
//  Pipflow
//
//  Create new trade journal entry
//

import SwiftUI
import PhotosUI

struct NewJournalEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var analyticsService = AnalyticsService.shared
    @StateObject private var positionTrackingService = PositionTrackingService.shared
    
    // Form fields
    @State private var selectedPosition: TrackedPosition?
    @State private var symbol = ""
    @State private var side: TradeSide = .buy
    @State private var entryPrice = ""
    @State private var exitPrice = ""
    @State private var quantity = ""
    @State private var profit = ""
    @State private var notes = ""
    @State private var selectedEmotions: Set<TradeEmotion> = []
    @State private var setupQuality = 3
    @State private var executionQuality = 3
    @State private var lessons = ""
    @State private var tags = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    
    private var recentPositions: [TrackedPosition] {
        positionTrackingService.trackedPositions.sorted { $0.openTime > $1.openTime }
    }
    
    var body: some View {
        NavigationView {
            Form {
                positionSelectionSection
                tradeDetailsSection
                psychologySection
                qualityRatingsSection
                lessonsSection
                photosSection
                tagsSection
            }
        }
        .navigationTitle("New Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveEntry()
                }
                .fontWeight(.semibold)
                .disabled(!isValidEntry)
            }
        }
        .onChange(of: selectedImages) { _ in
            loadImages()
        }
    }
    
    private var positionSelectionSection: some View {
        Section("Trade Details") {
            Picker("Select Position", selection: $selectedPosition) {
                Text("Manual Entry").tag(nil as TrackedPosition?)
                ForEach(recentPositions, id: \.id) { position in
                    HStack {
                        Text(position.symbol)
                        Spacer()
                        Text(formatCurrency(position.netPL))
                            .foregroundColor(position.netPL >= 0 ? Color.Theme.success : Color.Theme.error)
                    }
                    .tag(position as TrackedPosition?)
                }
            }
            .onChange(of: selectedPosition) { position in
                if let position = position {
                    fillFromPosition(position)
                }
            }
        }
    }
    
    private var tradeDetailsSection: some View {
        Group {
            if selectedPosition == nil {
                Section {
                    TextField("Symbol", text: $symbol)
                    
                    Picker("Side", selection: $side) {
                        Text("Buy").tag(TradeSide.buy)
                        Text("Sell").tag(TradeSide.sell)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        TextField("Entry Price", text: $entryPrice)
                            .keyboardType(.decimalPad)
                        Text("/")
                        TextField("Exit Price", text: $exitPrice)
                            .keyboardType(.decimalPad)
                    }
                    
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                    
                    TextField("Profit/Loss", text: $profit)
                        .keyboardType(.decimalPad)
                }
            }
        }
    }
    
    private var psychologySection: some View {
        Section("Trading Psychology") {
            VStack(alignment: .leading, spacing: 12) {
                Text("How were you feeling?")
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.secondaryText)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(TradeEmotion.allCases, id: \.self) { emotion in
                        EmotionSelectionChip(
                            emotion: emotion,
                            isSelected: selectedEmotions.contains(emotion),
                            action: {
                                if selectedEmotions.contains(emotion) {
                                    selectedEmotions.remove(emotion)
                                } else {
                                    selectedEmotions.insert(emotion)
                                }
                            }
                        )
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var qualityRatingsSection: some View {
        Section("Execution Quality") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Setup Quality")
                    Spacer()
                    Text("\(setupQuality)/5")
                        .foregroundColor(Color.Theme.secondaryText)
                }
                
                Slider(value: Binding(
                    get: { Double(setupQuality) },
                    set: { setupQuality = Int($0) }
                ), in: 1...5, step: 1)
                
                HStack {
                    Text("Execution Quality")
                    Spacer()
                    Text("\(executionQuality)/5")
                        .foregroundColor(Color.Theme.secondaryText)
                }
                
                Slider(value: Binding(
                    get: { Double(executionQuality) },
                    set: { executionQuality = Int($0) }
                ), in: 1...5, step: 1)
            }
        }
    }
    
    private var lessonsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                TextField("What did you learn?", text: $lessons, axis: .vertical)
                    .lineLimit(3...6)
                
                TextField("Additional notes...", text: $notes, axis: .vertical)
                    .lineLimit(4...8)
            }
        } header: {
            Text("Notes & Lessons")
        }
    }
    
    private var photosSection: some View {
        Section {
            PhotosPicker(
                selection: $selectedImages,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Label("Add Screenshots", systemImage: "camera")
                    .foregroundColor(Color.Theme.accent)
            }
            
            if !loadedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .cornerRadius(8)
                                
                                Button(action: {
                                    loadedImages.remove(at: index)
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white, in: Circle())
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        } header: {
            Text("Screenshots")
        }
    }
    
    private var tagsSection: some View {
        Section {
            TextField("Tags (comma separated)", text: $tags)
        } header: {
            Text("Tags")
        } footer: {
            Text("e.g., breakout, trend-following, news-driven")
                .font(.caption)
        }
    }
    
    private var isValidEntry: Bool {
        if selectedPosition != nil {
            return !notes.isEmpty
        } else {
            return !symbol.isEmpty && !notes.isEmpty
        }
    }
    
    private func fillFromPosition(_ position: TrackedPosition) {
        symbol = position.symbol
        side = position.type == .buy ? .buy : .sell
        entryPrice = "\(position.openPrice)"
        exitPrice = "\(position.currentPrice)"
        quantity = "\(position.volume)"
        profit = "\(position.netPL)"
    }
    
    private func loadImages() {
        Task {
            loadedImages = []
            for item in selectedImages {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        loadedImages.append(image)
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        let entry = TradeJournalEntry(
            id: UUID(),
            tradeId: UUID(uuidString: selectedPosition?.id ?? "") ?? UUID(),
            timestamp: Date(),
            symbol: symbol,
            side: side,
            entryPrice: Double(entryPrice) ?? 0,
            exitPrice: exitPrice.isEmpty ? nil : Double(exitPrice),
            quantity: Double(quantity) ?? 0,
            profit: profit.isEmpty ? nil : Double(profit),
            notes: notes,
            tags: tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            screenshots: [], // In production, upload images and store URLs
            emotions: Array(selectedEmotions),
            setupQuality: setupQuality,
            executionQuality: executionQuality,
            lessons: lessons.isEmpty ? nil : lessons
        )
        
        analyticsService.addJournalEntry(entry)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct EmotionSelectionChip: View {
    let emotion: TradeEmotion
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(emotion.color)
                    .frame(width: 10, height: 10)
                Text(emotion.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? emotion.color.opacity(0.2) : Color.Theme.secondary)
            .foregroundColor(isSelected ? emotion.color : Color.Theme.text)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? emotion.color : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct QualitySlider: View {
    let title: String
    @Binding var value: Int
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= value ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(star <= value ? Color.Theme.warning : Color.Theme.divider)
                            .onTapGesture {
                                value = star
                            }
                    }
                }
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
        }
    }
}

#Preview {
    NewJournalEntryView()
}