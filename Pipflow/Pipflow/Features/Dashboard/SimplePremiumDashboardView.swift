//
//  SimplePremiumDashboardView.swift
//  Pipflow
//
//  Premium Dashboard without particle effects
//

import SwiftUI

struct SimplePremiumDashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTimeframe = "1D"
    @State private var showNewTrade = false
    @State private var animateBalance = false
    
    let timeframes = ["1M", "5M", "15M", "1H", "4H", "1D"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Background
                LinearGradient(
                    colors: [
                        Color(hex: "0F0F0F"),
                        Color(hex: "1A1A2E")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        customHeader
                        
                        // Balance Card
                        balanceCard
                        
                        // Stats Row
                        statsRow
                        
                        // Quick Actions
                        quickActions
                        
                        // Positions
                        positionsSection
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showNewTrade) {
            NewTradeView(
                symbol: "EUR/USD",
                side: .buy,
                onComplete: {}
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateBalance = true
            }
        }
    }
    
    var customHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Alex Thompson")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {}) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: {}) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.top, 60)
    }
    
    var balanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Portfolio Value")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("158,749.32")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                
                Text("+$2,847.50")
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Text("(+1.83%)")
                    .font(.caption)
                    .opacity(0.8)
            }
            .foregroundColor(Color(hex: "00F5A0"))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    var statsRow: some View {
        HStack(spacing: 16) {
            PremiumStatCard(
                title: "Win Rate",
                value: "73.5%",
                icon: "chart.line.uptrend.xyaxis",
                color: Color(hex: "00F5A0")
            )
            
            PremiumStatCard(
                title: "Today's P&L",
                value: "+$2,847",
                icon: "dollarsign.circle",
                color: Color(hex: "3A86FF")
            )
        }
    }
    
    var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                DashboardActionButton(
                    icon: "arrow.up.arrow.down",
                    title: "Trade",
                    color: Color(hex: "00F5A0"),
                    action: { showNewTrade = true }
                )
                
                DashboardActionButton(
                    icon: "doc.text.magnifyingglass",
                    title: "Signals",
                    color: Color(hex: "3A86FF"),
                    action: {}
                )
                
                DashboardActionButton(
                    icon: "person.2.fill",
                    title: "Copy",
                    color: Color(hex: "FF006E"),
                    action: {}
                )
                
                DashboardActionButton(
                    icon: "graduationcap.fill",
                    title: "Learn",
                    color: Color(hex: "8338EC"),
                    action: {}
                )
            }
        }
    }
    
    var positionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Positions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            if viewModel.activePositions.isEmpty {
                Text("No open positions")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
            }
        }
    }
}

struct PremiumStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct DashboardActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }
}