# Run Pause/Resume Controls

## Purpose

Add a real paused run state to the app-side run controller so Runlini can pause
route capture and elapsed metrics without ending the current session.

## Context and Orientation

- Playback state and live GPS tracking live in
  `lib/features/run_tracking/state/run_playback_providers.dart`.
- The running HUD and bottom controls live in
  `lib/features/run_tracking/ui/running_tab_screen.dart`.
- Live metrics are derived in
  `lib/features/run_tracking/state/run_live_metrics_providers.dart` and
  `lib/features/run_tracking/service/live_run_metrics_calculator.dart`.
- Health export remains a side effect through
  `lib/core/health/health_workout_recorder.dart`.

## Progress

- [x] Add pause-aware playback state and controller methods
- [x] Stop route-point appends while paused and resume without countdown
- [x] Replace the bottom-left settings button with pause/resume during an active run
- [x] Keep the metrics panel visible while paused and freeze active-time values
- [x] Update tests and docs for the new control flow
- [ ] Run guardrails, analyze, and tests

## Decisions

- `idle` keeps `Settings` on the left and `START` in the center.
- `running` shows `PAUSE` on the left and `STOP` in the center.
- `paused` shows `RESUME` on the left and `STOP` in the center.
- `STOP` opens the finish review where the runner saves or discards.
- Resume is immediate and does not replay the 3-2-1 countdown.
- Pause freezes app-side elapsed time, pace, speed, and route capture.
- Live location can still update the visible running map while paused, but no
  new points are appended to `recordedPoints`.
- HealthKit / Health Connect export stays as one workout from first `START` to
  the finish-review save in this pass.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- Health export route timestamps now represent active running time, while the
  exported workout still spans wall-clock start to finish-review save.
- The running tab remains a large widget, so further control additions should
  keep moving state/formatting concerns out into focused files.
