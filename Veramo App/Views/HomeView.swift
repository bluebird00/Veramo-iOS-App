//
//  HomeView.swift
//  Veramo App
//
//  Created by rentamac on 12/10/25.
//

import SwiftUI

struct HomeView: View {
    @State private var navigateToBooking = false
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Simple background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Top search bar
                VStack(spacing: 16) {
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Cards section
                    VStack(spacing: 12) {
                        // TWINT payment card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Easy payment with TWINT")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text("Pay securely and quickly with your TWINT app.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            Spacer()
                        }
                        .padding()
                        .frame(height: 150)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        
                        // Book a ride card
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Ready? Book a ride.")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button(action: {
                                navigateToBooking = true
                            }) {
                                Text("Book Ride")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.black)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.separator), lineWidth: 1)
                                    )
                            }
                        }
                        .padding()
                        .frame(height: 150)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
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
                
                // Debug button to show welcome screen
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Toggle hasSeenWelcome by resetting it
                        NotificationCenter.default.post(name: .resetWelcomeScreen, object: nil)
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                    }
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
