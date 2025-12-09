//
//  TripsView.swift
//  Veramo App
//
//  Created by rentamac on 12/7/25.
//

import SwiftUI

struct TripsView: View {
    @State private var upcomingTrips: [CustomerTrip] = []
    @State private var pastTrips: [CustomerTrip] = []
    @State private var customerName: String = ""
    @State private var isLoading: Bool = true
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedTab: TripTab = .upcoming
    
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    enum TripTab {
        case upcoming
        case past
    }
    
    var body: some View {
        NavigationStack {
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
                                    TripCard(trip: trip)
                                }
                            }
                        }
                        .padding()
                    }
                }
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
            .task {
                await loadTripsAsync()
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
        
        do {
            let response = try await CustomerTripsService.shared.fetchTrips()
            
            await MainActor.run {
                upcomingTrips = response.upcoming
                pastTrips = response.past
                customerName = response.customer?.name ?? ""
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

// MARK: - Trip Card

struct TripCard: View {
    let trip: CustomerTrip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Reference and Status
            HStack {
                Text(trip.reference)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Status badge
                Text(trip.bookingStatus.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor(for: trip.bookingStatus))
                    .cornerRadius(12)
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
    }
    
    private func statusColor(for status: String) -> Color {
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
}

#Preview {
    TripsView()
}
