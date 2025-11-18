//
//  ConceptView.swift
//  Pipflow
//
//  Simple UI Concept Comparison
//

import SwiftUI

struct ConceptView: View {
    @State private var showQuantum = false
    @State private var particleAnimation = false
    @State private var energyFlow = false
    @State private var selectedDimension = 0
    
    var body: some View {
        ZStack {
            if showQuantum {
                // REVOLUTIONARY QUANTUM INTERFACE
                quantumInterface
            } else {
                // CURRENT TRADITIONAL INTERFACE
                traditionalInterface
            }
            
            // Toggle button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                            showQuantum.toggle()
                        }
                    }) {
                        Text(showQuantum ? "SHOW OLD UI" : "SHOW NEW UI")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(showQuantum ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 60)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            particleAnimation = true
            energyFlow = true
        }
    }
    
    var quantumInterface: some View {
        ZStack {
            // Deep space background
            RadialGradient(
                colors: [
                    Color(red: 0, green: 0.02, blue: 0.06),
                    Color(red: 0, green: 0.01, blue: 0.03),
                    Color.black
                ],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            // Floating particles
            ForEach(0..<35, id: \.self) { index in
                Circle()
                    .fill(quantumColors[selectedDimension].opacity(0.6))
                    .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 100...800)
                    )
                    .scaleEffect(particleAnimation ? 2.0 : 0.3)
                    .opacity(particleAnimation ? 0.8 : 0.2)
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.05),
                        value: particleAnimation
                    )
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Central Quantum Portal
                ZStack {
                    // Energy rings
                    ForEach(0..<3, id: \.self) { ring in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        quantumColors[selectedDimension],
                                        quantumColors[selectedDimension].opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: CGFloat(4 - ring)
                            )
                            .frame(width: CGFloat(300 + ring * 40), height: CGFloat(300 + ring * 40))
                            .rotationEffect(.degrees(energyFlow ? 360 + Double(ring * 120) : Double(ring * 120)))
                            .animation(
                                .linear(duration: Double(15 + ring * 5))
                                .repeatForever(autoreverses: false),
                                value: energyFlow
                            )
                            .opacity(0.4 - Double(ring) * 0.1)
                    }
                    
                    // Central display
                    VStack(spacing: 20) {
                        Text("NEURAL CORE")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(quantumColors[selectedDimension])
                            .opacity(0.9)
                        
                        Text("$847,295")
                            .font(.system(size: 52, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("Portfolio Value")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(quantumColors[selectedDimension])
                                .frame(width: 8, height: 8)
                                .scaleEffect(energyFlow ? 1.5 : 1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: energyFlow)
                            
                            Text("NEURAL ACTIVE")
                                .font(.caption)
                                .foregroundColor(quantumColors[selectedDimension])
                        }
                    }
                }
                .frame(height: 400)
                
                Spacer()
                
                // Quantum Tabs
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedDimension = index
                            }
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            selectedDimension == index ?
                                            RadialGradient(
                                                colors: [
                                                    quantumColors[index].opacity(0.6),
                                                    quantumColors[index].opacity(0.2),
                                                    Color.clear
                                                ],
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 30
                                            ) :
                                            RadialGradient(
                                                colors: [Color.clear, Color.clear],
                                                center: .center,
                                                startRadius: 0,
                                                endRadius: 30
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(
                                                    selectedDimension == index ? 
                                                    quantumColors[index] : 
                                                    Color.white.opacity(0.15),
                                                    lineWidth: selectedDimension == index ? 3 : 1
                                                )
                                        )
                                        .frame(width: 66, height: 66)
                                    
                                    Image(systemName: quantumIcons[index])
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(
                                            selectedDimension == index ? 
                                            quantumColors[index] : 
                                            .white.opacity(0.4)
                                        )
                                        .scaleEffect(selectedDimension == index ? 1.2 : 1.0)
                                }
                                
                                Text(quantumNames[index])
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(
                                        selectedDimension == index ? 
                                        quantumColors[index] : 
                                        .white.opacity(0.4)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 60)
            }
        }
    }
    
    var traditionalInterface: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Balance card
                VStack(spacing: 16) {
                    Text("Total Balance")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("$0.00")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                )
                .padding(.horizontal)
                
                // Metric cards
                HStack(spacing: 16) {
                    VStack {
                        Text("Today's P&L")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("+$250.00")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                    )
                    
                    VStack {
                        Text("Win Rate")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("68%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Bottom tab bar
                HStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        VStack(spacing: 4) {
                            Image(systemName: traditionIcons[index])
                                .font(.system(size: 24))
                                .foregroundColor(index == 0 ? .blue : .gray)
                            
                            Text(traditionNames[index])
                                .font(.caption)
                                .foregroundColor(index == 0 ? .blue : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                .background(Color.gray.opacity(0.1))
            }
        }
    }
    
    // MARK: - Data
    
    private let quantumColors = [
        Color(red: 0, green: 1, blue: 0.67),  // Neural - Neon Green
        Color(red: 1, green: 0, blue: 0.6),   // Trading - Neon Pink  
        Color(red: 0, green: 0.6, blue: 1),   // AI - Electric Blue
        Color(red: 1, green: 0.67, blue: 0),  // Social - Neon Orange
        Color(red: 0.67, green: 0, blue: 1)   // Portal - Neon Purple
    ]
    
    private let quantumNames = ["NEURAL", "TRADE", "AI", "SOCIAL", "PORTAL"]
    private let quantumIcons = ["brain.head.profile", "chart.xyaxis.line", "cpu", "person.2.wave.2", "atom"]
    
    private let traditionNames = ["Dashboard", "Market", "Trade", "Social", "More"]
    private let traditionIcons = ["chart.line.uptrend.xyaxis", "chart.bar.xaxis", "arrow.up.arrow.down", "person.3.fill", "ellipsis"]
}

#Preview {
    ConceptView()
}