//
//  AppDelegate.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import UIKit
import UserNotifications
import StreamChat

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Request push notification permission
        PushNotificationService.shared.requestAuthorization()
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Called when APNs successfully registers the device
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ Device token received: \(deviceToken.hexString)")
        
        // Register device token with Stream
        PushNotificationService.shared.registerDeviceToken(deviceToken)
    }
    
    // Called when registration fails
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Show banner, badge, and play sound even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        // Check if this is a Stream chat notification
        if let channelId = userInfo["channel_id"] as? String {
            print("📬 User tapped notification for channel: \(channelId)")
            
            // Post notification to open chat
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenChatChannel"),
                object: nil,
                userInfo: ["channelId": channelId]
            )
        }
        
        completionHandler()
    }
}

// Helper extension
extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
