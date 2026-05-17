# Context Notes

## 2026-05-12

- 사용자는 `고스트런`을 러닝앱 사용자에게 더 직관적인 이름으로 바꾸길 원했고,
  최종 사용자 표시명은 `기록 레이스`로 결정했다.
- 내부 코드명은 `record_race`로 결정했다.
- 기존 `ghost_*` 로컬 DB, 설정 키, Wear Data Layer 경로와 워치 캐시는
  마이그레이션 또는 fallback으로 보존한다.
- 완료된 archive 실행 계획은 변경 이력으로 남기고, 살아 있는 제품/플랫폼 문서만
  현재 명칭에 맞춘다.
- 기존 작업트리의 `docs/exec-plans/active/interval-feature-lock-v1.md` 수정은
  이번 작업에서 건드리지 않는다.
- `record_race` 리네이밍은 새 DB 컬럼 `record_race_summary_json`을 쓰고,
  기존 `ghost_summary_json`, `ghostSummary`, Wear `ghost_*` 경로는 읽기
  fallback으로 유지한다.
- 최종 검증은 guardrails, analyzer, 전체 Flutter 테스트, app/wear unit test,
  Wear debug assemble로 완료했다.

## 2026-05-11

- 문제 재현 맥락은 출발 확인 이후 러닝 중 고스트 경로 이탈 안내가 나와야 하는 상황이다.
- 사용자 설정, 볼륨, 출발 확인 게이트보다 TTS 재생 중 새 안내가 버려지는 경로를 우선 의심한다.
- 긴급 cue 정책은 기존 안내를 기다리지 않고 즉시 끊고 재생하는 방식으로 결정했다.
- `flutter_tts.speak`가 Android에서 `0`을 반환하면 발화가 수락되지 않은 것으로 처리한다.
- 킬로미터 안내는 낮은 우선순위로, 인터벌과 추월 계열 고스트 안내는 일반 우선순위로 둔다.
- 경로 이탈, 경로 복귀, 고스트 코스 완료 안내는 긴급 우선순위로 처리한다.
- dispatcher는 일반 안내 재생 중 들어온 일반 안내를 끼워 넣지 않고, 긴급 안내만 `stop` 후 재생한다.
- `RunningTabScreen.dispose`에서는 `ref.read`를 쓰지 않도록 TTS 클라이언트를 `initState`에서 보관한다.
- 설정 화면의 폰 음성 테스트 버튼은 현장 테스트 용도였고, 사용자 요청에 따라 제품 UI에서 제거한다.
- Android 12+ 스플래시에서 기존 `splash_logo`가 시스템 아이콘 영역에 꽉 차 잘리는 문제가 있어, 같은 캔버스 안에서 로고를 약 70%로 줄인 `splash_logo_v31` 리소스를 별도로 사용한다.
- Android 11 이하 launch background는 기존 `splash_logo`를 유지해 이전 기기 렌더링을 바꾸지 않는다.
- 인터벌 기능은 임시 잠금 상태로 두고, 버튼 탭 시 설정 시트를 열지 않고 추후 제공 안내만 보여준다.
- 기존 저장값의 `intervalWorkout.enabled`는 지우지 않는다. 대신 현재 런타임, 고스트 충돌 처리, 워치 동기화에서 비활성으로 취급한다.
- 인터벌 시트와 계산기는 추후 재개를 위해 보존하고, 외부 진입점과 런타임 provider에서만 잠금을 적용한다.
- 인터벌 잠금 변경은 focused widget/provider 테스트, guardrails, analyze, 전체 `flutter test`로 검증했다.

## 2026-05-17

- 사용자는 메인 화면의 전체 디자인 점검을 요청했고, 앱 기본 탭이 `AppTab.history`라서 `기록` 탭을 메인 화면으로 본다.
- 범위는 하단 탭 셸과 첫 화면 인상까지 확인하되, 코드 변경은 기록 홈 화면에 필요한 최소 조정으로 제한한다.
- Android 기기는 현재 `flutter devices`에서 잡히지 않는다. macOS와 Chrome만 연결되어 있어 실제 Android 캡처가 어려우면 위젯 테스트 렌더링과 Flutter 분석으로 검증한다.
- 기존 테마는 네오브루탈리스트 다크 톤, 굵은 테두리, `AppColors` 토큰을 사용한다. 새 팔레트나 전면 리디자인은 하지 않는다.
- 390x844 위젯 렌더링에서 목표 링 패널이 첫 화면 대부분을 차지하고, 달력과 당일 기록이 아래로 밀리는 문제가 보인다.
- 개선 방향은 헤더 설명문을 짧게 줄이고, 목표 패널의 링 크기와 내부 박스 장식을 낮춰 첫 화면의 스캔 범위를 넓히는 것이다.
- 수정 후 390x844 위젯 렌더링에서 달력과 첫 기록 카드 상단이 첫 화면에 들어오고, 중첩 박스가 줄어든 것을 확인했다.
- 검증은 `dart run tool/guardrails.dart`, `flutter analyze`, focused widget tests, 전체 `flutter test`로 통과했다.
- 실제 Android 기기 캡처는 연결된 Android 디바이스가 없어 수행하지 못했다.
- Android 에뮬레이터 연결 후 확인하니 날짜별 빈 기록 패널이 텍스트 폭만 차지해 다른 홈 패널과 정렬이 어긋났다. `HistoryNoRunsOnDatePanel`은 전체 폭을 차지하도록 맞춘다.
