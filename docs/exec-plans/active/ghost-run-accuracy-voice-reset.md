# Ghost Run Accuracy Guard And Voice Reset

## Purpose

Make phone-started ghost runs require high-accuracy location tracking and
temporarily silence ghost-run TTS until the cue policy is redesigned.

## Progress

- [x] Block phone ghost-run start when location updates are not `정확`.
- [x] Route the accuracy dialog action to Settings > 러닝.
- [x] Silence phone TTS for all ghost runs.
- [x] Silence Wear TTS for all ghost runs while keeping haptics.
- [x] Add phone, Wear, and widget regression tests.
- [x] Run guardrails, analyze, Flutter tests, and Wear tests.

## Decisions

- `정확` means `RunLocationTrackingPreset.highAccuracy`.
- The app does not change the setting automatically.
- The guard applies to phone-started ghost runs; Wear has no matching phone
  location preset UI.
- Ghost-run TTS is fully disabled for now, including kilometer, interval, and
  ghost-status speech.
- Ghost runs and interval runs are mutually exclusive active modes for V1.
