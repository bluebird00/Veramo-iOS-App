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
        print("✅ [APNs] Successfully registered for remote notifications")
        
        // Register device token with Stream and backend
        PushNotificationService.shared.registerDeviceToken(deviceToken)
    }
    
    // Called when APNs registration fails
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [APNs] Failed to register for remote notifications: \(error.localizedDescription)")
        
        // This is common in simulator - not a critical error
        #if targetEnvironment(simulator)
        print("ℹ️ [APNs] This is normal in iOS Simulator - push notifications require a physical device")
        #endif
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
        
        // Check notification type
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "driver_arrival":
                // Handle driver arrival notification tap
                if let reference = userInfo["reference"] as? String {
                    print("🚗 Driver arrival notification tapped for reference: \(reference)")
                    NotificationCenter.default.post(
                        name: .driverArrived,
                        object: nil,
                        userInfo: ["reference": reference]
                    )
                }
                
            case "driver_status":
                // Handle driver status change notification tap
                if let reference = userInfo["reference"] as? String,
                   let statusRaw = userInfo["status"] as? String {
                    print("🚗 Driver status notification tapped: \(statusRaw)")
                    NotificationCenter.default.post(
                        name: .driverStatusChanged,
                        object: nil,
                        userInfo: [
                            "reference": reference,
                            "status": statusRaw
                        ]
                    )
                }
                
            default:
                break
            }
        }
        
        // Check if this is a Stream chat notification
        if let channelId = userInfo["channel_id"] as? String {            
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
