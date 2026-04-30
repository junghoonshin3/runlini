# Wear OS Voice Cues V1

## Purpose

워치 단독 러닝에서 워치가 직접 짧은 TTS 안내를 제공한다.

## Progress

- [x] 워치 설정에 `음성 안내`, `고스트 음성` 추가
- [x] Android Wear `TextToSpeech` 래퍼 추가
- [x] 1km 브리핑 음성 추가
- [x] 고스트 상태 변화 음성 추가
- [x] 30초 debounce와 중복 방지 추가
- [x] 테스트 추가

## Decisions

- 워치에서 시작한 러닝의 음성은 워치에서 나온다.
- `음성 안내`는 기본 ON이며 1km마다 짧게 안내한다.
- `고스트 음성`은 기본 OFF이며 고스트 러닝에서 상태 변화 때만 안내한다.
- 기존 `1km 알림`은 진동 알림 의미로 유지한다.
- 폰 스피커/이어폰으로 음성을 보내는 구조와 코칭 멘트는 후속 작업으로 둔다.

## Validation

- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`
- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
