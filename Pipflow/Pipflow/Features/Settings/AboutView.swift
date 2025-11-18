//
//  AboutView.swift
//  Pipflow
//
//  About page with app information and links
//

import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationView {
            List {
                // App Info Section
                Section {
                    VStack(spacing: 16) {
                        // App Icon
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                        
                        // App Name
                        Text("Pipflow AI")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Version
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                        
                        // Tagline
                        Text("Empowering traders with AI-driven insights")
                            .font(.subheadline)
                            .foregroundColor(Color.Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                // Links Section
                Section("Links") {
                    LinkRow(
                        title: "Website",
                        icon: "globe",
                        url: "https://pipflow.ai"
                    )
                    
                    LinkRow(
                        title: "Support",
                        icon: "questionmark.circle",
                        url: "https://pipflow.ai/support"
                    )
                    
                    LinkRow(
                        title: "Privacy Policy",
                        icon: "hand.raised",
                        url: "https://pipflow.ai/privacy"
                    )
                    
                    LinkRow(
                        title: "Terms of Service",
                        icon: "doc.text",
                        url: "https://pipflow.ai/terms"
                    )
                }
                
                // Social Section
                Section("Connect") {
                    LinkRow(
                        title: "Twitter",
                        icon: "at",
                        url: "https://twitter.com/pipflowai"
                    )
                    
                    LinkRow(
                        title: "Discord",
                        icon: "bubble.left.and.bubble.right",
                        url: "https://discord.gg/pipflow"
                    )
                    
                    LinkRow(
                        title: "YouTube",
                        icon: "play.rectangle",
                        url: "https://youtube.com/@pipflowai"
                    )
                    
                    Button(action: shareApp) {
                        Label("Share Pipflow", systemImage: "square.and.arrow.up")
                            .foregroundColor(Color.Theme.accent)
                    }
                }
                
                // Credits Section
                Section("Credits") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Built with ❤️ by the Pipflow Team")
                            .font(.subheadline)
                        
                        Text("Special thanks to our community of traders who inspire us to build better tools every day.")
                            .font(.caption)
                            .foregroundColor(Color.Theme.secondaryText)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Technologies")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 12) {
                                TechBadge(name: "SwiftUI")
                                TechBadge(name: "MetaAPI")
                                TechBadge(name: "GPT-4")
                            }
                            
                            HStack(spacing: 12) {
                                TechBadge(name: "Supabase")
                                TechBadge(name: "TradingView")
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Legal Section
                Section {
                    Text("© 2025 Pipflow AI. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(Color.Theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func shareApp() {
        let text = "Check out Pipflow AI - The smart trading companion powered by AI!\n\nhttps://pipflow.ai"
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct LinkRow: View {
    let title: String
    let icon: String
    let url: String
    
    var body: some View {
        Button(action: openURL) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundColor(Color.Theme.text)
                Spacer()
                Image(systemName: "arrow.up.forward.square")
                    .font(.caption)
                    .foregroundColor(Color.Theme.secondaryText)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openURL() {
        if let url = URL(string: url) {
            UIApplication.shared.open(url)
        }
    }
}

struct TechBadge: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.Theme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.Theme.divider, lineWidth: 1)
            )
    }
}

#Preview {
    AboutView()
}