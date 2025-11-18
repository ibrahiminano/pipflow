//
//  AcademyService.swift
//  Pipflow
//
//  Service for managing academy content and progress
//

import Foundation
import Combine

@MainActor
class AcademyService: ObservableObject {
    static let shared = AcademyService()
    
    @Published var courses: [Course] = []
    @Published var featuredCourses: [Course] = []
    @Published var userProgress: [CourseProgress] = []
    @Published var achievements: [Achievement] = []
    @Published var userAchievements: Set<UUID> = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadMockData()
        setupSearch()
    }
    
    // MARK: - Course Management
    
    func loadMockData() {
        // Create mock instructors
        let instructor1 = Instructor(
            id: UUID(),
            name: "Alex Thompson",
            bio: "Professional trader with 15 years of experience in forex and crypto markets",
            avatarURL: "instructor1",
            expertise: ["Forex", "Technical Analysis", "Risk Management"],
            rating: 4.8,
            totalStudents: 12500
        )
        
        let instructor2 = Instructor(
            id: UUID(),
            name: "Sarah Chen",
            bio: "Quantitative analyst and AI trading specialist",
            avatarURL: "instructor2",
            expertise: ["AI Trading", "Python", "Machine Learning"],
            rating: 4.9,
            totalStudents: 8200
        )
        
        // Create mock courses
        courses = [
            createBeginnerTradingCourse(instructor: instructor1),
            createAITradingCourse(instructor: instructor2),
            createRiskManagementCourse(instructor: instructor1),
            createTechnicalAnalysisCourse(instructor: instructor1),
            createCryptoTradingCourse(instructor: instructor2)
        ]
        
        featuredCourses = Array(courses.prefix(3))
        
        // Create mock achievements
        achievements = createAchievements()
    }
    
    private func createBeginnerTradingCourse(instructor: Instructor) -> Course {
        let module1 = Module(
            id: UUID(),
            title: "Introduction to Trading",
            description: "Learn the basics of trading and financial markets",
            orderIndex: 0,
            lessons: [
                Lesson(
                    id: UUID(),
                    title: "What is Trading?",
                    description: "Understanding the fundamentals of trading",
                    orderIndex: 0,
                    type: .video,
                    content: .video(VideoContent(
                        videoURL: "intro_to_trading.mp4",
                        duration: 15,
                        transcriptURL: "intro_transcript.txt",
                        chapters: [
                            VideoChapter(title: "Introduction", timestamp: 0),
                            VideoChapter(title: "Types of Markets", timestamp: 180),
                            VideoChapter(title: "Trading vs Investing", timestamp: 420)
                        ]
                    )),
                    estimatedDuration: 15,
                    resources: [],
                    practiceExercises: []
                ),
                Lesson(
                    id: UUID(),
                    title: "Market Terminology",
                    description: "Essential trading terms you need to know",
                    orderIndex: 1,
                    type: .article,
                    content: .article(ArticleContent(
                        markdownContent: "# Market Terminology\n\n## Key Terms\n\n...",
                        readingTime: 10,
                        images: ["terminology_chart.png"]
                    )),
                    estimatedDuration: 10,
                    resources: [],
                    practiceExercises: createBasicExercises()
                )
            ],
            quiz: createBasicQuiz()
        )
        
        return Course(
            id: UUID(),
            title: "Trading Fundamentals for Beginners",
            description: "Start your trading journey with this comprehensive beginner course",
            thumbnail: "beginner_course_thumb",
            instructor: instructor,
            difficulty: .beginner,
            duration: 180,
            modules: [module1],
            tags: ["Trading", "Beginner", "Fundamentals"],
            rating: 4.7,
            enrollmentCount: 5420,
            lastUpdated: Date(),
            isPremium: false
        )
    }
    
    private func createAITradingCourse(instructor: Instructor) -> Course {
        let module1 = Module(
            id: UUID(),
            title: "Introduction to AI Trading",
            description: "Understanding how AI is revolutionizing trading",
            orderIndex: 0,
            lessons: [
                Lesson(
                    id: UUID(),
                    title: "AI in Financial Markets",
                    description: "Overview of AI applications in trading",
                    orderIndex: 0,
                    type: .interactive,
                    content: .interactive(InteractiveContent(
                        htmlContent: "<div>Interactive AI concepts...</div>",
                        requiredInteractions: ["concept_1", "concept_2"],
                        checkpoints: []
                    )),
                    estimatedDuration: 20,
                    resources: [],
                    practiceExercises: []
                ),
                Lesson(
                    id: UUID(),
                    title: "Building Your First Trading Bot",
                    description: "Step-by-step guide to creating an AI trading bot",
                    orderIndex: 1,
                    type: .liveCoding,
                    content: .liveCoding(LiveCodingContent(
                        language: "python",
                        initialCode: "# Your first trading bot\nimport pandas as pd\n\ndef analyze_market(data):\n    # TODO: Implement analysis\n    pass",
                        solution: "# Complete solution...",
                        testCases: [
                            TestCase(input: "EURUSD", expectedOutput: "BUY", isHidden: false)
                        ],
                        hints: ["Consider using moving averages", "Check for trend direction"]
                    )),
                    estimatedDuration: 30,
                    resources: [],
                    practiceExercises: []
                )
            ],
            quiz: nil
        )
        
        return Course(
            id: UUID(),
            title: "AI-Powered Trading Strategies",
            description: "Learn to build and deploy AI trading systems",
            thumbnail: "ai_course_thumb",
            instructor: instructor,
            difficulty: .advanced,
            duration: 420,
            modules: [module1],
            tags: ["AI", "Machine Learning", "Advanced"],
            rating: 4.9,
            enrollmentCount: 2150,
            lastUpdated: Date(),
            isPremium: true
        )
    }
    
    private func createRiskManagementCourse(instructor: Instructor) -> Course {
        return Course(
            id: UUID(),
            title: "Mastering Risk Management",
            description: "Protect your capital with professional risk management techniques",
            thumbnail: "risk_course_thumb",
            instructor: instructor,
            difficulty: .intermediate,
            duration: 240,
            modules: [],
            tags: ["Risk Management", "Strategy", "Essential"],
            rating: 4.8,
            enrollmentCount: 3890,
            lastUpdated: Date(),
            isPremium: false
        )
    }
    
    private func createTechnicalAnalysisCourse(instructor: Instructor) -> Course {
        return Course(
            id: UUID(),
            title: "Technical Analysis Masterclass",
            description: "Chart patterns, indicators, and advanced technical analysis",
            thumbnail: "tech_analysis_thumb",
            instructor: instructor,
            difficulty: .intermediate,
            duration: 360,
            modules: [],
            tags: ["Technical Analysis", "Charts", "Indicators"],
            rating: 4.6,
            enrollmentCount: 4230,
            lastUpdated: Date(),
            isPremium: true
        )
    }
    
    private func createCryptoTradingCourse(instructor: Instructor) -> Course {
        return Course(
            id: UUID(),
            title: "Cryptocurrency Trading Essentials",
            description: "Navigate the exciting world of crypto trading",
            thumbnail: "crypto_course_thumb",
            instructor: instructor,
            difficulty: .intermediate,
            duration: 300,
            modules: [],
            tags: ["Cryptocurrency", "Bitcoin", "DeFi"],
            rating: 4.7,
            enrollmentCount: 6720,
            lastUpdated: Date(),
            isPremium: false
        )
    }
    
    private func createBasicExercises() -> [Exercise] {
        return [
            Exercise(
                id: UUID(),
                question: "What is the difference between a bid and ask price?",
                type: .multipleChoice,
                options: [
                    "Bid is higher than ask",
                    "Ask is the price to buy, bid is the price to sell",
                    "They are always the same",
                    "Bid is the price to buy, ask is the price to sell"
                ],
                correctAnswer: "Ask is the price to buy, bid is the price to sell",
                explanation: "The ask price is what you pay to buy, while the bid price is what you receive when selling",
                difficulty: .beginner
            )
        ]
    }
    
    private func createBasicQuiz() -> Quiz {
        return Quiz(
            id: UUID(),
            title: "Trading Basics Quiz",
            description: "Test your understanding of trading fundamentals",
            questions: [
                QuizQuestion(
                    id: UUID(),
                    question: "What is a pip in forex trading?",
                    type: .multipleChoice,
                    options: [
                        AnswerOption(id: UUID(), text: "A type of currency", isCorrect: false),
                        AnswerOption(id: UUID(), text: "The smallest price move", isCorrect: true),
                        AnswerOption(id: UUID(), text: "A trading platform", isCorrect: false),
                        AnswerOption(id: UUID(), text: "A type of order", isCorrect: false)
                    ],
                    correctAnswer: "The smallest price move",
                    explanation: "A pip (percentage in point) is the smallest price move in a currency pair",
                    points: 10,
                    hint: "Think about price movements",
                    imageURL: nil
                )
            ],
            passingScore: 70,
            timeLimit: 10,
            allowRetake: true,
            showAnswersAfter: true
        )
    }
    
    private func createAchievements() -> [Achievement] {
        return [
            Achievement(
                id: UUID(),
                title: "First Steps",
                description: "Complete your first lesson",
                icon: "star.fill",
                category: .learning,
                requirement: .completeCourses(count: 1),
                points: 10,
                rarity: .common
            ),
            Achievement(
                id: UUID(),
                title: "Quiz Master",
                description: "Pass 10 quizzes with a perfect score",
                icon: "checkmark.seal.fill",
                category: .mastery,
                requirement: .completeCourses(count: 10),
                points: 100,
                rarity: .rare
            ),
            Achievement(
                id: UUID(),
                title: "Dedicated Learner",
                description: "Maintain a 7-day learning streak",
                icon: "flame.fill",
                category: .streak,
                requirement: .dailyStreak(days: 7),
                points: 50,
                rarity: .rare
            )
        ]
    }
    
    // MARK: - Search
    
    private func setupSearch() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.filterCourses(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func filterCourses(query: String) {
        // Implement search logic
    }
    
    // MARK: - Progress Tracking
    
    func startCourse(_ courseId: UUID) {
        guard let course = courses.first(where: { $0.id == courseId }) else { return }
        
        let progress = CourseProgress(
            id: UUID(),
            userId: UUID(), // Current user ID
            courseId: courseId,
            startedAt: Date(),
            lastAccessedAt: Date(),
            completedLessons: [],
            quizScores: [:],
            totalTimeSpent: 0,
            currentModuleId: course.modules.first?.id,
            currentLessonId: course.modules.first?.lessons.first?.id
        )
        
        userProgress.append(progress)
    }
    
    func completeLesson(_ lessonId: UUID, in courseId: UUID) {
        guard let index = userProgress.firstIndex(where: { $0.courseId == courseId }) else { return }
        
        userProgress[index].completedLessons.insert(lessonId)
        userProgress[index].lastAccessedAt = Date()
        
        // Check for achievements
        checkAchievements()
    }
    
    func submitQuiz(_ quizId: UUID, score: QuizScore, courseId: UUID) {
        guard let index = userProgress.firstIndex(where: { $0.courseId == courseId }) else { return }
        
        userProgress[index].quizScores[quizId] = score
        
        // Check for achievements
        checkAchievements()
    }
    
    private func checkAchievements() {
        // Check each achievement requirement
        for achievement in achievements {
            guard !userAchievements.contains(achievement.id) else { continue }
            
            switch achievement.requirement {
            case .completeCourses(let count):
                let completedCount = userProgress.filter { $0.completionPercentage == 100 }.count
                if completedCount >= count {
                    unlockAchievement(achievement)
                }
                
            case .completeModules(let count):
                let totalModules = userProgress.reduce(0) { total, progress in
                    total + progress.completedLessons.count
                }
                if totalModules >= count {
                    unlockAchievement(achievement)
                }
                
            case .passQuizzes(let count):
                let passedQuizzes = userProgress.reduce(0) { total, progress in
                    total + progress.quizScores.values.filter { $0.score >= 70 }.count
                }
                if passedQuizzes >= count {
                    unlockAchievement(achievement)
                }
                
            case .perfectScore(let count):
                let perfectScores = userProgress.reduce(0) { total, progress in
                    total + progress.quizScores.values.filter { $0.score == 100 }.count
                }
                if perfectScores >= count {
                    unlockAchievement(achievement)
                }
                
            default:
                break
            }
        }
    }
    
    private func unlockAchievement(_ achievement: Achievement) {
        userAchievements.insert(achievement.id)
        
        // Show notification
        NotificationManager.shared.showAchievementUnlocked(achievement)
    }
    
    // MARK: - Course Recommendations
    
    func getRecommendedCourses(for user: User? = nil) -> [Course] {
        // Simple recommendation logic
        let completedCourseIds = Set(userProgress.map { $0.courseId })
        
        return courses
            .filter { !completedCourseIds.contains($0.id) }
            .sorted { $0.rating > $1.rating }
            .prefix(5)
            .map { $0 }
    }
    
    func getNextLesson(for courseId: UUID) -> Lesson? {
        guard let progress = userProgress.first(where: { $0.courseId == courseId }),
              let course = courses.first(where: { $0.id == courseId }) else {
            return nil
        }
        
        // Find the next uncompleted lesson
        for module in course.modules.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            for lesson in module.lessons.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                if !progress.completedLessons.contains(lesson.id) {
                    return lesson
                }
            }
        }
        
        return nil
    }
}