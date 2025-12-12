//
//  MainTabView.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showBookingConfirmation = false
    @State private var bookingReference: String?
    
    enum Tab {
        case home
        case trips
        case chat
        case profile
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            TripsView()
                .tabItem {
                    Label("My Trips", systemImage: "calendar")
                }
                .tag(Tab.trips)
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(Tab.chat)
            
            ProfileView()
                .tabItem {
                    Label("Account", systemImage: "person.circle.fill")
                }
                .tag(Tab.profile)
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .sheet(isPresented: $showBookingConfirmation) {
            if let reference = bookingReference {
                BookingConfirmedView(
                    reference: reference,
                    selectedTab: $selectedTab
                )
            }
        }
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLink(_ url: URL) {
        print("📱 Received deep link: \(url.absoluteString)")
        
        // Verify it's our app's URL scheme
        guard url.scheme == "veramo" else {
            print("❌ Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }
        
        // Check the path/host
        switch url.host {
        case "booking-confirmed":
            handleBookingConfirmed(url)
            
        default:
            print("❌ Unknown deep link host: \(url.host ?? "nil")")
        }
    }
    
    private func handleBookingConfirmed(_ url: URL) {
        // Parse query parameters
        // Example: veramo://booking-confirmed?ref=VRM-1234
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("❌ No query parameters found in deep link")
            return
        }
        
        // Extract booking reference
        if let refItem = queryItems.first(where: { $0.name == "ref" }),
           let reference = refItem.value {
            
            print("✅ Booking confirmed: \(reference)")
            
            // Update state to show confirmation
            bookingReference = reference
            showBookingConfirmation = true
        } else {
            print("❌ No 'ref' parameter in deep link")
        }
    }
}

#Preview {
    MainTabView()
}
