# Wear Design And History Today

## Purpose

Refine the native Wear OS app UX and change the phone History tab so it opens
on today's run data instead of a recent-records list.

## Context And Orientation

- Wear UI is already split into ready, active pager, paused, review, metric
  components, and formatter files.
- Design identity requires true black, volt green for positive emphasis,
  electric red for destructive or losing states, oversized blunt typography,
  and sharp outlined surfaces.
- History currently treats `selectedDate == null` as "recent records", then
  filters only after a calendar date is selected.

## Progress

- [x] Read repo architecture and design docs.
- [x] Delegate Wear OS UI refinement to Worker 1.
- [x] Delegate History tab today-default behavior to Worker 2.
- [x] Change phone History tab to select and filter today on entry.
- [x] Replace the all-records clear path with a return-to-today action.
- [x] Add focused History widget coverage for today-default filtering.
- [x] Run Worker 2 Flutter guardrails, analyzer, and test validation.
- [x] Integrate worker changes.
- [x] Update tests for final behavior.
- [x] Run validation commands.

## Decisions

- Worker 1 owns `android/wear` UI files and Wear UI tests only.
- Worker 2 owns History tab UI behavior and related Flutter tests only.
- The phone History tab should default to today's date and never use a
  `null` date as the visible recent-records mode.
- The Wear app behavior should remain functionally unchanged for recording,
  Health Services, ghost calculations, draft sync, and Data Layer contracts.

## Implementation Steps

1. Refine Wear UI hierarchy, labels, spacing, and small-screen readability
   using the existing split UI files.
2. Change History tab state so today's date is selected on initial entry.
3. Remove or redirect the "recent/all records" clear path so the list returns
   to today rather than unfiltered records.
4. Keep distance progress, calendar navigation, empty states, refresh, and
   detail navigation intact.
5. Add or update focused tests for Wear UI models/formatters and History
   default filtering.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`

Worker 2 history validation passed:

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

Final integrated validation passed:

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `./gradlew :wear:testDebugUnitTest`
- `./gradlew :wear:assembleDebug`

## Risks Or Recovery

- If round watch layouts become cramped, keep the improved hierarchy but reduce
  copy before changing recording flows.
- If History widget tests rely on "최근 기록", update them to assert today's
  date label and today's filtered sessions instead.
