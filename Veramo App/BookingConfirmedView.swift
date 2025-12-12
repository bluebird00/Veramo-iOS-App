//
//  BookingConfirmedView.swift
//  Veramo App
//
//  Booking confirmation page shown after successful payment
//

import SwiftUI

struct BookingConfirmedView: View {
    let reference: String
    @Binding var selectedTab: MainTabView.Tab
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: reference)
                
                // Title
                VStack(spacing: 8) {
                    Text("Booking Confirmed!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Reference: \(reference)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                
                // Information Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("What's Next?")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    InfoRow(
                        icon: "envelope.fill",
                        text: "Check your email for confirmation"
                    )
                    
                    InfoRow(
                        icon: "bell.fill",
                        text: "We'll notify you with driver details"
                    )
                    
                    InfoRow(
                        icon: "phone.fill",
                        text: "Your driver will contact you before pickup"
                    )
                    
                    InfoRow(
                        icon: "car.fill",
                        text: "Track your ride on the day of travel"
                    )
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Primary Button - See Upcoming Trips
                    Button {
                        selectedTab = .trips  // Switch to trips tab
                        dismiss()
                    } label: {
                        Label("See Upcoming Trips", systemImage: "calendar")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Secondary Button - Done
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                        
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(24)
            .navigationTitle("Success")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()  // Prevent accidental dismissal
        }
    }
}

// MARK: - Supporting Views

private struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
             
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    BookingConfirmedView(
        reference: "VRM-1234-5678",
        selectedTab: .constant(.home)
    )
}
