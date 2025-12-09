//
//  PushNotificationService.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import UIKit
import UserNotifications
import StreamChat

class PushNotificationService {
    static let shared = PushNotificationService()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Push notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("❌ Push notification permission error: \(error)")
            } else {
                print("⚠️ Push notification permission denied")
            }
        }
    }
    
    func registerDeviceToken(_ deviceToken: Data) {
        guard let chatClient = ChatManager.shared.chatClient else {
            print("❌ Chat client not initialized")
            return
        }
        
        // Register device token with Stream
        chatClient.currentUserController().addDevice(.apn(token: deviceToken)) { error in
            if let error = error {
                print("❌ Failed to register device token: \(error)")
            } else {
                print("✅ Device token registered successfully")
            }
        }
    }
    
    func unregisterDeviceToken(_ deviceToken: Data) {
        guard let chatClient = ChatManager.shared.chatClient else {
            return
        }
        
        let hexString = deviceToken.map { String(format: "%02x", $0) }.joined()
        
        chatClient.currentUserController().removeDevice(id: hexString) { error in
            if let error = error {
                print("❌ Failed to unregister device token: \(error)")
            } else {
                print("✅ Device token unregistered successfully")
            }
        }
    }
}
