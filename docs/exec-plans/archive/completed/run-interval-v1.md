# Runlini 인터벌 러닝 V1

## Summary
- 폰에서 간단 반복 인터벌을 설정하고 폰/워치 러닝 중 현재 단계와 다음 단계를 안내한다.
- V1은 `워밍업 -> 질주/휴식 반복 -> 쿨다운` 구조로 제한한다.
- 완료 기록은 기존 `RunSession` 그대로 저장하고, 단계별 분석/랩 저장은 후속으로 둔다.

## Decisions
- 기본값은 기능 OFF 상태로 저장하되 값은 `워밍업 5분 / 질주 1분 / 휴식 1분 / 8회 / 쿨다운 5분`이다.
- 내부 단계 목표는 호환을 위해 `time`, `distance`, `open`, `skip`을 지원하고, V1 사용자 UI는 질주/휴식의 `시간 | 거리` 선택, 직접 입력, 워밍업/쿨다운 토글을 노출한다.
- 폰은 Running 탭 왼쪽 하단 인터벌 버튼에서 bottom sheet로 설정하고, 러닝 중 현재 단계 pill을 보여준다.
- 폰 인터벌 bottom sheet는 프리셋/옵션칩 없이 직접 입력 전용으로 유지한다.
- Running 탭의 설정 이동 버튼은 제거하고, 설정 탭은 앱 하단 내비게이션의 설정 화면으로만 접근한다.
- 인터벌 바텀시트는 고스트 기록 선택 시트와 같은 `DraggableScrollableSheet` 패턴을 사용한다.
- 인터벌/고스트 선택 바텀시트는 fullscreen으로 열되 status bar 아래 safe area부터 시작한다.
- 워치는 Data Layer로 받은 설정을 로컬 저장하고, Ready 설정 화면에서 인터벌 ON/OFF, 질주/휴식 시간·거리, 반복 횟수를 `- / +` stepper로 직접 조정한다.
- 고스트와 인터벌을 동시에 켤 수 있지만, 러닝 화면의 짧은 상태 안내는 인터벌을 우선한다.
- 폰은 직접 입력을 허용하고, 워치는 작은 화면에 맞춰 `- / +` stepper 직접 조정을 사용한다.
- 워치 러닝 중 인터벌 hero는 `남은 시간/거리` 라벨과 값(`30초`, `250m`)을 분리하고 ellipsis를 쓰지 않는다.
- Open 인터벌과 복잡한 자유 단계 편집은 Apple Watch/COROS식 고급 커스텀 워크아웃 영역으로 보고 후속 범위로 둔다.

## Checklist
- [x] Dart interval model/calculator
- [x] Settings persistence and Running tab sheet
- [x] Phone live interval guidance
- [x] Phone interval bottom sheet UI redesign
- [x] Phone interval bottom sheet open crash stabilization
- [x] Phone interval V1 simplification and Running tab button placement
- [x] Phone interval bottom sheet ghost-picker interaction alignment
- [x] Phone interval and ghost picker fullscreen safe-area alignment
- [x] Phone interval time/distance target controls
- [x] Phone interval direct input for time and distance targets
- [x] Phone interval direct-input-only simplification
- [x] Phone -> Wear Data Layer sync
- [x] Wear interval store/reducer/UI
- [x] Wear interval quick settings with time/distance targets
- [x] Wear interval direct stepper adjustment: time 10s, distance 50m
- [x] Wear interval active hero text split to avoid truncation
- [x] Tests and validation

## Validation
- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`
