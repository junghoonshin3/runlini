# Wear OS Ready Settings V1

## Purpose

Ready 화면에서 왼쪽 스와이프로 들어가는 작은 워치 설정 화면을 추가한다.

## Progress

- [x] Ready 전용 `Ready → Settings` pager 추가
- [x] 워치 로컬 설정 저장소 추가
- [x] `카운트다운`, `진동`, `1km 알림`, `음성 안내`, `고스트 음성` 토글 추가
- [x] 카운트다운 off 시 즉시 러닝 시작
- [x] 1km 알림 진동 중복 방지
- [x] 테스트 추가

## Decisions

- 앱 진입 첫 화면은 항상 Ready다.
- 설정은 Ready 상태에서만 접근한다.
- 설정은 워치 로컬에만 저장한다.
- V1 항목은 `카운트다운`, `진동`, `1km 알림`, `음성 안내`, `고스트 음성`만 둔다.
- `음성 안내`는 기본 ON, `고스트 음성`은 기본 OFF다.
- 러닝 중 설정, 기록 목록, 동기화, Health 설정은 워치 설정에 넣지 않는다.

## Validation

- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`
- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
