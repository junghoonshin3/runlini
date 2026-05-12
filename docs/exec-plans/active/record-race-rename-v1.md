# 기록 레이스 리네이밍

## Purpose

`고스트런` 기능을 사용자에게 더 직관적인 `기록 레이스`로 바꾸고,
내부 코드명도 `record_race`로 정리한다.

## Context and orientation

- 사용자 표시명은 `기록 레이스`다.
- 내부 Dart/Kotlin 표준은 `RecordRace`, `recordRace`, `record_race`다.
- 기존 로컬 DB, 설정 키, Wear Data Layer 경로, 워치 캐시는 보존한다.
- 기존 사용자 수정인 `docs/exec-plans/active/interval-feature-lock-v1.md`는
  이번 변경 범위에서 제외한다.

## Progress

- [x] 계획과 컨텍스트 노트를 추가한다.
- [x] Dart 도메인, provider, UI, 테스트를 `record_race`로 바꾼다.
- [x] DB와 설정 키 레거시 호환을 추가한다.
- [x] Kotlin Wear/phone 경로와 테스트를 `record_race`로 바꾼다.
- [x] 사용자 문구와 살아 있는 제품 문서를 갱신한다.
- [x] Guardrails, analyzer, Flutter tests, Android/Wear unit tests를 실행한다.

## Decisions

- `ghost_summary_json`은 레거시 컬럼으로 남기고 새 컬럼
  `record_race_summary_json`을 추가한다.
- 새 JSON 필드는 `recordRaceSessionId`, `recordRaceLabel`이다.
- 기존 JSON 필드 `ghostSessionId`, `ghostLabel`은 읽기 fallback으로 유지한다.
- 새 Wear Data Layer 경로는 `/runlini/phone/record_race_config`와
  `/runlini/phone/record_race_configs`다.
- Wear 수신부는 기존 `/runlini/phone/ghost_config`와
  `/runlini/phone/ghost_configs`도 계속 읽는다.

## Implementation steps

1. 파일명과 import 경로를 `ghost_racer`에서 `record_race`로 바꾼다.
2. Dart 심볼과 문자열 키를 `RecordRace` 계열로 바꾸고 레거시 읽기를 남긴다.
3. Kotlin 심볼과 Data Layer 경로를 `RecordRace` 계열로 바꾸고 레거시 수신을 남긴다.
4. UI/음성/문서의 사용자 표현을 `기록 레이스`로 바꾼다.
5. 실패하는 테스트와 참조를 새 이름으로 갱신한다.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :app:testDebugUnitTest`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`

## Risks or recovery

- 전역 리네이밍이 넓으므로 검증 실패는 실제 오류 라인을 읽고 좁게 수정한다.
- 레거시 저장 키는 삭제하지 않고 fallback으로만 유지해 기존 기록 손실을 막는다.
