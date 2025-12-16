//
//  AppsFlyerEvents.swift
//  Veramo App
//
//  AppsFlyer event tracking for ride-sharing/chauffeur service
//

import Foundation
import AppsFlyerLib

/// Handles all AppsFlyer event tracking for the Veramo app
class AppsFlyerEvents {
    
    static let shared = AppsFlyerEvents()
    
    private init() {}
    
    // MARK: - User Registration & Authentication
    
    /// Track when user completes registration via SMS
    /// Call this after successful SMS code verification (new users only)
    func trackCompleteRegistration(customer: AuthenticatedCustomer) {
        let values: [String: Any] = [
            AFEventParamRegistrationMethod: "sms"
        ]
        
        AppsFlyerLib.shared().logEvent(AFEventCompleteRegistration, withValues: values)
        print("📊 [AppsFlyer] Tracked registration: \(customer.name ?? "unknown") via SMS")
    }
    
    /// Track when user successfully logs in
    /// Call this after successful user auth (existing users)
    func trackLogin() {
        AppsFlyerLib.shared().logEvent(AFEventLogin, withValues: nil)
        print("📊 [AppsFlyer] Tracked login")
    }
    
    // MARK: - Payment Events
    
    /// Track when user adds payment info (credit card selection)
    /// Call this when user selects a payment method in Mollie checkout
    func trackAddPaymentInfo(paymentMethod: String, success: Bool) {
        let values: [String: Any] = [
            AFEventParamSuccess: success ? "1" : "0",
            "payment_method_type": paymentMethod // e.g., "credit_card", "ideal", "bancontact"
        ]
        
        AppsFlyerLib.shared().logEvent(AFEventAddPaymentInfo, withValues: values)
        print("📊 [AppsFlyer] Tracked payment info: \(paymentMethod), success: \(success)")
    }
    
    // MARK: - Ride Booking Events
    
    /// Track when user creates a ride booking request (before payment)
    /// Call this when booking API call succeeds and checkout URL is generated
    func trackRideBookingRequested(
        booking: BookingResponse,
        pickup: String,
        destination: String,
        vehicleClass: String,
        distance: Double?
    ) {
        guard let priceCents = booking.priceCents else { return }
        
        let priceChf = Double(priceCents) / 100.0
        
        var values: [String: Any] = [
            AFEventParamPrice: priceChf,
            AFEventParamCurrency: "CHF",
            AFEventParamDestinationA: pickup,
            AFEventParamDestinationB: destination,
            AFEventParamContentType: vehicleClass, // "business", "first", "xl"
            AFEventParamCountry: "Switzerland"
        ]
        
        if let distance = distance {
            values["distance"] = distance
        }
        
        if let reference = booking.quoteReference {
            values["order_id"] = reference
        }
        
        AppsFlyerLib.shared().logEvent("ride_booking_requested", withValues: values)
        print("📊 [AppsFlyer] Tracked ride booking requested: \(priceChf) CHF")
    }
    
    /// Track when booking is confirmed (payment successful)
    /// Call this after payment confirmation (from booking confirmed view or payment webhook)
    func trackRideBookingConfirmed(trip: CustomerTrip) {
        let priceChf = Double(trip.priceCents) / 100.0
        
        let values: [String: Any] = [
            AFEventParamPrice: priceChf,
            AFEventParamCurrency: "CHF",
            AFEventParamDestinationA: trip.pickupDescription,
            AFEventParamDestinationB: trip.destinationDescription,
            AFEventParamContentType: trip.vehicleClass, // "business", "first", "xl"
            AFEventParamCountry: "Switzerland",
            AFEventParamOrderId: trip.reference,
            "passengers": trip.passengers
        ]
        
        AppsFlyerLib.shared().logEvent("ride_booking_confirmed", withValues: values)
        print("📊 [AppsFlyer] Tracked ride booking confirmed: \(trip.reference)")
    }
    
    /// Track when booking is confirmed with additional details
    /// Use this version when you have more booking details available
    func trackRideBookingConfirmedDetailed(
        reference: String,
        priceCents: Int,
        pickup: String,
        destination: String,
        vehicleClass: String,
        passengers: Int,
        distance: Double?,
        paymentMethod: String?
    ) {
        let priceChf = Double(priceCents) / 100.0
        
        var values: [String: Any] = [
            AFEventParamPrice: priceChf,
            AFEventParamCurrency: "CHF",
            AFEventParamDestinationA: pickup,
            AFEventParamDestinationB: destination,
            AFEventParamContentType: vehicleClass,
            AFEventParamCountry: "Switzerland",
            AFEventParamOrderId: reference,
            "passengers": passengers
        ]
        
        if let distance = distance {
            values["distance"] = distance
        }
        
        if let paymentMethod = paymentMethod {
            values["payment_method_type"] = paymentMethod
        }
        
        AppsFlyerLib.shared().logEvent("ride_booking_confirmed", withValues: values)
        print("📊 [AppsFlyer] Tracked ride booking confirmed: \(reference) - \(priceChf) CHF")
    }
    
    /// Track when booking is canceled
    /// Call this when user or system cancels a booking
    func trackRideBookingCanceled(
        trip: CustomerTrip,
        canceledBy: String, // "customer" or "system"
        reason: String?
    ) {
        let priceChf = Double(trip.priceCents) / 100.0
        
        var values: [String: Any] = [
            AFEventParamPrice: priceChf,
            AFEventParamCurrency: "CHF",
            AFEventParamDestinationA: trip.pickupDescription,
            AFEventParamDestinationB: trip.destinationDescription,
            AFEventParamContentType: trip.vehicleClass,
            AFEventParamCountry: "Switzerland",
            "order_id": trip.reference,
            "canceled_by": canceledBy
        ]
        
        if let reason = reason {
            values["cancelation_reason"] = reason
        }
        
        AppsFlyerLib.shared().logEvent("ride_booking_canceled", withValues: values)
        print("📊 [AppsFlyer] Tracked ride booking canceled: \(trip.reference)")
    }
    
