# Runlini

Runlini는 실시간 러닝 기록, 과거 기록과의 기록 레이스, 기록 분석,
Health Connect와 건강 앱 연동을 한 흐름으로 다루는 Flutter 러닝 앱입니다.
앱의 핵심 질문은 간단합니다.

> 지금 내가 이전 기록보다 앞서고 있는가?

## Demo

<video src="docs/assets/runlini-app-screen-recording-20260525.mov" controls width="360"></video>

[Runlini 앱 구동 화면 보기](docs/assets/runlini-app-screen-recording-20260525.mov)

이 영상은 macOS 화면 기록 도구로 실제 Android 에뮬레이터에서 촬영했습니다.

## 주요 기능

- **라이브 러닝** - GPS 기반 거리, 시간, 평균 페이스, 평균 속도, 칼로리,
  현재 위치, 시작 전 카운트다운, 일시정지와 저장 흐름을 제공합니다.
- **기록 레이스** - 이전 러닝 기록을 선택해 현재 기록과 실시간으로 비교하고,
  앞섬과 뒤처짐, 거리 차이, 경로 이탈 상태를 보여줍니다.
- **기록 홈** - 주간, 월간, 연간 목표 진행률과 달력 기반 기록 목록을
  한 화면에서 확인합니다.
- **상세 분석** - 저장된 러닝의 경로, 스플릿, 페이스, 속도, 고도, 심박,
  러닝화, Health 백업 상태를 확인합니다.
- **Health 연동** - Android는 Health Connect, iOS는 건강 앱을 통해 러닝 기록을
  가져오거나 백업합니다.
- **설정과 러닝화 관리** - 거리와 페이스 단위, 목표 거리, 위치 추적 품질,
  음성 안내, 개인정보 표시, 러닝화 교체 기준을 관리합니다.

## 기술 구성

- Flutter와 Dart 기반의 iOS, Android 앱입니다.
- Riverpod으로 화면 상태와 사용자 의도를 관리합니다.
- sqflite로 로컬 러닝 기록과 설정을 저장합니다.
- Android는 Google Maps, iOS는 Apple Maps를 사용합니다.
- `health` 패키지로 Health Connect와 HealthKit 경계를 다룹니다.
- Wear OS 연동은 공유 contract와 phone import 흐름을 기준으로 확장합니다.

## 시작하기

Flutter SDK와 Android 또는 iOS 실행 대상이 필요합니다.

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

Android 지도 실행에는 Google Maps API key가 필요합니다.

```properties
GOOGLE_MAPS_API_KEY=your_key_here
```

위 값을 `android/local.properties`에 추가합니다. iOS는 Apple Maps를 사용하므로
별도 지도 API key가 필요하지 않습니다.

## 검증

CI와 로컬 개발에서 같은 순서로 확인합니다.

```bash
dart run tool/guardrails.dart
flutter analyze
flutter test
```

`tool/guardrails.dart`는 필수 문서, feature layer 의존성, Dart 파일 길이 제한을
검사합니다.

## 프로젝트 구조

- `lib/app` - 앱 부트스트랩, 테마, 전역 UI 규칙을 둡니다.
- `lib/core` - 지도, 위치, Health, Wear, 이미지 저장 같은 외부 경계를 둡니다.
- `lib/features` - 제품 도메인을 `types`, `repo`, `service`, `state`, `ui` 계층으로
  나눕니다.
- `docs` - 제품, 디자인, 플랫폼, 테스트, 릴리즈 문서를 둡니다.
- `tool` - 로컬과 CI에서 실행하는 구조 검증 도구를 둡니다.

자세한 계층 규칙은 [ARCHITECTURE.md](ARCHITECTURE.md)를 기준으로 합니다.

## 주요 문서

- [제품 우선순위](docs/product-specs/runlini-feature-priorities.md)
- [단계별 로드맵](docs/product-specs/phase-roadmap.md)
- [플랫폼 권한](docs/platform/permissions.md)
- [Watch 연동](docs/platform/watch-integration.md)
- [필드 테스트 프로토콜](docs/testing/field-test-protocol.md)
- [Git 작업 흐름](docs/development/git-workflow.md)

## 개발 원칙

- 제품과 설계 결정은 `docs`에 남깁니다.
- 구조 변경은 `ARCHITECTURE.md`와 guardrails를 통과해야 합니다.
- 러닝 기록은 로컬 DB 기록을 사용자에게 보이는 단일 source of truth로 둡니다.
- Health 백업 실패는 저장 실패가 아니라 별도 동기화 상태로 다룹니다.
- 새 기능은 실제 러닝 흐름을 막지 않는 fallback을 먼저 갖춰야 합니다.
