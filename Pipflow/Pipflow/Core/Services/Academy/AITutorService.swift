//
//  AITutorService.swift
//  Pipflow
//
//  AI-powered tutoring service for personalized learning
//

import Foundation
import Combine

@MainActor
class AITutorService: ObservableObject {
    static let shared = AITutorService()
    
    @Published var currentSession: AITutorSession?
    @Published var isProcessing = false
    @Published var suggestedActions: [TutorAction] = []
    @Published var learningPath: [Course] = []
    
    private let aiService = AISignalService.shared
    private let academyService = AcademyService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Session Management
    
    func startSession(for course: Course? = nil, lesson: Lesson? = nil) {
        let context = TutorContext(
            courseId: course?.id,
            lessonId: lesson?.id,
            topic: course?.title ?? "General Trading",
            difficultyLevel: course?.difficulty ?? .beginner,
            learningObjectives: []
        )
        
        currentSession = AITutorSession(
            id: UUID(),
            userId: UUID(), // Current user
            startedAt: Date(),
            context: context,
            messages: [
                TutorMessage(
                    id: UUID(),
                    role: .tutor,
                    content: generateWelcomeMessage(context: context),
                    timestamp: Date(),
                    attachments: nil,
                    suggestedActions: generateInitialActions(context: context)
                )
            ]
        )
    }
    
    func endSession() {
        // Save session history
        if let session = currentSession {
            saveSessionHistory(session)
        }
        currentSession = nil
        suggestedActions = []
    }
    
    // MARK: - Message Handling
    
    func sendMessage(_ content: String, attachments: [MessageAttachment]? = nil) async {
        guard let session = currentSession else { return }
        
        // Add user message
        let userMessage = TutorMessage(
            id: UUID(),
            role: .user,
            content: content,
            timestamp: Date(),
            attachments: attachments,
            suggestedActions: nil
        )
        
        currentSession?.messages.append(userMessage)
        
        // Process with AI
        isProcessing = true
        
        do {
            let tutorResponse = try await generateTutorResponse(
                userMessage: content,
                context: session.context,
                history: session.messages
            )
            
            currentSession?.messages.append(tutorResponse)
            
            // Update suggested actions
            if let actions = tutorResponse.suggestedActions {
                suggestedActions = actions
            }
            
        } catch {
            // Handle error
            let errorMessage = TutorMessage(
                id: UUID(),
                role: .tutor,
                content: "I apologize, but I'm having trouble processing your request. Please try again.",
                timestamp: Date(),
                attachments: nil,
                suggestedActions: nil
            )
            currentSession?.messages.append(errorMessage)
        }
        
        isProcessing = false
    }
    
    private func generateTutorResponse(
        userMessage: String,
        context: TutorContext,
        history: [TutorMessage]
    ) async throws -> TutorMessage {
        
        // Build prompt for AI
        let prompt = buildTutorPrompt(
            userMessage: userMessage,
            context: context,
            history: history
        )
        
        // Get AI response (mocked for now)
        let response = generateMockAIResponse(prompt: prompt)
        
        // Parse response and extract suggested actions
        let (content, actions) = parseAIResponse(response)
        
        return TutorMessage(
            id: UUID(),
            role: .tutor,
            content: content,
            timestamp: Date(),
            attachments: nil,
            suggestedActions: actions
        )
    }
    
    private func buildTutorPrompt(
        userMessage: String,
        context: TutorContext,
        history: [TutorMessage]
    ) -> String {
        var prompt = """
        You are an AI tutor for Pipflow, a trading education platform. 
        Your role is to help users learn trading concepts in a personalized, engaging way.
        
        Context:
        - Topic: \(context.topic)
        - Difficulty Level: \(context.difficultyLevel.rawValue)
        """
        
        if let courseId = context.courseId,
           let course = academyService.courses.first(where: { $0.id == courseId }) {
            prompt += "\n- Course: \(course.title)"
        }
        
        if let lessonId = context.lessonId,
           let course = academyService.courses.first(where: { $0.id == context.courseId! }),
           let lesson = course.modules.flatMap({ $0.lessons }).first(where: { $0.id == lessonId }) {
            prompt += "\n- Current Lesson: \(lesson.title)"
        }
        
        // Add conversation history (last 5 messages)
        let recentHistory = history.suffix(5)
        if !recentHistory.isEmpty {
            prompt += "\n\nConversation History:"
            for message in recentHistory {
                prompt += "\n\(message.role.rawValue.capitalized): \(message.content)"
            }
        }
        
        prompt += """
        
        User Question: \(userMessage)
        
        Please provide a helpful, educational response that:
        1. Answers the user's question clearly
        2. Uses appropriate examples for their skill level
        3. Suggests next steps or related topics to explore
        4. Encourages active learning and practice
        
        If relevant, suggest specific lessons, exercises, or resources from the course.
        """
        
        return prompt
    }
    
