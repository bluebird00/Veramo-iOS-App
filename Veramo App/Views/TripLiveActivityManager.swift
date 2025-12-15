//
//  TripLiveActivityManager.swift
//  Veramo App
//
//  Manager for Trip Live Activities
//

import ActivityKit
import Foundation
import OSLog

private let logger = Logger(subsystem: "ch.veramo.app", category: "LiveActivity")

class TripLiveActivityManager {
    static let shared = TripLiveActivityManager()
    
    // Track active Live Activities by trip reference
    private var activities: [String: Activity<TripActivityAttributes>] = [:]
    
    private init() {
        // Check for existing activities on init
        Task { @MainActor [weak self] in
            self?.loadExistingActivities()
        }
    }
    
    /// Load any existing Live Activities that are still running
    @MainActor
    private func loadExistingActivities() {
        for activity in Activity<TripActivityAttributes>.activities {
            let reference = activity.attributes.tripReference
            activities[reference] = activity
            logger.info("📱 [LiveActivity] Found existing activity for trip: \(reference)")
            logger.info("📱 [LiveActivity] Activity state: \(String(describing: activity.activityState))")
            logger.info("📱 [LiveActivity] Activity ID: \(activity.id)")
            logger.info("📱 [LiveActivity] Content: \(String(describing: activity.content))")
        }
    }
    
    /// Start a Live Activity for a trip
    @MainActor
    func startActivity(for trip: CustomerTrip, status: TripStatus) {
        // Check if Live Activities are supported
        let authInfo = ActivityAuthorizationInfo()
        logger.info("📱 [LiveActivity] Authorization status: \(authInfo.areActivitiesEnabled)")
        logger.info("📱 [LiveActivity] Frequency status: \(String(describing: authInfo.frequentPushesEnabled))")
        
        guard authInfo.areActivitiesEnabled else {
            logger.warning("⚠️ [LiveActivity] Live Activities are not enabled")
            return
        }
        
        // Don't start if already exists
        if activities[trip.reference] != nil {
            logger.debug("📱 [LiveActivity] Activity already exists for \(trip.reference)")
            updateActivity(for: trip, status: status)
            return
        }
        
        // Check if status is active
        let activeStatuses = ["en_route", "nearby", "arrived", "waiting"]
        guard activeStatuses.contains(status.status.lowercased()) else {
            logger.debug("⏭️ [LiveActivity] Skipping activity - status not active: \(status.status)")
            return
        }
        
        guard let pickupDate = trip.date else {
            logger.warning("⚠️ [LiveActivity] Cannot start activity - no pickup date")
            return
        }
        
        let attributes = TripActivityAttributes(
            tripReference: trip.reference,
            vehicleClass: trip.vehicleClass,
            pickupTime: pickupDate
        )
        
        let vehicleData = formatVehicleInfo(status.vehicle)
        let contentState = TripActivityAttributes.ContentState(
            status: status.status,
            statusDisplayName: statusDisplayName(for: status.status),
            driverName: status.driver?.name,
            driverPhone: status.driver?.phone,
            vehicleInfo: vehicleData.description,
            vehicleColor: vehicleData.color,
            licensePlate: vehicleData.plate,
            etaMinutes: status.eta?.minutes,
            etaDistanceKm: status.eta?.distanceKm,
            pickupDescription: trip.pickupDescription,
            destinationDescription: trip.destinationDescription,
            lastUpdated: Date()
        )
        
        do {
            let activity = try Activity<TripActivityAttributes>.request(
                attributes: attributes,
                content: .init(
                    state: contentState,
                    staleDate: Date().addingTimeInterval(3600) // Stay fresh for 1 hour
                ),
                pushType: nil
            )
            
            activities[trip.reference] = activity
            logger.info("✅ [LiveActivity] Started activity for trip: \(trip.reference)")
            logger.debug("📱 [LiveActivity] Activity ID: \(activity.id)")
            logger.debug("📱 [LiveActivity] Activity state: \(String(describing: activity.activityState))")
            logger.debug("📱 [LiveActivity] Content state: \(contentState.statusDisplayName)")
            
            // Monitor for activity end
            Task {
                await monitorActivityState(activity: activity, reference: trip.reference)
            }
        } catch {
            logger.error("❌ [LiveActivity] Failed to start activity: \(error.localizedDescription)")
        }
    }
    
