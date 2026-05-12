# Phone TTS Korean Voice V1

## Purpose

Make phone-side voice cues speak Korean text reliably instead of only reading
numbers when the default Android TTS engine does not select a Korean voice.

## Context and Orientation

- Phone voice cues are emitted by `FlutterTtsRunVoiceCueClient`.
- The connected Android phone uses Samsung TTS as the default engine, while
  Google TTS is also installed.
- The current client calls `setLanguage('ko-KR')` but does not verify whether
  the language or voice was actually selected.

## Progress

- [x] Create the execution plan and update shared notes.
- [x] Add a testable TTS adapter boundary.
- [x] Verify and select a Korean voice before speaking.
- [x] Fall back to Google TTS on Android when the default engine cannot speak Korean.
- [x] Skip speaking when no Korean voice is available.
- [x] Add Android manifest TTS queries.
- [x] Add focused regression tests.
- [x] Run guardrails, analyze, and Flutter tests.

## Decisions

- The app does not change the system default TTS engine.
- Android fallback engine is `com.google.android.tts`.
- Korean voice matching accepts `ko-KR` first, then any `ko-*` voice.
- If Korean voice setup fails, the cue is skipped rather than allowing a
  number-only utterance.

## Implementation Steps

1. Introduce a small wrapper around `FlutterTts` so configuration can be tested.
2. Check `isLanguageAvailable('ko-KR')` and the result of `setLanguage`.
3. Select a Korean voice from `getVoices` when one is exposed by the engine.
4. On Android, switch to Google TTS and retry Korean setup when the default
   engine fails.
5. Add package and TTS service visibility queries to the Android manifest.
6. Add unit tests for success, fallback, and skip behavior.

## Validation

- `dart format`
- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

All validation commands passed on 2026-05-09.

## Risks or Recovery

- If a device lacks Google TTS, the app will skip voice cues and log the reason.
- If Samsung TTS reports Korean support but still speaks poorly, Google fallback
  may need to be preferred when Samsung is the active engine.
