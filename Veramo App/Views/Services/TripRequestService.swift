

//
//  TripRequestService.swift
//  Veramo App
//

import Foundation

// MARK: - Request Models

struct Customer: Codable {
    let name: String
    let email: String
    let phone: String
}

struct Location: Codable {
    let description: String
    let place_id: String?
}

struct Trip: Codable {
    let pickup: Location
    let destination: Location
    let dateTime: String
    let passengers: Int?
    let flightNumber: String?
    let vehicleClass: String
}

struct TripRequest: Codable {
    let customer: Customer
    let trip: Trip
}

// MARK: - Response Model

struct TripResponse: Codable {
    let success: Bool?
    let requestId: Int?
    let message: String?
    let error: String?
}

// MARK: - Error Types

enum TripRequestError: LocalizedError {
    case invalidURL
    case encodingError
    case networkError(Error)
    case serverError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .encodingError:
            return "Failed to encode request data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .unknownError:
            return "An unexpected error occurred"
        }
    }
}

// MARK: - Service

class TripRequestService {
    static let shared = TripRequestService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions/trip-request"
    
    private init() {}
    
    func submitTripRequest(request: TripRequest) async throws -> TripResponse {
        guard let url = URL(string: baseURL) else {
            throw TripRequestError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw TripRequestError.encodingError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log response for debugging (remove in production)
            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }
            #endif
            
            let tripResponse = try JSONDecoder().decode(TripResponse.self, from: data)
            
            // Check for error in response
            if let error = tripResponse.error {
                throw TripRequestError.serverError(error)
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                throw TripRequestError.serverError(tripResponse.error ?? "Server returned status \(httpResponse.statusCode)")
            }
            
            return tripResponse
            
        } catch let error as TripRequestError {
            throw error
        } catch is DecodingError {
            throw TripRequestError.unknownError
        } catch {
            throw TripRequestError.networkError(error)
        }
    }
}

// MARK: - Helper Extensions

extension VehicleType {
    /// Maps VehicleType to API vehicle class string
    var apiVehicleClass: String {
        let lowercasedName = name.lowercased()
        
        if lowercasedName.contains("first") || lowercasedName.contains("s-class") {
            return "first"
        } else if lowercasedName.contains("xl") || lowercasedName.contains("v-class") {
            return "xl"
        } else {
            // Default to business class (E-Class or similar)
            return "business"
        }
    }
}

extension Date {
    /// Combines a date and time into ISO 8601 format string
    static func combinedISO8601(date: Date, time: Date) -> String {
        let calendar = Calendar.current
        
        // Extract date components from date
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Extract time components from time
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        // Combine into single date
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = 0
        
        guard let combinedDate = calendar.date(from: combined) else {
            return ISO8601DateFormatter().string(from: date)
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: combinedDate)
    }
}
