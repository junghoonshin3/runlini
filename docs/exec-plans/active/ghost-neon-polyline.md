# Ghost Red Polyline

## Purpose

Keep the ghost rider route style as a simple electric-red dashed line on native
and test maps.

This plan has been superseded by `ghost-pace-colored-polyline.md`, which keeps
the dashed route treatment but colors each ghost segment by relative pace.

## Progress

- [x] Revert native ghost polylines to a single electric-red dashed layer.
- [x] Mirror the same single red dashed style in `FakeRunMapSurface`.
- [x] Document the ghost route visual rule in the design identity.
- [x] Validate with guardrails, analysis, and tests.

## Decisions

- Use `AppColors.electricRed` as the ghost route color.
- Keep the ghost route dashed and wider than the runner line.
- Keep the runner route as the existing `AppColors.voltGreen` solid line.
- Preserve the existing `ghost-polyline-layer` widget key in fake map tests.

## Validation

- `dart run tool/guardrails.dart` passes with existing file-length warnings.
- `flutter analyze` passes.
- `flutter test` passes.
