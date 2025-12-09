//
//  DebugMenu.swift
//  Veramo App
//
//  Created by rentamac on 12/8/25.
//
//  Debug helper for development - Remove before production!
//

import SwiftUI

struct DebugMenu: View {
    @Binding var hasSeenWelcome: Bool
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🛠️ Debug Menu")
                .font(.title2)
                .fontWeight(.bold)
            
            Button(action: {
                showConfirmation = true
            }) {
                Label("Reset Welcome Screen", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Current State:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Has Seen Welcome: \(hasSeenWelcome ? "Yes" : "No")")
                    .font(.caption)
                Text("Is Authenticated: \(AuthenticationManager.shared.isAuthenticated ? "Yes" : "No")")
                    .font(.caption)
                if let customer = AuthenticationManager.shared.currentCustomer {
                    Text("User: \(customer.name)")
                        .font(.caption)
                }
            }
        }
        .padding()
        .confirmationDialog("Reset Welcome Screen?", isPresented: $showConfirmation) {
            Button("Reset & Restart App", role: .destructive) {
                AuthenticationManager.shared.hasSeenWelcome = false
                hasSeenWelcome = false
                // Note: You may need to force restart the app to see the welcome screen again
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset the welcome screen. You may need to restart the app to see it again.")
        }
    }
}

// MARK: - Debug Button Overlay

/// Add this as an overlay to your main view during development
struct DebugButton: View {
    @Binding var hasSeenWelcome: Bool
    @State private var showDebugMenu = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    showDebugMenu.toggle()
                }) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
            Spacer()
        }
        .sheet(isPresented: $showDebugMenu) {
            DebugMenu(hasSeenWelcome: $hasSeenWelcome)
                .presentationDetents([.medium])
        }
    }
}

#Preview {
    DebugMenu(hasSeenWelcome: .constant(true))
}
