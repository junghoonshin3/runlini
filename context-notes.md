# Context Notes

## 2026-05-28 Android 전역 UI 깨짐 점검

- 사용자는 전역 화면에서 글자가 넘어가거나 의도치 않게 줄바꿈되는 부분, 컴포넌트 높이와 크기가 맞지 않는 부분을 전체적으로 확인하고 수정하길 요청했다.
- 범위는 Android 우선이며, 현재 연결된 실행 대상은 `emulator-5554`다.
- 처리 방식은 발견한 명확한 UI 깨짐을 같은 작업에서 바로 수정하는 것이다.
- 기존 `integration_test/app_ui_smoke_test.dart`는 최근 기록 레이스 진입점이 하단 chip에서 상단 card로 변경된 상태를 반영하지 못해 `record-race-control-chip` 기대값에서 먼저 실패한다.
- `StartupWeightScreen`은 현재 `RunliniApp`의 home 흐름에 연결되어 있지 않으므로 전역 smoke 안에서 앱 라우트로 기대하지 않고, 필요하면 별도 위젯 검증 대상으로 다룬다.
- 검증 기준은 compact viewport, 일반 Android viewport, 텍스트 확대에서 Flutter framework overflow 예외가 없고 주요 CTA와 터치 대상이 화면과 부모 컴포넌트 안에 유지되는 것이다.
- 기존 미추적 `docs/assets/runlini-emulator-demo-20260525.mov`는 이번 작업과 무관하므로 건드리지 않는다.
- 구현 결과 `integration_test/app_ui_smoke_test.dart`는 최신 기록 레이스 상단 카드, 선택 카드, 권한 preflight skip, 독립 `StartupWeightScreen` 검증 흐름에 맞게 갱신했다.
- 새 `test/runlini_global_ui_audit_test.dart`는 360x640 compact viewport와 390x844 텍스트 1.3배 환경에서 히스토리, 상세, 러닝 idle, 기록 레이스 card와 sheet, active run, 종료 리뷰, 설정, 러닝화 관리를 순회한다.
- audit 결과 production UI 코드에서 즉시 수정해야 할 텍스트 overflow나 터치 타깃 크기 문제는 재현되지 않았다.
- 검증은 새 global UI audit, 관련 focused UI tests, Android emulator smoke, `flutter analyze`, `dart run tool/guardrails.dart`, `git diff --check`로 통과했다.

## 2026-05-28 Android 앱 시작 크래시 수정

- 사용자는 직전 `ACTIVITY_RECOGNITION` preflight 구현 후 앱이 종료된다고 보고했다.
- 에뮬레이터 logcat crash buffer에서 `Unable to instantiate activity ComponentInfo{kr.sjh.runlini/kr.sjh.runlini.MainActivity}`와 `NullPointerException: ... Context.getSharedPreferences(...) on a null object reference`를 확인했다.
- 스택트레이스는 `RunMotionPermissionHandler.<init>(RunMotionPermissionHandler.kt:21)`와 `MainActivity.<init>(MainActivity.kt:11)`를 가리킨다.
- 원인은 `MainActivity` 필드 초기화 시점에 `RunMotionPermissionHandler(this)`를 만들고, 핸들러 생성자에서 즉시 `getSharedPreferences()`를 호출한 것이다.
- 수정 방향은 `RunMotionPermissionHandler` 생성을 `configureFlutterEngine()` 내부로 늦추고, SharedPreferences 접근도 lazy로 늦추는 것이다.
- 기존 미추적 `docs/assets/runlini-emulator-demo-20260525.mov`는 이번 작업과 무관하므로 건드리지 않는다.
- 구현 결과 `MainActivity`는 `configureFlutterEngine()` 이후에만 `RunMotionPermissionHandler`를 생성하고, permission callback도 handler 초기화 이후에만 위임한다.
- `RunMotionPermissionHandler`는 `SharedPreferences` 접근을 lazy로 늦추고 `applicationContext`를 사용해 Activity attach 전 context 접근을 피한다.
- 검증은 `./gradlew :app:compileDebugKotlin`, `flutter test test/runlini_motion_permission_preflight_widget_test.dart test/core/motion/run_motion_permission_client_test.dart`, `flutter analyze`, `dart run tool/guardrails.dart`, `git diff --check`, `./gradlew :app:assembleDebug`로 통과했다.
- 수정 APK를 `emulator-5554`에 설치해 `kr.sjh.runlini/.MainActivity`를 실행했고, 프로세스 생존과 crash buffer에 새 로그가 없는 것을 확인했다.

## 2026-05-28 ACTIVITY_RECOGNITION 시작 전 preflight

