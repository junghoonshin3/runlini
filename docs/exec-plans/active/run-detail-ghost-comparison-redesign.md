# Run Detail Ghost Comparison Redesign

## Summary

Redesign the run detail ghost comparison card so it explains the result with
numeric differences instead of only showing the saved time and distance gap.

## Progress

- [x] Add a comparison builder for current run vs original ghost run.
- [x] Load the original ghost session on the detail screen.
- [x] Redesign the comparison card in Korean with readable numeric rows.
- [x] Add unit and widget tests.
- [x] Run guardrails, analyze, and Flutter tests.

## Decisions

- Keep the DB schema unchanged.
- Use the saved `RunSessionGhostSummary` as the finish result source of truth.
- Use the original ghost session when available to derive course time, pace,
  speed, cadence, elevation, and extra recording deltas.
- Fall back to summary-only display if the original ghost session is missing.
