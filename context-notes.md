# Context Notes

## 2026-05-21 경쟁레이스 기록선택화면 개편 방향 논의

- 사용자는 경쟁레이스 기록선택화면을 어떻게 개편하면 좋을지 리서치 담당자, UI/UX 디자이너, 서비스 기획자의 의견을 취합해 듣길 원한다.
- 이번 범위는 제품 방향 제안이며 코드 구현은 하지 않는다.
- 현재 화면은 `RecordRaceSessionPickerSheet` 바텀시트에서 최신 기록을 기본 확장하고, 접힘/확장 카드로 거리, 시간, 평균 페이스, 경로 프리뷰, 선택 버튼을 보여준다.
- 러닝 시작 전에는 `RunRecordRaceRecommendationCard`가 오늘 추천 기록을 작게 노출하고, 탭 시 기존 기록 레이스 선택 상태로 연결한다.
- 의사결정 오너는 서비스 기획자이며, 리서치 담당자는 외부 사례와 패턴, UI/UX 디자이너는 화면 구조와 상호작용을 지원한다.
- 최종 결론은 기록선택화면을 `추천 1개 + 다른 후보 리스트` 구조로 바꾸는 것이다.
- 러닝 탭의 `오늘 추천` 카드는 즉시 선택이 아니라 선택 시트 진입점으로 두고, 시트 상단 추천 카드에서 추천 이유, 핵심 지표, 경로 미리보기, 명시적 CTA를 제공하는 방향이 우선이다.
- MVP는 현재 추천 로직인 같은 요일 우선, 없으면 최근 기록을 유지하고 화면 구조, 추천 이유, 빈 상태, 경로 부족 상태를 정리하는 데 집중한다.
- 개인 최고, 즐겨찾기, 고급 필터, route grouping, 추천 알고리즘 고도화는 후순위로 둔다.
- 논의 기록은 `.agent-company/discussions/20260521T052150Z-discussion-70e16d`에 닫았고, 회의록은 `.agent-company/meetings/20260521T052907Z-meeting-7f99f1.md`에 저장했다.

## 2026-05-20 기록 레이스 완료 팝업 정책 반영

- 사용자는 Agent Company 리서치·기획 토론 결론을 바탕으로 개발 구현을 요청했다.
- 결정된 제품 정책은 기록 레이스 완료를 운동 종료가 아니라 기록 중 완료 이벤트로 다루는 것이다.
- `record-race-run-completion-dialog`는 “기록 레이스 완료 결과 + 계속 달리기/러닝 종료 선택” 화면으로 정의한다.
- 완료 판정 전에는 내부 진행률이 99.5% 이상이어도 화면에 100%를 표시하지 않는다.
- 완료 확정 이후에는 100% 표시와 완료 팝업이 같은 완료 의미를 가져야 한다.
- GPS 기반 실시간 결과는 최종 확정 표현을 피하고 `실시간 결과`로 표현한다.
- finish 근처 자동 일시정지는 사용자의 수동 중단이 아니므로 기존 완료 안전 조건을 만족한 경우에만 완료 prompt 쓰기를 허용한다.
- 수동 pause, off-route, 시작 미확정, finish 조건 미충족 상태는 완료로 인정하지 않는다.
- 기존 dirty worktree의 `app-store-screenshots.json`, `src/lib/defaults.ts`, `.agents/`, `skills-lock.json` 변경은 이번 구현과 무관하므로 건드리지 않는다.
- 구현 후 focused widget/provider 테스트와 `flutter analyze`가 통과했다.
- 앱 화면 테스트는 위치 스트림 자체보다 provider 상태가 실제 `RunningTabScreen` 완료 팝업으로 이어지는지를 검증하도록 좁혔다. 완료 판정 계산과 자동 일시정지 허용은 provider 테스트가 담당한다.

## 2026-05-18 스토어 스크린샷 제작

