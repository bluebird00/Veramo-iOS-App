//
//  PricingService.swift
//  Veramo App
//
//  Created by rentamac on 12/9/25.
//

import Foundation

enum PricingError: Error, LocalizedError {
    case invalidURL
    case missingLocationData
    case networkError(Error)
    case decodingError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid pricing API URL"
        case .missingLocationData:
            return "Missing required location data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse pricing response"
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Response Models

struct PricingResponse: Codable {
    let success: Bool
    let distanceKm: Double
    let distanceMeters: Int
    let durationMinutes: Int
    let pickup: PickupDetails
    let prices: VehiclePrices
    
    enum CodingKeys: String, CodingKey {
        case success
        case distanceKm = "distance_km"
        case distanceMeters = "distance_meters"
        case durationMinutes = "duration_minutes"
        case pickup
        case prices
    }
}

struct PickupDetails: Codable {
    let datetime: String
    let isWeekend: Bool
    let isNight: Bool
    let dayAdjustmentPercent: Int
    let hourAdjustmentPercent: Int
    let totalAdjustmentPercent: Int
    
    enum CodingKeys: String, CodingKey {
        case datetime
        case isWeekend = "is_weekend"
        case isNight = "is_night"
        case dayAdjustmentPercent = "day_adjustment_percent"
        case hourAdjustmentPercent = "hour_adjustment_percent"
        case totalAdjustmentPercent = "total_adjustment_percent"
    }
}

struct VehiclePrices: Codable {
    let business: PriceDetails
    let first: PriceDetails
    let xl: PriceDetails
}

struct PriceDetails: Codable {
    let priceCents: Int
    let priceFormatted: String
    let baseFareCents: Int
    let distanceCostCents: Int
    let adjustmentCents: Int
    
    enum CodingKeys: String, CodingKey {
        case priceCents = "price_cents"
        case priceFormatted = "price_formatted"
        case baseFareCents = "base_fare_cents"
        case distanceCostCents = "distance_cost_cents"
        case adjustmentCents = "adjustment_cents"
    }
}

// MARK: - Pricing Service

class PricingService {
    static let shared = PricingService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    
    private init() {}
    
    /// Fetches pricing for a trip using place IDs
    func fetchPricing(
        originPlaceId: String,
        destinationPlaceId: String,
        pickupDatetime: Date? = nil
    ) async throws -> PricingResponse {
        var components = URLComponents(string: "\(baseURL)/pricing")
        
        var queryItems = [
            URLQueryItem(name: "origin_place_id", value: originPlaceId),
            URLQueryItem(name: "destination_place_id", value: destinationPlaceId)
        ]
        
        // Add pickup datetime if provided - format in Switzerland timezone
        if let pickupDatetime = pickupDatetime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")
            let dateString = dateFormatter.string(from: pickupDatetime)
            queryItems.append(URLQueryItem(name: "pickup_datetime", value: dateString))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw PricingError.invalidURL
        }
        
        return try await performRequest(url: url)
    }
    
    /// Fetches pricing for a trip using coordinates
    func fetchPricing(
        originLat: Double,
        originLng: Double,
        destinationLat: Double,
        destinationLng: Double,
        pickupDatetime: Date? = nil
    ) async throws -> PricingResponse {
        var components = URLComponents(string: "\(baseURL)/pricing")
        
        var queryItems = [
            URLQueryItem(name: "origin_lat", value: String(originLat)),
            URLQueryItem(name: "origin_lng", value: String(originLng)),
            URLQueryItem(name: "destination_lat", value: String(destinationLat)),
            URLQueryItem(name: "destination_lng", value: String(destinationLng))
        ]
        
        // Add pickup datetime if provided - format in Switzerland timezone
        if let pickupDatetime = pickupDatetime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.timeZone = TimeZone(identifier: "Europe/Zurich")
            let dateString = dateFormatter.string(from: pickupDatetime)
            queryItems.append(URLQueryItem(name: "pickup_datetime", value: dateString))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw PricingError.invalidURL
        }
        
