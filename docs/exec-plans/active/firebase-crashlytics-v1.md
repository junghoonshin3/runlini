# Firebase Crashlytics V1

## Summary

- Add Firebase Crashlytics to the Flutter phone app and native Wear module.
- Connect Android, iOS, and Wear configs to Firebase project `runlini`.
- Keep local builds working when Firebase config files are absent.
- Capture Flutter framework and async uncaught errors once Firebase initializes.

## Decisions

- Android Gradle Firebase plugins are conditional on `google-services.json`.
- Flutter initializes Firebase with `DefaultFirebaseOptions.currentPlatform`.
- Flutter Crashlytics is enabled for debug, profile, and release app runs.
- Tests and missing Firebase config use a no-op path.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :app:assembleDebug :wear:assembleDebug`
