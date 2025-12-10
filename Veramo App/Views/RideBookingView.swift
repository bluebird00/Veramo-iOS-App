import SwiftUI
import Combine
import MapKit

// MARK: - Vehicle Type Model

struct RideBookingView: View {
    @State private var pickupLocation: String = ""
    @State private var destination: String = ""
    @State private var pickupLocationEnglish: String = ""  // For database
    @State private var destinationEnglish: String = ""  // For database
    @State private var pickupPlaceId: String? = nil
    @State private var destinationPlaceId: String? = nil
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: Date = Date()
    @State private var passengerCount: Int = 1
    @State private var showVehicleSelection = false
    
    var autoFocusPickup: Bool = false  // New parameter for auto-focus
    
    // Map state
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.3769, longitude: 8.5417), // Zurich
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )
    @State private var pickupCoordinate: CLLocationCoordinate2D?
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    @State private var route: MKRoute?
    @State private var animatedMarkerCoordinate: CLLocationCoordinate2D?
    @State private var animationProgress: Double = 0.0
    @State private var animationTimer: Timer?
    @State private var markerOpacity: Double = 1.0
    
    @StateObject private var pickupPlacesService = GooglePlacesService()
    @StateObject private var destinationPlacesService = GooglePlacesService()
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case pickup
        case destination
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Map on top
                Map(position: $cameraPosition) {
                    // Pickup marker
                    if let pickupCoordinate {
                        Annotation("Pickup", coordinate: pickupCoordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                                
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                    
                    // Destination marker
                    if let destinationCoordinate {
                        Annotation("Destination", coordinate: destinationCoordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                                
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }
                    
                    // Animated marker traveling along route
                    if let animatedMarkerCoordinate {
                        Annotation("", coordinate: animatedMarkerCoordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 16, height: 16)
                                    .shadow(color: .black.opacity(0.5), radius: 4)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 16, height: 16)
                            }
                            .opacity(markerOpacity)
                        }
                    }
                    
                    // Route polyline
                    if let route {
                        MapPolyline(route.polyline)
                            .stroke(Color.black, lineWidth: 3)
                    }
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: false))
                .ignoresSafeArea()
                
                // Bottom sheet content that switches between booking form and vehicle selection
                VStack(spacing: 0) {
                    // Draggable handle
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 8)
                    
                    if !showVehicleSelection {
                        // Booking form
                        VStack(spacing: 0) {
                            // Title
                            Text("Book a Ride")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                            
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
                                                pickupLocationEnglish = suggestion.fullTextEnglish
                                                pickupPlaceId = suggestion.placeId
                                                pickupPlacesService.clearSuggestions()
                                                
                                                // Only auto-focus destination if it's empty
                                                if destination.isEmpty {
                                                    focusedField = .destination
                                                } else {
                                                    focusedField = nil
                                                }
                                                
                                                // Geocode and update map
                                                geocodeLocation(suggestion.fullText) { coordinate in
                                                    pickupCoordinate = coordinate
                                                    updateMapCamera()
                                                    
                                                    // Recalculate route if destination already exists
                                                    if destinationCoordinate != nil {
                                                        calculateRoute()
                                                    }
                                                }
                                            }
                                        )
                                        .focused($focusedField, equals: .pickup)
                                        .onChange(of: pickupLocation) { oldValue, newValue in
                                            // If pickup is cleared, reset its coordinate and route
                                            if newValue.isEmpty {
                                                pickupCoordinate = nil
                                                pickupLocationEnglish = ""
                                                pickupPlaceId = nil
                                                route = nil
                                                animatedMarkerCoordinate = nil
                                                animationProgress = 0.0
                                                animationTimer?.invalidate()
                                                animationTimer = nil
                                                markerOpacity = 1.0
                                                
                                                // If destination still exists, zoom to it
                                                if destinationCoordinate != nil {
                                                    updateMapCamera()
                                                }
                                            }
                                        }
                                        
                                        // Connector line with divider
                                        HStack(spacing: 0) {
                                            // Vertical connector
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.6))
                                                .frame(width: 2, height: 20)
                                                .padding(.leading, 8)
                                            
                                            // Horizontal divider (doesn't extend to left edge)
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(height: 1)
                                                .padding(.leading, 30)
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
                                                destinationEnglish = suggestion.fullTextEnglish
                                                destinationPlaceId = suggestion.placeId
                                                destinationPlacesService.clearSuggestions()
                                                focusedField = nil
                                                
                                                // Geocode and calculate route
                                                geocodeLocation(suggestion.fullText) { coordinate in
                                                    destinationCoordinate = coordinate
                                                    updateMapCamera()
                                                    calculateRoute()
                                                }
                                            }
                                        )
                                        .focused($focusedField, equals: .destination)
                                        .onChange(of: destination) { oldValue, newValue in
                                            // If destination is cleared, reset its coordinate and route
                                            if newValue.isEmpty {
                                                destinationCoordinate = nil
                                                destinationEnglish = ""
                                                destinationPlaceId = nil
                                                route = nil
                                                animatedMarkerCoordinate = nil
                                                animationProgress = 0.0
                                                animationTimer?.invalidate()
                                                animationTimer = nil
                                                markerOpacity = 1.0
                                                
                                                // If pickup still exists, zoom to it
                                                if pickupCoordinate != nil {
                                                    updateMapCamera()
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 20)
                                    
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
                                    .padding(.horizontal)
                                    
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
                                    .padding(.horizontal)
                                }
                                .padding(.top, 16)
                                .padding(.bottom, 24)
                            }
                        }
                    } else {
                        // Vehicle selection
                        VehicleSelectionView(
                            pickup: pickupLocation,
                            destination: destination,
                            pickupEnglish: pickupLocationEnglish,
                            destinationEnglish: destinationEnglish,
                            date: selectedDate,
                            time: selectedTime,
                            passengers: passengerCount,
                            pickupPlaceId: pickupPlaceId,
                            destinationPlaceId: destinationPlaceId,
                            showVehicleSelection: $showVehicleSelection
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.5)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .onAppear {
                if autoFocusPickup {
                    // Small delay to ensure view is fully loaded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedField = .pickup
                    }
                }
            }
    }
    
    private func searchRides() {
        showVehicleSelection = true
    }
    
    // MARK: - Map Helper Functions
    
    private func geocodeLocation(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = address
        searchRequest.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.3769, longitude: 8.5417),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.location.coordinate else {
                completion(nil)
                return
            }
            completion(coordinate)
        }
    }
    
    private func updateMapCamera() {
        if let pickup = pickupCoordinate, let destination = destinationCoordinate {
            // Show both locations
            let minLat = min(pickup.latitude, destination.latitude)
            let maxLat = max(pickup.latitude, destination.latitude)
            let minLon = min(pickup.longitude, destination.longitude)
            let maxLon = max(pickup.longitude, destination.longitude)
            
            // Calculate the span with extra padding
            let latDelta = (maxLat - minLat) * 2.2
            let lonDelta = (maxLon - minLon) * 2.2
            
            // Shift the center upward to account for the bottom sheet (50% of screen)
            let centerLat = (minLat + maxLat) / 2
            let adjustedCenterLat = centerLat + (latDelta * 0.2) // Shift up by 20% of span
            
            let center = CLLocationCoordinate2D(
                latitude: adjustedCenterLat,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: latDelta,
                longitudeDelta: lonDelta
            )
            
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
            }
        } else if let pickup = pickupCoordinate {
            // Show only pickup - shift center down so the pickup appears in the top half of the map
            // Bottom sheet covers bottom 50%, so shift down by 25% of the span to center in visible area
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let adjustedLat = pickup.latitude - (span.latitudeDelta * 0.25) // Shift down (subtract)
            
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: adjustedLat, longitude: pickup.longitude),
                    span: span
                ))
            }
        } else if let destination = destinationCoordinate {
            // Show only destination - shift center down so the destination appears in the top half of the map
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let adjustedLat = destination.latitude - (span.latitudeDelta * 0.25) // Shift down (subtract)
            
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: adjustedLat, longitude: destination.longitude),
                    span: span
                ))
            }
        }
    }
    
    private func calculateRoute() {
        guard let pickup = pickupCoordinate,
              let destination = destinationCoordinate else {
            return
        }
        
        let request = MKDirections.Request()
        
        // Create map items directly from coordinates
        let pickupLocation = CLLocation(latitude: pickup.latitude, longitude: pickup.longitude)
        let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        
        let pickupItem = MKMapItem(location: pickupLocation, address: nil)
        let destinationItem = MKMapItem(location: destinationLocation, address: nil)
        
        request.source = pickupItem
        request.destination = destinationItem
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                return
            }
            
            self.route = route
            
            // Update camera to fit the route with proper padding
            self.fitRouteInView(route: route)
            
            // Start the animation
            self.startRouteAnimation()
        }
    }
    
    private func fitRouteInView(route: MKRoute) {
        let rect = route.polyline.boundingMapRect
        
        // Convert map rect to coordinate region
        let topLeft = MKMapPoint(x: rect.minX, y: rect.minY)
        let bottomRight = MKMapPoint(x: rect.maxX, y: rect.maxY)
        
        let topLeftCoord = topLeft.coordinate
        let bottomRightCoord = bottomRight.coordinate
        
        let center = CLLocationCoordinate2D(
            latitude: (topLeftCoord.latitude + bottomRightCoord.latitude) / 2,
            longitude: (topLeftCoord.longitude + bottomRightCoord.longitude) / 2
        )
        
        // Increase span to account for bottom sheet covering 50% of screen
        let span = MKCoordinateSpan(
            latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * 2.5,
            longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * 1.5
        )
        
        // Shift center DOWNWARD (subtract from latitude) to move the visible area up
        // This accounts for the bottom sheet covering 50% of screen
        let adjustedCenter = CLLocationCoordinate2D(
            latitude: center.latitude - (span.latitudeDelta * 0.25),
            longitude: center.longitude
        )
        
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(center: adjustedCenter, span: span))
        }
    }
    
    // MARK: - Route Animation
    
    private func startRouteAnimation() {
        guard let route = route else { return }
        
        // Cancel any existing animation
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Reset animation
        animationProgress = 0.0
        animatedMarkerCoordinate = nil
        markerOpacity = 1.0
        
        // Calculate animation duration based on route distance
        // Route distance is in meters, we want to simulate 500 km/h
        let distanceInKm = route.distance / 1000.0
        let speedKmh = 500.0
        let durationInHours = distanceInKm / speedKmh
        let durationInSeconds = durationInHours * 3600.0
        
        // Cap the duration between 0.6 and 5 seconds for practical viewing
        let clampedDuration = min(max(durationInSeconds, 0.6), 5.0)
        
        // Start animation after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.animateMarkerAlongRoute(route: route, duration: clampedDuration)
        }
    }
    
    private func animateMarkerAlongRoute(route: MKRoute, duration: TimeInterval) {
        let polyline = route.polyline
        let pointCount = polyline.pointCount
        
        guard pointCount > 0 else { return }
        
        // Pre-calculate cumulative distances for each point
        let points = polyline.points()
        var cumulativeDistances: [Double] = [0.0]
        var totalDistance = 0.0
        
        for i in 1..<pointCount {
            let prevPoint = points[i-1]
            let currPoint = points[i]
            
            let prevLocation = CLLocation(
                latitude: prevPoint.coordinate.latitude,
                longitude: prevPoint.coordinate.longitude
            )
            let currLocation = CLLocation(
                latitude: currPoint.coordinate.latitude,
                longitude: currPoint.coordinate.longitude
            )
            
            let segmentDistance = prevLocation.distance(from: currLocation)
            totalDistance += segmentDistance
            cumulativeDistances.append(totalDistance)
        }
        
        let startTime = Date()
        let updateInterval: TimeInterval = 1.0 / 60.0 // 60 FPS
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / duration, 1.0)
            
            // Calculate target distance along the route
            let targetDistance = progress * totalDistance
            
            // Binary search to find the segment
            var left = 0
            var right = cumulativeDistances.count - 1
            
            while left < right {
                let mid = (left + right + 1) / 2
                if cumulativeDistances[mid] <= targetDistance {
                    left = mid
                } else {
                    right = mid - 1
                }
            }
            
            let index = left
            
            // Interpolate between points if not at the last point
            if index < pointCount - 1 {
                let segmentStart = cumulativeDistances[index]
                let segmentEnd = cumulativeDistances[index + 1]
                let segmentProgress = (targetDistance - segmentStart) / (segmentEnd - segmentStart)
                
                let startCoord = points[index].coordinate
                let endCoord = points[index + 1].coordinate
                
                // Linear interpolation between coordinates
                let lat = startCoord.latitude + (endCoord.latitude - startCoord.latitude) * segmentProgress
                let lon = startCoord.longitude + (endCoord.longitude - startCoord.longitude) * segmentProgress
                
                self.animatedMarkerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            } else {
                self.animatedMarkerCoordinate = points[pointCount - 1].coordinate
            }
            
            self.animationProgress = progress
            
            // Stop when complete
            if progress >= 1.0 {
                timer.invalidate()
                self.animationTimer = nil
                self.animatedMarkerCoordinate = nil
                self.markerOpacity = 1.0
            }
        }
        
        // Ensure timer runs during scrolling and other UI interactions
        if let timer = animationTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
}



// MARK: - Preview
#Preview {
    RideBookingView()
}
