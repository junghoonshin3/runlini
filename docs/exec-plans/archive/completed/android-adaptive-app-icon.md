# Android Adaptive App Icon

## Summary

- Android launcher currently shows the legacy square `ic_launcher.png` inside a
  white launcher mask.
- Add a proper adaptive icon so Runlini renders as a native masked icon with a
  black background.

## Changes

- Add adaptive icon XML resources for API 26+.
- Add black icon background color and foreground bitmap resources with safe
  padding.
- Keep existing legacy launcher PNGs for older Android versions.

## Validation

- `./gradlew :app:assembleDebug` passed from `android/`.
- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed.
- `flutter test` passed.
