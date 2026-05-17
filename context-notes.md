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
- 이번 요청의 대상은 홈 화면이며, 현재 앱의 홈은 `RunliniHomeScreen`의 기본 `기록` 탭이다.
- 이번 패스는 이전 메인 화면 점검을 반복하되, 새 기능 추가 없이 홈 기록 탭의 모바일 사용성 문제만 최소 수정한다.
- `adb devices`에는 연결된 Android 대상이 없고, `flutter devices`에는 macOS와 Chrome만 잡힌다. Android 실기기 캡처는 현재 불가능하다.
- 홈 헤더의 보조 설명은 말줄임을 제거해 작은 폭이나 글자 크기 변경에서 정보가 잘리지 않게 한다.
- 기간 선택 버튼과 달력 주간, 월간 전환 버튼은 최소 44dp 높이를 보장해 모바일 터치 타깃을 안정화한다.
- 390x844 위젯 렌더링 테스트에서 목표 패널, 달력, 오늘 기록 카드가 초기 뷰포트에 들어오는지 확인한다.
- 검증은 focused history tests, `dart run tool/guardrails.dart`, `flutter analyze`, 전체 `flutter test`로 통과했다.

## 2026-05-17 홈 화면 UI 개선

- 사용자의 요청은 홈 화면 UI 개선이며, 현재 앱의 홈은 `RunliniHomeScreen`의 기본 `기록` 탭이다.
- 이번 변경은 기존 네오브루탈리스트 다크 테마와 `AppColors` 토큰을 유지한다. 새 팔레트, 새 기능, 전면 리디자인은 하지 않는다.
- Android 연결 확인 결과 `adb devices`에는 연결 대상이 없고, `flutter devices`에는 macOS와 Chrome만 잡힌다. `flutter emulators`에는 `Medium_Phone_API_36.0` Android 폰 AVD가 있다.
- 개선 후보는 홈 헤더의 첫 화면 정보 위계, 하단 내비게이션의 선택 상태와 터치 안정성, 빈 기록 CTA의 폭과 상태 표현이다.
- 최종 변경 범위는 홈 기록 탭 헤더에 오늘 거리, 횟수 요약 배지를 추가하고, 하단 내비게이션을 별도 위젯으로 분리해 안전 영역, 얇은 상단 구분선, 선택 아이콘 위계를 조정하는 것이다.
- 390x844 위젯 테스트에서 홈 요약 배지, 목표 패널, 달력, 오늘 기록 카드가 깨지지 않고 렌더링되는지 확인한다.
- Android 폰 AVD `Medium_Phone_API_36.0`에서 앱 실행과 스크린샷 캡처를 시도했다. 첫 홈 캡처에서는 텍스트 겹침이 없었고, 마지막 재실행은 에뮬레이터 스냅샷이 설정 탭 상태로 복원되어 홈 화면 재캡처까지는 이어지지 않았다.
- 검증은 `flutter test test/features/run_tracking/history_home_mobile_layout_test.dart`, `flutter test test/features/dashboard/runlini_shell_test.dart`, `flutter analyze`, `git diff --check`로 통과했다.

## 2026-05-17 전체 화면 실제 UI 테스트

- 사용자는 모든 화면을 실제 UI로 테스트하길 요청했다. 단순 위젯 테스트만으로 끝내지 않고 Android 에뮬레이터에서 실행되는 integration test를 추가한다.
- 테스트 대상 화면은 기본 탭 3개, 기록 상세, 러닝 탭 지도와 컨트롤, 기록 레이스 선택 시트, 설정 탭, 러닝화 관리, 러닝화 추가와 수정, 러닝화별 기록, 삭제 확인 다이얼로그, 시작 체중 입력 화면이다.
- 실제 앱 데이터만 사용하면 시작 체중, 상세, 러닝화 하위 화면처럼 조건부 화면을 안정적으로 열기 어렵다. 테스트에서는 실제 앱 위젯을 쓰되 provider override로 세션, 설정, 러닝화를 통제한다.
- `adb devices`에는 연결된 Android 기기가 없고, `flutter devices`에는 macOS와 Chrome만 잡힌다. AVD는 이전 확인 기준 `Medium_Phone_API_36.0`를 사용한다.
- 기존 작업트리의 `docs/exec-plans/active/interval-feature-lock-v1.md` 변경은 이번 테스트와 무관하므로 건드리지 않는다.
- Android AVD `emulator-5554`에서 `flutter test -d emulator-5554 integration_test/app_ui_smoke_test.dart`로 전체 UI smoke test 2건이 통과했다.
- 테스트 중 발견된 실패는 스크린샷 surface 변환, 스크롤 대상 선택, 라우트 전환 직후 탭 타이밍, Back tooltip 중복처럼 테스트 안정성 문제였다. 운영 UI 코드는 수정하지 않았다.
- Google Maps 설정이 없는 테스트 환경에서는 러닝 탭의 지도 대신 `android-map-config-error` 상태를 검증하고, 실제 러닝 컨트롤과 기록 레이스 흐름은 그대로 연다.
- 테스트 종료 후 앱 패키지가 에뮬레이터에서 제거되어 ADB 수동 캡처는 런처 화면만 확인됐다. 최종 근거는 에뮬레이터에서 실행된 integration test 로그와 `flutter analyze` 결과로 둔다.