        return try await performRequest(url: url)
    }
    
    // MARK: - Private Helpers
    
    private func performRequest(url: URL) async throws -> PricingResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 🔍 Log the request
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📍 PRICING API REQUEST")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🌐 Full URL: \(url.absoluteString)")
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            print("\n📋 Query Parameters:")
            components.queryItems?.forEach { item in
                print("   • \(item.name): \(item.value ?? "nil")")
            }
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw PricingError.networkError(NSError(domain: "", code: -1))
            }
            
            // 🔍 Log the response
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📥 PRICING API RESPONSE")
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
            
            guard httpResponse.statusCode == 200 else {
                // Try to decode error message from response
                if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorDict["error"] as? String {
                    print("❌ Server Error: \(errorMessage)")
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                    throw PricingError.serverError(errorMessage)
                }
                print("❌ Server returned status code: \(httpResponse.statusCode)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
                throw PricingError.serverError("Server returned status code: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            let pricingResponse = try decoder.decode(PricingResponse.self, from: data)
            
            // 🔍 Log parsed pricing data
            print("\n💰 PARSED PRICES:")
            print("   • Business: \(pricingResponse.prices.business.priceFormatted) (\(pricingResponse.prices.business.priceCents) cents)")
            print("     - Base Fare: \(pricingResponse.prices.business.baseFareCents) cents")
            print("     - Distance Cost: \(pricingResponse.prices.business.distanceCostCents) cents")
            print("     - Adjustment: \(pricingResponse.prices.business.adjustmentCents) cents")
            print("\n   • First Class: \(pricingResponse.prices.first.priceFormatted) (\(pricingResponse.prices.first.priceCents) cents)")
            print("     - Base Fare: \(pricingResponse.prices.first.baseFareCents) cents")
            print("     - Distance Cost: \(pricingResponse.prices.first.distanceCostCents) cents")
            print("     - Adjustment: \(pricingResponse.prices.first.adjustmentCents) cents")
            print("\n   • XL: \(pricingResponse.prices.xl.priceFormatted) (\(pricingResponse.prices.xl.priceCents) cents)")
            print("     - Base Fare: \(pricingResponse.prices.xl.baseFareCents) cents")
            print("     - Distance Cost: \(pricingResponse.prices.xl.distanceCostCents) cents")
            print("     - Adjustment: \(pricingResponse.prices.xl.adjustmentCents) cents")
            print("\n📏 Distance: \(pricingResponse.distanceKm) km (\(pricingResponse.distanceMeters) meters)")
            print("⏱️  Duration: \(pricingResponse.durationMinutes) minutes")
            print("📅 Pickup DateTime: \(pricingResponse.pickup.datetime)")
            print("📆 Is Weekend: \(pricingResponse.pickup.isWeekend)")
            print("🌙 Is Night: \(pricingResponse.pickup.isNight)")
            print("🔧 Day Adjustment: \(pricingResponse.pickup.dayAdjustmentPercent)%")
            print("🔧 Hour Adjustment: \(pricingResponse.pickup.hourAdjustmentPercent)%")
            print("🔧 Total Adjustment: \(pricingResponse.pickup.totalAdjustmentPercent)%")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            return pricingResponse
        } catch let error as PricingError {
            print("❌ PricingError: \(error.localizedDescription)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw error
        } catch let error as DecodingError {
            print("❌ Decoding error details:")
            switch error {
            case .keyNotFound(let key, let context):
                print("   • Key '\(key.stringValue)' not found: \(context.debugDescription)")
                print("   • Coding path: \(context.codingPath)")
            case .valueNotFound(let type, let context):
                print("   • Value of type '\(type)' not found: \(context.debugDescription)")
                print("   • Coding path: \(context.codingPath)")
            case .typeMismatch(let type, let context):
                print("   • Type mismatch for type '\(type)': \(context.debugDescription)")
                print("   • Coding path: \(context.codingPath)")
            case .dataCorrupted(let context):
                print("   • Data corrupted: \(context.debugDescription)")
                print("   • Coding path: \(context.codingPath)")
            @unknown default:
                print("   • Unknown decoding error: \(error)")
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw PricingError.decodingError
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            throw PricingError.networkError(error)
        }
    }
}
