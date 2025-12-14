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
    
    var body: some View {
        VStack(spacing: 10) {
            // Header with status and ETA
            HStack(spacing: 14) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: context.state.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.statusDisplayName)
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
                
                // ETA Badge
                if let eta = context.state.etaMinutes {
                    VStack(spacing: 3) {
                        Text("\(eta)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(statusColor)
                        Text("MIN")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                    }
                    .frame(width: 60)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(statusColor.opacity(0.15))
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            
            // Route information
            VStack(spacing: 8) {
                // Pickup location
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 20, height: 20)
                        Circle()
                            .strokeBorder(Color.green, lineWidth: 2)
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
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 20, height: 20)
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
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
            HStack(spacing: 10) {
                // Trip reference
                HStack(spacing: 4) {
                    Image(systemName: "number.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(context.attributes.tripReference)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Call driver button
                if let phone = context.state.driverPhone {
                    Link(destination: URL(string: "tel://\(phone)")!) {
                        HStack(spacing: 5) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 12))
                            Text("Call")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(Color(.systemBackground))
    }
    
    private var statusColor: Color {
        switch context.state.status.lowercased() {
        case "en_route":
            return .blue
        case "nearby":
            return .orange
        case "arrived":
            return .green
        case "waiting":
            return .orange
        case "in_progress":
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
                            Text("min")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .offset(y: 4)
                        }
                        Text("ETA")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(1)
                    }
                    .padding(.trailing, 4)
                }
            }
            
            DynamicIslandExpandedRegion(.center) {
                VStack(spacing: 8) {
                    Text(context.state.statusDisplayName)
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
                                    Text("Call")
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
                    Text("m")
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
        case "en_route":
            return .blue
        case "nearby":
            return .orange
        case "arrived":
            return .green
        case "waiting":
            return .orange
        case "in_progress":
            return .purple
        default:
            return .gray
        }
    }
}
