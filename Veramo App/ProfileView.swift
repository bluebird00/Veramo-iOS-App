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
    @State private var showEditProfile = false
    @State private var showLoginSheet = false
    @State private var editName: String = ""
    @State private var editEmail: String = ""
    @State private var isUpdating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var customer: AuthenticatedCustomer? {
        let customer = AuthenticationManager.shared.currentCustomer
        print("👤 [ProfileView] Getting customer: \(customer?.name ?? "nil")")
        print("🔐 [ProfileView] Auth state - isAuthenticated: \(appState.isAuthenticated)")
        return customer
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
                                        Text((customer.name?.prefix(1) ?? "?").uppercased())
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    if customer.name != nil {
                                        Text(customer.name!)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    } else {
                                        Button(action: {
                                            prepareEditProfile()
                                        }) {
                                            Text("Complete your profile")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    LinearGradient(
                                                        colors: [.black, Color(.darkGray)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                // Edit button for existing profiles
                                if customer.name != nil {
                                    Button(action: {
                                        prepareEditProfile()
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.black)
                                            .opacity(0.5)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        // Not logged in - show login prompt
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sign in to your account")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("Track your trips, save your preferences, and book rides faster.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                showLoginSheet = true
                            }) {
                                Text("Sign In")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [.black, Color(.darkGray)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Profile")
                }
                
                // Contact Information (only show if logged in)
                if customer != nil {
                    Section {
                        if let customer = customer {
                            if let email = customer.email {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.gray)
                                        .frame(width: 24)
                                    Text(email)
                                        .font(.body)
                                }
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
                }
                
                // Account Section (only show if logged in)
                if customer != nil {
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
                
                // Developer Tools (Debug builds only)
                #if DEBUG
                Section {
                    NavigationLink {
                        NotificationTestView()
                    } label: {
                        Label("Test Notifications", systemImage: "bell.badge")
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("These tools are only available in debug builds.")
                }
                #endif
            }
            .navigationTitle("Account")
            .alert("Logout", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    performLogout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showEditProfile) {
                NavigationView {
                    Form {
                        Section {
                            TextField("Name", text: $editName)
                                .textContentType(.name)
                                .autocapitalization(.words)
                            
                            TextField("Email", text: $editEmail)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        } header: {
                            Text("Profile Information")
                        } footer: {
                            Text("Your name and email help us provide better service.")
                        }
                    }
                    .navigationTitle("Edit Profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showEditProfile = false
                            }
                            .disabled(isUpdating)
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button(action: saveProfile) {
                                if isUpdating {
                                    ProgressView()
                                } else {
                                    Text("Save")
                                        .fontWeight(.semibold)
                                }
                            }
                            .disabled(isUpdating || editName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showLoginSheet) {
                SMSLoginView()
                    .environment(appState)
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
    
    private func prepareEditProfile() {
        // Pre-fill with current values
        editName = customer?.name ?? ""
        editEmail = customer?.email ?? ""
        showEditProfile = true
    }
    
    private func saveProfile() {
        guard !isUpdating else { return }
        guard let sessionToken = AuthenticationManager.shared.sessionToken else {
            errorMessage = "Session expired. Please log in again."
            showError = true
            return
        }
        
        let trimmedName = editName.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = editEmail.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Name is required"
            showError = true
            return
        }
        
        print("💾 [PROFILE] Saving profile...")
        print("💾 [PROFILE] Name: \(trimmedName)")
        print("💾 [PROFILE] Email: \(trimmedEmail)")
        
        isUpdating = true
        
        Task {
            do {
                let updatedCustomer = try await VeramoAuthService.shared.updateProfile(
                    sessionToken: sessionToken,
                    name: trimmedName.isEmpty ? nil : trimmedName,
                    email: trimmedEmail.isEmpty ? nil : trimmedEmail
                )
                
                await MainActor.run {
                    print("✅ [PROFILE] Profile updated successfully!")
                    print("✅ [PROFILE] New name: \(updatedCustomer.name ?? "nil")")
                    print("✅ [PROFILE] New email: \(updatedCustomer.email ?? "nil")")
                    
                    isUpdating = false
                    showEditProfile = false
                }
            } catch {
                await MainActor.run {
                    print("❌ [PROFILE] Failed to update profile: \(error.localizedDescription)")
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