- 사용자는 러닝 시작 버튼을 누른 뒤 카운트다운이 끝난 시점에 피지컬 액티비티 권한 팝업이 떠서 UX를 해치는 문제를 제기했고, Agent Company deep discussion 후 구현을 요청했다.
- deep discussion 참여자는 `service-planner`, `researcher`, `ui-ux-designer`, `architect`, `qa-engineer`였고 최종 전원이 `agree`했다.
- 결정은 `ACTIVITY_RECOGNITION`을 기본 GPS 러닝 시작의 hard gate가 아니라 자동 일시정지, 케이던스, 걸음 기반 보정, motion evidence를 위한 soft gate로 다루는 것이다.
- 앱 첫 실행, 카운트다운 중, 카운트다운 종료 직후에는 권한 요청을 하지 않는다.
- START 직후 카운트다운 전에 짧은 설명과 함께 권한을 요청할 수 있지만, 거부되거나 다시 묻지 않음이어도 GPS-only 러닝은 계속 시작한다.
- 현재 문제의 원인은 `RunPlaybackController.start()`가 카운트다운 완료 후 motion evidence tracking을 켜고, Android `RunMotionEvidenceStreamHandler.onListen()`이 권한 없음 상태에서 바로 `requestPermissions()`를 호출하는 구조다.
- 구현 방향은 EventChannel 구독에서 권한 요청 부작용을 제거하고, 별도 MethodChannel을 통해 START preflight에서만 권한 상태 확인과 요청을 수행하는 것이다.
- 기존 untracked `docs/assets/runlini-emulator-demo-20260525.mov`는 이번 작업과 무관하므로 건드리지 않는다.
- 구현 결과 Android phone은 `runlini/motion_permission` MethodChannel에서 활동 인식 권한 상태 확인, 요청, 앱 설정 열기를 처리한다.
- `RunMotionEvidenceStreamHandler`는 더 이상 `requestPermissions()`를 호출하지 않고, 권한이 없으면 `permissionDenied` evidence만 방출한다.
- Flutter START 흐름은 기록 레이스 관련 사전 확인 후, 카운트다운 전에 움직임 감지 권한 안내를 표시한다.
- 권한을 건너뛰거나 거부하거나 다시 묻지 않음 상태여도 GPS-only 카운트다운과 러닝 시작은 계속 진행한다.
- 검증은 motion permission client 테스트, motion preflight widget 테스트, 기존 countdown widget/provider 테스트, motion evidence client 테스트, `flutter analyze`, `dart run tool/guardrails.dart`, `git diff --check`, Android `./gradlew :app:compileDebugKotlin`로 통과했다.

## 2026-05-27 START 하단 컨트롤 종료 애니메이션

- 사용자는 START 버튼을 누를 때 하단 컨트롤 또는 바텀시트처럼 보이는 영역이 너무 갑자기 사라져 자연스러운 애니메이션 적용을 요청했다.
- Agent Company deep discussion 결과 `service-planner`, `ui-ux-designer`, `architect`, `fullstack-developer`, `qa-engineer`, `knowledge-manager` 전원이 `RunningTabScreen` 프리런 하단 컨트롤 묶음에만 visual exit를 적용하는 데 합의했다.
- 작업은 새 브랜치 `feature/start-bottom-controls-exit-animation`에서 진행한다.
- 기존 untracked `docs/assets/runlini-emulator-demo-20260525.mov`는 이번 작업과 무관하므로 건드리지 않는다.
- 적용 대상은 `START`, `인터벌`, `현재 위치` 버튼으로 구성된 프리런 하단 컨트롤 묶음이다.
- 제외 대상은 `RunliniHomeScreen` 하단탭, 실제 `showModalBottomSheet`, countdown provider, playback state machine, 지도, 위치 권한, 저장 흐름이다.
- 모션은 기존 `RunliniMotion.shortTransition` 140ms와 `RunliniMotion.exitCurve`를 사용하고, fade out plus 20dp downward slide를 기본으로 한다.
- START 수락과 `RunStartCountdownOverlay` 표시는 애니메이션 완료를 기다리지 않고 즉시 진행해야 한다.
- 하단 컨트롤은 시각적으로 남아 있어도 즉시 hit-test와 semantics action에서 제외되어야 한다.
- reduce motion에서는 `RunliniMotion.enabledDuration`에 따라 즉시 전환하고 중간 fade나 slide 상태를 남기지 않는다.
- 구현은 `RunningTabScreen` 본문에서 하단 컨트롤 배치를 `running_tab_screen_bottom_controls.dart` part로 옮기고, stable key가 있는 `_RunBottomControlsExit` wrapper가 outgoing child를 140ms 동안 보존하는 방식으로 정리했다.
- `AnimatedSwitcher` 단독 적용은 상단 추천 카드가 동시에 제거될 때 하단 레이어 state가 새로 만들어져 outgoing child 보존이 불안정했으므로 사용하지 않는다.
- focused 검증은 `flutter test test/runlini_countdown_widget_test.dart test/runlini_countdown_bottom_controls_animation_test.dart test/runlini_running_controls_widget_test.dart`로 통과했다.
- 전체 검증은 `flutter analyze`, `dart run tool/guardrails.dart`, `git diff --check`, `flutter test`로 통과했다.
- Android 실기기 `5200024fee2b2571`에서 `flutter run -d 5200024fee2b2571`로 debug 설치와 launch를 확인했고, 러닝 탭 화면의 START, 인터벌, 현재 위치 컨트롤 표시를 캡처로 확인했다.

## 2026-05-27 러닝 집중 상태 하단탭 숨김

