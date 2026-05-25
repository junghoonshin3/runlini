# Crash Reporting

Runlini uses Firebase Crashlytics for crash diagnostics. The app is
connected to Firebase project `runlini`.

## Configuration

- Flutter uses generated options from `lib/firebase_options.dart`.
- The phone app Firebase config lives at `android/app/google-services.json`.
- The Wear app Firebase config lives at `android/wear/google-services.json`.
- The iOS config lives at `ios/Runner/GoogleService-Info.plist`.
- Android Firebase Gradle plugins are applied only when the matching
  `google-services.json` exists, so local builds without Firebase config keep
  working.

## Runtime Policy

- Flutter startup installs Crashlytics handlers for `FlutterError` and
  `PlatformDispatcher` errors.
- Crashlytics collection is enabled for debug, profile, and release app runs.
- Tests skip Crashlytics initialization.
- If Firebase config is missing or initialization fails, Runlini logs a short
  debug message and continues without crash reporting.
