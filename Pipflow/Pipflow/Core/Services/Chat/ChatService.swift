//
//  ChatService.swift
//  Pipflow
//
//  Service for managing chat and real-time messaging
//

import Foundation
import Combine

@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()
    
    @Published var chatRooms: [ChatRoom] = []
    @Published var activeRoom: ChatRoom?
    @Published var messages: [UUID: [ChatMessage]] = [:] // roomId: messages
    @Published var typingUsers: [UUID: Set<UUID>] = [:] // roomId: userIds
    @Published var onlineUsers: Set<UUID> = []
    @Published var unreadCounts: [UUID: Int] = [:] // roomId: count
    
    private let supabaseService = SupabaseService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    private var messageSubscriptions: [UUID: AnyCancellable] = [:]
    
    private init() {
        setupSubscriptions()
        loadChatRooms()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Subscribe to auth changes
        authService.$currentUser
            .sink { [weak self] user in
                if user != nil {
                    self?.connectToChat()
                } else {
                    self?.disconnectFromChat()
                }
            }
            .store(in: &cancellables)
    }
    
    private func connectToChat() {
        // In production, connect to WebSocket
        // For now, load mock data
        loadChatRooms()
        subscribeToPresence()
    }
    
    private func disconnectFromChat() {
        // Clean up subscriptions
        messageSubscriptions.values.forEach { $0.cancel() }
        messageSubscriptions.removeAll()
        chatRooms.removeAll()
        messages.removeAll()
        onlineUsers.removeAll()
    }
    
    // MARK: - Chat Room Management
    
    func loadChatRooms() {
        // Load user's chat rooms
        // For now, create mock data
        let mockRooms = createMockChatRooms()
        chatRooms = mockRooms
        
        // Load unread counts
        mockRooms.forEach { room in
            unreadCounts[room.id] = room.unreadCount
        }
    }
    
    func createDirectChat(with userId: UUID) async throws -> ChatRoom {
        // Check if direct chat already exists
        if let existingRoom = chatRooms.first(where: { room in
            room.type == .direct && room.participants.contains(userId)
        }) {
            return existingRoom
        }
        
        // Create new direct chat
        let currentUserId = authService.currentUser?.id ?? UUID()
        let room = ChatRoom(
            id: UUID(),
            type: .direct,
            name: nil,
            description: nil,
            avatarURL: nil,
            participants: [currentUserId, userId],
            admins: [],
            createdAt: Date(),
            updatedAt: Date(),
            lastMessage: nil,
            unreadCount: 0,
            isPinned: false,
            isMuted: false,
            settings: ChatRoomSettings(
                allowedMessageTypes: Set(MessageType.allCases),
                maxParticipants: 2,
                isPublic: false,
                requiresApproval: false,
                allowedRoles: UserRole.allCases,
                features: [.voiceMessages, .fileSharing, .tradingSignals]
            )
        )
        
        chatRooms.append(room)
        return room
    }
    
    func createGroupChat(name: String, participants: [UUID]) async throws -> ChatRoom {
        let currentUserId = authService.currentUser?.id ?? UUID()
        var allParticipants = participants
        if !allParticipants.contains(currentUserId) {
            allParticipants.append(currentUserId)
        }
        
        let room = ChatRoom(
            id: UUID(),
            type: .group,
            name: name,
            description: nil,
            avatarURL: nil,
            participants: allParticipants,
            admins: [currentUserId],
            createdAt: Date(),
            updatedAt: Date(),
            lastMessage: nil,
            unreadCount: 0,
            isPinned: false,
            isMuted: false,
            settings: ChatRoomSettings(
                allowedMessageTypes: Set(MessageType.allCases),
                maxParticipants: 50,
                isPublic: false,
                requiresApproval: false,
                allowedRoles: UserRole.allCases,
                features: Set(ChatFeature.allCases)
            )
        )
        
        chatRooms.append(room)
        subscribeToRoom(room)
        return room
    }
    
    func joinChannel(_ channelId: UUID) async throws {
        // Implementation for joining public channels
    }
    
    func leaveRoom(_ roomId: UUID) async throws {
        chatRooms.removeAll { $0.id == roomId }
        messages[roomId] = nil
        unreadCounts[roomId] = nil
        messageSubscriptions[roomId]?.cancel()
        messageSubscriptions[roomId] = nil
    }
    
    // MARK: - Message Management
    
    func loadMessages(for roomId: UUID) async {
        // In production, fetch from Supabase
        // For now, create mock messages
        if messages[roomId] == nil {
            messages[roomId] = createMockMessages(for: roomId)
        }
    }
    
    func sendMessage(
        to roomId: UUID,
        type: MessageType,
        content: MessageContent,
        replyTo: UUID? = nil
    ) async throws {
        let currentUserId = authService.currentUser?.id ?? UUID()
        
        let message = ChatMessage(
            id: UUID(),
            roomId: roomId,
            senderId: currentUserId,
            type: type,
            content: content,
            createdAt: Date(),
            updatedAt: nil,
            editedAt: nil,
            deletedAt: nil,
            readBy: [currentUserId],
            reactions: [],
            replyTo: replyTo,
            mentions: extractMentions(from: content),
            isPinned: false,
            metadata: nil
        )
        
        // Add to local messages
        if messages[roomId] == nil {
            messages[roomId] = []
        }
        messages[roomId]?.append(message)
        
        // Update last message in room
        if let index = chatRooms.firstIndex(where: { $0.id == roomId }) {
            var updatedRoom = chatRooms[index]
            updatedRoom = ChatRoom(
                id: updatedRoom.id,
                type: updatedRoom.type,
                name: updatedRoom.name,
                description: updatedRoom.description,
                avatarURL: updatedRoom.avatarURL,
                participants: updatedRoom.participants,
                admins: updatedRoom.admins,
                createdAt: updatedRoom.createdAt,
                updatedAt: Date(),
                lastMessage: message,
                unreadCount: 0,
                isPinned: updatedRoom.isPinned,
                isMuted: updatedRoom.isMuted,
                settings: updatedRoom.settings
            )
            chatRooms[index] = updatedRoom
        }
        
        // In production, send to Supabase
    }
    
    func sendTextMessage(to roomId: UUID, text: String, replyTo: UUID? = nil) async throws {
        try await sendMessage(
            to: roomId,
            type: .text,
            content: .text(text),
            replyTo: replyTo
        )
    }
    
    func editMessage(_ messageId: UUID, in roomId: UUID, newText: String) async throws {
        guard let messageIndex = messages[roomId]?.firstIndex(where: { $0.id == messageId }) else {
            return
        }
        
        var message = messages[roomId]![messageIndex]
        
        // Create edit record
        let editRecord = EditRecord(
            editedAt: Date(),
            previousContent: {
                if case .text(let text) = message.content {
                    return text
                }
                return ""
            }(),
            editedBy: authService.currentUser?.id ?? UUID()
        )
        
        // Update message
        var metadata = message.metadata ?? MessageMetadata(
            editHistory: [],
            forwardedFrom: nil,
            scheduledAt: nil,
            expiresAt: nil,
            isAnnouncement: false
        )
        
        var editHistory = metadata.editHistory ?? []
        editHistory.append(editRecord)
        
        metadata = MessageMetadata(
            editHistory: editHistory,
            forwardedFrom: metadata.forwardedFrom,
            scheduledAt: metadata.scheduledAt,
            expiresAt: metadata.expiresAt,
            isAnnouncement: metadata.isAnnouncement
        )
        
        message = ChatMessage(
            id: message.id,
            roomId: message.roomId,
            senderId: message.senderId,
            type: message.type,
            content: .text(newText),
            createdAt: message.createdAt,
            updatedAt: Date(),
            editedAt: Date(),
            deletedAt: message.deletedAt,
            readBy: message.readBy,
            reactions: message.reactions,
            replyTo: message.replyTo,
            mentions: extractMentions(from: .text(newText)),
            isPinned: message.isPinned,
            metadata: metadata
        )
        
        messages[roomId]![messageIndex] = message
    }
    
    func deleteMessage(_ messageId: UUID, in roomId: UUID) async throws {
        guard let messageIndex = messages[roomId]?.firstIndex(where: { $0.id == messageId }) else {
            return
        }
        
        messages[roomId]?.remove(at: messageIndex)
    }
    
    func addReaction(to messageId: UUID, in roomId: UUID, emoji: String) async throws {
        guard let messageIndex = messages[roomId]?.firstIndex(where: { $0.id == messageId }) else {
            return
        }
        
        var message = messages[roomId]![messageIndex]
        let currentUserId = authService.currentUser?.id ?? UUID()
        
        // Find or create reaction
        if let reactionIndex = message.reactions.firstIndex(where: { $0.emoji == emoji }) {
            var reaction = message.reactions[reactionIndex]
            var users = reaction.users
            
            if users.contains(currentUserId) {
                users.remove(currentUserId)
            } else {
                users.insert(currentUserId)
            }
            
            if users.isEmpty {
                message.reactions.remove(at: reactionIndex)
            } else {
                reaction = MessageReaction(emoji: emoji, users: users)
                message.reactions[reactionIndex] = reaction
            }
        } else {
            let reaction = MessageReaction(emoji: emoji, users: [currentUserId])
            message.reactions.append(reaction)
        }
        
        messages[roomId]![messageIndex] = message
    }
    
    // MARK: - Real-time Features
    
    func sendTypingIndicator(in roomId: UUID) {
        let currentUserId = authService.currentUser?.id ?? UUID()
        
        if typingUsers[roomId] == nil {
            typingUsers[roomId] = []
        }
        typingUsers[roomId]?.insert(currentUserId)
        
        // Remove after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.typingUsers[roomId]?.remove(currentUserId)
        }
    }
    
    func markAsRead(roomId: UUID) {
        unreadCounts[roomId] = 0
        
        // Mark all messages as read
        let currentUserId = authService.currentUser?.id ?? UUID()
        messages[roomId]?.indices.forEach { index in
            messages[roomId]![index].readBy.insert(currentUserId)
        }
    }
    
    // MARK: - Presence
    
    private func subscribeToPresence() {
        // In production, subscribe to Supabase presence
        // For now, simulate some online users
        onlineUsers = Set([UUID(), UUID(), UUID()])
    }
    
    func updateStatus(_ status: UserStatus) {
        // Update user's online status
    }
    
    // MARK: - Search
    
    func searchMessages(query: String, in roomId: UUID? = nil) -> [ChatMessage] {
        let searchQuery = query.lowercased()
        var allMessages: [ChatMessage] = []
        
        if let roomId = roomId {
            allMessages = messages[roomId] ?? []
        } else {
            allMessages = messages.values.flatMap { $0 }
        }
        
        return allMessages.filter { message in
            switch message.content {
            case .text(let text):
                return text.lowercased().contains(searchQuery)
            case .tradingSignal(let signal):
                return signal.symbol.lowercased().contains(searchQuery) ||
                       signal.analysis?.lowercased().contains(searchQuery) ?? false
            default:
                return false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractMentions(from content: MessageContent) -> [UUID] {
        // Extract @mentions from message content
        // This is a simplified implementation
        return []
    }
    
    private func subscribeToRoom(_ room: ChatRoom) {
        // Subscribe to real-time updates for this room
        let subscription = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                // In production, this would be a WebSocket subscription
                self?.simulateIncomingMessage(in: room.id)
            }
        
        messageSubscriptions[room.id] = subscription
    }
    
    private func simulateIncomingMessage(in roomId: UUID) {
        // Simulate receiving a message (for demo purposes)
        guard Bool.random() else { return }
        
        let senderIds = [UUID(), UUID(), UUID()]
        let senderId = senderIds.randomElement()!
        
        let messages = [
            "Great analysis! 📊",
            "What's your take on EUR/USD?",
            "Just closed a profitable trade 🎯",
            "Thanks for sharing!",
            "Anyone trading gold today?"
        ]
        
        let message = ChatMessage(
            id: UUID(),
            roomId: roomId,
            senderId: senderId,
            type: .text,
            content: .text(messages.randomElement()!),
            createdAt: Date(),
            updatedAt: nil,
            editedAt: nil,
            deletedAt: nil,
            readBy: [senderId],
            reactions: [],
            replyTo: nil,
            mentions: [],
            isPinned: false,
            metadata: nil
        )
        
        if self.messages[roomId] == nil {
            self.messages[roomId] = []
        }
        self.messages[roomId]?.append(message)
        
        // Increment unread count if not in active room
        if activeRoom?.id != roomId {
            unreadCounts[roomId] = (unreadCounts[roomId] ?? 0) + 1
        }
    }
    
    // MARK: - Mock Data
    
    private func createMockChatRooms() -> [ChatRoom] {
        let currentUserId = authService.currentUser?.id ?? UUID()
        
        return [
            // AI Assistant
            ChatRoom(
                id: UUID(),
                type: .aiAssistant,
                name: "Pipflow AI Assistant",
                description: "Your personal trading AI assistant",
                avatarURL: nil,
                participants: [currentUserId],
                admins: [],
                createdAt: Date().addingTimeInterval(-86400 * 7),
                updatedAt: Date().addingTimeInterval(-3600),
                lastMessage: ChatMessage(
                    id: UUID(),
                    roomId: UUID(),
                    senderId: UUID(),
                    type: .text,
                    content: .text("How can I help you with your trading today?"),
                    createdAt: Date().addingTimeInterval(-3600),
                    updatedAt: nil,
                    editedAt: nil,
                    deletedAt: nil,
                    readBy: [currentUserId],
                    reactions: [],
                    replyTo: nil,
                    mentions: [],
                    isPinned: false,
                    metadata: nil
                ),
                unreadCount: 0,
                isPinned: true,
                isMuted: false,
                settings: ChatRoomSettings(
                    allowedMessageTypes: Set(MessageType.allCases),
                    maxParticipants: 2,
                    isPublic: false,
                    requiresApproval: false,
                    allowedRoles: UserRole.allCases,
                    features: [.tradingSignals, .fileSharing]
                )
            ),
            
            // Trading Signals Channel
            ChatRoom(
                id: UUID(),
                type: .channel,
                name: "📊 Trading Signals",
                description: "Premium trading signals from top traders",
                avatarURL: nil,
                participants: Array(repeating: UUID(), count: 234),
                admins: [UUID()],
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date().addingTimeInterval(-1800),
                lastMessage: ChatMessage(
                    id: UUID(),
                    roomId: UUID(),
                    senderId: UUID(),
                    type: .tradingSignal,
                    content: .tradingSignal(TradingSignalContent(
                        signalId: UUID(),
                        symbol: "EUR/USD",
                        action: .buy,
                        entry: 1.0856,
                        stopLoss: 1.0826,
                        takeProfit: 1.0906,
                        confidence: 0.85,
                        analysis: "Strong support at 1.0850 with bullish divergence"
                    )),
                    createdAt: Date().addingTimeInterval(-1800),
                    updatedAt: nil,
                    editedAt: nil,
                    deletedAt: nil,
                    readBy: [currentUserId],
                    reactions: [
                        MessageReaction(emoji: "🚀", users: Set(Array(repeating: UUID(), count: 15))),
                        MessageReaction(emoji: "🎯", users: Set(Array(repeating: UUID(), count: 8)))
                    ],
                    replyTo: nil,
                    mentions: [],
                    isPinned: true,
                    metadata: nil
                ),
                unreadCount: 3,
                isPinned: true,
                isMuted: false,
                settings: ChatRoomSettings(
                    allowedMessageTypes: [.text, .tradingSignal, .image],
                    maxParticipants: nil,
                    isPublic: true,
                    requiresApproval: false,
                    allowedRoles: [.premium, .mentor, .moderator, .admin],
                    features: [.tradingSignals, .polls, .events]
                )
            ),
            
            // General Chat
            ChatRoom(
                id: UUID(),
                type: .channel,
                name: "💬 General Chat",
                description: "Community discussion about trading",
                avatarURL: nil,
                participants: Array(repeating: UUID(), count: 567),
                admins: [UUID(), UUID()],
                createdAt: Date().addingTimeInterval(-86400 * 90),
                updatedAt: Date().addingTimeInterval(-300),
                lastMessage: ChatMessage(
                    id: UUID(),
                    roomId: UUID(),
                    senderId: UUID(),
                    type: .text,
                    content: .text("Anyone else seeing this bullish pattern on Gold? 📈"),
                    createdAt: Date().addingTimeInterval(-300),
                    updatedAt: nil,
                    editedAt: nil,
                    deletedAt: nil,
                    readBy: Set(Array(repeating: UUID(), count: 45)),
                    reactions: [
                        MessageReaction(emoji: "👍", users: Set(Array(repeating: UUID(), count: 12)))
                    ],
                    replyTo: nil,
                    mentions: [],
                    isPinned: false,
                    metadata: nil
                ),
                unreadCount: 15,
                isPinned: false,
                isMuted: false,
                settings: ChatRoomSettings(
                    allowedMessageTypes: Set(MessageType.allCases),
                    maxParticipants: nil,
                    isPublic: true,
                    requiresApproval: false,
                    allowedRoles: UserRole.allCases,
                    features: Set(ChatFeature.allCases)
                )
            )
        ]
    }
    
    private func createMockMessages(for roomId: UUID) -> [ChatMessage] {
        let currentUserId = authService.currentUser?.id ?? UUID()
        let otherUserIds = [UUID(), UUID(), UUID()]
        
        var mockMessages: [ChatMessage] = []
        
        // Create a variety of message types
        for i in 0..<20 {
            let senderId = i % 3 == 0 ? currentUserId : otherUserIds.randomElement()!
            let createdAt = Date().addingTimeInterval(Double(-3600 * (20 - i)))
            
            let message: ChatMessage
            
            switch i % 5 {
            case 0:
                // Text message
                let texts = [
                    "Hey everyone! 👋",
                    "What's your analysis on this?",
                    "I think we might see a reversal here",
                    "Thanks for sharing!",
                    "Interesting perspective"
                ]
                message = ChatMessage(
                    id: UUID(),
                    roomId: roomId,
                    senderId: senderId,
                    type: .text,
                    content: .text(texts.randomElement()!),
                    createdAt: createdAt,
                    updatedAt: nil,
                    editedAt: nil,
                    deletedAt: nil,
                    readBy: [senderId, currentUserId],
                    reactions: i % 3 == 0 ? [MessageReaction(emoji: "👍", users: Set(otherUserIds.prefix(2)))] : [],
                    replyTo: nil,
                    mentions: [],
                    isPinned: false,
                    metadata: nil
                )
                
            case 1:
                // Trading signal
                message = ChatMessage(
                    id: UUID(),
                    roomId: roomId,
                    senderId: senderId,
                    type: .tradingSignal,
                    content: .tradingSignal(TradingSignalContent(
                        signalId: UUID(),
                        symbol: ["EUR/USD", "GBP/USD", "XAU/USD"].randomElement()!,
                        action: Bool.random() ? .buy : .sell,
                        entry: Double.random(in: 1.0...2.0),
                        stopLoss: Double.random(in: 0.9...1.0),
                        takeProfit: Double.random(in: 2.0...2.5),
                        confidence: Double.random(in: 0.7...0.95),
                        analysis: "Technical analysis shows strong momentum"
                    )),
                    createdAt: createdAt,
                    updatedAt: nil,
                    editedAt: nil,
                    deletedAt: nil,
                    readBy: [senderId, currentUserId],
                    reactions: [
                        MessageReaction(emoji: "🚀", users: Set(otherUserIds)),
                        MessageReaction(emoji: "🎯", users: Set([currentUserId]))
                    ],
                    replyTo: nil,
                    mentions: [],
                    isPinned: i == 5,
                    metadata: nil
                )
                
            default:
                // Regular text
                message = ChatMessage(
                    id: UUID(),
                    roomId: roomId,
                    senderId: senderId,
                    type: .text,
                    content: .text("Message \(i): This is a test message for the chat"),
                    createdAt: createdAt,
                    updatedAt: nil,
                    editedAt: nil,
                    deletedAt: nil,
                    readBy: [senderId, currentUserId],
                    reactions: [],
                    replyTo: nil,
                    mentions: [],
                    isPinned: false,
                    metadata: nil
                )
            }
            
            mockMessages.append(message)
        }
        
        return mockMessages
    }
}