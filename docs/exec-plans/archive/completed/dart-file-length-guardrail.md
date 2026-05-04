# Dart File Length Guardrail

## Purpose

Make 300 lines the hard maximum for Dart source files and split current files
that exceed the limit.

## Context and Orientation

- Guardrails now fail for Dart files over 300 lines in `lib`, `test`, and `tool`.
- Map, running UI, run playback state, large widget tests, large provider tests,
  and the emulator GPS tool have been split below the limit.
- The new rule should fail fast so future work splits files before they grow.

## Progress

- [x] Split current Dart files over 300 lines.
- [x] Change guardrails from warning to error for over-300-line Dart files.
- [x] Document the hard 300-line limit in `AGENTS.md`.
- [x] Run formatting, guardrails, analysis, and tests.

## Decisions

- Keep 300 lines as the hard maximum.
- Keep the existing layered architecture intact while splitting files.
- Preserve existing public provider imports through the run playback provider
  facade.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
