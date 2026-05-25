# Splash Background Color

## Purpose

Make the native splash background match the Runlini app icon instead of showing
a white flash.

## Context and Orientation

- Android launch drawables still used white or theme background values.
- iOS `LaunchScreen.storyboard` still used a white root view background.
- The app icon background color is already black via `ic_launcher_background`.

## Progress

- [x] Set Android launch drawables to `@color/ic_launcher_background`.
- [x] Set Android pre-Flutter `NormalTheme` window background to black.
- [x] Add Android 12+ splash background override.
- [x] Set iOS LaunchScreen root background to black.
- [x] Run validation commands.

## Decisions

- Use the existing launcher background color `#000000`.
- Keep the splash static; no Lottie or runtime animation is used.

## Implementation Steps

1. Update Android launch background resources.
2. Update Android window background styles for pre-Flutter frames.
3. Update iOS LaunchScreen root view color.
4. Validate native Android resources with a debug app build.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `cd android && ./gradlew :app:assembleDebug`

## Risks or Recovery

- If Android 12+ still shows a different icon background, verify the launcher
  adaptive icon mask and generated splash icon background separately.
