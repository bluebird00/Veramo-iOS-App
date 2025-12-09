//
//  AuthenticationChoiceView.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import SwiftUI

/// Optional view that lets users choose between SMS or Email authentication
/// Use this in Veramo_AppApp.swift instead of SMSLoginView if you want both options
struct AuthenticationChoiceView: View {
    @State private var selectedMethod: AuthMethod = .sms
    
    enum AuthMethod {
        case sms
        case email
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
                
                Text("Choose how you'd like to sign in")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 48)
            
            // Method selector
            Picker("Authentication Method", selection: $selectedMethod) {
                Text("Phone Number").tag(AuthMethod.sms)
                Text("Email").tag(AuthMethod.email)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 32)
            
            // Show the appropriate login view
            Group {
                if selectedMethod == .sms {
                    SMSLoginView()
                } else {
                    LoginView()
                }
            }
            .transition(.opacity)
            .animation(.easeInOut, value: selectedMethod)
        }
    }
}

#Preview {
    AuthenticationChoiceView()
        .environment(AppState())
}
