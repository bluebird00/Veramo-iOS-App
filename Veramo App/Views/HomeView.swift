//
//  HomeView.swift
//  Veramo App
//
//  Created by rentamac on 12/10/25.
//

import SwiftUI

struct HomeView: View {
    @State private var navigateToBooking = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Simple background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Top search bar
                VStack {
                    Button(action: {
                        navigateToBooking = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            Text("Enter pickup location")
                                .foregroundColor(.gray)
                                .font(.body)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                        )
                        .padding()
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Veramo")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .navigationDestination(isPresented: $navigateToBooking) {
                RideBookingView(autoFocusPickup: true)
            }
        }
    }
}

#Preview {
    HomeView()
}
