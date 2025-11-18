//
//  ForumService.swift
//  Pipflow
//
//  Service for managing community forum
//

import Foundation
import Combine

@MainActor
class ForumService: ObservableObject {
    static let shared = ForumService()
    
    @Published var categories: [ForumCategory] = []
    @Published var topics: [ForumTopic] = []
    @Published var currentTopic: ForumTopic?
    @Published var posts: [UUID: [ForumPost]] = [:] // topicId: posts
    
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var allTopicsCount: Int {
        topics.count
    }
    
    var trendingTopics: [ForumTopic] {
        // Return top 5 topics sorted by a combination of views and posts
        topics.sorted { ($0.viewsCount + $0.postsCount * 10) > ($1.viewsCount + $1.postsCount * 10) }
            .prefix(5)
            .enumerated()
            .map { index, topic in
                var updatedTopic = topic
                updatedTopic.rank = index + 1
                return updatedTopic
            }
    }
    
    private init() {
        loadCategories()
        loadTopics()
        loadInitialPosts()
    }
    
    // MARK: - Categories
    
    func loadCategories() {
        // Mock categories
        categories = [
            ForumCategory(
                id: UUID(),
                name: "General Discussion",
                description: "General trading topics and community chat",
                icon: "bubble.left.and.bubble.right",
                color: "007AFF",
                orderIndex: 0,
                isLocked: false,
                requiredRole: nil,
                topicCount: 156,
                postCount: 1234,
                lastPost: nil
            ),
            ForumCategory(
                id: UUID(),
                name: "Market Analysis",
                description: "Technical and fundamental market analysis",
                icon: "chart.line.uptrend.xyaxis",
                color: "34C759",
                orderIndex: 1,
                isLocked: false,
                requiredRole: nil,
                topicCount: 89,
                postCount: 567,
                lastPost: nil
            ),
            ForumCategory(
                id: UUID(),
                name: "Trading Strategies",
                description: "Share and discuss trading strategies",
                icon: "brain",
                color: "FF9500",
                orderIndex: 2,
                isLocked: false,
                requiredRole: .premium,
                topicCount: 67,
                postCount: 890,
                lastPost: nil
            ),
            ForumCategory(
                id: UUID(),
                name: "Education",
                description: "Learning resources and educational content",
                icon: "graduationcap",
                color: "AF52DE",
                orderIndex: 3,
                isLocked: false,
                requiredRole: nil,
                topicCount: 45,
                postCount: 234,
                lastPost: nil
            ),
            ForumCategory(
                id: UUID(),
                name: "Platform Updates",
                description: "Official announcements and updates",
                icon: "megaphone",
                color: "FF3B30",
                orderIndex: 4,
                isLocked: true,
                requiredRole: .admin,
                topicCount: 12,
                postCount: 89,
                lastPost: nil
            )
        ]
    }
    
    // MARK: - Topics
    
    func loadTopics() {
        // Mock topics
        var mockTopics: [ForumTopic] = []
        
        let titles = [
            "Best strategies for volatile markets?",
            "EUR/USD analysis - Major breakout incoming",
            "How to manage risk in crypto trading",
            "My journey from $1k to $50k in 6 months",
            "Weekly market wrap-up and predictions",
            "Gold hitting resistance - Time to short?",
            "Beginner's guide to Fibonacci retracements",
            "Psychology of trading: Dealing with losses",
            "AI signals accuracy discussion",
            "Platform feature request: Advanced charting"
        ]
        
        let tags = [
            ["strategy", "risk-management"],
            ["forex", "analysis", "EUR/USD"],
            ["crypto", "risk", "education"],
            ["success-story", "motivation"],
            ["market-analysis", "weekly"],
            ["gold", "commodities", "signals"],
            ["education", "technical-analysis"],
            ["psychology", "mindset"],
            ["AI", "signals", "discussion"],
            ["feature-request", "platform"]
        ]
        
        for (index, title) in titles.enumerated() {
            let viewsCount = Int.random(in: 100...5000)
            let postsCount = Int.random(in: 5...150)
            let topic = ForumTopic(
                id: UUID(),
                categoryId: categories.randomElement()!.id,
                authorId: UUID(),
                title: title,
                content: "This is a sample topic content discussing \(title.lowercased()). Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                tags: tags[index],
                isPinned: index < 2,
                isLocked: false,
                isFeatured: index == 3,
                viewCount: viewsCount,
                replyCount: postsCount,
                lastReply: nil,
                createdAt: Date().addingTimeInterval(Double(-index * 3600 * 24)),
                updatedAt: Date().addingTimeInterval(Double(-index * 3600 * 12)),
                votes: Int.random(in: 10...500),
                userVote: Bool.random() ? .upvote : nil,
                subscribers: Set(Array(repeating: UUID(), count: Int.random(in: 5...50))),
                rank: 0, // Will be set in trendingTopics computed property
                postsCount: postsCount,
                viewsCount: viewsCount
            )
            mockTopics.append(topic)
        }
        
        topics = mockTopics
    }
    
