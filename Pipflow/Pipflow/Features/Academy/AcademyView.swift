//
//  AcademyView.swift
//  Pipflow
//
//  Main view for the Academy & Education feature
//

import SwiftUI

struct AcademyView: View {
    @StateObject private var academyService = AcademyService.shared
    @StateObject private var tutorService = AITutorService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    @State private var showingCourseDetail: Course?
    @State private var showingAITutor = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with search
                    AcademyHeaderView(searchQuery: $academyService.searchQuery)
                        .padding(.horizontal)
                    
                    // Tab selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            AcademyTabButton(title: "All Courses", isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            AcademyTabButton(title: "My Learning", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                            AcademyTabButton(title: "Achievements", isSelected: selectedTab == 2) {
                                selectedTab = 2
                            }
                            AcademyTabButton(title: "Live Sessions", isSelected: selectedTab == 3) {
                                selectedTab = 3
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case 0:
                            AllCoursesView(
                                courses: academyService.courses,
                                featuredCourses: academyService.featuredCourses,
                                showingCourseDetail: $showingCourseDetail
                            )
                        case 1:
                            MyLearningView(
                                userProgress: academyService.userProgress,
                                showingCourseDetail: $showingCourseDetail
                            )
                        case 2:
                            AchievementsView(
                                achievements: academyService.achievements,
                                userAchievements: academyService.userAchievements
                            )
                        case 3:
                            LiveSessionsView()
                        default:
                            EmptyView()
                        }
                    }
                    .transition(.opacity)
                }
                .padding(.vertical)
            }
            .background(themeManager.currentTheme.backgroundColor)
            .navigationBarHidden(true)
            .sheet(item: $showingCourseDetail) { course in
                CourseDetailView(course: course)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingAITutor) {
                AITutorChatView()
                    .environmentObject(themeManager)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // AI Tutor floating button
            Button(action: { showingAITutor = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "brain")
                    Text("AI Tutor")
                }
                .font(.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            themeManager.currentTheme.accentColor,
                            themeManager.currentTheme.accentColor.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: themeManager.currentTheme.accentColor.opacity(0.3), radius: 10, y: 5)
            }
            .padding()
        }
    }
}

// MARK: - Header View
struct AcademyHeaderView: View {
    @Binding var searchQuery: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Academy")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textColor)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                TextField("Search courses, topics, instructors...", text: $searchQuery)
                    .foregroundColor(themeManager.currentTheme.textColor)
                
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
    }
}

// MARK: - Academy Tab Button
struct AcademyTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bodyMedium)
                .fontWeight(isSelected ? .semibold : .regular)
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

// MARK: - All Courses View
struct AllCoursesView: View {
    let courses: [Course]
    let featuredCourses: [Course]
    @Binding var showingCourseDetail: Course?
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Featured Courses
            VStack(alignment: .leading, spacing: 16) {
                Text("Featured Courses")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(featuredCourses) { course in
                            FeaturedCourseCard(course: course) {
                                showingCourseDetail = course
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Course Categories
            VStack(alignment: .leading, spacing: 16) {
                Text("Browse by Category")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    CategoryCard(title: "Beginner", icon: "star.fill", color: .green)
                    CategoryCard(title: "Technical Analysis", icon: "chart.line.uptrend.xyaxis", color: .blue)
                    CategoryCard(title: "AI Trading", icon: "brain", color: .purple)
                    CategoryCard(title: "Risk Management", icon: "shield.fill", color: .orange)
                    CategoryCard(title: "Crypto", icon: "bitcoinsign.circle.fill", color: .yellow)
                    CategoryCard(title: "Psychology", icon: "brain.head.profile", color: .pink)
                }
                .padding(.horizontal)
            }
            
            // All Courses
            VStack(alignment: .leading, spacing: 16) {
                Text("All Courses")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ForEach(courses) { course in
                        CourseListItem(course: course) {
                            showingCourseDetail = course
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Featured Course Card
struct FeaturedCourseCard: View {
    let course: Course
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.currentTheme.accentColor,
                                themeManager.currentTheme.accentColor.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 160)
                    .overlay(
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(course.title)
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .lineLimit(2)
                    
                    Text(course.instructor.name)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", course.rating))
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textColor)
                        }
                        
                        Spacer()
                        
                        Text(course.difficulty.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(course.difficulty.color)
                        
                        if course.isPremium {
                            Label("PRO", systemImage: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(width: 280)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

// MARK: - Course List Item
struct CourseListItem: View {
    let course: Course
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Thumbnail
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.currentTheme.accentColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.title)
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .lineLimit(2)
                    
                    Text(course.instructor.name)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", course.rating))
                                .font(.caption)
                        }
                        
                        Text("•")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Text(course.estimatedCompletionTime)
                            .font(.caption)
                        
                        Text("•")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Text("\(course.totalLessons) lessons")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if course.isPremium {
                        Label("PRO", systemImage: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
            .padding()
            .background(themeManager.currentTheme.secondaryBackgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Note: MyLearningView and AchievementsView are now in separate files

// MARK: - Live Sessions View (Placeholder)
struct LiveSessionsView: View {
    var body: some View {
        VStack {
            Text("Live Sessions")
                .font(.title)
            Text("Coming Soon")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    AcademyView()
        .environmentObject(ThemeManager())
}