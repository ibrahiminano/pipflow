//
//  ChatView.swift
//  Pipflow
//
//  Main chat interface with room list and messaging
//

import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedRoom: ChatRoom?
    @State private var showNewChat = false
    @State private var searchText = ""
    
    var filteredRooms: [ChatRoom] {
        if searchText.isEmpty {
            return chatService.chatRooms
        }
        return chatService.chatRooms.filter { room in
            room.displayName.localizedCaseInsensitiveContains(searchText) ||
            (room.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            sidebarContent
        } detail: {
            detailContent
        }
        .sheet(isPresented: $showNewChat) {
            NewChatView()
                .environmentObject(themeManager)
        }
        .onAppear {
            selectFirstRoomIfNeeded()
        }
    }
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            headerSection
            searchSection
            roomListSection
        }
        .frame(minWidth: 320)
        .background(themeManager.currentTheme.backgroundColor)
    }
    
    private var headerSection: some View {
        HStack {
            Text("Messages")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Spacer()
            
            Button(action: { showNewChat = true }) {
                Image(systemName: "square.and.pencil")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
        }
        .padding()
    }
    
    private var searchSection: some View {
        SearchBar(text: $searchText, placeholder: "Search messages...")
            .padding(.horizontal)
            .padding(.bottom, 8)
    }
    
    private var roomListSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredRooms) { room in
                    ChatRoomRow(
                        room: room,
                        isSelected: selectedRoom?.id == room.id,
                        unreadCount: chatService.unreadCounts[room.id] ?? 0,
                        onlineUsers: chatService.onlineUsers
                    )
                    .onTapGesture {
                        selectedRoom = room
                        chatService.activeRoom = room
                        chatService.markAsRead(roomId: room.id)
                    }
                    
                    if room != filteredRooms.last {
                        Divider()
                            .background(themeManager.currentTheme.separatorColor)
                            .padding(.leading, 76)
                    }
                }
            }
        }
    }
    
    private var detailContent: some View {
        Group {
            if let room = selectedRoom {
                ChatRoomView(room: room)
                    .environmentObject(themeManager)
                    .id(room.id)
            } else {
                EmptyChatView()
                    .environmentObject(themeManager)
            }
        }
    }
    
    private func selectFirstRoomIfNeeded() {
        if selectedRoom == nil && !chatService.chatRooms.isEmpty {
            selectedRoom = chatService.chatRooms.first
            chatService.activeRoom = selectedRoom
        }
    }
}

// MARK: - Chat Room Row
struct ChatRoomRow: View {
    let room: ChatRoom
    let isSelected: Bool
    let unreadCount: Int
    let onlineUsers: Set<UUID>
    @EnvironmentObject var themeManager: ThemeManager
    
    private var isOnline: Bool {
        room.participants.contains { onlineUsers.contains($0) }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            avatarSection
            contentSection
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            isSelected ? themeManager.currentTheme.accentColor.opacity(0.1) : Color.clear
        )
        .contentShape(Rectangle())
    }
    
    private var avatarSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Group {
                        if room.type == .aiAssistant {
                            Image(systemName: "brain")
                                .font(.title2)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        } else if let avatarURL = room.avatarURL {
                            // AsyncImage for avatar
                            Color.gray.opacity(0.3)
                        } else {
                            Image(systemName: room.type.icon)
                                .font(.title3)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        }
                    }
                )
            
            // Online indicator
            if isOnline && room.type == .direct {
                Circle()
                    .fill(Color.green)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(themeManager.currentTheme.backgroundColor, lineWidth: 2)
                    )
            }
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            topRowContent
            bottomRowContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var topRowContent: some View {
        HStack {
            // Name
            HStack(spacing: 6) {
                Text(room.displayName)
                    .font(.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .lineLimit(1)
                
                if room.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                if room.isMuted {
                    Image(systemName: "bell.slash.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Time
            if let lastMessage = room.lastMessage {
                Text(lastMessage.createdAt.chatTimeFormat())
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
        }
    }
    
    private var bottomRowContent: some View {
        HStack {
            // Last message preview
            if let lastMessage = room.lastMessage {
                HStack(spacing: 4) {
                    if lastMessage.senderId == AuthService.shared.currentUser?.id {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundColor(
                                lastMessage.readBy.count > 1
                                    ? themeManager.currentTheme.accentColor
                                    : themeManager.currentTheme.secondaryTextColor
                            )
                    }
                    
                    Text(formatMessagePreview(lastMessage))
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(1)
                }
            } else {
                Text(room.description ?? "Start a conversation")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Unread badge
            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(themeManager.currentTheme.accentColor)
                    .clipShape(Capsule())
            }
        }
    }
    
    private func formatMessagePreview(_ message: ChatMessage) -> String {
        switch message.content {
        case .text(let text):
            return text
        case .tradingSignal(let signal):
            return "📊 \(signal.action.rawValue.uppercased()) \(signal.symbol)"
        case .media(let media):
            if media.mimeType.starts(with: "image/") {
                return "📷 Photo"
            } else if media.mimeType.starts(with: "video/") {
                return "🎥 Video"
            } else {
                return "📎 File"
            }
        case .trade(let trade):
            return "💹 \(trade.symbol) Trade"
        case .poll(let poll):
            return "📊 Poll: \(poll.question)"
        case .system(let system):
            return system.text
        case .achievement(let achievement):
            return "🏆 \(achievement.title)"
        }
    }
}

// MARK: - Empty Chat View
struct EmptyChatView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 80))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.3))
            
            Text("Select a conversation")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text("Choose a chat from the sidebar to start messaging")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.backgroundColor)
    }
}

// MARK: - Date Extension
extension Date {
    func chatTimeFormat() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else if calendar.isDate(self, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter.string(from: self)
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(ThemeManager())
}