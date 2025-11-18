//
//  TopicDetailView.swift
//  Pipflow
//
//  Detail view for forum topics with posts
//

import SwiftUI

struct TopicDetailView: View {
    let topic: ForumTopic
    @StateObject private var forumService = ForumService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var replyText = ""
    @State private var replyingTo: ForumPost?
    @State private var editingPost: ForumPost?
    @State private var showingActions = false
    @FocusState private var isReplyFocused: Bool
    
    private var posts: [ForumPost] {
        forumService.posts[topic.id] ?? []
    }
    
    private func getReplyToPost(topicId: UUID, replyToId: UUID) -> ForumPost? {
        return forumService.posts[topicId]?.first(where: { $0.id == replyToId })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Topic Header
                    TopicHeader(
                        topic: topic,
                        onVote: { voteType in
                            Task {
                                try await forumService.voteTopic(topic.id, voteType: voteType)
                            }
                        },
                        onSubscribe: {
                            Task {
                                try await forumService.subscribeTopic(topic.id)
                            }
                        }
                    )
                    .padding()
                    
                    Divider()
                        .background(themeManager.currentTheme.separatorColor)
                    
                    // Posts
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostView(
                                post: post,
                                isAccepted: post.isAcceptedAnswer,
                                isModeratorsChoice: post.isModeratorsChoice,
                                onReply: {
                                    replyingTo = post
                                    isReplyFocused = true
                                },
                                onVote: { voteType in
                                    Task {
                                        try await forumService.votePost(
                                            post.id,
                                            in: topic.id,
                                            voteType: voteType
                                        )
                                    }
                                },
                                onReaction: { reactionType in
                                    Task {
                                        try await forumService.addReaction(
                                            to: post.id,
                                            in: topic.id,
                                            type: reactionType
                                        )
                                    }
                                }
                            )
                            .id(post.id)
                            
                            if post != posts.last {
                                Divider()
                                    .background(themeManager.currentTheme.separatorColor)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .onAppear {
                Task {
                    await forumService.loadPosts(for: topic.id)
                }
            }
            
            // Reply Section
            if !topic.isLocked {
                VStack(spacing: 0) {
                    Divider()
                        .background(themeManager.currentTheme.separatorColor)
                    
                    if let replyingTo = replyingTo {
                        ReplyingToIndicator(
                            post: replyingTo,
                            onCancel: { self.replyingTo = nil }
                        )
                    }
                    
                    ReplyInputView(
                        text: $replyText,
                        isEditing: editingPost != nil,
                        onSend: sendReply,
                        onCancel: cancelEdit
                    )
                    .focused($isReplyFocused)
                }
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {}) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {}) {
                        Label(
                            topic.subscribers.contains(AuthService.shared.currentUser?.id ?? UUID()) ? "Unsubscribe" : "Subscribe",
                            systemImage: "bell"
                        )
                    }
                    
                    if topic.authorId == AuthService.shared.currentUser?.id {
                        Divider()
                        
                        Button(action: {}) {
                            Label("Edit Topic", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {}) {
                            Label("Delete Topic", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
        }
    }
    
    private func sendReply() {
        guard !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            if let editingPost = editingPost {
                // Edit post
                // Implementation for editing
                self.editingPost = nil
            } else {
                // Create new post
                try await forumService.createPost(
                    topicId: topic.id,
                    content: replyText,
                    replyTo: replyingTo?.id
                )
                replyingTo = nil
            }
            replyText = ""
        }
    }
    
    private func cancelEdit() {
        editingPost = nil
        replyText = ""
    }
}

// MARK: - Topic Header
struct TopicHeader: View {
    let topic: ForumTopic
    let onVote: (VoteType) -> Void
    let onSubscribe: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(topic.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(topic.content)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
    }
}

// MARK: - Post View
struct PostView: View {
    let post: ForumPost
    let isAccepted: Bool
    let isModeratorsChoice: Bool
    let onReply: () -> Void
    let onVote: (VoteType) -> Void
    let onReaction: (ReactionType) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post.content)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            HStack {
                Button("Reply", action: onReply)
                Spacer()
                Text("\(post.votes) votes")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.backgroundColor)
    }
}

// MARK: - Reply Input View
struct ReplyInputView: View {
    @Binding var text: String
    let isEditing: Bool
    let onSend: () -> Void
    let onCancel: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            TextField("Write a reply...", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
            
            HStack {
                if isEditing {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Send", action: onSend)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
    }
}

// MARK: - Replying To Indicator
struct ReplyingToIndicator: View {
    let post: ForumPost
    let onCancel: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text("Replying to post")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Spacer()
            
            Button("Cancel", action: onCancel)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(themeManager.currentTheme.separatorColor.opacity(0.3))
    }
}