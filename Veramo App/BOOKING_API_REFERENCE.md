# Quick Reference: Booking API Parameters

## Vehicle Classes

Use these exact strings for the `vehicleClass` parameter:

| Vehicle Class | Description | Max Passengers |
|--------------|-------------|----------------|
| `"business"` | Mercedes E-Class or similar | 3 |
| `"first"` | Mercedes S-Class or similar | 3 |
| `"xl"` | Mercedes V-Class or similar | 6 |

## Date/Time Format

**Important:** All date/times must be in ISO 8601 format with UTC timezone.

```swift
// Example: January 15, 2025 at 2:00 PM Switzerland time
// Converts to: "2025-01-15T13:00:00.000Z" (UTC)

let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
formatter.timeZone = TimeZone(identifier: "UTC")
let dateTimeString = formatter.string(from: date)
```

## Required vs Optional Parameters

### Required Parameters
- ✅ `pickup.place_id` - Google Place ID
- ✅ `pickup.description` - Human-readable location name
- ✅ `destination.place_id` - Google Place ID
- ✅ `destination.description` - Human-readable location name
- ✅ `dateTime` - ISO 8601 UTC format
- ✅ `vehicleClass` - One of: "business", "first", "xl"
- ✅ `sessionToken` - Valid authentication token (via Bearer header)

### Optional Parameters
- 🔵 `passengers` - Number of passengers (default: 1)
- 🔵 `flightNumber` - Flight number for airport pickups

## Request Example

```json
POST /app-book
Authorization: Bearer abc123...

{
  "pickup": {
    "place_id": "ChIJlaW7RciqmkcRrel029KMuT8",
    "description": "Zurich Airport"
  },
  "destination": {
    "place_id": "ChIJbwaKz_imxkcRxK6IYJJJPpQ",
    "description": "Hotel Baur au Lac, Talstrasse 1, 8001 Zürich"
  },
  "dateTime": "2025-01-15T13:00:00.000Z",
  "passengers": 2,
  "vehicleClass": "business",
  "flightNumber": "LX123"
}
```

## Success Response Example

```json
{
  "success": true,
  "tripRequestId": 123,
  "quoteReference": "VRM-1234",
  "priceCents": 15000,
  "priceFormatted": "CHF 150.00",
  "distanceKm": 12.5,
  "durationMinutes": 18,
  "checkoutUrl": "https://checkout.mollie.com/..."
}
```

## Error Responses

### 400 - Validation Error
```json
{
  "success": false,
  "error": "Missing required field: pickup.place_id"
}
```

### 401 - Unauthorized
```json
{
  "success": false,
  "error": "Session expired"
}
```

**Action:** Clear stored session and re-authenticate user.

### 502 - Route Calculation Failed
```json
{
  "success": false,
  "error": "Failed to calculate route"
}
```

**Action:** Ask user to verify locations are correct.

## Important Constraints

1. **Advance Booking:** Minimum 2 days in advance (configurable on backend)
2. **Quote Expiration:** 30 minutes - payment must be completed within this time
3. **Session Validity:** 7 days - after which re-authentication is required
4. **Place IDs:** Must be valid Google Place IDs from the Places API

## Common Issues

### Issue: "Missing required field: pickup.place_id"
**Cause:** Location selected without Google Place ID
**Fix:** Ensure location is selected from autocomplete results

### Issue: "Session expired"
**Cause:** Session token older than 7 days or invalid
**Fix:** Call `AuthenticationManager.shared.logout()` and re-authenticate

### Issue: "Failed to calculate route"
**Cause:** Invalid Place IDs or unreachable locations
**Fix:** Verify Place IDs are valid and route is possible

### Issue: "Booking must be at least X days in advance"
**Cause:** Selected date/time too close to current time
**Fix:** Select a date at least 2 days (or configured minimum) in the future

## Testing Tips

### Test with Valid Data
```swift
// Use real Place IDs from Google Places API
let zurichAirport = "ChIJlaW7RciqmkcRrel029KMuT8"
let bahnhofstrasse = "ChIJHzaU8LukmkcRLJdRNwHy0bw"

// Ensure date is at least 2 days ahead
let futureDate = Calendar.current.date(
    byAdding: .day, 
    value: 3, 
    to: Date()
)!
```

### Test Session Expiration
```swift
// Manually expire session
AuthenticationManager.shared.sessionToken = "expired-token"

// Attempt booking
// Should receive 401 and trigger re-auth
```

### Test Invalid Locations
```swift
// Use empty or invalid Place IDs
let invalidPlaceId = ""

// Should receive 400 validation error
```
