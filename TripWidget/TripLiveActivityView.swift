//
//  TripLiveActivityView.swift
//  TripWidget
//
//  Live Activity UI for the Widget Extension
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - Lock Screen View

struct TripLiveActivityView: View {
    let context: ActivityViewContext<TripActivityAttributes>
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 10) {
            // Header with status and ETA
            HStack(spacing: 14) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(
                            colorScheme == .dark
                                ? statusColor.opacity(0.3)
                                : statusColor.opacity(0.12)
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: context.state.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(TripWidgetLocalizer.localizedStatus(context.state.status))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(statusColor)
                    
                    if let driverName = context.state.driverName {
                        Text(driverName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    } else {
                        Text(context.attributes.vehicleClass)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Vehicle info section (right-aligned)
                VStack(alignment: .trailing, spacing: 4) {
                    // License plate on top
                    if let licensePlate = context.state.licensePlate {
                        Text(licensePlate)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background {
                                if colorScheme == .dark {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.secondary.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
                                        )
                                }
                            }
                    }
                    
                    // Vehicle make and model
                    if let vehicleInfo = context.state.vehicleInfo {
                        Text(vehicleInfo)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                    }
                    
                    // Vehicle color underneath
                    if let vehicleColor = context.state.vehicleColor {
                        Text(vehicleColor)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    } else if context.state.licensePlate == nil && context.state.vehicleInfo == nil {
                        // Show vehicle class if no vehicle info
                        Text(context.attributes.vehicleClass)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            
            // ETA Badge (if available, show below header)
            if let eta = context.state.etaMinutes {
                HStack {
                    Spacer()
                    VStack(spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(statusColor)
                            
                            Text("\(eta)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(statusColor)
                            
                            Text(TripWidgetLocalizer.minutesLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        // Show distance if available
                        if let distanceKm = context.state.etaDistanceKm {
                            Text(String(format: "%.1f km away", distanceKm))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        if colorScheme == .dark {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(statusColor.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(statusColor.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(statusColor.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
            }
            
            // Route information
            VStack(spacing: 8) {
                // Pickup location
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                colorScheme == .dark
                                    ? Color.green.opacity(0.25)
                                    : Color.green.opacity(0.12)
                            )
                            .frame(width: 20, height: 20)
                        Circle()
                            .strokeBorder(
                                Color.green,
                                lineWidth: 2
                            )
                            .frame(width: 10, height: 10)
                    }
                    
                    Text(context.state.pickupDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                }
                
                // Destination
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                colorScheme == .dark
                                    ? Color.red.opacity(0.25)
                                    : Color.red.opacity(0.12)
                            )
                            .frame(width: 20, height: 20)
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.red)
                    }
                    
                    Text(context.state.destinationDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 14)
            
            // Footer
            if let phone = context.state.driverPhone {
                HStack {
                    Spacer()
                    
                    // Call driver button
                    Link(destination: URL(string: "tel://\(phone)")!) {
                        HStack(spacing: 5) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 12))
                            Text(TripWidgetLocalizer.callAction)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(.thinMaterial)
    }
    
    private var statusColor: Color {
        switch context.state.status.lowercased() {
        case TripWidgetLocalizer.StatusKey.enRoute:
            return .blue
        case TripWidgetLocalizer.StatusKey.nearby:
            return .orange
        case TripWidgetLocalizer.StatusKey.arrived:
            return .green
        case TripWidgetLocalizer.StatusKey.waiting:
            return .orange
        case TripWidgetLocalizer.StatusKey.inProgress:
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Widget Configuration

@available(iOS 16.2, *)
struct TripLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) { context in
            // Lock Screen view
            TripLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island configuration
            DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                ZStack {
                    Circle()
                        .fill(getStatusColor(for: context.state.status).opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: context.state.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(getStatusColor(for: context.state.status))
                }
            }
            
            DynamicIslandExpandedRegion(.trailing) {
                if let eta = context.state.etaMinutes {
                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(spacing: 4) {
                            Text("\(eta)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(getStatusColor(for: context.state.status))
                            Text(TripWidgetLocalizer.minutesShort)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .offset(y: 4)
                        }
                        Text(TripWidgetLocalizer.etaLabel)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1)
                    }
                    .padding(.trailing, 4)
                }
            }
            
            DynamicIslandExpandedRegion(.center) {
                VStack(spacing: 8) {
                    Text(TripWidgetLocalizer.localizedStatus(context.state.status))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(getStatusColor(for: context.state.status))
                    
                    if let driverName = context.state.driverName {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text(driverName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Vehicle info with license plate
                    if let licensePlate = context.state.licensePlate {
                        Text(licensePlate)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.15))
                            )
                        
                        if let vehicleInfo = context.state.vehicleInfo {
                            Text(vehicleInfo)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        if let vehicleColor = context.state.vehicleColor {
                            Text(vehicleColor)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(context.attributes.vehicleClass)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.15))
                            )
                    }
                }
                .padding(.top, 4)
            }
            
            DynamicIslandExpandedRegion(.bottom) {
                VStack(spacing: 12) {
                    // Route information
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.green)
                            Text(context.state.pickupDescription)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.red)
                            Text(context.state.destinationDescription)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        // Trip reference
                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .font(.system(size: 10))
                            Text(context.attributes.tripReference)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                        )
                        
                        Spacer()
                        
                        if let phone = context.state.driverPhone {
                            Link(destination: URL(string: "tel://\(phone)")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 12))
                                    Text(TripWidgetLocalizer.callAction)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        } compactLeading: {
            // Compact leading (left side of notch)
            HStack(spacing: 4) {
                Image(systemName: context.state.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(getStatusColor(for: context.state.status))
            }
        } compactTrailing: {
            // Compact trailing (right side of notch)
            if let eta = context.state.etaMinutes {
                HStack(spacing: 2) {
                    Text("\(eta)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(getStatusColor(for: context.state.status))
                    Text(String(TripWidgetLocalizer.minutesShort.prefix(1)))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(getStatusColor(for: context.state.status).opacity(0.7))
                }
            } else {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(getStatusColor(for: context.state.status))
            }
        } minimal: {
            // Minimal view (when multiple activities)
            ZStack {
                Circle()
                    .fill(getStatusColor(for: context.state.status).opacity(0.3))
                    .frame(width: 20, height: 20)
                
                Image(systemName: "car.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(getStatusColor(for: context.state.status))
            }
        }
        }
    }
    
    // Helper function to get status color
    private func getStatusColor(for status: String) -> Color {
        switch status.lowercased() {
        case TripWidgetLocalizer.StatusKey.enRoute:
            return .blue
        case TripWidgetLocalizer.StatusKey.nearby:
            return .orange
        case TripWidgetLocalizer.StatusKey.arrived:
            return .green
        case TripWidgetLocalizer.StatusKey.waiting:
            return .orange
        case TripWidgetLocalizer.StatusKey.inProgress:
            return .purple
        default:
            return .gray
        }
    }
}

