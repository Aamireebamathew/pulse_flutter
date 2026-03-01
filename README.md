# Pulse Flutter App

A Flutter port of the **Pulse** React web app — a smart object tracking and monitoring application.

---

## Features Converted

| React Screen | Flutter Screen |
|---|---|
| Login / Register / Forgot Password | `login_screen.dart`, `register_screen.dart` |
| Dashboard Overview with stats | `overview_screen.dart` |
| Registered Objects (search + delete) | `registered_objects_screen.dart` |
| Add Object (image upload) | `add_object_screen.dart` |
| Live Camera ML Detection | `live_camera_screen.dart` |
| Alerts & History (filter chips) | `alerts_history_screen.dart` |
| Phone Recovery (GPS + sound) | `phone_recovery_screen.dart` |
| Bluetooth Device Management | `bluetooth_devices_screen.dart` |
| Settings (preferences + theme) | `settings_screen.dart` |
| Sidebar Navigation | `main_dashboard.dart` |

---

## Setup

### 1. Add your Supabase credentials

Open `lib/services/supabase_service.dart` and replace:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run the app
```bash
flutter run
```

---

## Platform Permissions

### Android — `android/app/src/main/AndroidManifest.xml`
Add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

Also add `android:usesCleartextTraffic="true"` to `<application>` for Supabase.

### iOS — `ios/Runner/Info.plist`
Add:
```xml
<key>NSCameraUsageDescription</key>
<string>Used to detect registered objects</string>
<key>NSMicrophoneUsageDescription</key>
<string>Used for voice assistant features</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to locate your phone</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Used to connect and track Bluetooth devices</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to upload object photos</string>
```

---

## Architecture

```
lib/
├── main.dart                     # App entry + GoRouter
├── utils/
│   └── app_theme.dart            # Light + Dark themes
├── services/
│   └── supabase_service.dart     # All Supabase calls
├── providers/
│   ├── auth_provider.dart        # Auth state (ChangeNotifier)
│   └── theme_provider.dart       # Theme toggle (ChangeNotifier)
├── widgets/
│   └── common_widgets.dart       # GlassCard, GradientButton, StatCard, etc.
└── screens/
    ├── login_screen.dart
    ├── register_screen.dart
    └── dashboard/
        ├── main_dashboard.dart   # Shell with sidebar nav
        ├── overview_screen.dart
        ├── registered_objects_screen.dart
        ├── add_object_screen.dart
        ├── live_camera_screen.dart
        ├── alerts_history_screen.dart
        ├── phone_recovery_screen.dart
        ├── bluetooth_devices_screen.dart
        └── settings_screen.dart
```

---

## Key Dependencies

| Package | Purpose |
|---|---|
| `supabase_flutter` | Backend (auth, database, storage) |
| `go_router` | Navigation with deep linking |
| `provider` | State management |
| `geolocator` | GPS for phone recovery |
| `flutter_blue_plus` | Bluetooth device scanning |
| `camera` | Live camera feed |
| `image_picker` | Object photo uploads |
| `speech_to_text` | Voice assistant |
| `shared_preferences` | Theme persistence |

---

## Live Camera ML Detection

The React app uses TensorFlow.js + MobileNet in the browser. In Flutter:

1. Install `tflite_flutter` and `tflite_flutter_helper`
2. Download the MobileNet `.tflite` model from TFHub
3. Add to `assets/` and declare in `pubspec.yaml`
4. In `live_camera_screen.dart`, replace the placeholder with:
   - `CameraController` from `camera` package
   - `Interpreter` from `tflite_flutter`
   - Cosine similarity logic (same as the React version)

---

## Notes

- The glassmorphism design from the React app is replicated using `withOpacity()` on `Container` backgrounds with `BoxShadow`
- Light/dark theme fully supported, toggleable from sidebar or Settings
- Responsive layout: sidebar on wide screens (tablets), drawer on mobile
- All Supabase tables expected: `objects`, `activity_logs`, `user_preferences`
