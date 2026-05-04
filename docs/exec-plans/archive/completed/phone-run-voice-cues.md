# Phone Run Voice Cues

## Purpose

Add phone-side TTS for runs started in the phone app, using the same cue scope
as Wear: kilometer summaries, interval step changes, and ghost status changes.

## Progress

- [x] Add phone TTS client and settings fields.
- [x] Add run voice cue coordinator and phone UI listener.
- [x] Sync shared voice settings to Wear.
- [x] Add focused tests and run validation.
- [x] Move this plan to `archive/completed/`.

## Decisions

- Phone-started runs speak on the phone.
- Wear-started runs keep speaking on Wear.
- Voice settings are shared between phone and Wear for V1.
- Ghost voice remains default OFF.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :app:testDebugUnitTest`
- `./gradlew :wear:testDebugUnitTest`
