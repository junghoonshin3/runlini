# START 위 경쟁레이스 선택 UI 개편 계획

## 목표

- START 버튼 위 위치는 유지한다.
- 현재 `기록 레이스 OFF/ON` 토글 칩은 폐기한다.
- 새 UI는 선택 전 `경쟁레이스 선택`, 선택 후 선택 기록 요약을 보여주는 compact mode selector로 만든다.
- 선택된 상태의 주 탭은 즉시 해제가 아니라 기록 변경 시트를 연다.
- 해제는 별도 버튼으로 분리한다.

## 구현 범위

- `RunRecordRaceControlChip`의 내부 UI와 탭 동작을 개편한다.
- 기존 `openRecordRacePicker`와 `recordRaceSettingsProvider` 흐름은 유지한다.
- 기록이 없는 사용자에게는 하단 selector를 숨긴다.
- 기존 테스트의 OFF/ON 기대값을 새 selector 동작으로 갱신한다.

## 검증

- 관련 기록 레이스 위젯 테스트를 실행한다.
- 러닝 컨트롤과 카운트다운 회귀 테스트를 실행한다.
- `flutter analyze`를 실행한다.
