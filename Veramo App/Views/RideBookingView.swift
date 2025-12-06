import SwiftUI
import Combine



// MARK: - Vehicle Type Model


struct RideBookingView: View {
    @State private var pickupLocation: String = ""
    @State private var destination: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var passengerCount: Int = 1
    @State private var showVehicleSelection = false
    
    @StateObject private var pickupPlacesService = GooglePlacesService()
    @StateObject private var destinationPlacesService = GooglePlacesService()
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case pickup
        case destination
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Location inputs
                    VStack(spacing: 0) {
                        AutocompleteLocationField(
                            icon: "circle.fill",
                            iconColor: .black,
                            placeholder: "Pickup location",
                            text: $pickupLocation,
                            placesService: pickupPlacesService,
                            isFocused: focusedField == .pickup,
                            onFocus: { focusedField = .pickup },
                            onSelect: { suggestion in
                                pickupLocation = suggestion.fullText
                                pickupPlacesService.clearSuggestions()
                                focusedField = .destination
                            }
                        )
                        .focused($focusedField, equals: .pickup)
                        
                        // Connector line
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 2, height: 20)
                                .padding(.leading, 8)
                            Spacer()
                        }
                        
                        AutocompleteLocationField(
                            icon: "circle.fill",
                            iconColor: .black,
                            placeholder: "Destination",
                            text: $destination,
                            placesService: destinationPlacesService,
                            isFocused: focusedField == .destination,
                            onFocus: { focusedField = .destination },
                            onSelect: { suggestion in
                                destination = suggestion.fullText
                                destinationPlacesService.clearSuggestions()
                                focusedField = nil
                            }
                        )
                        .focused($focusedField, equals: .destination)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Date and Time pickers
                    HStack(spacing: 12) {
                        DatePickerCard(
                            title: "Date",
                            icon: "calendar",
                            date: $selectedDate,
                            displayedComponents: .date
                        )
                        
                        DatePickerCard(
                            title: "Time",
                            icon: "clock",
                            date: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                    }
                    
                    // Passenger count wheel
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Passengers", systemImage: "person.2.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Passengers", selection: $passengerCount) {
                            ForEach(1...8, id: \.self) { count in
                                Text("\(count) \(count == 1 ? "passenger" : "passengers")")
                                    .tag(count)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Search button
                    Button(action: searchRides) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.headline)
                            Text("Search Rides")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.black, Color(.darkGray)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(pickupLocation.isEmpty || destination.isEmpty)
                    .opacity(pickupLocation.isEmpty || destination.isEmpty ? 0.5 : 1)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Book a Ride")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .background(Color(.systemBackground))
            .navigationDestination(isPresented: $showVehicleSelection) {
                VehicleSelectionView(
                    pickup: pickupLocation,
                    destination: destination,
                    date: selectedDate,
                    time: selectedTime,
                    passengers: passengerCount
                )
            }
        }
    }
    
    private func searchRides() {
        showVehicleSelection = true
    }
}



// MARK: - Preview
#Preview {
    RideBookingView()
}
