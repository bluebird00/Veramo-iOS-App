//
//  AppState.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import SwiftUI

@Observable
class AppState {
    var isAuthenticated: Bool
    
    init() {
        self.isAuthenticated = AuthenticationManager.shared.isAuthenticated
    }
    
    func login() {
        isAuthenticated = true
    }
    
    func logout() {
        AuthenticationManager.shared.logout()
        isAuthenticated = false
    }
}
