//
//  AppDelegate.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import UIKit
import UserNotifications
import StreamChat
import AppsFlyerLib

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // MARK: - AppsFlyer Configuration
        AppsFlyerLib.shared().appsFlyerDevKey = "oadcqb6QLGDMYKUNUT8irJ"
        AppsFlyerLib.shared().appleAppID = "id6756296416"
        
        // Enable debug logs (set to false in production)
        #if DEBUG
        AppsFlyerLib.shared().isDebug = true
        #else
        AppsFlyerLib.shared().isDebug = false
        #endif
        
        
        
        print("✅ [AppsFlyer] SDK configured")
        
        // Request push notification permission
        PushNotificationService.shared.requestAuthorization()
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // MARK: - AppsFlyer Lifecycle
    // Note: AppsFlyer.start() is called in Veramo_AppApp.swift via scenePhase observer
    // applicationDidBecomeActive is not called in SwiftUI apps
    
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
    
    // Called when a remote notification arrives (app in background or foreground)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📬 [APNs] Received remote notification")
        print("   UserInfo: \(userInfo)")
        
        // Check if this is a Stream Chat notification
        if userInfo["sender"] as? String != nil || userInfo["channel_id"] as? String != nil {
            print("💬 [STREAM] Detected Stream Chat notification")
            
            // Let Stream SDK handle the notification
            if let chatClient = ChatManager.shared.chatClient {
                // Stream will handle updating unread counts, etc.
                print("✅ [STREAM] Passing notification to Stream SDK")
            }
            
            completionHandler(.newData)
        } else {
            // Handle other notifications (driver, etc.)
            print("📱 [PUSH] Other notification type")
            completionHandler(.noData)
        }
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
        
        print("👆 [NOTIFICATION] User tapped notification")
        print("   UserInfo: \(userInfo)")
        
        // Check if this is a Stream chat notification (multiple possible keys)
        let isStreamNotification = userInfo["channel_id"] != nil 
            || userInfo["sender"] != nil 
            || userInfo["message_id"] != nil
            || userInfo["channel_type"] != nil
        
        if isStreamNotification {
            print("💬 [STREAM] Stream chat notification tapped")
            
            if let channelId = userInfo["channel_id"] as? String {
                print("   Channel ID: \(channelId)")
                // Post notification to open chat
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenChatChannel"),
                    object: nil,
                    userInfo: ["channelId": channelId]
                )
            } else {
                print("⚠️ [STREAM] No channel_id found, just opening chat tab")
                // Just open the chat tab
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenChatTab"),
                    object: nil
                )
            }
            
            completionHandler()
            return
        }
        
        // Check notification type for driver notifications
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
                print("⚠️ Unknown notification type: \(notificationType)")
                break
            }
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
