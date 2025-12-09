//
//  Veramo_AppApp.swift
//  Veramo App
//
//  Created by rentamac on 12/6/25.
//

import SwiftUI

@main
struct Veramo_AppApp: App {
    @State private var appState = AppState()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasSeenWelcome = AuthenticationManager.shared.hasSeenWelcome
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content
                Group {
                    if appState.isAuthenticated {
                        MainTabView()
                            .environment(appState)
                    } else {
                        LoginView()
                    }
                }
                .onOpenURL { url in
                    handleMagicLink(url: url)
                }
                .alert("Authentication Error", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
                
                // Welcome screen overlay (shows on first launch)
                if !hasSeenWelcome {
                    WelcomeScreenAlternate(hasSeenWelcome: $hasSeenWelcome)
                        .transition(.opacity)
                        .zIndex(1)
                }
                
                // DEBUG ONLY: Remove before production!
                #if DEBUG
                DebugButton(hasSeenWelcome: $hasSeenWelcome)
                    .zIndex(999)
                #endif
            }
            .onChange(of: hasSeenWelcome) { _, newValue in
                // Save the preference when it changes
                AuthenticationManager.shared.hasSeenWelcome = newValue
            }
        }
    }
    
    private func handleMagicLink(url: URL) {
        // Verify it's a veramo URL with auth host
        guard url.scheme == "veramo",
              url.host == "auth" else {
            print("Invalid URL scheme or host: \(url)")
            return
        }
        
        // Extract the token from query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
            errorMessage = "Invalid authentication link"
            showError = true
            return
        }
        
        // Verify token with your API
        Task {
            do {
                let (customer, sessionToken) = try await VeramoAuthService.shared.verifyMagicLink(token: token)
                
                print("✅ Successfully authenticated: \(customer.name)")
                print("📝 Session token: \(sessionToken)")
                
                // Update authentication state
                await MainActor.run {
                    // Save authentication using the manager
                    AuthenticationManager.shared.saveAuthentication(
                        customer: customer,
                        sessionToken: sessionToken
                    )
                    
                    appState.login()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to authenticate: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}
