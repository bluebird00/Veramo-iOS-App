//
//  BookingService.swift
//  Veramo App
//
//  Created by rentamac on 12/12/25.
//

import Foundation

// MARK: - Booking Request Models

struct BookingRequest: Codable {
    let pickup: BookingLocation
    let destination: BookingLocation
    let dateTime: String  // ISO 8601 format: "2025-01-15T14:00:00Z"
    let passengers: Int?
    let vehicleClass: String  // "business", "first", or "xl"
    let flightNumber: String?
    let redirectUrl: String?  // Deep link URL for post-payment redirect (e.g., "veramo://booking-confirmed")
    
    enum CodingKeys: String, CodingKey {
        case pickup, destination, dateTime, passengers, vehicleClass, flightNumber, redirectUrl
    }
}

struct BookingLocation: Codable {
    let placeId: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case description
    }
}

// MARK: - Booking Response Models

struct BookingResponse: Codable {
    let success: Bool
    let tripRequestId: Int?
    let quoteReference: String?
    let quoteToken: String?  // Token for checking payment status via quote-public endpoint
    let priceCents: Int?
    let priceFormatted: String?
    let distanceKm: Double?
    let durationMinutes: Int?
    let checkoutUrl: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case tripRequestId
        case quoteReference
        case quoteToken
        case priceCents
        case priceFormatted
        case distanceKm
        case durationMinutes
        case checkoutUrl
        case error
    }
}

// MARK: - Booking Error Types

enum BookingError: Error, LocalizedError {
    case invalidURL
    case unauthorized  // 401 - Session expired
    case validationError(String)  // 400 - Validation error
    case routeCalculationFailed  // 502 - Route calculation failed
    case networkError(Error)
    case decodingError
    case serverError(String)
    case missingSessionToken
    case missingPlaceId
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid booking API URL"
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .validationError(let message):
            return "Validation error: \(message)"
        case .routeCalculationFailed:
            return "Failed to calculate route. Please check your locations and try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse booking response"
        case .serverError(let message):
            return message
        case .missingSessionToken:
            return "Not authenticated. Please log in."
        case .missingPlaceId:
            return "Location information is missing. Please select locations again."
        }
    }
}

// MARK: - Booking Service

class BookingService {
    static let shared = BookingService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    
    private init() {}
    
    /// Creates a booking using authenticated session
    /// - Parameters:
    ///   - pickupPlaceId: Google Place ID for pickup location
    ///   - pickupDescription: Human-readable pickup location name
    ///   - destinationPlaceId: Google Place ID for destination
    ///   - destinationDescription: Human-readable destination name
    ///   - dateTime: Pickup date and time
    ///   - passengers: Number of passengers (optional, defaults to 1)
    ///   - vehicleClass: One of "business", "first", or "xl"
    ///   - flightNumber: Flight number (optional)
    ///   - redirectUrl: Deep link URL for post-payment redirect (e.g., "veramo://booking-confirmed")
    ///   - sessionToken: Authentication session token (valid for 7 days)
    /// - Returns: BookingResponse with checkout URL and booking details
    func createBooking(
        pickupPlaceId: String,
        pickupDescription: String,
        destinationPlaceId: String,
        destinationDescription: String,
        dateTime: Date,
        passengers: Int? = nil,
        vehicleClass: String,
        flightNumber: String? = nil,
        redirectUrl: String? = nil,
        sessionToken: String
    ) async throws -> BookingResponse {
        
        // Validate inputs
        guard !pickupPlaceId.isEmpty else {
            throw BookingError.missingPlaceId
        }
        guard !destinationPlaceId.isEmpty else {
            throw BookingError.missingPlaceId
        }
        guard !sessionToken.isEmpty else {
            throw BookingError.missingSessionToken
        }
        
        // Construct URL
        guard let url = URL(string: "\(baseURL)/app-book") else {
            throw BookingError.invalidURL
        }
        
        // Format datetime as ISO 8601 in UTC
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        let dateTimeString = formatter.string(from: dateTime)
        
        // Create request body
        let bookingRequest = BookingRequest(
            pickup: BookingLocation(
                placeId: pickupPlaceId,
                description: pickupDescription
            ),
            destination: BookingLocation(
                placeId: destinationPlaceId,
                description: destinationDescription
            ),
            dateTime: dateTimeString,
            passengers: passengers,
            vehicleClass: vehicleClass,
            flightNumber: flightNumber,
            redirectUrl: redirectUrl
        )
        
        // Configure HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        // Encode request body
        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(bookingRequest)
        } catch {
            print("❌ [BOOKING] Failed to encode request: \(error)")
            throw BookingError.networkError(error)
        }
        
