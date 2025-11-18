//
//  NewChatView.swift
//  Pipflow
//
//  View for creating new chats and groups
//

import SwiftUI

struct NewChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var chatService = ChatService.shared
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var selectedUsers: Set<UUID> = []
    @State private var groupName = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selection
                Picker("", selection: $selectedTab) {
                    Text("Direct Message").tag(0)
                    Text("New Group").tag(1)
                    Text("Join Channel").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on tab
                switch selectedTab {
                case 0:
                    DirectMessageView(
                        searchText: $searchText,
                        onSelectUser: { userId in
                            Task {
                                isCreating = true
                                do {
                                    let _ = try await chatService.createDirectChat(with: userId)
                                    dismiss()
                                    // Navigate to chat room
                                } catch {
                                    // Handle error
                                }
                                isCreating = false
                            }
                        }
                    )
                case 1:
                    NewGroupView(
                        groupName: $groupName,
                        selectedUsers: $selectedUsers,
                        searchText: $searchText,
                        onCreate: createGroup
                    )
                case 2:
                    JoinChannelView(searchText: $searchText)
                default:
                    EmptyView()
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if selectedTab == 1 && !selectedUsers.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create") {
                            createGroup()
                        }
                        .disabled(groupName.isEmpty || isCreating)
                    }
                }
            }
            .overlay {
                if isCreating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView("Creating...")
                                .padding()
                                .background(themeManager.currentTheme.secondaryBackgroundColor)
                                .cornerRadius(12)
                        )
                }
            }
        }
    }
    
    private func createGroup() {
        guard !groupName.isEmpty, !selectedUsers.isEmpty else { return }
        
        Task {
            isCreating = true
            do {
                let _ = try await chatService.createGroupChat(
                    name: groupName,
                    participants: Array(selectedUsers)
                )
                dismiss()
                // Navigate to chat room
            } catch {
                // Handle error
            }
            isCreating = false
        }
    }
}

// MARK: - Direct Message View
struct DirectMessageView: View {
    @Binding var searchText: String
    let onSelectUser: (UUID) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    // Mock users for demo
    let users = [
        (id: UUID(), name: "John Trader", username: "@johntrader", isOnline: true),
        (id: UUID(), name: "Sarah Analyst", username: "@sarahfx", isOnline: true),
        (id: UUID(), name: "Mike Scalper", username: "@mikescalp", isOnline: false),
        (id: UUID(), name: "Emma Investor", username: "@emmainvest", isOnline: true),
        (id: UUID(), name: "David Swing", username: "@davidswing", isOnline: false)
    ]
    
    var filteredUsers: [(id: UUID, name: String, username: String, isOnline: Bool)] {
        if searchText.isEmpty {
            return users
        }
        return users.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $searchText, placeholder: "Search users...")
                .padding()
            
            // User list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredUsers, id: \.id) { user in
                        UserRow(
                            name: user.name,
                            username: user.username,
                            isOnline: user.isOnline,
                            onTap: { onSelectUser(user.id) }
                        )
                        
