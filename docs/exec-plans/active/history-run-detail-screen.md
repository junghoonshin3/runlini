# History Run Detail Screen

## Purpose

Let runners open a saved run from the history tab and inspect the same detailed
post-run view used after finishing a workout.

## Context And Orientation

- The history tab currently renders `RunSessionSummaryTile` rows from
  `runSessionSummaryListProvider`.
- The post-run review panel already calculates and displays distance, time,
  pace, speed, elevation, heart-rate placeholders, route preview, charts, and
  splits from a full `RunSession`.
- History detail should be read-only: no save/discard controls.

## Progress

- [x] Inspect the history list and finish review widgets.
- [x] Add navigation from a history row to a read-only detail screen.
- [x] Reuse the existing detailed run body without duplicating calculations.
- [x] Add widget coverage for opening and closing the detail screen.
- [x] Update product docs.
- [x] Run guardrails, analyze, and tests.
- [x] Add a pace-over-time chart to the detail body.
- [x] Re-run guardrails, analyze, and tests after the pace chart update.
- [x] Add saved-record deletion from the history detail screen.
- [x] Re-run guardrails, analyze, and tests after the delete update.
- [x] Redesign the shared detail body away from the reference-app layout.
- [x] Replace custom chart bars with `fl_chart` line charts over elapsed time.

## Decisions

- Pass the selected `RunSession` directly from the history list into the detail
  screen instead of re-fetching by id.
- Keep the finish review panel as the shared detail body, but make its bottom
  save/discard action slot optional.
- Use the top-left close button as the history detail back control.
- The detail pace chart uses `RunPoint.paceSecPerKm` when available and derives
  segment pace from GPS distance/time when it is not.
- Faster pace values render taller bars because lower seconds-per-kilometer is
  better for pace.
- Saved-record deletion lives behind the detail screen overflow button and uses
  a confirmation dialog before mutating the repository.
- Detail charts use timestamped metric samples and touchable line-chart
  rendering.
- Ghost-enabled runs stay in the same detail screen and show an optional ghost
  comparison section only when stored on the session.

## Implementation Steps

1. Change `HistoryTabScreen` to consume full sessions and attach `onTap` to each
   summary tile.
2. Add a small `RunSessionDetailScreen` wrapper.
3. Make `RunFinishReviewPanel` support read-only mode and optional close action.
4. Add/update widget tests.
5. Update product spec wording for history detail.
6. Add pace samples to the detail calculator and render a read-only pace chart.
7. Add `deleteSession` to the repository contract and wire it to history detail.

## Validation

- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed.
- `flutter test` passed.
- Delete update re-ran `dart run tool/guardrails.dart`, `flutter analyze`,
  and `flutter test`; all passed.

## Risks Or Recovery

- If the finish review panel grows past 300 lines, split reusable detail pieces
  into smaller files before continuing.
