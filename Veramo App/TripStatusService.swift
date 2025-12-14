//
//  TripStatusService.swift
//  Veramo App
//
//  Service for polling trip status for upcoming trips
//

import Foundation
import SwiftUI
import OSLog
import ActivityKit

// MARK: - Logger

private let logger = Logger(subsystem: "ch.veramo.app", category: "TripStatus")

// MARK: - Trip Status Models

struct TripStatus: Codable, Equatable {
    let reference: String
    let status: String
    let driver: DriverInfo?
    let driverLocation: DriverLocation?
    let eta: ETA?
    let pickup: LocationInfo?
    
    struct DriverInfo: Codable, Equatable {
        let name: String
        let phone: String?
    }
    
    struct DriverLocation: Codable, Equatable {
        let latitude: Double
        let longitude: Double
        let heading: Double
        let updatedAt: String
    }
    
    struct ETA: Codable, Equatable {
        let minutes: Int
    }
    
    struct LocationInfo: Codable, Equatable {
        let description: String
        let latitude: Double
        let longitude: Double
    }
}

// Wrapper response from API
struct AppTripStatusResponse: Codable {
    let success: Bool
    let trip: TripStatus?
    let error: String?
}

enum TripStatusType: String {
    case assigned = "assigned"
    case enRoute = "en_route"
    case nearby = "nearby"
    case arrived = "arrived"
    case waiting = "waiting"
    case inProgress = "in_progress"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .assigned: return "Driver Assigned"
        case .enRoute: return "En Route"
        case .nearby: return "Nearby"
        case .arrived: return "Arrived"
        case .waiting: return "Waiting"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }
    
    var color: Color {
        switch self {
        case .assigned: return .blue
        case .enRoute: return .blue
        case .nearby: return .orange
        case .arrived: return .green
        case .waiting: return .orange
        case .inProgress: return .purple
        case .completed: return .green
        }
    }
}

// MARK: - Trip Status Service

@Observable
class TripStatusService {
    static let shared = TripStatusService()
    
    private let baseURL = "https://veramo.ch/.netlify/functions"
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    
    // Status cache: [reference: status]
    private(set) var tripStatuses: [String: TripStatus] = [:]
    
    private init() {}
    
    // Store reference to trips being monitored for Live Activity updates
    private var monitoredTrips: [String: CustomerTrip] = [:]
    
    /// Start monitoring a trip's status based on pickup time
    func startMonitoring(trip: CustomerTrip) {
        // Don't monitor if already monitoring
        guard pollingTasks[trip.reference] == nil else {
            logger.info("📍 [TripStatus] Already monitoring trip: \(trip.reference)")
            return
        }
        
        // Store trip for Live Activity updates
        monitoredTrips[trip.reference] = trip
        
        // Calculate time until pickup
        guard let pickupDate = trip.date else {
            logger.warning("⚠️ [TripStatus] Cannot monitor trip \(trip.reference) - no pickup date")
            return
        }
        
        let now = Date()
        let timeUntilPickup = pickupDate.timeIntervalSince(now)
        let minutesUntilPickup = Int(timeUntilPickup / 60)
        
        // Monitor trips within 1 hour before pickup OR up to 2 hours after pickup
        let oneHour: TimeInterval = 3600
        let twoHours: TimeInterval = 7200
        
        // timeUntilPickup is positive if pickup is in future, negative if in past
        // Monitor if: -2 hours <= timeUntilPickup <= +1 hour
        guard timeUntilPickup <= oneHour && timeUntilPickup >= -twoHours else {
            if timeUntilPickup > oneHour {
                logger.debug("⏭️ [TripStatus] Skipping trip \(trip.reference) - pickup in \(minutesUntilPickup) min (too early)")
            } else {
                let minutesPastPickup = abs(minutesUntilPickup)
                logger.debug("⏭️ [TripStatus] Skipping trip \(trip.reference) - pickup was \(minutesPastPickup) min ago (too old)")
            }
            return
        }
        
        if timeUntilPickup > 0 {
            logger.info("🚀 [TripStatus] Starting monitoring for trip: \(trip.reference) (pickup in \(minutesUntilPickup) min)")
        } else {
            let minutesPastPickup = abs(minutesUntilPickup)
            logger.info("🚀 [TripStatus] Starting monitoring for trip: \(trip.reference) (pickup was \(minutesPastPickup) min ago)")
        }
        
        let task = Task {
            await pollTripStatus(reference: trip.reference, pickupDate: pickupDate)
        }
        
        pollingTasks[trip.reference] = task
        logger.debug("✅ [TripStatus] Active polling tasks: \(self.pollingTasks.count)")
    }
    
