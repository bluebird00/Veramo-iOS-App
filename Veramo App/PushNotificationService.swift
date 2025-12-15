//
//  PushNotificationService.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import UIKit
import UserNotifications
import StreamChat

// MARK: - Notification Names
extension Notification.Name {
    static let driverArrived = Notification.Name("driverArrived")
    static let driverStatusChanged = Notification.Name("driverStatusChanged")
}

// MARK: - Device Registration Models
struct DeviceRegistrationRequest: Codable {
    let deviceToken: String
    let platform: String
    let appVersion: String
    let language: String
}

struct DeviceUnregistrationRequest: Codable {
    let deviceToken: String
}
    
enum CodingKeys: String, CodingKey {
    case deviceToken = "device_token"
}


class PushNotificationService {
    static let shared = PushNotificationService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    
    private init() {}
    
    // MARK: - Helper Methods
    
    /// Get the user's device language, defaulting to supported languages
    private func getDeviceLanguage() -> String {
        let preferredLanguage = Locale.current.language.languageCode?.identifier ?? "de"
        
        // Map to supported languages (de, en, it, fr)
        let supportedLanguages = ["de", "en", "it", "fr"]
        
        // Return if it's a supported language
        if supportedLanguages.contains(preferredLanguage) {
            return preferredLanguage
        }
        
        // Default to German for unsupported languages
        return "de"
    }
    
