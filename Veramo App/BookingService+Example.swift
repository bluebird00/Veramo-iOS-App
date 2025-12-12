//
//  BookingService+Example.swift
//  Veramo App
//
//  Example usage of BookingService for creating bookings
//

import Foundation

/*
 
 EXAMPLE 1: Basic Booking Flow
 ==============================
 
 This shows the complete flow from authentication to booking creation.
 
 */

func exampleBasicBookingFlow() async throws {
    // Step 1: Authenticate (if not already authenticated)
    if !AuthenticationManager.shared.isAuthenticated {
        // Send SMS code
        let sendResponse = try await VeramoAuthService.shared.requestSMSCode(
            phone: "+41791234567"
        )
        print("SMS sent: \(sendResponse.message)")
        
        // User enters code in UI...
        let code = "123456"  // From user input
        
        // Verify code
        let (customer, sessionToken) = try await VeramoAuthService.shared.verifySMSCode(
            phone: "+41791234567",
            code: code
        )
        
        // Save authentication
        AuthenticationManager.shared.saveAuthentication(
            customer: customer,
            sessionToken: sessionToken
        )
    }
    
    // Step 2: Get session token
    guard let sessionToken = AuthenticationManager.shared.sessionToken else {
        throw BookingError.missingSessionToken
    }
    
    // Step 3: Prepare booking details
    let pickupPlaceId = "ChIJlaW7RciqmkcRrel029KMuT8"  // Zurich Airport
    let destinationPlaceId = "ChIJbwaKz_imxkcRxK6IYJJJPpQ"  // Hotel in Zurich
    
    // Create datetime (3 days from now at 2 PM Switzerland time)
    // IMPORTANT: Use Switzerland timezone for all date/time operations
    let swissTimeZone = TimeZone(identifier: "Europe/Zurich")!
    var calendar = Calendar.current
    calendar.timeZone = swissTimeZone
    
    // Get current date/time in Switzerland
    let now = Date()
    
    // Add 3 days and set to 2 PM
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
    components.day! += 3
    components.hour = 14
    components.minute = 0
    components.second = 0
    
    let pickupDateTime = calendar.date(from: components)!
    
    // Step 4: Create booking
    let response = try await BookingService.shared.createBooking(
        pickupPlaceId: pickupPlaceId,
        pickupDescription: "Zurich Airport",
        destinationPlaceId: destinationPlaceId,
        destinationDescription: "Hotel Baur au Lac, Zurich",
        dateTime: pickupDateTime,
        passengers: 2,
        vehicleClass: "business",
        flightNumber: "LX123",
        sessionToken: sessionToken
    )
    
    // Step 5: Handle response
    if response.success, let checkoutUrl = response.checkoutUrl {
        print("Booking created! Reference: \(response.quoteReference ?? "N/A")")
        print("Price: \(response.priceFormatted ?? "N/A")")
        print("Checkout URL: \(checkoutUrl)")
        
        // Open checkout URL in Safari/WebView
        if let url = URL(string: checkoutUrl) {
            // Open URL in UI...
            // await UIApplication.shared.open(url)
        }
    }
}

/*
 
 EXAMPLE 2: Booking with Pricing Preview
 ========================================
 
 Shows how to fetch pricing first, then create booking.
 
 */

