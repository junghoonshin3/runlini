# 앱 초기 실행 속도 개선

## Purpose

앱 첫 실행 때 기록/러닝/설정 탭과 Health/Wear 동기화가 한꺼번에 시작되어
첫 화면 표시가 느려지는 문제를 줄인다.

## Context

- `RunliniHomeScreen`은 `IndexedStack`으로 세 탭을 모두 mount한다.
- 기록 목록은 `runSessionListProvider`를 통해 모든 route point까지 읽는다.
- startup sync는 첫 frame 직후 Health, Wear draft, ghost config, interval/voice sync를
  거의 동시에 시작한다.

## Progress

- [x] 홈 탭 lazy mount 적용
- [x] 기록 탭 summary-first query 적용
- [x] startup sync idle delay + sequential execution 적용
- [x] startup weight prompt가 settings load 중 shell을 막지 않게 조정
- [x] 테스트/검증 완료

## Decisions

- 첫 화면 즉시 표시를 데이터 최신성보다 우선한다.
- Health/Wear 자동 동기화는 유지하되 앱 shell 표시 이후 백그라운드 순차 작업으로 둔다.
- 기록 상세, 고스트 실행처럼 route point가 필요한 순간에만 full session을 읽는다.

## Implementation Steps

1. `RunSessionRepository`에 lightweight summary query를 추가한다.
2. 기록 탭과 러닝화 요약은 summary provider를 사용한다.
3. 홈 화면은 방문한 탭만 mount하는 lazy stack을 사용한다.
4. startup sync는 짧은 delay 후 Health → Wear draft → ghost → interval/voice 순서로 실행한다.
5. startup 관련 widget/provider/repository tests를 보강한다.

## Validation

- `dart run tool/guardrails.dart` 통과
- `flutter analyze` 통과
- `flutter test` 통과

## Risks / Recovery

- 기존 tests가 `runSessionListProvider` override에 의존하므로 summary provider override로 갱신한다.
- Health/Wear 수동 동기화는 즉시 실행 경로를 유지한다.
