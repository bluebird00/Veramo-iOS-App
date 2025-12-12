# Booking System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         VERAMO iOS APP - BOOKING FLOW                        │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. AUTHENTICATION LAYER                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────────┐         ┌──────────────────┐         ┌─────────────────┐ │
│  │ SMSLoginView │────────▶│ VeramoAuthService│────────▶│ Backend API     │ │
│  │              │         │                  │         │ /sms-code-send  │ │
│  │ - Country    │         │ requestSMSCode() │         │ /sms-code-verify│ │
│  │ - Phone      │         │ verifySMSCode()  │         └─────────────────┘ │
│  │ - Code Input │         └──────────────────┘                ▼            │
│  └──────────────┘                  │                  ┌─────────────────┐  │
│         │                           │                  │ Session Token   │  │
│         │                           └─────────────────▶│ (Valid 7 days)  │  │
│         │                                              └─────────────────┘  │
│         │                                                       ▼            │
│         ▼                                              ┌─────────────────┐  │
│  ┌──────────────────┐                                 │ Authentication  │  │
│  │ Authentication   │◀────────────────────────────────│ Manager         │  │
│  │ Manager          │                                 │                 │  │
│  │ - Save Token     │                                 │ UserDefaults    │  │
│  │ - Save Customer  │                                 │ Storage         │  │
│  └──────────────────┘                                 └─────────────────┘  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. LOCATION SELECTION LAYER                                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────────────┐         ┌──────────────────┐         ┌─────────────┐ │
│  │ RideBookingView  │────────▶│ GooglePlaces     │────────▶│ Google      │ │
│  │                  │         │ Service          │         │ Places API  │ │
│  │ - Pickup Input   │         │                  │         │             │ │
│  │ - Destination    │         │ autocomplete()   │         │ (Place IDs) │ │
│  │ - Date/Time      │         └──────────────────┘         └─────────────┘ │
│  │ - Map Preview    │                  │                          │         │
│  └──────────────────┘                  │                          │         │
│         │                               ▼                          ▼         │
│         │                      ┌─────────────────┐       ┌──────────────┐  │
│         │                      │ Suggestions     │       │ Place ID     │  │
│         │                      │ - Full Text     │       │ ChIJ...      │  │
│         │                      │ - Place ID      │       │              │  │
│         │                      │ - Coordinates   │       │ (Required!)  │  │
│         │                      └─────────────────┘       └──────────────┘  │
│         │                                                                    │
│         ▼                                                                    │
│  ┌──────────────────┐                                                       │
│  │ Location Data    │                                                       │
│  │ - Pickup Place ID│                                                       │
│  │ - Dest Place ID  │                                                       │
│  │ - Descriptions   │                                                       │
│  │ - Coordinates    │                                                       │
│  └──────────────────┘                                                       │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. PRICING LAYER (Optional but Recommended)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────────────────┐         ┌────────────────┐         ┌───────────┐ │
│  │ VehicleSelectionView │────────▶│ PricingService │────────▶│ Backend   │ │
│  │                      │         │                │         │ /pricing  │ │
│  │ - Show Loading       │         │ fetchPricing() │         │           │ │
│  │ - Display Prices     │         └────────────────┘         └───────────┘ │
│  │ - Show Vehicle Cards │                  │                      ▼        │
│  └──────────────────────┘                  │              ┌──────────────┐ │
│           │                                 ▼              │ Pricing Data │ │
│           │                        ┌────────────────┐     │ - Business   │ │
│           │                        │ PricingResponse│     │ - First      │ │
│           │                        │                │     │ - XL         │ │
│           │                        │ - Business     │     │ - Distance   │ │
│           │                        │ - First        │     │ - Duration   │ │
│           │                        │ - XL           │     │ - Adjustments│ │
│           │                        │ - Distance     │     └──────────────┘ │
│           │                        │ - Duration     │                       │
│           │                        └────────────────┘                       │
│           │                                 │                               │
│           └─────────────────────────────────┘                               │
│                                     │                                        │
│                                     ▼                                        │
│                           ┌──────────────────┐                              │
│                           │ User Selects     │                              │
│                           │ Vehicle Class    │                              │
│                           │ - business       │                              │
│                           │ - first          │                              │
│                           │ - xl             │                              │
│                           └──────────────────┘                              │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 4. BOOKING CREATION LAYER                                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────────────────┐                                                   │
│  │ VehicleSelectionView │                                                   │
│  │                      │                                                   │
│  │ User clicks:         │                                                   │
│  │ "Book Business"      │                                                   │
│  └──────────────────────┘                                                   │
│           │                                                                  │
│           ▼                                                                  │
│  ┌──────────────────────┐         ┌────────────────┐                       │
│  │ Prepare Request      │         │ BookingService │                       │
│  │                      │────────▶│                │                       │
│  │ - Pickup Place ID    │         │ createBooking()│                       │
│  │ - Dest Place ID      │         │                │                       │
│  │ - DateTime (UTC)     │         │ - Validates    │                       │
│  │ - Vehicle Class      │         │ - Authenticates│                       │
│  │ - Passengers         │         │ - Handles      │                       │
│  │ - Flight Number      │         │   Errors       │                       │
│  │ - Session Token      │         └────────────────┘                       │
│  └──────────────────────┘                  │                               │
│                                             ▼                               │
│                                    ┌────────────────┐                       │
│                                    │ POST /app-book │                       │
│                                    │                │                       │
│                                    │ Authorization: │                       │
│                                    │ Bearer <token> │                       │
│                                    └────────────────┘                       │
│                                             │                               │
│           ┌─────────────────────────────────┴──────────┐                   │
│           ▼                                             ▼                   │
│  ┌────────────────┐                           ┌────────────────┐           │
│  │ SUCCESS (200)  │                           │ ERROR          │           │
│  │                │                           │                │           │
│  │ - Trip ID      │                           │ 400: Validation│           │
│  │ - Reference    │                           │ 401: Session   │           │
│  │ - Price        │                           │      Expired   │           │
│  │ - Distance     │                           │ 502: Route     │           │
│  │ - Duration     │                           │      Failed    │           │
│  │ - Checkout URL │                           └────────────────┘           │
│  └────────────────┘                                    │                   │
│           │                                            │                   │
│           │                                            ▼                   │
│           │                                   ┌────────────────┐           │
│           │                                   │ Error Handling │           │
│           │                                   │                │           │
│           │                                   │ - Show Alert   │           │
│           │                                   │ - Logout (401) │           │
│           │                                   │ - Retry Option │           │
│           │                                   └────────────────┘           │
│           │                                                                 │
│           ▼                                                                 │
│  ┌────────────────┐                                                        │
│  │ Checkout URL   │                                                        │
│  │ Received       │                                                        │
│  └────────────────┘                                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 5. PAYMENT LAYER                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────────────────┐                                                   │
│  │ Open Checkout URL    │                                                   │
│  │ in SafariView        │                                                   │
│  └──────────────────────┘                                                   │
│           │                                                                  │
│           ▼                                                                  │
│  ┌──────────────────────┐         ┌────────────────┐                       │
│  │ SafariView           │────────▶│ Mollie Checkout│                       │
│  │ (Full Screen)        │         │                │                       │
│  │                      │         │ - Card Payment │                       │
│  │ User completes       │         │ - Bank Transfer│                       │
│  │ payment              │         │ - Other Options│                       │
│  └──────────────────────┘         └────────────────┘                       │
│           │                                 │                               │
│           │                                 │                               │
│           │                         Payment Complete                        │
│           │                                 │                               │
│           │                                 ▼                               │
│           │                        ┌────────────────┐                       │
│           │                        │ Mollie Redirect│                       │
│           │                        │                │                       │
│           │                        │ veramo.ch/     │                       │
│           │                        │ booking-       │                       │
│           │                        │ confirmed.html │                       │
│           │                        │ ?ref=VRM-1234  │                       │
│           │                        └────────────────┘                       │
│           │                                 │                               │
│           │                                 ▼                               │
│           │                        ┌────────────────┐                       │
│           │                        │ Backend        │                       │
│           │                        │ Confirms       │                       │
│           │                        │ Booking        │                       │
│           │                        │ Automatically  │                       │
│           │                        └────────────────┘                       │
│           │                                 │                               │
│           │                                 ▼                               │
│           │                        ┌────────────────┐                       │
│           │                        │ Email          │                       │
│           │                        │ Confirmation   │                       │
│           │                        │ Sent           │                       │
│           │                        └────────────────┘                       │
│           │                                                                  │
│           ▼                                                                  │
│  ┌──────────────────────┐                                                   │
│  │ Safari Dismissed     │                                                   │
│  │                      │                                                   │
│  │ Navigate back to     │                                                   │
│  │ home screen          │                                                   │
│  └──────────────────────┘                                                   │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ KEY COMPONENTS                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  Services (Business Logic):                                                  │
│  ├─ VeramoAuthService.swift      - SMS authentication                       │
│  ├─ BookingService.swift          - Booking creation                        │
│  ├─ PricingService.swift          - Price calculation                       │
│  └─ AuthenticationManager.swift   - Session management                      │
│                                                                               │
│  Views (UI):                                                                 │
│  ├─ SMSLoginView.swift           - Phone & code input                       │
│  ├─ RideBookingView.swift        - Location & date selection                │
│  ├─ VehicleSelectionView.swift   - Vehicle choice & booking                 │
│  └─ SafariView.swift              - Payment browser                          │
│                                                                               │
│  Models (Data):                                                              │
│  ├─ BookingRequest               - Request structure                        │
│  ├─ BookingResponse              - Response structure                       │
│  ├─ BookingLocation              - Place ID + description                   │
│  ├─ PricingResponse              - Price details                            │
│  └─ AuthenticatedCustomer        - User data                                │
│                                                                               │
│  Helpers:                                                                    │
│  ├─ CountryCode.swift            - Country code picker                      │
│  └─ String.toVehicleClass        - Vehicle name → API class                 │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ DATA FLOW SUMMARY                                                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  Phone Number ──▶ SMS Code ──▶ Session Token (7 days)                       │
│       │                              │                                        │
│       │                              ▼                                        │
│       │                    UserDefaults Storage                              │
│       │                              │                                        │
│       │                              │                                        │
│  Location Input ──▶ Google Places ──▶ Place ID (Required!)                  │
│       │                                                                        │
│       │                                                                        │
│  Date/Time ──▶ Swiss TZ ──▶ UTC ISO 8601                                    │
│       │                                                                        │
│       │                                                                        │
│  Vehicle Choice ──▶ "business" | "first" | "xl"                             │
│       │                                                                        │
│       │                                                                        │
│       ▼                                                                        │
│  BookingRequest ──▶ Backend ──▶ BookingResponse                             │
│                          │                                                    │
│                          ▼                                                    │
│                   Checkout URL ──▶ Mollie ──▶ Payment ──▶ Confirmation      │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
```
