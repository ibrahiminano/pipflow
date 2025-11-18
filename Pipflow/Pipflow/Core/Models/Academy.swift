//
//  Academy.swift
//  Pipflow
//
//  Data models for the Academy & Education feature
//

import Foundation
import SwiftUI

// MARK: - Course Models

struct Course: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let thumbnail: String
    let instructor: Instructor
    let difficulty: DifficultyLevel
    let duration: Int // in minutes
    let modules: [Module]
    let tags: [String]
    let rating: Double
    let enrollmentCount: Int
    let lastUpdated: Date
    let isPremium: Bool
    
    var totalLessons: Int {
        modules.reduce(0) { $0 + $1.lessons.count }
    }
    
    var estimatedCompletionTime: String {
        let hours = duration / 60
        let minutes = duration % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct Module: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let orderIndex: Int
    let lessons: [Lesson]
    let quiz: Quiz?
    
    var duration: Int {
        lessons.reduce(0) { $0 + $1.estimatedDuration }
    }
}

struct Lesson: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let orderIndex: Int
    let type: LessonType
    let content: LessonContent
    let estimatedDuration: Int // in minutes
    let resources: [Resource]
    let practiceExercises: [Exercise]
    
    static func == (lhs: Lesson, rhs: Lesson) -> Bool {
        lhs.id == rhs.id
    }
}

enum LessonType: String, Codable, CaseIterable {
    case video = "video"
    case article = "article"
    case interactive = "interactive"
    case liveCoding = "live_coding"
    case simulation = "simulation"
    
    var icon: String {
        switch self {
        case .video: return "play.circle.fill"
        case .article: return "doc.text.fill"
        case .interactive: return "hand.tap.fill"
        case .liveCoding: return "chevron.left.forwardslash.chevron.right"
        case .simulation: return "chart.line.uptrend.xyaxis"
        }
    }
}

enum LessonContent: Codable, Equatable {
    case video(VideoContent)
    case article(ArticleContent)
    case interactive(InteractiveContent)
    case liveCoding(LiveCodingContent)
    case simulation(SimulationContent)
}

struct VideoContent: Codable, Equatable {
    let videoURL: String
    let duration: Int
    let transcriptURL: String?
    let chapters: [VideoChapter]
}

struct VideoChapter: Codable, Equatable {
    let title: String
    let timestamp: Int // in seconds
}

struct ArticleContent: Codable, Equatable {
    let markdownContent: String
    let readingTime: Int
    let images: [String]
}

struct InteractiveContent: Codable, Equatable {
    let htmlContent: String
    let requiredInteractions: [String]
    let checkpoints: [InteractionCheckpoint]
}

struct InteractionCheckpoint: Codable, Equatable {
    let id: String
    let description: String
    let validation: String // JavaScript code for validation
}

struct LiveCodingContent: Codable, Equatable {
    let language: String
    let initialCode: String
    let solution: String
    let testCases: [TestCase]
    let hints: [String]
}

struct TestCase: Codable, Equatable {
    let input: String
    let expectedOutput: String
    let isHidden: Bool
}

struct SimulationContent: Codable, Equatable {
    let simulationType: SimulationType
    let parameters: [String: Any]
    let objectives: [String]
    
    enum CodingKeys: String, CodingKey {
        case simulationType
        case parameters
        case objectives
    }
    
    init(simulationType: SimulationType, parameters: [String: Any], objectives: [String]) {
        self.simulationType = simulationType
        self.parameters = parameters
        self.objectives = objectives
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        simulationType = try container.decode(SimulationType.self, forKey: .simulationType)
        objectives = try container.decode([String].self, forKey: .objectives)
        parameters = [:] // Simplified for now
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(simulationType, forKey: .simulationType)
        try container.encode(objectives, forKey: .objectives)
        // Skip parameters for now
    }
    
    static func == (lhs: SimulationContent, rhs: SimulationContent) -> Bool {
        lhs.simulationType == rhs.simulationType && lhs.objectives == rhs.objectives
        // We skip parameters comparison since [String: Any] is not Equatable
    }
}

enum SimulationType: String, Codable {
    case trading = "trading"
    case riskManagement = "risk_management"
    case marketAnalysis = "market_analysis"
    case portfolioOptimization = "portfolio_optimization"
}

struct Resource: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let type: ResourceType
    let url: String
    let description: String?
    
    static func == (lhs: Resource, rhs: Resource) -> Bool {
        lhs.id == rhs.id
    }
}

enum ResourceType: String, Codable {
    case pdf = "pdf"
    case video = "video"
    case github = "github"
    case external = "external"
}

