//
//  TripsView.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "ch.veramo.app", category: "TripsView")

struct TripsView: View {
    @State private var upcomingTrips: [CustomerTrip] = []
    @State private var pastTrips: [CustomerTrip] = []
    @State private var customerName: String = ""
    @State private var isLoading: Bool = true
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedTab: TripTab = .upcoming
    @State private var tripStatusService = TripStatusService.shared
    
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    enum TripTab {
        case upcoming
        case past
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                authenticatedContentView
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("My Trips")
                            .font(.title2)
                            .fontWeight(.bold)
                        if !customerName.isEmpty {
                            Text(customerName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Only show menu if authenticated
                if appState.isAuthenticated {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(action: loadTrips) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: logout) {
                                Label("Log Out", systemImage: "arrow.right.square")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .task {
                if appState.isAuthenticated {
                    logger.debug("👤 [TripsView] User authenticated - loading trips")
                    await loadTripsAsync()
                } else {
                    logger.warning("⚠️ [TripsView] User not authenticated")
                    isLoading = false
                }
            }
            .onDisappear {
                // Stop monitoring when view disappears
                logger.info("👋 [TripsView] View disappeared - stopping all monitoring")
                tripStatusService.stopAllMonitoring()
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
                if errorMessage.contains("Session expired") {
                    Button("Log In") {
                        AuthenticationManager.shared.logout()
                        dismiss()
                    }
                }
            } message: {
                Text(errorMessage)
            }
            // Periodically reclassify trips as statuses update
            .onChange(of: tripStatusService.tripStatuses) { _, _ in
                reclassifyTripsBasedOnStatus()
            }
        }
    }
    
    // MARK: - View Components
    
    private var authenticatedContentView: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("Trip Type", selection: $selectedTab) {
                Text("Upcoming (\(upcomingTrips.count))").tag(TripTab.upcoming)
                Text("Past (\(pastTrips.count))").tag(TripTab.past)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Text("Loading your trips...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
                Spacer()
            } else {
                // Trip List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        let trips = selectedTab == .upcoming ? upcomingTrips : pastTrips
                        
                        if trips.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(trips) { trip in
                                TripCard(
                                    trip: trip,
                                    isWithinOneHour: isWithinMonitoringWindow(trip),
                                    currentStatus: tripStatusService.getStatus(for: trip.reference)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedTab == .upcoming ? "calendar.badge.clock" : "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(selectedTab == .upcoming ? "No Upcoming Trips" : "No Past Trips")
                .font(.headline)
            
            Text(selectedTab == .upcoming ? "Book your first ride to see it here" : "Your completed trips will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
    }
    
    // MARK: - Actions
    
    private func logout() {
        appState.logout()
    }
    
    // MARK: - Load Trips
    
    private func loadTrips() {
        Task {
            await loadTripsAsync()
        }
    }
    
    private func loadTripsAsync() async {
        isLoading = true
        logger.info("🔄 [TripsView] Loading trips...")
        
        do {
            let response = try await CustomerTripsService.shared.fetchTrips()
            
            await MainActor.run {
                // Reclassify trips based on monitoring window and status
                let (upcoming, past) = reclassifyTrips(
                    upcomingFromAPI: response.upcoming,
                    pastFromAPI: response.past
                )
                
                upcomingTrips = upcoming
                pastTrips = past
                customerName = response.customer?.name ?? ""
                isLoading = false
                
                logger.info("✅ [TripsView] Loaded \(self.upcomingTrips.count) upcoming, \(self.pastTrips.count) past trips (after reclassification)")
                
                // Start monitoring trips within the monitoring window
                startMonitoringTrips()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
                logger.error("❌ [TripsView] Error loading trips: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Trip Classification
    
    /// Reclassify trips: Move active trips from past to upcoming if they're still in progress
    private func reclassifyTrips(upcomingFromAPI: [CustomerTrip], pastFromAPI: [CustomerTrip]) -> ([CustomerTrip], [CustomerTrip]) {
        let now = Date()
        let twoHours: TimeInterval = 7200
        
        var upcoming = upcomingFromAPI
        var past: [CustomerTrip] = []
        
        // Check past trips - if within 2 hours after pickup AND not completed/cancelled, move to upcoming
        for trip in pastFromAPI {
            guard let pickupDate = trip.date else {
                past.append(trip)
                continue
            }
            
            let timeUntilPickup = pickupDate.timeIntervalSince(now)
            
            // If pickup was within last 2 hours, check if trip is still active
            if timeUntilPickup >= -twoHours && timeUntilPickup < 0 {
                // Check current status from service
                let currentStatus = tripStatusService.getStatus(for: trip.reference)
                let statusString = currentStatus?.status.lowercased() ?? ""
                
                // Only move to upcoming if NOT completed or cancelled
                if statusString != "completed" && statusString != "cancelled" {
                    logger.debug("🔄 [TripsView] Moving \(trip.reference) from past to upcoming (pickup was \(abs(Int(timeUntilPickup / 60))) min ago, status: \(statusString.isEmpty ? "unknown" : statusString))")
                    upcoming.append(trip)
                } else {
                    logger.debug("⏭️ [TripsView] Keeping \(trip.reference) in past (status: \(statusString))")
                    past.append(trip)
                }
            } else {
                past.append(trip)
            }
        }
        
        // Sort upcoming by pickup date (earliest first)
        upcoming.sort { trip1, trip2 in
            guard let date1 = trip1.date, let date2 = trip2.date else { return false }
            return date1 < date2
        }
        
        // Sort past by pickup date (most recent first)
        past.sort { trip1, trip2 in
            guard let date1 = trip1.date, let date2 = trip2.date else { return false }
            return date1 > date2
        }
        
        return (upcoming, past)
    }
    
    /// Re-run classification when trip statuses update (move completed trips from upcoming to past)
    private func reclassifyTripsBasedOnStatus() {
        let now = Date()
        let twoHours: TimeInterval = 7200
        
        var newUpcoming: [CustomerTrip] = []
        var tripsToMoveDown: [CustomerTrip] = []
        
        // Check each upcoming trip - move to past if completed/cancelled
        for trip in upcomingTrips {
            guard let pickupDate = trip.date else {
                newUpcoming.append(trip)
                continue
            }
            
            let timeUntilPickup = pickupDate.timeIntervalSince(now)
            
            // Only reclassify trips that have passed their pickup time
            if timeUntilPickup < 0 {
                let currentStatus = tripStatusService.getStatus(for: trip.reference)
                let statusString = currentStatus?.status.lowercased() ?? ""
                
                // Move to past if completed or cancelled, or if more than 2 hours past pickup
                if statusString == "completed" || statusString == "cancelled" || timeUntilPickup < -twoHours {
                    logger.debug("⬇️ [TripsView] Moving \(trip.reference) from upcoming to past (status: \(statusString.isEmpty ? "too old" : statusString))")
                    tripsToMoveDown.append(trip)
                } else {
                    newUpcoming.append(trip)
                }
            } else {
                // Future trips stay in upcoming
                newUpcoming.append(trip)
            }
        }
        
        // Update arrays if anything changed
        if !tripsToMoveDown.isEmpty {
            upcomingTrips = newUpcoming
            pastTrips.insert(contentsOf: tripsToMoveDown, at: 0)
            
            // Re-sort past trips
            pastTrips.sort { trip1, trip2 in
                guard let date1 = trip1.date, let date2 = trip2.date else { return false }
                return date1 > date2
            }
            
            logger.info("♻️ [TripsView] Reclassified \(tripsToMoveDown.count) trip(s). Now: \(upcomingTrips.count) upcoming, \(pastTrips.count) past")
        }
    }
    
    // MARK: - Trip Status Monitoring
    
    private func startMonitoringTrips() {
        let now = Date()
        let oneHour: TimeInterval = 3600
        let twoHours: TimeInterval = 7200
        
        logger.info("📡 [TripsView] Starting to monitor trips...")
        
        var monitoredCount = 0
        
        // Monitor upcoming trips (within 1 hour before OR 2 hours after pickup)
        // Note: After reclassification, all active trips (including those recently started)
        // are already in the upcoming array, so we don't need to check past trips separately
        for trip in upcomingTrips {
            guard let pickupDate = trip.date else {
                logger.debug("⏭️ [TripsView] Skipping trip \(trip.reference) - no pickup date")
                continue
            }
            
            let timeUntilPickup = pickupDate.timeIntervalSince(now)
            let minutesUntilPickup = Int(timeUntilPickup / 60)
            
            // Monitor if within window: -2 hours <= pickup time <= +1 hour
            if timeUntilPickup <= oneHour && timeUntilPickup >= -twoHours {
                if timeUntilPickup >= 0 {
                    logger.info("📍 [TripsView] Will monitor \(trip.reference) (pickup in \(minutesUntilPickup) min)")
                } else {
                    let minutesPastPickup = abs(minutesUntilPickup)
                    logger.info("📍 [TripsView] Will monitor \(trip.reference) (pickup was \(minutesPastPickup) min ago)")
                }
                tripStatusService.startMonitoring(trip: trip)
                monitoredCount += 1
            } else if timeUntilPickup > oneHour {
                logger.debug("⏭️ [TripsView] Skipping \(trip.reference) - pickup in \(minutesUntilPickup) min (too early)")
            }
        }
        
        logger.info("✅ [TripsView] Started monitoring \(monitoredCount) of \(self.upcomingTrips.count) upcoming trips")
    }
    
    private func isWithinMonitoringWindow(_ trip: CustomerTrip) -> Bool {
        guard let pickupDate = trip.date else { return false }
        let now = Date()
        let timeUntilPickup = pickupDate.timeIntervalSince(now)
        let oneHour: TimeInterval = 3600
        let twoHours: TimeInterval = 7200
        // Show status indicator if within 1 hour before OR 2 hours after pickup
        return timeUntilPickup <= oneHour && timeUntilPickup >= -twoHours
    }
}

// MARK: - Trip Card

struct TripCard: View {
    let trip: CustomerTrip
    let isWithinOneHour: Bool
    let currentStatus: TripStatus?
    
    @State private var isPulsing = false
    @State private var showTrackingView = false
    
    var body: some View {
        // Disabled: tap-to-open TripTrackingView
        cardContent
        /*
        Button {
            // Only show tracking view if we have active status
            if currentStatus != nil && isWithinOneHour {
                logger.info("🗺️ [TripCard] Opening tracking view for \(trip.reference)")
                showTrackingView = true
            } else {
                logger.debug("⚠️ [TripCard] Cannot open tracking - no active status for \(trip.reference)")
            }
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showTrackingView) {
            TripTrackingView(reference: trip.reference)
        }
        */
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Reference and Status
            HStack {
                Text(trip.reference)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Real-time status (if within 1 hour and status available)
                if let status = currentStatus, isWithinOneHour {
                    HStack(spacing: 6) {
                        // Pulsating dot
                        Circle()
                            .fill(statusColor(for: status.status))
                            .frame(width: 8, height: 8)
                            .scaleEffect(isPulsing ? 1.3 : 1.0)
                            .opacity(isPulsing ? 0.6 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                                value: isPulsing
                            )
                            .onAppear {
                                isPulsing = true
                            }
                        
                        Text(statusDisplayName(for: status.status))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor(for: status.status))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor(for: status.status).opacity(0.15))
                    .cornerRadius(12)
                } else {
                    // Booking status badge (fallback)
                    Text(trip.bookingStatus.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(bookingStatusColor(for: trip.bookingStatus))
                        .cornerRadius(12)
                }
            }
            
            Divider()
            
            // Route
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 2, height: 30)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(trip.pickupDescription)
                        .font(.subheadline)
                        .lineLimit(2)
                    Text(trip.destinationDescription)
                        .font(.subheadline)
                        .lineLimit(2)
                }
            }
            
            Divider()
            
            // Trip Details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(trip.formattedDate, systemImage: "calendar")
                    Label(trip.formattedTime, systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "car.fill")
                        Text(trip.vehicleDisplayName)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                        Text("\(trip.passengers)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            // Driver info and ETA (if status is available)
            if let status = currentStatus, isWithinOneHour {
                Divider()
                
                VStack(spacing: 8) {
                    // Driver info
                    if let driver = status.driver {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Driver")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(driver.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            
                            // Call button
                            if let url = URL(string: "tel://\(driver.phone)") {
                                Button {
                                    UIApplication.shared.open(url)
                                } label: {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                        .padding(8)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                    
                    // ETA
                    if let eta = status.eta {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Estimated Arrival")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("~\(eta.minutes) min")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                    }
                }
            }
            
            // Flight Number (if available)
            if let flightNumber = trip.flightNumber {
                HStack {
                    Image(systemName: "airplane")
                        .foregroundColor(.secondary)
                    Text("Flight: \(flightNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Price
            HStack {
                Text("Total Price")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(trip.formattedPrice)
                    .font(.headline)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        /*
        // Disabled: chevron indicator (card no longer tappable)
        .overlay(
            // Show chevron if tappable
            Group {
                if currentStatus != nil && isWithinOneHour {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(8)
                            Spacer()
                        }
                    }
                }
            }
        )
        */
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "assigned":
            return .blue
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
        case "completed":
            return .green
        default:
            return .gray
        }
    }
    
    private func bookingStatusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "confirmed":
            return .green
        case "pending":
            return .orange
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private func statusDisplayName(for status: String) -> String {
        switch status.lowercased() {
        case "assigned":
            return "Driver Assigned"
        case "en_route":
            return "En Route"
        case "nearby":
            return "Nearby"
        case "arrived":
            return "Arrived"
        case "waiting":
            return "Waiting"
        case "in_progress":
            return "In Progress"
        case "completed":
            return "Completed"
        default:
            return status.capitalized
        }
    }
}

#Preview {
    TripsView()
}
