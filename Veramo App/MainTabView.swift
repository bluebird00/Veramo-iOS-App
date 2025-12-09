//
//  MainTabView.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .booking
    
    enum Tab {
        case booking
        case trips
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RideBookingView()
                .tabItem {
                    Label("Book", systemImage: "car.fill")
                }
                .tag(Tab.booking)
            
            TripsView()
                .tabItem {
                    Label("My Trips", systemImage: "calendar")
                }
                .tag(Tab.trips)
        }
    }
}

#Preview {
    MainTabView()
}
