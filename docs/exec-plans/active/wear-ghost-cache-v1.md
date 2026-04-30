# Wear Ghost Cache V1

## Purpose

Keep up to three phone-selected ghost routes on the Wear OS app so the runner can
start a recent ghost run from the watch without re-selecting the route on the
phone every time.

## Decisions

- Cache size is exactly 3 most-recent phone-selected ghost routes.
- The active ghost is the most recently received or watch-selected route.
- Route points are stored as-is. No point thinning or resampling in V1.
- `timestampRelMs` is preserved because ghost gap accuracy depends on the
  original route timing.
- The phone only sends route candidates that pass basic sanity checks: positive
  duration/distance, strictly increasing `timestampRelMs`, finite in-range
  coordinates/elevation, and a compact route bounding box. Corrupt emulator
  routes are not valid ghost candidates.
- If the phone clears ghost mode, the watch clears the active ghost and cache.
- Existing single `wear_ghost_config.json` data migrates into a one-item cache
  on first read.

## UI Shape

- Zero cached ghosts: Ready pager still exposes `고스트 선택`, and the page shows
  only `없음`.
- One cached ghost: Ready keeps the direct `고스트런 시작` / `일반 시작` layout,
  and the pager still exposes `고스트 선택` so the runner can confirm it.
- Two or three cached ghosts: the same lightweight `고스트 선택` page lists them.
- The selection page shows at most three large rows with short label, distance,
  and duration. No search, history, delete, or sorting UI in V1.

## Validation

- [x] `./gradlew :wear:testDebugUnitTest`
- [x] `./gradlew :wear:assembleDebug`
- [x] `dart run tool/guardrails.dart`
- [x] `flutter analyze`
- [x] `flutter test`