- 사용자는 하단탭이 보이면 안 되거나 눌리면 안 되는 러닝 집중 상태에서는 하단탭을 아예 안 보이게 하는 방향을 선택했다.
- 작업은 새 브랜치 `feature/hide-run-focus-bottom-tab`에서 진행한다.
- 기존 untracked `docs/assets/runlini-emulator-demo-20260525.mov`는 이번 작업과 무관하므로 건드리지 않는다.
- 하단탭 표시 정책은 `RunliniHomeScreen` 한 곳에서만 소유한다.
- 하단탭 숨김 대상은 카운트다운, active running, paused running, record race completion, finish review다.
- 기록 메인, 러닝 대기, 설정 메인에서는 기존 앱 하단탭 `runlini-bottom-navigation`을 그대로 보여준다.
- 기록 상세, 러닝화 관리, 착용 기록, 러닝화 추가와 수정 같은 push leaf route는 기존 구조상 앱 하단탭이 없는 전체 화면으로 유지한다.
- `RunShoeFormScreen`의 `Scaffold.bottomNavigationBar`는 저장 CTA 영역이며 앱 하단탭이 아니다.
- 이번 변경에서는 ShellRoute, 탭별 Navigator, route별 `showBottomTab` 플래그를 추가하지 않는다.
- 하단탭을 `bottomNavigationBar: null`로 숨기면 러닝 컨트롤이 시스템 제스처 영역에 가까워질 수 있으므로 active/paused 컨트롤의 SafeArea 하단 여백을 같이 보정한다.
- 구현 결과 `RunliniHomeScreen`이 카운트다운, active, paused, review, record race completion 상태를 보고 앱 하단탭을 렌더링하지 않는다.
- active/paused 러닝 컨트롤은 하단 시스템 inset을 더해 배치한다.
- 검증은 focused widget tests, `flutter analyze`, `dart run tool/guardrails.dart`, 전체 `flutter test`, `git diff --check`로 통과했다.

## 2026-05-26 Google Play 스토어 스크린샷 제작

- 사용자는 출시 준비를 위해 Google Play Store에 올릴 앱 스크린샷 제작을 요청했다.
- 사용자는 별도 스크린샷과 앱 아이콘 경로를 모른다고 했고, Google Play 전용, 한국어, 추천 스타일로 진행을 승인했다.
- 기존 프로젝트에는 `package.json`, `app-store-screenshots.json`, `public/app-icon.png`, Android와 Apple 예시 스크린샷 디렉터리가 이미 존재한다.
- 새 템플릿을 루트에 덮어쓰지 않고 기존 스크린샷 에디터를 활용한다.
- 앱 아이콘 후보는 `assets/branding/runlini_play_store_icon_512.png`와 `public/app-icon.png`가 있다.
- Android 에뮬레이터는 `Medium_Phone_API_36.0`을 사용하고, 연결된 디바이스는 `emulator-5554`다.
- 스크린샷 카피는 한국어만 우선 seed하며, Runlini의 핵심 흐름인 기록 레이스, 실시간 러닝 화면, 기록 분석, 시작 화면, 설정/러닝 준비를 보여준다.
- 실제 캡처는 `public/screenshots/android/phone/ko/01.png`부터 `05.png`까지 저장했다.
- 스크린샷 덱은 Google Play Android Phone과 Feature Graphic 중심으로 `app-store-screenshots.json`에 seed했다.
- `runlini-clean` 테마를 추가해 밝은 배경과 런린이 네온 그린 포인트를 사용한다.
- 검증은 `npm run build`와 `curl -sI http://localhost:3000`으로 통과했다.
- 스크린샷 에디터는 `npm run dev`로 실행 중이며, 로컬 주소는 `http://localhost:3000`이다.

## 2026-05-25 러닝탭 기록레이스 상단 카드 복구

- 사용자는 러닝탭 상단 기록레이스 카드가 사라진 이유를 물었고, 이어 상단 카드 복구 계획 구현을 요청했다.
- 원인은 카드 삭제가 아니라 `a30011f 러닝탭 경쟁레이스 진입점 정리` 이후 상단 `오늘 추천` 카드가 추천 가능한 기록이 있을 때만 보이고, 추천이 없으면 START 근처 하단 칩으로 내려가는 정책 변경이다.
- 새 정책은 러닝 시작 전, 카운트다운 전, 리뷰 전 상태에서는 기록레이스 관련 진입점을 상단 카드로 항상 보여주는 것이다.
- 선택 가능한 기록이 없으면 상단 카드에서 비활성 안내만 보여주고 선택 시트를 열지 않는다.
- 이미 기록레이스가 선택된 상태에서도 상단 카드가 선택 상태와 변경, 해제 액션을 보여준다.
- Android 지도 설정 준비 여부를 보는 `mapControlsReady` 기존 보호 조건은 건드리지 않는다.
- 기존 미추적 파일 `docs/assets/runlini-emulator-demo-20260525.mov`는 이번 작업과 무관하므로 건드리지 않는다.
- 구현 결과 `RunRecordRaceRecommendationCard`는 추천, 선택됨, 선택 가능 기록 있음, 빈 상태, 로딩, 오류 상태를 모두 상단 카드로 표시한다.
- `RunningTabScreen`에서는 START 근처 `RunRecordRaceControlChip` 렌더링을 제거했고, 칩 파일은 후속 정리를 위해 남겨뒀다.
- 선택 전 fallback 카드의 `기록 선택`, 추천 카드의 `다른 기록`, 선택 카드의 `변경` 버튼이 모두 기존 선택 시트를 연다.
- 선택 카드의 `해제` 버튼은 기존 `recordRaceSettingsProvider`의 disable 흐름을 그대로 사용한다.
- 새 공통 카드 레이아웃은 `run_record_race_card_shell.dart`로 분리해 각 Dart 파일을 300줄 이하로 유지했다.
- 검증은 `flutter test test/features/run_tracking/run_record_race_recommendation_card_test.dart`, `flutter test test/features/record_race/record_race_settings_flow_test.dart test/features/run_tracking/record_race_interval_conflict_test.dart`, `flutter analyze`, `dart run tool/guardrails.dart`, `git diff --check`로 통과했다.

