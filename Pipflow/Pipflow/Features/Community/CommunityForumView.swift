//
//  CommunityForumView.swift
//  Pipflow
//
//  Community forum interface for discussions
//

import SwiftUI

struct CommunityForumView: View {
    @StateObject private var forumService = ForumService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedCategory: ForumCategory?
    @State private var showNewTopic = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .latest
    
    enum SortOption: String, CaseIterable {
        case latest = "Latest"
        case trending = "Trending"
        case mostReplies = "Most Replies"
        case mostViews = "Most Views"
        
        var icon: String {
            switch self {
            case .latest: return "clock"
            case .trending: return "flame"
            case .mostReplies: return "bubble.left.and.bubble.right"
            case .mostViews: return "eye"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Categories
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Community")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Spacer()
                    
                    Button(action: { showNewTopic = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
                .padding()
                
                // Categories
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // All Topics
                        CategoryRow(
                            category: nil,
                            isSelected: selectedCategory == nil,
                            topicCount: forumService.allTopicsCount,
                            onTap: { selectedCategory = nil }
                        )
                        
                        ForEach(forumService.categories) { category in
                            CategoryRow(
                                category: category,
                                isSelected: selectedCategory?.id == category.id,
                                topicCount: category.topicCount,
                                onTap: { selectedCategory = category }
                            )
                        }
                    }
                    .padding()
                }
            }
            .frame(minWidth: 280)
            .background(themeManager.currentTheme.backgroundColor)
            
        } detail: {
            // Detail View - Topics
            if let category = selectedCategory {
                TopicsListView(
                    category: category,
                    searchText: $searchText,
                    sortOption: $sortOption
                )
                .environmentObject(themeManager)
            } else {
                AllTopicsView(
                    searchText: $searchText,
                    sortOption: $sortOption
                )
                .environmentObject(themeManager)
            }
        }
        .sheet(isPresented: $showNewTopic) {
            NewTopicView(preselectedCategory: selectedCategory)
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Category Row
struct CategoryRow: View {
    let category: ForumCategory?
    let isSelected: Bool
    let topicCount: Int
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            category != nil
                                ? Color(hex: category!.color).opacity(0.2)
                                : themeManager.currentTheme.accentColor.opacity(0.2)
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: category?.icon ?? "bubble.left.and.bubble.right.fill")
                        .font(.body)
                        .foregroundColor(
                            category != nil
                                ? Color(hex: category!.color)
                                : themeManager.currentTheme.accentColor
                        )
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(category?.name ?? "All Topics")
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    if let description = category?.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .lineLimit(1)
                    } else {
                        Text("\(topicCount) topics")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                if category?.isLocked ?? false {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? themeManager.currentTheme.accentColor.opacity(0.1)
                    : Color.clear
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - All Topics View
struct AllTopicsView: View {
    @Binding var searchText: String
    @Binding var sortOption: CommunityForumView.SortOption
    @StateObject private var forumService = ForumService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var filteredTopics: [ForumTopic] {
        forumService.filterAndSortTopics(
            searchText: searchText,
            category: nil,
            sortOption: sortOption
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            TopicsHeader(
                title: "All Topics",
                searchText: $searchText,
                sortOption: $sortOption
            )
            
            // Topics List
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Pinned Topics
                    let pinnedTopics = filteredTopics.filter { $0.isPinned }
                    if !pinnedTopics.isEmpty {
                        Section {
                            ForEach(pinnedTopics) { topic in
                                NavigationLink(destination: TopicDetailView(topic: topic)) {
                                    TopicRow(topic: topic, isPinned: true)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } header: {
                            HStack {
                                Image(systemName: "pin.fill")
                                Text("Pinned")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)
                        }
                    }
                    
                    // Regular Topics
                    ForEach(filteredTopics.filter { !$0.isPinned }) { topic in
                        NavigationLink(destination: TopicDetailView(topic: topic)) {
                            TopicRow(topic: topic, isPinned: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .background(themeManager.currentTheme.backgroundColor)
        }
    }
}

// MARK: - Topics List View
struct TopicsListView: View {
    let category: ForumCategory
    @Binding var searchText: String
    @Binding var sortOption: CommunityForumView.SortOption
    @StateObject private var forumService = ForumService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var filteredTopics: [ForumTopic] {
        forumService.filterAndSortTopics(
            searchText: searchText,
            category: category,
            sortOption: sortOption
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            TopicsHeader(
                title: category.name,
                icon: category.icon,
                color: Color(hex: category.color),
                searchText: $searchText,
                sortOption: $sortOption
            )
            
            // Topics List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTopics) { topic in
                        NavigationLink(destination: TopicDetailView(topic: topic)) {
                            TopicRow(topic: topic, isPinned: topic.isPinned)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .background(themeManager.currentTheme.backgroundColor)
        }
    }
}

// MARK: - Topics Header
struct TopicsHeader: View {
    let title: String
    var icon: String? = nil
    var color: Color? = nil
    @Binding var searchText: String
    @Binding var sortOption: CommunityForumView.SortOption
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color ?? themeManager.currentTheme.accentColor)
                }
                
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Search and Sort
            HStack(spacing: 12) {
                // Search
                SearchBar(text: $searchText, placeholder: "Search topics...")
                
                // Sort
                Menu {
                    ForEach(CommunityForumView.SortOption.allCases, id: \.self) { option in
                        Button(action: { sortOption = option }) {
                            Label(option.rawValue, systemImage: option.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: sortOption.icon)
                        Text(sortOption.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.bodyMedium)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            Divider()
                .background(themeManager.currentTheme.separatorColor)
        }
    }
}

// MARK: - Topic Row
struct TopicRow: View {
    let topic: ForumTopic
    let isPinned: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and badges
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(topic.title)
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .lineLimit(2)
                    
                    // Tags
                    if !topic.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(topic.tags.prefix(3), id: \.self) { tag in
                                TopicTag(text: tag)
                            }
                            if topic.tags.count > 3 {
                                Text("+\(topic.tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Badges
                VStack(alignment: .trailing, spacing: 4) {
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                    
                    if topic.isFeatured {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    
                    if topic.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
            
            // Content preview
            Text(topic.content)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .lineLimit(2)
            
            // Stats
            HStack(spacing: 16) {
                // Author
                HStack(spacing: 4) {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                        .frame(width: 20, height: 20)
                    Text("Author")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                // Stats
                HStack(spacing: 12) {
                    Label("\(topic.replyCount)", systemImage: "bubble.left")
                    Label("\(topic.viewCount)", systemImage: "eye")
                    Label("\(topic.votes)", systemImage: "arrow.up")
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Spacer()
                
                // Time
                Text(topic.createdAt.relative())
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Topic Tag
struct TopicTag: View {
    let text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Text("#\(text)")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(themeManager.currentTheme.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(themeManager.currentTheme.accentColor.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - New Topic View
struct NewTopicView: View {
    let preselectedCategory: ForumCategory?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var forumService = ForumService.shared
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: ForumCategory?
    @State private var tags = ""
    @State private var isPoll = false
    @State private var pollQuestion = ""
    @State private var pollOptions: [String] = ["", ""]
    @State private var isSubmitting = false
    
    var isValid: Bool {
        !title.isEmpty && !content.isEmpty && selectedCategory != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Menu {
                            ForEach(forumService.categories) { category in
                                Button(action: { selectedCategory = category }) {
                                    Label(category.name, systemImage: category.icon)
                                }
                            }
                        } label: {
                            HStack {
                                if let category = selectedCategory {
                                    Image(systemName: category.icon)
                                        .foregroundColor(Color(hex: category.color))
                                    Text(category.name)
                                        .foregroundColor(themeManager.currentTheme.textColor)
                                } else {
                                    Text("Select a category")
                                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                            .padding()
                            .background(themeManager.currentTheme.secondaryBackgroundColor)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        TextField("What's your topic about?", text: $title)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(themeManager.currentTheme.secondaryBackgroundColor)
                            .cornerRadius(8)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(themeManager.currentTheme.secondaryBackgroundColor)
                            .cornerRadius(8)
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        TextField("Add tags separated by commas", text: $tags)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(themeManager.currentTheme.secondaryBackgroundColor)
                            .cornerRadius(8)
                    }
                    
                    // Poll Option
                    Toggle(isOn: $isPoll) {
                        Label("Add a poll", systemImage: "chart.bar.xaxis")
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                    }
                    .toggleStyle(SwitchToggleStyle())
                    
                    if isPoll {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Poll question", text: $pollQuestion)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(themeManager.currentTheme.secondaryBackgroundColor)
                                .cornerRadius(8)
                            
                            ForEach(0..<pollOptions.count, id: \.self) { index in
                                HStack {
                                    TextField("Option \(index + 1)", text: $pollOptions[index])
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                                        .cornerRadius(8)
                                    
                                    if pollOptions.count > 2 {
                                        Button(action: { pollOptions.remove(at: index) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            
                            Button(action: { pollOptions.append("") }) {
                                Label("Add option", systemImage: "plus.circle")
                                    .font(.bodyMedium)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.backgroundColor)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("New Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        submitTopic()
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView("Posting...")
                                .padding()
                                .background(themeManager.currentTheme.secondaryBackgroundColor)
                                .cornerRadius(12)
                        )
                }
            }
        }
        .onAppear {
            selectedCategory = preselectedCategory
        }
    }
    
    private func submitTopic() {
        guard isValid else { return }
        
        Task {
            isSubmitting = true
            
            // Create topic
            let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            do {
                try await forumService.createTopic(
                    categoryId: selectedCategory!.id,
                    title: title,
                    content: content,
                    tags: tagArray
                )
                dismiss()
            } catch {
                // Handle error
            }
            
            isSubmitting = false
        }
    }
}

// Color extension removed - using the one from Color+Extensions.swift