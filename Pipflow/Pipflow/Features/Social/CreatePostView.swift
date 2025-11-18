//
//  CreatePostView.swift
//  Pipflow
//
//  Create new social post view
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var socialService = EnhancedSocialTradingService.shared
    
    @State private var postText = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var includeTrade = false
    @State private var tradeSymbol = "EUR/USD"
    @State private var tradeAction = "BUY"
    @State private var entryPrice = ""
    @State private var stopLoss = ""
    @State private var takeProfit = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0A0A0F")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Post Content
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What's on your mind?")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $postText)
                                .frame(minHeight: 150)
                                .padding(8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.03))
                        )
                        
                        // Attachments
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Attachments")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: { showImagePicker = true }) {
                                    Label("Add Photo", systemImage: "photo")
                                        .font(.caption)
                                        .foregroundColor(.neonCyan)
                                }
                            }
                            
                            if !loadedImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(loadedImages.enumerated()), id: \.offset) { index, image in
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(12)
                                                .overlay(
                                                    Button(action: {
                                                        loadedImages.remove(at: index)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.white)
                                                            .background(Color.black.opacity(0.5))
                                                            .clipShape(Circle())
                                                    }
                                                    .padding(4),
                                                    alignment: .topTrailing
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.03))
                        )
                        
                        // Trade Details (Optional)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Include Trade Details")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $includeTrade)
                                    .toggleStyle(SwitchToggleStyle(tint: .neonCyan))
                            }
                            
                            if includeTrade {
                                VStack(spacing: 16) {
                                    // Symbol and Action
                                    HStack(spacing: 12) {
                                        TextField("Symbol", text: $tradeSymbol)
                                            .textFieldStyle(ModernTextFieldStyle())
                                        
                                        Picker("Action", selection: $tradeAction) {
                                            Text("BUY").tag("BUY")
                                            Text("SELL").tag("SELL")
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                    
                                    // Price Levels
                                    HStack(spacing: 12) {
                                        TextField("Entry", text: $entryPrice)
                                            .textFieldStyle(ModernTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                        
                                        TextField("SL", text: $stopLoss)
                                            .textFieldStyle(ModernTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                        
                                        TextField("TP", text: $takeProfit)
                                            .textFieldStyle(ModernTextFieldStyle())
                                            .keyboardType(.decimalPad)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.03))
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.neonCyan)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createPost) {
                        Text("Post")
                            .fontWeight(.semibold)
                            .foregroundColor(postText.isEmpty ? .gray : .neonCyan)
                    }
                    .disabled(postText.isEmpty)
                }
            }
        }
        .photosPicker(isPresented: $showImagePicker,
                     selection: $selectedImages,
                     maxSelectionCount: 4,
                     matching: .images)
        .onChange(of: selectedImages) { _, items in
            Task {
                loadedImages.removeAll()
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        loadedImages.append(image)
                    }
                }
            }
        }
    }
    
    private func createPost() {
        // Create post logic here
        dismiss()
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}

struct PostCommentsView: View {
    let post: SocialPost
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0A0A0F")
                    .ignoresSafeArea()
                
                VStack {
                    // Comments list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(0..<10) { index in
                                CommentRow(
                                    authorName: "User\(index + 100)",
                                    comment: "This is a sample comment #\(index + 1)",
                                    timeAgo: "\(index + 1)h ago",
                                    likes: Int.random(in: 0...50)
                                )
                            }
                        }
                        .padding()
                    }
                    
                    // Comment input
                    HStack(spacing: 12) {
                        TextField("Add a comment...", text: $commentText)
                            .textFieldStyle(ModernTextFieldStyle())
                        
                        Button(action: {
                            // Send comment
                            commentText = ""
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(commentText.isEmpty ? .gray : .neonCyan)
                        }
                        .disabled(commentText.isEmpty)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.neonCyan)
                }
            }
        }
    }
}

struct CommentRow: View {
    let authorName: String
    let comment: String
    let timeAgo: String
    let likes: Int
    @State private var isLiked = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.neonCyan, .electricBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Text(authorName.prefix(1))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("• \(timeAgo)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                }
                
                Text(comment)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(spacing: 16) {
                    Button(action: { isLiked.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundColor(isLiked ? .neonPink : .white.opacity(0.5))
                            
                            Text("\(likes + (isLiked ? 1 : 0))")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Button(action: {}) {
                        Text("Reply")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}