struct Exercise: Identifiable, Codable, Equatable {
    let id: UUID
    let question: String
    let type: ExerciseType
    let options: [String]?
    let correctAnswer: String
    let explanation: String
    let difficulty: DifficultyLevel
    
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
}

enum ExerciseType: String, Codable {
    case multipleChoice = "multiple_choice"
    case trueFalse = "true_false"
    case fillInBlank = "fill_blank"
    case coding = "coding"
    case calculation = "calculation"
}

// MARK: - Quiz Models

struct Quiz: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let questions: [QuizQuestion]
    let passingScore: Int // percentage
    let timeLimit: Int? // in minutes
    let allowRetake: Bool
    let showAnswersAfter: Bool
}

struct QuizQuestion: Identifiable, Codable {
    let id: UUID
    let question: String
    let type: QuestionType
    let options: [AnswerOption]?
    let correctAnswer: String
    let explanation: String
    let points: Int
    let hint: String?
    let imageURL: String?
}

enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case multipleSelect = "multiple_select"
    case trueFalse = "true_false"
    case shortAnswer = "short_answer"
    case essay = "essay"
    case coding = "coding"
}

struct AnswerOption: Identifiable, Codable {
    let id: UUID
    let text: String
    let isCorrect: Bool
}

// MARK: - Progress Models

struct CourseProgress: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let courseId: UUID
    let startedAt: Date
    var lastAccessedAt: Date
    var completedLessons: Set<UUID>
    var quizScores: [UUID: QuizScore]
    var totalTimeSpent: Int // in minutes
    var currentModuleId: UUID?
    var currentLessonId: UUID?
    var completionDate: Date?
    
    var completionPercentage: Int {
        // Calculate based on completed lessons
        0 // Placeholder
    }
    
    var progress: Double {
        Double(completionPercentage)
    }
    
    var lastAccessedDate: Date {
        lastAccessedAt
    }
}

struct QuizScore: Codable {
    let quizId: UUID
    let score: Int
    let maxScore: Int
    let attemptCount: Int
    let completedAt: Date
    let timeSpent: Int // in seconds
    let answers: [UUID: String] // questionId: answer
}

struct LessonProgress: Identifiable, Codable {
    let id: UUID
    let lessonId: UUID
    let userId: UUID
    let startedAt: Date
    let completedAt: Date?
    let timeSpent: Int
    let interactionProgress: [String: Bool] // For interactive content
    let videoProgress: Double? // Percentage for video content
    let exerciseScores: [UUID: Int]
}

// MARK: - Achievement Models

struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: AchievementRequirement
    let points: Int
    let rarity: AchievementRarity
    var dateEarned: Date?
}

enum AchievementCategory: String, Codable, CaseIterable {
    case learning = "learning"
    case practice = "practice"
    case streak = "streak"
    case social = "social"
    case mastery = "mastery"
    case trading = "trading"
}

enum AchievementRequirement: Codable {
    case completeCourses(count: Int)
    case completeModules(count: Int)
    case passQuizzes(count: Int)
    case dailyStreak(days: Int)
    case perfectScore(count: Int)
    case helpOthers(count: Int)
}

enum AchievementRarity: String, Codable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Supporting Models

struct Instructor: Identifiable, Codable {
    let id: UUID
    let name: String
    let bio: String
    let avatarURL: String
    let expertise: [String]
    let rating: Double
    let totalStudents: Int
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
}

// MARK: - AI Tutor Models

struct AITutorSession: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let startedAt: Date
    let context: TutorContext
    var messages: [TutorMessage]
}

struct TutorContext: Codable {
    let courseId: UUID?
    let lessonId: UUID?
    let topic: String
    let difficultyLevel: DifficultyLevel
    let learningObjectives: [String]
}

struct TutorMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let attachments: [MessageAttachment]?
    let suggestedActions: [TutorAction]?
}

enum MessageRole: String, Codable {
    case user = "user"
    case tutor = "tutor"
    case system = "system"
}

struct MessageAttachment: Codable {
    let type: AttachmentType
    let url: String
    let caption: String?
}

enum AttachmentType: String, Codable {
    case image = "image"
    case code = "code"
    case chart = "chart"
    case link = "link"
}

struct TutorAction: Identifiable, Codable {
    let id: UUID
    let type: ActionType
    let title: String
    let data: [String: String]
}

enum ActionType: String, Codable {
    case viewLesson = "view_lesson"
    case startQuiz = "start_quiz"
    case practiceExercise = "practice_exercise"
    case reviewConcept = "review_concept"
    case askFollowUp = "ask_follow_up"
}