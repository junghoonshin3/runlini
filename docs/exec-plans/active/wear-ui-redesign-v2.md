# Wear OS UI Redesign V2

## Purpose

Redesign the native Wear OS app around small round screens so active runs are
glanceable and controls remain safe. The first running page prioritizes
distance, elapsed time, and current pace with explicit Korean labels.

## Context And Orientation

- The Wear app already has separate ready, active pager, paused, review,
  metric component, and formatter files.
- Android Wear guidance recommends designing for 192dp first, accounting for
  round screen margins, and keeping key workout pages glanceable.
- Recording, Health Services, ghost calculation, draft sync, phone ack, and
  Data Layer payloads stay unchanged.
- Cadence uses Health Services `STEPS_PER_MINUTE` when supported, then stores
  session-level average cadence in the existing watch draft contract.
- The Wear app must recover an active run when the Activity is recreated or the
  user reopens the app after sending it to the background.
- Wear draft import preserves UTC instants, while History UI must group and
  filter those sessions by local calendar date.
- This is native platform UI work, so it runs on `feature/wear-ui-redesign-v2`.

## Progress

- [x] Create the short-lived feature branch.
- [x] Add a round-safe page frame and compact metric primitives.
- [x] Change ready model labels to short Korean copy.
- [x] Redesign the active running pager.
- [x] Redesign ready, paused, and finish review screens.
- [x] Update model tests.
- [x] Run full validation commands.
- [x] Add explicit pace/heart-rate labels and cadence display/storage.
- [x] Re-run validation after cadence changes.
- [x] Move active recording ownership from Activity memory to a Wear recording
  service.
- [x] Add active-run checkpoint storage for running, paused, and review states.
- [x] Restore owned Health Services running sessions on app reentry.
- [x] Fix History local-date filtering for imported Wear UTC timestamps.

## Decisions

- The active core page uses distance as the hero metric.
- Pause and stop stay off the first running page and live on the controls page.
- Labels use short Korean copy rather than English abbreviations.
- Pace labels should say `현재 페이스` and `평균 페이스`; heart rate should say
  `심박수`.
- Average pace belongs on the details page, not the core page.
- Cadence belongs on the details page and review summary when available.
- Review must keep `저장` and `삭제` visible without requiring a scroll.
- Activity disposal must not clear the Health Services exercise callback while
  a run is active.
- Checkpoint fallback converts stale active records into Review when Health
  Services no longer owns the exercise.
- History date filters and summaries use `startedAt.toLocal()`; import/storage
  keep the original instant unchanged.

## Implementation Steps

1. Replace stacked scroll-first Wear layouts with a shared round-safe frame.
2. Convert active pages to non-scrolling metric/control surfaces.
3. Move Ready secondary state, pending sync, and retry into compact footer areas.
4. Compress Paused and Review into first-viewport action-oriented layouts.
5. Add cadence to Wear state, Health Services metrics, review summary, and
   draft JSON through `averageCadenceSpm`.
6. Move controller ownership into `WearRunRecordingService` so the Activity can
   bind/unbind without resetting the run.
7. Persist active checkpoints and recover them through Health Services
   `getCurrentExerciseInfo()`.
8. Convert History tab, calendar summary, and distance-period filtering to local
   date semantics for UTC Wear imports.
9. Keep sync and ghost contracts otherwise untouched.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`
- `./gradlew :app:assembleDebug :wear:assembleDebug`
- cadence rerun:
  - `./gradlew :wear:testDebugUnitTest :wear:assembleDebug`
  - `dart run tool/guardrails.dart`
  - `flutter analyze`
  - `flutter test`
  - `./gradlew :app:assembleDebug :wear:assembleDebug`
- reentry recovery rerun:
  - `./gradlew :wear:testDebugUnitTest`
  - `./gradlew :wear:assembleDebug`
  - `dart run tool/guardrails.dart`
  - `flutter analyze`
  - `flutter test`
  - `./gradlew :app:assembleDebug :wear:assembleDebug`
- Wear local-date display rerun:
  - `dart run tool/guardrails.dart`
  - `flutter analyze`
  - `flutter test`

Completed so far:

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`
- `./gradlew :app:assembleDebug :wear:assembleDebug`
- reentry recovery rerun completed with the same commands.
- Wear local-date display rerun completed with `dart run tool/guardrails.dart`,
  `flutter analyze`, and `flutter test`.

## Risks Or Recovery

- If 192dp still feels cramped, reduce copy and border density before changing
  the page model.
- If Wear emulator validation exposes clipping, keep the underlying state logic
  and tune only layout specs, font sizes, and button sizing.
- If Health Services no longer owns an exercise after process death, preserve
  the locally checkpointed run in Review rather than dropping it.
