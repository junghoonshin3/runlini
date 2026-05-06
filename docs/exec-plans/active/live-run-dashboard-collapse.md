# Live Run Dashboard Collapse

## Purpose

Redesign the active-run map dashboard so it defaults to a compact collapsed
state and no longer covers too much of the map while recording.

## Context and Orientation

The current running tab places `LiveRunIntervalPanel` and
`LiveRunMetricsPanel` together at the top of the map. Ghost runs add another
large panel inside the metrics card, which can hide the route and map context.

## Progress

- [x] Add a collapsible active-run dashboard overlay.
- [x] Replace the current running tab live metrics stack.
- [x] Keep collapsed state as the default for every new run.
- [x] Update widget tests for collapsed/expanded, ghost, interval, and pause states.
- [x] Run guardrails, analyze, and Flutter tests.

## Decisions

- Collapsed state shows only distance, elapsed time, and average pace.
- Ghost and interval detail are available only in expanded state.
- Dashboard expansion is local UI state and is not persisted.
- Existing map, run, ghost, and interval calculations stay unchanged.

## Implementation Steps

1. Add a new `LiveRunDashboardOverlay` under the running UI layer.
2. Use a compact collapsed row with a chevron toggle.
3. Use a single expanded surface with metric rows, optional interval row, and optional ghost row.
4. Key the overlay by active session so each new run starts collapsed.
5. Update existing tests that previously expected the full metrics panel immediately.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks and Recovery

- If the new widget approaches the 300-line guardrail, split small display rows
  into a companion file before adding more behavior.
- If existing live metrics tests depend on old component internals, keep the
  old component test intact and add new integration coverage for the overlay.