    /// Track when ride is completed
    /// Call this when trip status changes to "completed" or after ride is finished
    func trackRideBookingCompleted(trip: CustomerTrip) {
        let priceChf = Double(trip.priceCents) / 100.0
        
        let values: [String: Any] = [
            AFEventParamPrice: priceChf,
            AFEventParamCurrency: "CHF",
            AFEventParamDestinationA: trip.pickupDescription,
            AFEventParamDestinationB: trip.destinationDescription,
            AFEventParamContentType: trip.vehicleClass,
            AFEventParamCountry: "Switzerland",
            "order_id": trip.reference,
            "passengers": trip.passengers
        ]
        
        AppsFlyerLib.shared().logEvent("ride_booking_completed", withValues: values)
        print("📊 [AppsFlyer] Tracked ride booking completed: \(trip.reference)")
    }
    
    // MARK: - Additional Engagement Events
    
    /// Track when user searches for a route
    func trackRouteSearch(pickup: String, destination: String) {
        let values: [String: Any] = [
            AFEventParamDestinationA: pickup,
            AFEventParamDestinationB: destination,
            AFEventParamCountry: "Switzerland"
        ]
        
        AppsFlyerLib.shared().logEvent(AFEventSearch, withValues: values)
        print("📊 [AppsFlyer] Tracked route search")
    }
    
    /// Track when user opens chat
    func trackChatOpened(channelId: String) {
        let values: [String: Any] = [
            "channel_id": channelId
        ]
        
        AppsFlyerLib.shared().logEvent("chat_opened", withValues: values)
        print("📊 [AppsFlyer] Tracked chat opened")
    }
    
    /// Track when user views their trips
    func trackTripsViewed(upcomingCount: Int, pastCount: Int) {
        let values: [String: Any] = [
            "upcoming_trips": upcomingCount,
            "past_trips": pastCount
        ]
        
        AppsFlyerLib.shared().logEvent("trips_viewed", withValues: values)
        print("📊 [AppsFlyer] Tracked trips viewed")
    }
    
    // MARK: - User Properties
    
    /// Set customer user ID for cross-device tracking
    /// Call this immediately after successful login/registration
    func setCustomerUserId(_ customerId: String) {
        AppsFlyerLib.shared().customerUserID = customerId
        print("👤 [AppsFlyer] Set customer user ID: \(customerId)")
    }
    
    /// Set customer email for attribution matching
    func setCustomerEmail(_ email: String) {
        AppsFlyerLib.shared().customData = ["customer_email": email]
        print("📧 [AppsFlyer] Set customer email: \(email)")
    }
}

// MARK: - Usage Examples & Integration Points

/*
 
 INTEGRATION GUIDE:
 
 1️⃣ AUTHENTICATION (Veramo_AppApp.swift - handleMagicLink):
 
 // After successful auth
 let (customer, sessionToken) = try await VeramoAuthService.shared.verifyMagicLink(token: token)
 
 // Determine if new user (you'll need to check this from your API response)
 if customer.isNewUser {
     AppsFlyerEvents.shared.trackCompleteRegistration(customer: customer)
 } else {
     AppsFlyerEvents.shared.trackLogin()
 }
 
 // Set user ID
 if let customerId = customer.id {
     AppsFlyerEvents.shared.setCustomerUserId(customerId)
 }
 
 
 2️⃣ BOOKING REQUESTED (RideBookingView.swift - after booking API call):
 
 let response = try await BookingService.shared.createBooking(...)
 
 if response.success {
     AppsFlyerEvents.shared.trackRideBookingRequested(
         booking: response,
         pickup: bookingDetails.pickupDescription,
         destination: bookingDetails.destinationDescription,
         vehicleClass: bookingDetails.vehicleClass,
         distance: response.distanceKm
     )
 }
 
 
 3️⃣ BOOKING CONFIRMED (BookingConfirmedView.swift - onAppear):
 
 .onAppear {
     if let trip = trip {
         AppsFlyerEvents.shared.trackRideBookingConfirmed(trip: trip)
     }
 }
 
 
 4️⃣ PAYMENT METHOD SELECTED (in payment flow):
 
 func handlePaymentMethodSelection(method: String) {
     AppsFlyerEvents.shared.trackAddPaymentInfo(
         paymentMethod: method,
         success: true
     )
 }
 
 
 5️⃣ BOOKING CANCELED (if you add cancel functionality):
 
 func cancelBooking(trip: CustomerTrip) {
     AppsFlyerEvents.shared.trackRideBookingCanceled(
         trip: trip,
         canceledBy: "customer",
         reason: "Changed plans"
     )
 }
 
 
 6️⃣ RIDE COMPLETED (when trip status updates):
 
 if trip.bookingStatus == "completed" {
     AppsFlyerEvents.shared.trackRideBookingCompleted(trip: trip)
 }
 
 
 7️⃣ ROUTE SEARCH (when user selects locations):
 
 Button("Search") {
     AppsFlyerEvents.shared.trackRouteSearch(
         pickup: pickupLocation.description,
         destination: destinationLocation.description
     )
 }
 
 
 8️⃣ CHAT OPENED (ChatView.swift):
 
 .onAppear {
     AppsFlyerEvents.shared.trackChatOpened(channelId: channelId)
 }
 
 
 9️⃣ TRIPS VIEWED (TripsView.swift):
 
 .onAppear {
     AppsFlyerEvents.shared.trackTripsViewed(
         upcomingCount: upcomingTrips.count,
         pastCount: pastTrips.count
     )
 }
 
 */
