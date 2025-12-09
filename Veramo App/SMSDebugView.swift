//
//  SMSDebugView.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import SwiftUI

/// DEBUG ONLY: A testing view that lets you bypass SMS and directly authenticate
/// Remove this file before production release!
#if DEBUG
struct SMSDebugView: View {
    @Environment(AppState.self) private var appState
    @State private var showDebugOptions = false
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    showDebugOptions.toggle()
                }) {
                    Image(systemName: "ladybug.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showDebugOptions) {
            NavigationView {
                List {
                    Section("Debug Authentication") {
                        Button("Login as Test User") {
                            loginAsTestUser()
                        }
                        
                        Button("Test API Endpoints") {
                            testAPIEndpoints()
                        }
                        
                        Button("Clear All Data") {
                            clearAllData()
                        }
                        .foregroundColor(.red)
                    }
                    
                    Section("Test Phone Numbers") {
                        Text("+41791234567")
                            .font(.system(.body, design: .monospaced))
                        Text("+14155551234")
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    Section("Test Codes") {
                        Text("111111 - Always valid in dev mode")
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .navigationTitle("🐛 Debug Options")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showDebugOptions = false
                        }
                    }
                }
            }
        }
    }
    
    private func loginAsTestUser() {
        // Create a test customer
        let testCustomer = AuthenticatedCustomer(
            id: 999,
            name: "Test User",
            email: "test@veramo.ch",
            phone: "+41791234567"
        )
        
        let testToken = "debug_session_token_12345"
        
        // Save authentication
        AuthenticationManager.shared.saveAuthentication(
            customer: testCustomer,
            sessionToken: testToken
        )
        
        // Mark welcome as seen
        AuthenticationManager.shared.hasSeenWelcome = true
        
        // Login
        appState.login()
        
        showDebugOptions = false
        
        print("🐛 DEBUG: Logged in as test user")
    }
    
    private func testAPIEndpoints() {
        Task {
            do {
                print("🐛 DEBUG: Testing SMS send endpoint...")
                let sendResponse = try await VeramoAuthService.shared.requestSMSCode(
                    phone: "+41791234567"
                )
                print("🐛 DEBUG: Send SMS response: \(sendResponse)")
                
                print("🐛 DEBUG: Testing SMS verify endpoint...")
                let (customer, token) = try await VeramoAuthService.shared.verifySMSCode(
                    phone: "+41791234567",
                    code: "111111"
                )
                print("🐛 DEBUG: Verify response - Customer: \(customer.name), Token: \(token)")
                
                await MainActor.run {
                    print("🐛 DEBUG: API test complete!")
                }
            } catch {
                print("🐛 DEBUG: API test failed: \(error)")
            }
        }
    }
    
    private func clearAllData() {
        // Clear authentication
        AuthenticationManager.shared.logout()
        
        // Reset welcome flag
        AuthenticationManager.shared.hasSeenWelcome = false
        
        // Logout from app state
        appState.logout()
        
        showDebugOptions = false
        
        print("🐛 DEBUG: All data cleared")
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        SMSDebugView()
            .environment(AppState())
    }
}
#endif
