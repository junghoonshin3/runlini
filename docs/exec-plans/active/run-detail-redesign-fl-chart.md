# Run Detail Redesign And Fl Chart

## Purpose

Move the saved-run detail/review UI away from the reference-app look and replace
the custom bar charts with time-based `fl_chart` line charts.

## Context and Orientation

- `RunFinishReviewPanel` is shared by post-stop review and history detail.
- `RunSessionDetailCalculator` owns derived metrics, splits, and chart data.
- `RunSession` is the single persisted workout model.

## Progress

- [x] Inspect current detail UI, calculator, tests, and docs.
- [x] Add `fl_chart`.
- [x] Add optional ghost summary persistence to `RunSession`.
- [x] Convert chart data to elapsed-time samples.
- [x] Replace custom bar charts with `fl_chart` line charts.
- [x] Redesign the shared detail panel with Runlini-specific visual language.
- [x] Update tests and docs.
- [x] Run guardrails, analyze, and tests.

## Decisions

- Keep one `RunSession` type; ghost-enabled runs store optional metadata.
- v1 saves only the final ghost comparison summary, not the full comparison
  timeline.
- Charts use line + touch tooltip only; no zoom or pan in this pass.
- Pace values remain real seconds-per-kilometer and are labeled as lower-is-
  faster instead of visually inverting the meaning.
- The detail route section uses the platform map SDK on Android/iOS, but only
  as a read-only route preview with map gestures and controls disabled.

## Implementation Steps

1. Add a run-tracking ghost summary type and wire it into `RunSession` JSON.
2. Capture the final ghost frame when `STOP` creates the review draft.
3. Add `RunMetricSample` and make detail calculations produce timestamped
   samples.
4. Replace `RunDetailBarChart` with a reusable `RunDetailLineChart`.
5. Split the detail panel into smaller section widgets to keep files under 300
   lines.
6. Refresh widget/provider tests for the new labels, keys, and chart structure.
7. Update product/design docs for Runlini detail and analysis behavior.

## Validation

- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed.
- `flutter test` passed.

## Risks or Recovery

- If `fl_chart` behavior is hard to assert in widget tests, test our stable keys,
  labels, and data calculator output, then rely on analyzer/runtime compile for
  the chart package wiring.
