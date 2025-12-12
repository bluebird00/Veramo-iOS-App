# Veramo App - Booking Implementation Guide

## Overview

The Veramo App implements a complete booking flow following the backend API specification. The booking process consists of authentication, location selection, pricing display, and payment checkout.

## Architecture

### Key Services

1. **VeramoAuthService** (`VeramoAuthService.swift`)
   - Handles SMS-based authentication
   - Manages session tokens (valid for 7 days)
   - Endpoints: `/sms-code-send`, `/sms-code-verify`

2. **PricingService** (`PricingService.swift`)
   - Fetches pricing for trip routes
   - Calculates prices with time-based adjustments
   - Endpoint: `/pricing`

3. **BookingService** (`BookingService.swift`)
   - Creates authenticated bookings
   - Returns Mollie checkout URL
   - Endpoint: `/app-book`

4. **AuthenticationManager** (`AuthenticationManager.swift`)
   - Stores session tokens and customer data locally
   - Manages authentication state

### Data Models

#### Location Data
```swift
struct BookingLocation: Codable {
    let placeId: String        // Google Place ID
    let description: String    // Human-readable name
}
```

#### Booking Request
```swift
struct BookingRequest: Codable {
    let pickup: BookingLocation
    let destination: BookingLocation
    let dateTime: String       // ISO 8601 UTC format
    let passengers: Int?       // Optional, defaults to 1
    let vehicleClass: String   // "business", "first", or "xl"
    let flightNumber: String?  // Optional
}
```

#### Booking Response
```swift
struct BookingResponse: Codable {
    let success: Bool
    let tripRequestId: Int?
    let quoteReference: String?      // e.g., "VRM-1234"
    let priceCents: Int?
    let priceFormatted: String?      // e.g., "CHF 150.00"
    let distanceKm: Double?
    let durationMinutes: Int?
    let checkoutUrl: String?         // Mollie payment URL
    let error: String?
}
```

## Booking Flow

### Step 1: Authentication (Required)

Before booking, users must authenticate via SMS:

```swift
// 1. Send SMS code
let response = try await VeramoAuthService.shared.requestSMSCode(
    phone: "+41791234567"
)

// 2. Verify SMS code
let (customer, sessionToken) = try await VeramoAuthService.shared.verifySMSCode(
    phone: "+41791234567",
    code: "123456"
)

// 3. Save authentication
AuthenticationManager.shared.saveAuthentication(
    customer: customer,
    sessionToken: sessionToken
)
```

**Session Token:**
- Valid for 7 days
- Stored in UserDefaults via AuthenticationManager
- Used for all authenticated API calls

### Step 2: Location Selection

Users select pickup and destination using Google Places autocomplete:

```swift
// Location must include:
// 1. Google Place ID (from Places API)
// 2. Human-readable description
// 3. Coordinates (for map display)

let pickup = BookingLocation(
    placeId: "ChIJ...",
    description: "Zurich Airport"
)

let destination = BookingLocation(
    placeId: "ChIJ...",
    description: "Hotel Baur au Lac, Zurich"
)
```

**Implementation Notes:**
- `RideBookingView.swift` handles location input
- Uses `GooglePlacesService` for autocomplete
- Stores both display text and Place IDs
- Map shows route preview with animation

### Step 3: Pricing (Optional but Recommended)

Fetch pricing before creating the booking to show users the cost:

```swift
let pricingResponse = try await PricingService.shared.fetchPricing(
    originPlaceId: pickupPlaceId,
    destinationPlaceId: destinationPlaceId,
    pickupDatetime: pickupDateTime
)

// Response includes prices for all vehicle classes:
// - business: Mercedes E-Class or similar
// - first: Mercedes S-Class or similar
// - xl: Mercedes V-Class or similar
```

**Pricing Features:**
- Time-based adjustments (weekends, nights)
- Distance-based calculation
- Route duration estimate
- All prices in CHF cents

### Step 4: Create Booking

Create the booking with selected options:

```swift
let response = try await BookingService.shared.createBooking(
    pickupPlaceId: "ChIJ...",
    pickupDescription: "Zurich Airport",
    destinationPlaceId: "ChIJ...",
    destinationDescription: "Hotel Baur au Lac",
    dateTime: pickupDateTime,
    passengers: 2,
    vehicleClass: "business",
    flightNumber: "LX123",  // Optional
    sessionToken: sessionToken
)

if let checkoutUrl = URL(string: response.checkoutUrl ?? "") {
    // Open Mollie checkout in Safari or WebView
    self.checkoutUrl = checkoutUrl
}
```

**Requirements:**
- Booking must be at least 2 days in advance (configurable on backend)
- Session token must be valid
- Place IDs must be valid Google Place IDs
- Vehicle class must be one of: "business", "first", "xl"

