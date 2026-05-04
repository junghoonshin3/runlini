# Run Finish Review Flow

## Purpose

Change `STOP` from an immediate save/export action into a review step where the
runner explicitly saves or discards the finished run.

## Context and Orientation

- Playback state lives in `lib/features/run_tracking/state/`.
- Running tab controls live in `lib/features/run_tracking/ui/`.
- Health export starts on `START`, then finishes only after the runner chooses
  `저장하기`.

## Progress

- [x] Add a `reviewing` playback status and pending finished-session draft
- [x] Change `STOP` to stop capture and open the finish review state
- [x] Add explicit save and discard controller methods
- [x] Add a dark finish review overlay with save/discard actions
- [x] Expand the finish review into a Nike-style detail page with summary,
  route preview, charts, and splits
- [x] Confirm discard with a dialog before dropping the draft
- [x] Add provider and widget coverage for save/discard behavior
- [x] Update product and health export docs
- [x] Refresh the review UI into Runlini data-lab panels and line charts

## Decisions

- `STOP` stops workout tracking immediately, but does not save locally or finish
  health export.
- `저장하기` saves through `RunSessionRepository` and then best-effort finishes
  HealthKit / Health Connect export.
- `기록 버리기` never saves locally and cancels health route capture.
- The v1 review screen does not include title, memo, photos, or visibility.
- Speed and elevation charts use captured GPS data when present. Heart-rate UI
  is shown as an empty state until watch/health samples are stored.
- The route preview is an in-app dark route drawing, not a native map snapshot.
- The review screen can persist and display a final ghost comparison summary
  without creating a separate run type.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- The current fixture repository only persists saved runs for the app process.
  Durable storage remains a separate persistence task.
- Health export remains best effort; a health failure must not block local save.
