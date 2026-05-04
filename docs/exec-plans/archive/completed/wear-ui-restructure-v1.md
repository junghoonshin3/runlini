# Wear OS UI Restructure V1

## Purpose

Restructure the native Wear OS app from one dense metrics screen into a
watch-native flow: ready launch hub, swipeable running pages, a safe controls
page, paused focus, and finish review.

## Context And Orientation

- Health Services recording, pending draft sync, phone ack, ghost config sync,
  and ghost gap calculation are already in place.
- `MainActivity.kt` currently owns app bootstrap, permissions, and every
  composable screen.
- The active run UI currently stacks elapsed time, ghost status, all metrics,
  and controls in one vertical list.

## Progress

- [x] Confirm UI direction: ready hub, horizontal running pages, controls page.
- [x] Split Wear UI composables out of `MainActivity.kt`.
- [x] Add page model, formatter, ready model, and review model tests.
- [x] Add swipeable active run pages.
- [x] Preserve recording and sync behavior.
- [x] Run validation commands.
- [x] Worker 1 design pass: sharpen Wear UI hierarchy, spacing, labels, and tests.

## Decisions

- Ready screen acts as a launch hub.
- Running pages are `Core`, optional `Ghost`, `Details`, and `Controls`.
- Pause and stop actions live on the controls page while running.
- Paused state gets its own focused resume / stop screen.
- Review screen shows only save, discard, and short result summary.
- Worker 1 keeps Health Services, Data Layer, ghost gap, and draft sync logic
  unchanged; the pass is limited to Wear presentation and UI model labels.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`
- `./gradlew :app:assembleDebug :wear:assembleDebug`

Worker 1 validation:

- `android/gradlew :wear:testDebugUnitTest` passed.
- `android/gradlew :wear:assembleDebug` passed.
- `dart run tool/guardrails.dart` ran from the repo root and failed on
  pre-existing out-of-scope Dart file length issues in
  `lib/features/run_tracking/ui/history/history_tab_screen.dart` and
  `test/helpers/runlini_widget_harness.dart`.

## Risks Or Recovery

- Horizontal pager behavior needs emulator validation on round screens.
- If pager dependencies conflict, keep the file split and fall back to the
  existing vertical active screen until dependency alignment is resolved.