### Step 5: Payment

The booking response includes a Mollie checkout URL:

```swift
// Example checkout URL:
// https://checkout.mollie.com/...

// Open in SafariView (see VehicleSelectionView.swift)
.fullScreenCover(item: $checkoutUrl) { checkout in
    SafariView(url: checkout.url) {
        // Dismissed after payment
        // Booking is confirmed automatically
    }
}
```

**Payment Flow:**
1. User is redirected to Mollie checkout page
2. User completes payment
3. Mollie redirects to: `https://veramo.ch/booking-confirmed.html?ref=VRM-1234`
4. Backend automatically confirms booking
5. Customer receives confirmation email

**Quote Expiration:**
- Quote expires in 30 minutes if payment not completed
- Customer must create a new booking if quote expires

## Error Handling

### HTTP Status Codes

| Status | Meaning | Action |
|--------|---------|--------|
| 200 | Success | Process booking response |
| 400 | Validation error | Show error message to user |
| 401 | Session expired | Re-authenticate user |
| 502 | Route calculation failed | Ask user to check locations |

### BookingError Types

```swift
enum BookingError: Error {
    case invalidURL
    case unauthorized              // 401 - Re-auth required
    case validationError(String)   // 400 - Show message
    case routeCalculationFailed    // 502 - Check locations
    case networkError(Error)
    case decodingError
    case serverError(String)
    case missingSessionToken
    case missingPlaceId
}
```

### Handling Session Expiration

```swift
do {
    let response = try await BookingService.shared.createBooking(...)
} catch BookingError.unauthorized {
    // Session expired
    AuthenticationManager.shared.logout()
    
    // Show alert and navigate to login
    showSessionExpiredAlert = true
}
```

## Time Zone Handling

**Important:** All times are handled in Switzerland timezone (Europe/Zurich).

```swift
// Combine user-selected date and time in Switzerland timezone
let swissTimeZone = TimeZone(identifier: "Europe/Zurich")!
var swissCalendar = Calendar.current
swissCalendar.timeZone = swissTimeZone

var components = DateComponents()
components.year = 2025
components.month = 1
components.day = 15
components.hour = 14
components.minute = 0
components.timeZone = swissTimeZone

let pickupDateTime = swissCalendar.date(from: components)!

// BookingService converts to ISO 8601 UTC format
// Example: "2025-01-15T13:00:00.000Z"
```

## Implementation Checklist

### Required Components

- [x] SMS Authentication (SMSLoginView)
- [x] Session Token Storage (AuthenticationManager)
- [x] Location Selection with Place IDs (RideBookingView)
- [x] Pricing Display (PricingService + VehicleSelectionView)
- [x] Booking Creation (BookingService)
- [x] Payment Checkout (SafariView integration)
- [x] Error Handling (All services)
- [x] Session Expiration Handling

### Optional Features

- [ ] Booking History View
- [ ] Payment Status Checking
- [ ] Push Notifications
- [ ] Trip Tracking
- [ ] Driver Contact

## Testing

### Test Scenarios

1. **Happy Path:**
   - Authenticate with SMS
   - Select valid locations
   - View pricing
   - Create booking
   - Complete payment

2. **Session Expiration:**
   - Wait for session to expire (or use expired token)
   - Attempt booking
   - Verify re-authentication prompt

3. **Invalid Locations:**
   - Use locations without Place IDs
   - Verify error handling

4. **Network Errors:**
   - Disable network
   - Attempt booking
   - Verify graceful error messages

5. **Payment Abandonment:**
   - Start booking
   - Close payment page
   - Verify quote expiration handling

## API Endpoints Summary

```
Base URL: https://veramo.ch/.netlify/functions

POST   /sms-code-send       - Send SMS verification code
POST   /sms-code-verify     - Verify SMS code and get session token
GET    /pricing             - Get trip pricing (optional)
POST   /app-book            - Create authenticated booking
```

## Key Files

- `BookingService.swift` - Main booking logic
- `VeramoAuthService.swift` - Authentication
- `PricingService.swift` - Pricing calculations
- `AuthenticationManager.swift` - Token storage
- `VehicleSelectionView.swift` - Vehicle selection & booking UI
- `RideBookingView.swift` - Location selection & map
- `SMSLoginView.swift` - SMS authentication UI
- `CountryCode.swift` - Country code selection

## Notes

- All monetary values are in CHF cents (1 CHF = 100 cents)
- Session tokens are valid for 7 days
- Quotes expire after 30 minutes
- Minimum booking advance: 2 days (configurable)
- Supported vehicle classes: business, first, xl
- Payment provider: Mollie
- Location provider: Google Places API

## Support

For API issues or questions, contact the backend team.
For app issues, check the error logs - all services include detailed logging.
