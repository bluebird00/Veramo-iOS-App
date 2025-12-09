//
//  LoginView.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccessMessage: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo/Header
            VStack(spacing: 16) {
                Image(systemName: "car.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.black)
                
                Text("Welcome to Veramo")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Enter your email to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 48)
            
            // Email input
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                FormTextField(
                    placeholder: "your@email.com",
                    text: $email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
            }
            .padding(.horizontal)
            
            if showSuccessMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Check your email for the magic link!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 16)
            }
            
            Spacer()
            
            // Send Magic Link Button
            Button(action: sendMagicLink) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isLoading ? "Sending..." : "Send Magic Link")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.black, Color(.darkGray)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(!isEmailValid || isLoading)
            .opacity(isEmailValid && !isLoading ? 1 : 0.5)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func sendMagicLink() {
        guard !isLoading else { return }
        
        isLoading = true
        showSuccessMessage = false
        
        Task {
            do {
                let response = try await VeramoAuthService.shared.requestMagicLink(email: email)
                
                await MainActor.run {
                    isLoading = false
                    if response.success {
                        showSuccessMessage = true
                        // Clear email field after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            email = ""
                            showSuccessMessage = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
