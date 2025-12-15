//
//  TripTrackingView.swift
//  Veramo App
//
//  View for tracking an active trip with driver location and status
//

import SwiftUI
import MapKit

struct TripTrackingView: View {
    let reference: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var driverService = DriverStatusService.shared
    @State private var showDriverInfo = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map view showing driver location
                if let location = driverService.driverLocation {
                    MapView(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        heading: location.heading
                    )
                    .frame(height: 300)
                    .ignoresSafeArea(edges: .top)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 300)
                        .overlay {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Loading driver location...", comment: "Loading message for driver location")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .ignoresSafeArea(edges: .top)
                }
                
                // Status and info section
                ScrollView {
                    VStack(spacing: 24) {
                        // Current status card
                        statusCard
                        
                        // Driver info card (if available)
                        if driverService.driverInfo != nil {
                            driverInfoCard
                        }
                        
                        // ETA card
                        if let eta = driverService.estimatedArrival {
                            etaCard(eta: eta)
                        } else if let minutes = driverService.driverLocation?.estimatedArrivalMinutes {
                            etaCard(minutes: minutes)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Track Your Ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                // Start tracking when view appears
                driverService.startTracking(reference: reference, intervalSeconds: 10)
            }
            .onDisappear {
                // Stop tracking when view disappears
                driverService.stopTracking()
            }
            .onReceive(NotificationCenter.default.publisher(for: .driverArrived)) { notification in
                if let notificationRef = notification.userInfo?["reference"] as? String,
                   notificationRef == reference {
                    // Show alert or haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var statusCard: some View {
        VStack(spacing: 16) {
            // Status icon
            if let status = driverService.currentStatus {
                HStack(spacing: 16) {
                    statusIcon(for: status)
                        .font(.system(size: 50))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(status.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Reference: \(reference)", comment: "Booking reference label")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            } else {
                HStack(spacing: 16) {
                    ProgressView()
                    Text("Checking status...", comment: "Loading message for trip status")
                        .font(.headline)
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var driverInfoCard: some View {
        if let driver = driverService.driverInfo {
            VStack(alignment: .leading, spacing: 16) {
                Text("Driver Information", comment: "Section title for driver details")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(
                        icon: "person.fill",
                        text: driver.name
                    )
                    
                    if let vehicleMake = driver.vehicleMake,
                       let vehicleModel = driver.vehicleModel {
                        InfoRow(
                            icon: "car.fill",
                            text: "\(vehicleMake) \(vehicleModel)"
                        )
                    }
                    
                    if let color = driver.vehicleColor {
                        InfoRow(
                            icon: "paintpalette.fill",
                            text: color
                        )
                    }
                    
                    if let plate = driver.licensePlate {
                        InfoRow(
                            icon: "rectangle.and.text.magnifyingglass",
                            text: plate
                        )
                    }
                    
                    if let phone = driver.phoneNumber {
                        Button {
                            if let url = URL(string: "tel://\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                Text(phone)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    @ViewBuilder
    private func etaCard(eta: Date) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.blue)
                Text("Estimated Arrival", comment: "Label for estimated arrival time")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                Text(eta, style: .time)
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func etaCard(minutes: Int) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.blue)
                Text("Estimated Arrival", comment: "Label for estimated arrival time")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                Text("~\(minutes) min", comment: "Estimated minutes until arrival")
                    .font(.title)
                    .fontWeight(.semibold)
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func statusIcon(for status: DriverStatus) -> some View {
        Group {
            switch status {
            case .enRoute:
                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
            case .arrived:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: status)
            case .waitingForPickup:
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
            case .pickupComplete:
                Image(systemName: "figure.walk.departure")
                    .foregroundStyle(.blue)
            case .droppingOff:
                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
            case .complete:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .canceled:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Map View

private struct MapView: View {
    let latitude: Double
    let longitude: Double
    let heading: Double?
    
    @State private var region: MKCoordinateRegion
    
    init(latitude: Double, longitude: Double, heading: Double?) {
        self.latitude = latitude
        self.longitude = longitude
        self.heading = heading
        
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        Map(position: .constant(.region(region))) {
            // Driver marker
            Annotation("Driver", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) {
                ZStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 40, height: 40)
                        .shadow(radius: 4)
                    
                    Image(systemName: "car.fill")
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(heading ?? 0))
                }
            }
        }
        .mapStyle(.standard)
        .onChange(of: latitude) { _, newLat in
            updateRegion(lat: newLat, lon: longitude)
        }
        .onChange(of: longitude) { _, newLon in
            updateRegion(lat: latitude, lon: newLon)
        }
    }
    
    private func updateRegion(lat: Double, lon: Double) {
        withAnimation {
            region.center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    TripTrackingView(reference: "VRM-1234-5678")
}
