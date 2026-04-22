# Live Run Metrics Panel

## Purpose

Add a live metrics panel that appears once a run starts, showing distance,
elapsed time, average pace, average speed, and a calories placeholder. Keep the
pre-run map clear with no top status banner, and keep the panel visible with a
clear paused state while paused.

## Context and Orientation

- The running HUD lives in `lib/features/run_tracking/ui/running_tab_screen.dart`.
- The source of accepted run points is `RunPlaybackState.recordedPoints`.
- Elapsed time must keep moving even when no fresh GPS sample arrives.

## Progress

- [x] Add a derived live-run metrics type and calculator
- [x] Add a ticker-driven provider for running elapsed time updates
- [x] Swap the top running HUD from the status banner to a metrics panel
- [x] Remove the pre-run top `RUN / GHOST` banner
- [x] Add provider and widget coverage for running metrics behavior
- [x] Update the product spec to describe the live run HUD
- [x] Run guardrails, analyze, and tests

## Decisions

- The metrics panel appears whenever a run session is active, including both
  `RunScreenStatus.running` and `RunScreenStatus.paused`.
- Idle and countdown do not render a top status banner.
- Distance, average pace, and average speed use only accepted recorded points.
- Elapsed time uses pause-aware active running time, refreshed by a 1-second
  ticker provider.
- `startedAt` anchors to the real run-start moment after countdown completion,
  not to the timestamp of a stale cached/live GPS sample.
- Calories stay as the static `-- kcal` placeholder in v1.
- Ghost status is hidden while the metrics panel is visible.
- While paused, the panel stays mounted, shows a `PAUSED` label, and freezes
  elapsed time plus average metrics until resume.

## Implementation Steps

1. Add a calculator that derives distance and averages from recorded points.
2. Add an active-session provider that combines playback state with a 1-second
   ticker and an injectable clock.
3. Render a dedicated metrics panel widget in the running tab when the session
   is active, keeping idle/countdown top chrome empty.
4. Add provider tests for time/distance/average derivation and widget tests for
   the HUD swap and elapsed-time updates.
5. Update the matching product spec and validate with repo checks.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- `running_tab_screen.dart` is already long, so new UI and formatting helpers
  should live in dedicated files.
- Elapsed time in tests must use an injectable clock because widget-test pumps
  do not move `DateTime.now()` by themselves.