    /// Stop monitoring a trip's status
    func stopMonitoring(reference: String) {
        logger.info("🛑 [TripStatus] Stopping monitoring for trip: \(reference)")
        pollingTasks[reference]?.cancel()
        pollingTasks.removeValue(forKey: reference)
        tripStatuses.removeValue(forKey: reference)
        monitoredTrips.removeValue(forKey: reference)
        
        // End Live Activity
        Task { @MainActor in
            TripLiveActivityManager.shared.endActivity(for: reference)
        }
        
        logger.debug("✅ [TripStatus] Active polling tasks: \(self.pollingTasks.count)")
    }
    
    /// Stop monitoring all trips
    func stopAllMonitoring() {
        let count = pollingTasks.count
        logger.info("🛑 [TripStatus] Stopping all monitoring (\(count) tasks)")
        pollingTasks.values.forEach { $0.cancel() }
        pollingTasks.removeAll()
        tripStatuses.removeAll()
        monitoredTrips.removeAll()
        
        // End all Live Activities
        Task { @MainActor in
            TripLiveActivityManager.shared.endAllActivities()
        }
        
        logger.debug("✅ [TripStatus] All polling tasks stopped")
    }
    
    /// Get current status for a trip
    func getStatus(for reference: String) -> TripStatus? {
        return tripStatuses[reference]
    }
    
    // MARK: - Private Methods
    
