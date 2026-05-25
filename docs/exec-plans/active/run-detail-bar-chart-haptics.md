# 기록 상세 차트 막대그래프 전환 + 햅틱

## Purpose

기록 상세 화면의 metric 차트를 막대그래프로 바꾸고, 차트 값을 터치해 확인할 때 선택 햅틱을 제공한다.

## Context and Orientation

- 기존 상세 차트는 `RunDetailLineChart`가 `Pace`, `Speed`, `Elevation`, `Heart Rate`, `Cadence`에 공통 사용된다.
- 차트 summary와 empty/hidden 상태는 유지한다.
- `fl_chart`의 `BarChart`를 사용하고, raw sample summary는 기존 계산 방식을 유지한다.

## Progress

- [x] 현재 차트 위젯과 테스트 참조 확인.
- [x] `RunDetailBarChart` 추가.
- [x] 상세 차트 섹션을 막대그래프로 교체.
- [x] LineChart 테스트를 BarChart와 햅틱 기준으로 갱신.
- [x] `dart format` 실행.
- [x] `dart run tool/guardrails.dart` 실행.
- [x] `flutter analyze` 실행.
- [x] `flutter test` 실행.

## Decisions

- 표시용 bar는 최대 48개 bucket으로 집계한다.
- bucket 값은 포함 sample 평균값으로 만든다.
- summary의 Avg/min/max는 기존처럼 raw valid sample 기준을 유지한다.
- Pace chart의 session average 기준선과 `낮을수록 빠른 페이스` 문구는 유지한다.
- 햅틱은 bar index가 바뀔 때만 `selectionClick()`으로 발생시킨다.
- 실제 기기에서 `selectionClick()` 체감이 약하고, `fl_chart` touch callback은 얇은 bar를 맞춘 경우에만 안정적으로 호출된다.
- 차트 전체 영역의 pointer drag를 직접 듣고 bucket index를 계산해 햅틱을 발생시킨다.
- 체감 가능한 진동을 위해 차트 선택 햅틱은 `lightImpact()`를 사용한다.
- 단순 탭/터치다운은 햅틱을 발생시키지 않고, 8px 이상 드래그한 뒤 bucket이 바뀔 때만 발생시킨다.

## Context Notes

- 기존 `LineChart` ring dot/guide line 테스트는 막대 차트에서는 의미가 없어 제거하고, 평균선/tooltip/haptic 설정 검증으로 대체한다.
- 햅틱 실패는 UI를 깨지 않도록 platform call 실패를 삼키는 안전 경로로 처리한다.
- `RunDetailChartHeader`와 empty chart frame은 별도 파일로 분리해 차트 위젯 파일이 300줄 guardrail을 넘지 않게 했다.
- 사용자 확인 결과 드래그 중 햅틱이 체감되지 않아, bar hit-test 의존을 제거하고 chart surface pointer tracking을 추가했다.
- 사용자 확인 결과 터치다운에도 진동이 과하게 와서, pointer down은 시작 위치만 저장하고 pointer move에서 drag threshold를 넘은 경우에만 햅틱을 허용하도록 조정했다.

## Implementation Steps

1. `RunDetailBarChart`를 추가하고 기존 line chart와 동일한 public 입력을 유지한다.
2. `RunDetailChartsSection`에서 모든 metric chart를 새 widget으로 교체한다.
3. 기존 LineChart 기대 테스트를 BarChart 기대값으로 바꾼다.
4. touch callback 단위 테스트로 같은 bar 중복 햅틱 방지와 다른 bar 이동 햅틱을 검증한다.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- `fl_chart` touch event를 widget gesture로 직접 재현하기 어렵다면 `BarTouchData.touchCallback`을 직접 호출해 햅틱 gating을 검증한다.
- bar가 너무 촘촘하면 bucket 수나 bar width만 조정하고 summary 계산은 변경하지 않는다.
