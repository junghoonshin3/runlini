# GPS 드리프트 보정 + 자동 일시정지 V2

## Summary

- 정지 중 GPS 튐이 거리/페이스로 누적되는 문제를 줄인다.
- 자동 일시정지/재개는 Settings > 러닝에 추가하고 기본 OFF로 둔다.
- V1은 폰 러닝과 Wear OS 러닝 모두에 적용했다.
- V2는 GPS-only 필터 위에 폰 step evidence와 Wear cadence evidence를 얹는다.

## Decisions

- live marker는 최신 GPS를 따라가지만, 기록/거리/페이스/고스트 계산은 accepted point만 사용한다.
- 자동 일시정지는 elapsed timer와 거리 누적을 함께 멈춘다.
- 수동 일시정지는 자동 재개하지 않는다.
- active run 중 자동 일시정지 설정 변경은 즉시 반영한다.
- 자동 일시정지 상태에서 OFF로 바꾸면 즉시 running으로 돌아가고, 수동 pause는 건드리지 않는다.
- motion evidence가 available이면 stationary lock 이후 재개는 최근 4초 안의 step/cadence 증거가 있어야 한다.
- motion evidence가 unavailable/permission denied이면 기능 실패가 아니라 GPS-only V1 기준으로 fallback한다.

## Progress

- [x] 폰 `Settings > 러닝`에 기본 OFF `자동 일시정지` 토글을 추가했다.
- [x] 폰 러닝에 GPS drift 필터와 자동 pause/resume reason을 추가했다.
- [x] Wear 설정, 폰→워치 설정 payload, Wear JSON store에 `autoPauseEnabled`를 추가했다.
- [x] Wear 러닝 controller에 debug/Health Services sample용 자동 pause/resume detector를 연결했다.
- [x] GPS drift, 자동 pause/resume, settings migration, Wear store/controller 테스트를 추가했다.
- [x] 폰 native motion evidence adapter를 추가했다: Android step detector, iOS pedometer.
- [x] 폰 playback pipeline에 motion window와 stationary-lock gate를 연결했다.
- [x] Wear auto pause detector가 cadence를 resume evidence로 사용하도록 보강했다.
- [x] 폰/워치 자동 일시정지 설정을 active run 중 즉시 반영하도록 수정했다.
- [x] V2 검증 명령을 다시 실행했다.

## Validation

- [x] `dart run tool/guardrails.dart`
- [x] `flutter analyze`
- [x] `flutter test`
- [x] `./gradlew :app:testDebugUnitTest`
- [x] `./gradlew :wear:testDebugUnitTest`
- [x] `./gradlew :app:assembleDebug`
- [x] `./gradlew :wear:assembleDebug`
