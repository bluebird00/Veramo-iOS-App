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
    let pickupEnglish: String  // For database/backend
    let destinationEnglish: String  // For database/backend
    let date: Date
    let time: Date
    let passengers: Int
    let vehicle: VehicleType
    
    // Optional place IDs if available from location search
    var pickupPlaceId: String? = nil
    var destinationPlaceId: String? = nil
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    
    // API state
    @State private var isLoading: Bool = false
    @State private var showSuccessView: Bool = false
    @State private var requestId: Int? = nil
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    // Payment state
    @State private var showPayment = false
    @State private var paymentUrl: URL?
    @State private var paymentId: String?
    @State private var isProcessingPayment = false
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Lifecycle
    
    init(pickup: String, destination: String, pickupEnglish: String, destinationEnglish: String, date: Date, time: Date, passengers: Int, vehicle: VehicleType, pickupPlaceId: String? = nil, destinationPlaceId: String? = nil) {
        self.pickup = pickup
        self.destination = destination
        self.pickupEnglish = pickupEnglish
        self.destinationEnglish = destinationEnglish
        self.date = date
        self.time = time
        self.passengers = passengers
        self.vehicle = vehicle
        self.pickupPlaceId = pickupPlaceId
        self.destinationPlaceId = destinationPlaceId
        
        // Pre-fill customer data if available
        if let customer = AuthenticationManager.shared.currentCustomer {
            _email = State(initialValue: customer.email)
            
            // Split name into first and last name
            let nameComponents = customer.name.components(separatedBy: " ")
            if nameComponents.count >= 2 {
                _firstName = State(initialValue: nameComponents.first ?? "")
                _lastName = State(initialValue: nameComponents.dropFirst().joined(separator: " "))
            } else {
                _firstName = State(initialValue: customer.name)
            }
            
            // Pre-fill phone if available from customer or saved preference
            if let phone = customer.phone {
                _phoneNumber = State(initialValue: phone)
            } else if let savedPhone = AuthenticationManager.shared.savedPhoneNumber {
                _phoneNumber = State(initialValue: savedPhone)
            }
        } else if let savedPhone = AuthenticationManager.shared.savedPhoneNumber {
            // Even if not authenticated, use saved phone
            _phoneNumber = State(initialValue: savedPhone)
        }
    }
    
    var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty
    }
    
    var body: some View {
        ZStack {
            if showSuccessView {
                successView
            } else {
                bookingFormView
            }
        }
        .alert("Request Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
            Button("Try Again") {
                sendRequest()
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Booking Form View
    
    private var bookingFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Date and Time card (reusing the same style)
                HStack {
                    Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Spacer()
                    Label(time.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Vehicle card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vehicle.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text(vehicle.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let price = vehicle.priceFormatted {
                            Text(price)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Contact Details - Name only
                VStack(spacing: 0) {
                    // Name Row - Side by Side
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            
                            TextField("First", text: $firstName)
                                .textContentType(.givenName)
                                .autocorrectionDisabled()
                        }
                        
                        Divider()
                            .frame(height: 20)
                            .padding(.horizontal, 8)
                        
                        TextField("Last", text: $lastName)
                            .textContentType(.familyName)
                            .autocorrectionDisabled()
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Send Request Button
                Button(action: sendRequest) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isLoading ? "Processing..." : "Continue to Payment")
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
                .disabled(!isFormValid || isLoading)
                .opacity(isFormValid && !isLoading ? 1 : 0.5)
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
        .disabled(isLoading)
        .fullScreenCover(item: Binding(
            get: { paymentUrl.map { PaymentURL(url: $0) } },
            set: { paymentUrl = $0?.url }
        )) { paymentURL in
            SafariView(url: paymentURL.url) {
                // Called when Safari is dismissed
                checkPaymentStatus()
            }
            .ignoresSafeArea()
        }
    }
    
    // Helper struct for identifiable URL
    private struct PaymentURL: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("Request Sent!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your trip request has been submitted successfully.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let requestId = requestId {
                    Text("Request ID: #\(requestId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            
            // Trip Summary
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 8, height: 8)
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 2, height: 16)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 8, height: 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(pickup)
                            .font(.caption)
                            .lineLimit(1)
                        Text(destination)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                
                Divider()
                
                HStack {
                    Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Spacer()
                    Label(time.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            // Done Button
            Button(action: {
                dismiss()
            }) {
                Text("Done")
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
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Helpers
    
    private func localizedPaymentDescription() -> String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        
        switch languageCode {
        case "de":
            return "Fahrt von \(pickup) nach \(destination)"
        case "fr":
            return "Voyage de \(pickup) à \(destination)"
        case "it":
            return "Viaggio da \(pickup) a \(destination)"
        case "es":
            return "Viaje desde \(pickup) hasta \(destination)"
        default:
            return "Trip from \(pickup) to \(destination)"
        }
    }
    
    // MARK: - API Call
    
    private func sendRequest() {
        // Prevent double-tap
        guard !isLoading else { return }
        
        isLoading = true
        
        // First, create payment
        Task {
            do {
                guard let sessionToken = AuthenticationManager.shared.sessionToken,
                      let priceCents = vehicle.priceCents else {
                    throw MolliePaymentError.serverError("Missing payment information")
                }
                
                // Create payment
                let (paymentId, checkoutUrl) = try await MolliePaymentService.shared.createPayment(
                    amount: priceCents,
                    description: localizedPaymentDescription(),
                    sessionToken: sessionToken,
                    metadata: [
                        "pickup": pickup,
                        "destination": destination,
                        "date": date.formatted(date: .abbreviated, time: .omitted),
                        "vehicle": vehicle.name
                    ]
                )
                
                // Store payment ID
                await MainActor.run {
                    self.paymentId = paymentId
                    self.isLoading = false
                    
                    // Open payment URL
                    if let url = URL(string: checkoutUrl) {
                        self.paymentUrl = url
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func checkPaymentStatus() {
        guard let paymentId = paymentId,
              let sessionToken = AuthenticationManager.shared.sessionToken else {
            return
        }
        
        isProcessingPayment = true
        
        Task {
            do {
                // Check payment status
                let status = try await MolliePaymentService.shared.checkPaymentStatus(
                    paymentId: paymentId,
                    sessionToken: sessionToken
                )
                
                await MainActor.run {
                    self.isProcessingPayment = false
                    
                    if status == "paid" {
                        // Payment successful - now submit booking
                        submitBooking()
                    } else if status == "canceled" || status == "failed" || status == "expired" {
                        self.errorMessage = "Payment \(status). Please try again."
                        self.showErrorAlert = true
                    } else {
                        // Payment still pending
                        self.errorMessage = "Payment is still processing. Please check your email for confirmation."
                        self.showErrorAlert = true
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isProcessingPayment = false
                    self.errorMessage = "Could not verify payment status"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func submitBooking() {
        isLoading = true
        
        // Build the request
        let customer = Customer(
            name: "\(firstName) \(lastName)",
            email: email,
            phone: phoneNumber
        )
        
        let pickupLocation = Location(
            description: pickupEnglish,  // Use English version for database
            place_id: pickupPlaceId
        )
        
        let destinationLocation = Location(
            description: destinationEnglish,  // Use English version for database
            place_id: destinationPlaceId
        )
        
        let trip = Trip(
            pickup: pickupLocation,
            destination: destinationLocation,
            dateTime: Date.combinedISO8601(date: date, time: time),
            passengers: passengers,
            flightNumber: nil,
            vehicleClass: vehicle.apiVehicleClass
        )
        
        let tripRequest = TripRequest(
            customer: customer,
            trip: trip
        )
        
        // Make the API call
        Task {
            do {
                let response = try await TripRequestService.shared.submitTripRequest(request: tripRequest)
                
                await MainActor.run {
                    isLoading = false
                    
                    if response.success == true {
                        // Save phone number for future bookings
                        AuthenticationManager.shared.savedPhoneNumber = phoneNumber
                        
                        requestId = response.requestId
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSuccessView = true
                        }
                    } else {
                        errorMessage = response.error ?? "Something went wrong. Please try again."
                        showErrorAlert = true
                    }
                }
            } catch let error as TripRequestError {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "An unexpected error occurred. Please try again."
                    showErrorAlert = true
                }
            }
        }
    }
}
