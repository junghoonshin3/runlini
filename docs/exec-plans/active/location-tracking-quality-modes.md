# Location Tracking Quality Modes

## Purpose

Tune live GPS sampling so Runlini uses a lighter stream before a run and a
higher-frequency stream while recording.

## Context and Orientation

- Native location access is adapted in
  `lib/core/location/location_stream_client.dart`.
- Live subscription lifetime is controlled by
  `lib/features/run_tracking/state/live_location_providers.dart`.
- Playback status is `idle`, `running`, or `paused`.

## Progress

- [x] Add explicit passive and workout GPS tracking modes
- [x] Use passive mode before start and while paused on the running tab
- [x] Use workout mode while the run is actively recording, including on other tabs
- [x] Restart the native stream when the tracking mode changes
- [x] Cover mode selection in provider tests
- [x] Update platform permission notes

## Decisions

- Passive mode is `3s / 5m` on Android and `5m` on iOS.
- Workout mode is `1s / 3m` on Android and `3m` on iOS.
- Android foreground tracking notification is only attached to workout mode.
- iOS background location indicators are only enabled for workout mode.
- Paused sessions keep live map movement only while the running tab is visible.

## Implementation Steps

1. Add `LocationTrackingMode` to the core location adapter.
2. Pass the desired mode from `LiveLocationController` into
   `LocationStreamClient.watchLocationSamples`.
3. Derive the desired mode from app tab and playback status.
4. Restart the stream when status changes between passive and workout.
5. Update tests and docs.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- Android and iOS do not guarantee exact sample cadence. The requested cadence
  is a target; OS power policy and sensor conditions may still coalesce samples.
- If passive mode proves too chatty on real devices, increase its distance
  filter first before changing workout mode.
