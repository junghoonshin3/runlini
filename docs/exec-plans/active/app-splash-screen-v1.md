# App Splash Screen V1

## Purpose

Add a native splash screen that matches the Runlini app icon.

## Context and Orientation

- The current Android launch background is the Flutter default white/ambient
  background.
- The current iOS launch image is a 1px placeholder.
- The Runlini app icon already carries the brand language: true black,
  white runner, volt green route, and red speed streaks.

## Progress

- [x] Inspect current Android and iOS launch screen assets.
- [x] Generate splash logo assets from the existing app icon.
- [x] Update Android launch backgrounds to true black plus centered logo.
- [x] Update iOS LaunchScreen to true black plus centered logo.
- [x] Validate guardrails, analyzer, and tests.

## Decisions

- Use the existing app icon artwork instead of introducing a new splash-only
  illustration.
- Keep the splash screen quiet and readable: black background, centered mark,
  no extra copy.
- Preserve native launch behavior; do not add a Flutter-level splash route.

## Implementation Steps

1. Generate density-specific Android splash logo PNGs.
2. Generate iOS `LaunchImage` 1x/2x/3x PNGs.
3. Update Android `launch_background.xml` files.
4. Update iOS LaunchScreen background color.
5. Run validation.

## Validation

- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed.
- `flutter test` passed.
- `./gradlew :app:assembleDebug` passed.

## Risks or Recovery

- If a device renders the splash logo too large, regenerate the splash assets
  at a smaller base size.
- If Android 12 system splash differs, add a values-v31 theme follow-up.
