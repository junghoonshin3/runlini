# Checklist

## 기록 레이스 완료 팝업 정책 반영

- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] 완료 전 진행률 100% 미표시 정책을 대시보드에 반영한다.
- [x] 완료 결과 팝업 문구와 선택지를 정책에 맞게 바꾼다.
- [x] finish 근처 자동 일시정지 완료 prompt 예외를 추가한다.
- [x] focused widget/provider 테스트를 추가하거나 갱신한다.
- [x] 관련 테스트를 실행한다.
- [x] `flutter analyze`를 실행한다.
- [x] 변경을 하나의 논리 커밋으로 남긴다.

## 스토어 스크린샷 제작

- [x] 앱 이름, 아이콘, 기능 우선순위, 스타일 기준을 로컬 문서와 자산에서 확인한다.
- [x] 스토어 스크린샷 설계 문서를 만든다.
- [x] 구현 계획 문서를 만든다.
- [x] Android 실행 대상과 AVD 상태를 확인한다.
- [x] Android 에뮬레이터에서 앱을 실행하고 대표 화면을 캡처한다.
- [x] 스크린샷 편집기 템플릿을 기존 Flutter 루트 파일을 덮어쓰지 않게 복사한다.
- [x] Runlini 테마, 앱 아이콘, 초기 카피, 캡처 경로를 편집기에 시드한다.
- [x] 의존성을 설치하고 편집기 빌드를 검증한다.
- [x] 로컬 편집기 서버를 실행하고 URL을 정리한다.
- [x] 결과와 남은 리스크를 보고한다.

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

## iOS 전체 UI 테스트

- [x] iOS 디자인 기준과 프로젝트 실행 방법을 확인한다.
- [x] iOS Simulator, runtime, Flutter device 연결 상태를 확인한다.
- [x] 대표 iPhone Simulator를 부팅한다.
- [x] iOS Simulator에서 전체 UI smoke test를 실행한다.
- [x] 실패나 시각 결함이 있으면 실제 오류를 읽고 원인을 정리한다.
- [x] 필요한 최소 수정 또는 테스트 보완을 적용한다.
- [x] 관련 정적 검사나 focused test를 실행한다.
- [x] 검증 결과와 남은 리스크를 정리한다.

## 오늘의 기록 레이스 추천

- [x] 기존 기록 레이스 선택과 러닝 탭 배치 구조를 확인한다.
- [x] 추천 후보 계산 기준을 코드로 분리한다.
- [x] 러닝 탭 시작 전 추천 카드를 추가한다.
- [x] 탭 시 기존 기록 레이스 선택 상태로 연결한다.
- [x] 추천 계산과 UI focused 테스트를 추가한다.
- [x] `dart run tool/guardrails.dart`, `flutter analyze`, 관련 테스트를 실행한다.

## 오늘의 기록 레이스 추천 상단 노출

- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] 추천 카드의 상단 compact 배치를 검증하는 실패 테스트를 추가한다.
- [x] 러닝 탭 추천 카드 위치를 상단으로 옮긴다.
- [x] 추천 카드 시각 밀도를 낮춘다.
- [x] focused widget test와 정적 검사를 실행한다.
- [x] 가능한 범위에서 전체 테스트를 실행한다.
