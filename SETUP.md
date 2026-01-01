# Setup Guide for HabitMate

This guide will help you set up the HabitMate app for Android and iOS development.

## Prerequisites

1. **Flutter SDK**: Install Flutter (3.0.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio

3. **Xcode** (for iOS development - macOS only)
   - Available on Mac App Store

## Installation Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Android Setup

#### Minimum Requirements
- Android SDK 21 (Android 5.0) or higher
- Android Studio with Android SDK

#### Notification Permissions (Android 13+)

For Android 13 (API 33) and above, add the following permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add this line for notification permissions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application
        android:label="HabitMate"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... rest of your application config ... -->
    </application>
</manifest>
```

#### Run on Android

```bash
# List available devices
flutter devices

# Run on connected device/emulator
flutter run
```

### 3. iOS Setup (macOS only)

#### Minimum Requirements
- macOS with Xcode installed
- iOS 11.0 or higher
- CocoaPods (usually installed with Xcode)

#### Install CocoaPods Dependencies

```bash
cd ios
pod install
cd ..
```

#### Notification Permissions

iOS will automatically request notification permissions when the app first tries to schedule a notification. No manual configuration needed in Info.plist for basic notifications.

#### Run on iOS

```bash
# Open iOS Simulator or connect physical device
flutter run
```

## Testing Notifications

1. Create a new habit in the app
2. Add a reminder time (e.g., 10:00 AM)
3. Save the habit
4. The notification should appear at the scheduled time

**Note**: For testing notifications immediately:
- On Android: You can schedule a notification for a time just a few minutes in the future
- On iOS: Notifications work best when the app is in the background

## Troubleshooting

### Notifications Not Working

1. **Check Permissions**:
   - Android: Go to Settings > Apps > HabitMate > Notifications
   - iOS: Go to Settings > HabitMate > Notifications

2. **Verify Timezone**:
   - The app uses the device's local timezone
   - Check that your device timezone is set correctly

3. **Check Logs**:
   ```bash
   flutter run --verbose
   ```

### Database Issues

If you encounter database errors:
- The app uses SQLite (sqflite package)
- Data is stored locally on the device
- Uninstalling the app will delete all data

### Build Errors

1. **Clean and Rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check Flutter Version**:
   ```bash
   flutter --version
   ```
   Should be 3.0.0 or higher

## Project Structure

```
HabitMate/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── screens/
│   ├── services/
│   └── widgets/
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

## Next Steps

1. Run `flutter pub get` to install dependencies
2. Connect a device or start an emulator
3. Run `flutter run` to launch the app
4. Start adding habits and tracking your progress!

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [sqflite Package](https://pub.dev/packages/sqflite)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

---

Happy habit tracking! 🎯

