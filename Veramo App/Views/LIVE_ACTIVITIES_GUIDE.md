# Live Activities Implementation Guide

## Overview

Live Activities have been implemented for active trips (en_route, nearby, arrived, waiting). This provides users with real-time trip updates on their Lock Screen and Dynamic Island.

## Files Created

### 1. `TripActivityAttributes.swift`
Defines the Live Activity structure:
- **Static Attributes**: Trip reference, vehicle class, pickup time (doesn't change)
- **Dynamic State**: Status, driver info, ETA, locations (updates in real-time)

### 2. `TripLiveActivityView.swift`
UI for the Live Activity:
- **Lock Screen View**: Shows status, driver name, ETA, and call button
- **Dynamic Island**: Compact, expanded, and minimal views
- **Color-coded status**: Blue (en_route), Orange (nearby/waiting), Green (arrived)

### 3. `TripLiveActivityManager.swift`
Manages Live Activity lifecycle:
- `startActivity()`: Creates a new Live Activity
- `updateActivity()`: Updates existing Live Activity with new status
- `endActivity()`: Ends Live Activity when trip completes
- `endAllActivities()`: Cleanup all activities

### 4. Updated `TripStatusService.swift`
Integrated Live Activity management:
- Automatically starts Live Activity when trip becomes active
- Updates Live Activity on every status poll
- Ends Live Activity when trip completes or is cancelled

## How It Works

### 1. Trip Monitoring Starts
When `TripStatusService` starts monitoring a trip:
```swift
tripStatusService.startMonitoring(trip: trip)
```

### 2. Status Updates
Every time the trip status is polled (every 1-5 minutes):
- Status is fetched from API
- `tripStatuses` dictionary is updated
- Live Activity is automatically updated/created

### 3. Active Statuses Trigger Live Activity
Only these statuses show Live Activity:
- ✅ `en_route` - Driver is on the way
- ✅ `nearby` - Driver is close
- ✅ `arrived` - Driver has arrived
- ✅ `waiting` - Driver is waiting

### 4. Completion Ends Live Activity
When status changes to:
- `completed` - Trip finished
- `cancelled` - Trip cancelled

The Live Activity is automatically ended and dismissed.

## Project Setup Required

### 1. Add ActivityKit Framework
1. Select your app target in Xcode
2. Go to "General" → "Frameworks, Libraries, and Embedded Content"
3. Click "+" and add `ActivityKit.framework`

### 2. Update Info.plist
Add the following key:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### 3. Add Background Modes (if not already present)
Enable "Background Modes" capability and check:
- Background fetch
- Remote notifications

### 4. Register Live Activity Widget (Optional)
For better control, create a Widget Extension:

1. File → New → Target → Widget Extension
2. Name it "VeramoTripWidget"
3. In the widget file, register your Live Activity:

```swift
import ActivityKit
import WidgetKit
import SwiftUI

@main
struct VeramoTripWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Regular widget (if you want)
        // VeramoTripWidget()
        
        // Live Activity
        if #available(iOS 16.2, *) {
            TripLiveActivity()
        }
    }
}

@available(iOS 16.2, *)
struct TripLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) { context in
            // Lock Screen view
            TripLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island view
            TripLiveActivityDynamicIsland(context: context)
        }
    }
}
```

## Testing

### Test Live Activities:

1. **Run the app on a physical device** (Live Activities don't work in Simulator for Dynamic Island)

2. **Book a trip** that starts soon (or use a test trip)

3. **Wait for status to become active** (en_route, nearby, arrived, or waiting)

4. **Lock your device** - You should see the Live Activity on your Lock Screen

5. **Check Dynamic Island** (iPhone 14 Pro or later) - Status appears in the notch area

### Debug Logging:
Look for these log messages:
```
📱 [LiveActivity] Started activity for trip: ABC123
🔄 [LiveActivity] Updated activity for ABC123: en_route
🛑 [LiveActivity] Ended activity for ABC123
```

## Features

### Lock Screen
- ✅ Status indicator with pulsating color
- ✅ Driver name
- ✅ ETA in minutes
- ✅ Tap-to-call driver button
- ✅ Trip reference number
- ✅ Pickup location

### Dynamic Island
**Compact (notch closed):**
- Icon on left
- ETA on right

**Expanded (tap on notch):**
- Status at top center
- Driver name below
- ETA on right
- Pickup location at bottom
- Call button

**Minimal (multiple activities):**
- Just the car icon

## Architecture

```
TripStatusService
       ↓
   (polls API)
       ↓
  Status Update
       ↓
TripLiveActivityManager
       ↓
  ActivityKit
       ↓
Live Activity UI
(Lock Screen + Dynamic Island)
```

## Customization

### Change Colors
Edit `TripLiveActivityView.swift`:
```swift
private var statusColor: Color {
    switch context.state.status.lowercased() {
    case "en_route":
        return .blue  // Change this
    // ...
    }
}
```

### Change Polling Interval
Edit `TripStatusService.swift`:
```swift
private func pollingInterval(for status: String, pickupDate: Date) -> TimeInterval {
    if status == "en_route" || status == "nearby" {
        return 60 // Poll every 1 minute
    }
    // ...
}
```

### Change Active Statuses
Edit `TripLiveActivityManager.swift`:
```swift
func startActivity(for trip: CustomerTrip, status: TripStatus) {
    let activeStatuses = ["en_route", "nearby", "arrived", "waiting"]
    // Add or remove statuses here
}
```

## Troubleshooting

### Live Activity doesn't appear:
1. Check device settings: Settings → App Name → Enable "Live Activities"
2. Ensure trip status is active (en_route, nearby, arrived, waiting)
3. Check console logs for errors
4. Try restarting the app

### Live Activity doesn't update:
1. Check network connection
2. Verify `TripStatusService` is polling
3. Check if status actually changed in API
4. Look for error logs in Console

### Dynamic Island not showing:
1. Dynamic Island requires iPhone 14 Pro or later
2. Ensure Live Activity is active
3. Try tapping the notch area to expand

## Best Practices

### ✅ Do:
- Start Live Activity only for active statuses
- Update regularly but not too frequently (1-5 min intervals)
- End Live Activity when trip completes
- Provide useful, glanceable information
- Test on real devices

### ❌ Don't:
- Start Live Activities for all trips
- Update more than once per minute
- Keep Live Activities running after trip ends
- Show too much text (keep it concise)
- Rely on Simulator for testing

## Future Enhancements

### Possible additions:
1. **Map preview** in expanded Dynamic Island
2. **Push notification updates** for instant Live Activity updates
3. **Rich animations** when status changes
4. **Multiple trip support** (show nearest active trip)
5. **Haptic feedback** when driver arrives
6. **Sharing** trip status with others

## Resources

- [Apple ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [Live Activities WWDC Session](https://developer.apple.com/videos/play/wwdc2022/10184/)
- [Dynamic Island Design Guidelines](https://developer.apple.com/design/human-interface-guidelines/live-activities)
