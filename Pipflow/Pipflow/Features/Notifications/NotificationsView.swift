//
//  NotificationsView.swift
//  Pipflow
//
//  Main notifications list and management view
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedFilter: NotificationFilter = .all
    @State private var showingPreferences = false
    @State private var showingClearConfirmation = false
    
    private var filteredNotifications: [PipflowNotification] {
        switch selectedFilter {
        case .all:
            return notificationService.notifications
        case .unread:
            return notificationService.notifications.filter { !$0.isRead }
        case .type(let type):
            return notificationService.notifications.filter { $0.type == type }
        case .priority(let priority):
            return notificationService.notifications.filter { $0.priority == priority }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if filteredNotifications.isEmpty {
                    EmptyNotificationsView()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Filter Pills
                            NotificationFilterView(selectedFilter: $selectedFilter)
                                .padding(.horizontal)
                            
                            // Notifications List
                            LazyVStack(spacing: 8) {
                                ForEach(filteredNotifications) { notification in
                                    NotificationRow(notification: notification)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if notificationService.unreadCount > 0 {
                        Button(action: markAllAsRead) {
                            Label("Mark All Read", systemImage: "checkmark.circle")
                                .font(.body)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingPreferences = true }) {
                            Label("Preferences", systemImage: "gear")
                        }
                        
                        if !notificationService.notifications.isEmpty {
                            Button(role: .destructive, action: { showingClearConfirmation = true }) {
                                Label("Clear All", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                    }
                }
            }
            .sheet(isPresented: $showingPreferences) {
                NavigationView {
                    NotificationPreferencesView()
                }
            }
            .alert("Clear All Notifications", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    withAnimation {
                        notificationService.clearAll()
                    }
                }
            } message: {
                Text("This will permanently delete all notifications. This action cannot be undone.")
            }
        }
    }
    
    private func markAllAsRead() {
        withAnimation {
            notificationService.markAllAsRead()
        }
    }
}

// MARK: - Notification Filter
enum NotificationFilter: Equatable {
    case all
    case unread
    case type(NotificationType)
    case priority(NotificationPriority)
    
    var title: String {
        switch self {
        case .all: return "All"
        case .unread: return "Unread"
        case .type(let type): return type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        case .priority(let priority): return priority.rawValue.capitalized
        }
    }
}

// MARK: - Filter View
struct NotificationFilterView: View {
    @Binding var selectedFilter: NotificationFilter
    @EnvironmentObject var themeManager: ThemeManager
    
    let filters: [NotificationFilter] = [
        .all,
        .unread,
        .type(.priceAlert),
        .type(.tradeExecution),
        .type(.signalGenerated),
        .type(.marketNews)
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters.indices, id: \.self) { index in
                    NotificationFilterPill(
                        title: filters[index].title,
                        isSelected: selectedFilter == filters[index],
                        action: { selectedFilter = filters[index] }
                    )
                }
            }
        }
    }
}

struct NotificationFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryBackgroundColor
                )
                .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: PipflowNotification
    @StateObject private var notificationService = NotificationService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var offset: CGSize = .zero
    @State private var isDeleting = false
    
    var body: some View {
        ZStack {
            // Delete Background
            HStack {
                Spacer()
                
                Button(action: deleteNotification) {
                    VStack {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                }
            }
            .cornerRadius(12)
            
            // Notification Content
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(notification.type.defaultPriority.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: notification.type.icon)
                        .font(.body)
                        .foregroundColor(notification.type.defaultPriority.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(notification.isRead ? themeManager.currentTheme.secondaryTextColor : themeManager.currentTheme.textColor)
                        
                        Spacer()
                        
                        if !notification.isRead {
                            Circle()
                                .fill(themeManager.currentTheme.accentColor)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(2)
                    
                    HStack {
                        Text(notification.timestamp.relative())
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Spacer()
                        
                        if notification.priority == .high || notification.priority == .urgent {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption2)
                                Text(notification.priority.rawValue.capitalized)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(notification.priority.color)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
            .offset(x: offset.width)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = CGSize(width: max(value.translation.width, -80), height: 0)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width < -40 {
                                offset = CGSize(width: -80, height: 0)
                            } else {
                                offset = .zero
                            }
                        }
                    }
            )
            .onTapGesture {
                if !notification.isRead {
                    notificationService.markAsRead(notification.id)
                }
                
                // Handle notification tap action
                handleNotificationTap()
            }
        }
        .opacity(isDeleting ? 0 : 1)
    }
    
    private func deleteNotification() {
        withAnimation(.easeOut(duration: 0.3)) {
            isDeleting = true
            offset = CGSize(width: -UIScreen.main.bounds.width, height: 0)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            notificationService.deleteNotification(notification.id)
        }
    }
    
    private func handleNotificationTap() {
        // In a real app, navigate to relevant screen based on notification type
        switch notification.type {
        case .priceAlert:
            // Navigate to charts
            break
        case .tradeExecution, .tradeClosed:
            // Navigate to trades
            break
        case .signalGenerated:
            // Navigate to signals
            break
        case .marketNews:
            // Navigate to news
            break
        case .socialActivity:
            // Navigate to social
            break
        default:
            break
        }
    }
}

// MARK: - Empty State
struct EmptyNotificationsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            Text("No Notifications")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("You're all caught up! New notifications will appear here.")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    NotificationsView()
        .environmentObject(ThemeManager())
}