//
//  AccountManagementView.swift
//  Pipflow
//
//  User account management and profile settings
//

import SwiftUI
import PhotosUI

struct AccountManagementView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var userProfileService = UserProfileService.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var bio: String = ""
    @State private var location: String = ""
    @State private var tradingExperience: TradingExperience
    @State private var preferredMarkets: Set<Market> = []
    @State private var monthlyTarget: Double = 0
    
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    
    @State private var showChangePasswordAlert = false
    @State private var showVerifyEmailAlert = false
    @State private var isLoading = false
    
    init() {
        let user = AuthService.shared.currentUser
        _name = State(initialValue: user?.name ?? "")
        _email = State(initialValue: user?.email ?? "")
        _bio = State(initialValue: user?.bio ?? "")
        _location = State(initialValue: "")
        _tradingExperience = State(initialValue: .beginner)
        _preferredMarkets = State(initialValue: Set<Market>())
        _monthlyTarget = State(initialValue: 0)
    }
    
    var body: some View {
        NavigationView {
            Form {
                profilePictureSection
                personalInfoSection
                tradingPreferencesSection
                targetSection
                actionButtons
            }
            .navigationTitle("Account Management")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isLoading)
            .overlay(
                isLoading ? ProgressView() : nil
            )
        }
    }
    
    private var profilePictureSection: some View {
        Section {
            HStack {
                Spacer()
                
                VStack {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.Theme.secondaryText, lineWidth: 2)
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.Theme.gradientStart, Color.Theme.gradientEnd],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Text(initials)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    PhotosPicker(
                        selection: $selectedImage,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Change Photo")
                            .font(.caption)
                            .foregroundColor(Color.Theme.accent)
                    }
                    .onChange(of: selectedImage) { newItem in
                        Task {
                            if let newItem = newItem,
                               let data = try? await newItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                await MainActor.run {
                                    profileImage = image
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var personalInfoSection: some View {
        Section("Personal Information") {
            TextField("Name", text: $name)
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            TextField("Bio", text: $bio, axis: .vertical)
                .lineLimit(3...6)
            TextField("Location", text: $location)
        }
    }
    
    private var tradingPreferencesSection: some View {
        Section("Trading Preferences") {
            Picker("Experience Level", selection: $tradingExperience) {
                ForEach(TradingExperience.allCases, id: \.self) { experience in
                    Text(experience.rawValue.capitalized).tag(experience)
                }
            }
            
            // Preferred Markets
            Text("Preferred Markets")
                .font(.subheadline)
                .foregroundColor(Color.Theme.secondaryText)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(Market.allCases, id: \.self) { market in
                    Button(action: {
                        if preferredMarkets.contains(market) {
                            preferredMarkets.remove(market)
                        } else {
                            preferredMarkets.insert(market)
                        }
                    }) {
                        Text(market.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(preferredMarkets.contains(market) ? Color.Theme.accent : Color.Theme.cardBackground)
                            .foregroundColor(preferredMarkets.contains(market) ? .white : Color.Theme.text)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    private var targetSection: some View {
        Section {
            HStack {
                Text("$")
                TextField("0", value: $monthlyTarget, format: .number)
                    .keyboardType(.decimalPad)
            }
        } header: {
            Text("Monthly Target")
        } footer: {
            Text("Your monthly profit target in USD")
        }
    }
    
    private var actionButtons: some View {
        Section {
            Button("Change Password") {
                showChangePasswordAlert = true
            }
            .foregroundColor(Color.Theme.accent)
            
            Button("Verify Email") {
                showVerifyEmailAlert = true
            }
            .foregroundColor(Color.Theme.accent)
            
            Button("Save Changes") {
                saveChanges()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.Theme.accent)
            .cornerRadius(12)
        }
    }
    
    private var initials: String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
    
    private func saveChanges() {
        isLoading = true
        
        Task {
            do {
                // Update user profile
                var updatedUser = authService.currentUser ?? User(
                    id: UUID(),
                    name: name,
                    email: email,
                    bio: bio,
                    totalProfit: 0.0,
                    winRate: 0.0,
                    totalTrades: 0,
                    followers: 0,
                    following: 0,
                    avatarURL: nil,
                    riskScore: 5,
                    isVerified: false,
                    isPro: false
                )
                
                // Note: User model properties are immutable and don't include location, tradingExperience, etc.
                // In a real implementation, these would be saved to a separate UserProfile model
                
                // Upload profile image if changed
                if let profileImage = profileImage {
                    // In a real app, upload to storage and get URL
                    // updatedUser.avatarUrl = uploadedImageUrl
                }
                
                // Save to backend using ProfileUpdates
                let profileUpdates = ProfileUpdates(
                    displayName: name,
                    bio: bio.isEmpty ? nil : bio,
                    location: location.isEmpty ? nil : location,
                    website: nil,
                    avatarURL: nil,
                    coverImageURL: nil,
                    tradingStyle: nil,
                    riskLevel: nil,
                    preferredMarkets: preferredMarkets.map { $0.rawValue },
                    socialLinks: nil
                )
                try await userProfileService.updateProfile(profileUpdates)
                authService.currentUser = updatedUser
                
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            } catch {
                isLoading = false
                // Handle error
            }
        }
    }
    
    private func changePassword() {
        Task {
            try await authService.resetPassword(email: email)
        }
    }
    
    private func resendVerificationEmail() {
        Task {
            try await authService.resendVerificationEmail()
        }
    }
}

struct MarketToggleButton: View {
    let market: Market
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: market.icon)
                    .font(.caption)
                Text(market.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.Theme.accent : Color.Theme.cardBackground)
            .foregroundColor(isSelected ? .white : Color.Theme.text)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.Theme.secondaryText, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Market Extension
extension Market {
    var icon: String {
        switch self {
        case .forex: return "dollarsign.circle"
        case .crypto: return "bitcoinsign.circle"
        case .stocks: return "chart.bar"
        case .indices: return "chart.line.uptrend.xyaxis"
        case .commodities: return "cube"
        }
    }
}

#Preview {
    AccountManagementView()
}