                        if user.id != filteredUsers.last?.id {
                            Divider()
                                .background(themeManager.currentTheme.separatorColor)
                                .padding(.leading, 72)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - New Group View
struct NewGroupView: View {
    @Binding var groupName: String
    @Binding var selectedUsers: Set<UUID>
    @Binding var searchText: String
    let onCreate: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    // Mock users for demo
    let users = [
        (id: UUID(), name: "John Trader", username: "@johntrader"),
        (id: UUID(), name: "Sarah Analyst", username: "@sarahfx"),
        (id: UUID(), name: "Mike Scalper", username: "@mikescalp"),
        (id: UUID(), name: "Emma Investor", username: "@emmainvest"),
        (id: UUID(), name: "David Swing", username: "@davidswing")
    ]
    
    var filteredUsers: [(id: UUID, name: String, username: String)] {
        if searchText.isEmpty {
            return users
        }
        return users.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Group info
            VStack(spacing: 16) {
                // Group avatar
                Circle()
                    .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "camera")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    )
                    .onTapGesture {
                        // Handle photo selection
                    }
                
                // Group name
                TextField("Group Name", text: $groupName)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            
            Divider()
                .background(themeManager.currentTheme.separatorColor)
            
            // Search bar
            SearchBar(text: $searchText, placeholder: "Add participants...")
                .padding()
            
            // Selected users
            if !selectedUsers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedUsers), id: \.self) { userId in
                            if let user = users.first(where: { $0.id == userId }) {
                                SelectedUserChip(
                                    name: user.name,
                                    onRemove: { selectedUsers.remove(userId) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            
            // User list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredUsers, id: \.id) { user in
                        SelectableUserRow(
                            name: user.name,
                            username: user.username,
                            isSelected: selectedUsers.contains(user.id),
                            onTap: {
                                if selectedUsers.contains(user.id) {
                                    selectedUsers.remove(user.id)
                                } else {
                                    selectedUsers.insert(user.id)
                                }
                            }
                        )
                        
                        if user.id != filteredUsers.last?.id {
                            Divider()
                                .background(themeManager.currentTheme.separatorColor)
                                .padding(.leading, 72)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Join Channel View
struct JoinChannelView: View {
    @Binding var searchText: String
    @EnvironmentObject var themeManager: ThemeManager
    
    // Mock channels
    let channels = [
        (id: UUID(), name: "📊 Trading Signals", members: 234, description: "Premium trading signals"),
        (id: UUID(), name: "💬 General Chat", members: 567, description: "Community discussion"),
        (id: UUID(), name: "📈 Market Analysis", members: 189, description: "Daily market analysis"),
        (id: UUID(), name: "🎓 Education", members: 412, description: "Trading education and tips"),
        (id: UUID(), name: "🤖 Algo Trading", members: 98, description: "Algorithmic trading strategies")
    ]
    
    var filteredChannels: [(id: UUID, name: String, members: Int, description: String)] {
        if searchText.isEmpty {
            return channels
        }
        return channels.filter { channel in
            channel.name.localizedCaseInsensitiveContains(searchText) ||
            channel.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $searchText, placeholder: "Search channels...")
                .padding()
            
            // Channel list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredChannels, id: \.id) { channel in
                        ChannelCard(
                            name: channel.name,
                            members: channel.members,
                            description: channel.description,
                            onJoin: {
                                // Handle channel join
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Supporting Views
struct UserRow: View {
    let name: String
    let username: String
    let isOnline: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(name.prefix(2))
                                .font(.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        )
                    
                    if isOnline {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(themeManager.currentTheme.backgroundColor, lineWidth: 2)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text(username)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectableUserRow: View {
    let name: String
    let username: String
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(name.prefix(2))
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text(username)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryTextColor)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectedUserChip: View {
    let name: String
    let onRemove: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(themeManager.currentTheme.accentColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(themeManager.currentTheme.accentColor.opacity(0.1))
        .cornerRadius(15)
    }
}

struct ChannelCard: View {
    let name: String
    let members: Int
    let description: String
    let onJoin: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Button("Join") {
                    onJoin()
                }
                .font(.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            HStack {
                Image(systemName: "person.2")
                    .font(.caption)
                Text("\(members) members")
                    .font(.caption)
            }
            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct ChatRoomInfoView: View {
    let room: ChatRoom
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Room info
                    VStack(spacing: 16) {
                        Circle()
                            .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: room.type.icon)
                                    .font(.largeTitle)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            )
                        
                        Text(room.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        if let description = room.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .multilineTextAlignment(.center)
                        }
                        
                        Text("\(room.participants.count) participants")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    .padding()
                    
                    // Actions
                    VStack(spacing: 12) {
                        InfoActionRow(
                            icon: room.isMuted ? "bell.slash" : "bell",
                            title: room.isMuted ? "Unmute" : "Mute",
                            action: {}
                        )
                        
                        InfoActionRow(
                            icon: "magnifyingglass",
                            title: "Search in Chat",
                            action: {}
                        )
                        
                        InfoActionRow(
                            icon: "photo",
                            title: "Media & Files",
                            action: {}
                        )
                        
                        if room.type != .direct {
                            InfoActionRow(
                                icon: "person.badge.plus",
                                title: "Add Participants",
                                action: {}
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .background(themeManager.currentTheme.separatorColor)
                    
                    // Danger zone
                    VStack(spacing: 12) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "arrow.left.square")
                                Text("Leave Chat")
                            }
                            .font(.bodyMedium)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Chat Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}