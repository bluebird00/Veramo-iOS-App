//
//  BookingDetailsView.swift
//  Veramo App
//
//  Created by rentamac on 12/6/25.
//

import SwiftUI

struct BookingDetailsView: View {
    let pickup: String
    let destination: String
    let date: Date
    let time: Date
    let passengers: Int
    let vehicle: VehicleType
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    
    var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !phoneNumber.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Booking Overview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Booking Overview")
                        .font(.headline)
                    
                    // Route
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 10, height: 10)
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 2, height: 20)
                            Circle()
                                .fill(Color.black)
                                .frame(width: 10, height: 10)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text(pickup)
                                .font(.subheadline)
                                .lineLimit(2)
                            Text(destination)
                                .font(.subheadline)
                                .lineLimit(2)
                        }
                    }
                    
                    Divider()
                    
                    // Date, Time, Passengers
                    HStack {
                        Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        Spacer()
                        Label(time.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        Spacer()
                        Label("\(passengers)", systemImage: "person.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Vehicle
                    HStack(spacing: 12) {
                        
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vehicle.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(vehicle.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Contact Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Details")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        FormTextField(
                            placeholder: "First Name",
                            text: $firstName,
                            icon: "person.fill",
                            keyboardType: .default,
                            textContentType: .givenName
                        )
                        
                        FormTextField(
                            placeholder: "Last Name",
                            text: $lastName,
                            icon: "person.fill",
                            keyboardType: .default,
                            textContentType: .familyName
                        )
                        
                        FormTextField(
                            placeholder: "Email",
                            text: $email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )
                        
                        FormTextField(
                            placeholder: "Phone Number",
                            text: $phoneNumber,
                            icon: "phone.fill",
                            keyboardType: .phonePad,
                            textContentType: .telephoneNumber
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Send Request Button
                Button(action: sendRequest) {
                    Text("Send Request")
                        .font(.headline)
                        .fontWeight(.semibold)
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
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1 : 0.5)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Booking Details")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }
    
    private func sendRequest() {
        print("Sending request...")
        print("Name: \(firstName) \(lastName)")
        print("Email: \(email)")
        print("Phone: \(phoneNumber)")
        // Handle API call here
    }
}

