//
//  CustomTabBar.swift
//  Pipflow
//
//  Premium custom tab bar with glassmorphic design
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var animation
    
    let tabs = [
        TabItem(icon: "chart.line.uptrend.xyaxis", title: "Dashboard", tag: 0),
        TabItem(icon: "chart.bar.xaxis", title: "Market", tag: 1),
        TabItem(icon: "arrow.up.arrow.down", title: "Trade", tag: 2),
        TabItem(icon: "person.3.fill", title: "Social", tag: 3),
        TabItem(icon: "ellipsis", title: "More", tag: 4)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tag) { tab in
                TabButton(
                    icon: tab.icon,
                    title: tab.title,
                    tag: tab.tag,
                    selectedTab: $selectedTab,
                    animation: animation
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Glass background
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let tag: Int
    @Binding var selectedTab: Int
    let animation: Namespace.ID
    
    var isSelected: Bool {
        selectedTab == tag
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tag
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "00F5A0"),
                                        Color(hex: "00D9FF")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .matchedGeometryEffect(id: "TAB_SELECTED", in: animation)
                            .shadow(color: Color(hex: "00F5A0").opacity(0.5), radius: 10)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(width: 40, height: 40)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabItem {
    let icon: String
    let title: String
    let tag: Int
}

// MARK: - Premium Content View with Custom Tab Bar

struct PremiumContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var chartManager = ChartPresentationManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dark background
            GlassTheme.darkGradientBackground()
                .ignoresSafeArea()
            
            // Content
            Group {
                switch selectedTab {
                case 0:
                    PremiumDashboardView()
                case 1:
                    MarketWatchView()
                case 2:
                    TradingView()
                case 3:
                    ModernSocialHub()
                case 4:
                    MoreOptionsView()
                default:
                    PremiumDashboardView()
                }
            }
            .transition(.opacity)
            
            // Custom Tab Bar
            VStack(spacing: 0) {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard)
        }
        .fullScreenCover(isPresented: $chartManager.showChart) {
            ChartView(symbol: chartManager.selectedSymbol)
                .environmentObject(themeManager)
                .preferredColorScheme(.dark)
                .statusBar(hidden: true)
        }
    }
}

struct MoreOptionsView: View {
    var body: some View {
        NavigationView {
            ZStack {
                GlassTheme.darkGradientBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // More Options
                        moreOptionsList
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    var moreOptionsList: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("More")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.top, 60)
            
            // Options
            GlassCard {
                VStack(spacing: 0) {
                    MoreOptionRow(icon: "sparkles", title: "AI Signals", badge: "12")
                    Divider().background(Color.white.opacity(0.1))
                    MoreOptionRow(icon: "person.crop.circle", title: "Profile")
                    Divider().background(Color.white.opacity(0.1))
                    MoreOptionRow(icon: "gearshape.fill", title: "Settings")
                    Divider().background(Color.white.opacity(0.1))
                    MoreOptionRow(icon: "graduationcap.fill", title: "Academy")
                    Divider().background(Color.white.opacity(0.1))
                    MoreOptionRow(icon: "chart.pie.fill", title: "Analytics")
                }
            }
            
            GlassCard {
                VStack(spacing: 0) {
                    MoreOptionRow(icon: "questionmark.circle.fill", title: "Help & Support")
                    Divider().background(Color.white.opacity(0.1))
                    MoreOptionRow(icon: "doc.text.fill", title: "Legal")
                    Divider().background(Color.white.opacity(0.1))
                    MoreOptionRow(icon: "arrow.right.square.fill", title: "Sign Out", isDestructive: true)
                }
            }
        }
    }
}

struct MoreOptionRow: View {
    let icon: String
    let title: String
    var badge: String? = nil
    var isDestructive: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isDestructive ? .red : .white.opacity(0.8))
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundColor(isDestructive ? .red : .white)
            
            Spacer()
            
            if let badge = badge {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "FF006E"))
                    .clipShape(Capsule())
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 16)
    }
}

// Preview
#Preview {
    PremiumContentView()
        .environmentObject(ThemeManager())
}