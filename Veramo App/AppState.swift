//
//  AppState.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import SwiftUI
import Combine

@Observable
class AppState {
    var isAuthenticated: Bool
    
    init() {
        // Load authentication state from persistent storage
        self.isAuthenticated = AuthenticationManager.shared.isAuthenticated
    }
    
    func login() {
        // Refresh authentication state from persistent storage
        isAuthenticated = AuthenticationManager.shared.isAuthenticated
        print("🔐 [AppState] login() called - isAuthenticated refreshed: \(isAuthenticated)")
    }
    
    func logout() {
        AuthenticationManager.shared.logout()
        isAuthenticated = false
    }
    
    /// Call this method when you receive a 401 Unauthorized response from the API
    func handleAuthenticationError() {
        print("⚠️ Session expired - logging out user")
        logout()
    }
    
    /// Refresh authentication state from persistent storage
    func refreshAuthenticationState() {
        isAuthenticated = AuthenticationManager.shared.isAuthenticated
    }
}
