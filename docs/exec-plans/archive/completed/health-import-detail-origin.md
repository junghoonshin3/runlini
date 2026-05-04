# Health Import Detail Origin

## Summary

- Health Connect / 건강 앱 권한이 있으면 기록을 가져올 때 Health 기록도 함께
  조용히 가져온다.
- 기록 목록은 앱 기록과 Health 기록을 분리해 보이게 만들지 않고 하나의
  히스토리로 보여준다.
- 출처와 Health 전송 상태는 기록 상세 하단에서만 확인한다.

## Changes

- History tile에서 Health/source badge를 숨긴다.
- Detail sync section의 기존 origin/status badge는 유지한다.
- Platform permission docs에 목록/상세 출처 표시 정책을 적는다.

## Validation

- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed.
- `flutter test` passed.