    /// Get the app version from bundle
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version).\(build)"
    }
    
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
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("📱 [PUSH] Device token received from APNs")
        print("📱 [PUSH] Token: \(String(tokenString.prefix(20)))...")
        
        // Store the token immediately for later use
        UserDefaults.standard.set(tokenString, forKey: "deviceToken")
        print("💾 [PUSH] Device token stored locally")
        
        // Register with backend for driver notifications (only if authenticated)
        Task {
            await registerDeviceTokenWithBackend(tokenString)
        }
        
        // Also register with Stream for chat notifications
        guard let chatClient = ChatManager.shared.chatClient else {
            print("⚠️ Chat client not initialized, skipping Stream registration")
            return
        }
        
        // Specify the provider name "Apple" to match your Stream configuration
        chatClient.currentUserController().addDevice(.apn(token: deviceToken, providerName: "Apple")) { error in
            if let error = error {
                print("❌ Failed to register device token with Stream: \(error)")
            } else {
                print("✅ Device token registered with Stream successfully")
            }
        }
    }
    
    func unregisterDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("📱 [PUSH] Unregistering device token")
        
        // Unregister from backend
        Task {
            await unregisterDeviceTokenFromBackend(tokenString)
        }
        
        // Also unregister from Stream
        guard let chatClient = ChatManager.shared.chatClient else {
            return
        }
        
        chatClient.currentUserController().removeDevice(id: tokenString) { error in
            if let error = error {
                print("❌ Failed to unregister device token from Stream: \(error)")
            } else {
                print("✅ Device token unregistered from Stream successfully")
            }
        }
    }
    
    // MARK: - Backend Registration
    
    /// Register device token with backend for driver notifications
    private func registerDeviceTokenWithBackend(_ deviceToken: String) async {
        print("🌐 [PUSH] Registering device token with backend...")
        
        // Only register if user is authenticated
        guard let sessionToken = AuthenticationManager.shared.sessionToken else {
            print("⚠️ [PUSH] No session token - user not authenticated, skipping backend registration")
            return
        }
        
        guard let url = URL(string: "\(baseURL)/app-register-device") else {
            print("❌ [PUSH] Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let deviceLanguage = getDeviceLanguage()
        let appVersion = getAppVersion()
        
        let registrationRequest = DeviceRegistrationRequest(
            deviceToken: deviceToken,
            platform: "ios",
            appVersion: appVersion,
            language: deviceLanguage
        )
        
        print("📤 [PUSH] Sending registration request:")
        print("   URL: \(url)")
        print("   Device Token: \(String(deviceToken.prefix(20)))...")
        print("   Platform: ios")
        print("   App Version: \(appVersion)")
        print("   Language: \(deviceLanguage)")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(registrationRequest)
            
            // Log the actual JSON being sent
            if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
                print("   JSON: \(jsonString)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ [PUSH] Device token registered with backend successfully")
                    
                    // Store that we've registered this token
                    UserDefaults.standard.set(deviceToken, forKey: "registeredDeviceToken")
                } else {
                    print("❌ [PUSH] Backend returned status code: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("   Response: \(responseString)")
                    }
                }
            }
        } catch {
            print("❌ [PUSH] Failed to register device token with backend: \(error.localizedDescription)")
        }
    }
    
    /// Unregister device token from backend
    private func unregisterDeviceTokenFromBackend(_ deviceToken: String) async {
        print("🌐 [PUSH] Unregistering device token from backend...")
        
        guard let sessionToken = AuthenticationManager.shared.sessionToken else {
            print("⚠️ [PUSH] No session token - skipping backend unregistration")
            return
        }
        
        guard let url = URL(string: "\(baseURL)/app-unregister-device") else {
            print("❌ [PUSH] Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let unregistrationRequest = DeviceUnregistrationRequest(deviceToken: deviceToken)
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(unregistrationRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ [PUSH] Device token unregistered from backend successfully")
                    
                    // Remove stored token
                    UserDefaults.standard.removeObject(forKey: "registeredDeviceToken")
                } else {
                    print("❌ [PUSH] Backend returned status code: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("   Response: \(responseString)")
                    }
                }
            }
        } catch {
            print("❌ [PUSH] Failed to unregister device token from backend: \(error.localizedDescription)")
        }
    }
    
    /// Re-register device token if user logs in and token exists
    func reregisterDeviceTokenIfNeeded() {
        print("🔄 [PUSH] Checking if device token needs re-registration...")
        
        if let storedToken = UserDefaults.standard.string(forKey: "deviceToken") {
            print("📱 [PUSH] Found stored device token: \(String(storedToken.prefix(20)))...")
            print("🌐 [PUSH] Re-registering with backend...")
            Task {
                await registerDeviceTokenWithBackend(storedToken)
            }
        } else {
            print("⚠️ [PUSH] No stored device token found")
            print("ℹ️ [PUSH] This is normal if:")
            print("   • You're running in iOS Simulator (push notifications require physical device)")
            print("   • Notification permissions were denied")
            print("   • APNs hasn't responded yet (may take a few seconds)")
            print("   • This is the first app launch")
        }
    }
    
    // MARK: - Local Notifications
    
    /// Send a local notification when driver arrives
    /// This is useful for testing or as a fallback if push notifications fail
    func sendDriverArrivedNotification(reference: String, driverName: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Your driver has arrived!", comment: "Notification title when driver arrives")
        
        if let driverName = driverName {
            content.body = String(localized: "\(driverName) is waiting for you", comment: "Notification body with driver name")
        } else {
            content.body = String(localized: "Your driver is waiting for you", comment: "Notification body without driver name")
        }
        
        content.sound = .defaultCritical // Critical alert for important arrival notification
        content.categoryIdentifier = "DRIVER_ARRIVAL"
        content.userInfo = [
            "type": "driver_arrival",
            "reference": reference
        ]
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "driver-arrival-\(reference)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send local notification: \(error)")
            } else {
                print("✅ Driver arrival notification sent")
            }
        }
    }
    
    /// Send a local notification for driver status changes
    func sendDriverStatusNotification(reference: String, status: DriverStatus, estimatedMinutes: Int? = nil) {
        let content = UNMutableNotificationContent()
        
        switch status {
        case .enRoute:
            content.title = String(localized: "Driver on the way", comment: "Notification title when driver starts journey")
            if let minutes = estimatedMinutes {
                content.body = String(localized: "Arriving in approximately \(minutes) minutes", comment: "Notification body with ETA")
            } else {
                content.body = String(localized: "Your driver is heading to pick you up", comment: "Notification body without ETA")
            }
        case .arrived:
            content.title = String(localized: "Your driver has arrived!", comment: "Notification title when driver arrives")
            content.body = String(localized: "Your driver is waiting for you", comment: "Notification body for arrival")
            content.sound = .defaultCritical
        case .waitingForPickup:
            content.title = String(localized: "Driver waiting", comment: "Notification title when driver is waiting")
            content.body = String(localized: "Please head to your pickup location", comment: "Notification body prompting passenger to go to pickup")
        case .pickupComplete:
            content.title = String(localized: "On your way!", comment: "Notification title when trip starts")
            content.body = String(localized: "Heading to your destination", comment: "Notification body when heading to destination")
        case .droppingOff:
            content.title = String(localized: "Almost there", comment: "Notification title when approaching destination")
            if let minutes = estimatedMinutes {
                content.body = String(localized: "Arriving at destination in \(minutes) minutes", comment: "Notification body with destination ETA")
            } else {
                content.body = String(localized: "Approaching your destination", comment: "Notification body without destination ETA")
            }
        case .complete:
            content.title = String(localized: "Trip completed", comment: "Notification title when trip is complete")
            content.body = String(localized: "Thank you for riding with us!", comment: "Notification body for trip completion")
        case .canceled:
            content.title = String(localized: "Trip canceled", comment: "Notification title when trip is canceled")
            content.body = String(localized: "Your trip has been canceled", comment: "Notification body for cancellation")
        }
        
        content.categoryIdentifier = "DRIVER_STATUS"
        content.userInfo = [
            "type": "driver_status",
            "reference": reference,
            "status": status.rawValue
        ]
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "driver-status-\(reference)-\(status.rawValue)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send status notification: \(error)")
            } else {
                print("✅ Driver status notification sent: \(status.rawValue)")
            }
        }
    }
}