    /// Update an existing Live Activity
    @MainActor
    func updateActivity(for trip: CustomerTrip, status: TripStatus) {
        guard let activity = activities[trip.reference] else {
            logger.debug("📱 [LiveActivity] No activity to update for \(trip.reference)")
            return
        }
        
        let vehicleData = formatVehicleInfo(status.vehicle)
        let contentState = TripActivityAttributes.ContentState(
            status: status.status,
            statusDisplayName: statusDisplayName(for: status.status),
            driverName: status.driver?.name,
            driverPhone: status.driver?.phone,
            vehicleInfo: vehicleData.description,
            vehicleColor: vehicleData.color,
            licensePlate: vehicleData.plate,
            etaMinutes: status.eta?.minutes,
            etaDistanceKm: status.eta?.distanceKm,
            pickupDescription: trip.pickupDescription,
            destinationDescription: trip.destinationDescription,
            lastUpdated: Date()
        )
        
        Task {
            await activity.update(
                .init(
                    state: contentState,
                    staleDate: Date().addingTimeInterval(3600) // Stay fresh for 1 hour
                )
            )
            logger.info("🔄 [LiveActivity] Updated activity for \(trip.reference): \(status.status)")
        }
    }
    
    /// End a Live Activity
    @MainActor
    func endActivity(for reference: String, dismissalPolicy: ActivityUIDismissalPolicy = .default) {
        guard let activity = activities[reference] else {
            logger.debug("📱 [LiveActivity] No activity to end for \(reference)")
            return
        }
        
        Task {
            await activity.end(nil, dismissalPolicy: dismissalPolicy)
            activities.removeValue(forKey: reference)
            logger.info("🛑 [LiveActivity] Ended activity for \(reference)")
        }
    }
    
    /// End all Live Activities
    @MainActor
    func endAllActivities() {
        for (reference, activity) in activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
                logger.info("🛑 [LiveActivity] Ended activity for \(reference)")
            }
        }
        activities.removeAll()
    }
    
    /// Monitor activity state changes
    private func monitorActivityState(activity: Activity<TripActivityAttributes>, reference: String) async {
        for await state in activity.activityStateUpdates {
            if state == .dismissed || state == .ended {
                await MainActor.run {
                    activities.removeValue(forKey: reference)
                }
                logger.info("🔚 [LiveActivity] Activity ended/dismissed for \(reference)")
                break
            }
        }
    }
    
    /// Check if an activity exists for a trip
    @MainActor
    func hasActivity(for reference: String) -> Bool {
        return activities[reference] != nil
    }
    
    /// Debug: Check all active activities
    @MainActor
    func debugActiveActivities() {
        logger.info("🔍 [LiveActivity] Total activities tracked: \(self.activities.count)")
        logger.info("🔍 [LiveActivity] System activities count: \(Activity<TripActivityAttributes>.activities.count)")
        
        for activity in Activity<TripActivityAttributes>.activities {
            let stateString = "\(activity.activityState)"
            logger.info("🔍 [LiveActivity] System activity: \(activity.attributes.tripReference) - State: \(stateString)")
            logger.info("🔍 [LiveActivity] - Content state: \(activity.content.state.statusDisplayName)")
            logger.info("🔍 [LiveActivity] - Last updated: \(activity.content.state.lastUpdated)")
            logger.info("🔍 [LiveActivity] - Stale date: \(String(describing: activity.content.staleDate))")
        }
        
        // Check authorization
        let authInfo = ActivityAuthorizationInfo()
        logger.info("🔍 [LiveActivity] Authorization - Enabled: \(authInfo.areActivitiesEnabled)")
        logger.info("🔍 [LiveActivity] Authorization - Frequent pushes: \(String(describing: authInfo.frequentPushesEnabled))")
    }
    
    // MARK: - Helpers
    
    private func formatVehicleInfo(_ vehicle: TripStatus.VehicleInfo?) -> (description: String?, color: String?, plate: String?) {
        guard let vehicle = vehicle else { return (nil, nil, nil) }
        
        var parts: [String] = []
        
        // Add make and model (without color)
        if let make = vehicle.make, let model = vehicle.model {
            parts.append("\(make) \(model)")
        } else if let make = vehicle.make {
            parts.append(make)
        } else if let model = vehicle.model {
            parts.append(model)
        }
        
        let vehicleDescription = parts.isEmpty ? nil : parts.joined(separator: " ")
        
        return (vehicleDescription, vehicle.color, vehicle.licensePlate)
    }
    
    private func statusDisplayName(for status: String) -> String {
        switch status.lowercased() {
        case "assigned":
            return "Driver Assigned"
        case "en_route":
            return "Driver En Route"
        case "nearby":
            return "Driver Nearby"
        case "arrived":
            return "Driver Arrived"
        case "waiting":
            return "Driver Waiting"
        case "in_progress":
            return "Trip In Progress"
        case "completed":
            return "Trip Completed"
        default:
            return status.capitalized
        }
    }
}
