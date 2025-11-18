//
//  ChatRoomView.swift
//  Pipflow
//
//  Chat room interface for messaging
//

import SwiftUI
import Combine

struct ChatRoomView: View {
    let room: ChatRoom
    @StateObject private var chatService = ChatService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var messageText = ""
    @State private var scrollToBottom = false
    @State private var showingRoomInfo = false
    @State private var replyingTo: ChatMessage?
    @State private var editingMessage: ChatMessage?
    @State private var showingEmojiPicker = false
    @State private var selectedMessage: ChatMessage?
    @FocusState private var isInputFocused: Bool
    
    private var messages: [ChatMessage] {
        chatService.messages[room.id] ?? []
    }
    
    private var typingUsers: [UUID] {
        Array(chatService.typingUsers[room.id] ?? [])
            .filter { $0 != AuthService.shared.currentUser?.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ChatRoomHeader(
                room: room,
                typingUsers: typingUsers,
                onInfoTap: { showingRoomInfo = true }
            )
            
            Divider()
                .background(themeManager.currentTheme.separatorColor)
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            ChatMessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == AuthService.shared.currentUser?.id,
                                showAvatar: shouldShowAvatar(for: message),
                                onReply: { replyingTo = message },
                                onEdit: { 
                                    editingMessage = message
                                    messageText = extractText(from: message.content)
                                    isInputFocused = true
                                },
                                onReaction: { emoji in
                                    Task {
                                        try await chatService.addReaction(
                                            to: message.id,
                                            in: room.id,
                                            emoji: emoji
                                        )
                                    }
                                },
                                onDelete: {
                                    Task {
                                        try await chatService.deleteMessage(message.id, in: room.id)
                                    }
                                }
                            )
                            .id(message.id)
                            .contextMenu {
                                MessageContextMenu(
                                    message: message,
                                    isFromCurrentUser: message.senderId == AuthService.shared.currentUser?.id,
                                    onReply: { replyingTo = message },
                                    onEdit: {
                                        editingMessage = message
                                        messageText = extractText(from: message.content)
                                        isInputFocused = true
                                    },
                                    onCopy: {
                                        UIPasteboard.general.string = extractText(from: message.content)
                                    },
                                    onDelete: {
                                        Task {
                                            try await chatService.deleteMessage(message.id, in: room.id)
                                        }
                                    }
                                )
                            }
                        }
                        
                        // Scroll anchor
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .background(themeManager.currentTheme.backgroundColor)
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            
            // Typing indicator
            if !typingUsers.isEmpty {
                TypingIndicatorView(userCount: typingUsers.count)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            
            // Reply indicator
            if let replyingTo = replyingTo {
                ReplyIndicator(
                    message: replyingTo,
                    onCancel: { self.replyingTo = nil }
                )
            }
            
            // Input bar
            MessageInputBar(
                text: $messageText,
                isEditing: editingMessage != nil,
                onSend: sendMessage,
                onCancel: cancelEdit
            )
            .focused($isInputFocused)
        }
        .navigationTitle(room.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .background(themeManager.currentTheme.backgroundColor)
        .sheet(isPresented: $showingRoomInfo) {
            ChatRoomInfoView(room: room)
                .environmentObject(themeManager)
        }
        .onAppear {
            Task {
                await chatService.loadMessages(for: room.id)
            }
        }
        .onChange(of: messageText) { _ in
            if !messageText.isEmpty {
                chatService.sendTypingIndicator(in: room.id)
            }
        }
    }
    
    private func shouldShowAvatar(for message: ChatMessage) -> Bool {
        guard let index = messages.firstIndex(where: { $0.id == message.id }),
              index > 0 else { return true }
        
        let previousMessage = messages[index - 1]
        return previousMessage.senderId != message.senderId ||
               message.createdAt.timeIntervalSince(previousMessage.createdAt) > 300
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            if let editingMessage = editingMessage {
                // Edit existing message
                try await chatService.editMessage(
                    editingMessage.id,
                    in: room.id,
                    newText: messageText
                )
                self.editingMessage = nil
            } else {
                // Send new message
                try await chatService.sendTextMessage(
                    to: room.id,
                    text: messageText,
                    replyTo: replyingTo?.id
                )
                replyingTo = nil
            }
            messageText = ""
        }
    }
    
    private func cancelEdit() {
        editingMessage = nil
        messageText = ""
    }
    
    private func extractText(from content: MessageContent) -> String {
        switch content {
        case .text(let text):
            return text
        default:
            return ""
        }
    }
}

// MARK: - Chat Room Header
struct ChatRoomHeader: View {
    let room: ChatRoom
    let typingUsers: [UUID]
    let onInfoTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: room.type.icon)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(room.displayName)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                if !typingUsers.isEmpty {
                    Text("\(typingUsers.count) typing...")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                } else if room.type == .channel || room.type == .group {
                    Text("\(room.participants.count) members")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                } else if room.type == .direct {
                    Text("Active now")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "phone")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                Button(action: {}) {
                    Image(systemName: "video")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
                
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
    }
}

