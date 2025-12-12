//
//  SMSLoginView.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import SwiftUI
import Combine

struct SMSLoginView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedCountry = CountryCodeData.shared.getDefaultCountryCode()
    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var isLoading: Bool = false
    @State private var codeSent: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var countdown: Int = 0
    
    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var fullPhoneNumber: String {
        "\(selectedCountry.dialCode)\(phoneNumber.filter { $0.isNumber })"
    }
    
    var isPhoneValid: Bool {
        let digitsOnly = phoneNumber.filter { $0.isNumber }
        // Basic validation: at least 7 digits (can be adjusted per country)
        return digitsOnly.count >= 7 && digitsOnly.count <= 15
    }
    
    var isCodeValid: Bool {
        // 6-digit code
        let digitsOnly = verificationCode.filter { $0.isNumber }
        return digitsOnly.count == 6
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
                
                Text(codeSent ? "Enter verification code" : "Enter your phone number to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 48)
            
            if !codeSent {
                // Phone number input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    PhoneNumberInputView(
                        countryCode: $selectedCountry,
                        phoneNumber: $phoneNumber
                    )
                }
                .padding(.horizontal)
            } else {
                // Verification code input with OTP style
                VStack(spacing: 20) {
                    Text("We sent a 6-digit code to")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(selectedCountry.dialCode) \(phoneNumber)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Beautiful OTP Input
                    OTPInputView(
                        code: $verificationCode,
                        onComplete: verifyCode,
                        isLoading: isLoading
                    )
                    .padding(.horizontal, 20)
                    
                    HStack {
                        Button(action: {
                            codeSent = false
                            verificationCode = ""
                        }) {
                            Text("Change number")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if countdown > 0 {
                            Text("Resend in \(countdown)s")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Button(action: sendVerificationCode) {
                                Text("Resend code")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .disabled(isLoading)
                        }
                    }
                    .padding(.horizontal)
                }
                .onReceive(countdownTimer) { _ in
                    if countdown > 0 {
                        countdown -= 1
                    }
                }
            }
            
            Spacer()
            
            // Action Button - only show for phone number input
            if !codeSent {
                Button(action: sendVerificationCode) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isLoading ? "Sending..." : "Send Code")
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
                .disabled(!isPhoneValid || isLoading)
                .opacity(isPhoneValid && !isLoading ? 1 : 0.5)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func sendVerificationCode() {
        guard !isLoading else { return }
        
        print("📲 [UI] User tapped 'Send Code'")
        print("📲 [UI] Country: \(selectedCountry.country) (\(selectedCountry.dialCode))")
        print("📲 [UI] Phone number entered: \(phoneNumber)")
        print("📲 [UI] Full phone number: \(fullPhoneNumber)")
        
        isLoading = true
        
        Task {
            do {
                // Send the full phone number to the API
                print("📲 [UI] Calling requestSMSCode API...")
                let response = try await VeramoAuthService.shared.requestSMSCode(phone: fullPhoneNumber)
                
                await MainActor.run {
                    print("✅ [UI] SMS code sent successfully!")
                    print("✅ [UI] Server message: \(response.message)")
                    isLoading = false
                    if response.success {
                        codeSent = true
                        countdown = 60 // 60 second countdown before allowing resend
                        verificationCode = ""
                        print("✅ [UI] Switched to code entry screen")
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ [UI] Failed to send SMS code: \(error.localizedDescription)")
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func verifyCode() {
        guard !isLoading else { return }
        
        print("🔑 [UI] Auto-verify triggered")
        print("🔑 [UI] Country: \(selectedCountry.country) (\(selectedCountry.dialCode))")
        print("🔑 [UI] Phone number: \(phoneNumber)")
        print("🔑 [UI] Full phone number: \(fullPhoneNumber)")
        print("🔑 [UI] Code entered: \(verificationCode)")
        
        isLoading = true
        
        Task {
            do {
                print("🔑 [UI] Calling verifySMSCode API...")
                let (customer, sessionToken) = try await VeramoAuthService.shared.verifySMSCode(
                    phone: fullPhoneNumber,
                    code: verificationCode
                )
                
                await MainActor.run {
                    print("✅ [UI] Successfully authenticated via SMS!")
                    print("✅ [UI] Customer name: \(customer.name)")
                    print("✅ [UI] Customer ID: \(customer.id)")
                    print("✅ [UI] Customer email: \(customer.email)")
                    print("✅ [UI] Session token received: \(String(sessionToken.prefix(20)))...")
                    
                    // Save authentication
                    print("💾 [UI] Saving authentication to UserDefaults...")
                    AuthenticationManager.shared.saveAuthentication(
                        customer: customer,
                        sessionToken: sessionToken
                    )
                    
                    // Mark welcome as seen
                    print("👋 [UI] Marking welcome screen as seen...")
                    AuthenticationManager.shared.hasSeenWelcome = true
                    
                    // Update app state
                    print("🎬 [UI] Calling appState.login()...")
                    appState.login()
                    
                    print("🎉 [UI] Authentication complete! User logged in.")
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("❌ [UI] Failed to verify code: \(error.localizedDescription)")
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    SMSLoginView()
        .environment(AppState())
}