## 2026-05-25 README 인라인 데모 재생 개선

- 사용자는 README에서 영상을 다운로드하지 않고 바로 볼 수 있게 하라고 요청했다.
- GitHub README에서 repo 내부 MOV 상대 링크는 파일 페이지 또는 다운로드 흐름이 될 수 있으므로, README 본문에는 GitHub가 안정적으로 인라인 렌더링하는 GIF 프리뷰를 넣는다.
- 원본 MOV는 고화질 확인용 보조 링크로 남긴다.
- `ffmpeg`와 ImageMagick은 설치되어 있지 않고, macOS 기본 `avconvert`와 Swift 프레임워크는 사용할 수 있다.
- GIF는 최신 원본 `docs/assets/runlini-app-screen-recording-20260525.mov`에서 생성한다.
- macOS AVFoundation/ImageIO 기반 임시 Swift 스크립트로 16초, 5fps, 폭 360px GIF를 생성했다.
- README는 `docs/assets/runlini-app-demo-20260525.gif`를 인라인 이미지로 렌더링하고, 원본 MOV는 고화질 보조 링크로 둔다.
- GIF는 360x707, 534KB로 생성됐고, `README.md`에는 더 이상 `<video>` 태그가 없다.
- 검증은 GIF와 MOV 존재 확인, `sips` 크기 확인, README 링크 `rg`, `git diff --check`로 통과했다.

## 2026-05-25 README 화면 기록 영상 갱신

- 사용자는 지금 찍은 화면 기록 영상 파일을 찾아 README에 다시 올리라고 요청했다.
- 최근 2시간 내 Desktop 화면 기록 파일은 `화면 기록 2026-05-25 오후 8.12.46.mov`와 `화면 기록 2026-05-25 오후 8.10.38.mov`다.
- 가장 최신 파일은 `화면 기록 2026-05-25 오후 8.12.46.mov`이고 27MB QuickTime MOV 파일이다.
- 로컬 브랜치는 원격의 `8c9f5f3 Remove demo section from README`보다 뒤처져 있었으므로 README 수정 전 `git merge --ff-only origin/develop`로 동기화했다.
- README에는 최신 화면 기록 파일을 ASCII 파일명으로 `docs/assets`에 복사한 뒤 데모 섹션을 다시 연결한다.
- 최신 녹화본은 `docs/assets/runlini-app-screen-recording-20260525.mov`로 복사했고, README의 Demo 섹션은 이 파일을 가리키도록 복구했다.
- 검증은 파일 존재 확인, `file` 형식 확인, README 링크 `rg`, `git diff --check`로 통과했다.

## 2026-05-25 Runlini README 재작성

- 사용자는 Runlini README 작성을 요청했다.
- 현재 README에는 데모 영상, 기본 명령, 지도 설정, repo guide 정도만 있고, 실제 제품 기능과 현재 개발 흐름 설명이 부족하다.
- README는 한국어로 재작성하고, Runlini의 핵심 가치인 라이브 러닝, 기록 레이스, 기록 홈, 상세 분석, Health 연동, 설정과 러닝화 관리를 짧게 설명한다.
- 기존 Android 에뮬레이터 데모 영상 링크는 유지한다.
- 설정 안내는 Android Google Maps API key, iOS Apple Maps, Health Connect와 건강 앱 권한, Flutter 검증 명령으로 제한한다.
- 코드 변경은 하지 않고 README와 작업 기록만 변경한다.
- README는 제품 소개, 데모, 주요 기능, 기술 구성, 시작하기, 검증, 프로젝트 구조, 주요 문서, 개발 원칙 순서로 재작성했다.
- 데모 영상과 주요 문서 링크는 `test -f`로 확인했고, `git diff --check`는 통과했다.

## 2026-05-25 CI guardrails 파일 길이 실패 수정

