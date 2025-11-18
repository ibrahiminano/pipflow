//
//  TradeJournalView.swift
//  Pipflow
//
//  Trade journal for tracking and analyzing trades
//

import SwiftUI
import PhotosUI

struct TradeJournalView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var showingNewEntry = false
    @State private var searchText = ""
    @State private var selectedEmotion: TradeEmotion? = nil
    @State private var selectedTag: String? = nil
    
    private var filteredEntries: [TradeJournalEntry] {
        var entries = analyticsService.journalEntries
        
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.symbol.localizedCaseInsensitiveContains(searchText) ||
                entry.notes.localizedCaseInsensitiveContains(searchText) ||
                entry.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if let emotion = selectedEmotion {
            entries = entries.filter { $0.emotions.contains(emotion) }
        }
        
        if let tag = selectedTag {
            entries = entries.filter { $0.tags.contains(tag) }
        }
        
        return entries.sorted { $0.timestamp > $1.timestamp }
    }
    
    private var allTags: [String] {
        Array(Set(analyticsService.journalEntries.flatMap { $0.tags })).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filters
                VStack(spacing: 12) {
                    SearchBar(text: $searchText, placeholder: "Search journal entries...")
                    
                    // Emotion Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TradeEmotion.allCases, id: \.self) { emotion in
                                EmotionChip(
                                    emotion: emotion,
                                    isSelected: selectedEmotion == emotion,
                                    action: {
                                        selectedEmotion = selectedEmotion == emotion ? nil : emotion
                                    }
                                )
                            }
                        }
                    }
                    
                    // Tag Filter
                    if !allTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(allTags, id: \.self) { tag in
                                    TagChip(
                                        tag: tag,
                                        isSelected: selectedTag == tag,
                                        action: {
                                            selectedTag = selectedTag == tag ? nil : tag
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.Theme.cardBackground)
                
                // Journal Entries
                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredEntries) { entry in
                                JournalEntryCard(entry: entry)
                                    .onTapGesture {
                                        // In production, navigate to detail view
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.Theme.background)
            .navigationTitle("Trade Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewEntry = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewJournalEntryView()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Color.Theme.secondaryText)
            
            Text("No Journal Entries")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Start documenting your trades to improve\nyour trading psychology and performance")
                .font(.subheadline)
                .foregroundColor(Color.Theme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: { showingNewEntry = true }) {
                Label("Create First Entry", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.Theme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct JournalEntryCard: View {
    let entry: TradeJournalEntry
    
    private var profitColor: Color {
        guard let profit = entry.profit else { return Color.Theme.text }
        return profit >= 0 ? Color.Theme.success : Color.Theme.error
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.symbol)
                        .font(.headline)
                    Text(entry.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                }
                
                Spacer()
                
                if let profit = entry.profit {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(profit))
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(profitColor)
                        Text(entry.side.rawValue)
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                    }
                }
            }
            
            // Quality Ratings
            HStack(spacing: 16) {
                QualityRating(title: "Setup", rating: entry.setupQuality)
                QualityRating(title: "Execution", rating: entry.executionQuality)
            }
            
            // Notes Preview
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.subheadline)
                    .foregroundColor(Color.Theme.text)
                    .lineLimit(2)
            }
            
            // Tags and Emotions
            HStack {
                // Emotions
                if !entry.emotions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(entry.emotions, id: \.self) { emotion in
                            Circle()
                                .fill(emotion.color)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                
                Spacer()
                
                // Tags
                if !entry.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(entry.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.Theme.accent.opacity(0.1))
                                .foregroundColor(Color.Theme.accent)
                                .cornerRadius(12)
                        }
                        
                        if entry.tags.count > 3 {
                            Text("+\(entry.tags.count - 3)")
                                .font(.caption2)
                                .foregroundColor(Color.Theme.secondaryText)
                        }
                    }
                }
            }
            
            // Screenshots indicator
            if !entry.screenshots.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.caption)
                    Text("\(entry.screenshots.count)")
                        .font(.caption)
                }
                .foregroundColor(Color.Theme.secondaryText)
            }
        }
        .padding()
        .background(Color.Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.Theme.shadow, radius: 2, x: 0, y: 1)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct QualityRating: View {
    let title: String
    let rating: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.Theme.secondaryText)
            
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundColor(star <= rating ? Color.Theme.warning : Color.Theme.divider)
            }
        }
    }
}

struct EmotionChip: View {
    let emotion: TradeEmotion
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(emotion.color)
                    .frame(width: 8, height: 8)
                Text(emotion.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? emotion.color.opacity(0.2) : Color.Theme.secondary)
            .foregroundColor(isSelected ? emotion.color : Color.Theme.text)
            .cornerRadius(16)
        }
    }
}

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.Theme.accent : Color.Theme.secondary)
                .foregroundColor(isSelected ? .white : Color.Theme.text)
                .cornerRadius(16)
        }
    }
}

#Preview {
    TradeJournalView()
}