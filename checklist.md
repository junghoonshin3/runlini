# Checklist

## START 하단 컨트롤 종료 애니메이션

- [x] 새 브랜치를 생성한다.
- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] `RunningTabScreen`의 프리런 하단 컨트롤 묶음에 종료 애니메이션을 적용한다.
- [x] START 수락 직후 outgoing 컨트롤의 입력과 semantics action을 차단한다.
- [x] 카운트다운 overlay 즉시 표시, exit 완료, reduce motion, 실패 후 idle 복귀 테스트를 보강한다.
- [x] focused tests, `flutter analyze`, guardrails, diff 검사를 실행한다.
- [x] 가능한 Android 실행 대상에서 대표 화면을 확인한다.
- [x] 변경을 하나의 논리 커밋으로 남긴다.

## 러닝 집중 상태 하단탭 숨김

- [x] 별도 브랜치를 생성한다.
- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] `RunliniHomeScreen`에서 러닝 집중 상태 하단탭을 숨긴다.
- [x] 러닝 중 컨트롤 하단 SafeArea 여백을 보정한다.
- [x] 카운트다운, 러닝 중, 일시정지, 종료 검토, 기록 레이스 완료 테스트를 보강한다.
- [x] push 전체 화면의 앱 하단탭 부재 테스트를 보강한다.
- [x] focused tests, `flutter analyze`, guardrails, 전체 테스트를 실행한다.
- [x] 변경을 하나의 논리 커밋으로 남긴다.

## Google Play 스토어 스크린샷 제작

- [x] 기존 스크린샷 에디터, 앱 아이콘, Android 에뮬레이터 상태를 확인한다.
- [x] Android 에뮬레이터에서 실제 앱 주요 화면을 캡처한다.
- [x] Google Play 한국어 스크린샷 덱을 실제 캡처와 추천 카피로 seed한다.
- [x] 에디터 실행과 export 준비 상태를 확인한다.
- [x] 변경을 검증하고 커밋한다.

## 러닝탭 기록레이스 상단 카드 복구

- [x] 현재 기록레이스 카드 노출 조건과 최근 변경 원인을 확인한다.
- [x] 러닝 전 상단 카드가 선택, 추천, fallback, empty, loading, error 상태를 처리하게 바꾼다.
- [x] START 근처 하단 기록레이스 칩 노출을 제거한다.
- [x] 관련 widget tests를 새 상단 카드 정책에 맞게 갱신한다.
- [x] focused tests, analyzer, guardrails를 실행한다.
- [x] 변경을 커밋한다.

## README 인라인 데모 재생 개선

- [x] README의 기존 `.mov` 링크가 다운로드 흐름이 되는 문제를 확인한다.
- [x] 최신 화면 기록 MOV에서 README용 GIF 프리뷰를 생성한다.
- [x] README가 GIF를 직접 렌더링하고 원본 MOV는 보조 링크로 제공하게 수정한다.
- [x] GIF 파일, README 링크, diff 공백을 검증한다.
- [x] 변경을 커밋하고 push한다.

## README 화면 기록 영상 갱신

- [x] 최근 화면 기록 파일과 원격 README 상태를 확인한다.
- [x] 최신 화면 기록 파일을 `docs/assets`에 추가한다.
- [x] README 데모 섹션을 최신 영상으로 다시 연결한다.
- [x] 영상 링크와 문서 diff를 검증한다.
- [x] 변경을 커밋한다.

## Runlini README 재작성

- [x] 현재 README와 제품, 아키텍처, 플랫폼 문서를 확인한다.
- [x] README를 실제 Runlini 기능과 개발 흐름 기준으로 재작성한다.
- [x] 데모 영상 링크와 주요 문서 링크가 유효한지 확인한다.
- [x] 문서 diff 공백 검사를 실행한다.
- [x] 변경을 커밋한다.

## CI guardrails 파일 길이 실패 수정