- 사용자는 push 후 GitHub Actions가 다시 실패한 문제를 고치라고 요청했다.
- 최신 실패 run `26395893676`과 로컬 `dart run tool/guardrails.dart` 기준 실패 원인은 Dart 파일 300줄 제한 초과다.
- 실패 파일은 `lib/features/run_tracking/ui/detail/run_detail_summary_sections.dart` 328줄, `test/features/run_tracking/live_tracking_lifecycle_providers_test.dart` 413줄, `test/features/run_tracking/run_playback_session_providers_test.dart` 323줄, `test/runlini_running_controls_widget_test.dart` 366줄이다.
- guardrails 제한을 완화하지 않고, 의미 단위 파일 분리로 해결한다.
- `run_detail_summary_sections.dart`는 기존 import 경로를 유지하고 metric strip 관련 구현만 part 파일로 분리한다.
- provider lifecycle 테스트는 delayed cancel race 테스트와 fake stream client를 별도 테스트 파일로 분리한다.
- playback session 테스트는 리뷰 중 몸무게 저장 칼로리 갱신 테스트를 별도 테스트 파일로 분리한다.
- running controls widget 테스트는 reduce motion 고정 geometry 테스트를 별도 widget test 파일로 분리한다.
- 동작 변경과 API 변경은 하지 않고 CI 실패 해소를 위한 구조 분리만 한다.
- 구현 결과 8개 대상 파일의 줄 수는 각각 145, 187, 289, 135, 256, 78, 274, 97줄로 모두 300줄 이하가 됐다.
- 검증은 `dart run tool/guardrails.dart`, 분리 대상 focused `flutter test` 3묶음, `flutter analyze`, 전체 `flutter test`로 통과했다.
- push 후 GitHub Actions run `26396285103`에서는 `Run guardrails`와 `Analyze`는 통과했지만 `flutter test`가 14건 실패했다.
- 원격 실패 원인은 Flutter stable 3.44에서 배경색 있는 `DecoratedBox` 안의 `ListTile` 계열 위젯을 assertion으로 잡는 것이다.
- 실패 위치는 설정 개인정보 스위치, 러닝화 기본값 스위치, 상세 기록 삭제 dialog의 Health 삭제 checkbox이며, `SwitchListTile`와 `CheckboxListTile`을 투명 `Material`로 감싸 해결한다.
- ListTile assertion 보정 후 실패 대상 focused 테스트 묶음, `dart run tool/guardrails.dart`, `flutter analyze`, 전체 `flutter test`가 통과했다.

## 2026-05-22 경쟁레이스 완료 판정 finish corridor 우선 정책 구현

- 사용자는 기존 기획과 리서치 결론을 토대로 경쟁레이스 완료 판정 구현을 진행하라고 승인했다.
- 구현 목표는 사용자 본인의 전체 경쟁레이스 완료 확정 이벤트에만 완료 팝업을 띄우는 것이다.
- 99% 진행률 고정 표시 정책은 폐기된 상태를 유지한다.
- 현재 Dart `RecordRaceCompletionDetector`는 `frame.isOffRoute`를 finish 후보 계산 전 하드 차단한다.
- 현재 Wear `WearRecordRaceCompletionDetector`는 `distanceFromRouteM > 35`를 finish 후보 계산 전 하드 차단한다.
- 새 정책은 `startConfirmed`, unavailable, 유효하지 않은 total distance, 최소 runner distance 비율 미달은 하드 차단으로 유지한다.
- 그 뒤 detector 입력값 기준 finish corridor 후보를 계산하고, finish corridor가 성립하면 마지막 GPS off-route 흔들림보다 완료 후보를 우선한다.
- finish corridor가 성립하지 않는 일반 구간에서는 기존 off-route 차단을 유지한다.
- 구현 범위는 Dart detector, Wear detector, 양쪽 테스트로 제한하고 진행률 UI, gap 계산, 일반 기록 종료 정책, 팝업 중복 상태 관리는 바꾸지 않는다.
- 구현 결과 off-route 상태라도 finish point radius 안이거나 route progress 완료 후보이면서 finish point가 projection window 안이면 완료 후보를 유지한다.
- off-route 상태에서 route progress와 남은 거리가 완료처럼 보여도 finish point가 projection window 밖이면 완료 후보를 차단한다.
- 검증은 `flutter test test/features/record_race/record_race_completion_detector_test.dart test/features/record_race/record_race_event_engine_test.dart test/features/run_tracking/run_record_race_provider_loop_test.dart test/features/run_tracking/run_playback_record_race_completion_providers_test.dart`, `./gradlew :wear:testDebugUnitTest --tests kr.sjh.runlini.wear.WearRecordRaceCompletionDetectorTest --tests kr.sjh.runlini.wear.WearRecordRaceEventEngineTest`, `flutter analyze`로 통과했다.

## 2026-05-22 경쟁레이스 진행률 99% 고정 정책 폐기

- 사용자는 경쟁레이스 진행률을 완료 전 99%로 고정하는 정책 폐기를 명시했다.
- 기존 `_formatRecordRaceProgress`는 `completed == false`이면 route progress가 100% 이상이어도 99%로 표시했다.
- 새 결정은 완료 프롬프트 여부와 무관하게 화면 진행률은 실제 `routeProgress`를 0~100% clamp 후 반올림해 표시하는 것이다.
- 완료 프롬프트 판정은 별도 `RecordRaceCompletionDetector` 책임으로 남기고, 이번 변경에서는 판정 조건을 바꾸지 않는다.
- 과거 `완료 전 진행률 100% 미표시` 정책은 이번 결정으로 supersede 한다.
- 검증은 `flutter test test/features/run_tracking/live_run_dashboard_overlay_test.dart`, `flutter analyze`, `git diff --check`로 통과했다.