        // Log the request
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🚗 BOOKING API REQUEST")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌐 URL: \(url.absoluteString)")
        print("🔐 Authorization: Bearer \(String(sessionToken.prefix(20)))...")
        print("\n📦 Request Body:")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print(bodyString)
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [BOOKING] Invalid HTTP response")
                throw BookingError.networkError(NSError(domain: "", code: -1))
            }
            
            // Log the response
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📥 BOOKING API RESPONSE")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📊 Status Code: \(httpResponse.statusCode)")
            
            // Pretty print the JSON response
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("\n📄 Response Body:")
                print(prettyString)
            } else if let rawString = String(data: data, encoding: .utf8) {
                print("\n📄 Raw Response:")
                print(rawString)
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200:
                // Success - decode response
                let decoder = JSONDecoder()
                let bookingResponse = try decoder.decode(BookingResponse.self, from: data)
                
                if bookingResponse.success {
                    print("\n✅ BOOKING SUCCESSFUL!")
                    print("   • Trip Request ID: \(bookingResponse.tripRequestId ?? 0)")
                    print("   • Quote Reference: \(bookingResponse.quoteReference ?? "N/A")")
                    print("   • Quote Token: \(bookingResponse.quoteToken ?? "N/A")")
                    print("   • Price: \(bookingResponse.priceFormatted ?? "N/A")")
                    print("   • Distance: \(bookingResponse.distanceKm ?? 0) km")
                    print("   • Duration: \(bookingResponse.durationMinutes ?? 0) minutes")
                    print("   • Checkout URL: \(bookingResponse.checkoutUrl ?? "N/A")")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                    return bookingResponse
                } else {
                    let errorMsg = bookingResponse.error ?? "Booking failed"
                    print("❌ [BOOKING] Server returned error: \(errorMsg)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                    throw BookingError.serverError(errorMsg)
                }
                
            case 400:
                // Validation error
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorDict["error"] as? String {
                    print("❌ [BOOKING] Validation error: \(errorMessage)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                    throw BookingError.validationError(errorMessage)
                }
                print("❌ [BOOKING] Validation error (no message)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw BookingError.validationError("Invalid booking data")
                
            case 401:
                // Session expired
                print("❌ [BOOKING] Session expired (401) - handling via NetworkAuthenticationHandler")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                
                // Use centralized authentication handler
                NetworkAuthenticationHandler.shared.handleUnauthorizedResponse(endpoint: "app-book")
                
                throw BookingError.unauthorized
                
            case 502:
                // Route calculation failed
                print("❌ [BOOKING] Route calculation failed (502)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw BookingError.routeCalculationFailed
                
            default:
                // Other server error
                let errorMsg = "Server returned status code: \(httpResponse.statusCode)"
                print("❌ [BOOKING] \(errorMsg)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw BookingError.serverError(errorMsg)
            }
            
        } catch let error as BookingError {
            throw error
        } catch let error as DecodingError {
            print("❌ [BOOKING] Decoding error: \(error)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw BookingError.decodingError
        } catch {
            print("❌ [BOOKING] Network error: \(error.localizedDescription)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw BookingError.networkError(error)
        }
    }
}

// MARK: - Helper Extensions

extension String {
    /// Maps vehicle type name to API vehicle class
    var toVehicleClass: String {
        let lowercased = self.lowercased()
        if lowercased.contains("first") {
            return "first"
        } else if lowercased.contains("xl") {
            return "xl"
        } else {
            return "business"
        }
    }
}
