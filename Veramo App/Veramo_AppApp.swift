//
//  Veramo_AppApp.swift
//  Veramo App
//
//  Created by rentamac on 12/6/25.
//

import SwiftUI
import StreamChat
import StreamChatSwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let paymentReturnDetected = Notification.Name("paymentReturnDetected")
    static let resetWelcomeScreen = Notification.Name("resetWelcomeScreen")
}

@main
struct Veramo_AppApp: App {
    @State private var appState = AppState()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasSeenWelcome = AuthenticationManager.shared.hasSeenWelcome
    @State private var welcomeScreenOpacity: Double = 1.0
    
    init() {
        // Debug: Log initial state
        print("🚀 App initializing")
        print("📱 hasSeenWelcome from UserDefaults: \(AuthenticationManager.shared.hasSeenWelcome)")
        print("🔐 isAuthenticated from UserDefaults: \(AuthenticationManager.shared.isAuthenticated)")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content - always show MainTabView (browsing allowed without auth)
                MainTabView()
                    .environment(appState)
                .alert("Authentication Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {
                        // Force view refresh after alert dismissal
                        print("✅ Alert dismissed, ensuring logout state is applied")
                        appState.refreshAuthenticationState()
                    }
                } message: {
                    Text(errorMessage)
                }
                .onReceive(NotificationCenter.default.publisher(for: .userDidBecomeUnauthenticated)) { _ in
                    // Handle authentication error notification
                    print("🔔 Received userDidBecomeUnauthenticated notification")
                    
                    // Logout on main thread to ensure UI updates
                    Task { @MainActor in
                        appState.logout()
                        errorMessage = "Your session has expired. Please log in again."
                        showError = true
                        
                        // Force immediate view update
                        print("🔄 Forcing view refresh after logout")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .resetWelcomeScreen)) { _ in
                    // Handle welcome screen reset notification (DEBUG only)
                    print("🔔 Received resetWelcomeScreen notification")
                    Task { @MainActor in
                        hasSeenWelcome = false
                        AuthenticationManager.shared.hasSeenWelcome = false
                        print("🔄 DEBUG: Reset hasSeenWelcome to false")
                    }
                }
                
                // Welcome screen overlay - only show if BOTH conditions are true:
                // 1. User hasn't seen welcome before
                // 2. User is NOT authenticated
                if shouldShowWelcome {
                    WelcomeScreen(hasSeenWelcome: $hasSeenWelcome)
                        .opacity(welcomeScreenOpacity)
                        .zIndex(1)
                        .onAppear {
                            print("⚠️ Welcome screen IS showing!")
                            print("   hasSeenWelcome: \(hasSeenWelcome)")
                            print("   appState.isAuthenticated: \(appState.isAuthenticated)")
                        }
                }
                
               
            }
            .onChange(of: hasSeenWelcome) { oldValue, newValue in
                // Save the preference when it changes
                print("👀 hasSeenWelcome changed from \(oldValue) to \(newValue)")
                
                if newValue {
                    // Animate the welcome screen out
                    withAnimation(.easeOut(duration: 0.3)) {
                        welcomeScreenOpacity = 0
                    }
                    
                    // Remove it after animation completes
                    Task {
                        try? await Task.sleep(for: .milliseconds(300))
                        await MainActor.run {
                            AuthenticationManager.shared.hasSeenWelcome = newValue
                            print("💾 Saved to UserDefaults: \(AuthenticationManager.shared.hasSeenWelcome)")
                        }
                    }
                } else {
                    // Show welcome screen immediately
                    welcomeScreenOpacity = 1.0
                    AuthenticationManager.shared.hasSeenWelcome = newValue
                    print("💾 Saved to UserDefaults: \(AuthenticationManager.shared.hasSeenWelcome)")
                }
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
    // Only show on first launch, regardless of auth status (users can browse without auth)
    private var shouldShowWelcome: Bool {
        let show = !hasSeenWelcome
        print("🤔 Checking shouldShowWelcome: \(show) (hasSeenWelcome: \(hasSeenWelcome))")
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
        
        // Handle booking confirmation (veramo://booking-confirmed?ref=...)
        if url.scheme == "veramo" && url.host == "booking-confirmed" {
            print("✅ Booking confirmation deep link detected")
            print("   URL will be handled by MainTabView")
            // Let this pass through - MainTabView will handle it
            return
        }
        
        // Handle payment return (veramo://payment-return)
        if url.scheme == "veramo" && url.host == "payment-return" {
            print("💳 Payment return detected - posting notification")
            NotificationCenter.default.post(name: .paymentReturnDetected, object: nil)
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
