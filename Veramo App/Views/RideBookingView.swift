import SwiftUI
import Combine
import MapKit

// MARK: - Vehicle Type Model

struct RideBookingView: View {
    // Swiss timezone constant
    private static let swissTimeZone = TimeZone(identifier: "Europe/Zurich") ?? .current
    
    @State private var pickupLocation: String = ""
    @State private var destination: String = ""
    @State private var pickupLocationEnglish: String = ""  // For database
    @State private var destinationEnglish: String = ""  // For database
    @State private var pickupPlaceId: String? = nil
    @State private var destinationPlaceId: String? = nil
    @State private var selectedDate: Date = {
        // Create a date that's 4 hours in the future in Swiss timezone
        var calendar = Calendar.current
        calendar.timeZone = swissTimeZone
        let futureDate = calendar.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        print("📅 Default date set to: \(futureDate) (Swiss TZ)")
        return futureDate
    }()
    @State private var selectedTime: Date = {
        // Create a time that's 4 hours in the future in Swiss timezone
        var calendar = Calendar.current
        calendar.timeZone = swissTimeZone
        let futureTime = calendar.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        print("⏰ Default time set to: \(futureTime) (Swiss TZ)")
        return futureTime
    }()
    @State private var passengerCount: Int = 1
    @State private var showVehicleSelection = false
    @State private var showingTimePicker = false  // Track time picker modal state
    @State private var showingDatePicker = false  // Unused, but needed for DatePickerCard signature
    @State private var isVehicleListCompact = false  // Track compact mode for vehicle list
    
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
    @State private var keyboardHeight: CGFloat = 0
    @State private var sheetOffset: CGFloat = 0
    @State private var lastSheetOffset: CGFloat = 0
    @State private var lastFocusedField: Field? = nil
    @State private var isDragging: Bool = false
    
    // Location suggestions state
    @State private var pickupSuggestions: [LocationSuggestion] = []
    @State private var destinationSuggestions: [LocationSuggestion] = []
    @State private var isLoadingPickupSuggestions = false
    @State private var isLoadingDestinationSuggestions = false
    
    enum Field {
        case pickup
        case destination
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Map on top
                mapView
                