// MARK: - Message Bubble
struct ChatMessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let showAvatar: Bool
    let onReply: () -> Void
    let onEdit: () -> Void
    let onReaction: (String) -> Void
    let onDelete: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showReactions = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isFromCurrentUser && showAvatar {
                // Avatar
                Circle()
                    .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("U")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    )
            } else if !isFromCurrentUser {
                // Avatar spacer
                Color.clear
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Reply indicator
                if let replyToId = message.replyTo,
                   let replyToMessage = chatService.messages[message.roomId]?.first(where: { $0.id == replyToId }) {
                    ReplyPreview(message: replyToMessage)
                        .font(.caption)
                }
                
                // Message content
                HStack {
                    if isFromCurrentUser { Spacer(minLength: 60) }
                    
                    MessageContentView(message: message)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            isFromCurrentUser
                                ? themeManager.currentTheme.accentColor
                                : themeManager.currentTheme.secondaryBackgroundColor
                        )
                        .foregroundColor(
                            isFromCurrentUser
                                ? .white
                                : themeManager.currentTheme.textColor
                        )
                        .cornerRadius(16, corners: isFromCurrentUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                    
                    if !isFromCurrentUser { Spacer(minLength: 60) }
                }
                
                // Reactions
                if !message.reactions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(message.reactions, id: \.emoji) { reaction in
                            ReactionBubble(
                                reaction: reaction,
                                hasReacted: reaction.users.contains(AuthService.shared.currentUser?.id ?? UUID()),
                                onTap: { onReaction(reaction.emoji) }
                            )
                        }
                        
                        Button(action: { showReactions = true }) {
                            Image(systemName: "plus.circle")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    .padding(.top, 2)
                }
                
                // Timestamp & status
                HStack(spacing: 4) {
                    if message.editedAt != nil {
                        Text("edited")
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Text(message.createdAt.chatTimeFormat())
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    if isFromCurrentUser {
                        Image(systemName: message.readBy.count > 1 ? "checkmark.circle.fill" : "checkmark")
                            .font(.caption2)
                            .foregroundColor(
                                message.readBy.count > 1
                                    ? themeManager.currentTheme.accentColor
                                    : themeManager.currentTheme.secondaryTextColor
                            )
                    }
                }
            }
            
            if isFromCurrentUser && showAvatar {
                // Current user avatar
                Circle()
                    .fill(themeManager.currentTheme.accentColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("Me")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    )
            } else if isFromCurrentUser {
                // Avatar spacer
                Color.clear
                    .frame(width: 32, height: 32)
            }
        }
        .sheet(isPresented: $showReactions) {
            EmojiPickerView(onSelect: onReaction)
                .presentationDetents([.height(300)])
        }
    }
    
    @StateObject private var chatService = ChatService.shared
}

// MARK: - Message Content View
struct MessageContentView: View {
    let message: ChatMessage
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        switch message.content {
        case .text(let text):
            Text(text)
                .font(.body)
            
        case .tradingSignal(let signal):
            TradingSignalView(signal: signal)
            
        case .media(let media):
            MediaMessageView(media: media)
            
        case .trade(let trade):
            TradeMessageView(trade: trade)
            
        case .poll(let poll):
            PollMessageView(poll: poll)
            
        case .system(let system):
            SystemMessageView(system: system)
            
        case .achievement(let achievement):
            AchievementMessageView(achievement: achievement)
        }
    }
}

// MARK: - Reaction Bubble
struct ReactionBubble: View {
    let reaction: MessageReaction
    let hasReacted: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(reaction.emoji)
                    .font(.caption)
                
                if reaction.count > 1 {
                    Text("\(reaction.count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                hasReacted
                    ? themeManager.currentTheme.accentColor.opacity(0.2)
                    : themeManager.currentTheme.secondaryBackgroundColor
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        hasReacted
                            ? themeManager.currentTheme.accentColor
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Message Input Bar
struct MessageInputBar: View {
    @Binding var text: String
    let isEditing: Bool
    let onSend: () -> Void
    let onCancel: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showAttachments = false
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(themeManager.currentTheme.separatorColor)
            
            HStack(spacing: 12) {
                // Attachment button
                Button(action: { showAttachments.toggle() }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                // Text field
                HStack {
                    TextField("Type a message...", text: $text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...5)
                        .onSubmit(onSend)
                    
                    if isEditing {
                        Button("Cancel", action: onCancel)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(themeManager.currentTheme.secondaryBackgroundColor)
                .cornerRadius(20)
                
                // Send button
                Button(action: onSend) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(
                            text.isEmpty
                                ? themeManager.currentTheme.secondaryTextColor
                                : themeManager.currentTheme.accentColor
                        )
                }
                .disabled(text.isEmpty)
            }
            .padding()
            
            // Attachment options
            if showAttachments {
                AttachmentOptionsView()
                    .transition(.move(edge: .bottom))
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
}

// MARK: - Supporting Views
struct ReplyIndicator: View {
    let message: ChatMessage
    let onCancel: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Replying to")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                Text(extractPreview(from: message))
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(themeManager.currentTheme.secondaryBackgroundColor)
    }
    
    private func extractPreview(from message: ChatMessage) -> String {
        switch message.content {
        case .text(let text):
            return text
        default:
            return "Message"
        }
    }
}

struct ReplyPreview: View {
    let message: ChatMessage
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(themeManager.currentTheme.accentColor)
                .frame(width: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Reply")
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Text(extractPreview(from: message))
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .padding(.leading, 4)
        .opacity(0.7)
    }
    
    private func extractPreview(from message: ChatMessage) -> String {
        switch message.content {
        case .text(let text):
            return text
        default:
            return "Message"
        }
    }
}

struct TypingIndicatorView: View {
    let userCount: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(themeManager.currentTheme.accentColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: UUID()
                    )
            }
            
            Text("\(userCount) typing")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Message Context Menu
struct MessageContextMenu: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let onReply: () -> Void
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Group {
            Button(action: onReply) {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }
            
            if isFromCurrentUser && message.type == .text {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            if isFromCurrentUser {
                Divider()
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}