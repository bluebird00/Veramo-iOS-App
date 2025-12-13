//
//  LocationSuggestionsService.swift
//  Veramo App
//
//  Service for fetching pickup and destination suggestions based on user patterns
//

import Foundation

// MARK: - Location Suggestion Models

struct LocationSuggestion: Codable, Identifiable, Hashable {
    let placeId: String      // Google Place ID
    let description: String  // Human-readable address
    let frequency: Int       // How often user visited
    
    var id: String { placeId } // Conform to Identifiable
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case description
        case frequency
    }
}

struct SuggestionsResponse: Codable {
    let success: Bool
    let suggestions: [LocationSuggestion]
    let error: String?
}

// MARK: - Location Suggestion Error Types

enum LocationSuggestionsError: Error, LocalizedError {
    case invalidURL
    case notAuthenticated
    case networkError(Error)
    case decodingError
    case serverError(String)
    case unauthorized  // 401 - Session expired
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid location suggestions API URL"
        case .notAuthenticated:
            return "User is not authenticated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse location suggestions response"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Your session has expired. Please log in again."
        }
    }
}

// MARK: - Location Suggestions Service

class LocationSuggestionsService {
    static let shared = LocationSuggestionsService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    
    // Simple cache to avoid repeated API calls (5 minute TTL)
    private var pickupCache: CachedSuggestions?
    private var destinationCache: [String: CachedSuggestions] = [:] // Keyed by pickup place_id
    private let cacheTTL: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Pickup Suggestions
    
