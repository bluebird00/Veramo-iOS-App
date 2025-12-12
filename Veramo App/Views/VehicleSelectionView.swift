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
    let pickupEnglish: String  // For database/backend
    let destinationEnglish: String  // For database/backend
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
    
    @Binding var showVehicleSelection: Bool  // To control parent view state
    
    // Booking state
    @State private var isProcessingBooking = false
    @State private var checkoutUrl: URL?
    @State private var bookingReference: String?
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    @State private var showSessionExpiredAlert = false
    @State private var showBookingConfirmed = false
    
    // Optional flight number
    @State private var flightNumber: String = ""
    @State private var showFlightNumberInput = false
    
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
    
    init(pickup: String, destination: String, pickupEnglish: String, destinationEnglish: String, date: Date, time: Date, passengers: Int, pickupPlaceId: String? = nil, destinationPlaceId: String? = nil, showVehicleSelection: Binding<Bool>) {
        self.pickup = pickup
        self.destination = destination
        self.pickupEnglish = pickupEnglish
        self.destinationEnglish = destinationEnglish
        self.date = date
        self.time = time
        self.passengers = passengers
        self.pickupPlaceId = pickupPlaceId
        self.destinationPlaceId = destinationPlaceId
        self._showVehicleSelection = showVehicleSelection
    }
    
    // Swiss timezone constant
    private static let swissTimeZone = TimeZone(identifier: "Europe/Zurich") ?? .current
    
    // Formatted date in Swiss timezone
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = Self.swissTimeZone
        return formatter.string(from: date)
    }
    
    // Formatted time in Swiss timezone
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = Self.swissTimeZone
        return formatter.string(from: time)
    }
    
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
    
    // Dynamic button text based on selected vehicle
    private var buttonText: String {
        if isProcessingBooking {
            return String(localized: "Processing...")
        } else if let vehicle = selectedVehicle {
            return String(localized: "Book \(vehicle.name)")
        } else {
            return String(localized: "Select Vehicle")
        }
    }
    
    var body: some View {
        // Vehicle Selection
        VStack(spacing: 0) {
            // Trip summary - only date and time
            HStack {
                Label(formattedDate, systemImage: "calendar")
                Spacer()
                Label(formattedTime, systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
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
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Optional flight number input
            if showFlightNumberInput {
                HStack(spacing: 8) {
                    Image(systemName: "airplane")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    
                    TextField("Flight number (optional)", text: $flightNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 8)
            } else {
                Button(action: { showFlightNumberInput = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "airplane")
                            .font(.footnote)
                        Text("Add flight number")
                            .font(.footnote)
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 8)
            }
            
            // Book now button
            VStack(spacing: 8) {
                Button(action: createBooking) {
                    HStack(spacing: 8) {
                        if isProcessingBooking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(buttonText)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.black, Color(.darkGray)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(selectedVehicle == nil || isProcessingBooking)
                .opacity(selectedVehicle != nil && !isProcessingBooking ? 1 : 0.5)
                
                #if DEBUG
                // Debug button to test confirmation view without payment
                Button(action: testBookingConfirmation) {
                    Text("🧪 Test Confirmation (Debug)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .disabled(selectedVehicle == nil)
                .opacity(selectedVehicle != nil ? 1 : 0.5)
                #endif
            }
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 5)
        }
        .task {
            await fetchPricing()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showVehicleSelection = false
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                    }
                }
            }
        }
        .alert("Booking Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Session Expired", isPresented: $showSessionExpiredAlert) {
            Button("Log In Again", role: .cancel) {
                // Navigate back and trigger re-authentication
                showVehicleSelection = false
            }
        } message: {
            Text("Your session has expired. Please log in again to continue.")
        }
        .fullScreenCover(item: Binding(
            get: { checkoutUrl.map { CheckoutURL(url: $0, reference: bookingReference) } },
            set: { checkoutUrl = $0?.url }
        )) { checkout in
            SafariView(url: checkout.url) {
                // Called when Safari is dismissed
                // The booking is confirmed automatically once payment completes
                print("📱 [BOOKING] Payment browser dismissed")
                print("📱 [BOOKING] Booking reference: \(checkout.reference ?? "N/A")")
                
                // Show booking confirmation
                showBookingConfirmed = true
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showBookingConfirmed) {
            // When confirmation is dismissed, navigate back to home
            showVehicleSelection = false
        } content: {
            if let reference = bookingReference {
                BookingConfirmedViewContent(
                    reference: reference,
                    onDismiss: {
                        showBookingConfirmed = false
                        showVehicleSelection = false
                    }
                )
                .onAppear {
                    print("✅ [DEBUG] BookingConfirmedViewContent appeared with reference: \(reference)")
                }
            } else {
                // Fallback if reference is nil
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    Text("Error: No booking reference")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Button("Close") {
                        showBookingConfirmed = false
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .onAppear {
                    print("❌ [DEBUG] ERROR: Showing fallback - bookingReference is nil!")
                }
            }
        }
    }
    
    // Helper struct for identifiable URL with reference
    private struct CheckoutURL: Identifiable {
        let id = UUID()
        let url: URL
        let reference: String?
    }
    
    // MARK: - Booking Action
    
    private func createBooking() {
        guard let selectedVehicle = selectedVehicle else {
            return
        }
        
        // Validate we have place IDs
        guard let pickupPlaceId = pickupPlaceId,
              let destinationPlaceId = destinationPlaceId else {
            errorMessage = "Location information is missing. Please go back and select locations again."
            showErrorAlert = true
            return
        }
        
        // Validate we have a session token
        guard let sessionToken = AuthenticationManager.shared.sessionToken else {
            errorMessage = "You are not logged in. Please log in to continue."
            showErrorAlert = true
            return
        }
        
        isProcessingBooking = true
        
        Task {
            do {
                // Combine date and time into a single datetime in Switzerland timezone
                let swissTimeZone = TimeZone(identifier: "Europe/Zurich")!
                
                // IMPORTANT: Extract components in the SWISS timezone, not local device timezone
                // This ensures the user's selected date/time is interpreted correctly
                var swissCalendar = Calendar.current
                swissCalendar.timeZone = swissTimeZone
                
                let dateComponents = swissCalendar.dateComponents([.year, .month, .day], from: date)
                let timeComponents = swissCalendar.dateComponents([.hour, .minute], from: time)
                
                var combinedComponents = DateComponents()
                combinedComponents.year = dateComponents.year
                combinedComponents.month = dateComponents.month
                combinedComponents.day = dateComponents.day
                combinedComponents.hour = timeComponents.hour
                combinedComponents.minute = timeComponents.minute
                combinedComponents.second = 0
                combinedComponents.timeZone = swissTimeZone
                
                guard let pickupDateTime = swissCalendar.date(from: combinedComponents) else {
                    throw BookingError.serverError("Failed to create pickup datetime")
                }
                
                // Debug: Log the datetime details
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                formatter.timeZone = swissTimeZone
                let swissTimeString = formatter.string(from: pickupDateTime)
                
                formatter.timeZone = TimeZone(identifier: "UTC")
                let utcTimeString = formatter.string(from: pickupDateTime)
                
                let now = Date()
                let hoursFromNow = pickupDateTime.timeIntervalSince(now) / 3600
                
                print("📅 [BOOKING] DateTime Validation:")
                print("   • Selected date: \(date)")
                print("   • Selected time: \(time)")
                print("   • Combined (Swiss): \(swissTimeString)")
                print("   • Combined (UTC): \(utcTimeString)")
                print("   • Current time: \(formatter.string(from: now))")
                print("   • Hours from now: \(String(format: "%.2f", hoursFromNow))")
                
                // Validate minimum advance time locally before sending to backend
                if hoursFromNow < 4 {
                    throw BookingError.validationError("Booking must be at least 4 hours in the future. Currently \(String(format: "%.1f", hoursFromNow)) hours ahead.")
                }
                
                // Determine vehicle class
                let vehicleClass = selectedVehicle.name.toVehicleClass
                
                // Create booking with redirect URL for deep linking
                let response = try await BookingService.shared.createBooking(
                    pickupPlaceId: pickupPlaceId,
                    pickupDescription: pickup,
                    destinationPlaceId: destinationPlaceId,
                    destinationDescription: destination,
                    dateTime: pickupDateTime,
                    passengers: passengers,
                    vehicleClass: vehicleClass,
                    flightNumber: flightNumber.isEmpty ? nil : flightNumber,
                    redirectUrl: "veramo://booking-confirmed",  // Deep link back to app after payment
                    sessionToken: sessionToken
                )
                
                await MainActor.run {
                    isProcessingBooking = false
                    
                    if let checkoutUrlString = response.checkoutUrl,
                       let url = URL(string: checkoutUrlString) {
                        // Save the booking reference
                        let reference = response.quoteReference ?? "UNKNOWN"
                        bookingReference = reference
                        checkoutUrl = url
                        
                        print("✅ [BOOKING] Booking created successfully!")
                        print("   • Reference: \(reference)")
                        print("   • Opening checkout URL...")
                    } else {
                        errorMessage = "Booking created but no payment URL was provided"
                        showErrorAlert = true
                    }
                }
            } catch let error as BookingError {
                await MainActor.run {
                    isProcessingBooking = false
                    
                    if case .unauthorized = error {
                        // Session expired - show special alert
                        showSessionExpiredAlert = true
                    } else {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessingBooking = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Debug Testing
    
    #if DEBUG
    /// Test function to simulate a successful booking without actual payment
    private func testBookingConfirmation() {
        // Generate a fake booking reference
        let testReference = "TEST-\(Int.random(in: 1000...9999))-\(Int.random(in: 1000...9999))"
        
        print("🧪 [DEBUG] Simulating booking confirmation with reference: \(testReference)")
        
        // Set the reference and show confirmation
        bookingReference = testReference
        
        // Small delay to ensure state is set
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🧪 [DEBUG] bookingReference is now: \(self.bookingReference ?? "nil")")
            print("🧪 [DEBUG] About to show booking confirmed sheet")
            self.showBookingConfirmed = true
        }
    }
    #endif
    
    private func fetchPricing() async {
        isLoadingPricing = true
        pricingError = nil
        
        do {
            // Use Switzerland timezone for the final datetime
            let swissTimeZone = TimeZone(identifier: "Europe/Zurich")!
            
            // IMPORTANT: Extract date components in SWISS timezone, not local device timezone
            // This ensures the user's selected date/time is interpreted correctly
            var swissCalendar = Calendar.current
            swissCalendar.timeZone = swissTimeZone
            
            let dateComponents = swissCalendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = swissCalendar.dateComponents([.hour, .minute], from: time)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            combinedComponents.second = 0
            combinedComponents.timeZone = swissTimeZone
            
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



