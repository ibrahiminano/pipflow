//
//  FuturisticTheme.swift
//  Pipflow
//
//  Revolutionary Design System for Next-Gen Trading
//

import SwiftUI

// MARK: - Futuristic Color Palette
struct FuturisticColors {
    static let neonCyan = Color(hex: "00FFFF")
    static let neonPurple = Color(hex: "BD00FF")
    static let neonPink = Color(hex: "FF00F7")
    static let electricBlue = Color(hex: "0080FF")
    static let plasmaGreen = Color(hex: "00FF88")
    static let holographicSilver = Color(hex: "E8E8F0")
    static let deepSpace = Color(hex: "0A0A0F")
    static let darkMatter = Color(hex: "12121A")
    static let cosmicGray = Color(hex: "1C1C28")
    static let stellarWhite = Color(hex: "FAFAFA")
}

extension Color {
    static let neonCyan = FuturisticColors.neonCyan
    static let neonPurple = FuturisticColors.neonPurple
    static let neonPink = FuturisticColors.neonPink
    static let electricBlue = FuturisticColors.electricBlue
    static let plasmaGreen = FuturisticColors.plasmaGreen
    static let holographicSilver = FuturisticColors.holographicSilver
    static let deepSpace = FuturisticColors.deepSpace
    static let darkMatter = FuturisticColors.darkMatter
    static let cosmicGray = FuturisticColors.cosmicGray
    static let stellarWhite = FuturisticColors.stellarWhite
    
    // Gradient Colors
    static let quantumGradient = LinearGradient(
        colors: [neonCyan, electricBlue, neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let plasmaGradient = LinearGradient(
        colors: [plasmaGreen, neonCyan, electricBlue],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let cosmicGradient = LinearGradient(
        colors: [deepSpace, darkMatter, cosmicGray],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let holographicGradient = LinearGradient(
        colors: [
            neonCyan.opacity(0.3),
            neonPurple.opacity(0.3),
            neonPink.opacity(0.3),
            electricBlue.opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Futuristic Visual Effects
struct FuturisticEffects {
    // Holographic shimmer effect
    static func holographicOverlay() -> some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.0),
                Color.white.opacity(0.1),
                Color.neonCyan.opacity(0.2),
                Color.white.opacity(0.1),
                Color.white.opacity(0.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .rotationEffect(.degrees(45))
    }
    
    // Neon glow modifier
    struct NeonGlow: ViewModifier {
        let color: Color
        let radius: CGFloat
        
        func body(content: Content) -> some View {
            content
                .shadow(color: color.opacity(0.3), radius: radius * 0.5)
                .shadow(color: color.opacity(0.2), radius: radius * 0.75)
        }
    }
    
    // Circuit board pattern
    static func circuitPattern() -> some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let gridSize: CGFloat = 30
                
                // Horizontal lines
                for y in stride(from: 0, through: height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                
                // Vertical lines with random connections
                for x in stride(from: 0, through: width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Color.neonCyan.opacity(0.1), Color.electricBlue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.5
            )
        }
    }
}

// MARK: - Interactive Components

struct HolographicCard<Content: View>: View {
    let content: Content
    @State private var rotation: Double = 0
    @State private var isPressed = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.neonCyan.opacity(0.15),
                                            Color.electricBlue.opacity(0.1),
                                            Color.neonPurple.opacity(0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                }
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
            }
    }
}

// MARK: - Quantum Button
struct QuantumButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    @State private var isPressed = false
    @State private var particleAnimation = false
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
                particleAnimation.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            action()
        }) {
            ZStack {
                // Background with animated gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isPressed ? 
                                [Color.neonPurple, Color.neonCyan] : 
                                [Color.neonCyan, Color.electricBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                // Particle effect on tap
                if particleAnimation {
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                            .offset(x: particleAnimation ? CGFloat.random(in: -40...40) : 0,
                                   y: particleAnimation ? CGFloat.random(in: -40...40) : 0)
                            .opacity(particleAnimation ? 0 : 1)
                            .animation(
                                .easeOut(duration: 0.6)
                                .delay(Double(index) * 0.05),
                                value: particleAnimation
                            )
                    }
                }
                
                // Content
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
            }
        }
        .frame(height: 56)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Neural Network Background
struct NeuralNetworkBackground: View {
    @State private var nodes: [NodeData] = []
    @State private var connections: [ConnectionData] = []
    let nodeCount = 20
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.deepSpace
                    .ignoresSafeArea()
                