    private func pollTripStatus(reference: String, pickupDate: Date) async {
        var pollCount = 0
        logger.info("🔄 [TripStatus] Poll loop started for \(reference)")
        
        while !Task.isCancelled {
            pollCount += 1
            let now = Date()
            let timeUntilPickup = pickupDate.timeIntervalSince(now)
            let minutesUntilPickup = Int(timeUntilPickup / 60)
            
            logger.debug("🔍 [TripStatus] Poll #\(pollCount) for \(reference) (pickup in \(minutesUntilPickup) min)")
            
            do {
                let status = try await fetchTripStatus(reference: reference)
                
                // Check if status changed
                let previousStatus = tripStatuses[reference]?.status
                let statusChanged = previousStatus != status.status
                
                if statusChanged {
                    logger.info("🔄 [TripStatus] Status changed for \(reference): \(previousStatus ?? "nil") → \(status.status)")
                    
                    // Log driver info if available
                    if let driver = status.driver {
                        logger.debug("👤 [TripStatus] Driver assigned: \(driver.name)")
                    }
                    
                    // Log ETA if available
                    if let eta = status.eta {
                        logger.debug("⏱️ [TripStatus] ETA: \(eta.minutes) min")
                    }
                } else {
                    logger.debug("✓ [TripStatus] Status unchanged for \(reference): \(status.status)")
                }
                
                await MainActor.run {
                    tripStatuses[reference] = status
                    
                    // Update or start Live Activity for active statuses
                    if let trip = monitoredTrips[reference] {
                        let activeStatuses = ["en_route", "nearby", "arrived", "waiting"]
                        if activeStatuses.contains(status.status.lowercased()) {
                            if TripLiveActivityManager.shared.hasActivity(for: reference) {
                                TripLiveActivityManager.shared.updateActivity(for: trip, status: status)
                            } else {
                                TripLiveActivityManager.shared.startActivity(for: trip, status: status)
                            }
                        } else if status.status.lowercased() == "completed" || status.status.lowercased() == "cancelled" {
                            // End Live Activity if trip is completed/cancelled
                            TripLiveActivityManager.shared.endActivity(for: reference, dismissalPolicy: .default)
                        }
                    }
                }
                
                // Determine polling interval based on status
                let interval = pollingInterval(for: status.status, pickupDate: pickupDate)
                let intervalMinutes = Int(interval / 60)
                
                logger.debug("⏰ [TripStatus] Next poll for \(reference) in \(intervalMinutes) min (status: \(status.status))")
                
                // Wait for the interval
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
                // Check if we should stop polling
                if shouldStopPolling(status: status.status, pickupDate: pickupDate) {
                    logger.info("🏁 [TripStatus] Stopping polling for \(reference) - status: \(status.status)")
                    break
                }
            } catch {
                logger.error("❌ [TripStatus] Error polling \(reference): \(error.localizedDescription)")
                logger.debug("🔄 [TripStatus] Retrying in 30 seconds...")
                
                // On error, wait 30 seconds before retrying
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
        
        logger.info("⏹️ [TripStatus] Poll loop ended for \(reference) after \(pollCount) polls")
        
        // Clean up when done
        await MainActor.run {
            pollingTasks.removeValue(forKey: reference)
            logger.debug("🧹 [TripStatus] Cleaned up polling task for \(reference). Active tasks: \(self.pollingTasks.count)")
        }
    }
    
    private func fetchTripStatus(reference: String) async throws -> TripStatus {
        logger.debug("🌐 [TripStatus] Fetching status for \(reference)...")
        
        guard let sessionToken = AuthenticationManager.shared.sessionToken else {
            logger.error("❌ [TripStatus] No session token available")
            throw TripsError.noSessionToken
        }
        
        guard let url = URL(string: "\(baseURL)/app-trip-status?reference=\(reference)") else {
            logger.error("❌ [TripStatus] Invalid URL for reference: \(reference)")
            throw TripsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        
        logger.debug("📡 [TripStatus] HTTP Request: GET \(url.absoluteString)")
        
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let duration = Date().timeIntervalSince(startTime)
        
        logger.debug("⏱️ [TripStatus] Request completed in \(String(format: "%.2f", duration))s")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ [TripStatus] Invalid HTTP response")
            throw TripsError.networkError(NSError(domain: "", code: -1))
        }
        
        logger.debug("📥 [TripStatus] Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            logger.warning("⚠️ [TripStatus] Unauthorized - session expired")
            throw TripsError.unauthorized
        }
        
        guard httpResponse.statusCode == 200 else {
            logger.error("❌ [TripStatus] Server error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("📄 [TripStatus] Response body: \(responseString)")
            }
            throw TripsError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        // Log the raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            logger.debug("📄 [TripStatus] Raw response for \(reference): \(responseString)")
        }
        
        let decoder = JSONDecoder()
        
        do {
            // Try to decode the wrapper response
            let wrapperResponse = try decoder.decode(AppTripStatusResponse.self, from: data)
            
            // Check if it's an error response
            if !wrapperResponse.success {
                let errorMsg = wrapperResponse.error ?? "Unknown error"
                logger.error("❌ [TripStatus] API returned error: \(errorMsg)")
                throw TripsError.serverError(errorMsg)
            }
            
            // Extract the trip status
            guard let status = wrapperResponse.trip else {
                logger.error("❌ [TripStatus] API response missing 'trip' data")
                throw TripsError.serverError("Missing trip data in response")
            }
            
            logger.info("✅ [TripStatus] Successfully fetched status for \(reference): \(status.status)")
            return status
            
        } catch let decodingError as DecodingError {
            // Log detailed decoding error
            switch decodingError {
            case .keyNotFound(let key, let context):
                logger.error("❌ [TripStatus] Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                logger.debug("🔍 [TripStatus] Context: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                logger.error("❌ [TripStatus] Missing value of type '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                logger.debug("🔍 [TripStatus] Context: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                logger.error("❌ [TripStatus] Type mismatch for '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                logger.debug("🔍 [TripStatus] Context: \(context.debugDescription)")
            case .dataCorrupted(let context):
                logger.error("❌ [TripStatus] Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                logger.debug("🔍 [TripStatus] Context: \(context.debugDescription)")
            @unknown default:
                logger.error("❌ [TripStatus] Unknown decoding error: \(decodingError)")
            }
            throw TripsError.decodingError
        } catch {
            logger.error("❌ [TripStatus] Unexpected error decoding response: \(error.localizedDescription)")
            throw TripsError.decodingError
        }
    }
    
    private func pollingInterval(for status: String, pickupDate: Date) -> TimeInterval {
        let now = Date()
        let timeUntilPickup = pickupDate.timeIntervalSince(now)
        
        // If driver is en_route or later status, poll every 1 minute
        if status == "en_route" || status == "nearby" || status == "arrived" || status == "waiting" {
            logger.debug("⚡ [TripStatus] Using 1-minute polling interval (status: \(status))")
            return 60 // 1 minute
        }
        
        // Otherwise, poll every 5 minutes if within 1 hour
        if timeUntilPickup <= 3600 {
            logger.debug("⏰ [TripStatus] Using 5-minute polling interval (status: \(status))")
            return 300 // 5 minutes
        }
        
        // Default: 5 minutes
        logger.debug("⏰ [TripStatus] Using default 5-minute polling interval")
        return 300
    }
    
    private func shouldStopPolling(status: String, pickupDate: Date) -> Bool {
        // Stop polling if trip is completed or cancelled
        if status == "completed" || status == "cancelled" {
            logger.info("🏁 [TripStatus] Trip is \(status) - stopping polling")
            return true
        }
        
        let now = Date()
        let timeSincePickup = now.timeIntervalSince(pickupDate)
        
        // Stop if more than 2 hours past pickup
        let twoHours: TimeInterval = 7200
        if timeSincePickup > twoHours {
            let minutesPastPickup = Int(timeSincePickup / 60)
            logger.info("🏁 [TripStatus] Trip is \(minutesPastPickup) min past pickup - stopping polling")
            return true
        }
        
        return false
    }
}
