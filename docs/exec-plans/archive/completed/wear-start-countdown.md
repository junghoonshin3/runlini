# Wear OS Start Countdown

## Purpose

워치에서 러닝을 시작할 때 바로 기록을 시작하지 않고 3초 카운트다운 후
Health Services 운동 기록을 시작한다.

## Context

- 기존 `시작`, `고스트 시작`, `일반 시작`은 곧바로
  `HealthServicesRunController.startRunInternal()`로 이어졌다.
- 실제 운동 시작 시각과 draft `startedAt`은 카운트다운이 끝난 뒤로 잡아야 한다.
- 카운트다운은 임시 UI 상태이므로 checkpoint, foreground workout
  notification, draft 저장 대상이 아니다.

## Progress

- [x] `CountingDown` phase와 countdown state 추가
- [x] 일반/고스트 시작을 countdown 후 실제 start로 지연
- [x] 취소 없는 countdown 화면 추가
- [x] countdown 상태를 active checkpoint에서 제외
- [x] Ready 화면에서 pending draft count와 재전송 액션 숨김
- [x] 기본 Ready 화면에서 `준비` status pill 숨김
- [x] active run에서 시작 화면 자리를 컨트롤 페이지로 대체
- [x] 러닝 중 컨트롤 화면을 `RUNLINI` 컨트롤 허브로 정리
- [x] 러닝 중 컨트롤 액션을 pause / stop 아이콘 중심으로 변경
- [x] 컨트롤 버튼을 중앙에 두 개 나란히 배치
- [x] 별도 Paused 화면 제거, 일시정지 후에도 active pager 안에서 조작 유지
- [x] core 거리 hero를 숫자/단위 분리 표시로 바꿔 긴 거리도 짤리지 않게 정리
- [x] 저장/삭제 후 1초 completion feedback 화면 추가
- [x] Ready 화면에 저장/삭제 완료 문구가 남지 않게 정리
- [x] unit test 추가
- [x] 문서 갱신
- [x] 검증 실행

## Decisions

- 일반 시작과 고스트 시작 모두 3초 카운트다운을 사용한다.
- countdown 화면은 `준비` / `고스트 준비` 라벨과 큰 숫자만 표시한다.
- countdown 중 앱이 종료되면 복구하지 않고 Ready로 돌아가도 된다.
- 실제 `startedAt`은 countdown 완료 후 기존 start 경로에서 생성한다.
- 워치는 기록 장치, 폰은 동기화 관리 장치로 본다. 그래서 워치 Ready
  화면은 pending count나 retry 버튼을 노출하지 않는다.
- 기본 Ready 화면은 시작 버튼 아래 상태 pill을 비워두고, 고스트/오류처럼
  실행 판단에 필요한 상태만 표시한다.
- Active run은 시작 화면 자리의 replacement로 컨트롤 페이지를 두고,
  Running 진입 직후에는 `Core` 페이지를 initial page로 연다.
- 일반 active page 순서는 `Controls → Core → Details`, 고스트 active page
  순서는 `Controls → Core → Ghost → Details`를 사용한다.
- 러닝 중 시작 화면 자리의 컨트롤 페이지는 `RUNLINI` 상단을 유지하되,
  중앙에 pause/resume 버튼과 stop 버튼을 나란히 배치한다.
- 러닝 중 컨트롤은 텍스트보다 아이콘을 우선하고, 접근성 라벨로
  `일시정지` / `재개` / `중지` 의미를 유지한다.
- `일시정지` 후에는 별도 Paused 화면으로 전환하지 않는다. 같은 active
  pager 안에 머물고, 컨트롤 허브의 primary action만 `재개`로 바뀐다.
- Core 거리 hero는 `12.10`과 `km`를 분리해 그리고 ellipsis를 쓰지 않는다.
  거리 숫자가 길어지면 compact/regular profile별로 숫자 폰트를 줄인다.
- 저장/삭제 완료는 transient feedback 화면에서 1초만 보여준다.
- Ready 화면은 시작 허브로 유지하며 저장/삭제 결과 문구를 남기지 않는다.
- 워치 저장 직후에도 pending draft는 기존 ack 흐름으로 내부 보존한다.

## Implementation Steps

1. `WearRunPhase.CountingDown`과 countdown 필드를 `WearRunState`에 추가한다.
2. `startRun()` / `startGhostRun()`을 countdown job 시작으로 바꾼다.
3. countdown job이 `3 → 2 → 1`을 표시한 뒤 기존 start 경로를 호출한다.
4. `WearRunScreen`에 `WearCountdownScreen` route를 추가한다.
5. `WearActiveRunStore`와 foreground service는 countdown을 active run으로
   취급하지 않는다.
6. `WearReadyScreen`과 ready model에서 동기화 관리 문구와 버튼을 제거한다.
7. 저장/삭제 완료는 `Feedback` phase에서 짧게 보여준 뒤 메시지 없는 Ready로
   돌아간다.
8. active run page model은 컨트롤 페이지를 첫 페이지에 두고, pager 초기
   페이지는 `Core` 인덱스로 지정한다.
9. 컨트롤 페이지는 시작 화면 자리의 `RUNLINI` 컨트롤 허브로 구성한다.
10. Paused phase도 active pager로 라우팅해서 별도 pause 화면을 제거한다.
11. 컨트롤 페이지 액션은 중앙 side-by-side 원형 아이콘 버튼으로 배치한다.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`
