# Bottom Sheet No Partial Hang

## Purpose

Keep interval and ghost picker sheets as full-screen sheets that either stay
full-screen or dismiss, without resting at a partial height.

## Progress

- [x] Remove stable partial extents from interval and ghost picker sheets.
- [x] Add tests for pull-down dismiss and short-drag snap-back.
- [x] Run guardrails, analyzer, and tests.
- [x] Move this plan to `archive/completed/`.

## Decisions

- Full-screen means the sheet opens at `1.0` below the status bar safe area.
- There should be no visible 38% resting state.
- Sheet content, settings, and ghost selection behavior stay unchanged.

## Validation

- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed.
- `flutter test` passed.
