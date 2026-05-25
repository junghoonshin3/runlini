# 고스트런 루프 코스 진행률/완료 판정 안정화

## Purpose

시작점과 종료점이 가까운 루프/왕복 고스트 코스에서 출발 직후 완료 지점으로 오판하거나, 진행률이 가까운 다른 구간으로 튀는 문제를 막는다.

## Context

- 폰 고스트 비교는 `GhostRaceGapService`가 계산한다.
- Wear 고스트 비교는 `WearGhostGapCalculator`가 계산한다.
- 완료 판정은 현재의 보수적인 90% 거리, 98% 진행률, 2회 연속 후보 정책을 유지한다.
- 고스트런과 인터벌은 V1에서 동시에 active가 아니다.

## Progress

- [x] 폰 고스트 route projection을 이전 진행률 기반 추적으로 변경한다.
- [x] 폰 playback state에 출발 확인과 tracked distance를 저장한다.
- [x] 출발 확인 전 완료 판정과 고스트 이벤트를 보류한다.
- [x] 폰 라이브 대시보드에 `출발 확인 중` 상태를 표시한다.
- [x] Wear 고스트 route projection과 state를 같은 정책으로 변경한다.
- [x] Wear 고스트 페이지에 출발 확인 상태를 표시한다.
- [x] 루프 코스와 완료 판정 회귀 테스트를 추가한다.
- [x] guardrails, analyze, Flutter tests, Wear tests를 실행한다.
- [x] 폰 `ghostRaceFrameProvider`가 playback state를 다시 갱신하는 provider 루프를 제거한다.
- [x] `startConfirmed`를 완료 안전장치로만 쓰고, 출발 확인 전에도 고스트 비교값을 표시한다.
- [x] `RunningTabScreen.build()`의 고스트 completion listener를 `listenManual` one-shot listener로 옮겨 provider 재빌드 루프를 차단한다.

## Decisions

- 루프 코스는 V1에서 정상 지원한다.
- 출발 확인은 러닝 중 시작점 45m 이내 anchor를 찾고, 경로 초반 250m 방향으로 accepted point 2개가 연속 진행될 때 완료한다.
- 시작점 anchor를 못 찾더라도 accepted distance가 80m 이상이고, 현재 projection이 경로 위이며 초반 40m~400m 구간이면 출발 확인을 완료한다.
- 진행률 탐색은 이전 distance-along-route 기준 뒤 50m, 앞 250m를 우선한다.
- 탐색 범위에서 on-route projection을 찾지 못하면 전체 경로 projection을 참고하되, tracked progress를 급격히 튀게 하지 않는다.
- 출발 확인 전에도 앞섬/뒤처짐, 시간 차이, 거리 차이, 진행률은 표시한다.
- 출발 확인 전에는 `출발 확인 중`을 작은 badge로만 표시하고, 완료 prompt/TTS만 잠근다.
- 출발 확인 전에도 1km 요약과 고스트 상태 TTS는 설정이 켜져 있으면 허용한다.
- 폰 출발 확인과 route projection은 playback 저장 필드가 아니라 recorded points와 accepted distance에서 파생한다.
- `ghostRaceFrameProvider`는 고스트 frame을 계산만 하고 playback에 tracking 값을 되쓰지 않는다.
- 고스트 완료 candidate count는 playback state에 매 frame 저장하지 않고, 화면 state 내부에서만 추적한다.
- 고스트 완료 prompt/summary는 완료 확정 시점에만 post-frame으로 한 번 기록한다.

## Implementation Steps

1. 공통 route projection 모델을 Dart에서 분리해 global/tracked/held projection을 계산한다.
2. `GhostRaceGapService`에 start decision과 previous-distance 기반 calculate API를 추가한다.
3. recorded points와 accepted distance를 기준으로 출발 확인 상태와 tracked distance를 파생한다.
4. completion detector와 live dashboard를 출발 확인 상태에 맞게 수정한다.
5. Wear calculator/state/reducer/store/UI에 같은 필드를 추가한다.
6. Dart, Flutter, Wear 테스트를 추가한다.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`

## Validation Result

- `dart run tool/guardrails.dart` 통과.
- `flutter analyze` 통과.
- `flutter test` 통과.
- `./gradlew :wear:testDebugUnitTest` 통과.
- `./gradlew :wear:assembleDebug` 통과.
- Provider 루프 수정 후 `dart run tool/guardrails.dart`, `flutter analyze`, `flutter test`, `./gradlew :wear:testDebugUnitTest` 재검증 통과.

## Risks Or Recovery

- 필드 테스트에서 출발 확인이 너무 늦으면 연속 point 수보다 초반 방향 거리 기준을 먼저 조정한다.
- 루프에서 진행률이 여전히 튀면 projection window를 좁히기 전에 debug 로그로 held/global source 빈도를 확인한다.
