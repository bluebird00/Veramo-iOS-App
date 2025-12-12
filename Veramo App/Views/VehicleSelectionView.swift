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
    
    // Payment and name state
    @State private var showNameModal = false
    @State private var showLegalModal = false
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var isProcessingPayment = false
    @State private var paymentUrl: URL?
    @State private var paymentId: String?
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    
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
        if isProcessingPayment {
            return String(localized: "Processing...")
        } else if let vehicle = selectedVehicle {
            return String(localized: "Select \(vehicle.name)")
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
            
            // Select vehicle button
            Button(action: continueToPayment) {
                HStack(spacing: 8) {
                    if isProcessingPayment {
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
            .disabled(selectedVehicle == nil || isProcessingPayment)
            .opacity(selectedVehicle != nil && !isProcessingPayment ? 1 : 0.5)
            .padding(.horizontal, 28)
            .padding(.top, 32)
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
        .sheet(isPresented: $showNameModal) {
            nameInputModal
        }
        .sheet(isPresented: $showLegalModal) {
            legalDisclaimerModal
        }
        .alert("Payment Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(item: Binding(
            get: { paymentUrl.map { PaymentURL(url: $0) } },
            set: { paymentUrl = $0?.url }
        )) { paymentURL in
            SafariView(url: paymentURL.url) {
                // Called when Safari is dismissed
                // You can add payment status checking here if needed
            }
            .ignoresSafeArea()
        }
    }
    
    // Helper struct for identifiable URL
    private struct PaymentURL: Identifiable {
        let id = UUID()
        let url: URL
    }
    
    // Name input modal
    private var nameInputModal: some View {
        VStack(spacing: 24) {
            Text("Enter Your Name")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
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
                    .fill(Color(.systemGray6))
            )
            
            Button(action: {
                showNameModal = false
                showLegalModal = true
            }) {
                Text("Continue")
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
            .disabled(firstName.isEmpty || lastName.isEmpty)
            .opacity(firstName.isEmpty || lastName.isEmpty ? 0.5 : 1)
        }
        .padding()
        .presentationDetents([.height(280)])
    }
    
    // Legal disclaimer modal
    private var legalDisclaimerModal: some View {
        VStack(spacing: 24) {
            Text("Important Information")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Important information about the transport operator")
                    .font(.headline)
                
                Text("The transportation contract is concluded between you and the independent partner.\n\nVeramo itself is not a transportation service provider and acts solely as an intermediary between you and the independent partner.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: {
                showLegalModal = false
                initiatePayment()
            }) {
                Text("Continue")
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
        }
        .padding()
        .presentationDetents([.height(400)])
    }
    
    private func continueToPayment() {
        // Check if we have first and last name
        if firstName.isEmpty || lastName.isEmpty {
            showNameModal = true
        } else {
            // Show legal disclaimer before payment
            showLegalModal = true
        }
    }
    
    private func initiatePayment() {
        guard let selectedVehicle = selectedVehicle,
              let priceCents = selectedVehicle.priceCents,
              let sessionToken = AuthenticationManager.shared.sessionToken else {
            errorMessage = "Missing payment information"
            showErrorAlert = true
            return
        }
        
        isProcessingPayment = true
        
        Task {
            do {
                let (paymentId, checkoutUrl) = try await MolliePaymentService.shared.createPayment(
                    amount: priceCents,
                    description: "Trip from \(pickup) to \(destination)",
                    sessionToken: sessionToken,
                    metadata: [
                        "pickup": pickup,
                        "destination": destination,
                        "date": date.formatted(date: .abbreviated, time: .omitted),
                        "vehicle": selectedVehicle.name
                    ]
                )
                
                await MainActor.run {
                    self.paymentId = paymentId
                    self.isProcessingPayment = false
                    
                    if let url = URL(string: checkoutUrl) {
                        self.paymentUrl = url
                        // Open payment URL (you'll need to add SafariView handling)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isProcessingPayment = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
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



