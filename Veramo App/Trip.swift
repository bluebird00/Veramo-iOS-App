//
//  Trip.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import Foundation

struct CustomerTrip: Codable, Identifiable {
    let id: Int
    let bookingStatus: String
    let bookedAt: String
    let reference: String
    let priceCents: Int
    let vehicleClass: String
    let pickupDescription: String
    let destinationDescription: String
    let dateTime: String
    let passengers: Int
    let flightNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case bookingStatus = "booking_status"
        case bookedAt = "booked_at"
        case reference
        case priceCents = "price_cents"
        case vehicleClass = "vehicle_class"
        case pickupDescription = "pickup_description"
        case destinationDescription = "destination_description"
        case dateTime = "date_time"
        case passengers
        case flightNumber = "flight_number"
    }
    
    // Computed properties for display
    var formattedPrice: String {
        let dollars = Double(priceCents) / 100.0
        return String(format: "CHF %.2f", dollars)
    }
    
    var date: Date? {
        // Try ISO8601 with fractional seconds first
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = iso8601Formatter.date(from: dateTime) {
            return date
        }
        
        // Try ISO8601 without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: dateTime) {
            return date
        }
        
        // Try standard DateFormatter as fallback
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return dateFormatter.date(from: dateTime)
    }
    
    // Format date in Zurich timezone (all trips are in Switzerland)
    var formattedDate: String {
        guard let date = date else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone(identifier: "Europe/Zurich")
        return formatter.string(from: date)
    }
    
    // Format time in Zurich timezone (all trips are in Switzerland)
    var formattedTime: String {
        guard let date = date else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "Europe/Zurich")
        return formatter.string(from: date)
    }
    
    // Format date and time together in Zurich timezone
    var formattedDateTime: String {
        guard let date = date else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "Europe/Zurich")
        return formatter.string(from: date)
    }
    
    var vehicleDisplayName: String {
        switch vehicleClass.lowercased() {
        case "business":
            return "Business"
        case "first":
            return "First Class"
        case "xl":
            return "XL"
        default:
            return vehicleClass.capitalized
        }
    }
    
    var statusColor: String {
        switch bookingStatus.lowercased() {
        case "confirmed":
            return "green"
        case "pending":
            return "orange"
        case "cancelled":
            return "red"
        default:
            return "gray"
        }
    }
}

struct CustomerTripsResponse: Codable {
    let success: Bool
    let customer: TripCustomer?
    let upcoming: [CustomerTrip]
    let past: [CustomerTrip]
    let error: String?
    
    struct TripCustomer: Codable {
        let name: String
        let email: String
    }
}
