# Watch App V1 Foundation

## Purpose

Add the phone-side contracts and import path needed for future Wear OS and
watchOS apps to save independent runs into Runlini.

## Context and Orientation

- Runlini's phone local DB remains the UI source of truth.
- Health Connect and HealthKit remain backup / recovery sources.
- Native watch apps will be platform adapters. The shared run contracts live in
  `run_tracking` because they become normal `RunSession` records.

## Progress

- [x] Add watch capture source metadata.
- [x] Add watch snapshot / draft / event contracts.
- [x] Add watch draft to `RunSession` import service.
- [x] Persist watch capture source in local DB.
- [x] Document the watch v1 decisions.
- [x] Run guardrails.
- [x] Run analyzer.
- [x] Run tests.

## Decisions

- `recordSource` keeps its existing sync/import meaning.
- `captureSource` identifies whether the workout was captured by phone GPS,
  Wear OS, or watchOS.
- Watch-origin runs are `recordSource: appLocal` so local save and Health backup
  behavior stays the same.
- v1 watch UI excludes maps, history, charts, shoes, and settings.
- Voice cues are phone-first when the phone is connected; watches guarantee
  haptic and text cues.

## Implementation Steps

1. Extend `RunSession` and local DB persistence with `captureSource`.
2. Add watch run contracts for snapshots, completed drafts, and events.
3. Convert completed watch drafts into local `RunSession` records.
4. Block re-import of locally deleted watch records through existing tombstones.
5. Add tests for JSON contracts, persistence, import, and duplicate handling.

## Validation

- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed.
- `flutter test` passed.

## Risks or Recovery

- Native Wear OS / watchOS modules are not part of this foundation slice.
- If watch platform payloads change later, add fields as optional values and keep
  old JSON fallbacks.