                // Bottom sheet content that switches between booking form and vehicle selection
                bottomSheetContent
                    .frame(maxWidth: .infinity, maxHeight: sheetMaxHeight(for: geometry))
                    .background(bottomSheetBackground)
                    .offset(y: sheetOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: keyboardHeight)
                    .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isVehicleListCompact)
                    .gesture(sheetDragGesture)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .onAppear {
                // Preload pickup suggestions so they're ready immediately
                Task {
                    await preloadPickupSuggestions()
                }
                
                if autoFocusPickup {
                    // Small delay to ensure view is fully loaded
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedField = .pickup
                    }
                }
            }
            .onChange(of: focusedField) { oldValue, newValue in
                // Track the last focused field
                if let newValue = newValue {
                    lastFocusedField = newValue
                    
                    // Load suggestions when field gains focus
                    Task {
                        await loadSuggestionsForField(newValue)
                    }
                }
                
                // Only reset sheet offset if not currently dragging
                if !isDragging && newValue == nil {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        sheetOffset = 0
                        lastSheetOffset = 0
                    }
                }
            }
            .onChange(of: keyboardHeight) { oldValue, newValue in
                // When keyboard dismisses and we're not dragging, reset sheet position
                if newValue == 0 && !isDragging {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        sheetOffset = 0
                        lastSheetOffset = 0
                    }
                }
            }
            .overlay {
                // Time picker modal at top level
                if showingTimePicker {
                    TimePickerModal(
                        showingPicker: $showingTimePicker,
                        date: $selectedTime,
                        timeZone: Self.swissTimeZone
                    )
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
    }
    
    // MARK: - View Components
    
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Pickup marker
            if let pickupCoordinate {
                Annotation(pickupLocation.isEmpty ? "Pickup" : pickupLocation.components(separatedBy: ",").first ?? pickupLocation, coordinate: pickupCoordinate) {
                    mapMarkerView(color: .white, innerColor: .black)
                }
            }
            
            // Destination marker
            if let destinationCoordinate {
                Annotation(destination.isEmpty ? "Destination" : destination.components(separatedBy: ",").first ?? destination, coordinate: destinationCoordinate) {
                    mapMarkerView(color: .white, innerColor: .black)
                }
            }
            
            // Animated marker traveling along route
            if let animatedMarkerCoordinate {
                Annotation("", coordinate: animatedMarkerCoordinate) {
                    animatedMarkerView
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
    }
    
    private func mapMarkerView(color: Color, innerColor: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
            
            Circle()
                .fill(innerColor)
                .frame(width: 10, height: 10)
        }
    }
    
    private var animatedMarkerView: some View {
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
    
    @ViewBuilder
    private var bottomSheetContent: some View {
        VStack(spacing: 0) {
            draggableHandle
            
            if !showVehicleSelection {
                bookingFormView
            } else {
                vehicleSelectionView
            }
        }
    }
    
    private var draggableHandle: some View {
        Capsule()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .contentShape(Rectangle())
            .gesture(handleDragGesture)
    }
    
    private var handleDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                let translation = value.translation.height
                sheetOffset = lastSheetOffset + translation
                
                // If dragging down, dismiss keyboard
                if translation > 10 {
                    focusedField = nil
                }
            }
            .onEnded { value in
                isDragging = false
                let translation = value.translation.height
                let velocity = value.predictedEndTranslation.height - value.translation.height
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    // Dismiss keyboard if dragged down significantly
                    if translation > 50 || velocity > 100 {
                        focusedField = nil
                        sheetOffset = 0
                        lastSheetOffset = 0
                    } else if translation < -50 || velocity < -100 {
                        // Expand sheet upward and focus last field
                        sheetOffset = 0
                        lastSheetOffset = 0
                        
                        // Immediately focus to trigger keyboard
                        // Focus the last used field or default to pickup
                        if let lastField = lastFocusedField {
                            focusedField = lastField
                        } else if pickupLocation.isEmpty {
                            focusedField = .pickup
                        } else if destination.isEmpty {
                            focusedField = .destination
                        } else {
                            focusedField = .destination // Default to destination if both filled
                        }
                    } else {
                        // Snap back
                        if lastSheetOffset > -30 {
                            sheetOffset = 0
                            lastSheetOffset = 0
                        } else {
                            sheetOffset = 0
                            lastSheetOffset = 0
                        }
                    }
                }
            }
    }
    
    private var bookingFormView: some View {
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
                VStack(spacing: 16) {
                    locationInputsView
                    dateTimePickersView
                    searchButtonView
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private var locationInputsView: some View {
        VStack(spacing: 0) {
            pickupLocationField
            
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
            
            destinationLocationField
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    private var pickupLocationField: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    pickupSuggestions = [] // Clear suggestions after selection
                    
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
                // Clear suggestions when user starts typing
                if !newValue.isEmpty && newValue != oldValue {
                    pickupSuggestions = []
                }
                
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
                    pickupSuggestions = []
                    
                    // If destination still exists, zoom to it
                    if destinationCoordinate != nil {
                        updateMapCamera()
                    }
                }
            }
            
            // Show location suggestions if available and field is focused and text is empty
            if focusedField == .pickup && pickupLocation.isEmpty && !pickupSuggestions.isEmpty {
                suggestionsList(
                    suggestions: pickupSuggestions,
                    isLoading: isLoadingPickupSuggestions,
                    onSelect: { suggestion in
                        pickupLocation = suggestion.description
                        pickupLocationEnglish = suggestion.description // Use same for now
                        pickupPlaceId = suggestion.placeId
                        pickupSuggestions = []
                        
                        // Only auto-focus destination if it's empty
                        if destination.isEmpty {
                            focusedField = .destination
                        } else {
                            focusedField = nil
                        }
                        
                        // Geocode and update map
                        geocodeLocation(suggestion.description) { coordinate in
                            pickupCoordinate = coordinate
                            updateMapCamera()
                            
                            // Recalculate route if destination already exists
                            if destinationCoordinate != nil {
                                calculateRoute()
                            }
                        }
                    }
                )
                .padding(.top, 8)
            }
        }
    }
    
    private var destinationLocationField: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    destinationSuggestions = [] // Clear suggestions after selection
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
                // Clear suggestions when user starts typing
                if !newValue.isEmpty && newValue != oldValue {
                    destinationSuggestions = []
                }
                
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
                    destinationSuggestions = []
                    
                    // If pickup still exists, zoom to it
                    if pickupCoordinate != nil {
                        updateMapCamera()
                    }
                }
            }
            
            // Show location suggestions if available and field is focused and text is empty
            if focusedField == .destination && destination.isEmpty && !destinationSuggestions.isEmpty {
                suggestionsList(
                    suggestions: destinationSuggestions,
                    isLoading: isLoadingDestinationSuggestions,
                    onSelect: { suggestion in
                        destination = suggestion.description
                        destinationEnglish = suggestion.description // Use same for now
                        destinationPlaceId = suggestion.placeId
                        destinationSuggestions = []
                        focusedField = nil
                        
                        // Geocode and calculate route
                        geocodeLocation(suggestion.description) { coordinate in
                            destinationCoordinate = coordinate
                            updateMapCamera()
                            calculateRoute()
                        }
                    }
                )
                .padding(.top, 8)
            }
        }
    }
    
    private var dateTimePickersView: some View {
        HStack(spacing: 12) {
            DatePickerCard(
                title: "Date",
                icon: "calendar",
                date: $selectedDate,
                displayedComponents: .date,
                timeZone: Self.swissTimeZone,
                showingTimePicker: $showingDatePicker
            )
            
            DatePickerCard(
                title: "Time",
                icon: "clock",
                date: $selectedTime,
                displayedComponents: .hourAndMinute,
                timeZone: Self.swissTimeZone,
                showingTimePicker: $showingTimePicker
            )
        }
        .padding(.horizontal)
    }
    
    private var searchButtonView: some View {
        Button(action: searchRides) {
            HStack {
                Text("Select Vehicle")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [.black, Color(.darkGray)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(pickupLocation.isEmpty || destination.isEmpty)
        .opacity(pickupLocation.isEmpty || destination.isEmpty ? 0.5 : 1)
        .padding(.horizontal, 28)
    }
    
    private var vehicleSelectionView: some View {
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
            showVehicleSelection: $showVehicleSelection,
            isCompactMode: $isVehicleListCompact
        )
    }
    
    private var bottomSheetBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            .ignoresSafeArea(edges: .bottom)
    }
    
    private var sheetDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                let translation = value.translation.height
                
                if translation > 0 {
                    // Dragging down
                    sheetOffset = translation
                    // Dismiss keyboard when dragging down
                    if translation > 20 {
                        focusedField = nil
                    }
                } else if translation < 0 {
                    // Dragging up - no artificial limit, let it follow
                    sheetOffset = translation
                }
            }
            .onEnded { value in
                isDragging = false
                let translation = value.translation.height
                
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    if translation > 50 {
                        // Dragged down
                        if showVehicleSelection && !isVehicleListCompact {
                            // In vehicle selection, collapse to compact mode first
                            isVehicleListCompact = true
                            sheetOffset = 0
                            lastSheetOffset = 0
                        } else {
                            // Either in booking form, or already compact - close/reset
                            sheetOffset = 0
                            lastSheetOffset = 0
                            focusedField = nil
                            if showVehicleSelection && isVehicleListCompact {
                                // Reset compact mode when closing
                                isVehicleListCompact = false
                            }
                        }
                    } else if translation < -20 {
                        // Dragged up - expand
                        sheetOffset = 0
                        lastSheetOffset = 0
                        
                        if showVehicleSelection && isVehicleListCompact {
                            // In vehicle selection compact mode - expand to show all vehicles
                            isVehicleListCompact = false
                        } else if !showVehicleSelection {
                            // In booking form - focus field
                            // Focus the last used field or default intelligently
                            if let lastField = lastFocusedField {
                                focusedField = lastField
                            } else if pickupLocation.isEmpty {
                                focusedField = .pickup
                            } else if destination.isEmpty {
                                focusedField = .destination
                            } else {
                                focusedField = .destination
                            }
                        }
                    } else {
                        // Snap back to previous position
                        sheetOffset = 0
                        lastSheetOffset = 0
                    }
                }
            }
    }
    
    // MARK: - Actions
    
    private func sheetMaxHeight(for geometry: GeometryProxy) -> CGFloat {
        if keyboardHeight > 0 {
            // Keyboard is visible - expand to 84% of screen
            return geometry.size.height * 0.84
        } else if showVehicleSelection && isVehicleListCompact {
            // Compact mode - just enough for one vehicle card
            // Breakdown:
            // - Trip summary card: 16 (top padding) + 16 (padding) + ~60 (content + padding) = ~92pt
            // - Vehicle card: 12 (spacing) + 24 (vertical padding) + ~90 (content) = ~126pt
            // - Book button area: 8 (top padding) + 18 (button vertical) + 5 (bottom) = ~31pt
            // - Additional spacing: ~30pt
            // Total: ~280pt
            return 300
        } else if showVehicleSelection {
            // Vehicle selection expanded - 54% of screen
            return geometry.size.height * 0.54
        } else {
            // Booking form - 54% of screen
            return geometry.size.height * 0.54
        }
    }
    
    private func searchRides() {
        print("🔍 User clicked Search Rides - showing vehicle selection")
        isVehicleListCompact = false  // Reset compact mode when showing vehicle selection
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
    
    // MARK: - Location Suggestions
    
    /// Preload pickup suggestions on view appear
    private func preloadPickupSuggestions() async {
        // Don't load if pickup already has content
        guard pickupLocation.isEmpty else { return }
        
        do {
            let suggestions = try await LocationSuggestionsService.shared.fetchPickupSuggestions()
            await MainActor.run {
                // Only set suggestions if pickup is still empty
                if pickupLocation.isEmpty {
                    pickupSuggestions = suggestions
                    print("✅ Preloaded \(suggestions.count) pickup suggestions")
                }
            }
        } catch {
            // Silently fail - not critical
            print("⚠️ Failed to preload pickup suggestions: \(error)")
        }
    }
    
    /// Load suggestions when a field gains focus
    private func loadSuggestionsForField(_ field: Field) async {
        switch field {
        case .pickup:
            // Only load suggestions if pickup field is empty
            guard pickupLocation.isEmpty else { return }
            
            isLoadingPickupSuggestions = true
            do {
                let suggestions = try await LocationSuggestionsService.shared.fetchPickupSuggestions()
                await MainActor.run {
                    pickupSuggestions = suggestions
                    isLoadingPickupSuggestions = false
                }
            } catch LocationSuggestionsError.unauthorized {
                // Session expired - handle re-authentication
                print("⚠️ Session expired while fetching pickup suggestions")
                await MainActor.run {
                    isLoadingPickupSuggestions = false
                }
            } catch {
                // Silently fail - user can type normally
                print("⚠️ Failed to load pickup suggestions: \(error)")
                await MainActor.run {
                    isLoadingPickupSuggestions = false
                }
            }
            
        case .destination:
            // Only load suggestions if destination field is empty
            guard destination.isEmpty else { return }
            
            isLoadingDestinationSuggestions = true
            do {
                // Pass pickup place_id if available for paired suggestions
                let suggestions = try await LocationSuggestionsService.shared.fetchDestinationSuggestions(
                    pickupPlaceId: pickupPlaceId
                )
                await MainActor.run {
                    destinationSuggestions = suggestions
                    isLoadingDestinationSuggestions = false
                }
            } catch LocationSuggestionsError.unauthorized {
                // Session expired - handle re-authentication
                print("⚠️ Session expired while fetching destination suggestions")
                await MainActor.run {
                    isLoadingDestinationSuggestions = false
                }
            } catch {
                // Silently fail - user can type normally
                print("⚠️ Failed to load destination suggestions: \(error)")
                await MainActor.run {
                    isLoadingDestinationSuggestions = false
                }
            }
        }
    }
    
    /// View component for displaying location suggestions
    @ViewBuilder
    private func suggestionsList(
        suggestions: [LocationSuggestion],
        isLoading: Bool,
        onSelect: @escaping (LocationSuggestion) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading suggestions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
            } else {
                ForEach(Array(suggestions.prefix(3))) { suggestion in
                    Button(action: { onSelect(suggestion) }) {
                        HStack(spacing: 12) {
                            Text(suggestion.description)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if suggestion.id != suggestions.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, 8)
    }
}



// MARK: - Preview
#Preview {
    RideBookingView()
}
