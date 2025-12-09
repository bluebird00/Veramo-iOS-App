//
//  CustomerTripsService.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import Foundation

enum TripsError: Error, LocalizedError {
    case unauthorized
    case noSessionToken
    case invalidURL
    case networkError(Error)
    case decodingError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired. Please log in again."
        case .noSessionToken:
            return "Not authenticated. Please log in."
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse server response"
        case .serverError(let message):
            return message
        }
    }
}

class CustomerTripsService {
    static let shared = CustomerTripsService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    
    private init() {}
    
    /// Fetches customer trips (upcoming and past)
    func fetchTrips() async throws -> CustomerTripsResponse {
        guard let sessionToken = AuthenticationManager.shared.sessionToken else {
            throw TripsError.noSessionToken
        }
        
        guard let url = URL(string: "\(baseURL)/customer-trips") else {
            throw TripsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TripsError.networkError(NSError(domain: "", code: -1))
            }
            
            // Handle 401 - Unauthorized / Session expired
            if httpResponse.statusCode == 401 {
                // Clear authentication
                AuthenticationManager.shared.logout()
                throw TripsError.unauthorized
            }
            
            guard httpResponse.statusCode == 200 else {
                throw TripsError.serverError("Server returned status code: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let tripsResponse = try decoder.decode(CustomerTripsResponse.self, from: data)
            
            if tripsResponse.success {
                return tripsResponse
            } else {
                throw TripsError.serverError(tripsResponse.error ?? "Failed to fetch trips")
            }
        } catch let error as TripsError {
            throw error
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
            throw TripsError.decodingError
        } catch {
            throw TripsError.networkError(error)
        }
    }
}