## 2026-05-22 Release signing 구성

- 사용자는 Google Play release signing을 Codex가 알아서 처리할 수 있는지 물었다.
- 실제 Play Console 업로드, 게시, Play App Signing 설정 클릭은 하지 않는다.
- 저장소에는 release signing 설정 골격과 ignore 규칙만 커밋한다.
- 실제 upload keystore와 `android/key.properties`는 로컬 비밀 파일로 생성하고 커밋하지 않는다.
- upload keystore는 `android/app/upload-keystore.jks`, key alias는 `upload`로 둔다.
- `android/key.properties`는 `storeFile`, `storePassword`, `keyAlias`, `keyPassword`를 담고, 비밀번호는 로컬에서 생성한다.
- release build는 key 설정이 없으면 debug signing으로 fallback 하지 않고 명확한 Gradle 오류로 중단되게 한다.
- phone과 wear 배포 전략이 아직 최종 확정되지 않았으므로 같은 upload key 설정을 양쪽 release build에 적용한다.
- `android/.gitignore`가 이미 `key.properties`와 `**/*.jks`를 ignore 하므로 루트 ignore 중복 추가는 하지 않는다.
- `android/key.properties`와 `android/app/upload-keystore.jks`를 생성했고 권한은 `600`으로 확인했다.
- `:app:signingReport`와 `:wear:signingReport`에서 release variant가 모두 `android/app/upload-keystore.jks`의 `upload` alias를 사용함을 확인했다.
- `flutter build appbundle --release`와 `./gradlew :wear:assembleRelease`가 새 signing 설정으로 통과했다.
- `flutter analyze`, `flutter test`, `./gradlew :app:testDebugUnitTest :wear:testDebugUnitTest`, `git diff --check`가 통과했다.

## 2026-05-22 Google Play 릴리즈 준비

- 사용자는 Runlini를 Google Play Store에 올리고 싶다고 했고, 릴리즈 담당자 중심 Agent Company 진행을 승인했다.
- 실제 Play Console 업로드, 게시, credential 변경은 이번 작업에서 하지 않는다.
- 2026-05-22 기준 공식 요구사항은 새 앱과 업데이트가 Android 15, API 35 이상을 target 해야 하며, Android 15 이상 대상 제출은 16KB page size 지원 리스크도 확인해야 한다.
- 신규 개인 개발자 계정이 2023-11-13 이후 생성됐다면 production access 전 12명 이상 테스터가 14일 연속 closed test에 opt-in 해야 한다.
- Runlini는 위치, Health, Wear, 운동 기록 데이터를 다루므로 Play Console App content, Data safety, 개인정보처리방침, 민감 권한 설명이 출시 gate다.
- 이번 로컬 점검은 Android build config, signing, app bundle 빌드, 테스트 전략, 스토어 등록 준비 항목을 확인하는 데 집중한다.
- 기존 작업트리의 미커밋 변경은 사용자 작업으로 보고 되돌리지 않는다.
- 로컬 확인 결과 phone 앱은 `compileSdk = 36`, `targetSdk = 36`, `minSdk = 26`, `applicationId = "kr.sjh.runlini"`이고, `pubspec.yaml` 기준 버전은 `1.0.0+1`이다.
- 로컬 확인 결과 wear 모듈은 `compileSdk = 36`, `targetSdk = 36`, `minSdk = 30`, `applicationId = "kr.sjh.runlini"`, `versionCode = 36010001`, `versionName = "1.0.0"`이다.
- `android/app/build.gradle.kts`의 release build는 현재 `signingConfigs.getByName("debug")`를 사용하므로, 현재 상태 그대로는 Play 제출 전 차단 항목이다.
- `flutter build appbundle --release`는 Agent Company 아키텍트 점검에서 통과했고 `build/app/outputs/bundle/release/app-release.aab`가 생성되어 있다. 단, debug signing 상태라 제출용 산출물로 보지 않는다.
- AAB 내부 네이티브 라이브러리는 아키텍트가 `llvm-readelf`로 LOAD alignment를 확인했고, 제출 전에는 `bundletool` 또는 Play pre-launch 기준으로 split APK 16KB page size 검증을 추가해야 한다.
- `android/local.properties`에는 `GOOGLE_MAPS_API_KEY`, Flutter version fields, SDK 경로가 있고, `android/app/google-services.json`과 `android/wear/google-services.json`이 존재한다.
- 개인정보처리방침 파일이나 URL은 저장소에서 확인되지 않았다. Play 제출 전 공개 URL과 지원 이메일을 확정해야 한다.
- 제출 준비 문서는 `docs/release/google-play-release-readiness.md`에 남긴다.
- 검증은 `flutter analyze`, `flutter test`, `flutter build appbundle --release`, `./gradlew :app:testDebugUnitTest :wear:testDebugUnitTest`, `git diff --check`로 통과했다.
- `flutter build appbundle --release`는 최초 sandbox 안에서 Flutter SDK cache 파일 쓰기 제한으로 실패했고, 승인된 escalated 실행에서 통과했다.
- Agent Company 회의 `20260522T084115Z-google-play-릴리즈-준비-회의-13eddb`는 모든 참여자의 조건부 합의로 닫았다.
- 결정 `20260522T084935Z-decision-aeb496`은 지금 바로 Play 제출하지 않고, release signing과 정책 입력값을 먼저 닫은 뒤 internal testing부터 시작한다는 내용이다.

