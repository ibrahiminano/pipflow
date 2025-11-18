//
//  MyLearningView.swift
//  Pipflow
//
//  View for tracking user's learning progress and enrolled courses
//

import SwiftUI

struct MyLearningView: View {
    let userProgress: [CourseProgress]
    @Binding var showingCourseDetail: Course?
    @StateObject private var academyService = AcademyService.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedFilter = "all"
    @State private var showingCertificates = false
    
    var filteredProgress: [CourseProgress] {
        switch selectedFilter {
        case "active":
            return userProgress.filter { $0.progress < 100 }
        case "completed":
            return userProgress.filter { $0.progress >= 100 }
        default:
            return userProgress
        }
    }
    
    var totalLearningTime: Int {
        userProgress.reduce(0) { $0 + $1.totalTimeSpent }
    }
    
    var currentStreak: Int {
        // Calculate consecutive days of learning
        7 // Placeholder
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Learning Stats
            LearningStatsView(
                totalCourses: userProgress.count,
                completedCourses: userProgress.filter { $0.progress >= 100 }.count,
                totalTime: totalLearningTime,
                currentStreak: currentStreak
            )
            .padding(.horizontal)
            
            // Filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterButton(title: "All", count: userProgress.count, isSelected: selectedFilter == "all") {
                        selectedFilter = "all"
                    }
                    FilterButton(title: "Active", count: userProgress.filter { $0.progress < 100 }.count, isSelected: selectedFilter == "active") {
                        selectedFilter = "active"
                    }
                    FilterButton(title: "Completed", count: userProgress.filter { $0.progress >= 100 }.count, isSelected: selectedFilter == "completed") {
                        selectedFilter = "completed"
                    }
                }
                .padding(.horizontal)
            }
            
            // Course Progress List
            if filteredProgress.isEmpty {
                EmptyLearningView()
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(filteredProgress) { progress in
                            if let course = academyService.courses.first(where: { $0.id == progress.courseId }) {
                                CourseProgressCard(
                                    course: course,
                                    progress: progress,
                                    onTap: {
                                        showingCourseDetail = course
                                    },
                                    onContinue: {
                                        if academyService.getNextLesson(for: course.id) != nil {
                                            // Show lesson
                                        }
                                    }
                                )
                            }
                        }
                        
                        // Certificates button
                        if userProgress.contains(where: { $0.progress >= 100 }) {
                            Button(action: { showingCertificates = true }) {
                                HStack {
                                    Image(systemName: "seal.fill")
                                        .font(.title3)
                                    Text("View Certificates")
                                        .font(.bodyMedium)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundColor(themeManager.currentTheme.accentColor)
                                .padding()
                                .background(themeManager.currentTheme.accentColor.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showingCertificates) {
            CertificatesView(completedCourses: userProgress.filter { $0.progress >= 100 })
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Learning Stats View
struct LearningStatsView: View {
    let totalCourses: Int
    let completedCourses: Int
    let totalTime: Int
    let currentStreak: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Learning Journey")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                LearningStatCard(
                    icon: "book.fill",
                    value: "\(totalCourses)",
                    label: "Enrolled",
                    color: .blue
                )
                
                LearningStatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(completedCourses)",
                    label: "Completed",
                    color: .green
                )
                
                LearningStatCard(
                    icon: "clock.fill",
                    value: formatTime(totalTime),
                    label: "Time Spent",
                    color: .orange
                )
                
                LearningStatCard(
                    icon: "flame.fill",
                    value: "\(currentStreak)",
                    label: "Day Streak",
                    color: .red
                )
            }
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            return "\(hours)h"
        }
    }
}

struct LearningStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                Spacer()
            }
            
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                Spacer()
            }
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        isSelected ? Color.white.opacity(0.2) : themeManager.currentTheme.secondaryTextColor.opacity(0.2)
                    )
                    .cornerRadius(10)
            }
            .foregroundColor(isSelected ? .white : themeManager.currentTheme.textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryBackgroundColor
            )
            .cornerRadius(20)
        }
    }
}

// MARK: - Course Progress Card
struct CourseProgressCard: View {
    let course: Course
    let progress: CourseProgress
    let onTap: () -> Void
    let onContinue: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var nextLesson: String {
        let completedCount = progress.completedLessons.count
        let totalLessons = course.totalLessons
        if completedCount < totalLessons {
            return "Lesson \(completedCount + 1) of \(totalLessons)"
        } else {
            return "Course Completed!"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Course thumbnail
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.currentTheme.accentColor.opacity(0.3),
                                    themeManager.currentTheme.accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "book.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(course.title)
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .lineLimit(1)
                        
                        Text(nextLesson)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(themeManager.currentTheme.secondaryBackgroundColor)
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(progress.progress >= 100 ? Color.green : themeManager.currentTheme.accentColor)
                                    .frame(width: geometry.size.width * (progress.progress / 100), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(progress.progress))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(progress.progress >= 100 ? .green : themeManager.currentTheme.accentColor)
                        
                        if progress.progress < 100 {
                            Button(action: {
                                onContinue()
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Last accessed
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Last accessed \(formatDate(progress.lastAccessedDate))")
                        .font(.caption)
                    Spacer()
                }
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Empty Learning View
struct EmptyLearningView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No courses yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                Text("Start your learning journey by enrolling in a course")
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Certificates View
struct CertificatesView: View {
    let completedCourses: [CourseProgress]
    @StateObject private var academyService = AcademyService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(completedCourses) { progress in
                        if let course = academyService.courses.first(where: { $0.id == progress.courseId }) {
                            CertificateCard(course: course, completionDate: progress.completionDate ?? Date())
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationTitle("Certificates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
    }
}

struct CertificateCard: View {
    let course: Course
    let completionDate: Date
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Certificate of Completion")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            Text(course.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.accentColor)
                .multilineTextAlignment(.center)
            
            Text("Completed on \(formatDate(completionDate))")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            HStack(spacing: 20) {
                Button(action: {}) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.bodyMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(themeManager.currentTheme.accentColor)
                        .cornerRadius(8)
                }
                
                Button(action: {}) {
                    Label("Download", systemImage: "arrow.down.circle")
                        .font(.bodyMedium)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(themeManager.currentTheme.accentColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(
            LinearGradient(
                colors: [
                    themeManager.currentTheme.secondaryBackgroundColor,
                    themeManager.currentTheme.secondaryBackgroundColor.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 2)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

#Preview {
    MyLearningView(
        userProgress: [],
        showingCourseDetail: .constant(nil)
    )
    .environmentObject(ThemeManager())
}