    /// Fetches pickup location suggestions based on user's history
    /// This should be called when the pickup input field gains focus (before user types)
    /// - Parameters:
    ///   - sessionToken: The authenticated session token
    ///   - dayOfWeek: Optional day of week (0 = Monday, 6 = Sunday). If nil, uses current day.
    ///   - hour: Optional hour (0-23). If nil, uses current hour.
    ///   - useCache: Whether to use cached results if available (default: true)
    /// - Returns: Array of location suggestions ordered by frequency
    func fetchPickupSuggestions(
        sessionToken: String? = nil,
        dayOfWeek: Int? = nil,
        hour: Int? = nil,
        useCache: Bool = true
    ) async throws -> [LocationSuggestion] {
        
        // Use provided token or get from AuthenticationManager
        let token = sessionToken ?? AuthenticationManager.shared.sessionToken
        
        guard let token = token else {
            throw LocationSuggestionsError.notAuthenticated
        }
        
        // Check cache first
        if useCache, let cached = pickupCache, !cached.isExpired {
            print("📍 [PICKUP-SUGGESTIONS] Using cached suggestions (\(cached.suggestions.count) items)")
            return cached.suggestions
        }
        
        // Build URL with optional query parameters
        var urlComponents = URLComponents(string: "\(baseURL)/app-pickup-suggestions")!
        var queryItems: [URLQueryItem] = []
        
        if let dayOfWeek = dayOfWeek {
            queryItems.append(URLQueryItem(name: "day_of_week", value: "\(dayOfWeek)"))
        }
        
        if let hour = hour {
            queryItems.append(URLQueryItem(name: "hour", value: "\(hour)"))
        }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw LocationSuggestionsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📍 PICKUP SUGGESTIONS REQUEST")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌐 URL: \(url.absoluteString)")
        print("🔑 Token: \(String(token.prefix(20)))...")
        if let dayOfWeek = dayOfWeek {
            print("📅 Day of Week: \(dayOfWeek)")
        }
        if let hour = hour {
            print("🕐 Hour: \(hour)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw LocationSuggestionsError.networkError(NSError(domain: "", code: -1))
            }
            
            print("📊 Status Code: \(httpResponse.statusCode)")
            
            // Pretty print the JSON response
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("\n📄 Response Body:")
                print(prettyString)
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                let suggestionsResponse = try decoder.decode(SuggestionsResponse.self, from: data)
                
                guard suggestionsResponse.success else {
                    let errorMsg = suggestionsResponse.error ?? "Failed to get pickup suggestions"
                    print("❌ Server error: \(errorMsg)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                    throw LocationSuggestionsError.serverError(errorMsg)
                }
                
                print("\n✅ PICKUP SUGGESTIONS RETRIEVED")
                print("   • Count: \(suggestionsResponse.suggestions.count)")
                for (index, suggestion) in suggestionsResponse.suggestions.prefix(3).enumerated() {
                    print("   • [\(index + 1)] \(suggestion.description) (freq: \(suggestion.frequency))")
                }
                if suggestionsResponse.suggestions.count > 3 {
                    print("   • ... and \(suggestionsResponse.suggestions.count - 3) more")
                }
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                
                // Cache the results
                pickupCache = CachedSuggestions(suggestions: suggestionsResponse.suggestions)
                
                return suggestionsResponse.suggestions
                
            case 401:
                print("❌ Unauthorized - session expired")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw LocationSuggestionsError.unauthorized
                
            default:
                let errorMsg = "Server returned status code: \(httpResponse.statusCode)"
                print("❌ \(errorMsg)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw LocationSuggestionsError.serverError(errorMsg)
            }
            
        } catch let error as LocationSuggestionsError {
            throw error
        } catch let error as DecodingError {
            print("❌ Decoding error: \(error)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw LocationSuggestionsError.decodingError
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw LocationSuggestionsError.networkError(error)
        }
    }
    
    // MARK: - Destination Suggestions
    
    /// Fetches destination location suggestions based on user's history and selected pickup
    /// This should be called when the destination input gains focus AND pickup is already selected
    /// - Parameters:
    ///   - pickupPlaceId: Optional Google Place ID of the selected pickup location
    ///   - sessionToken: The authenticated session token
    ///   - dayOfWeek: Optional day of week (0 = Monday, 6 = Sunday). If nil, uses current day.
    ///   - hour: Optional hour (0-23). If nil, uses current hour.
    ///   - useCache: Whether to use cached results if available (default: true)
    /// - Returns: Array of location suggestions ordered by frequency
    func fetchDestinationSuggestions(
        pickupPlaceId: String?,
        sessionToken: String? = nil,
        dayOfWeek: Int? = nil,
        hour: Int? = nil,
        useCache: Bool = true
    ) async throws -> [LocationSuggestion] {
        
        // Use provided token or get from AuthenticationManager
        let token = sessionToken ?? AuthenticationManager.shared.sessionToken
        
        guard let token = token else {
            throw LocationSuggestionsError.notAuthenticated
        }
        
        // Check cache first
        let cacheKey = pickupPlaceId ?? "no_pickup"
        if useCache, let cached = destinationCache[cacheKey], !cached.isExpired {
            print("📍 [DESTINATION-SUGGESTIONS] Using cached suggestions (\(cached.suggestions.count) items)")
            return cached.suggestions
        }
        
        // Build URL with optional query parameters
        var urlComponents = URLComponents(string: "\(baseURL)/app-destination-suggestions")!
        var queryItems: [URLQueryItem] = []
        
        if let pickupPlaceId = pickupPlaceId {
            queryItems.append(URLQueryItem(name: "pickup_place_id", value: pickupPlaceId))
        }
        
        if let dayOfWeek = dayOfWeek {
            queryItems.append(URLQueryItem(name: "day_of_week", value: "\(dayOfWeek)"))
        }
        
        if let hour = hour {
            queryItems.append(URLQueryItem(name: "hour", value: "\(hour)"))
        }
        
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw LocationSuggestionsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📍 DESTINATION SUGGESTIONS REQUEST")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌐 URL: \(url.absoluteString)")
        print("🔑 Token: \(String(token.prefix(20)))...")
        if let pickupPlaceId = pickupPlaceId {
            print("📍 Pickup Place ID: \(pickupPlaceId)")
        }
        if let dayOfWeek = dayOfWeek {
            print("📅 Day of Week: \(dayOfWeek)")
        }
        if let hour = hour {
            print("🕐 Hour: \(hour)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw LocationSuggestionsError.networkError(NSError(domain: "", code: -1))
            }
            
            print("📊 Status Code: \(httpResponse.statusCode)")
            
            // Pretty print the JSON response
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print("\n📄 Response Body:")
                print(prettyString)
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                let suggestionsResponse = try decoder.decode(SuggestionsResponse.self, from: data)
                
                guard suggestionsResponse.success else {
                    let errorMsg = suggestionsResponse.error ?? "Failed to get destination suggestions"
                    print("❌ Server error: \(errorMsg)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                    throw LocationSuggestionsError.serverError(errorMsg)
                }
                
                print("\n✅ DESTINATION SUGGESTIONS RETRIEVED")
                print("   • Count: \(suggestionsResponse.suggestions.count)")
                for (index, suggestion) in suggestionsResponse.suggestions.prefix(3).enumerated() {
                    print("   • [\(index + 1)] \(suggestion.description) (freq: \(suggestion.frequency))")
                }
                if suggestionsResponse.suggestions.count > 3 {
                    print("   • ... and \(suggestionsResponse.suggestions.count - 3) more")
                }
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                
                // Cache the results
                destinationCache[cacheKey] = CachedSuggestions(suggestions: suggestionsResponse.suggestions)
                
                return suggestionsResponse.suggestions
                
            case 401:
                print("❌ Unauthorized - session expired")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw LocationSuggestionsError.unauthorized
                
            default:
                let errorMsg = "Server returned status code: \(httpResponse.statusCode)"
                print("❌ \(errorMsg)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw LocationSuggestionsError.serverError(errorMsg)
            }
            
        } catch let error as LocationSuggestionsError {
            throw error
        } catch let error as DecodingError {
            print("❌ Decoding error: \(error)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw LocationSuggestionsError.decodingError
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw LocationSuggestionsError.networkError(error)
        }
    }
    
    // MARK: - Cache Management
    
    /// Clears all cached suggestions
    func clearCache() {
        pickupCache = nil
        destinationCache.removeAll()
        print("🗑️ Location suggestions cache cleared")
    }
    
    /// Clears only pickup suggestions cache
    func clearPickupCache() {
        pickupCache = nil
        print("🗑️ Pickup suggestions cache cleared")
    }
    
    /// Clears only destination suggestions cache
    func clearDestinationCache() {
        destinationCache.removeAll()
        print("🗑️ Destination suggestions cache cleared")
    }
}

// MARK: - Cache Helper

private struct CachedSuggestions {
    let suggestions: [LocationSuggestion]
    let timestamp: Date
    
    init(suggestions: [LocationSuggestion]) {
        self.suggestions = suggestions
        self.timestamp = Date()
    }
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 300 // 5 minutes
    }
}