                // Neural network visualization
                Canvas { context, size in
                    // Draw connections
                    for connection in connections {
                        if let startNode = nodes.first(where: { $0.id == connection.from }),
                           let endNode = nodes.first(where: { $0.id == connection.to }) {
                            
                            var path = Path()
                            path.move(to: startNode.position)
                            path.addLine(to: endNode.position)
                            
                            context.stroke(
                                path,
                                with: .linearGradient(
                                    Gradient(colors: [
                                        Color.neonCyan.opacity(0.3),
                                        Color.electricBlue.opacity(0.1)
                                    ]),
                                    startPoint: startNode.position,
                                    endPoint: endNode.position
                                ),
                                lineWidth: 0.5
                            )
                        }
                    }
                    
                    // Draw nodes
                    for node in nodes {
                        context.fill(
                            Circle().path(in: CGRect(
                                x: node.position.x - 3,
                                y: node.position.y - 3,
                                width: 6,
                                height: 6
                            )),
                            with: .color(Color.neonCyan.opacity(0.8))
                        )
                        
                        // Glow effect
                        context.fill(
                            Circle().path(in: CGRect(
                                x: node.position.x - 10,
                                y: node.position.y - 10,
                                width: 20,
                                height: 20
                            )),
                            with: .radialGradient(
                                Gradient(colors: [
                                    Color.neonCyan.opacity(0.3),
                                    Color.clear
                                ]),
                                center: node.position,
                                startRadius: 0,
                                endRadius: 10
                            )
                        )
                    }
                }
                .onAppear {
                    generateNetwork(size: geometry.size)
                }
            }
        }
    }
    
    private func generateNetwork(size: CGSize) {
        // Generate random nodes
        nodes = (0..<nodeCount).map { index in
            NodeData(
                id: index,
                position: CGPoint(
                    x: CGFloat.random(in: 50...(size.width - 50)),
                    y: CGFloat.random(in: 50...(size.height - 50))
                )
            )
        }
        
        // Generate connections
        connections = []
        for i in 0..<nodeCount {
            let connectionCount = Int.random(in: 1...3)
            for _ in 0..<connectionCount {
                let targetIndex = Int.random(in: 0..<nodeCount)
                if targetIndex != i {
                    connections.append(ConnectionData(from: i, to: targetIndex))
                }
            }
        }
    }
}

// MARK: - Data Structures
struct NodeData {
    let id: Int
    let position: CGPoint
}

struct ConnectionData {
    let from: Int
    let to: Int
}

// MARK: - Plasma Orb Loading Indicator
struct PlasmaOrb: View {
    @State private var rotation = 0.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.neonCyan.opacity(0.4),
                            Color.electricBlue.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(scale)
            
            // Inner orb
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.neonCyan, Color.electricBlue, Color.neonPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                )
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale * 0.8)
            
            // Energy particles
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                    .offset(x: 25)
                    .rotationEffect(.degrees(Double(index) * 60 + rotation))
                    .scaleEffect(scale)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                scale = 1.2
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func neonGlow(color: Color = .neonCyan, radius: CGFloat = 10) -> some View {
        self.modifier(FuturisticEffects.NeonGlow(color: color, radius: radius))
    }
    
    func holographicShimmer() -> some View {
        self.overlay(FuturisticEffects.holographicOverlay())
    }
}