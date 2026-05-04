# GPS Stationary Drift Filter

## Purpose

Prevent stationary GPS jitter from inflating route distance, pace, calories, and
ghost race comparison while keeping the live blue dot responsive.

## Context and Orientation

- Native GPS values enter through `GeolocatorRunLocationClient`.
- Live marker state is owned by `LiveLocationController`.
- Recorded route points pass through `RunPointSanitizer` before they become
  `RunPlaybackState.recordedPoints`.
- Samsung Health exposes exercise route accuracy publicly, but its internal
  stationary filtering algorithm is not public.

## Progress

- [x] Add horizontal and speed accuracy to live samples and recorded points
- [x] Preserve accuracy fields through Health route import/export
- [x] Reject poor-accuracy points from recorded routes
- [x] Reject low-speed movement inside the reported accuracy radius
- [x] Keep the live marker on raw live GPS while filtering recorded points
- [x] Add focused sanitizer and provider tests
- [x] Run guardrails, analyze, and full tests

## Decisions

- The first recorded point remains the session anchor even if accuracy is
  unknown or poor.
- Workout route candidates with horizontal accuracy above `35m` are rejected.
- Movement under `3m` is treated as jitter.
- Low or missing OS speed plus movement inside the combined accuracy radius is
  treated as stationary drift.
- This is not auto-pause: elapsed time keeps running.

## Implementation Steps

1. Carry `horizontalAccuracyM` and `speedAccuracyMps` from platform positions to
   live samples and recorded points.
2. Extend `RunPointSanitizer` with accuracy, stationary drift, max speed, and
   conservative acceleration checks.
3. Keep map marker state based on `liveLocationProvider`; only
   `recordedPoints` are filtered.
4. Update reliability docs with the raw-vs-accepted GPS rule.
5. Validate with guardrails, analyzer, and tests.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- Some devices report weak or missing speed accuracy. The filter still uses
  horizontal accuracy and distance gates, and falls back to the previous spike
  filter when accuracy is unavailable.
- If real runs feel under-recorded, tune the `35m`, `3m`, and `0.7m/s`
  thresholds before adding sensor-based auto-pause.
