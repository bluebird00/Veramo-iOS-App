//
//  SettingsService.swift
//  Veramo App
//
//  Created by rentamac on 12/15/25.
//

import Foundation

// MARK: - Settings Response Models

struct SettingsResponse: Codable {
    let success: Bool
    let settings: AppSettings
}

struct AppSettings: Codable {
    let minBookingHours: String
    
    enum CodingKeys: String, CodingKey {
        case minBookingHours = "min_booking_hours"
    }
    
    /// Returns the minimum booking hours as an integer
    var minBookingHoursInt: Int {
        return Int(minBookingHours) ?? 4  // Default to 4 hours if parsing fails
    }
}

// MARK: - Settings Error Types

enum SettingsError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid settings API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse settings response"
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Settings Service

class SettingsService {
    static let shared = SettingsService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    
    // Cache the settings to avoid repeated API calls
    private var cachedSettings: AppSettings?
    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    /// Fetches app settings from the API
    /// - Returns: AppSettings with min_booking_hours and other settings
    func fetchSettings(forceRefresh: Bool = false) async throws -> AppSettings {
        // Return cached settings if still valid and not forcing refresh
        if !forceRefresh,
           let cached = cachedSettings,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration {
            print("✅ [SETTINGS] Using cached settings (min_booking_hours: \(cached.minBookingHours))")
            return cached
        }
        
        // Construct URL
        guard let url = URL(string: "\(baseURL)/settings") else {
            throw SettingsError.invalidURL
        }
        
        // Configure HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        // Log the request
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("⚙️ SETTINGS API REQUEST")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌐 URL: \(url.absoluteString)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [SETTINGS] Invalid HTTP response")
                throw SettingsError.networkError(NSError(domain: "", code: -1))
            }
            
            // Log the response
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📥 SETTINGS API RESPONSE")
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
                let settingsResponse = try decoder.decode(SettingsResponse.self, from: data)
                
                if settingsResponse.success {
                    // Cache the settings
                    cachedSettings = settingsResponse.settings
                    lastFetchTime = Date()
                    
                    print("\n✅ SETTINGS LOADED!")
                    print("   • Min Booking Hours: \(settingsResponse.settings.minBookingHours)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                    return settingsResponse.settings
                } else {
                    let errorMsg = "Settings fetch failed"
                    print("❌ [SETTINGS] \(errorMsg)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                    throw SettingsError.serverError(errorMsg)
                }
                
            default:
                // Server error
                let errorMsg = "Server returned status code: \(httpResponse.statusCode)"
                print("❌ [SETTINGS] \(errorMsg)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw SettingsError.serverError(errorMsg)
            }
            
        } catch let error as SettingsError {
            throw error
        } catch let error as DecodingError {
            print("❌ [SETTINGS] Decoding error: \(error)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw SettingsError.decodingError
        } catch {
            print("❌ [SETTINGS] Network error: \(error.localizedDescription)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw SettingsError.networkError(error)
        }
    }
    
    /// Clears the cached settings, forcing a fresh fetch on next call
    func clearCache() {
        cachedSettings = nil
        lastFetchTime = nil
        print("🗑️ [SETTINGS] Cache cleared")
    }
}
