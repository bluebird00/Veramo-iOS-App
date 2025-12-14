//
//  TripActivityAttributes.swift
//  Veramo App
//
//  Live Activity attributes for active trips
//

import ActivityKit
import Foundation

/// Attributes for Trip Live Activity
struct TripActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Trip status
        var status: String
        var statusDisplayName: String
        
        // Driver info
        var driverName: String?
        var driverPhone: String?
        
        // ETA info
        var etaMinutes: Int?
        
        // Location info
        var pickupDescription: String
        var destinationDescription: String
        
        // Last updated
        var lastUpdated: Date
    }
    
    // Static trip info (doesn't change)
    var tripReference: String
    var vehicleClass: String
    var pickupTime: Date
}

/// Status color for Live Activity
extension TripActivityAttributes.ContentState {
    var statusColor: String {
        switch status.lowercased() {
        case "en_route":
            return "blue"
        case "nearby":
            return "orange"
        case "arrived":
            return "green"
        case "waiting":
            return "orange"
        case "in_progress":
            return "purple"
        default:
            return "gray"
        }
    }
    
    var icon: String {
        switch status.lowercased() {
        case "en_route":
            return "car.fill"
        case "nearby":
            return "location.fill"
        case "arrived":
            return "checkmark.circle.fill"
        case "waiting":
            return "clock.fill"
        case "in_progress":
            return "arrow.right.circle.fill"
        default:
            return "car"
        }
    }
}
