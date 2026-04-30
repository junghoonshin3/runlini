# Wear Recent Ghost Sync V1

## Purpose

Keep the watch stocked with the three most recent runnable ghost routes from the
phone so a runner can start a ghost run on Wear OS without manually re-sending a
single route each time.

## Decisions

- Runnable means the session can build a `WatchGhostConfig` with at least two
  route points.
- The phone sends a batch to `/runlini/phone/ghost_configs` with one active id
  and up to three original route configs.
- Route points are not thinned or resampled. `timestampRelMs` is preserved.
- App launch, foreground resume, run list changes, and Settings > 연동 manual
  sync update the watch cache.
- Charging-only background sync is a follow-up, not V1.

## Validation

- [x] `dart run tool/guardrails.dart`
- [x] `flutter analyze`
- [x] `flutter test`
- [x] `./gradlew :app:testDebugUnitTest`
- [x] `./gradlew :wear:testDebugUnitTest`
- [x] `./gradlew :wear:assembleDebug`
