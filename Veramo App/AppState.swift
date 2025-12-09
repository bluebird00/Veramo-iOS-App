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
        print("🔐 AppState initialized - isAuthenticated: \(isAuthenticated)")
    }
    
    func login() {
        isAuthenticated = true
        print("✅ AppState: User logged in")
    }
    
    func logout() {
        AuthenticationManager.shared.logout()
        isAuthenticated = false
        print("🚪 AppState: User logged out")
    }
}
