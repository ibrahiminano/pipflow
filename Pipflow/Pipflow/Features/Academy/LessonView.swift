//
//  LessonView.swift
//  Pipflow
//
//  View for displaying and interacting with lesson content
//

import SwiftUI
import AVKit
import WebKit

struct LessonView: View {
    let lesson: Lesson
    let courseId: UUID
    
    @StateObject private var academyService = AcademyService.shared
    @StateObject private var tutorService = AITutorService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var progress: Double = 0
    @State private var showingQuiz = false
    @State private var showingAITutor = false
    @State private var isCompleted = false
    @State private var exerciseResults: [UUID: Bool] = [:]
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressBar(progress: progress)
                        .frame(height: 4)
                    
                    // Content
                    VStack(spacing: 24) {
                        // Lesson header
                        LessonHeaderView(lesson: lesson)
                            .padding()
                        
                        // Main content based on type
                        Group {
                            switch lesson.content {
                            case .video(let videoContent):
                                VideoLessonView(content: videoContent, progress: $progress)
                                
                            case .article(let articleContent):
                                ArticleLessonView(content: articleContent, progress: $progress)
                                
                            case .interactive(let interactiveContent):
                                InteractiveLessonView(content: interactiveContent, progress: $progress)
                                
                            case .liveCoding(let codingContent):
                                LiveCodingView(content: codingContent, progress: $progress)
                                
                            case .simulation(let simulationContent):
                                SimulationView(content: simulationContent, progress: $progress)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Practice exercises
                        if !lesson.practiceExercises.isEmpty {
                            PracticeExercisesSection(
                                exercises: lesson.practiceExercises,
                                results: $exerciseResults
                            )
                            .padding()
                        }
                        
                        // Resources
                        if !lesson.resources.isEmpty {
                            ResourcesSection(resources: lesson.resources)
                                .padding()
                        }
                        
                        // Completion button
                        if progress >= 0.9 && !isCompleted {
                            Button(action: completeLesson) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark as Complete")
                                }
                                .font(.bodyMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                            .padding()
                        }
                        
                        // Next lesson button
                        if isCompleted,
                           let nextLesson = academyService.getNextLesson(for: courseId) {
                            Button(action: { 
                                // Navigate to next lesson
                            }) {
                                HStack {
                                    Text("Next Lesson: \(nextLesson.title)")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.currentTheme.accentColor.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding()
                        }
                    }
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(themeManager.currentTheme.textColor)
                },
                trailing: HStack(spacing: 16) {
                    // AI Tutor button
                    Button(action: { showingAITutor = true }) {
                        Image(systemName: "brain")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                    
                    // More options
                    Menu {
                        Button(action: {}) {
                            Label("Take Notes", systemImage: "note.text")
                        }
                        Button(action: {}) {
                            Label("Download Resources", systemImage: "arrow.down.circle")
                        }
                        Button(action: {}) {
                            Label("Report Issue", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                }
            )
        }
        .sheet(isPresented: $showingAITutor) {
            AITutorChatView()
                .environmentObject(themeManager)
        }
        .onAppear {
            checkCompletionStatus()
        }
    }
    
    private func checkCompletionStatus() {
        if let progress = academyService.userProgress.first(where: { $0.courseId == courseId }) {
            isCompleted = progress.completedLessons.contains(lesson.id)
        }
    }
    
    private func completeLesson() {
        academyService.completeLesson(lesson.id, in: courseId)
        isCompleted = true
        
        // Show completion animation
        withAnimation {
            // Add celebration effect
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let progress: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(themeManager.currentTheme.secondaryBackgroundColor)
                
                Rectangle()
                    .fill(themeManager.currentTheme.accentColor)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut, value: progress)
            }
        }
    }
}

// MARK: - Lesson Header
struct LessonHeaderView: View {
    let lesson: Lesson
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(lesson.type.rawValue.capitalized, systemImage: lesson.type.icon)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                
                Spacer()
                
                Label("\(lesson.estimatedDuration) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            Text(lesson.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(lesson.description)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
    }
}

// MARK: - Video Lesson View
struct VideoLessonView: View {
    let content: VideoContent
    @Binding var progress: Double
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Video player placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .aspectRatio(16/9, contentMode: .fit)
                .overlay(
                    VStack {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
            
            // Video chapters
            if !content.chapters.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Chapters")
                        .font(.headline)
                    
                    ForEach(content.chapters, id: \.title) { chapter in
                        HStack {
                            Text(formatTime(chapter.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 50, alignment: .leading)
                            
                            Text(chapter.title)
                                .font(.body)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .onAppear {
            // In real app, initialize video player
            // For demo, simulate progress
            simulateProgress()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func simulateProgress() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Article Lesson View
struct ArticleLessonView: View {
    let content: ArticleContent
    @Binding var progress: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Reading time
            HStack {
                Image(systemName: "book.fill")
                Text("\(content.readingTime) min read")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            // Article content (simplified markdown rendering)
            Text(content.markdownContent)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            // Images
            ForEach(content.images, id: \.self) { image in
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.currentTheme.secondaryBackgroundColor)
                    .aspectRatio(4/3, contentMode: .fit)
                    .overlay(
                        Text("Image: \(image)")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    )
            }
        }
        .onAppear {
            // Track reading progress
            progress = 1.0
        }
    }
}

// MARK: - Interactive Lesson View
struct InteractiveLessonView: View {
    let content: InteractiveContent
    @Binding var progress: Double
    @State private var completedInteractions: Set<String> = []
    
    var body: some View {
        VStack(spacing: 16) {
            // Web view for interactive content
            HTMLWebView(htmlString: content.htmlContent)
                .frame(height: 400)
                .cornerRadius(12)
            
            // Required interactions checklist
            VStack(alignment: .leading, spacing: 12) {
                Text("Complete all interactions:")
                    .font(.headline)
                
                ForEach(content.requiredInteractions, id: \.self) { interaction in
                    HStack {
                        Image(systemName: completedInteractions.contains(interaction) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(completedInteractions.contains(interaction) ? .green : .gray)
                        
                        Text(interaction.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.body)
                    }
                }
            }
            
            // Simulate interaction completion
            Button(action: simulateInteraction) {
                Text("Complete Next Interaction")
                    .font(.bodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
    }
    
    private func simulateInteraction() {
        let remainingInteractions = content.requiredInteractions.filter { !completedInteractions.contains($0) }
        if let next = remainingInteractions.first {
            completedInteractions.insert(next)
            progress = Double(completedInteractions.count) / Double(content.requiredInteractions.count)
        }
    }
}

// MARK: - Live Coding View
struct LiveCodingView: View {
    let content: LiveCodingContent
    @Binding var progress: Double
    @State private var userCode: String = ""
    @State private var output: String = ""
    @State private var showingSolution = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Code editor
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(content.language.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.currentTheme.accentColor.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Button(action: { showingSolution.toggle() }) {
                        Text(showingSolution ? "Hide Solution" : "Show Solution")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
                
                TextEditor(text: showingSolution ? .constant(content.solution) : $userCode)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                    .frame(height: 200)
            }
            
            // Test cases
            VStack(alignment: .leading, spacing: 8) {
                Text("Test Cases")
                    .font(.headline)
                
                ForEach(content.testCases.filter { !$0.isHidden }, id: \.input) { testCase in
                    HStack {
                        Text("Input: \(testCase.input)")
                            .font(.caption)
                        Spacer()
                        Text("Expected: \(testCase.expectedOutput)")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(6)
                }
            }
            
            // Hints
            if !content.hints.isEmpty {
                DisclosureGroup("Hints") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(content.hints.enumerated()), id: \.offset) { index, hint in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(hint)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            
            // Run button
            Button(action: runCode) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Run Code")
                }
                .font(.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(8)
            }
            
            // Output
            if !output.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output")
                        .font(.headline)
                    
                    Text(output)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                }
            }
        }
        .onAppear {
            userCode = content.initialCode
        }
    }
    
    private func runCode() {
        // Simulate code execution
        output = "✅ All test cases passed!"
        progress = 1.0
    }
}

// MARK: - Simulation View
struct SimulationView: View {
    let content: SimulationContent
    @Binding var progress: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Trading Simulation")
                .font(.headline)
            
            // Simulation type badge
            Text(content.simulationType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(themeManager.currentTheme.accentColor.opacity(0.2))
                .cornerRadius(15)
            
            // Objectives
            VStack(alignment: .leading, spacing: 12) {
                Text("Objectives")
                    .font(.headline)
                
                ForEach(content.objectives, id: \.self) { objective in
                    HStack(alignment: .top) {
                        Image(systemName: "target")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        Text(objective)
                            .font(.body)
                    }
                }
            }
            
            // Simulation placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.secondaryBackgroundColor)
                .frame(height: 300)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 50))
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        Text("Simulation Interface")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                )
            
            // Start simulation button
            Button(action: { progress = 1.0 }) {
                Text("Complete Simulation")
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.accentColor)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Practice Exercises Section
struct PracticeExercisesSection: View {
    let exercises: [Exercise]
    @Binding var results: [UUID: Bool]
    @State private var selectedAnswers: [UUID: String] = [:]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Practice Exercises")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            ForEach(exercises) { exercise in
                ExerciseCard(
                    exercise: exercise,
                    selectedAnswer: selectedAnswers[exercise.id],
                    isCorrect: results[exercise.id],
                    onSelectAnswer: { answer in
                        selectedAnswers[exercise.id] = answer
                    },
                    onSubmit: {
                        let isCorrect = selectedAnswers[exercise.id] == exercise.correctAnswer
                        results[exercise.id] = isCorrect
                    }
                )
            }
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    let selectedAnswer: String?
    let isCorrect: Bool?
    let onSelectAnswer: (String) -> Void
    let onSubmit: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.question)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            if let options = exercise.options {
                ForEach(options, id: \.self) { option in
                    Button(action: { onSelectAnswer(option) }) {
                        HStack {
                            Image(systemName: selectedAnswer == option ? "circle.fill" : "circle")
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            
                            Text(option)
                                .font(.body)
                                .foregroundColor(themeManager.currentTheme.textColor)
                            
                            Spacer()
                            
                            if let isCorrect = isCorrect {
                                if selectedAnswer == option {
                                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isCorrect ? .green : .red)
                                }
                            }
                        }
                        .padding()
                        .background(
                            selectedAnswer == option 
                                ? themeManager.currentTheme.accentColor.opacity(0.1)
                                : themeManager.currentTheme.secondaryBackgroundColor
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if selectedAnswer != nil && isCorrect == nil {
                Button(action: onSubmit) {
                    Text("Check Answer")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(themeManager.currentTheme.accentColor)
                        .cornerRadius(6)
                }
            }
            
            if let isCorrect = isCorrect {
                Text(isCorrect ? "Correct! \(exercise.explanation)" : "Incorrect. \(exercise.explanation)")
                    .font(.caption)
                    .foregroundColor(isCorrect ? .green : themeManager.currentTheme.secondaryTextColor)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Resources Section
struct ResourcesSection: View {
    let resources: [Resource]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Resources")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            ForEach(resources) { resource in
                HStack {
                    Image(systemName: iconForResourceType(resource.type))
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resource.title)
                            .font(.bodyMedium)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        if let description = resource.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .padding()
                .background(themeManager.currentTheme.secondaryBackgroundColor)
                .cornerRadius(8)
            }
        }
    }
    
    private func iconForResourceType(_ type: ResourceType) -> String {
        switch type {
        case .pdf: return "doc.fill"
        case .video: return "play.rectangle.fill"
        case .github: return "link"
        case .external: return "globe"
        }
    }
}

// MARK: - HTML Web View
struct HTMLWebView: UIViewRepresentable {
    let htmlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: HTMLWebView
        
        init(_ parent: HTMLWebView) {
            self.parent = parent
        }
    }
}