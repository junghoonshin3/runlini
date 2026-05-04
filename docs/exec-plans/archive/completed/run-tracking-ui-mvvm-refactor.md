# Run Tracking UI MVVM Refactor

## Purpose

Make `run_tracking` easier to navigate by grouping UI files by screen role and
documenting how Runlini applies MVVM inside the existing layered feature
structure.

## Context and Orientation

- Feature layers stay `types -> repo -> service -> state -> ui`.
- `state` providers are the ViewModel layer.
- `ui` widgets are Views and should mostly render data or forward user intent.
- Shared presentation pieces should live under `ui/common`.

## Progress

- [x] Group run-tracking UI files into `running`, `history`, `detail`,
  `formatters`, and `common`.
- [x] Move reusable panel styling into a common widget.
- [x] Update imports after file moves.
- [x] Document MVVM roles in architecture docs.
- [x] Run guardrails, analyze, and tests.

## Decisions

- Keep Riverpod providers in the existing `state` layer instead of adding a
  separate `view_model` layer.
- Keep business calculations in `service` and data contracts in `types`.
- Nested folders under `ui` are allowed because guardrails validate only the
  top-level feature layers.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