func exampleBookingWithPricing() async throws {
    let pickupPlaceId = "ChIJlaW7RciqmkcRrel029KMuT8"
    let destinationPlaceId = "ChIJbwaKz_imxkcRxK6IYJJJPpQ"
    
    // Prepare datetime in Switzerland timezone
    let swissTimeZone = TimeZone(identifier: "Europe/Zurich")!
    var calendar = Calendar.current
    calendar.timeZone = swissTimeZone
    
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
    components.day! += 3
    components.hour = 14
    components.minute = 0
    
    let pickupDateTime = calendar.date(from: components)!
    
    // Step 1: Get pricing (optional but recommended)
    let pricingResponse = try await PricingService.shared.fetchPricing(
        originPlaceId: pickupPlaceId,
        destinationPlaceId: destinationPlaceId,
        pickupDatetime: pickupDateTime
    )
    
    print("Pricing for trip:")
    print("- Business: \(pricingResponse.prices.business.priceFormatted)")
    print("- First Class: \(pricingResponse.prices.first.priceFormatted)")
    print("- XL: \(pricingResponse.prices.xl.priceFormatted)")
    print("Distance: \(pricingResponse.distanceKm) km")
    print("Duration: \(pricingResponse.durationMinutes) minutes")
    
    // User selects vehicle class in UI...
    let selectedVehicleClass = "business"
    
    // Step 2: Create booking with selected vehicle class
    guard let sessionToken = AuthenticationManager.shared.sessionToken else {
        throw BookingError.missingSessionToken
    }
    
    let bookingResponse = try await BookingService.shared.createBooking(
        pickupPlaceId: pickupPlaceId,
        pickupDescription: "Zurich Airport",
        destinationPlaceId: destinationPlaceId,
        destinationDescription: "Hotel Baur au Lac, Zurich",
        dateTime: pickupDateTime,
        passengers: 2,
        vehicleClass: selectedVehicleClass,
        sessionToken: sessionToken
    )
    
    if let checkoutUrl = bookingResponse.checkoutUrl {
        print("Booking created! Opening payment page...")
        // Open checkout URL
    }
}

/*
 
 EXAMPLE 3: Error Handling
 ==========================
 
 Shows proper error handling for common scenarios.
 
 */

func exampleErrorHandling() async {
    do {
        guard let sessionToken = AuthenticationManager.shared.sessionToken else {
            throw BookingError.missingSessionToken
        }
        
        let response = try await BookingService.shared.createBooking(
            pickupPlaceId: "ChIJ...",
            pickupDescription: "Pickup Location",
            destinationPlaceId: "ChIJ...",
            destinationDescription: "Destination",
            dateTime: Date().addingTimeInterval(3 * 24 * 60 * 60),
            vehicleClass: "business",
            sessionToken: sessionToken
        )
        
        // Success
        print("Booking created: \(response.quoteReference ?? "N/A")")
        
    } catch BookingError.unauthorized {
        // Session expired - re-authenticate
        print("Session expired. Please log in again.")
        AuthenticationManager.shared.logout()
        // Navigate to login screen...
        
    } catch BookingError.validationError(let message) {
        // Validation error - show to user
        print("Validation error: \(message)")
        // Show error alert to user...
        
    } catch BookingError.routeCalculationFailed {
        // Route calculation failed - check locations
        print("Failed to calculate route. Please check your locations.")
        // Show error alert to user...
        
    } catch BookingError.missingPlaceId {
        // Missing Place ID - location not properly selected
        print("Please select a valid location from the list.")
        // Navigate back to location selection...
        
    } catch {
        // Generic error
        print("Booking failed: \(error.localizedDescription)")
        // Show generic error alert...
    }
}

/*
 
 EXAMPLE 4: Complete SwiftUI Integration
 ========================================
 
 Shows how to integrate booking into a SwiftUI view.
 
 */

import SwiftUI

struct BookingExampleView: View {
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var checkoutUrl: URL?
    
    let pickupPlaceId: String
    let destinationPlaceId: String
    let pickupDescription: String
    let destinationDescription: String
    let pickupDateTime: Date
    let vehicleClass: String
    let passengers: Int
    let flightNumber: String?
    
