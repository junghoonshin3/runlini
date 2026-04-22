# Osaka Ghost Fixture

## Purpose

Add repeatable Osaka ghost run fixtures so the ghost rider flow can be tested
with realistic route geometry before a real saved run exists.

## Context and Orientation

- The Google Routes API response uses GeoJSON coordinates in `[lng, lat]`
  order.
- Runlini route playback uses `RunSession` and `RunPoint` with
  `latitude`, `longitude`, relative timestamps, optional pace, and point source.
- The Tobita fixture models a 6:00/km runner over the provided 2.909 km route.
- The Kanzakigawa fixture models a 7:00/km runner over the provided 7.921 km
  route with varied segment paces.
- Cadence is not part of a `RunPoint`; store average cadence as optional
  session-level metadata for now.

## Progress

- [x] Add the provided Google route response as a fixture asset.
- [x] Convert the route response into a `RunSession` with generated timestamps.
- [x] Preserve the existing primary fixture as the default map fallback.
- [x] Fit the native map camera to a selected ghost route before a run starts.
- [x] Add tests for the Osaka ghost fixture shape and timing.
- [x] Run guardrails, analysis, and tests.
- [x] Add the Osaka Namba to Kanzakigawa route fixture.
- [x] Generate a 7:00/km, cadence-170 ghost with varied segment pace bands.

## Decisions

- Keep the raw route response in an asset so the original Google API shape is
  still inspectable.
- Generate point timestamps from cumulative route distance so dense and sparse
  route segments progress naturally over time.
- Use `durationMs = distanceKm * 360 seconds` for a 6:00/km average pace.
- Use `durationMs = distanceKm * 420 seconds` for the Kanzakigawa 7:00/km
  average pace.
- Keep the Kanzakigawa fixture as the newest fixture so fixture fallback map
  center and emulator GPS defaults both begin at the route start.
- Store cadence as `RunSession.averageCadenceSpm` because the current live GPS
  point model does not carry step cadence.
- Keep Google route conversion in a shared fixture factory so new route fixtures
  do not bloat `FakeRunFixtureLoader`.
- When a ghost route is selected and no current run polyline exists yet, preview
  the whole ghost route once. The current-location button still recenters to
  live GPS when the user asks for it.

## Implementation Steps

1. Add `assets/fixtures/osaka_namba_tobita_route.json`.
2. Register the asset in `pubspec.yaml`.
3. Extend `RunSession` and `RunSessionSummary` with optional cadence metadata.
4. Add route fixture loading and conversion in `FakeRunFixtureLoader`.
5. Make native maps fit the selected ghost route before recording starts.
6. Add a fixture loader test.

## Validation

- `dart run tool/guardrails.dart` passes.
- `flutter analyze` passes.
- `flutter test` passes.

## Risks Or Recovery

- If the route asset is malformed, the loader test should fail before the app
  reaches the ghost picker.
- If cadence later moves to per-sample data, migrate the session-level field to
  richer sensor samples without changing this route fixture's geometry.