    private func loadInitialPosts() {
        // Load posts for trending topics
        for topic in topics.prefix(5) {
            posts[topic.id] = createMockPosts(for: topic.id)
        }
    }
    
    func createTopic(
        categoryId: UUID,
        title: String,
        content: String,
        tags: [String]
    ) async throws {
        let currentUserId = authService.currentUser?.id ?? UUID()
        
        let topic = ForumTopic(
            id: UUID(),
            categoryId: categoryId,
            authorId: currentUserId,
            title: title,
            content: content,
            tags: tags,
            isPinned: false,
            isLocked: false,
            isFeatured: false,
            viewCount: 0,
            replyCount: 0,
            lastReply: nil,
            createdAt: Date(),
            updatedAt: Date(),
            votes: 0,
            userVote: nil,
            subscribers: [currentUserId],
            rank: 0,
            postsCount: 0,
            viewsCount: 0
        )
        
        topics.insert(topic, at: 0)
        
        // Update category topic count
        if let index = categories.firstIndex(where: { $0.id == categoryId }) {
            var category = categories[index]
            category = ForumCategory(
                id: category.id,
                name: category.name,
                description: category.description,
                icon: category.icon,
                color: category.color,
                orderIndex: category.orderIndex,
                isLocked: category.isLocked,
                requiredRole: category.requiredRole,
                topicCount: category.topicCount + 1,
                postCount: category.postCount,
                lastPost: nil
            )
            categories[index] = category
        }
    }
    
    func voteTopic(_ topicId: UUID, voteType: VoteType) async throws {
        guard let index = topics.firstIndex(where: { $0.id == topicId }) else { return }
        
        var topic = topics[index]
        let currentVote = topic.userVote
        
        if currentVote == voteType {
            // Remove vote
            topic.userVote = nil
            topic.votes -= voteType == .upvote ? 1 : -1
        } else if currentVote == nil {
            // Add vote
            topic.userVote = voteType
            topic.votes += voteType == .upvote ? 1 : -1
        } else {
            // Change vote
            topic.userVote = voteType
            topic.votes += voteType == .upvote ? 2 : -2
        }
        
        topics[index] = topic
    }
    
    func subscribeTopic(_ topicId: UUID) async throws {
        guard let index = topics.firstIndex(where: { $0.id == topicId }) else { return }
        
        var topic = topics[index]
        let currentUserId = authService.currentUser?.id ?? UUID()
        
        if topic.subscribers.contains(currentUserId) {
            topic.subscribers.remove(currentUserId)
        } else {
            topic.subscribers.insert(currentUserId)
        }
        
        topics[index] = topic
    }
    
    // MARK: - Posts
    
    func loadPosts(for topicId: UUID) async {
        // Mock posts
        if posts[topicId] == nil {
            posts[topicId] = createMockPosts(for: topicId)
        }
        
        // Increment view count
        if let index = topics.firstIndex(where: { $0.id == topicId }) {
            topics[index].viewCount += 1
        }
    }
    
    func createPost(
        topicId: UUID,
        content: String,
        replyTo: UUID? = nil
    ) async throws {
        let currentUserId = authService.currentUser?.id ?? UUID()
        
        let post = ForumPost(
            id: UUID(),
            topicId: topicId,
            authorId: currentUserId,
            title: "Reply",
            content: content,
            category: "General",
            preview: String(content.prefix(100)),
            replyTo: replyTo,
            createdAt: Date(),
            updatedAt: nil,
            editedAt: nil,
            deletedAt: nil,
            votes: 0,
            replies: 0,
            likes: 0,
            views: 0,
            isPinned: false,
            userVote: nil,
            reactions: [],
            attachments: [],
            mentions: [],
            isAcceptedAnswer: false,
            isModeratorsChoice: false
        )
        
        if posts[topicId] == nil {
            posts[topicId] = []
        }
        posts[topicId]?.append(post)
        
        // Update topic
        if let index = topics.firstIndex(where: { $0.id == topicId }) {
            topics[index].replyCount += 1
            topics[index].lastReply = post
            topics[index].updatedAt = Date()
        }
    }
    
    func votePost(_ postId: UUID, in topicId: UUID, voteType: VoteType) async throws {
        guard let postIndex = posts[topicId]?.firstIndex(where: { $0.id == postId }) else { return }
        
        var post = posts[topicId]![postIndex]
        let currentVote = post.userVote
        
        if currentVote == voteType {
            // Remove vote
            post.userVote = nil
            post.votes -= voteType == .upvote ? 1 : -1
        } else if currentVote == nil {
            // Add vote
            post.userVote = voteType
            post.votes += voteType == .upvote ? 1 : -1
        } else {
            // Change vote
            post.userVote = voteType
            post.votes += voteType == .upvote ? 2 : -2
        }
        
        posts[topicId]![postIndex] = post
    }
    
