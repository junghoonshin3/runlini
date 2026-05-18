# Interval Feature Lock V1

## Purpose

Temporarily lock the interval feature while keeping the existing implementation
available for future reactivation.

## Context and Orientation

- The visible entry point is the running tab interval button.
- Existing saved settings may already contain `intervalWorkout.enabled=true`.
- While locked, saved interval settings should not be deleted or migrated.
- Runtime behavior should treat intervals as inactive so ghost runs, voice cues,
  live dashboard panels, and Wear sync are not affected by stale enabled values.

## Progress

- [x] Confirm intended scope: runtime should treat intervals as disabled.
- [x] Add a single interval lock constant and effective workout helper.
- [x] Show a future-availability message from the running tab button.
- [x] Skip ghost/interval conflict prompts while the lock is active.
- [x] Send a disabled interval config to Wear while the lock is active.
- [x] Update tests and docs.
- [x] Run guardrails, analyze, and tests.

## Decisions

- Use a `SnackBar` with `인터벌 기능은 추후에 제공될 예정이에요.` for the locked
  entry point.
- Preserve stored interval settings and do not add a migration.
- Keep interval sheet tests in place because the hidden implementation remains
  valid future code.

## Implementation Steps

1. Add `runIntervalFeatureLocked`, `runIntervalFeatureLockedMessage`, and an
   effective interval workout helper.
2. Apply the helper in `runIntervalFrameProvider`, ghost conflict checks, and
   Wear interval sync.
3. Change the running tab interval button to show the locked message and never
   open the sheet while locked.
4. Update widget/provider tests for the locked behavior.
5. Update the watch integration doc to match current behavior.

## Validation

- `flutter test test/features/run_tracking/run_interval_sheet_test.dart test/features/run_tracking/ghost_interval_conflict_test.dart test/features/ghost_racer/ghost_settings_flow_test.dart` passed.
- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed after removing an unnecessary direct import.
- `flutter test` passed.

## Risks or Recovery

- Remove the lock by setting `runIntervalFeatureLocked` to `false` and restoring
  the conflict tests when interval configuration is reopened.
