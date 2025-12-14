//
//  HomeView.swift
//  Veramo App
//
//  Created by rentamac on 12/10/25.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "ch.veramo.app", category: "HomeView")

struct HomeView: View {
    @State private var navigateToBooking = false
    @State private var activeTrips: [CustomerTrip] = []
    @State private var tripStatusService = TripStatusService.shared
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Simple background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 16) {
                        // Top search bar
                        Button(action: {
                            navigateToBooking = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                Text("Enter pickup location")
                                    .foregroundColor(.gray)
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Active Trips Section (if any)
                        if !activeTrips.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Active Trip")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(activeTrips) { trip in
                                    TripCard(
                                        trip: trip,
                                        isWithinOneHour: true,
                                        currentStatus: tripStatusService.getStatus(for: trip.reference)
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Cards section
                        VStack(spacing: 12) {
                            // TWINT payment card
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Easy payment with TWINT")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text("Pay securely and quickly with your TWINT app.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                Spacer()
                            }
                            .padding()
                            .frame(height: 150)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                            
                            // Book a ride card
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Ready? Book a ride.")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Button(action: {
                                    navigateToBooking = true
                                }) {
                                    Text("Book Ride")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.black)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(.separator), lineWidth: 1)
                                        )
                                }
                            }
                            .padding()
                            .frame(height: 150)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Veramo")
                        .font(.title2)
                        .fontWeight(.bold)
                        
                }
                
                // Debug button to show welcome screen
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Toggle hasSeenWelcome by resetting it
                        NotificationCenter.default.post(name: .resetWelcomeScreen, object: nil)
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToBooking) {
                RideBookingView(autoFocusPickup: true)
            }
            .task {
                // Load active trips when view appears
                if appState.isAuthenticated {
                    await loadActiveTrips()
                }
            }
            .onAppear {
                // Refresh when returning to this view
                if appState.isAuthenticated {
                    Task {
                        await loadActiveTrips()
                    }
                }
            }
            .onChange(of: tripStatusService.tripStatuses) { _, _ in
                // Re-filter active trips when statuses update
                filterActiveTrips()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Load trips and filter for active ones
    private func loadActiveTrips() async {
        logger.info("🔄 [HomeView] Loading active trips...")
        
        do {
            let response = try await CustomerTripsService.shared.fetchTrips()
            
            // Combine upcoming and recent past trips
            let allTrips = response.upcoming + response.past
            
            // Filter for trips within monitoring window
            let now = Date()
            let oneHour: TimeInterval = 3600
            let twoHours: TimeInterval = 7200
            
            let tripsInWindow = allTrips.filter { trip in
                guard let pickupDate = trip.date else { return false }
                let timeUntilPickup = pickupDate.timeIntervalSince(now)
                return timeUntilPickup <= oneHour && timeUntilPickup >= -twoHours
            }
            
            logger.debug("📊 [HomeView] Found \(tripsInWindow.count) trips in monitoring window")
            
            // Start monitoring these trips
            for trip in tripsInWindow {
                tripStatusService.startMonitoring(trip: trip)
            }
            
            // Wait a moment for initial status fetch
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Filter for active statuses (on main actor)
            await MainActor.run {
                filterActiveTrips(from: tripsInWindow)
            }
        } catch {
            await MainActor.run {
                logger.error("❌ [HomeView] Error loading trips: \(error.localizedDescription)")
            }
        }
    }
    
    /// Filter trips to only show those with active statuses
    private func filterActiveTrips(from trips: [CustomerTrip]? = nil) {
        let tripsToFilter = trips ?? activeTrips
        
        let activeStatuses = ["en_route", "nearby", "arrived", "waiting"]
        
        let filtered = tripsToFilter.filter { trip in
            guard let status = tripStatusService.getStatus(for: trip.reference) else {
                return false
            }
            return activeStatuses.contains(status.status.lowercased())
        }
        
        activeTrips = filtered
        
        if !filtered.isEmpty {
            logger.info("✅ [HomeView] Showing \(filtered.count) active trip(s)")
        } else {
            logger.debug("📭 [HomeView] No active trips to display")
        }
    }
}

#Preview {
    HomeView()
}