- 사용자는 App Store와 Google Play용 스크린샷 제작을 요청했다.
- 실제 앱 캡처 PNG는 아직 없고, 사용자는 Android 에뮬레이터 기준으로 캡처와 편집기 구성을 진행해도 된다고 승인했다.
- 앱 이름은 `Runlini`로 둔다.
- 앱 아이콘은 `assets/branding/runlini_app_icon_1024.png`를 기본으로 쓰고, Play Store 보조 아이콘은 `assets/branding/runlini_play_store_icon_512.png`를 쓴다.
- 스토어 대상은 처음 요청대로 App Store와 Google Play 둘 다로 둔다.
- 초기 locale은 템플릿 기본값인 `en`을 사용하되, 편집기에서 나중에 한국어 등으로 바꿀 수 있게 둔다.
- 스타일은 `docs/DESIGN.md`와 `docs/design-docs/design-identity.md`의 true black, volt green, electric red, oversized blunt typography, bordered surface 기준을 따른다.
- 핵심 내러티브는 기록 레이스, 러닝 중 앞섬/뒤처짐 즉시 확인, 과거 경로 재사용, 기록 분석, Health sync와 워치 준비 흐름이다.
- 앱 런타임 코드는 변경하지 않고, 마케팅 캡처 자산과 Next.js 편집기만 추가한다.
- 템플릿 루트의 `README.md`와 `.gitignore`는 Flutter 프로젝트 파일과 충돌하므로 덮어쓰지 않는다.
- Android `Medium_Phone_API_36.0` 에뮬레이터에서 `01.png` 기록 홈, `02.png` 러닝 시작 화면, `03.png` 설정 화면, `04.png` 기록 레이스 선택 시트, `05.png` 러닝 중 화면을 캡처했다.
- 캡처 크기는 모두 1080x2400이다. 편집기 Android phone export canvas는 1080x1920이라 기기 프레임 안에서는 상단 기준 cover crop으로 보인다.
- 템플릿 복사는 `README.md`와 `.gitignore`를 제외하고 수행했다.
- `app-store-screenshots.json`과 `src/lib/defaults.ts`는 같은 Runlini 덱 내러티브를 가리키도록 맞췄다.
- `bun`, `pnpm`, `yarn`은 없고 `npm`만 사용 가능하다.
- `npm install`은 React RC peer dependency 해석 때문에 `.npmrc`의 `legacy-peer-deps=true`가 필요했다.
- `next`는 audit의 critical 취약점 때문에 `15.5.18`로 올렸고, Next 내부 `postcss` advisory는 루트 `postcss`와 `overrides`를 `8.5.14`로 고정해 해결했다.
- `next/font/google`은 빌드 중 Google Fonts 네트워크 fetch가 필요해서 제거하고 시스템 폰트 스택으로 대체했다.
- `tailwind.config.ts`의 CommonJS `require`는 dev 서버 ESM 경로에서 실패해서 `tailwindcss-animate` ESM import로 바꿨다.
- Next dev 서버가 React 19 RC와 devtools manifest 오류를 냈기 때문에 `react`, `react-dom`, `@types/react`, `@types/react-dom`을 안정 19.x로 올렸다.
- 최종 확인은 `npm run build`, `npm audit --audit-level=moderate`, `curl` 루트와 `/api/project` HTTP 200, `git diff --check`, Android 캡처 PNG 치수 확인으로 통과했다.

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

## 2026-05-17 iOS 전체 UI 테스트

