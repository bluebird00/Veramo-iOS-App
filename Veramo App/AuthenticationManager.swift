//
//  AuthenticationManager.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import Foundation
import UIKit

class AuthenticationManager {
    static let shared = AuthenticationManager()
    
    private let sessionTokenKey = "sessionToken"
    private let customerKey = "authenticatedCustomer"
    private let phoneNumberKey = "savedPhoneNumber"  // Save phone separately
    private let hasSeenWelcomeKey = "hasSeenWelcome"  // Track welcome screen
    
    private init() {}
    
    // MARK: - Session Token
    
    var sessionToken: String? {
        get {
            let token = UserDefaults.standard.string(forKey: sessionTokenKey)
            return token
        }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: sessionTokenKey)
                UserDefaults.standard.synchronize() // Force immediate save
                print("✅ Token saved and synchronized")
            } else {
                print("🗑️ Removing sessionToken from UserDefaults")
                UserDefaults.standard.removeObject(forKey: sessionTokenKey)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    var isAuthenticated: Bool {
        let token = sessionToken
        let customer = currentCustomer
        let isAuth = token != nil && customer != nil
        print("🔑 isAuthenticated check: \(isAuth) (token exists: \(token != nil), customer exists: \(customer != nil))")
        if let token = token {
            print("   Token preview: \(String(token.prefix(20)))...")
        }
        return isAuth
    }
    
    // MARK: - Customer Info
    
    var customerId: Int? {
        return currentCustomer?.id
    }
    
    var currentCustomer: AuthenticatedCustomer? {
        get {
            guard let data = UserDefaults.standard.data(forKey: customerKey) else {
                print("🔍 Getting currentCustomer from UserDefaults: nil")
                return nil
            }
            let customer = try? JSONDecoder().decode(AuthenticatedCustomer.self, from: data)
            print("🔍 Getting currentCustomer from UserDefaults: \(customer?.name ?? "decode failed or nil")")
            return customer
        }
        set {
            if let customer = newValue,
               let data = try? JSONEncoder().encode(customer) {
                print("💾 Setting currentCustomer in UserDefaults: \(customer.name ?? "nil")")
                UserDefaults.standard.set(data, forKey: customerKey)
                UserDefaults.standard.synchronize() // Force immediate save
                print("✅ Customer saved and synchronized")
            } else {
                print("🗑️ Removing currentCustomer from UserDefaults")
                UserDefaults.standard.removeObject(forKey: customerKey)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    // MARK: - Saved Phone Number
    
    var savedPhoneNumber: String? {
        get {
            UserDefaults.standard.string(forKey: phoneNumberKey)
        }
        set {
            if let phone = newValue {
                UserDefaults.standard.set(phone, forKey: phoneNumberKey)
            } else {
                UserDefaults.standard.removeObject(forKey: phoneNumberKey)
            }
        }
    }
    
    // MARK: - Welcome Screen
    
    var hasSeenWelcome: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasSeenWelcomeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasSeenWelcomeKey)
        }
    }
    
    // MARK: - Authentication Actions
    
    func saveAuthentication(customer: AuthenticatedCustomer, sessionToken: String) {
        print("💾 Saving authentication...")
        print("   Customer: \(customer.name ?? "nil")")
        print("   Token: \(String(sessionToken.prefix(20)))...")
        
        self.sessionToken = sessionToken
        self.currentCustomer = customer
        
        // Force UserDefaults to save immediately
        UserDefaults.standard.synchronize()
        
        // Verify it was saved by reading back
        print("✅ Saved! Verifying...")
        print("   sessionToken in UserDefaults: \(self.sessionToken != nil)")
        print("   currentCustomer in UserDefaults: \(self.currentCustomer != nil)")
        print("   isAuthenticated check: \(self.isAuthenticated)")
        
        if let savedToken = self.sessionToken {
            print("   ✅ Token verified: \(String(savedToken.prefix(20)))...")
        }
        if let savedCustomer = self.currentCustomer {
            print("   ✅ Customer verified: \(savedCustomer.name ?? "nil")")
        }
        
        // Re-register device token for push notifications now that user is authenticated
        PushNotificationService.shared.reregisterDeviceTokenIfNeeded()
        
        // Also trigger a fresh APNs registration in case token hasn't been received yet
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func logout() {
        print("🚪 [AUTH] Logging out user...")
        print("   Previous token: \(sessionToken != nil ? "existed" : "none")")
        print("   Previous customer: \(currentCustomer?.name ?? "none")")
        
        // Disconnect from chat before clearing credentials
        Task {
            await ChatManager.shared.disconnect()
        }
        
        sessionToken = nil
        currentCustomer = nil
        
        // Optionally clear phone number on logout:
        // savedPhoneNumber = nil
        
        print("✅ [AUTH] Logout complete")
        print("   sessionToken cleared: \(sessionToken == nil)")
        print("   currentCustomer cleared: \(currentCustomer == nil)")
    }
}
