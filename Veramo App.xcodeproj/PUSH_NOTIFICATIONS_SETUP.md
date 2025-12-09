# Push Notifications Setup Guide

## Overview
This guide explains how to enable push notifications so users receive alerts when support sends them messages in the chat.

## Files Added
1. **PushNotificationService.swift** - Handles push notification registration
2. **AppDelegate.swift** - Manages APNs callbacks and notification handling
3. Updated **Veramo_AppApp.swift** - Connected AppDelegate

## Setup Steps

### 1. Apple Developer Portal Configuration

#### A. Enable Push Notifications for Your App ID
1. Go to https://developer.apple.com/account
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** → Your App ID
4. Enable **Push Notifications** capability
5. Click **Save**

#### B. Create APNs Authentication Key (Recommended)
1. Go to **Keys** → Click **+** to create a new key
2. Name it "Stream Chat Push Notifications"
3. Check **Apple Push Notifications service (APNs)**
4. Click **Continue** → **Register**
5. **Download the key** (.p8 file) - You can only download this once!
6. Note your **Key ID** and **Team ID**

### 2. Xcode Project Configuration

#### A. Add Push Notifications Capability
1. In Xcode, select your project
2. Select your app target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Push Notifications**

#### B. Add Background Modes
1. Still in **Signing & Capabilities**
2. Click **+ Capability** again
3. Add **Background Modes**
4. Check:
   - ✅ **Remote notifications**

### 3. Stream Dashboard Configuration

1. Go to https://dashboard.getstream.io/
2. Select your app (API key: `j46xbwqsrzsk`)
3. Navigate to **Chat** → **Push Notifications**
4. Select **iOS** tab
5. Choose **APNs Auth Key** (recommended)
6. Upload your `.p8` file
7. Enter:
   - **Key ID**: From Apple Developer Portal
   - **Team ID**: Your Apple Developer Team ID
   - **Bundle ID**: `com.yourcompany.VeramoApp` (your actual bundle ID)
8. Select environment: **Development** (for testing) or **Production**
9. Click **Save**

### 4. Testing Push Notifications

#### Test in Development:
1. Run app on a **real device** (push notifications don't work in simulator)
2. Log in as a customer
3. Open the Chat tab to register device token
4. Go to Stream Dashboard as `veramo-admin`
5. Send a message to the customer
6. Customer should receive a push notification!

#### What Gets Sent:
When support sends a message, the user receives:
- **Title**: "Support" (or sender name)
- **Body**: The message text
- **Badge**: Unread message count
- **Sound**: Default notification sound

#### Notification Behavior:
- **App Closed**: Full notification with sound
- **App in Background**: Full notification with sound
- **App in Foreground**: Banner notification (configurable)
- **Tap Notification**: Opens chat to that conversation

### 5. Production Configuration

Before releasing to the App Store:

#### A. Update Stream Dashboard
1. In Stream Dashboard → Push Notifications
2. Add **Production** configuration
3. Use **Production** APNs environment
4. Can use the same `.p8` key file

#### B. Test with TestFlight
1. Upload build to TestFlight
2. Install on test device
3. Verify push notifications work in production mode

### 6. Customizing Notifications

#### Modify Notification Content:
You can customize notifications in the Stream Dashboard:

1. **Push Templates**:
   - Go to **Chat** → **Push Templates**
   - Customize message format
   - Add custom data

2. **Notification Sounds**:
   - Add custom sound files to Xcode project
   - Configure in Stream push template

#### Code Customization:
In `AppDelegate.swift`, modify notification presentation:

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // Customize what shows when app is in foreground
    completionHandler([.banner, .badge, .sound])
}
```

### 7. Handling Notification Taps

When user taps a notification, the app opens to the chat. This is handled in `AppDelegate.swift`:

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    // Opens the chat channel
    if let channelId = userInfo["channel_id"] as? String {
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenChatChannel"),
            object: nil,
            userInfo: ["channelId": channelId]
        )
    }
    completionHandler()
}
```

### 8. Troubleshooting

#### "Failed to register for remote notifications"
- **Check**: Push Notifications enabled in Xcode capabilities
- **Check**: Running on real device (not simulator)
- **Check**: Valid provisioning profile with push enabled

#### "Device token not registering with Stream"
- **Check**: User is logged into chat (device token sent after connection)
- **Check**: Stream API key is correct
- **Check**: Internet connection available

#### "Not receiving notifications"
- **Check**: Notifications enabled in iOS Settings → Your App
- **Check**: APNs key uploaded to Stream Dashboard
- **Check**: Bundle ID matches in Stream Dashboard
- **Check**: Using correct environment (Development vs Production)

#### Test APNs Connection:
Use Apple's push notification testing tool:
```bash
# Install
brew install knoxite/tap/houston

# Test
houston apns push \
  --key /path/to/key.p8 \
  --key-id YOUR_KEY_ID \
  --team-id YOUR_TEAM_ID \
  --bundle-id com.yourcompany.VeramoApp \
  --token DEVICE_TOKEN \
  --alert "Test message"
```

### 9. Privacy & Permissions

#### Info.plist Updates:
Add notification description (optional but recommended):

```xml
<key>NSUserNotificationUsageDescription</key>
<string>We'll notify you when support responds to your messages</string>
```

#### Permission Timing:
Currently, permission is requested on app launch. Consider requesting when:
- User first opens Chat tab
- User sends their first message
- During onboarding flow

Update in `ChatView.swift` `onAppear`:
```swift
.onAppear {
    connectUserIfNeeded()
    // Request push permission when user uses chat
    PushNotificationService.shared.requestAuthorization()
}
```

### 10. Unregistering Device Token

When user logs out, unregister their device token:

Update `AuthenticationManager.swift` logout:
```swift
func logout() {
    // Unregister push notifications
    if let deviceToken = savedDeviceToken {
        PushNotificationService.shared.unregisterDeviceToken(deviceToken)
    }
    
    sessionToken = nil
    currentCustomer = nil
    ChatManager.shared.disconnect()
}
```

## Summary

✅ **Setup Complete When:**
- Push capability enabled in Xcode
- APNs key uploaded to Stream Dashboard
- AppDelegate connected
- Tested on real device

🔔 **Users Will Receive:**
- Notifications when support sends messages
- Unread message badge count
- Sound/vibration alerts
- Deep link to open chat on tap

## Next Steps

1. Test thoroughly on real devices
2. Verify notifications in Development environment
3. Configure Production settings before App Store release
4. Consider adding notification customization
5. Monitor notification delivery rates in Stream Dashboard

## Support

- Stream Push Docs: https://getstream.io/chat/docs/ios-swift/push_introduction/
- APNs Guide: https://developer.apple.com/documentation/usernotifications
- Stream Dashboard: https://dashboard.getstream.io/
