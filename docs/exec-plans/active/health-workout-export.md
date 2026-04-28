# Health Workout Export

## Purpose

Wire the in-app running session to Apple HealthKit on iOS and Health Connect on
Android so a run started in Runlini can be exported as a workout, with route
data when available, without blocking the app's own run capture.

## Context and Orientation

- The running flow lives in `lib/features/run_tracking/state/run_playback_providers.dart`.
- Platform health adapters belong in `lib/core/health/`.
- The app already depends on the `health` Flutter plugin, but nothing in the
  app currently configures it or writes workout data.
- `RunPoint` stores relative timestamps, which is enough to rebuild workout
  route samples by combining it with the run `startedAt`.

## Progress

- [x] Confirm current run start/stop flow and existing health plugin support
- [x] Add a core health workout export adapter with platform guards
- [x] Trigger health export start from run start and finish from explicit save
- [x] Update Android and iOS project permissions/capabilities for workout export
- [x] Add focused tests for health export behavior
- [x] Update docs to match the new export flow
- [x] Run guardrails, analyze, and tests

## Decisions

- Keep Runlini's own GPS/run state as the source of truth. Health export is a
  secondary best-effort side effect.
- Do not block app-side run recording when HealthKit or Health Connect is
  unavailable, denied, or fails mid-flow.
- Treat `저장하기` as a local DB save first. Health backup runs afterward and
  updates the same local record to `synced`, `syncSkipped`, or `syncFailed`.
- A Health backup failure never rolls back the local saved run. The runner sees
  `저장됨 · Health 백업 실패` and can retry from the run detail or Settings tab.
- Build workout routes from accepted `recordedPoints` plus `startedAt`, so the
  health export matches the route the app actually chose to keep.
- App-side pause/resume remains local-only in v1. Health export still writes a
  single workout spanning the first `START` through the finish-review save.
- Create the workout-route builder at run start, then write/finalize the
  workout only when the runner taps `저장하기`.
- If the runner taps `기록 버리기`, discard the active workout-route builder
  instead of writing a workout.
- Request `WORKOUT` and `WORKOUT_ROUTE` permissions together through the
  `health` plugin.
- On Android, also request read access for distance, total calories burned, and
  steps because the `health` plugin enriches workout reads with those record
  types while resolving the saved workout UUID.
- On Android, request `WRITE_DISTANCE` together with `DISTANCE_DELTA`
  `READ_WRITE` access because `writeWorkoutData(totalDistance: ...)` writes a
  Health Connect distance record as part of the workout export.
- Request health permissions as a pre-start preflight before the 3-2-1
  countdown. The workout route builder still opens only after the countdown,
  when the real run starts.
- On Android 13 and lower, if Health Connect is missing or needs an update,
  show a pre-countdown choice: open the Health Connect install flow or continue
  with an app-local run that skips health export.

## Implementation Steps

1. Add a `core/health` adapter that wraps the `health` plugin and hides
   configure, authorization, route builder, workout write, and cleanup logic.
2. Inject that adapter into the run playback controller and call it from
   `start()`, `saveFinishedRun()`, and `discardFinishedRun()`.
3. Update native project files:
   - Android manifest permissions and Health Connect intent plumbing
   - Android `MainActivity` host class for the plugin permission flow
   - iOS `Info.plist` HealthKit purpose strings
   - iOS entitlements/project wiring for HealthKit capability
4. Add provider/unit tests that verify:
   - run start still succeeds when health export is unavailable
  - run stop creates a draft without health finish
  - save forwards the completed track to the health exporter
  - discard cancels route capture without writing a workout
   - failed health export does not crash or wedge the run controller

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- Health Connect and HealthKit capability setup can still require final
  signing/capability confirmation in Android Studio/Xcode.
- If the health plugin cannot surface the saved workout UUID reliably, keep the
  local run working, mark Health backup by status, and leave `externalId` null.
- The current export writes the workout and then looks it up again to attach the
  route, because the Flutter `health` plugin write API returns only success and
  not the created workout UUID.