    private func parseAIResponse(_ response: String) -> (content: String, actions: [TutorAction]) {
        // For now, return the response as-is
        // In a real implementation, we'd parse structured responses
        var actions: [TutorAction] = []
        
        // Extract any lesson recommendations
        if response.contains("recommend") || response.contains("suggest") {
            actions.append(TutorAction(
                id: UUID(),
                type: .reviewConcept,
                title: "Review Related Concepts",
                data: [:]
            ))
        }
        
        // Add follow-up question option
        actions.append(TutorAction(
            id: UUID(),
            type: .askFollowUp,
            title: "Ask a follow-up question",
            data: [:]
        ))
        
        return (response, actions)
    }
    
    // MARK: - Learning Path Generation
    
    func generateLearningPath(for user: User? = nil) async {
        isProcessing = true
        
        // Analyze user progress
        let completedCourses = academyService.userProgress.filter { $0.completionPercentage > 80 }
        let skillLevel = determineSkillLevel(from: completedCourses)
        
        // Generate personalized path
        let prompt = """
        Based on a user with \(skillLevel) skill level who has completed \(completedCourses.count) courses,
        recommend a learning path of 3-5 courses from the following options:
        
        \(academyService.courses.map { "- \($0.title) (\($0.difficulty.rawValue))" }.joined(separator: "\n"))
        
        Consider progression from current skill level and diverse topic coverage.
        """
        
        // Use mock response for now
        let response = generateMockAIResponse(prompt: prompt)
        learningPath = parseRecommendedCourses(from: response)
        
        // If no courses matched, use default recommendations
        if learningPath.isEmpty {
            learningPath = Array(academyService.getRecommendedCourses().prefix(3))
        }
        
        isProcessing = false
    }
    
    private func determineSkillLevel(from progress: [CourseProgress]) -> String {
        let avgCompletion = progress.isEmpty ? 0 : progress.reduce(0) { $0 + $1.completionPercentage } / progress.count
        
        switch avgCompletion {
        case 0..<30: return "beginner"
        case 30..<60: return "intermediate"
        case 60..<80: return "advanced"
        default: return "expert"
        }
    }
    
    private func parseRecommendedCourses(from response: String) -> [Course] {
        // Simple parsing - in production, use structured response
        return academyService.courses.filter { course in
            response.lowercased().contains(course.title.lowercased())
        }
    }
    
    // MARK: - Smart Q&A
    
    func answerQuestion(_ question: String, relatedTo lesson: Lesson? = nil) async -> String {
        let context = lesson != nil ? "Related to lesson: \(lesson!.title)" : "General trading question"
        
        let prompt = """
        Answer this trading-related question in a clear, educational manner:
        
        Question: \(question)
        Context: \(context)
        
        Provide:
        1. A direct answer
        2. An example if applicable
        3. Common misconceptions to avoid
        4. Further reading suggestions
        """
        
        // Mock implementation for now
        return generateMockAIResponse(prompt: prompt)
    }
    
    // MARK: - Practice Problem Generation
    
    func generatePracticeProblems(for topic: String, difficulty: DifficultyLevel, count: Int = 5) async -> [Exercise] {
        let prompt = """
        Generate \(count) practice problems for trading topic: \(topic)
        Difficulty: \(difficulty.rawValue)
        
        For each problem provide:
        - Question
        - 4 multiple choice options
        - Correct answer
        - Explanation
        
        Format as JSON array.
        """
        
        // Use mock response for now
        let response = generateMockAIResponse(prompt: prompt)
        return parsePracticeProblems(from: response)
    }
    
    private func parsePracticeProblems(from response: String) -> [Exercise] {
        // Parse JSON response into Exercise objects
        // For now, return empty array
        return []
    }
    
    // MARK: - Helper Methods
    
    private func generateWelcomeMessage(context: TutorContext) -> String {
        let greetings = [
            "Hello! I'm your AI trading tutor. I'm here to help you master \(context.topic).",
            "Welcome back! Ready to continue your journey in \(context.topic)?",
            "Hi there! Let's dive into \(context.topic) together.",
            "Great to see you! I'm excited to help you learn about \(context.topic)."
        ]
        
        return greetings.randomElement() ?? greetings[0]
    }
    
