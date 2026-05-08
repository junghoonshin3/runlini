# Ghost Run Live Experience V1

## Purpose

Make active ghost runs answer the race question immediately: am I beating my
ghost right now?

## Context and Orientation

- Phone ghost feedback comes from `GhostRaceGapService`.
- Wear ghost feedback comes from `WearGhostGapCalculator`.
- Ghost runs and interval runs remain mutually exclusive.
- Conservative ghost completion thresholds remain unchanged.
- Phone and Wear share the same product policy, with Dart and Kotlin
  implementations.

## Progress

- [x] Add phone ghost race event engine.
- [x] Add Wear ghost race event engine.
- [x] Re-enable ghost-run kilometer summary voice where settings allow it.
- [x] Add event-based ghost voice cues.
- [x] Improve phone live dashboard collapsed and expanded ghost states.
- [x] Improve phone map relationship display between runner and ghost.
- [x] Add Wear race-style ghost page details.
- [x] Add debug/profile diagnostics for missed ghost completion.
- [x] Add Dart, Flutter, and Wear tests.
- [x] Run guardrails, analyze, Flutter tests, and Wear tests.

## Decisions

- The live ghost-run role is judge plus race drama, not full coaching.
- The screen always shows current status, while voice and haptics only fire for
  meaningful events.
- Off-route and return events require about 10 seconds stable.
- Ahead and behind transitions require about 15 seconds stable.
- Event names are `kmSummary`, `offRoute`, `backOnRoute`, `overtake`,
  `lostLead`, `last500m`, `last200m`, and `completed`.
- `voiceCueEnabled` is the master switch.
- `kmVoiceCueEnabled` allows kilometer summaries during ghost runs.
- `ghostVoiceCueEnabled` is required for ghost-specific event speech.
- Level or tie state is not spoken.
- Wear uses haptics for ghost events. Phone haptics stay minimal.

## Checklist

- [x] Create Dart event model and stability engine.
- [x] Wire Dart events into `RunVoiceCueCoordinator`.
- [x] Update phone dashboard ghost collapsed and expanded UI.
- [x] Show active ghost marker during an active phone ghost run.
- [x] Create Kotlin event model and stability engine.
- [x] Wire Wear events into speech and haptics.
- [x] Update Wear ghost page progress and final-stretch labels.
- [x] Add completion blocker diagnostics.
- [x] Update policy docs that previously said ghost-run TTS is silent.

## Context Notes

- The previous ghost-run TTS reset plan is superseded by this event-gated
  policy. Interval speech remains disabled during ghost runs because interval
  frames are already suppressed for ghost runs.
- Completion thresholds stay conservative. This work improves feedback and
  diagnostics without loosening finish detection.
- Active phone ghost runs now show the current ghost marker even when the
  optional pre-run ghost marker setting is off. The setting still controls
  non-active preview behavior.

## Implementation Steps

1. Add a Dart ghost race event engine that consumes the current frame, runner
   distance, active status, and time.
2. Use the engine in phone voice cues to allow kilometer summaries and
   optional ghost-specific events.
3. Make collapsed phone dashboard ghost runs show race judgment first.
4. Make expanded phone dashboard show gap, progress, and remaining distance.
5. Add a Kotlin Wear engine with matching event names and thresholds.
6. Route Wear events to speech and haptics through existing settings.
7. Add compact progress/final-stretch details to the Wear ghost page.
8. Log completion blocker fields in debug/profile builds.
9. Update docs and tests.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`

## Risks or Recovery

- If ghost event speech is too noisy, keep event generation but tighten speech
  behind `ghostVoiceCueEnabled`.
- If overtake or lost-lead flickers in field tests, increase stability from
  15 seconds to 20 seconds before changing UI.
- If completion remains misunderstood, improve diagnostics and copy before
  changing thresholds.
