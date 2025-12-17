//
//  VehicleSelectionView.swift
//  Veramo App
//
//  Created by rentamac on 12/6/25.
//

import SwiftUI
import SafariServices
import MapKit

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
    @State private var isLoadingPricing = true
    @State private var pricingError: String?
    @State private var pricingResponse: PricingResponse?
    @State private var sheetHeight: CGFloat = 0
    @State private var renderedVehicles: [VehicleType] = []  // Track what's actually rendered
    
    @Binding var showVehicleSelection: Bool  // To control parent view state
    @Binding var isCompactMode: Bool  // Controlled by parent sheet drag gesture
    let isDragging: Bool  // Track if parent is currently dragging
    
    // Authentication state
    @Environment(AppState.self) private var appState
    @State private var showLoginSheet = false
    
    // Booking state
    @State private var isProcessingBooking = false
    @State private var checkoutUrl: URL?
    @State private var bookingReference: String?
    @State private var quoteToken: String?  // Token for checking payment status
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
            description: String(localized: "Mercedes E-Class or similar", comment: "Description for Business vehicle class"),
            maxPassengers: 3,
            imageName: "business-car",
            useSystemImage: false
        ),
        VehicleType(
            name: "First Class",
            description: String(localized: "Mercedes S-Class or similar", comment: "Description for First Class vehicle"),
            maxPassengers: 3,
            imageName: "first-car",
            useSystemImage: false
        ),
        VehicleType(
            name: "XL",
            description: String(localized: "Mercedes V-Class or similar", comment: "Description for XL vehicle class"),
            maxPassengers: 6,
            imageName: "xl-car",
            useSystemImage: false
        )
    ]
    
    init(pickup: String, destination: String, pickupEnglish: String, destinationEnglish: String, date: Date, time: Date, passengers: Int, pickupPlaceId: String? = nil, destinationPlaceId: String? = nil, showVehicleSelection: Binding<Bool>, isCompactMode: Binding<Bool>, isDragging: Bool = false) {
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
        self._isCompactMode = isCompactMode
        self.isDragging = isDragging
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
    
    // Vehicles to display based on sheet state
    private var displayedVehicles: [VehicleType] {
        // During drag, always show all vehicles for smooth expansion
        if isDragging {
            return availableVehicles
        }
        
        // When in compact mode (not dragging) and a vehicle is selected, show only that one
        if isCompactMode, let selected = selectedVehicle {
            return availableVehicles.filter { $0.name == selected.name }
        }
        
        // Otherwise show all available vehicles
        return availableVehicles
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
        GeometryReader { geometry in
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
                            // Vehicle cards - use renderedVehicles which doesn't change during drag
                            LazyVStack(spacing: 12) {
                                ForEach(renderedVehicles) { vehicle in
                                    VehicleOptionCard(
                                        vehicle: vehicle,
                                        isSelected: selectedVehicle?.name == vehicle.name,
                                        onSelect: {
                                            withAnimation(.linear(duration: 0.15)) {
                                                selectedVehicle = vehicle
                                            }
                                        }
                                    )
                                    .simultaneousGesture(
                                        TapGesture()
                                            .onEnded { _ in
                                                withAnimation(.linear(duration: 0.15)) {
                                                    selectedVehicle = vehicle
                                                }
                                            }
                                    )
                                    .id(vehicle.name) // Add ID for smooth transitions
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear
                                .preference(
                                    key: ViewHeightKey.self,
                                    value: scrollGeometry.size.height
                                )
                        }
                    )
                }
                .scrollIndicators(.hidden)
                
                
                
                
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
                    
                    
                    
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)
                .padding(.bottom, 5)
            }
            .onAppear {
                sheetHeight = geometry.size.height
                // Initialize rendered vehicles
                renderedVehicles = displayedVehicles
            }
            .onChange(of: geometry.size.height) { oldValue, newValue in
                sheetHeight = newValue
            }
            .onChange(of: displayedVehicles.count) { oldCount, newCount in
                // Only update rendered vehicles when not dragging
                if !isDragging {
                    renderedVehicles = displayedVehicles
                }
            }
            .onChange(of: isDragging) { wasDragging, nowDragging in
                // When drag ends, update rendered vehicles
                if wasDragging && !nowDragging {
                    renderedVehicles = displayedVehicles
                }
                // When drag starts, ensure all vehicles are shown
                if !wasDragging && nowDragging {
                    renderedVehicles = availableVehicles
                }
            }
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
            get: { checkoutUrl.map { CheckoutURL(url: $0, reference: bookingReference, token: quoteToken) } },
            set: { newValue in
                // When Safari is dismissed (set to nil), clear the checkout URL
                if newValue == nil {
                    print("📱 [BOOKING] Safari fullScreenCover binding set to nil")
                    checkoutUrl = nil
                } else {
                    checkoutUrl = newValue?.url
                }
            }
        )) { checkout in
            SafariView(url: checkout.url) {
                // Called when user manually dismisses Safari (NOT when redirecting)
                print("📱 [BOOKING] Safari view onDismiss called")
                print("📱 [BOOKING] Booking reference: \(checkout.reference ?? "N/A")")
                print("📱 [BOOKING] Quote token: \(checkout.token ?? "N/A")")
                
                // Preserve the booking data - this is crucial
                bookingReference = checkout.reference
                quoteToken = checkout.token
                
                // Show confirmation sheet with a delay to allow Safari to fully dismiss
                // This handles both cases:
                // 1. User manually dismisses Safari without paying
                // 2. Payment completed but deep link didn't fire
                Task { @MainActor in
                    // Wait for Safari dismissal animation to complete
                    try? await Task.sleep(for: .milliseconds(600))
                    
                    print("📱 [BOOKING] Showing confirmation sheet after Safari dismissal")
                    showBookingConfirmed = true
                }
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
                    quoteToken: quoteToken,
                    onDismiss: {
                        showBookingConfirmed = false
                        showVehicleSelection = false
                    }
                )
                .onAppear {
                    print("✅ [DEBUG] BookingConfirmedViewContent appeared with reference: \(reference)")
                    print("✅ [DEBUG] Quote Token: \(quoteToken ?? "N/A")")
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
                        showVehicleSelection = false
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
        .sheet(isPresented: $showLoginSheet) {
            SMSLoginView()
                .environment(appState)
                .onDisappear {
                    // After successful login, automatically proceed with booking
                    if appState.isAuthenticated {
                        print("✅ User logged in successfully - proceeding with booking")
                        performBooking()
                    }
                }
        }
        .onOpenURL { url in
            // Intercept booking-confirmed deep links if they match our booking reference
            handleBookingConfirmedDeepLink(url)
        }
        
    }
    
    // Helper struct for identifiable URL with reference and token
    private struct CheckoutURL: Identifiable {
        let id = UUID()
        let url: URL
        let reference: String?
        let token: String?
    }
    
    // MARK: - Booking Action
    
    private func handleBookingConfirmedDeepLink(_ url: URL) {
        // Only handle if it's our booking-confirmed deep link
        guard url.scheme == "veramo",
              url.host == "booking-confirmed",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let ref = queryItems.first(where: { $0.name == "ref" })?.value else {
            return
        }
        
        print("📱 [VEHICLE_SELECTION] Intercepted booking-confirmed deep link: \(ref)")
        
        // Check if this is OUR booking
        if let ourReference = bookingReference, ref == ourReference {
            print("✅ [VEHICLE_SELECTION] Deep link matches our booking")
            print("   • Reference: \(ref)")
            print("   • Token: \(quoteToken ?? "N/A")")
            
            // Check if we're already showing the confirmation sheet
            if showBookingConfirmed {
                print("ℹ️ [VEHICLE_SELECTION] Confirmation sheet already showing - ignoring deep link")
                return
            }
            
            // IMPORTANT: Delay showing the sheet to allow Safari fullScreenCover to fully dismiss
            // Without this delay, we get "presentation is in progress" error and the sheet auto-dismisses
            Task { @MainActor in
                // First, ensure Safari is dismissed by clearing the URL
                checkoutUrl = nil
                
                // Wait for Safari dismissal animation to complete (typically 0.3-0.5s)
                try? await Task.sleep(for: .milliseconds(600))
                
                // Only show if not already showing (race condition check)
                if !showBookingConfirmed {
                    print("📱 [VEHICLE_SELECTION] Presenting BookingConfirmedView from deep link")
                    showBookingConfirmed = true
                }
            }
        } else {
            print("⚠️ [VEHICLE_SELECTION] Deep link reference (\(ref)) doesn't match our booking (\(bookingReference ?? "none"))")
            // Not our booking, let MainTabView handle it
        }
    }
    
    private func createBooking() {
        // Validate we have selected a vehicle
        guard selectedVehicle != nil else {
            errorMessage = "Please select a vehicle to continue."
            showErrorAlert = true
            return
        }
        
        // Validate we have place IDs
        guard pickupPlaceId != nil, destinationPlaceId != nil else {
            errorMessage = "Location information is missing. Please go back and select locations again."
            showErrorAlert = true
            return
        }
        
        // Check authentication BEFORE booking
        if !appState.isAuthenticated {
            print("⚠️ User not authenticated - showing login sheet")
            showLoginSheet = true
            return
        }
        
        // User is authenticated, proceed with booking
        performBooking()
    }
    
    private func performBooking() {
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
                
                print("📅 [BOOKING] DateTime Info:")
                print("   • Selected date: \(date)")
                print("   • Selected time: \(time)")
                print("   • Combined (Swiss): \(swissTimeString)")
                print("   • Combined (UTC): \(utcTimeString)")
                print("   • Current time: \(formatter.string(from: now))")
                print("   • Hours from now: \(String(format: "%.2f", hoursFromNow))")
                print("   ℹ️  Minimum advance time validation (dynamic from API) is performed in RideBookingView")
                
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
                        // Save the booking reference and quote token
                        let reference = response.quoteReference ?? "UNKNOWN"
                        let token = response.quoteToken
                        
                        bookingReference = reference
                        quoteToken = token
                        checkoutUrl = url
                        
                        print("✅ [BOOKING] Booking created successfully!")
                        print("   • Reference: \(reference)")
                        print("   • Quote Token: \(token ?? "N/A")")
                        print("   • Opening checkout URL...")
                        
                        // Track booking requested in AppsFlyer
                        AppsFlyerEvents.shared.trackRideBookingRequested(
                            booking: response,
                            pickup: pickup,
                            destination: destination,
                            vehicleClass: vehicleClass,
                            distance: response.distanceKm
                        )
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


    
    // MARK: - Pricing
    
    private func fetchPricing() async {
        isLoadingPricing = true
        pricingError = nil
        
        do {
            let swissTimeZone = TimeZone(identifier: "Europe/Zurich")!
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
            
            if let pickupId = pickupPlaceId, let destinationId = destinationPlaceId {
                pricingResponse = try await PricingService.shared.fetchPricing(
                    originPlaceId: pickupId,
                    destinationPlaceId: destinationId,
                    pickupDatetime: pickupDatetime
                )
                
                await MainActor.run {
                    isLoadingPricing = false
                    
                    // Auto-select Business class after pricing loads
                    selectedVehicle = availableVehicles.first { $0.name == "Business" }
                    
                    // Initialize rendered vehicles
                    renderedVehicles = displayedVehicles
                }
            } else {
                throw PricingError.missingLocationData
            }
        } catch {
            await MainActor.run {
                isLoadingPricing = false
                pricingError = error.localizedDescription
            }
        }
    }
    
}



// MARK: - View Height Preference Key

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