    private func generateInitialActions(context: TutorContext) -> [TutorAction] {
        var actions: [TutorAction] = []
        
        // Add lesson-specific actions
        if let lessonId = context.lessonId {
            actions.append(TutorAction(
                id: UUID(),
                type: .viewLesson,
                title: "Start the lesson",
                data: ["lessonId": lessonId.uuidString]
            ))
        }
        
        // Add general actions
        actions.append(contentsOf: [
            TutorAction(
                id: UUID(),
                type: .askFollowUp,
                title: "Ask about prerequisites",
                data: ["prompt": "What should I know before starting?"]
            ),
            TutorAction(
                id: UUID(),
                type: .practiceExercise,
                title: "Try a practice problem",
                data: ["difficulty": context.difficultyLevel.rawValue]
            ),
            TutorAction(
                id: UUID(),
                type: .reviewConcept,
                title: "Review key concepts",
                data: ["topic": context.topic]
            )
        ])
        
        return actions
    }
    
    private func saveSessionHistory(_ session: AITutorSession) {
        // Save to local storage or backend
        // Implementation depends on persistence strategy
    }
    
    // MARK: - Mock Response Generator
    
    private func generateMockAIResponse(prompt: String) -> String {
        // Generate contextual mock responses based on the prompt
        if prompt.lowercased().contains("what is") || prompt.lowercased().contains("explain") {
            return """
            That's a great question! Let me explain this concept for you.
            
            In trading, this concept is fundamental because it helps you understand market dynamics and make informed decisions. The key points to remember are:
            
            1. Always consider the broader market context
            2. Look for confirmation signals before taking action
            3. Manage your risk appropriately
            
            Would you like me to provide a specific example or go deeper into any particular aspect?
            """
        } else if prompt.lowercased().contains("how do i") || prompt.lowercased().contains("how to") {
            return """
            Here's a step-by-step guide to help you:
            
            1. First, analyze the current market conditions
            2. Identify key support and resistance levels
            3. Set up your entry and exit points
            4. Define your risk management parameters
            5. Execute the trade when conditions align
            
            Remember to always practice with small positions first and gradually increase as you gain confidence. Would you like me to walk through a practical example?
            """
        } else if prompt.lowercased().contains("practice") || prompt.lowercased().contains("exercise") {
            return """
            Let's work through a practice scenario together!
            
            Scenario: You're analyzing EUR/USD and notice a bullish pattern forming.
            
            Question: What factors would you consider before entering a long position?
            
            Think about:
            - Current trend direction
            - Key technical levels
            - Risk/reward ratio
            - Position sizing
            
            Take your time to analyze this, and I'll provide feedback on your approach.
            """
        } else {
            return """
            I understand you're interested in learning more about this topic. 
            
            This is an important concept in trading that requires both theoretical understanding and practical application. The best approach is to:
            
            1. Master the fundamentals first
            2. Practice with demo accounts
            3. Gradually apply the concepts in real trading
            
            Is there a specific aspect you'd like to focus on, or would you like me to provide more examples?
            """
        }
    }
    
    // MARK: - Analytics
    
    func trackLearningProgress() -> LearningAnalytics {
        let totalTime = academyService.userProgress.reduce(0) { $0 + $1.totalTimeSpent }
        let completedLessons = academyService.userProgress.reduce(0) { $0 + $1.completedLessons.count }
        let avgQuizScore = calculateAverageQuizScore()
        
        return LearningAnalytics(
            totalLearningTime: totalTime,
            lessonsCompleted: completedLessons,
            averageQuizScore: avgQuizScore,
            strongTopics: identifyStrongTopics(),
            weakTopics: identifyWeakTopics(),
            learningStreak: calculateLearningStreak()
        )
    }
    
    private func calculateAverageQuizScore() -> Double {
        let allScores = academyService.userProgress.flatMap { $0.quizScores.values }
        guard !allScores.isEmpty else { return 0 }
        
        let totalScore = allScores.reduce(0) { $0 + Double($1.score) }
        let totalMax = allScores.reduce(0) { $0 + Double($1.maxScore) }
        
        return (totalScore / totalMax) * 100
    }
    
    private func identifyStrongTopics() -> [String] {
        // Analyze quiz scores and completion rates by topic
        return ["Technical Analysis", "Risk Management"]
    }
    
    private func identifyWeakTopics() -> [String] {
        // Identify topics with low scores or incomplete lessons
        return ["Options Trading", "Fundamental Analysis"]
    }
    
    private func calculateLearningStreak() -> Int {
        // Calculate consecutive days of learning activity
        return 5
    }
}

// MARK: - Supporting Types

struct LearningAnalytics {
    let totalLearningTime: Int // minutes
    let lessonsCompleted: Int
    let averageQuizScore: Double
    let strongTopics: [String]
    let weakTopics: [String]
    let learningStreak: Int // days
}