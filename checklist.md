# Checklist

## 기록 레이스 리네이밍

- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] Dart 도메인, provider, UI, 테스트를 `record_race`로 바꾼다.
- [x] DB와 설정 키 레거시 호환을 추가한다.
- [x] Kotlin Wear/phone 경로와 테스트를 `record_race`로 바꾼다.
- [x] 사용자 문구와 살아 있는 제품 문서를 갱신한다.
- [x] `dart run tool/guardrails.dart`를 실행한다.
- [x] `flutter analyze`를 실행한다.
- [x] `flutter test`를 실행한다.
- [x] `./gradlew :app:testDebugUnitTest`를 실행한다.
- [x] `./gradlew :wear:testDebugUnitTest`를 실행한다.
- [x] `./gradlew :wear:assembleDebug`를 실행한다.

- [x] 실행 계획과 컨텍스트 노트를 만든다.
- [x] TTS 클라이언트가 발화 수락 여부를 반환하도록 바꾼다.
- [x] 음성 안내 우선순위와 고스트 긴급 cue 매핑을 추가한다.
- [x] 음성 안내 dispatcher를 추가하고 화면 호출부를 교체한다.
- [x] fake와 테스트를 갱신한다.
- [x] focused test를 실행한다.
- [x] `dart run tool/guardrails.dart`를 실행한다.
- [x] `flutter analyze`를 실행한다.
- [x] `flutter test`를 실행한다.
- [x] 에뮬레이터 cold start 스크린샷으로 로고 잘림이 사라졌는지 확인한다.

## Android 12 스플래시 이미지 잘림 수정

- [x] 기존 Android 스플래시 설정과 리소스를 확인한다.
- [x] Android 12+ 전용 safe-area 스플래시 PNG를 생성한다.
- [x] Android 12+ LaunchTheme이 새 스플래시 PNG를 사용하도록 바꾼다.
- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] Android debug build를 실행한다.
- [x] `dart run tool/guardrails.dart`를 실행한다.
- [x] `flutter analyze`를 실행한다.
- [x] `flutter test`를 실행한다.

## 설정 폰 음성 테스트 제거

- [x] 설정 러닝 섹션에서 폰 음성 테스트 버튼을 제거한다.
- [x] 전용 테스트 버튼 위젯과 테스트 파일을 삭제한다.
- [x] 관련 문서와 컨텍스트 노트를 갱신한다.
- [x] focused test를 실행한다.
- [x] `dart run tool/guardrails.dart`를 실행한다.
- [x] `flutter analyze`를 실행한다.
- [x] `flutter test`를 실행한다.

## 인터벌 기능 임시 잠금

- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] 인터벌 잠금 상수와 런타임 비활성 처리를 추가한다.
- [x] 러닝 탭 인터벌 버튼이 안내 문구만 띄우도록 바꾼다.
- [x] 고스트 충돌과 워치 동기화가 잠긴 인터벌을 비활성으로 취급하도록 바꾼다.
- [x] 테스트와 문서를 갱신한다.
- [x] `dart run tool/guardrails.dart`를 실행한다.
- [x] `flutter analyze`를 실행한다.
- [x] `flutter test`를 실행한다.

## 메인 화면 디자인 점검

- [x] 메인 화면 진입점과 기본 탭을 확인한다.
- [x] 디자인 기준과 기존 테마, 컴포넌트를 확인한다.
- [x] 현재 기록 홈 화면을 렌더링해 관찰한다.
- [x] 문제를 3개 이하로 좁히고 최소 UI 개선을 적용한다.
- [x] 관련 테스트와 분석을 실행한다.
- [x] 검증 결과와 남은 리스크를 정리한다.
- [x] Android 에뮬레이터에서 빈 기록 패널 폭을 확인하고 조정한다.

## 홈 화면 디자인 재점검

- [x] 홈 화면 진입점과 기본 기록 탭 구조를 확인한다.
- [x] Android와 Flutter 실행 대상 연결 상태를 확인한다.
- [x] 모바일 폭에서 홈 기록 탭 렌더링을 관찰한다.
- [x] 문제를 3개 이하로 좁히고 최소 UI 개선을 적용한다.
- [x] 관련 위젯 테스트와 `flutter analyze`를 실행한다.
- [x] 검증 결과와 남은 리스크를 정리한다.

## 홈 화면 UI 개선

- [x] 홈 화면 진입점과 기존 디자인 토큰을 확인한다.
- [x] Android, Flutter 실행 대상과 AVD 상태를 확인한다.
- [x] 홈 기록 탭의 개선 범위를 3개 이하로 좁힌다.
- [x] 기존 패턴 안에서 홈 기록 탭과 하단 내비게이션을 최소 수정한다.
- [x] 관련 focused 테스트를 실행한다.
- [x] `flutter analyze`를 실행한다.
- [x] 가능한 화면 실행 검증을 수행하고 결과를 정리한다.

## 전체 화면 실제 UI 테스트

- [x] 앱 화면 인벤토리와 조건부 화면을 코드 기준으로 확인한다.
- [x] Android, Flutter 실행 대상과 AVD 상태를 확인한다.
- [x] 실제 Android 에뮬레이터에서 실행되는 UI smoke test를 추가한다.
- [x] 주요 탭, 상세 화면, 설정 하위 화면, 시트, 다이얼로그를 테스트에서 연다.
- [x] 에뮬레이터에서 전체 화면 UI 테스트를 실행한다.
- [x] 실패나 시각 결함이 있으면 최소 수정한다.
- [x] `flutter analyze`와 관련 테스트를 실행한다.
- [x] 검증 결과와 남은 리스크를 정리한다.
