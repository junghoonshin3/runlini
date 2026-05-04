# Run Detail Primary Metrics Placement

## Summary

- 기록 상세 화면에서 거리, 시간, 평균 페이스를 헤더 칩이 아니라 metric
  grid 영역에 배치한다.
- 적용 범위는 기록 상세 화면만이다. 러닝 종료 직후 리뷰 화면은 기존
  정보량을 유지한다.

## Decisions

- 상세 화면 헤더는 `RUNLINI RECORD`, `Run Detail`, 날짜만 보여준다.
- 거리, 시간, 평균 페이스는 평균 속도, 칼로리, 고도, 심박수, 신발과
  같은 metric grid 안에서 보여준다.
- `앱에만 저장됨` 같은 동기화 상태 섹션은 상세 콘텐츠 하단에 배치한다.
- app-local 기록이 아직 Health에 저장되지 않았으면 상세 하단에서
  `Health Connect로 보내기` / `건강 앱으로 보내기` 액션을 제공한다.
- 공용 `RunFinishReviewPanel`은 기본 동작을 유지하고, 상세 화면에서만
  header summary chip을 숨기는 옵션을 사용한다.

## Validation

- [x] `dart run tool/guardrails.dart`
- [x] `flutter analyze`
- [x] `flutter test`
