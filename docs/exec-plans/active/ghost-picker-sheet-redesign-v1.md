# 고스트 기록 선택 바텀시트 개편

## Purpose

고스트 기록 선택 바텀시트를 빠른 재선택 중심으로 개편한다.

## Context and Orientation

현재 바텀시트는 전체 높이 시트 안에 기록 요약 타일을 그대로 나열하고, 타일을
누르면 즉시 선택한다. 새 흐름은 최신 기록을 기본 확장하고, 다른 기록은 탭해서
코스를 확인한 뒤 명시적 버튼으로 선택한다.

## Progress

- [x] 최신 기록 기본 확장 상태를 추가한다.
- [x] 접힌 compact 기록 카드와 확장 카드 선택 버튼을 만든다.
- [x] 지도 타일 없는 route shape preview를 추가한다.
- [x] 기존 선택, empty, drag close/snap 테스트를 갱신한다.
- [x] guardrails, analyze, Flutter tests를 실행한다.

## Validation Result

- `flutter test test/features/ghost_racer/ghost_session_picker_sheet_test.dart test/features/ghost_racer/ghost_settings_flow_test.dart test/features/run_tracking/ghost_interval_conflict_test.dart` 통과.
- `dart run tool/guardrails.dart` 통과.
- `flutter analyze` 통과.
- `flutter test` 통과.

## Decisions

- 1차 목표는 빠른 재선택이다.
- 최신 기록을 기본 확장한다.
- 실제 지도 대신 route shape만 보여준다.
- 카드 탭은 확장, 확정 버튼은 선택으로 역할을 분리한다.
- 날짜 선택, 검색, 필터, 즐겨찾기, 선택 이력 저장은 이번 범위에서 제외한다.

## Implementation Steps

1. `GhostSessionPickerSheet`를 stateful UI로 바꾸고 확장된 summary id를 관리한다.
2. 확장된 기록만 `runSessionByIdProvider`로 상세 포인트를 읽는다.
3. route shape preview custom painter를 별도 파일로 추가한다.
4. 기존 flow 테스트를 새 상호작용에 맞게 수정하고 route fallback 테스트를 추가한다.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks and Recovery

- route preview가 작은 화면에서 세로 공간을 많이 쓰면 높이를 줄이고 목록 spacing을
  먼저 조정한다.
- 세션 상세 로드가 느리면 확장 카드만 skeleton을 보여주고 목록 스크롤은 막지 않는다.
