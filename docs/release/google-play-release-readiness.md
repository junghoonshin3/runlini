# Google Play 릴리즈 준비 상태

작성일은 2026-05-22이다.

## 결론

Runlini는 로컬에서 Android App Bundle 생성과 release signing이 가능하다.

기술적으로는 release AAB를 만들 수 있지만, Play Console에 올리기 전에는 Play App Signing 설정, upload key 백업, 개인정보처리방침 URL, Data safety, App content, 계정 production access 상태를 먼저 닫아야 한다.

## 로컬 확인 결과

- Phone 앱은 `compileSdk = 36`, `targetSdk = 36`, `minSdk = 26`, `applicationId = "kr.sjh.runlini"`이다.
- Wear 모듈은 `compileSdk = 36`, `targetSdk = 36`, `minSdk = 30`, `applicationId = "kr.sjh.runlini"`이다.
- Phone 버전은 `pubspec.yaml`의 `1.0.0+1`을 따른다.
- Wear 버전은 `versionCode = 36010001`, `versionName = "1.0.0"`이다.
- `flutter build appbundle --release`가 통과했고 `build/app/outputs/bundle/release/app-release.aab`가 생성됐다.
- Phone과 Wear release variant는 `android/app/upload-keystore.jks`의 `upload` alias로 signing 된다.
- `android/key.properties`와 `android/app/upload-keystore.jks`는 로컬 비밀 파일이며 git에 커밋하지 않는다.
- `android/app/google-services.json`, `android/wear/google-services.json`, `GOOGLE_MAPS_API_KEY` 설정 키가 존재한다.
- 개인정보처리방침 URL은 저장소에서 확인되지 않았다.

## 공식 요구사항 기준

- Google Play의 새 앱과 앱 업데이트는 Android 15, API 35 이상을 target 해야 한다.
- Wear OS 새 앱과 업데이트는 Android 14, API 34 이상을 target 해야 한다.
- Android 15 이상 대상 제출은 2025-11-01부터 16KB page size 지원 요구사항을 만족해야 한다.
- 신규 개인 개발자 계정이면 production access 신청 전 최소 12명 테스터가 14일 연속 closed test에 opt-in 해야 한다.
- Data safety 답변은 개발자가 실제 데이터 처리 기준으로 정확하게 작성해야 한다.

공식 문서.

- Google Play target API 요구사항. https://support.google.com/googleplay/android-developer/answer/11926878
- Google Play Data safety. https://support.google.com/googleplay/android-developer/answer/10787469
- 신규 개인 개발자 계정 테스트 요구사항. https://support.google.com/googleplay/android-developer/answer/14151465
- Android 16KB page size 요구사항. https://developer.android.com/guide/practices/page-sizes
- Flutter Android release build와 app bundle. https://docs.flutter.dev/deployment/android

## 제출 전 차단 항목

- Play App Signing 사용 여부와 upload key 백업 위치를 확정한다.
- 개인정보처리방침 URL과 지원 이메일을 확정한다.
- Phone과 Wear를 같은 Play 앱 패키지로 함께 배포할지, phone 중심으로 먼저 배포할지 결정한다.
- Data safety와 App content 답변을 실제 구현 기준으로 작성한다.
- AAB에서 생성되는 split APK를 기준으로 16KB page size 검증을 완료한다.

## Data Safety 초안 범위

Runlini는 다음 데이터를 실제 구현 기준으로 확인해 Play Console에 반영해야 한다.

- 위치 데이터와 백그라운드 위치.
- 러닝 경로, 거리, 페이스, 운동 시간, 운동 기록.
- Health Connect의 걸음, 심박, 거리, 칼로리, 운동, 운동 경로 읽기와 쓰기.
- 활동 인식과 foreground service location 사용.
- 사용자가 입력한 체중, 러닝화 정보, 설정값.
- Firebase Crashlytics 또는 Google 서비스가 수집하는 진단 데이터.
- Wear OS 기기와 phone 사이에 전송되는 운동 draft, 설정, 기록 데이터.

## 권장 제출 순서

1. Upload key를 안전한 위치에 백업하고 Play App Signing 절차를 확정한다.
2. 개인정보처리방침 URL, 지원 이메일, 기본 등록 언어, 출시 국가, 첫 트랙을 확정한다.
3. Data safety, App content, 권한 사용 사유, Health Connect 설명을 작성한다.
4. `flutter analyze`, `flutter test`, Android unit tests, release build, 16KB 검증을 통과시킨다.
5. Internal testing 트랙에 먼저 업로드해 설치, 권한, 러닝 기록, Health Connect, Wear 연동을 검증한다.
6. 신규 개인 개발자 계정이면 closed testing 12명, 14일 연속 opt-in을 완료한 뒤 production access를 신청한다.
7. Production은 제한된 staged rollout로 시작하고 crash, ANR, 정책 경고, 데이터 손상 제보를 기준으로 확대한다.

## 사용자 확인 필요 항목

- Play Console 계정이 조직 계정인지 개인 계정인지.
- 개인 계정이라면 2023-11-13 이후 생성됐는지.
- production access가 이미 승인되어 있는지.
- 기본 등록 언어를 영어로 할지 한국어로 할지.
- 개인정보처리방침 URL, 지원 이메일, 웹사이트.
- 첫 출시 국가와 첫 배포 트랙.
- Phone만 먼저 제출할지 Wear companion까지 함께 제출할지.
- Crashlytics와 Health, 위치 데이터가 서버 또는 외부 서비스로 전송되는 정확한 범위.
