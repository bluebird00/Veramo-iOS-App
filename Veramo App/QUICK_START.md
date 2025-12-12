# 🚀 Quick Start Guide - Veramo Booking System

## For Developers

### Installation (Already Complete ✅)

The booking system is fully implemented and ready to use. No additional setup required.

### Files You Need to Know About

| File | Purpose | When to Use |
|------|---------|------------|
| `BookingService.swift` | Core booking API | Import when creating bookings |
| `VehicleSelectionView.swift` | Booking UI | Already integrated in app flow |
| `BOOKING_IMPLEMENTATION.md` | Detailed docs | When you need to understand architecture |
| `BookingService+Example.swift` | Code examples | Copy-paste examples for new features |

### How to Test Right Now

#### 1. Run the App
```bash
# In Xcode
⌘ + R
```

#### 2. Test Authentication
```
1. Tap "Login" or navigate to SMSLoginView
2. Select your country code (defaults to device location)
3. Enter your phone number
4. Tap "Send Code"
5. Check your phone for SMS
6. Enter the 6-digit code
7. ✅ You're authenticated!
```

#### 3. Test Booking
```
1. Navigate to RideBookingView (Home → Book a Ride)
2. Tap "Pickup location"
3. Type "Zurich Airport" (or any location)
4. Select from suggestions (must use suggestions!)
5. Tap "Destination"
6. Type a destination
7. Select from suggestions
8. Choose date (at least 2 days ahead)
9. Choose time
10. Tap "Search Rides"
11. See pricing for all vehicle classes
12. Select a vehicle
13. (Optional) Add flight number
14. Tap "Book [Vehicle]"
15. Payment page opens
16. Complete payment
17. ✅ Booking confirmed!
```

## For Product Managers / QA

### What Works Now

✅ **Complete Booking Flow**
- User can authenticate via SMS
- User can select pickup/destination with map preview
- User sees real-time pricing
- User can book and pay
- User receives confirmation email

✅ **Error Handling**
- Session expiration automatically handled
- Invalid locations caught with helpful messages
- Network errors shown with retry options
- Payment failures handled gracefully

✅ **User Experience**
- Smooth animations and transitions
- Loading states during API calls
- Clear error messages
- Auto-focus on inputs
- Smart defaults (country code, dates)

### Test Scenarios

#### Happy Path ✅
```
Phone authentication → Location selection → Pricing → 
Booking → Payment → Confirmation
```
**Expected:** Smooth flow, no errors

#### Session Expiration 🔐
```
Wait 7+ days → Try to book
```
**Expected:** "Session expired" alert → Redirect to login

#### Invalid Location ⚠️
```
Type location manually (don't select from list) → Try to book
```
**Expected:** Error about missing Place ID

#### Network Error 📡
```
Turn on Airplane Mode → Try to book
```
**Expected:** Network error with retry button

#### Booking Too Soon ⏰
```
Select today's date → Try to book
```
**Expected:** "Must be at least 2 days in advance" error

### Known Limitations

1. **Minimum Advance Booking:** 2 days (configurable on backend)
2. **Quote Expiration:** 30 minutes - must complete payment
3. **Session Duration:** 7 days - then must re-authenticate
4. **Location Requirements:** Must use Google Places autocomplete

### Metrics to Track

- **Authentication Success Rate**
  - SMS codes sent vs verified
  - Session token storage success

- **Booking Conversion Rate**
  - Location selections → Pricing viewed → Bookings created → Payments completed

- **Error Rates**
  - Session expirations
  - Validation errors
  - Route calculation failures
  - Payment abandonments

## For Backend Developers

### API Endpoints Used

```
POST /sms-code-send          - Send verification code
POST /sms-code-verify        - Verify code, return token
GET  /pricing                - Get trip pricing
POST /app-book               - Create booking
```

### Expected Request/Response

#### Booking Request
```json
POST /app-book
Authorization: Bearer <session-token>
Content-Type: application/json

{
  "pickup": {
    "place_id": "ChIJlaW7RciqmkcRrel029KMuT8",
    "description": "Zurich Airport"
  },
  "destination": {
    "place_id": "ChIJbwaKz_imxkcRxK6IYJJJPpQ",
    "description": "Hotel Baur au Lac, Zurich"
  },
  "dateTime": "2025-01-18T13:00:00.000Z",
  "passengers": 2,
  "vehicleClass": "business",
  "flightNumber": "LX123"
}
```

#### Success Response
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

### Status Codes App Handles

| Code | Meaning | App Behavior |
|------|---------|--------------|
| 200 | Success | Opens payment page |
| 400 | Validation error | Shows error message to user |
| 401 | Session expired | Logs out, prompts re-login |
| 502 | Route calc failed | Shows location error |

### Logging

All API calls are logged extensively:
```
📱 Request details (URL, headers, body)
📥 Response details (status, body)
✅ Success info (parsed data)
❌ Error details (type, message)
```

## Common Questions

### Q: Can users book without authenticating?
**A:** No. Authentication via SMS is required before booking.

### Q: How long do session tokens last?
**A:** 7 days. After that, users must re-authenticate.

### Q: What payment methods are supported?
**A:** Mollie handles payment - cards, bank transfers, etc.

### Q: Can users save favorite locations?
**A:** Not yet - this is a future enhancement.

### Q: What happens if payment fails?
**A:** Quote remains valid for 30 minutes. User can retry payment.

### Q: Are bookings confirmed immediately?
**A:** After payment completes, backend confirms automatically.

### Q: Can users cancel bookings?
**A:** Not in current version - contact support to cancel.

### Q: What time zone is used?
**A:** Switzerland (Europe/Zurich) for display, UTC for API.

### Q: What if location doesn't have a Place ID?
**A:** All locations must come from Google Places autocomplete.

### Q: Can users edit booking details?
**A:** Not after creation. Must create new booking.

## Next Steps

### Immediate
1. ✅ Test with real phone numbers
2. ✅ Test with real locations in Switzerland
3. ✅ Complete a test booking end-to-end
4. ✅ Verify email confirmation arrives

### Short Term
1. Add booking history view
2. Add push notifications
3. Add payment status polling
4. Add favorite locations

### Long Term
1. Trip tracking with real-time updates
2. Driver contact features
3. Recurring bookings
4. Corporate accounts

## Support Contacts

- **API Issues:** Backend team
- **Payment Issues:** Mollie support
- **App Issues:** Check logs (extensive logging included)
- **Feature Requests:** Product team

## Version Info

- **Implementation Version:** 1.0
- **Date:** December 12, 2025
- **Platform:** iOS (Swift/SwiftUI)
- **API Compatibility:** Veramo Backend v1
- **Minimum iOS:** 16.0+

## Resources

📚 **Documentation**
- `BOOKING_IMPLEMENTATION.md` - Full architecture guide
- `BOOKING_API_REFERENCE.md` - API quick reference
- `BookingService+Example.swift` - Code examples
- `ARCHITECTURE_DIAGRAM.md` - Visual flow diagram

🔍 **Debugging**
- Check Xcode console for detailed logs
- All services include `print()` statements
- Errors include localized descriptions

⚡ **Performance**
- API calls are async/await
- UI updates on MainActor
- No blocking operations

🔒 **Security**
- Session tokens stored in UserDefaults (encrypted by iOS)
- HTTPS for all API calls
- Bearer token authentication
- Auto-logout on session expiration

---

**Status:** 🟢 Ready for Testing

**Last Updated:** December 12, 2025
