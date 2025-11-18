//
//  NotificationService.swift
//  Pipflow
//
//  Notification management service with local and push support
//

import Foundation
import UserNotifications
import Combine

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var notifications: [PipflowNotification] = []
    @Published var unreadCount: Int = 0
    @Published var preferences = PipflowNotificationPreferences()
    @Published var priceAlerts: [PriceAlert] = []
    @Published var isAuthorized = false
    
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        setupNotifications()
        loadMockData()
    }
    
    private func setupNotifications() {
        notificationCenter.delegate = self
        checkAuthorizationStatus()
        
        // Observe notification count changes
        $notifications
            .map { notifications in
                notifications.filter { !$0.isRead }.count
            }
            .assign(to: &$unreadCount)
    }
    
    // MARK: - Authorization
    func requestAuthorization() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await MainActor.run {
                self.isAuthorized = granted
            }
        } catch {
            print("Notification authorization error: \(error)")
        }
    }
    
    func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Send Notifications
    func sendNotification(_ notification: PipflowNotification) {
        // Check preferences
        guard preferences.shouldShowNotification(
            type: notification.type,
            priority: notification.priority
        ) else { return }
        
        // Add to in-app notifications
        notifications.insert(notification, at: 0)
        
        // Send push notification if enabled
        if preferences.enablePushNotifications && isAuthorized {
            schedulePushNotification(notification)
        }
        
        // Play sound if enabled
        if preferences.enableSoundAlerts {
            playNotificationSound(for: notification.priority)
        }
    }
    
    private func schedulePushNotification(_ notification: PipflowNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = getNotificationSound(for: notification.priority)
        content.badge = NSNumber(value: unreadCount + 1)
        
        // Add category identifier for actions
        content.categoryIdentifier = notification.type.rawValue
        
        // Add user info
        content.userInfo = [
            "notificationId": notification.id,
            "type": notification.type.rawValue,
            "priority": notification.priority.rawValue
        ]
        
        // Create trigger (immediate)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func getNotificationSound(for priority: NotificationPriority) -> UNNotificationSound {
        switch priority {
        case .urgent:
            return UNNotificationSound.defaultCritical
        case .high:
            return UNNotificationSound(named: UNNotificationSoundName("alert_high.wav"))
        default:
            return .default
        }
    }
    
    private func playNotificationSound(for priority: NotificationPriority) {
        // In a real app, implement sound playback
    }
    
    // MARK: - Mark as Read
    func markAsRead(_ notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            var updatedNotification = notifications[index]
            updatedNotification = PipflowNotification(
                id: updatedNotification.id,
                type: updatedNotification.type,
                title: updatedNotification.title,
                message: updatedNotification.message,
                timestamp: updatedNotification.timestamp,
                priority: updatedNotification.priority,
                isRead: true,
                data: updatedNotification.data,
                actionUrl: updatedNotification.actionUrl,
                expiresAt: updatedNotification.expiresAt
            )
            notifications[index] = updatedNotification
        }
    }
    
    func markAllAsRead() {
        notifications = notifications.map { notification in
            PipflowNotification(
                id: notification.id,
                type: notification.type,
                title: notification.title,
                message: notification.message,
                timestamp: notification.timestamp,
                priority: notification.priority,
                isRead: true,
                data: notification.data,
                actionUrl: notification.actionUrl,
                expiresAt: notification.expiresAt
            )
        }
    }
    
    // MARK: - Delete Notifications
    func deleteNotification(_ notificationId: String) {
        notifications.removeAll { $0.id == notificationId }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
    
    func clearAll() {
        notifications.removeAll()
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    // MARK: - Price Alerts
    func createPriceAlert(_ alert: PriceAlert) {
        priceAlerts.append(alert)
    }
    
    func updatePriceAlert(_ alert: PriceAlert) {
        if let index = priceAlerts.firstIndex(where: { $0.id == alert.id }) {
            priceAlerts[index] = alert
        }
    }
    
    func deletePriceAlert(_ alertId: String) {
        priceAlerts.removeAll { $0.id == alertId }
    }
    
    func checkPriceAlerts(currentPrices: [String: Double]) {
        for alert in priceAlerts where alert.isActive {
            guard let currentPrice = currentPrices[alert.symbol] else { continue }
            
            var shouldTrigger = false
            
            switch alert.condition {
            case .above:
                shouldTrigger = currentPrice > alert.targetPrice
            case .below:
                shouldTrigger = currentPrice < alert.targetPrice
            case .crosses:
                // Would need previous price to check crossing
                shouldTrigger = false
            case .percentChangeUp, .percentChangeDown:
                // Would need to calculate percentage change
                shouldTrigger = false
            }
            
            if shouldTrigger {
                triggerPriceAlert(alert, currentPrice: currentPrice)
            }
        }
    }
    
    private func triggerPriceAlert(_ alert: PriceAlert, currentPrice: Double) {
        // Mark alert as triggered
        var triggeredAlert = alert
        triggeredAlert = PriceAlert(
            id: alert.id,
            symbol: alert.symbol,
            condition: alert.condition,
            targetPrice: alert.targetPrice,
            isActive: false,
            createdAt: alert.createdAt,
            triggeredAt: Date(),
            expiresAt: alert.expiresAt,
            note: alert.note
        )
        updatePriceAlert(triggeredAlert)
        
        // Create notification
        let priceChange = currentPrice - alert.targetPrice
        let priceChangePercent = (priceChange / alert.targetPrice) * 100
        
        let notification = PipflowNotification(
            type: .priceAlert,
            title: "\(alert.symbol) Alert Triggered",
            message: "\(alert.symbol) is now at \(String(format: "%.2f", currentPrice)). \(alert.condition.description) \(String(format: "%.2f", alert.targetPrice))",
            priority: .high,
            data: .priceAlert(PriceAlertData(
                symbol: alert.symbol,
                condition: alert.condition,
                targetPrice: alert.targetPrice,
                currentPrice: currentPrice,
                priceChange: priceChange,
                priceChangePercent: priceChangePercent
            ))
        )
        
        sendNotification(notification)
    }
    
    // MARK: - Trade Notifications
    func sendTradeNotification(
        trade: Trade,
        status: String
    ) {
        let title: String
        let message: String
        
        switch status {
        case "OPENED":
            title = "Trade Opened"
            message = "\(trade.type) \(trade.volume) lots of \(trade.symbol) at \(String(format: "%.5f", Double(truncating: trade.openPrice as NSNumber)))"
        case "CLOSED":
            let profitValue = Double(truncating: trade.profit as NSNumber)
            let profitText = profitValue >= 0 ? "+$\(String(format: "%.2f", profitValue))" : "-$\(String(format: "%.2f", abs(profitValue)))"
            title = "Trade Closed"
            message = "\(trade.symbol) position closed with \(profitText) profit"
        case "MODIFIED":
            title = "Trade Modified"
            message = "\(trade.symbol) position has been updated"
        default:
            return
        }
        
        let notification = PipflowNotification(
            type: status == "CLOSED" ? .tradeClosed : .tradeExecution,
            title: title,
            message: message,
            priority: .high,
            data: .trade(TradeNotificationData(
                tradeId: trade.id.uuidString,
                symbol: trade.symbol,
                type: trade.type.rawValue,
                volume: Double(truncating: trade.volume as NSNumber),
                price: Double(truncating: trade.openPrice as NSNumber),
                profit: Double(truncating: trade.profit as NSNumber),
                status: status
            ))
        )
        
        sendNotification(notification)
    }
    
    // MARK: - Signal Notifications
    func sendSignalNotification(_ signal: Signal) {
        let notification = PipflowNotification(
            type: .signalGenerated,
            title: "New Trading Signal",
            message: "\(signal.action.rawValue) \(signal.symbol) - Confidence: \(Int(signal.confidence * 100))%",
            priority: signal.confidence > 0.8 ? .high : .medium,
            data: .signal(SignalNotificationData(
                signalId: signal.id.uuidString,
                symbol: signal.symbol,
                action: signal.action.rawValue,
                confidence: signal.confidence,
                entryPrice: Double(truncating: signal.entry as NSNumber),
                stopLoss: Double(truncating: signal.stopLoss as NSNumber),
                takeProfit: Double(truncating: (signal.takeProfits.first?.price ?? 0) as NSNumber)
            ))
        )
        
        sendNotification(notification)
    }
    
    // MARK: - Social Notifications
    func sendSocialNotification(
        userId: String,
        username: String,
        action: String,
        targetId: String? = nil,
        targetType: String? = nil
    ) {
        let message: String
        switch action {
        case "followed":
            message = "\(username) started following you"
        case "liked":
            message = "\(username) liked your \(targetType ?? "post")"
        case "commented":
            message = "\(username) commented on your \(targetType ?? "post")"
        case "copied":
            message = "\(username) started copying your strategy"
        default:
            message = "\(username) interacted with your content"
        }
        
        let notification = PipflowNotification(
            type: .socialActivity,
            title: "Social Activity",
            message: message,
            priority: .low,
            data: .social(SocialNotificationData(
                userId: userId,
                username: username,
                action: action,
                targetId: targetId,
                targetType: targetType
            ))
        )
        
        sendNotification(notification)
    }
    
    // MARK: - News Notifications
    func sendNewsNotification(
        title: String,
        message: String,
        importance: String,
        affectedSymbols: [String],
        sourceUrl: String? = nil
    ) {
        let priority: NotificationPriority = importance == "high" ? .high : .medium
        
        let notification = PipflowNotification(
            type: .marketNews,
            title: title,
            message: message,
            priority: priority,
            data: .news(NewsNotificationData(
                newsId: UUID().uuidString,
                category: "market",
                importance: importance,
                affectedSymbols: affectedSymbols,
                sourceUrl: sourceUrl
            ))
        )
        
        sendNotification(notification)
    }
    
    // MARK: - Mock Data
    private func loadMockData() {
        // Mock notifications
        let mockNotifications = [
            PipflowNotification(
                type: .priceAlert,
                title: "EUR/USD Alert",
                message: "EUR/USD reached your target price of 1.0850",
                timestamp: Date().addingTimeInterval(-3600),
                priority: .high,
                isRead: false
            ),
            PipflowNotification(
                type: .tradeExecution,
                title: "Trade Opened",
                message: "BUY 0.1 lots of GBP/USD at 1.2650",
                timestamp: Date().addingTimeInterval(-7200),
                priority: .medium,
                isRead: true
            ),
            PipflowNotification(
                type: .signalGenerated,
                title: "New Signal",
                message: "SELL XAU/USD - Confidence: 85%",
                timestamp: Date().addingTimeInterval(-10800),
                priority: .high,
                isRead: false
            ),
            PipflowNotification(
                type: .marketNews,
                title: "Breaking News",
                message: "Fed announces interest rate decision",
                timestamp: Date().addingTimeInterval(-14400),
                priority: .high,
                isRead: true
            ),
            PipflowNotification(
                type: .socialActivity,
                title: "New Follower",
                message: "TraderPro123 started following you",
                timestamp: Date().addingTimeInterval(-86400),
                priority: .low,
                isRead: false
            )
        ]
        
        notifications = mockNotifications
        
        // Mock price alerts
        priceAlerts = [
            PriceAlert(
                symbol: "EUR/USD",
                condition: .above,
                targetPrice: 1.0900,
                note: "Resistance level breakout"
            ),
            PriceAlert(
                symbol: "GBP/USD",
                condition: .below,
                targetPrice: 1.2500,
                note: "Support level test"
            ),
            PriceAlert(
                symbol: "XAU/USD",
                condition: .crosses,
                targetPrice: 2000.00,
                note: "Psychological level"
            )
        ]
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let notificationId = userInfo["notificationId"] as? String {
            Task { @MainActor in
                // Mark notification as read
                self.markAsRead(notificationId)
                
                // Handle notification action
                // In a real app, navigate to relevant screen
            }
        }
        
        completionHandler()
    }
}