# Watch Record Import Connection Status

## Purpose

Rename the manual Wear action to `워치 기록 가져오기` and use watch connection
status to make Settings feedback clearer without blocking already-received
phone inbox imports.

## Progress

- [x] Add watch connection client and Android channel.
- [x] Update Settings Wear card wording and messages.
- [x] Update docs and tests.
- [x] Run validation.
- [x] Move this plan to `archive/completed/`.

## Decisions

- Connection status is advisory, not a hard import precondition.
- Pending drafts already stored on the phone can be imported while disconnected.
- Recent ghost route refresh stays best-effort behind the manual action.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :app:testDebugUnitTest`
