//
//  AITutorChatView.swift
//  Pipflow
//
//  Interactive AI tutor chat interface
//

import SwiftUI

struct AITutorChatView: View {
    let lesson: Lesson? = nil
    
    @StateObject private var tutorService = AITutorService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy? = nil
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(tutorService.currentSession?.messages ?? []) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if tutorService.isProcessing {
                                TutorTypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                        scrollToBottom()
                    }
                    .onChange(of: tutorService.currentSession?.messages.count ?? 0) { _ in
                        scrollToBottom()
                    }
                }
                
                // Suggested actions
                if !tutorService.suggestedActions.isEmpty {
                    SuggestedActionsView(actions: tutorService.suggestedActions) { action in
                        handleAction(action)
                    }
                }
                
                Divider()
                
                // Input area
                ChatInputView(
                    text: $messageText,
                    isProcessing: tutorService.isProcessing,
                    onSend: sendMessage
                )
                .focused($isInputFocused)
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("AI Tutor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: startNewSession) {
                            Label("New Session", systemImage: "plus.bubble")
                        }
                        Button(action: {}) {
                            Label("Session History", systemImage: "clock")
                        }
                        Button(action: {}) {
                            Label("Learning Path", systemImage: "map")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                }
            }
        }
        .onAppear {
            if tutorService.currentSession == nil {
                tutorService.startSession(for: nil, lesson: lesson)
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await tutorService.sendMessage(messageText)
            messageText = ""
            scrollToBottom()
        }
    }
    
    private func handleAction(_ action: TutorAction) {
        switch action.type {
        case .askFollowUp:
            if let prompt = action.data["prompt"] {
                messageText = prompt
            }
        case .viewLesson:
            // Navigate to lesson
            dismiss()
        case .startQuiz:
            // Start quiz
            break
        case .practiceExercise:
            // Show practice problems
            break
        case .reviewConcept:
            // Review concept
            break
        }
    }
    
    private func startNewSession() {
        tutorService.endSession()
        tutorService.startSession(for: nil, lesson: lesson)
    }
    
    private func scrollToBottom() {
        guard let lastMessage = tutorService.currentSession?.messages.last else { return }
        withAnimation {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: TutorMessage
    @EnvironmentObject var themeManager: ThemeManager
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isUser ? .white : themeManager.currentTheme.textColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        isUser 
                            ? themeManager.currentTheme.accentColor
                            : themeManager.currentTheme.secondaryBackgroundColor
                    )
                    .cornerRadius(20, corners: isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                
                // Attachments
                if let attachments = message.attachments {
                    ForEach(attachments, id: \.url) { attachment in
                        AttachmentView(attachment: attachment)
                    }
                }
                
                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer() }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Attachment View
struct AttachmentView: View {
    let attachment: MessageAttachment
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: iconForType(attachment.type))
                .foregroundColor(themeManager.currentTheme.accentColor)
            
            Text(attachment.caption ?? attachment.url)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textColor)
                .lineLimit(1)
        }
        .padding(8)
        .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(8)
    }
    
    private func iconForType(_ type: AttachmentType) -> String {
        switch type {
        case .image: return "photo"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .chart: return "chart.line.uptrend.xyaxis"
        case .link: return "link"
        }
    }
}

// MARK: - Typing Indicator
struct TutorTypingIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animatingDots = [false, false, false]
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(themeManager.currentTheme.secondaryTextColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animatingDots[index] ? 1.0 : 0.6)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animatingDots[index]
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
            
            Spacer()
        }
        .onAppear {
            for index in 0..<3 {
                animatingDots[index] = true
            }
        }
    }
}

// MARK: - Suggested Actions View
struct SuggestedActionsView: View {
    let actions: [TutorAction]
    let onSelect: (TutorAction) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(actions) { action in
                    Button(action: { onSelect(action) }) {
                        HStack(spacing: 8) {
                            Image(systemName: iconForAction(action.type))
                            Text(action.title)
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(themeManager.currentTheme.accentColor.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private func iconForAction(_ type: ActionType) -> String {
        switch type {
        case .viewLesson: return "book.fill"
        case .startQuiz: return "questionmark.circle.fill"
        case .practiceExercise: return "pencil.and.outline"
        case .reviewConcept: return "arrow.counterclockwise"
        case .askFollowUp: return "bubble.left.fill"
        }
    }
}

// MARK: - Chat Input View
struct ChatInputView: View {
    @Binding var text: String
    let isProcessing: Bool
    let onSend: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Attachment button
            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
            .disabled(isProcessing)
            
            // Text field
            HStack {
                TextField("Ask me anything...", text: $text)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .disabled(isProcessing)
                    .onSubmit {
                        onSend()
                    }
                
                if !text.isEmpty && !isProcessing {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(25)
            
            // Send button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(text.isEmpty || isProcessing ? Color.gray : themeManager.currentTheme.accentColor)
            }
            .disabled(text.isEmpty || isProcessing)
        }
        .padding()
    }
}

// Corner radius extension removed - using the one from View+Extensions.swift

#Preview {
    AITutorChatView()
        .environmentObject(ThemeManager())
}