- [x] 최신 GitHub Actions 실패 로그와 로컬 guardrails 실패를 확인한다.
- [x] 300줄 초과 UI 파일을 의미 단위 part 파일로 분리한다.
- [x] 300줄 초과 테스트 파일 3개를 의미 단위로 분리한다.
- [x] 분리된 파일과 원본 파일이 모두 300줄 이하인지 확인한다.
- [x] CI Flutter stable의 ListTile Material assertion을 수정한다.
- [x] 관련 focused tests, guardrails, analyzer, 전체 테스트를 실행한다.
- [x] 파일 분리 변경을 커밋하고 push한다.
- [x] CI assertion 보강 변경을 커밋하고 push한다.

## 경쟁레이스 완료 판정 finish corridor 우선 정책 구현

- [x] Agent Company 구현 회의를 시작하고 역할별 검토를 병렬 요청한다.
- [x] 현재 Dart와 Wear 완료 판정 코드와 테스트를 확인한다.
- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] Dart `RecordRaceCompletionDetector`의 하드 차단과 finish 후보 판정 순서를 조정한다.
- [x] Wear `WearRecordRaceCompletionDetector`도 같은 정책으로 맞춘다.
- [x] Dart와 Kotlin detector 테스트를 추가하거나 갱신한다.
- [x] focused tests와 `flutter analyze`를 실행한다.
- [x] Agent Company 회의를 닫고 결정 기록을 남긴다.
- [x] 변경을 하나의 논리 커밋으로 남긴다.

## 경쟁레이스 진행률 99% 고정 정책 폐기

- [x] 99% 고정 표시 정책 참조 위치를 확인한다.
- [x] 경쟁레이스 진행률 표시가 실제 route progress를 그대로 반영하게 바꾼다.
- [x] 완료 전 100% 표시를 허용하도록 위젯 테스트를 갱신한다.
- [x] focused test와 `flutter analyze`를 실행한다.
- [x] 변경을 커밋하고 남은 리스크를 정리한다.

## Release signing 구성

- [x] 현재 Android signing 설정과 ignore 규칙을 확인한다.
- [x] release signing 작업 범위와 비밀 파일 정책을 기록한다.
- [x] Android release signing 비밀 파일 ignore 적용을 확인한다.
- [x] phone과 wear release build가 upload key signing을 쓰도록 설정한다.
- [x] 로컬 upload keystore와 `android/key.properties`를 생성한다.
- [x] release build와 signing report를 검증한다.
- [x] 변경을 커밋하고 남은 Play Console 액션을 정리한다.

## Google Play 릴리즈 준비

- [x] Agent Company 릴리즈 준비 회의를 시작하고 역할별 점검을 병렬 요청한다.
- [x] 공식 Google Play 요구사항을 확인한다.
- [x] Android target SDK, signing, version, permission 설정을 확인한다.
- [x] Play Console App content와 Data safety에 필요한 항목을 정리한다.
- [x] 내부 테스트와 비공개 테스트 전략을 정리한다.
- [x] release app bundle 빌드 가능 여부를 확인한다.
- [x] Google Play 제출 준비 문서를 작성한다.
- [x] 출시 전 focused tests와 정적 검사를 실행한다.
- [x] 릴리즈 회의를 닫고 결정 기록을 남긴다.
- [x] 실제 업로드 전 사용자 확인 질문과 다음 액션을 정리한다.

## 설정탭 정보 구조 정리 구현

- [x] Agent Company 구현 회의를 시작하고 역할별 검토를 병렬 요청한다.
- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] 현재 설정탭 코드와 관련 테스트를 확인한다.
- [x] 러닝 설정을 `러닝 추적`과 `러닝 화면과 안내`로 분리한다.
- [x] 기록 표시와 기록 목표를 `기록 목표와 표시` 흐름으로 정리한다.
- [x] 나머지 섹션명을 `내 정보`, `러닝화`, `연동과 백업`, `개인정보 보호` 기준으로 정리한다.
- [x] 섹션 순서와 기존 설정 조작 흐름을 검증하는 테스트를 갱신한다.
- [x] 관련 focused tests와 `flutter analyze`를 실행한다.
- [x] Agent Company 회의를 닫고 결정 기록을 남긴다.
- [x] 변경을 하나의 논리 커밋으로 남긴다.

## 러닝탭 경쟁레이스 진입점 정리

- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] 추천 있음·미선택 상태에서 오늘 추천만 주 진입점으로 남긴다.
- [x] 추천 카드의 `이 기록 선택` 즉시 선택과 `다른 기록` picker 진입을 구현한다.
- [x] 선택됨 상태에서 selector가 요약, 변경, 해제 역할만 하게 정리한다.
- [x] 추천 없음·선택 가능 기록 있음 fallback과 기록 없음 숨김 상태를 테스트한다.
- [x] focused widget tests와 정적 검사를 실행한다.
- [x] 전체 `flutter test`를 실행한다.
- [x] 가능한 Android 실행 대상에서 대표 화면을 확인한다.
- [x] 변경을 하나의 논리 커밋으로 남긴다.

## Runlini 애니메이션 적용 v1

- [x] 애니메이션 정책 문서와 실행 계획을 추가한다.
- [x] 공통 `RunliniMotion` 기준을 추가한다.
- [x] 스켈레톤 shimmer와 카운트다운이 공통 모션과 reduce-motion 기준을 쓰게 한다.
- [x] 러닝 탭 시작 전후, 라이브 대시보드, pause/resume/stop 상태 전환에 공통 모션을 적용한다.
- [x] 기록 레이스 선택 시트의 카드 확장과 route preview 로딩 전환을 정리한다.
- [x] 기록 홈, 히스토리 달력, 상세 route preview, 설정 sync status 로딩 전환에 공통 모션을 적용한다.
- [x] focused widget tests를 보강하고 실행한다.
- [x] `dart run tool/guardrails.dart`, `flutter analyze`, `flutter test`를 실행한다.
- [x] 변경을 논리 단위로 커밋한다.

## 경쟁레이스 기록선택화면 추천 중심 개편 구현

- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] 선택 시트 테스트를 추천 기본 확장, 경로 부족 숨김, 빈 상태 기준으로 갱신한다.
- [x] 추천 카드 테스트를 시트 진입 후 CTA 확정 흐름으로 갱신한다.
- [x] 선택 가능한 기록 필터와 추천 메타데이터를 선택 시트에 반영한다.
- [x] 러닝 탭 추천 카드와 기록 레이스 칩이 같은 선택 흐름을 쓰도록 정리한다.
- [x] focused 테스트와 `flutter analyze`를 실행한다.
- [x] 변경을 하나의 논리 커밋으로 남긴다.

## 경쟁레이스 기록선택화면 개편 방향 논의

- [x] 기존 기록 레이스 기록 선택 화면과 추천 카드 맥락을 확인한다.
- [x] 리서치 담당자에게 외부 경쟁·세그먼트 선택 사례와 시사점을 요청한다.
- [x] UI/UX 디자이너에게 화면 구조와 상호작용 개편안을 요청한다.
- [x] 서비스 기획자에게 MVP 범위와 우선순위 결론을 요청한다.
- [x] 세 역할 결과의 합의, 이견, 추천안을 회의 기록으로 남긴다.
- [x] 사용자에게 개편 방향과 다음 액션을 보고한다.

## 기록 레이스 완료 팝업 정책 반영

- [x] 실행 계획과 컨텍스트 노트를 갱신한다.
- [x] 완료 전 진행률 100% 미표시 정책을 대시보드에 반영했다. 이후 `경쟁레이스 진행률 99% 고정 정책 폐기`로 supersede 했다.
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

## 기록 레이스 완료 리뷰 비교 표시 정리

- [x] 완료 리뷰와 기록 레이스 비교 데이터 흐름을 실제 코드로 확인한다.
- [x] 완료 리뷰 오버레이가 원본 기록 레이스 세션을 비교 카드에 전달하게 한다.
- [x] 평균 페이스 차이 문구를 자연스러운 한국어 표현으로 바꾼다.
- [x] 시작/종료 위치 보호 배지를 완료 리뷰/상세 패널에서 제거한다.
- [x] 관련 widget test를 추가 또는 갱신한다.
- [x] focused test를 실행한다.
- [x] `dart run tool/guardrails.dart`를 실행한다.
- [x] `flutter analyze`를 실행한다.
- [x] `git diff --check`를 실행한다.
- [x] 전체 `flutter test`를 실행한다.
