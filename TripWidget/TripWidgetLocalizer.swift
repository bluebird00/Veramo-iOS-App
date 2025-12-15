//
//  TripWidgetLocalizer.swift
//  TripWidget
//
//  Localization helper for Trip Live Activity
//

import Foundation

/// Provides localized strings for Trip Live Activity
enum TripWidgetLocalizer {
    
    // MARK: - Status Keys
    
    /// Standard trip status keys (should match backend values)
    enum StatusKey {
        static let enRoute = "en_route"
        static let nearby = "nearby"
        static let arrived = "arrived"
        static let waiting = "waiting"
        static let inProgress = "in_progress"
    }
    
    // MARK: - Time
    
    static var minutesLabel: String {
        String(localized: "min", comment: "Minutes label for ETA display")
    }
    
    static var minutesShort: String {
        String(localized: "m", comment: "Short minutes label")
    }
    
    static var etaLabel: String {
        String(localized: "ETA", comment: "ETA (Estimated Time of Arrival) label")
    }
    
    // MARK: - Actions
    
    static var callAction: String {
        String(localized: "Call", comment: "Call driver button")
    }
    
    // MARK: - Status
    
    static func localizedStatus(_ status: String) -> String {
        switch status.lowercased() {
        case StatusKey.enRoute:
            return String(localized: "En Route", comment: "Trip status: Driver is on the way")
        case StatusKey.nearby:
            return String(localized: "Nearby", comment: "Trip status: Driver is nearby")
        case StatusKey.arrived:
            return String(localized: "Arrived", comment: "Trip status: Driver has arrived")
        case StatusKey.waiting:
            return String(localized: "Waiting", comment: "Trip status: Driver is waiting")
        case StatusKey.inProgress:
            return String(localized: "In Progress", comment: "Trip status: Trip in progress")
        default:
            return String(localized: "Unknown", comment: "Unknown trip status")
        }
    }
}
