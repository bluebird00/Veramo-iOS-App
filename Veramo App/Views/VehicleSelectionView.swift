//
//  VehicleSelectionView.swift
//  Veramo App
//
//  Created by rentamac on 12/6/25.
//

import SwiftUI

struct VehicleSelectionView: View {
    let pickup: String
    let destination: String
    let date: Date
    let time: Date
    let passengers: Int
    
    @State private var selectedVehicle: VehicleType?
    @State private var showBookingDetails = false
    
    private let vehicleTypes: [VehicleType] = [
        VehicleType(
            name: "Business",
            description: "Mercedes E-Class or similar",
            maxPassengers: 3
        ),
        VehicleType(
            name: "First Class",
            description: "Mercedes S-Class or similar",
            maxPassengers: 3
        ),
        VehicleType(
            name: "XL",
            description: "Mercedes V-Class or similar",
            maxPassengers: 6
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Trip summary
            VStack(alignment: .leading, spacing: 12) {
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
                            .lineLimit(1)
                        Text(destination)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
                
                Divider()
                
                HStack {
                    Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Spacer()
                    Label(time.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                    Spacer()
                    Label("\(passengers)", systemImage: "person.fill")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding()
            
            // Vehicle options
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(vehicleTypes) { vehicle in
                        VehicleOptionCard(
                            vehicle: vehicle,
                            isSelected: selectedVehicle?.id == vehicle.id,
                            onSelect: { selectedVehicle = vehicle }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Confirm button
            Button(action: confirmBooking) {
                Text("Confirm Booking")
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
            .disabled(selectedVehicle == nil)
            .opacity(selectedVehicle == nil ? 0.5 : 1)
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Select Vehicle")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .navigationDestination(isPresented: $showBookingDetails) {
            BookingDetailsView(
                pickup: pickup,
                destination: destination,
                date: date, time: time,
                passengers: passengers,
                vehicle: selectedVehicle ?? vehicleTypes[0]
            )
        }
    }
    
    private func confirmBooking() {
        showBookingDetails = true
    }
    
}