    func addReaction(to postId: UUID, in topicId: UUID, type: ReactionType) async throws {
        guard let postIndex = posts[topicId]?.firstIndex(where: { $0.id == postId }) else { return }
        
        var post = posts[topicId]![postIndex]
        let currentUserId = authService.currentUser?.id ?? UUID()
        
        if let reactionIndex = post.reactions.firstIndex(where: { $0.type == type }) {
            var reaction = post.reactions[reactionIndex]
            
            if reaction.users.contains(currentUserId) {
                reaction.users.remove(currentUserId)
                reaction.count -= 1
                
                if reaction.count == 0 {
                    post.reactions.remove(at: reactionIndex)
                } else {
                    post.reactions[reactionIndex] = reaction
                }
            } else {
                reaction.users.insert(currentUserId)
                reaction.count += 1
                post.reactions[reactionIndex] = reaction
            }
        } else {
            let reaction = PostReaction(
                type: type,
                count: 1,
                users: [currentUserId]
            )
            post.reactions.append(reaction)
        }
        
        posts[topicId]![postIndex] = post
    }
    
    // MARK: - Filtering & Sorting
    
    func filterAndSortTopics(
        searchText: String,
        category: ForumCategory?,
        sortOption: CommunityForumView.SortOption
    ) -> [ForumTopic] {
        var filtered = topics
        
        // Filter by category
        if let category = category {
            filtered = filtered.filter { $0.categoryId == category.id }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            filtered = filtered.filter { topic in
                topic.title.localizedCaseInsensitiveContains(searchText) ||
                topic.content.localizedCaseInsensitiveContains(searchText) ||
                topic.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort
        switch sortOption {
        case .latest:
            filtered.sort { $0.createdAt > $1.createdAt }
        case .trending:
            filtered.sort { $0.votes > $1.votes }
        case .mostReplies:
            filtered.sort { $0.replyCount > $1.replyCount }
        case .mostViews:
            filtered.sort { $0.viewCount > $1.viewCount }
        }
        
        return filtered
    }
    
    // MARK: - Mock Data
    
    private func createMockPosts(for topicId: UUID) -> [ForumPost] {
        var mockPosts: [ForumPost] = []
        
        let contents = [
            "Great question! I've been trading volatile markets for years and here are my top strategies...",
            "I completely agree with the analysis. The technical indicators are showing a clear pattern.",
            "Has anyone tried using the AI signals for this? The accuracy has been impressive.",
            "Thanks for sharing! This is exactly what I was looking for. Very helpful.",
            "I have a different perspective on this. Based on my experience...",
            "This is gold! Bookmarking for future reference.",
            "Can you elaborate on the risk management aspect? That's where I struggle.",
            "Following this thread. Great discussion everyone!",
            "@previous_poster That's an excellent point. I hadn't considered that angle.",
            "Here's a chart that supports your analysis: [chart image would be here]"
        ]
        
        for (index, content) in contents.enumerated() {
            let categories = ["General", "Analysis", "Strategy", "Education", "Discussion"]
            let category = categories.randomElement()!
            let post = ForumPost(
                id: UUID(),
                topicId: topicId,
                authorId: UUID(),
                title: "Re: Discussion Post #\(index + 1)",
                content: content,
                category: category,
                preview: String(content.prefix(100)),
                replyTo: index > 5 ? mockPosts.randomElement()?.id : nil,
                createdAt: Date().addingTimeInterval(Double(index * 3600)),
                updatedAt: nil,
                editedAt: index == 3 ? Date() : nil,
                deletedAt: nil,
                votes: Int.random(in: 0...50),
                replies: Int.random(in: 0...20),
                likes: Int.random(in: 0...100),
                views: Int.random(in: 50...500),
                isPinned: index == 0,
                userVote: Bool.random() ? (Bool.random() ? .upvote : .downvote) : nil,
                reactions: index % 3 == 0 ? createMockReactions() : [],
                attachments: [],
                mentions: [],
                isAcceptedAnswer: index == 1,
                isModeratorsChoice: index == 2
            )
            mockPosts.append(post)
        }
        
        return mockPosts
    }
    
    private func createMockReactions() -> [PostReaction] {
        let types: [ReactionType] = [.like, .helpful, .insightful]
        return types.compactMap { type in
            if Bool.random() {
                return PostReaction(
                    type: type,
                    count: Int.random(in: 1...20),
                    users: Set(Array(repeating: UUID(), count: Int.random(in: 1...20)))
                )
            }
            return nil
        }
    }
}