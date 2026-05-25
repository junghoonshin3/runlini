# 고스트런 Pause/Resume 앱 종료 방어

## Summary

- 폰 고스트런에서 수동 일시정지 중에는 고스트 완료 판정을 보류한다.
- 재개 후 새 위치/프레임이 들어오면 기존 완료 조건을 다시 평가한다.
- 고스트 완료 진동과 TTS는 실패해도 앱을 종료시키지 않고 debug 로그만 남긴다.

## Decisions

- 고스트 완료 팝업 UX와 완료 조건 수식은 유지한다.
- `RunScreenStatus.running` 상태에서만 완료 후보/확정을 반영한다.
- TTS/Haptic side effect는 best-effort로 처리하고 예외는 삼킨다.

## Validation

- pause 중 completion update 무시, resume 후 completion prompt 표시 회귀 테스트를 추가한다.
- `dart run tool/guardrails.dart`, `flutter analyze`, `flutter test`로 검증한다.
