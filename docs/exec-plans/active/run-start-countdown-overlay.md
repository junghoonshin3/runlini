# Run Start Countdown Overlay

## Purpose

Add a pre-start countdown overlay to the running tab so Runlini dims the whole
app, shows a 3-2-1 countdown, and only starts the actual run after the
countdown completes.

## Context and Orientation

- The running start/stop control lives in
  `lib/features/run_tracking/ui/running_tab_screen.dart`.
- The app shell uses an `IndexedStack` in
  `lib/features/dashboard/ui/runlini_home_screen.dart`, so a local overlay
  inside the running tab would not cover the bottom navigation.
- The run start action already flows through
  `RunPlaybackController.start()` in
  `lib/features/run_tracking/state/run_playback_providers.dart`.

## Progress

- [x] Confirm the current running-tab start flow and overlay insertion point
- [x] Add countdown state and controller
- [x] Render a global countdown overlay above the app scaffold
- [x] Animate each countdown number with a local fade/scale entrance-exit cycle
- [x] Route idle `START` presses through the countdown flow
- [x] Run HealthKit / Health Connect permission preflight before the countdown begins
- [x] Add provider and widget coverage for countdown behavior
- [x] Update product docs to mention the pre-start countdown
- [x] Run guardrails, analyze, and tests

## Decisions

- Countdown state will be global app UI state, not local widget state.
- Countdown covers the entire app surface, including the bottom navigation.
- The real run start happens only after `1` completes.
- Idle `START` first runs the health-permission preflight. The countdown begins
  only after that permission flow returns.
- If the preflight reports that Health Connect needs installation or update,
  the runner chooses between installing Health Connect and starting an app-local
  run before countdown begins.
- `STOP` still bypasses countdown and moves directly to the finish review.
- There is no cancel path, sound, or haptic in v1.
- The scrim stays static while each visible number animates locally with a
  fade/scale in-hold-out rhythm keyed off the displayed second.

## Implementation Steps

1. Add a small countdown state model plus a dedicated notifier/provider.
2. Render the overlay from the home screen and block interactions while active.
3. Update the running tab so idle starts run health-permission preflight, then
   use the countdown notifier; running stops bypass countdown and enter finish
   review.
4. Add provider tests for re-entry/reset and widget tests for overlay timing,
   interaction blocking, unavailable-start fallback, and stop regression.
5. Update the matching product doc and validate with repo checks.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- `running_tab_screen.dart` is already above the soft file-size target, so keep
  new logic outside that file where possible.
- If widget-test tap hit testing becomes flaky under the modal barrier, use
  coordinate taps instead of direct finder taps.
