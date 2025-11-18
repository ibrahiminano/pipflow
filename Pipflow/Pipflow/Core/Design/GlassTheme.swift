//
//  GlassTheme.swift
//  Pipflow
//
//  Premium glassmorphic design system for futuristic AI trading
//

import SwiftUI

struct GlassTheme {
    // MARK: - Glass Effects
    
    static func glassBackground(opacity: Double = 0.1) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
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
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    static func premiumGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "7F5AF0"),
                Color(hex: "2D9CDB"),
                Color(hex: "27AE60")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func darkGradientBackground() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "0F0F0F"),
                Color(hex: "1A1A2E"),
                Color(hex: "16213E")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static func accentGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "FF006E"),
                Color(hex: "8338EC"),
                Color(hex: "3A86FF")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static func profitGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "00F5A0"),
                Color(hex: "00D9FF")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static func lossGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "FF4757"),
                Color(hex: "FF6B81")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Animation Effects
    
    static func shimmerEffect() -> some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0),
                Color.white.opacity(0.3),
                Color.white.opacity(0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Neon Effects
    
    static func neonGlow(color: Color, intensity: Double = 1.0) -> some View {
        ZStack {
            color
                .blur(radius: 20 * intensity)
                .opacity(0.5)
            color
                .blur(radius: 10 * intensity)
                .opacity(0.7)
            color
        }
    }
}

// MARK: - Premium Components

struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(GlassTheme.glassBackground())
    }
}

struct GradientText: View {
    let text: String
    let gradient: LinearGradient
    let font: Font
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }
}

// AnimatedNumberComponent is defined in AnimatedNumber.swift

struct PulsingView<Content: View>: View {
    @State private var isPulsing = false
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct ShimmeringView<Content: View>: View {
    @State private var isShimmering = false
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .overlay(
                GeometryReader { geometry in
                    GlassTheme.shimmerEffect()
                        .frame(width: geometry.size.width * 3)
                        .offset(x: isShimmering ? geometry.size.width * 2 : -geometry.size.width * 2)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    isShimmering = true
                }
            }
    }
}

// MARK: - Particle Effect

struct ParticleEmitterView: View {
    @State private var particles: [GlassParticle] = []
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .blur(radius: particle.blur)
                }
            }
            .onReceive(timer) { _ in
                // Add new particle
                let newParticle = GlassParticle(
                    position: CGPoint(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: geometry.size.height + 20
                    ),
                    velocity: CGPoint(
                        x: CGFloat.random(in: -20...20),
                        y: CGFloat.random(in: -100...(-50))
                    ),
                    color: [Color.blue, Color.purple, Color.cyan].randomElement()!,
                    size: CGFloat.random(in: 2...6),
                    opacity: Double.random(in: 0.3...0.7),
                    blur: CGFloat.random(in: 0...2)
                )
                particles.append(newParticle)
                
                // Update existing particles
                particles = particles.compactMap { particle in
                    var updatedParticle = particle
                    updatedParticle.position.x += updatedParticle.velocity.x * 0.1
                    updatedParticle.position.y += updatedParticle.velocity.y * 0.1
                    updatedParticle.opacity -= 0.01
                    
                    return updatedParticle.opacity > 0 ? updatedParticle : nil
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct GlassParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
    var blur: CGFloat
}

// MARK: - Premium Button Styles

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Group {
                    if configuration.isPressed {
                        GlassTheme.glassBackground(opacity: 0.3)
                    } else {
                        GlassTheme.glassBackground(opacity: 0.15)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct GradientButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(gradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}