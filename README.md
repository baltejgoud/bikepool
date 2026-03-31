# BikePool 🚴 — P2P Ride-Sharing App

Real-time bike and car pooling platform for Hyderabad, India. Built with Flutter.

---

## 🚀 Getting Started

### Prerequisites

1. **Install Flutter SDK**: Download from [flutter.dev](https://docs.flutter.dev/get-started/install/windows)
   - Extract to `C:\flutter`
   - Add `C:\flutter\bin` to your **System PATH**
   - Run `flutter doctor` and resolve all issues

2. **Android Studio** (for emulator/device builds)
   - Install Android Studio
   - Install an Android Virtual Device (AVD) via AVD Manager

3. **Google Maps API Key**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable: **Maps SDK for Android**, **Maps SDK for iOS**, **Geocoding API**, **Places API**
   - Create an API key and paste it in `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY"
                android:value="YOUR_KEY_HERE"/>
     ```

---

## 🛠️ Setup

```bash
# 1. Navigate to the Flutter project
cd "c:\Users\admin\Desktop\Bike pooling\BikePool"

# 2. Get all dependencies
flutter pub get

# 3. Run the app (with a connected device or emulator)
flutter run
```

---

## 📁 Project Structure

```
lib/
├── main.dart                       # Entry point (Riverpod ProviderScope)
├── app.dart                        # Root app with GoRouter + theme
├── core/
│   ├── theme/
│   │   ├── app_colors.dart         # Brand color palette
│   │   └── app_theme.dart          # Light & Dark ThemeData
│   └── router/
│       └── app_router.dart         # GoRouter with all named routes
└── features/
    ├── onboarding/
    │   └── onboarding_screen.dart  # Phone + OTP login
    ├── home/
    │   └── home_screen.dart        # Map + "Where to?" + mode toggle
    ├── ride_selection/
    │   └── ride_selection_screen.dart  # Bottom drawer with Bike/Car options
    ├── ride_tracking/
    │   └── tracking_screen.dart    # Live map + driver info + SOS
    └── driver/
        └── offer_ride_screen.dart  # Post a ride (Driver mode)
shared/
└── widgets/
    ├── vehicle_card.dart           # Ride option card (price, ETA, seats)
    └── quick_suggestion_chip.dart  # Home/Work quick chips
```

---

## 🔑 Key Dependencies

| Package | Purpose |
| :--- | :--- |
| `google_maps_flutter` | Interactive map widget |
| `geolocator` | Real-time GPS |
| `go_router` | Declarative navigation |
| `flutter_riverpod` | State management |
| `google_fonts` | Inter + Outfit typography |
| `lottie` | Micro-animations |

---

## 🎨 Screens

| Screen | Route | Description |
| :--- | :--- | :--- |
| Onboarding | `/onboarding` | Phone + OTP entry |
| Home | `/home` | Map-first, Rider/Driver toggle |
| Ride Selection | `/home/select-ride` | Bottom drawer with Bike/Car |
| Live Tracking | `/home/tracking` | Route map + driver info + SOS |
| Offer Ride | `/offer-ride` | Driver post-ride screen |

---

## ⚠️ Legal Disclaimer

This platform operates on a **cost-sharing model** for personal commuters. Pricing is capped at actual fuel/maintenance costs and does not constitute a commercial taxi or transport service.

---

*Built by Antigravity for BikePool Hyderabad — 2026*