## 2026-05-22 설정탭 정보 구조 정리 구현

- 사용자는 이전 Agent Company 설정탭 변경 계획대로 개발 진행을 승인했다.
- 구현 목표는 설정탭 단일 홈을 유지하면서 섹션 정보 구조를 정리해 난잡함을 줄이는 것이다.
- 이번 MVP 섹션 기준은 `러닝 추적`, `러닝 화면과 안내`, `기록 목표와 표시`, `내 정보`, `러닝화`, `연동과 백업`, `개인정보 보호`다.
- 새 하위 화면, 검색, 접힘 패널, provider 변경, 저장 구조 변경, Health/Wear 로직 이동, 새 아이콘 체계는 제외한다.
- `러닝화` 섹션명은 이번 MVP에서 유지한다.
- 상단 `조치 필요` 요약 카드는 이번 구현에서 제외한다.
- 기존 작업트리의 `app-store-screenshots.json`, `src/lib/defaults.ts`, `.agent-company/`, `.agents/`, `skills-lock.json` 변경은 이번 요청과 무관하므로 되돌리거나 정리하지 않는다.
- `checklist.md`와 `context-notes.md`는 기존 내용을 보존하고 이번 섹션만 맨 위에 추가한다.
- 구현은 `SettingsTabScreen`의 단일 `ListView`와 기존 provider/key를 유지한 채 섹션 순서와 제목을 바꾸는 방식으로 제한한다.
- `SettingsRunningSection`은 위치 업데이트와 자동 일시정지만 담는 `러닝 추적`으로 줄이고, 기록 레이스 마커와 음성 안내 계열은 같은 파일의 `SettingsRunGuidanceSection`으로 분리한다.
- 거리 단위 선택은 기존 key와 controller 호출을 유지한 채 `SettingsDistanceGoalSection` 안의 `기록 목표와 표시` 패널로 옮겨 목표 입력과 같은 기록 해석 맥락에 둔다.
- 섹션 순서 smoke test는 `settings_tab_information_architecture_test.dart`로 분리해 guardrail의 300라인 제한을 지킨다.
- 검증은 설정 focused tests, 대시보드 탭 전환 테스트, `flutter analyze`, `dart run tool/guardrails.dart`, `git diff --check`로 통과했다.

## 2026-05-22 러닝탭 경쟁레이스 진입점 정리

- 사용자는 러닝탭의 상단 `오늘 추천` 섹션과 START 근처 `경쟁레이스 선택` 버튼이 역할상 중복된다고 보고 Agent Company 토론을 요청했다.
- 회의 결론은 상단 `오늘 추천`은 추천과 발견, START 근처 selector는 선택된 경쟁레이스 상태 확인, 변경, 해제 역할로 분리하는 것이다.
- 사용자 결정은 추천 카드 주 동작을 `이 기록 선택` 즉시 선택으로 하고, 러닝탭 진입 UI 용어는 `경쟁레이스`, 기록 없음 또는 추천 불가 상태는 안내 없이 숨기는 것이다.
- 구현 범위는 러닝탭 시작 전 진입점과 관련 widget tests로 제한한다. DB, repository, provider 저장 구조, 지도/러닝 중 UI는 바꾸지 않는다.
- 현재 작업트리의 `app-store-screenshots.json`, `src/lib/defaults.ts`, `.agent-company/`, `.agents/`, `skills-lock.json` 변경은 이번 요청과 무관하므로 건드리지 않는다.
- `checklist.md`와 `context-notes.md`는 이미 수정된 상태이므로 기존 내용을 보존하고 이번 섹션만 맨 위에 추가한다.
- 구현 결과 추천 있음·미선택 상태에서는 `오늘 추천` 카드만 보이고, `이 기록 선택`은 즉시 선택, `다른 기록`은 기존 선택 시트를 연다.
- 선택 후에는 추천 카드가 사라지고 START 근처 selector가 선택 요약, 변경, 해제를 담당한다.
- 추천이 없거나 추천 provider 오류가 있을 때 선택 가능한 기록이 있으면 selector fallback을 노출하고, 기록 또는 선택 가능한 경로가 없으면 경쟁레이스 UI를 숨긴다.
- 검증은 `dart run tool/guardrails.dart`, `flutter analyze`, 관련 focused widget tests, 전체 `flutter test`로 통과했다.
- Android 실기기 `5200024fee2b2571`에서 debug app 설치와 launch까지 확인했다. 기기 화면이 잠금 상태라 screenshot은 잠금 화면으로 캡처되어 앱 UI 시각 검증은 제한됐다.

## 2026-05-22 Runlini 애니메이션 적용 v1

