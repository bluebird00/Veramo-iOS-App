//
//  Veramo_AppApp.swift
//  Veramo App
//
//  Created by rentamac on 12/6/25.
//

import SwiftUI
import StreamChat
import StreamChatSwiftUI

@main
struct Veramo_AppApp: App {
    @State private var appState = AppState()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasSeenWelcome = AuthenticationManager.shared.hasSeenWelcome
    
    init() {
        // Debug: Log initial state
        print("🚀 App initializing")
        print("📱 hasSeenWelcome from UserDefaults: \(AuthenticationManager.shared.hasSeenWelcome)")
        print("🔐 isAuthenticated from UserDefaults: \(AuthenticationManager.shared.isAuthenticated)")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content
                Group {
                    if appState.isAuthenticated {
                        MainTabView()
                            .environment(appState)
                    } else {
                        SMSLoginView()
                            .environment(appState)
                    }
                }
                .alert("Authentication Error", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
                
                // Welcome screen overlay - only show if BOTH conditions are true:
                // 1. User hasn't seen welcome before
                // 2. User is NOT authenticated
                if shouldShowWelcome {
                    WelcomeScreenAlternate(hasSeenWelcome: $hasSeenWelcome)
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            print("⚠️ Welcome screen IS showing!")
                            print("   hasSeenWelcome: \(hasSeenWelcome)")
                            print("   appState.isAuthenticated: \(appState.isAuthenticated)")
                        }
                } else {
                    Color.clear.onAppear {
                        print("✅ Welcome screen NOT showing")
                        print("   hasSeenWelcome: \(hasSeenWelcome)")
                        print("   appState.isAuthenticated: \(appState.isAuthenticated)")
                    }
                }
                
                // DEBUG ONLY: Remove before production!
                #if DEBUG
                DebugButton(hasSeenWelcome: $hasSeenWelcome)
                    .zIndex(999)
                
                // SMS Debug overlay (bottom-right ladybug button)
                if !appState.isAuthenticated {
                    SMSDebugView()
                        .environment(appState)
                        .zIndex(998)
                }
                #endif
            }
            .onChange(of: hasSeenWelcome) { oldValue, newValue in
                // Save the preference when it changes
                print("👀 hasSeenWelcome changed from \(oldValue) to \(newValue)")
                AuthenticationManager.shared.hasSeenWelcome = newValue
                print("💾 Saved to UserDefaults: \(AuthenticationManager.shared.hasSeenWelcome)")
            }
            .onOpenURL { url in
                print("📨 onOpenURL triggered with: \(url)")
                handleIncomingURL(url: url)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                print("🌐 onContinueUserActivity triggered")
                if let url = userActivity.webpageURL {
                    print("   WebpageURL: \(url)")
                    handleIncomingURL(url: url)
                }
            }
        }
    }
    
    // Computed property to determine if welcome screen should show
    private var shouldShowWelcome: Bool {
        let show = !hasSeenWelcome && !appState.isAuthenticated
        print("🤔 Checking shouldShowWelcome: \(show) (hasSeenWelcome: \(hasSeenWelcome), isAuth: \(appState.isAuthenticated))")
        return show
    }
    
    private func handleIncomingURL(url: URL) {
        print("🔗 handleIncomingURL called with: \(url)")
        print("   Scheme: \(url.scheme ?? "none")")
        print("   Host: \(url.host ?? "none")")
        print("   Path: \(url.path)")
        print("   Query: \(url.query ?? "none")")
        
        // Handle deep link (veramo://auth?token=...)
        if url.scheme == "veramo" && url.host == "auth" {
            handleMagicLink(url: url)
            return
        }
        
        // Handle web link (https://veramo.ch/open-app.html?token=...)
        if url.scheme == "https" && url.host == "veramo.ch" {
            print("✅ Detected web link - extracting token from query")
            
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
                print("❌ No token found in web URL")
                errorMessage = "Invalid authentication link"
                showError = true
                return
            }
            
            print("✅ Token extracted from web URL: \(String(token.prefix(20)))...")
            
            // Create a proper deep link URL and handle it
            if let deepLinkURL = URL(string: "veramo://auth?token=\(token)") {
                handleMagicLink(url: deepLinkURL)
            }
            return
        }
        
        print("❌ Unrecognized URL format")
    }
    
    private func handleMagicLink(url: URL) {
        print("🔗 handleMagicLink called with URL: \(url)")
        
        // Verify it's a veramo URL with auth host
        guard url.scheme == "veramo",
              url.host == "auth" else {
            print("❌ Invalid URL scheme or host: \(url)")
            return
        }
        
        print("✅ Valid veramo:// URL scheme")
        
        // Extract the token from query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
            print("❌ No token found in URL")
            errorMessage = "Invalid authentication link"
            showError = true
            return
        }
        
        print("✅ Token extracted: \(String(token.prefix(20)))...")
        
        // Verify token with your API
        Task {
            print("🌐 Calling verifyMagicLink API...")
            do {
                let (customer, sessionToken) = try await VeramoAuthService.shared.verifyMagicLink(token: token)
                
                print("✅ Successfully authenticated: \(customer.name)")
                print("📝 Session token: \(sessionToken)")
                
                // Update authentication state
                await MainActor.run {
                    print("🎬 Running on MainActor...")
                    
                    // Save authentication using the manager
                    AuthenticationManager.shared.saveAuthentication(
                        customer: customer,
                        sessionToken: sessionToken
                    )
                    
                    // Mark welcome screen as seen when successfully authenticated
                    hasSeenWelcome = true
                    print("✅ Set hasSeenWelcome to true after authentication")
                    
                    appState.login()
                }
            } catch {
                print("❌ Authentication failed: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to authenticate: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}
