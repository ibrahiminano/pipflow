// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pipflow",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PipflowKit",
            targets: ["PipflowKit"]
        ),
    ],
    dependencies: [
        // Supabase for auth and database
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
        
        // SwiftLint for code quality
        .package(url: "https://github.com/realm/SwiftLint", from: "0.54.0"),
        
        // Keychain wrapper for secure storage
        .package(url: "https://github.com/evgenyneu/keychain-swift", from: "20.0.0"),
        
        // Charts library for trading charts
        .package(url: "https://github.com/danielgindi/Charts", from: "5.0.0"),
        
        // TradingView Lightweight Charts iOS
        .package(url: "https://github.com/tradingview/LightweightChartsIOS", from: "4.0.0"),
        
        // Lottie for animations
        .package(url: "https://github.com/airbnb/lottie-ios", from: "4.3.0"),
        
        // SwiftUI components
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "2.2.0")
        
        // OpenAI SDK for ChatGPT integration - TODO: Add when needed
        // .package(url: "https://github.com/MacPaw/OpenAI.git", branch: "main")
    ],
    targets: [
        .target(
            name: "PipflowKit",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "KeychainSwift", package: "keychain-swift"),
                .product(name: "DGCharts", package: "Charts"),
                .product(name: "LightweightCharts", package: "LightweightChartsIOS"),
                .product(name: "Lottie", package: "lottie-ios"),
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI")
                // .product(name: "OpenAI", package: "OpenAI")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PipflowKitTests",
            dependencies: ["PipflowKit"],
            path: "Tests"
        ),
    ]
)