- 사용자는 iOS에서 전체 UI 테스트 진행을 요청했다.
- 대표 검증 대상은 일반 iPhone 크기의 `iPhone 17 Simulator`로 둔다. 여러 Simulator가 있지만 사용자가 특정 기기를 지정하지 않았고, 전체 smoke 목적에는 일반 크기 iPhone이 가장 적합하다.
- 샌드박스 내부 `xcrun simctl`과 `xcrun xctrace`는 CoreSimulatorService와 Instruments 캐시 접근 권한 문제로 실패했다. 승인된 샌드박스 외부 조회에서는 iOS 26.2 runtime과 여러 종료 상태 Simulator가 확인됐다.
- `flutter devices`는 macOS와 Chrome만 표시했고, iOS 실기기 `iPhone (26.3.1)`은 offline으로 보인다.
- `iPhone 17 Simulator` 부팅 후 `flutter devices`에서 iOS target으로 인식됐다.
- 첫 iOS smoke test 실행은 CocoaPods에서 실패했다. 원인은 Firebase iOS SDK가 최소 iOS 15.0을 요구하는데 앱의 Podfile과 Runner target이 14.0으로 설정된 것이다.
- 최소 수정으로 iOS deployment target을 15.0으로 올리고, smoke test의 Android 전용 지도 placeholder 기대값을 iOS에서는 `run-map`으로 검증하도록 분기한다.
- 두 번째 iOS smoke test는 앱 실행과 주요 화면 탐색까지 진행됐고, 러닝화 관리 화면에서 `add-shoe-button` 탭이 실패했다. 로그상 버튼 중심 좌표가 화면 오른쪽 밖에 있어 iOS route 전환 애니메이션 중 너무 이르게 탭한 테스트 타이밍 문제로 판단한다.
- 전역 `_expectScreen` 대기는 카운트다운처럼 짧게 사라지는 화면에 부작용이 있어 사용하지 않는다. 대신 러닝화 관리처럼 `Navigator.push` route 전환 직후 바로 탭하는 구간에만 350ms pump를 둔다.
- 최종 iOS smoke test는 `iPhone 17 Simulator`에서 2개 테스트가 통과했다. 확인 화면은 기록 홈, 기록 상세, 러닝 탭, 기록 레이스 시트, 카운트다운, 완료 리뷰, 폐기 다이얼로그, 설정, 러닝화 관리/추가/수정/착용 기록/삭제 다이얼로그, 시작 체중 화면이다.
- 직접 `flutter run`으로 iPhone 17 Simulator에 앱을 띄워 `/private/tmp/runlini-ios-home.png`를 캡처했다. 실제 로컬 상태에서는 시작 체중 입력 화면이 첫 화면으로 표시됐고 키보드와 저장 버튼이 iOS safe area 안에서 보인다.
- 검증은 `flutter test -d 5CEFCD89-0A8C-47DE-B0FE-B6776C10F9EA integration_test/app_ui_smoke_test.dart`, `flutter analyze`, `flutter test test/features/settings/settings_tab_screen_test.dart`, `git diff --check`로 통과했다.

## 2026-05-18 오늘의 기록 레이스 추천

- 사용자는 변증법 검토 결과의 1번 기능인 `오늘의 기록 레이스 추천 카드` 구현을 진행하길 원했다.
- 범위는 DB 변경 없이 기존 `RunSessionSummary` 목록에서 추천 후보 1개를 계산해 러닝 탭 시작 전 카드로 보여주는 것이다.
- 추천 기준은 기록 레이스에 쓸 수 있는 정상 기록 중 오늘과 같은 요일의 기록을 우선하고, 없으면 가장 최근 정상 기록으로 둔다.
- 추천 카드 탭은 새 선택 흐름을 만들지 않고 기존 `recordRaceSettingsProvider.selectSession`을 호출해 기록 레이스 선택 상태로 연결한다.
- 기존 작업트리의 `docs/exec-plans/active/interval-feature-lock-v1.md` 수정은 이번 작업과 무관하므로 건드리지 않는다.
- 구현은 `RunRecordRaceRecommendationService`, `runRecordRaceRecommendationProvider`, `RunRecordRaceRecommendationCard`로 나눴다.
- 추천 카드는 기록 레이스가 아직 선택되지 않았고, 시작 전이며, 추천 가능한 기록이 있을 때만 러닝 탭에 표시된다.
- 검증은 focused tests, `flutter analyze`, 전체 `flutter test`로 통과했다.
- `dart run tool/guardrails.dart`는 이번 변경과 무관한 기존 `lib/features/run_tracking/ui/history/history_tab_screen.dart` 412라인 제한 위반으로 실패했다.
- 사용자가 실제 앱에서 UI가 보이지 않는다고 지적했다. 원인은 추천 가능한 경로 기록이 없으면 카드가 완전히 숨겨지는 조건이었다.
- 추천 가능한 기록이 없어도 러닝 탭 시작 전 `오늘 추천` 비활성 안내 카드를 보여주도록 바꿨다.

## 2026-05-18 오늘의 기록 레이스 추천 상단 노출

- 사용자는 오늘의 추천기록을 상단에 작게 노출하길 원했다.
- 추천 계산과 추천 카드 탭 시 기록 레이스 선택 동작은 기존 구현을 유지한다.
- 변경 범위는 러닝 탭 시작 전 추천 카드의 위치와 시각 밀도 조정으로 제한한다.
- 추천 카드 노출 조건은 기존과 동일하다. 러닝 탭, 시작 전, 카운트다운 전, 리뷰 아님, 기록 레이스 미선택 상태에서 표시된다.
- 추천 후보가 있으면 같은 요일 최신 기록을 우선하고 없으면 최근 기록을 쓴다. 추천 가능한 기록이 없으면 빈 상태 안내를 표시한다.
