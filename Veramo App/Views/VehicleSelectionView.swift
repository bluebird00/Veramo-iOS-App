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
    
    // Optional place IDs from location search
    var pickupPlaceId: String? = nil
    var destinationPlaceId: String? = nil
    
    @State private var selectedVehicle: VehicleType?
    @State private var showBookingDetails = false
    @State private var isLoadingPricing = false
    @State private var pricingError: String?
    @State private var pricingResponse: PricingResponse?
    
    private let vehicleTypes: [VehicleType] = [
        VehicleType(
            name: "Business",
            description: "Mercedes E-Class or similar",
            maxPassengers: 3,
            imageName: "business-car",
            useSystemImage: false
        ),
        VehicleType(
            name: "First Class",
            description: "Mercedes S-Class or similar",
            maxPassengers: 3,
            imageName: "first-car",
            useSystemImage: false
        ),
        VehicleType(
            name: "XL",
            description: "Mercedes V-Class or similar",
            maxPassengers: 6,
            imageName: "xl-car",
            useSystemImage: false
        )
    ]
    
    // Filter vehicles based on passenger count and add pricing
    private var availableVehicles: [VehicleType] {
        vehicleTypes.filter { vehicle in
            vehicle.maxPassengers >= passengers
        }.map { vehicle in
            var updatedVehicle = vehicle
            
            // Add pricing from the response
            if let pricingResponse = pricingResponse {
                switch vehicle.name {
                case "Business":
                    updatedVehicle.priceFormatted = pricingResponse.prices.business.priceFormatted
                    updatedVehicle.priceCents = pricingResponse.prices.business.priceCents
                case "First Class":
                    updatedVehicle.priceFormatted = pricingResponse.prices.first.priceFormatted
                    updatedVehicle.priceCents = pricingResponse.prices.first.priceCents
                case "XL":
                    updatedVehicle.priceFormatted = pricingResponse.prices.xl.priceFormatted
                    updatedVehicle.priceCents = pricingResponse.prices.xl.priceCents
                default:
                    break
                }
            }
            
            return updatedVehicle
        }
    }
    
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
                    if isLoadingPricing {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Calculating pricing...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let error = pricingError {
                        // Error state
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            Text("Failed to load pricing")
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task {
                                    await fetchPricing()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                    } else {
                        // Vehicle cards
                        ForEach(availableVehicles) { vehicle in
                            VehicleOptionCard(
                                vehicle: vehicle,
                                isSelected: selectedVehicle?.id == vehicle.id,
                                onSelect: { selectedVehicle = vehicle }
                            )
                        }
                        
                        // Trip info from pricing response
                        if let pricingResponse = pricingResponse {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Trip Details")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                HStack {
                                    Label("\(String(format: "%.1f", pricingResponse.distanceKm)) km", systemImage: "map")
                                    Spacer()
                                    Label("\(pricingResponse.durationMinutes) min", systemImage: "clock")
                                }
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                
                                if pricingResponse.pickup.totalAdjustmentPercent != 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: pricingResponse.pickup.totalAdjustmentPercent > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                            .foregroundColor(pricingResponse.pickup.totalAdjustmentPercent > 0 ? .orange : .green)
                                        Text("\(abs(pricingResponse.pickup.totalAdjustmentPercent))% \(pricingResponse.pickup.totalAdjustmentPercent > 0 ? "surcharge" : "discount")")
                                        if pricingResponse.pickup.isWeekend {
                                            Text("• Weekend")
                                        }
                                        if pricingResponse.pickup.isNight {
                                            Text("• Night")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
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
        .task {
            await fetchPricing()
        }
        .navigationDestination(isPresented: $showBookingDetails) {
            BookingDetailsView(
                pickup: pickup,
                destination: destination,
                date: date, time: time,
                passengers: passengers,
                vehicle: selectedVehicle ?? vehicleTypes[0],
                pickupPlaceId: pickupPlaceId,
                destinationPlaceId: destinationPlaceId
            )
        }
    }
    
    private func confirmBooking() {
        showBookingDetails = true
    }
    
    private func fetchPricing() async {
        isLoadingPricing = true
        pricingError = nil
        
        do {
            // Use Switzerland timezone for the final datetime
            let swissTimeZone = TimeZone(identifier: "Europe/Zurich")!
            
            // Extract date components using LOCAL calendar (to get what user sees)
            var localCalendar = Calendar.current
            localCalendar.timeZone = TimeZone.current
            
            let dateComponents = localCalendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = localCalendar.dateComponents([.hour, .minute], from: time)
            
            // Create combined components in SWITZERLAND timezone
            var swissCalendar = Calendar.current
            swissCalendar.timeZone = swissTimeZone
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour  // Use the hour/minute user SEES
            combinedComponents.minute = timeComponents.minute
            combinedComponents.second = 0
            combinedComponents.timeZone = swissTimeZone  // But interpret as Switzerland time
            
            guard let pickupDatetime = swissCalendar.date(from: combinedComponents) else {
                throw PricingError.serverError("Failed to create pickup datetime")
            }
            
            // Try to use place IDs first, if available
            if let pickupId = pickupPlaceId, let destinationId = destinationPlaceId {
                pricingResponse = try await PricingService.shared.fetchPricing(
                    originPlaceId: pickupId,
                    destinationPlaceId: destinationId,
                    pickupDatetime: pickupDatetime
                )
            } else {
                // Fallback: Show error since we need place IDs or coordinates
                throw PricingError.missingLocationData
            }
            
            isLoadingPricing = false
        } catch {
            isLoadingPricing = false
            pricingError = error.localizedDescription
        }
    }
    
}

// MARK: - Preview
#Preview {
    VehicleSelectionView(
        pickup: "kulm",
        destination: "zrh",
        date: Date(timeIntervalSince1970: 1788825600),
        time: Date(timeIntervalSince1970: 1788825600),
        passengers: 3
    )
}

