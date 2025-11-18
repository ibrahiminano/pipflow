//
//  CourseDetailView.swift
//  Pipflow
//
//  Detailed view for a specific course
//

import SwiftUI

struct CourseDetailView: View {
    let course: Course
    @StateObject private var academyService = AcademyService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedModule: Module?
    @State private var showingLesson: Lesson?
    @State private var isEnrolled = false
    @State private var expandedModules: Set<UUID> = []
    
    var courseProgress: CourseProgress? {
        academyService.userProgress.first { $0.courseId == course.id }
    }
    
    var completionPercentage: Int {
        guard let progress = courseProgress else { return 0 }
        let totalLessons = course.totalLessons
        guard totalLessons > 0 else { return 0 }
        return (progress.completedLessons.count * 100) / totalLessons
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    CourseHeaderView(
                        course: course,
                        isEnrolled: isEnrolled,
                        completionPercentage: completionPercentage,
                        onEnroll: enrollInCourse,
                        onContinue: continuelearning
                    )
                    
                    // Course Info
                    CourseInfoSection(course: course)
                        .padding()
                    
                    // Instructor
                    InstructorSection(instructor: course.instructor)
                        .padding()
                    
                    Divider()
                        .background(themeManager.currentTheme.separatorColor)
                    
                    // Course Content
                    CourseContentSection(
                        modules: course.modules,
                        expandedModules: $expandedModules,
                        completedLessons: courseProgress?.completedLessons ?? [],
                        onSelectLesson: { lesson in
                            showingLesson = lesson
                        }
                    )
                    .padding()
                    
                    // Reviews Section (placeholder)
                    ReviewsSection()
                        .padding()
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {}) {
                            Label("Share Course", systemImage: "square.and.arrow.up")
                        }
                        Button(action: {}) {
                            Label("Download for Offline", systemImage: "arrow.down.circle")
                        }
                        if isEnrolled {
                            Button(action: {}) {
                                Label("Reset Progress", systemImage: "arrow.counterclockwise")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                }
            }
        }
        .sheet(item: $showingLesson) { lesson in
            LessonView(lesson: lesson, courseId: course.id)
                .environmentObject(themeManager)
        }
        .onAppear {
            checkEnrollmentStatus()
        }
    }
    
    private func checkEnrollmentStatus() {
        isEnrolled = academyService.userProgress.contains { $0.courseId == course.id }
    }
    
    private func enrollInCourse() {
        academyService.startCourse(course.id)
        isEnrolled = true
    }
    
    private func continuelearning() {
        if let nextLesson = academyService.getNextLesson(for: course.id) {
            showingLesson = nextLesson
        }
    }
}

// MARK: - Course Header
struct CourseHeaderView: View {
    let course: Course
    let isEnrolled: Bool
    let completionPercentage: Int
    let onEnroll: () -> Void
    let onContinue: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Video/Image placeholder
            ZStack {
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.accentColor,
                        themeManager.currentTheme.accentColor.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 200)
                
                VStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Preview Course")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text(course.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text(course.description)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                // Action buttons
                HStack(spacing: 12) {
                    if isEnrolled {
                        Button(action: onContinue) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Continue Learning")
                            }
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.currentTheme.accentColor)
                            .cornerRadius(12)
                        }
                        
                        // Progress indicator
                        VStack(spacing: 4) {
                            Text("\(completionPercentage)%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            Text("Complete")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                        .frame(width: 80)
                    } else {
                        Button(action: onEnroll) {
                            HStack {
                                if course.isPremium {
                                    Image(systemName: "crown.fill")
                                }
                                Text(course.isPremium ? "Unlock Course" : "Enroll Now")
                            }
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                course.isPremium 
                                    ? LinearGradient(
                                        colors: [Color.yellow, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [themeManager.currentTheme.accentColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Course Info Section
struct CourseInfoSection: View {
    let course: Course
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                InfoItem(
                    icon: "clock",
                    title: "Duration",
                    value: course.estimatedCompletionTime
                )
                
                InfoItem(
                    icon: "book.closed",
                    title: "Lessons",
                    value: "\(course.totalLessons)"
                )
                
                InfoItem(
                    icon: "chart.bar.fill",
                    title: "Level",
                    value: course.difficulty.displayName
                )
                
                InfoItem(
                    icon: "person.2.fill",
                    title: "Students",
                    value: "\(course.enrollmentCount)"
                )
            }
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(course.tags, id: \.self) { tag in
                        CourseTagView(tag: tag)
                    }
                }
            }
        }
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(themeManager.currentTheme.accentColor)
            
            Text(value)
                .font(.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CourseTagView: View {
    let tag: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(themeManager.currentTheme.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(themeManager.currentTheme.accentColor.opacity(0.1))
            .cornerRadius(15)
    }
}

// MARK: - Instructor Section
struct InstructorSection: View {
    let instructor: Instructor
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Instructor")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            HStack(spacing: 16) {
                Circle()
                    .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(instructor.name.prefix(2))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(instructor.name)
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", instructor.rating))
                                .font(.caption)
                        }
                        
                        Text("•")
                        
                        Text("\(instructor.totalStudents) students")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Text(instructor.bio)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(2)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Course Content Section
struct CourseContentSection: View {
    let modules: [Module]
    @Binding var expandedModules: Set<UUID>
    let completedLessons: Set<UUID>
    let onSelectLesson: (Lesson) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Course Content")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            VStack(spacing: 12) {
                ForEach(modules.sorted(by: { $0.orderIndex < $1.orderIndex })) { module in
                    ModuleCard(
                        module: module,
                        isExpanded: expandedModules.contains(module.id),
                        completedLessons: completedLessons,
                        onToggle: {
                            withAnimation {
                                if expandedModules.contains(module.id) {
                                    expandedModules.remove(module.id)
                                } else {
                                    expandedModules.insert(module.id)
                                }
                            }
                        },
                        onSelectLesson: onSelectLesson
                    )
                }
            }
        }
    }
}

struct ModuleCard: View {
    let module: Module
    let isExpanded: Bool
    let completedLessons: Set<UUID>
    let onToggle: () -> Void
    let onSelectLesson: (Lesson) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var completedCount: Int {
        module.lessons.filter { completedLessons.contains($0.id) }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Module \(module.orderIndex + 1): \(module.title)")
                            .font(.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        
                        HStack(spacing: 12) {
                            Text("\(module.lessons.count) lessons")
                            Text("•")
                            Text("\(module.duration) min")
                            if completedCount > 0 {
                                Text("•")
                                Text("\(completedCount)/\(module.lessons.count) completed")
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                .padding()
            }
            
            if isExpanded {
                Divider()
                    .background(themeManager.currentTheme.separatorColor)
                
                VStack(spacing: 0) {
                    ForEach(module.lessons.sorted(by: { $0.orderIndex < $1.orderIndex })) { lesson in
                        LessonRow(
                            lesson: lesson,
                            isCompleted: completedLessons.contains(lesson.id),
                            onSelect: { onSelectLesson(lesson) }
                        )
                        
                        if lesson != module.lessons.last {
                            Divider()
                                .background(themeManager.currentTheme.separatorColor)
                                .padding(.leading, 48)
                        }
                    }
                }
            }
        }
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

struct LessonRow: View {
    let lesson: Lesson
    let isCompleted: Bool
    let onSelect: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : lesson.type.icon)
                    .font(.title3)
                    .foregroundColor(isCompleted ? .green : themeManager.currentTheme.accentColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    HStack(spacing: 8) {
                        Text(lesson.type.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        
                        Text("•")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Text("\(lesson.estimatedDuration) min")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Reviews Section
struct ReviewsSection: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Student Reviews")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Spacer()
                
                Button(action: {}) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
            
            // Placeholder for reviews
            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<3) { _ in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(themeManager.currentTheme.secondaryBackgroundColor)
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("John Doe")
                                    .font(.bodyMedium)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                HStack(spacing: 2) {
                                    ForEach(0..<5) { i in
                                        Image(systemName: i < 4 ? "star.fill" : "star")
                                            .font(.caption2)
                                            .foregroundColor(.yellow)
                                    }
                                }
                            }
                            
                            Text("Great course! Really helped me understand the basics.")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    CourseDetailView(
        course: Course(
            id: UUID(),
            title: "Sample Course",
            description: "Learn the basics",
            thumbnail: "",
            instructor: Instructor(
                id: UUID(),
                name: "John Doe",
                bio: "Expert trader",
                avatarURL: "",
                expertise: ["Trading"],
                rating: 4.8,
                totalStudents: 1000
            ),
            difficulty: .beginner,
            duration: 120,
            modules: [],
            tags: ["Trading", "Beginner"],
            rating: 4.7,
            enrollmentCount: 500,
            lastUpdated: Date(),
            isPremium: false
        )
    )
    .environmentObject(ThemeManager())
}