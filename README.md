# Inzirax mobile

Flutter app for real-time driver navigation, traffic reporting, and speed-camera warnings.

## Run

Install Flutter 3.22+. The repository contains the platform configuration, while Flutter generates the standard Xcode project and Gradle wrapper on the first setup:

```powershell
flutter create .
flutter pub get
flutter run --dart-define=INZIRAX_API_URL=http://10.0.2.2:8000 --dart-define=MAPBOX_ACCESS_TOKEN=<public-token>
```

`10.0.2.2` is Android Emulator's host loopback. Use `http://localhost:8000` for iOS Simulator, or the development machine's LAN IP on a physical device. Never ship a `ws://` endpoint or a Mapbox secret token in production.

The current FastAPI server exposes `POST /api/v1/trips/plan-routes`, `POST /api/v1/incidents`, and `ws/driver/location`, which are consumed by this app. Authenticate first through `AuthRepository` (or inject an access token with `SessionController.setAccessToken`) before planning routes or streaming telemetry.

## Platform configuration

The checked-in Android and iOS snippets contain the required location declarations. Complete these before release:

- Android: set a Mapbox public download token in `android/gradle.properties` as `MAPBOX_DOWNLOADS_TOKEN`, configure the Transistorsoft background-geolocation license if required, and request `ACCESS_BACKGROUND_LOCATION` only with Play-policy justification.
- iOS: set `MBXAccessToken` in `ios/Runner/Info.plist`, enable Background Modes → Location updates, and configure the background-geolocation license if required.
- The background plugin requires Transistorsoft licensing for production Android builds; foreground `geolocator` tracking remains functional without it.

## Architecture

`lib/features/navigation` owns screen state and map rendering. `lib/services` owns GPS, background GPS, WebSocket, voice, and offline camera cache. Network models deliberately mirror the backend's snake_case contract.