    var body: some View {
        Button("Book Now") {
            Task {
                await createBooking()
            }
        }
        .disabled(isProcessing)
        .alert("Booking Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .fullScreenCover(item: Binding(
            get: { checkoutUrl.map { URLWrapper(url: $0) } },
            set: { checkoutUrl = $0?.url }
        )) { wrapper in
            SafariView(url: wrapper.url) {
                // Dismissed after payment
                print("Payment completed or cancelled")
            }
            .ignoresSafeArea()
        }
    }
    
    private func createBooking() async {
        guard let sessionToken = AuthenticationManager.shared.sessionToken else {
            errorMessage = "Not authenticated. Please log in."
            showError = true
            return
        }
        
        isProcessing = true
        
        do {
            let response = try await BookingService.shared.createBooking(
                pickupPlaceId: pickupPlaceId,
                pickupDescription: pickupDescription,
                destinationPlaceId: destinationPlaceId,
                destinationDescription: destinationDescription,
                dateTime: pickupDateTime,
                passengers: passengers,
                vehicleClass: vehicleClass,
                flightNumber: flightNumber,
                sessionToken: sessionToken
            )
            
            await MainActor.run {
                isProcessing = false
                
                if let urlString = response.checkoutUrl,
                   let url = URL(string: urlString) {
                    checkoutUrl = url
                } else {
                    errorMessage = "Booking created but no payment URL was provided"
                    showError = true
                }
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    struct URLWrapper: Identifiable {
        let id = UUID()
        let url: URL
    }
}

/*
 
 EXAMPLE 5: Testing Helpers
 ===========================
 
 Useful functions for testing the booking flow.
 
 */

#if DEBUG
extension BookingService {
    /// Creates a test booking with default values
    static func createTestBooking() async throws -> BookingResponse {
        // Ensure authenticated
        guard let sessionToken = AuthenticationManager.shared.sessionToken else {
            throw BookingError.missingSessionToken
        }
        
        // Use Zurich locations
        let pickupPlaceId = "ChIJlaW7RciqmkcRrel029KMuT8"  // Zurich Airport
        let destinationPlaceId = "ChIJHzaU8LukmkcRLJdRNwHy0bw"  // Bahnhofstrasse
        
        // 3 days from now at 2 PM
        let swissTimeZone = TimeZone(identifier: "Europe/Zurich")!
        var calendar = Calendar.current
        calendar.timeZone = swissTimeZone
        
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        components.day! += 3
        components.hour = 14
        components.minute = 0
        
        let pickupDateTime = calendar.date(from: components)!
        
        return try await BookingService.shared.createBooking(
            pickupPlaceId: pickupPlaceId,
            pickupDescription: "Zurich Airport",
            destinationPlaceId: destinationPlaceId,
            destinationDescription: "Bahnhofstrasse, Zurich",
            dateTime: pickupDateTime,
            passengers: 1,
            vehicleClass: "business",
            sessionToken: sessionToken
        )
    }
}

// Test authentication
func testAuthentication() async throws {
    print("Testing SMS authentication...")
    
    let testPhone = "+41791234567"
    
    // Send code
    let sendResponse = try await VeramoAuthService.shared.requestSMSCode(phone: testPhone)
    assert(sendResponse.success, "SMS send should succeed")
    print("✅ SMS sent successfully")
    
    // In real scenario, user enters code
    // For testing, you would need to check your phone or backend logs
    let testCode = "123456"
    
    do {
        let (customer, token) = try await VeramoAuthService.shared.verifySMSCode(
            phone: testPhone,
            code: testCode
        )
        print("✅ Authenticated: \(customer.name)")
        print("✅ Token: \(String(token.prefix(20)))...")
        
        AuthenticationManager.shared.saveAuthentication(
            customer: customer,
            sessionToken: token
        )
    } catch {
        print("❌ Verification failed: \(error.localizedDescription)")
    }
}

// Test pricing
func testPricing() async throws {
    print("Testing pricing API...")
    
    let response = try await PricingService.shared.fetchPricing(
        originPlaceId: "ChIJlaW7RciqmkcRrel029KMuT8",
        destinationPlaceId: "ChIJHzaU8LukmkcRLJdRNwHy0bw"
    )
    
    print("✅ Pricing retrieved:")
    print("   Business: \(response.prices.business.priceFormatted)")
    print("   First: \(response.prices.first.priceFormatted)")
    print("   XL: \(response.prices.xl.priceFormatted)")
    print("   Distance: \(response.distanceKm) km")
}
#endif


