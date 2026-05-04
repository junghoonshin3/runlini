# Wear OS Voice Cues V1

## Purpose

워치 단독 러닝에서 워치가 직접 짧은 TTS 안내를 제공한다.

## Progress

- [x] 워치 설정에 `음성 안내`, `고스트 음성` 추가
- [x] Android Wear `TextToSpeech` 래퍼 추가
- [x] 1km 브리핑 음성 추가: 거리, 평균 페이스, 경과 시간
- [x] 폰/워치 음성 음량 설정 추가
- [x] 음량 변경 시 워치에서 테스트 음성 재생
- [x] 워치 음량 100% 표시에서도 `- / +` 버튼 위치 고정
- [x] 고스트 상태 변화 음성 추가
- [x] 30초 debounce와 중복 방지 추가
- [x] 테스트 추가

## Decisions

- 워치에서 시작한 러닝의 음성은 워치에서 나온다.
- `음성 안내`는 전체 TTS 마스터이며 기본 ON이다.
- `1km 알림`은 1km 진동과 1km 음성 브리핑을 함께 제어하며, 음성은 평균 페이스와 경과 시간을 포함한다.
- 음성 음량은 폰 Settings > 러닝에서 조절해 워치로 전송하고, 워치 설정에서도 `- / +`로 로컬 조정할 수 있다.
- 음량 변경이 사용자 조작으로 발생하면 워치는 `음량 테스트`를 현재 음량으로 한 번 재생한다.
- `고스트 음성`은 기본 OFF이며 고스트 러닝에서 상태 변화 때만 안내한다.
- 인터벌 단계 전환 음성은 `음성 안내`가 켜져 있고 인터벌이 ON일 때만 나온다.
- 폰 스피커/이어폰으로 음성을 보내는 구조와 코칭 멘트는 후속 작업으로 둔다.

## Validation

- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`
- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
