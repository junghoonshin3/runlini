# 고스트 코스 시작/종료 깃발 V1

## Purpose

고스트런 지도에서 선택된 고스트 코스의 시작점과 종료점을 바로 구분할 수 있게 한다.

## Context and Orientation

- 폰 지도는 `RunMapViewState`가 route data를 준비하고 `core/map`의 fake, Google, Apple map view가 렌더링한다.
- 고스트 route polyline은 선택된 `RunSession` points에서 파생된다.
- Wear 화면에는 지도 표면이 없으므로 이번 범위에서 제외한다.
- 시작점과 종료점이 10m 이내면 루프 코스로 보고 하나의 복합 마커를 보여준다.

## Progress

- [x] 요구사항 기준을 10m 이내 복합 마커로 정한다.
- [x] route endpoint marker 모델과 10m 병합 규칙을 추가한다.
- [x] fake, Google, Apple 지도 표면에 endpoint marker를 렌더링한다.
- [x] 관련 테스트와 제품 문서를 갱신한다.
- [x] guardrails, analyze, Flutter tests를 실행한다.
- [x] 첨부된 깃발 스타일을 `flag_start`, `flag_finish`, `flag_sf` asset으로 대체한다.

## Decisions

- 출발지와 도착지가 10m 초과로 떨어져 있으면 시작 깃발과 종료 깃발을 각각 실제 좌표에 표시한다.
- 출발지와 도착지가 10m 이내면 실제 좌표를 임의로 벌리지 않고 시작점 좌표에 `출발·도착` 복합 마커 하나를 표시한다.
- 현재 고스트 위치 marker 설정과 별개로, 선택된 고스트 코스가 보이면 endpoint marker도 함께 보인다.
- endpoint marker asset 파일명은 `flag_start.png`, `flag_finish.png`, `flag_sf.png`로 유지한다.

## Implementation Steps

1. `core/map`에 route endpoint marker 타입과 builder를 추가한다.
2. `RunMapStaticState`와 `RunMapViewState`에 endpoint marker 목록을 전달한다.
3. `RunMapPanel`이 fake, Google, Apple 지도에 marker 목록을 넘긴다.
4. 각 지도 표면에서 시작, 종료, 복합 marker icon을 렌더링한다.
5. 10m 기준 unit test와 fake surface widget test를 추가한다.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Validation Result

- 관련 `flutter test test/core/map/map_route_endpoint_marker_test.dart test/core/map/fake_run_map_surface_test.dart test/features/run_tracking/run_map_view_state_test.dart` 통과.
- `dart run tool/guardrails.dart` 통과.
- `flutter analyze` 통과.
- 전체 `flutter test` 통과.

## Risks or Recovery

- native map icon 크기가 실제 기기에서 과하면 logical size만 줄이고 marker 좌표 정책은 유지한다.
- endpoint marker가 현재 고스트 marker와 겹쳐 보이면 z-index만 조정하고 route data 정책은 바꾸지 않는다.
