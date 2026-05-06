# Ghost Run Finish Conditions V1

## Purpose

Detect when a runner reaches the end of the selected ghost route without
auto-saving the run. Show a completion choice so the runner can stop for review
or keep recording a cooldown.

## Context and Orientation

- Phone ghost feedback is calculated by `GhostRaceGapService`.
- Wear ghost feedback is calculated by `WearGhostGapCalculator`.
- Existing stop/review flows remain the source of truth for saving.
- Ghost-run TTS remains disabled; completion may use haptics only.

## Progress

- [x] Add route progress fields to phone and Wear ghost frames.
- [x] Add conservative completion detectors.
- [x] Add phone completion prompt and continue/stop actions.
- [x] Add Wear completion prompt and continue/stop actions.
- [x] Preserve the completion ghost result when continuing.
- [x] Add phone and Wear tests.
- [x] Run guardrails, analyze, Flutter tests, and Wear tests.

## Decisions

- Completion does not auto-save or auto-stop.
- Completion requires two consecutive candidate frames.
- Completion is blocked while off route.
- Loop routes require accepted runner distance of at least 90% of ghost distance.
- Continuing suppresses the completion prompt for the rest of that active run.

## Implementation Steps

1. Extend ghost frame models with route progress metadata.
2. Add completion detector services using the planned thresholds.
3. Track completion state in phone playback state and Wear run state.
4. Render the phone dialog and Wear completion screen.
5. Route stop actions through the existing review flow.
6. Update docs and tests.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`

## Risks or Recovery

- If completion over-fires on loops, raise the accepted-distance gate.
- If completion is missed near finish, tune only the final-point radius while
  keeping the two-frame confirmation.
