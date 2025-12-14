//
//  DriverStatusService.swift
//  Veramo App
//
//  Service for tracking driver status and location updates
//

import Foundation
import Combine

enum DriverStatus: String, Codable {
    case enRoute = "en_route"
    case arrived = "arrived"
    case waitingForPickup = "waiting_for_pickup"
    case pickupComplete = "pickup_complete"
    case droppingOff = "dropping_off"
    case complete = "complete"
    case canceled = "canceled"
    
    var displayName: String {
        switch self {
        case .enRoute:
            return String(localized: "Driver on the way", comment: "Driver status: on the way")
        case .arrived:
            return String(localized: "Driver has arrived", comment: "Driver status: arrived")
        case .waitingForPickup:
            return String(localized: "Driver waiting", comment: "Driver status: waiting for passenger")
        case .pickupComplete:
            return String(localized: "Picked up", comment: "Driver status: passenger picked up")
        case .droppingOff:
            return String(localized: "Heading to destination", comment: "Driver status: going to destination")
        case .complete:
            return String(localized: "Trip completed", comment: "Driver status: trip complete")
        case .canceled:
            return String(localized: "Trip canceled", comment: "Driver status: canceled")
        }
    }
}

struct DriverLocation: Codable {
    let latitude: Double
    let longitude: Double
    let heading: Double?
    let estimatedArrivalMinutes: Int?
    let lastUpdated: Date
}

struct DriverInfo: Codable {
    let driverId: String
    let name: String
    let vehicleMake: String?
    let vehicleModel: String?
    let vehicleColor: String?
    let licensePlate: String?
    let phoneNumber: String?
}

struct TripStatusResponse: Codable {
    let reference: String
    let status: DriverStatus
    let driverLocation: DriverLocation?
    let driverInfo: DriverInfo?
    let estimatedArrivalTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case reference
        case status
        case driverLocation = "driver_location"
        case driverInfo = "driver_info"
        case estimatedArrivalTime = "estimated_arrival_time"
    }
}

@MainActor
class DriverStatusService: ObservableObject {
    static let shared = DriverStatusService()
    
    @Published var currentStatus: DriverStatus?
    @Published var driverLocation: DriverLocation?
    @Published var driverInfo: DriverInfo?
    @Published var estimatedArrival: Date?
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    private var pollingTask: Task<Void, Never>?
    
    private init() {}
    
    /// Start polling for driver status updates
    /// - Parameters:
    ///   - reference: The booking reference number
    ///   - intervalSeconds: How often to poll (default: 15 seconds)
    func startTracking(reference: String, intervalSeconds: TimeInterval = 15) {
        print("🚗 [DRIVER] Starting driver tracking for reference: \(reference)")
        
        // Cancel any existing polling
        stopTracking()
        
        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    try await fetchDriverStatus(reference: reference)
                    
                    // Wait before next poll
                    try await Task.sleep(for: .seconds(intervalSeconds))
                } catch is CancellationError {
                    print("🚗 [DRIVER] Tracking cancelled")
                    break
                } catch {
                    print("⚠️ [DRIVER] Error fetching driver status: \(error)")
                    // Continue polling even on error
                    try? await Task.sleep(for: .seconds(intervalSeconds))
                }
            }
        }
    }
    
    /// Stop polling for driver status updates
    func stopTracking() {
        print("🚗 [DRIVER] Stopping driver tracking")
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    /// Fetch current driver status once
    func fetchDriverStatus(reference: String) async throws {
        print("🚗 [DRIVER] Fetching status for reference: \(reference)")
        
        guard let url = URL(string: "\(baseURL)/app-trip-status?reference=\(reference)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add session token if authenticated
        if let sessionToken = AuthenticationManager.shared.sessionToken {
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ [DRIVER] Server returned status code: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let statusResponse = try decoder.decode(TripStatusResponse.self, from: data)
        
        // Update published properties
        await MainActor.run {
            currentStatus = statusResponse.status
            driverLocation = statusResponse.driverLocation
            driverInfo = statusResponse.driverInfo
            estimatedArrival = statusResponse.estimatedArrivalTime
            
            print("✅ [DRIVER] Status updated: \(statusResponse.status.rawValue)")
            if let eta = statusResponse.estimatedArrivalTime {
                print("   ETA: \(eta)")
            }
        }
    }
    
    /// Clear all tracking data
    func clearStatus() {
        currentStatus = nil
        driverLocation = nil
        driverInfo = nil
        estimatedArrival = nil
    }
}
