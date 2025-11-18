//
//  FuturisticTabBar.swift
//  Pipflow
//
//  Holographic Navigation System
//

import SwiftUI

struct FuturisticTabBar: View {
    @Binding var selectedTab: Int
    @State private var hoveredTab: Int? = nil
    @State private var particleEffect = false
    @Namespace private var animation
    
    let tabs = [
        TabItem(icon: "brain", title: "Neural", tag: 0),
        TabItem(icon: "chart.xyaxis.line", title: "Trading", tag: 1),
        TabItem(icon: "sparkles", title: "AI Lab", tag: 2),
        TabItem(icon: "person.2.wave.2", title: "Social", tag: 3),
        TabItem(icon: "square.stack.3d.up", title: "More", tag: 4)
    ]
    
    var body: some View {
        ZStack {
            // Background with glass effect
            UnevenRoundedRectangle(
                topLeadingRadius: 30,
                topTrailingRadius: 30
            )
            .fill(.ultraThinMaterial)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 30,
                    topTrailingRadius: 30
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.neonCyan.opacity(0.3),
                            Color.electricBlue.opacity(0.3),
                            Color.neonPurple.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, y: -10)
            
            // Circuit pattern overlay
            FuturisticEffects.circuitPattern()
                .opacity(0.05)
                .mask(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 30,
                        topTrailingRadius: 30
                    )
                )
            
            // Tab Items
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    TabBarItem(
                        tab: tabs[index],
                        isSelected: selectedTab == index,
                        isHovered: hoveredTab == index,
                        namespace: animation,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                                particleEffect.toggle()
                            }
                        }
                    )
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hoveredTab = isHovered ? index : nil
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            
            // Selection indicator
            GeometryReader { geometry in
                if selectedTab < tabs.count {
                    let itemWidth = (geometry.size.width - 40) / CGFloat(tabs.count)
                    let xOffset = CGFloat(selectedTab) * itemWidth + itemWidth / 2 + 20
                    
                    // Holographic selection effect
                    Circle()
                        .fill(.blue)
                        .frame(width: 4, height: 4)
                        .shadow(color: .blue, radius: 10)
                        .offset(x: xOffset, y: 70)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    
                    // Energy beam effect
                    if particleEffect {
                        ForEach(0..<5, id: \.self) { _ in
                            Circle()
                                .fill(.blue)
                                .frame(width: 2, height: 2)
                                .offset(
                                    x: xOffset + CGFloat.random(in: -20...20),
                                    y: 70 + CGFloat.random(in: -20...20)
                                )
                                .opacity(particleEffect ? 0 : 1)
                                .animation(
                                    .easeOut(duration: 0.6),
                                    value: particleEffect
                                )
                        }
                    }
                }
            }
        }
        .frame(height: 85)
    }
}

struct TabBarItem: View {
    let tab: TabItem
    let isSelected: Bool
    let isHovered: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    @State private var bounce = false
    
    var body: some View {
        Button(action: {
            action()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bounce.toggle()
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Background glow when selected
                    if isSelected {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .blur(radius: 10)
                            .matchedGeometryEffect(id: "glow", in: namespace)
                    }
                    
                    // Icon
                    Image(systemName: tab.icon)
                        .font(.system(size: 24))
                        .symbolEffect(.bounce, value: bounce)
                        .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
                        .scaleEffect(isSelected ? 1.1 : (isHovered ? 1.05 : 1.0))
                        .rotationEffect(.degrees(isSelected ? 360 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                    
                    // Holographic effect on selection
                    if isSelected {
                        Image(systemName: tab.icon)
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                            .blur(radius: 8)
                            .opacity(0.5)
                            .scaleEffect(1.3)
                            .matchedGeometryEffect(id: "hologram", in: namespace)
                    }
                }
                
                // Title
                Text(tab.title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.5))
                    .scaleEffect(isSelected ? 1.05 : 1.0)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Futuristic Main Container

struct FuturisticMainView: View {
    @State private var selectedTab = 0
    @State private var showParticles = false
    
    var body: some View {
        ZStack {
            // Dynamic background
            ZStack {
                Color.deepSpace
                    .ignoresSafeArea()
                
                // Animated gradient background
                LinearGradient(
                    colors: [
                        Color.neonCyan.opacity(0.05),
                        Color.electricBlue.opacity(0.05),
                        Color.neonPurple.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .hueRotation(.degrees(showParticles ? 60 : 0))
                .animation(.linear(duration: 10).repeatForever(autoreverses: true), value: showParticles)
                
                // Particle system background
                ParticleSystemView()
                    .opacity(0.3)
                    .ignoresSafeArea()
            }
            
            // Content
            VStack(spacing: 0) {
                // Main content area
                TabView(selection: $selectedTab) {
                    FuturisticDashboardView()
                        .tag(0)
                    
                    TradingView()
                        .tag(1)
                    
                    AILabView()
                        .tag(2)
                    
                    SocialTradingView()
                        .tag(3)
                    
                    MoreTabView()
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom tab bar
                FuturisticTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            showParticles = true
        }
    }
}

// MARK: - Particle System Background

struct FuturisticParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
    var blur: CGFloat
}

struct ParticleSystemView: View {
    @State private var particles: [FuturisticParticle] = []
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .blur(radius: particle.blur)
                }
            }
            .onAppear {
                // Initialize particles
                for _ in 0..<50 {
                    particles.append(
                        FuturisticParticle(
                            position: CGPoint(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            ),
                            velocity: CGPoint(
                                x: CGFloat.random(in: -0.5...0.5),
                                y: CGFloat.random(in: -0.5...0.5)
                            ),
                            color: [FuturisticColors.neonCyan, FuturisticColors.electricBlue, FuturisticColors.neonPurple].randomElement()!,
                            size: CGFloat.random(in: 1...3),
                            opacity: 0.6,
                            blur: 1
                        )
                    )
                }
            }
            .onReceive(timer) { _ in
                updateParticles(in: geometry.size)
            }
        }
    }
    
    private func updateParticles(in size: CGSize) {
        for index in particles.indices {
            var particle = particles[index]
            
            // Update position
            particle.position.x += particle.velocity.x
            particle.position.y += particle.velocity.y
            
            // Wrap around edges
            if particle.position.x < 0 {
                particle.position.x = size.width
            } else if particle.position.x > size.width {
                particle.position.x = 0
            }
            
            if particle.position.y < 0 {
                particle.position.y = size.height
            } else if particle.position.y > size.height {
                particle.position.y = 0
            }
            
            // Update opacity for twinkling effect
            particle.opacity = Double.random(in: 0.3...0.8)
            
            particles[index] = particle
        }
    }
}


// MARK: - Placeholder Views

struct AILabView: View {
    var body: some View {
        ZStack {
            Color.deepSpace.ignoresSafeArea()
            
            VStack {
                Text("AI Lab")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.neonPurple)
                    .neonGlow(color: .neonPurple)
                
                PlasmaOrb()
            }
        }
    }
}

struct SocialTradingView: View {
    var body: some View {
        ZStack {
            Color.deepSpace.ignoresSafeArea()
            
            VStack {
                Text("Social Trading")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.plasmaGreen)
                    .neonGlow(color: .plasmaGreen)
            }
        }
    }
}

struct MoreTabView: View {
    var body: some View {
        ZStack {
            Color.deepSpace.ignoresSafeArea()
            
            VStack {
                Text("More")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.neonPink)
                    .neonGlow(color: .neonPink)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FuturisticMainView()
}