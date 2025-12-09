//
//  AuthenticationManager.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import Foundation

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
            UserDefaults.standard.string(forKey: sessionTokenKey)
        }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: sessionTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: sessionTokenKey)
            }
        }
    }
    
    var isAuthenticated: Bool {
        sessionToken != nil
    }
    
    // MARK: - Customer Info
    
    var currentCustomer: AuthenticatedCustomer? {
        get {
            guard let data = UserDefaults.standard.data(forKey: customerKey) else {
                return nil
            }
            return try? JSONDecoder().decode(AuthenticatedCustomer.self, from: data)
        }
        set {
            if let customer = newValue,
               let data = try? JSONEncoder().encode(customer) {
                UserDefaults.standard.set(data, forKey: customerKey)
            } else {
                UserDefaults.standard.removeObject(forKey: customerKey)
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
        self.sessionToken = sessionToken
        self.currentCustomer = customer
    }
    
    func logout() {
        sessionToken = nil
        currentCustomer = nil
        // Optionally clear phone number on logout:
        // savedPhoneNumber = nil
    }
}
