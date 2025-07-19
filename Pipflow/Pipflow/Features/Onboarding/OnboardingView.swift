//
//  OnboardingView.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showAuth = false
    
    var body: some View {
        if showAuth {
            AuthenticationView()
        } else {
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    image: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "AI-Powered Trading",
                    subtitle: "Advanced algorithms analyze markets 24/7 to find the best trading opportunities",
                    gradient: [Color.Theme.gradientStart, Color.Theme.gradientEnd]
                )
                .tag(0)
                
                OnboardingPageView(
                    image: "person.2.circle.fill",
                    title: "Copy Expert Traders",
                    subtitle: "Follow and automatically copy trades from verified profitable traders",
                    gradient: [Color.Theme.accent, Color.Theme.gradientEnd]
                )
                .tag(1)
                
                OnboardingPageView(
                    image: "bell.circle.fill",
                    title: "Real-Time Signals",
                    subtitle: "Get instant AI-generated trading signals with clear entry and exit points",
                    gradient: [Color.Theme.info, Color.Theme.accent]
                )
                .tag(2)
                
                OnboardingPageView(
                    image: "graduationcap.circle.fill",
                    title: "Learn & Earn",
                    subtitle: "Interactive AI academy helps you master trading while earning rewards",
                    gradient: [Color.purple, Color.Theme.accent],
                    isLast: true,
                    onGetStarted: {
                        UserDefaults.standard.set(true, forKey: "has_seen_onboarding")
                        withAnimation {
                            showAuth = true
                        }
                    }
                )
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}

struct OnboardingPageView: View {
    let image: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    var isLast: Bool = false
    var onGetStarted: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with gradient background
            ZStack {
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 180, height: 180)
                .clipShape(Circle())
                .shadow(color: gradient.first?.opacity(0.5) ?? .clear, radius: 20, x: 0, y: 10)
                
                Image(systemName: image)
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.Theme.text)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.bodyLarge)
                    .foregroundColor(Color.Theme.text.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            if isLast {
                Button(action: {
                    onGetStarted?()
                }) {
                    Text("Get Started")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(.cornerRadius)
                        .shadow(color: Color.Theme.shadow, radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            } else {
                Spacer()
                    .frame(height: 100)
            }
        }
        .background(Color.Theme.background)
    }
}

#Preview {
    OnboardingView()
}