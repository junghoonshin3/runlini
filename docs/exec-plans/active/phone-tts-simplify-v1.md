# Phone TTS Simplify V1

## Purpose

Keep phone TTS behavior but remove the test-only wrapper and platform
abstraction that make the call path harder to understand.

## Context and Orientation

- Phone speech is emitted through `FlutterTtsRunVoiceCueClient`.
- `RunVoiceCueClient` is the app-level boundary used by providers and tests.
- `RunVoiceCueTts` mirrors `FlutterTts` without adding product semantics.
- The app targets Android and iOS; macOS only appears as the local test
  environment.

## Progress

- [x] Create this execution plan and update shared notes.
- [x] Remove `RunVoiceCueTts` and platform abstraction.
- [x] Make `FlutterTtsRunVoiceCueClient` call `FlutterTts` directly.
- [x] Add simple Android engine and Korean voice selection helpers.
- [x] Replace wrapper fake tests with helper tests.
- [x] Add temporary phone voice test button.
- [x] Run validation after the temporary button.
- [x] Remove Android TTS engine selection.
- [x] Run validation after engine selection removal.
- [x] Compare current behavior with `flutter_tts` README and device logs.
- [x] Remove forced Korean voice selection and the hard speak gate.
- [x] Request Android audio focus on speak and set navigation audio attributes.
- [x] Restore Android TTS service package-visibility query.
- [x] Run focused validation for the simplified TTS path.

## Decisions

- Keep `RunVoiceCueClient`.
- Remove `RunVoiceCueTts`, `FlutterRunVoiceCueTts`, `RunVoiceCuePlatform`, and
  `DeviceRunVoiceCuePlatform`.
- Android uses the system default TTS engine instead of calling `setEngine`.
- Do not add platform injection just to make macOS-hosted tests exercise Android
  branches.
- Unit tests cover pure selection helpers; device behavior still needs Android
  field testing.
- Device logs show Samsung TTS synthesis completes, so the next fix targets audio
  focus and output routing instead of engine selection.
- `getVoices` and `setVoice` are optional `flutter_tts` APIs and should not gate
  phone speech.
- Android should use `speak(text, focus: true)` and
  `setAudioAttributesForNavigation()` for runner voice prompts.

## Implementation Steps

1. Move TTS platform checks back to direct Android/iOS checks in the client.
2. Select Korean voices from exposed voice metadata.
3. Delete the wrapper file and rewrite focused tests.
4. Add a temporary settings button that speaks a number-free Korean phrase.
5. Remove Android engine query and `setEngine` calls.
6. Remove forced voice metadata selection.
7. Restore the manifest `TTS_SERVICE` query.
8. Add Android audio focus and navigation audio attributes.

## Validation

- `dart format`
- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test test/core/voice/run_voice_cue_client_test.dart`
- `flutter test test/features/settings/settings_voice_test_button_test.dart`
- `flutter test`
- `./gradlew :app:assembleDebug`
- `adb -s 5200024fee2b2571 install -r build/app/outputs/flutter-apk/app-debug.apk`

All validation commands passed on 2026-05-10. The debug APK was installed on
the connected phone.

The audio-focus follow-up validation also passed on 2026-05-10:
`dart format`, `flutter test test/features/settings/settings_voice_test_button_test.dart`,
`dart run tool/guardrails.dart`, `flutter analyze`, `flutter test`, and
`./gradlew :app:assembleDebug`. The updated debug APK was installed on the
connected phone with `adb install -r`.

## Risks or Recovery

- If field testing shows Samsung exists but speaks Korean poorly, adjust the
  engine policy separately instead of reintroducing wrappers.
- If helper-only tests are too weak later, mock the real `flutter_tts`
  MethodChannel without adding a product wrapper.
