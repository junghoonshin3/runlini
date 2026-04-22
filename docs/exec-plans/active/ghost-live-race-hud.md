# Ghost Live Race HUD

## Purpose

Show live ghost-race feedback while a run is active so the runner can see
whether they are ahead or behind the selected previous run.

## Context and Orientation

- Ghost route selection and pace-colored route rendering already exist.
- The running screen already has a live metrics panel and pause-aware elapsed
  time.
- Current map state already carries runner and ghost route geometry.

## Progress

- [x] Add a route-progress based ghost gap service.
- [x] Expose a live ghost race frame provider.
- [x] Render the ghost comparison inside the live metrics panel.
- [x] Render the current-time ghost marker on fake, Google, and Apple maps.
- [x] Update product docs and tests.
- [x] Run guardrails, analyze, and tests.

## Decisions

- The primary comparison is time gap at the same route progress.
- The secondary comparison is distance gap at the same elapsed time.
- Samples rejected from `recordedPoints` are ignored by ghost comparison.
- Off-route starts at 35 meters from the selected ghost path.
- The ghost marker shows where the previous run was at the current active
  elapsed time.

## Implementation Steps

1. Add `GhostRaceFrame` and a service that projects the runner onto the selected
   ghost route.
2. Add a run-tracking provider that combines playback state, selected ghost
   session, ticker updates, and the gap service.
3. Add ghost frame formatting and render it in `LiveRunMetricsPanel`.
4. Add `ghostMarkerPoint` to map state and surfaces.
5. Add service/provider/widget tests for ahead, behind, level, off-route, pause,
   and marker rendering.

## Validation

- `dart run tool/guardrails.dart` passes with existing file-length warnings.
- `flutter analyze` passes.
- `flutter test` passes.

## Risks or Recovery

- Native map marker rendering differs by SDK, so fake map tests verify the app
  contract and emulator/device checks confirm the platform visuals.
