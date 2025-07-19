//
//  AppDelegate.swift
//  Pipflow
//
//  Created by Claude on 18/07/2025.
//

import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure app appearance
        configureAppearance()
        
        // Initialize services
        initializeServices()
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.Theme.background)
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance if needed
        UITabBar.appearance().backgroundColor = UIColor(Color.Theme.background)
    }
    
    private func initializeServices() {
        // Initialize crash reporting
        // Initialize analytics
        // Initialize push notifications
        // Initialize deep linking
    }
}