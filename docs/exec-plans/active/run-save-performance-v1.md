# 러닝 저장 성능 1차 개선

## Purpose

러닝 저장 중 UI가 멈춘 것처럼 보이는 문제를 줄인다.

## Context and Orientation

현재 저장 흐름은 리뷰 화면에서 `saveFinishedRun`을 호출하고,
`SqfliteRunSessionRepository.saveSession`이 세션과 포인트를 저장한다. 포인트는
트랜잭션 안에서 한 줄씩 `await insert` 되고, 저장 완료 상태 반영 때문에 같은
세션이 두 번 저장된다.

## Progress

- [x] 포인트 저장을 `sqflite` batch insert로 바꾼다.
- [x] 완료 상태를 먼저 반영해 저장 호출을 한 번으로 줄인다.
- [x] 많은 포인트 저장과 단일 저장 호출 회귀 테스트를 추가한다.
- [x] guardrails, analyze, Flutter tests를 실행한다.

## Validation Result

- `flutter test test/features/run_tracking/sqflite_run_session_repository_test.dart test/features/run_tracking/sqflite_run_session_repository_batch_test.dart test/features/run_tracking/run_playback_session_providers_test.dart` 통과.
- `dart run tool/guardrails.dart` 통과.
- `flutter analyze` 통과.
- `flutter test` 통과.

## Decisions

- 이번 단계에서는 isolate를 도입하지 않는다.
- 공개 repository API와 DB schema는 바꾸지 않는다.
- Health 백업은 현재처럼 Settings에서 처리되는 상태를 유지한다.
- 저장 직후 전체 세션 재조회 최적화는 프리즈가 남을 때 별도 작업으로 다룬다.

## Implementation Steps

1. `saveSession`의 포인트 delete와 insert를 `Batch`로 묶는다.
2. `saveFinishedRun`에서 최종 sync status를 적용한 세션을 한 번만 저장한다.
3. repository와 playback provider 테스트를 보강한다.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks and Recovery

- batch 저장이 특정 플랫폼에서 예상과 다르면 기존 transaction 경계는 유지하고
  batch만 되돌릴 수 있다.
- 단일 저장으로 누락되는 sync 상태가 있으면 playback provider 테스트가 잡도록
  최종 저장 세션의 `syncStatus`를 검증한다.
