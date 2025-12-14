//
//  MainTabView.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
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
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLink(_ url: URL) {
        print("📱 [MAINTAB] Received deep link: \(url.absoluteString)")
        
        // Verify it's our app's URL scheme
        guard url.scheme == "veramo" else {
            print("❌ [MAINTAB] Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }
        
        // Check the path/host
        switch url.host {
        case "booking-confirmed":
            // VehicleSelectionView handles booking-confirmed deep links during payment flow
            // MainTabView doesn't need to handle these anymore
            print("📱 [MAINTAB] Booking-confirmed deep link detected - VehicleSelectionView will handle it")
            
        default:
            print("❌ [MAINTAB] Unknown deep link host: \(url.host ?? "nil")")
        }
    }
}

#Preview {
    MainTabView()
}
