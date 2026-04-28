# Running Behavior Settings

## Purpose

Turn the Settings tab's running section from read-only status text into real
controls for pre-start countdown length and live-location quality.

## Context and Orientation

- Settings persistence uses the `app_settings` key/value table, so new settings
  can be added without a schema migration.
- Countdown display lives in `run_start_countdown_providers.dart`.
- Live GPS stream cadence is selected in `live_location_providers.dart` and
  applied by `core/location/location_stream_client.dart`.

## Progress

- [x] Add running settings to `RunSettingsState`
- [x] Persist countdown seconds and location tracking preset
- [x] Render countdown and location preset controls in the Settings tab
- [x] Drive countdown length from settings
- [x] Drive location stream config from settings
- [x] Add provider, repository, and widget coverage
- [x] Update platform docs for preset-based live location cadence
- [x] Run guardrails, analyzer, and tests

## Decisions

- Countdown cannot be disabled in v1.
- Countdown range is `3..10` seconds, defaulting to `3`.
- Location updates use presets instead of direct second/meter input.
- `balanced` preserves the previous default: passive `3s / 5m`, workout
  `1s / 3m`.

## Implementation Steps

1. Extend settings types/repository/controller with `countdownSeconds` and
   `locationTrackingPreset`.
2. Add Settings tab controls for countdown seconds and tracking preset.
3. Replace the hard-coded `3` countdown loop with the configured value.
4. Pass a `LocationTrackingConfig` into the location stream client whenever
   live tracking starts, and restart the stream when the preset changes.
5. Keep app data and run-session persistence unchanged.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- If a location preset causes battery or route-quality issues on a real device,
  revert to `balanced` by default and adjust only the preset mapping values.
