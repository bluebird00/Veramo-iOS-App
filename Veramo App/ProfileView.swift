//
//  ProfileView.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showLogoutConfirmation = false
    
    var customer: AuthenticatedCustomer? {
        AuthenticationManager.shared.currentCustomer
    }
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    if let customer = customer {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                // Avatar
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.black, Color(.darkGray)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 60, height: 60)
                                    .overlay {
                                        Text(customer.name.prefix(1).uppercased())
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(customer.name)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    Text("Customer ID: \(customer.id)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text("Profile")
                }
                
                // Contact Information
                Section {
                    if let customer = customer {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            Text(customer.email)
                                .font(.body)
                        }
                        
                        if let phone = customer.phone {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 24)
                                Text(phone)
                                    .font(.body)
                            }
                        }
                    }
                } header: {
                    Text("Contact Information")
                }
                
                // Account Section
                Section {
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Account")
                }
                
                // App Info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .alert("Logout", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
    
    private func performLogout() {
        print("🚪 [LOGOUT] User initiated logout")
        print("🗑️ [LOGOUT] Clearing session data...")
        
        withAnimation {
            appState.logout()
        }
        
        print("✅ [LOGOUT] Logout complete")
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
