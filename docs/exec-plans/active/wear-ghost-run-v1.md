# Wear OS Ghost Run V1

## Purpose

Let the phone-selected Ghost Rider run execute independently on the Wear OS app.
The phone prepares the ghost route, the watch caches it, and the watch compares
the live run against that cached ghost without requiring a live phone link.

## Context And Orientation

- Phone Flutter remains the source of truth for history and ghost selection.
- The Wear OS app already records independent runs and syncs completed drafts.
- Existing phone ghost logic compares the runner against a previous run by
  route projection and active elapsed time.
- Existing saved sessions already support optional `ghostSummary` metadata.

## Progress

- [x] Confirm product direction: phone-selected, watch-independent ghost runs.
- [x] Add phone-to-watch ghost config contract and Data Layer sender.
- [x] Add Wear ghost config listener, cache, and ready-screen entry.
- [x] Port ghost gap calculation to Wear Kotlin and show live status.
- [x] Include ghost summary in Wear draft import.
- [x] Update tests and docs.
- [x] Run validation commands.

## Decisions

- Data Layer path for selected ghost config is `/runlini/phone/ghost_config`.
- Full ghost config JSON is sent as Asset `ghostJson`.
- Watch only exposes a ghost run when the cached route has enough points.
- The watch Ready screen makes `GHOST START` primary when a ghost is cached and
  keeps `일반 시작` as a secondary action.
- Ghost thresholds match phone behavior: 3 seconds level, 3 meters level
  distance, and 35 meters off-route.

## Implementation Steps

1. Add `WatchGhostConfig` and extend `WatchRunDraft` with optional
   `ghostSummary`.
2. Add a phone MethodChannel and native Android Data Layer sender for ghost
   config send / clear.
3. Trigger ghost config sync from ghost selection / clear and app foreground.
4. Add Wear ghost config persistence, listener service, and manifest entry.
5. Add Wear ghost gap calculator, state fields, start flow, UI status, and
   draft mapping.
6. Add Dart and Kotlin tests for contracts, sync, calculator, draft import, and
   native sender / listener behavior.
7. Update watch integration docs and run validation.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :app:testDebugUnitTest`
- `./gradlew :app:assembleDebug :wear:assembleDebug`

## Risks Or Recovery

- Large ghost routes may make Data Layer assets bigger than normal settings
  payloads; if this becomes a problem, add route thinning in a later slice.
- Wear emulator location data may be sparse, so unit tests cover gap logic and
  manual emulator validation covers the real UI loop.
