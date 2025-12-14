# Backend Requirements for Driver Arrival Notifications

## Overview
To send push notifications when a driver arrives, your backend needs to implement the following:

## 1. APNs Integration

### Setup APNs Certificate/Key
- Create an APNs authentication key in Apple Developer Portal
- Configure your backend to send push notifications via APNs HTTP/2 API
- Store device tokens when users register their devices

### Device Token Storage
Store the device token when the app sends it:
```
POST /app-register-device
Authorization: Bearer [customer_session_token]

Request:
{
  "deviceToken": "abc123...",
  "platform": "ios"
}

Response:
{
  "success": true
}
```

**Note:** The customer ID is extracted from the session token on the backend, so it's not sent in the request body.

## 2. Driver Tracking System

### Real-time Location Tracking
Your backend should track driver locations in real-time:
- Driver app sends location updates every 10-15 seconds
- Calculate distance between driver and pickup location
- Detect when driver is within arrival threshold (e.g., 100 meters)

### Arrival Detection
When driver arrives at pickup location:
1. Update trip status to "arrived"
2. Trigger push notification to passenger
3. Store arrival timestamp

## 3. Push Notification Payload

### APNs Request Format
```json
{
  "aps": {
    "alert": {
      "title": "Your driver has arrived!",
      "body": "[Driver Name] is waiting for you"
    },
    "sound": "default",
    "badge": 1,
    "category": "DRIVER_ARRIVAL"
  },
  "type": "driver_arrival",
  "reference": "VRM-1234-5678",
  "driver_id": "driver-123",
  "timestamp": "2025-12-14T10:30:00Z"
}
```

### Sending via APNs HTTP/2 API
```bash
curl -X POST \
  -H "apns-topic: com.yourapp.bundle" \
  -H "apns-push-type: alert" \
  -H "apns-priority: 10" \
  -H "authorization: bearer [JWT_TOKEN]" \
  --data '{...}' \
  https://api.push.apple.com/3/device/[DEVICE_TOKEN]
```

## 4. Trip Status API Endpoint

### GET /app-trip-status
Allow app to poll for current trip status:

**Request:**
```
GET /app-trip-status?reference=VRM-1234-5678
Authorization: Bearer [session_token]
```

**Response:**
```json
{
  "reference": "VRM-1234-5678",
  "status": "arrived",
  "driver_location": {
    "latitude": 47.3769,
    "longitude": 8.5417,
    "heading": 180.0,
    "estimated_arrival_minutes": 0,
    "last_updated": "2025-12-14T10:30:00Z"
  },
  "driver_info": {
    "driver_id": "driver-123",
    "name": "John Smith",
    "vehicle_make": "BMW",
    "vehicle_model": "3 Series",
    "vehicle_color": "Black",
    "license_plate": "ZH 12345",
    "phone_number": "+41791234567"
  },
  "estimated_arrival_time": "2025-12-14T10:30:00Z"
}
```

**Status Values:**
- `en_route` - Driver is on the way to pickup
- `arrived` - Driver has arrived at pickup location
- `waiting_for_pickup` - Driver is waiting for passenger
- `pickup_complete` - Passenger picked up
- `dropping_off` - Heading to destination
- `complete` - Trip completed
- `canceled` - Trip canceled

## 5. Notification Triggers

### Different Events to Notify
1. **Driver Assigned** - Send notification when driver accepts trip
2. **Driver En Route** - Send notification with ETA when driver starts
3. **Driver Nearby** - Send notification when driver is 5 minutes away
4. **Driver Arrived** - Send notification when driver reaches pickup (CRITICAL)
5. **Driver Waiting** - Send reminder if passenger hasn't shown up after 2 minutes
6. **Trip Started** - Send notification when trip begins
7. **Approaching Destination** - Send notification when near destination
8. **Trip Completed** - Send notification when trip ends

## 6. Implementation Example (Node.js)

```javascript
const apn = require('apn');

// Initialize APNs provider
const provider = new apn.Provider({
  token: {
    key: 'path/to/APNsAuthKey.p8',
    keyId: 'YOUR_KEY_ID',
    teamId: 'YOUR_TEAM_ID'
  },
  production: true // or false for sandbox
});

// Send driver arrival notification
async function sendDriverArrivedNotification(deviceToken, reference, driverName) {
  const notification = new apn.Notification();
  
  notification.alert = {
    title: 'Your driver has arrived!',
    body: `${driverName} is waiting for you`
  };
  notification.sound = 'default';
  notification.badge = 1;
  notification.category = 'DRIVER_ARRIVAL';
  notification.topic = 'com.yourapp.bundle';
  notification.payload = {
    type: 'driver_arrival',
    reference: reference,
    timestamp: new Date().toISOString()
  };
  notification.pushType = 'alert';
  notification.priority = 10;
  
  try {
    const result = await provider.send(notification, deviceToken);
    console.log('✅ Notification sent:', result);
  } catch (error) {
    console.error('❌ Failed to send notification:', error);
  }
}

// Monitor driver location and trigger notifications
function monitorDriverLocation(tripId, driverId, pickupLocation) {
  const intervalId = setInterval(async () => {
    const driverLocation = await getDriverLocation(driverId);
    const distance = calculateDistance(driverLocation, pickupLocation);
    
    // Check if driver has arrived (within 100 meters)
    if (distance <= 0.1) { // 100 meters
      // Update trip status
      await updateTripStatus(tripId, 'arrived');
      
      // Get passenger device token
      const deviceToken = await getPassengerDeviceToken(tripId);
      const driverInfo = await getDriverInfo(driverId);
      
      // Send notification
      await sendDriverArrivedNotification(
        deviceToken,
        tripId,
        driverInfo.name
      );
      
      // Stop monitoring
      clearInterval(intervalId);
    }
  }, 10000); // Check every 10 seconds
}
```

## 7. Testing

### Test with Local Notifications
For development, you can test with local notifications (as implemented in the app):

```swift
// Test driver arrival notification
PushNotificationService.shared.sendDriverArrivedNotification(
    reference: "VRM-TEST-123",
    driverName: "Test Driver"
)
```

### Test APNs in Development
1. Use Apple's sandbox APNs server: `api.sandbox.push.apple.com`
2. Use a test device or simulator with proper provisioning
3. Monitor APNs response codes for debugging

## 8. Error Handling

### Handle APNs Errors
- **400 Bad Request** - Invalid notification payload
- **403 Forbidden** - Invalid certificate/key
- **410 Gone** - Device token is no longer valid (user uninstalled app)

### Retry Logic
Implement exponential backoff for failed notifications:
```javascript
async function sendNotificationWithRetry(deviceToken, notification, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await provider.send(notification, deviceToken);
    } catch (error) {
      if (attempt === maxRetries) throw error;
      await sleep(1000 * Math.pow(2, attempt)); // Exponential backoff
    }
  }
}
```

## 9. Privacy & Permissions

- Request notification permissions in app (already implemented)
- Store device tokens securely with encryption
- Delete device tokens when users log out or uninstall
- Respect user's notification preferences
- Comply with GDPR/privacy regulations for location tracking

## 10. Monitoring & Analytics

Track notification delivery:
- Notification sent count
- Notification delivered count
- Notification opened count
- Time from driver arrival to notification delivery
- Failed notification rate

This helps identify and fix issues quickly.