- 사용자는 이전 에이전트가 작성한 Runlini 애니메이션 적용 계획 v1을 fresh context에서 구현하길 요청했다.
- 이번 작업의 제품 기준은 “달리는 중 즉시 읽힘”이며, 애니메이션은 장식이 아니라 상태 변화, 로딩, 화면 전환을 명확히 하는 용도에 한정한다.
- 스플래시는 계속 정적으로 두고 Lottie, 새 패키지, 전역 라우트 전환 커스터마이징은 추가하지 않는다.
- 새 공통 모션 기준은 앱 UI 공통 계층의 내부 Dart 파일로 두고, 새 파일 첫 줄에는 프로젝트 규칙에 따라 한국어 역할 주석을 넣는다.
- 기존 작업트리의 `app-store-screenshots.json`, `src/lib/defaults.ts`, `.agent-company/`, `.agents/`, `skills-lock.json` 변경은 이번 요청과 무관하므로 건드리지 않는다.
- `checklist.md`와 `context-notes.md` 자체도 이미 수정된 상태였으므로 기존 내용을 보존하고 이번 섹션만 맨 위에 추가한다.
- 구현 범위는 `RunliniMotion` 공통 기준, skeleton shimmer reduce-motion, 카운트다운 fallback, 러닝 탭 컨트롤 전환, 기록 레이스 선택 시트, 히스토리와 상세, 설정 상태 전환이다.
- `AnimatedSize`는 reduce-motion에서 `Duration.zero`만 주면 일부 widget test에서 layout mutation 예외가 나므로, 접힘과 달력 본문은 애니메이션 위젯 자체를 우회한다.
- skeleton shimmer는 무한 `repeat` 대신 짧은 정지 간격이 있는 반복 sweep으로 구현했다. 화면에서는 반복 로딩으로 보이고, widget test의 `pumpAndSettle`은 안정적으로 종료된다.
- 검증은 `dart run tool/guardrails.dart`, `flutter analyze`, focused widget tests, 전체 `flutter test`로 통과했다.
- Android 실기기 `5200024fee2b2571`에는 debug app 설치와 launch까지 확인했다. ADB screenshot은 파일로 저장됐지만 프레임이 검은 화면이라 실제 UI 시각 확인은 완료 증거로 쓰지 않는다.

## 2026-05-21 경쟁레이스 기록선택화면 추천 중심 개편 구현

- 사용자는 확정된 계획을 구현하길 요청했다.
- 확정 결정은 러닝 탭 `오늘 추천` 카드 탭 시 즉시 선택하지 않고 기록선택 시트를 열어, 시트 안 CTA로 확정하는 것이다.
- 후보 카드 접힘 상태에는 작은 route shape 썸네일을 넣지 않고, 경로 가능 배지와 주요 지표만 둔다.
- 경로 부족 기록은 후보 목록에서 숨긴다.
- MVP에서는 현재 추천 로직인 같은 요일 우선, 없으면 최근 기록을 유지한다.
- 기존 작업트리의 `app-store-screenshots.json`, `src/lib/defaults.ts`, `.agent-company/`, `.agents/`, `skills-lock.json` 변경은 이번 구현과 무관하므로 건드리지 않는다.
- 구현은 `openRecordRacePicker` 공용 흐름을 추가해 추천 카드와 기록 레이스 칩이 같은 시트와 선택 확정 로직을 쓰도록 했다.
- `RecordRaceSessionPickerSheet`는 추천 기록을 상단 추천 카드로 보여주고, 선택 가능한 경로 기록만 후보로 노출한다.
- 검증은 focused record race picker/recommendation/flow tests, `flutter analyze`, `git diff --check`로 통과했다.

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

## 2026-05-27 기록 레이스 완료 리뷰 비교 표시 정리

- 사용자는 기록 레이스 완료 직후 상세 리뷰에서 `기록 레이스 비교`가 요약 행만 보이는 문제를 수정하길 원했다.
- 상세 화면은 `RunSessionDetailScreen`에서 원본 기록 레이스 세션을 `runSessionByIdProvider`로 로드해 `RunFinishReviewPanel`에 넘긴다.
- 완료 오버레이인 `RunFinishReviewOverlay`는 현재 원본 기록 레이스 세션을 넘기지 않아 `RunRecordRaceComparisonBuilder`가 `hasCourseMetrics == false` fallback을 사용한다.
- 수정 방향은 완료 오버레이에서도 `recordRaceSummary.recordRaceSessionId` 기준으로 원본 세션을 조회해 패널에 넘기는 것이다.
- `평균 페이스` 차이의 `0:13/km 느림` 표현은 초 단위 한국어로 바꿔 읽기 부담을 줄인다.
- `시작/종료 위치 보호 켜짐` 배지는 사용자가 불필요하다고 판단했으므로 패널에서 제거한다. 경로 자체를 숨기는 설정과 숨김 패널은 유지한다.
- 완료 오버레이는 선택된 기록 레이스 세션이 이미 지도 상태에 있으면 먼저 쓰고, 없으면 `runSessionByIdProvider`로 저장된 원본 세션을 조회한다.
- 검증은 focused widget tests, `dart run tool/guardrails.dart`, `flutter analyze`, `git diff --check`, 전체 `flutter test`로 통과했다.
