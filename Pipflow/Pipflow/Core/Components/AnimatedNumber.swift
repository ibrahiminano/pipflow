//
//  AnimatedNumber.swift
//  Pipflow
//
//  Futuristic Animated Number Component
//

import SwiftUI

struct AnimatedNumberComponent: View {
    let value: Double
    let format: String
    
    @State private var animatedValue: Double = 0
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text(String(format: format, displayValue))
            .onAppear {
                startAnimation()
            }
            .onChange(of: value) { oldValue, newValue in
                startAnimation()
            }
    }
    
    private func startAnimation() {
        withAnimation(.easeOut(duration: 2.0)) {
            animatedValue = value
        }
        
        // Smooth number counting animation
        let duration: TimeInterval = 2.0
        let steps = 60
        let stepDuration = duration / Double(steps)
        let increment = (value - displayValue) / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                displayValue = displayValue + increment
                if i == steps {
                    displayValue = value // Ensure final value is exact
                }
            }
        }
    }
}

#Preview("Animated Number") {
    VStack {
        AnimatedNumberComponent(value: 158749.32, format: "%.2f")
            .font(.largeTitle)
            .foregroundColor(.white)
            .background(Color.black)
    }
}