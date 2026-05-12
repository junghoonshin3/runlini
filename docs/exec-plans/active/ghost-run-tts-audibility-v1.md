# Ghost Run TTS Audibility V1

## Purpose

Make ghost-run voice cues slower and easier to understand on both phone and
Wear, especially gap announcements like ahead, behind, overtake, and finish.

## Context and Orientation

- Phone speech is produced by `FlutterTtsRunVoiceCueClient`.
- Phone cue text is coordinated by `RunVoiceCueCoordinator`.
- Wear speech is produced by `AndroidWearRunSpeech`.
- Wear cue text is coordinated by `WearRunAlertController`.
- Phone and Wear currently format similar ghost cues separately, so both sides
  must be updated together.

## Progress

- [x] Create the execution plan and update shared checklist notes.
- [x] Consolidate phone cue text onto the shared formatter.
- [x] Rewrite ghost gap cues as explicit Korean sentences.
- [x] Slow down phone and Wear speech rates.
- [x] Include ghost gap in kilometer summaries only when the start is confirmed.
- [x] Queue Wear TTS utterances instead of flushing same-tick cues.
- [x] Update Dart and Wear regression tests.
- [x] Run guardrails, analyze, Flutter tests, and Wear tests.
- [x] Gate kilometer ghost gap text behind ghost voice settings.
- [x] Suppress ghost event speech before start confirmation.
- [x] Emit only the highest-priority TTS cue in a single tick.
- [x] Re-run Dart and Wear regression checks.

## Decisions

- Keep the existing settings policy: `voiceCueEnabled` is the master switch,
  `kmVoiceCueEnabled` controls kilometer summaries, and `ghostVoiceCueEnabled`
  controls ghost-specific event speech.
- Phone speech rate becomes `0.42`.
- Wear speech rate becomes `0.85f`.
- Ghost gaps use complete sentences, for example:
  `고스트보다 30초 앞서고 있어요`.
- Completion uses result language, for example:
  `고스트보다 32초 빨랐어요`.
- Do not speak a ghost gap before the ghost start has been confirmed.
- `ghostVoiceCueEnabled` controls every ghost-related spoken phrase, including
  gap text attached to kilometer summaries.
- A ghost run may still speak the plain kilometer summary when `voiceCueEnabled`
  and `kmVoiceCueEnabled` are enabled while `ghostVoiceCueEnabled` is disabled.
- If multiple spoken cue candidates occur in one tick, speak only one cue by
  priority: completion, route off/back, lead change, final stretch, kilometer.
- Lower-priority cue candidates are not queued for later playback.

## Implementation Steps

1. Import the shared Dart formatter into `RunVoiceCueCoordinator` and remove the
   duplicated formatter code from that coordinator.
2. Add explicit ghost gap and completion sentence helpers to the Dart formatter.
3. Pass the active ghost frame into kilometer cue formatting only for confirmed,
   on-route ghost frames.
4. Mirror the same sentence policy in the Wear formatter.
5. Pass the Wear ghost frame into kilometer summary creation.
6. Lower speech rates and make Wear utterance queueing preserve sequential cues.
7. Update focused Dart and Wear tests for the new strings and unchanged gating.
8. Update phone coordinator selection so ghost event candidates outrank
   kilometer candidates and only one cue is returned.
9. Update Wear alert emission so each controller tick has a single speech
   budget while vibration behavior remains unchanged.

## Validation

- `dart format`
- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`

All validation commands passed on 2026-05-09.

Policy update validation passed on 2026-05-10:

- `dart format`
- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`

## Risks or Recovery

- If field testing says speech is too slow, adjust only the speech-rate
  constants.
- If Wear cues become too long, keep the complete sentence structure but trim
  event lead-in copy before changing event gating.
