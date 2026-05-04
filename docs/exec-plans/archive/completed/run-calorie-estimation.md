# Run Calorie Estimation

## Purpose

Add v1 activity calorie estimation for app-recorded runs using the inputs
Runlini can trust today: accepted GPS distance and a user-provided body weight.

## Context and Orientation

- `RunSession.caloriesKcal` and the `run_sessions.calories_kcal` DB column
  already exist.
- Live metrics previously showed a static `-- kcal` placeholder.
- Finished run drafts previously saved `caloriesKcal = null`.
- Health-imported workouts may still provide calories from platform data.

## Progress

- [x] Add `bodyWeightKg` to run settings.
- [x] Persist body weight in `app_settings`.
- [x] Add settings UI for profile body weight.
- [x] Add a reusable calorie calculator.
- [x] Use the calculator in live run metrics.
- [x] Use the calculator when building a finished run draft.
- [x] Add calculator, settings, live metric, and save-flow tests.
- [x] Show a required body weight screen on app startup when missing.

## Decisions

- v1 displays active calories, not resting-inclusive total calories.
- Formula: `kcal = bodyWeightKg * distanceKm * 1.0`.
- Body weight is required. Without it, calories remain `-- kcal`.
- Valid body weight range is `20kg` to `250kg`.
- Weight input is kg-only in v1.
- The startup weight screen blocks app entry until a valid body weight is saved.
- Health calorie write is deferred; local app calculation and Health-imported
  calorie reads remain separate.

## Implementation Steps

1. Store optional body weight in `RunSettingsState`.
2. Add `RunCalorieCalculator` under the run tracking service layer.
3. Feed body weight into `LiveRunMetricsCalculator`.
4. Feed body weight into `FinishedRunSessionBuilder`.
5. Show calculated calories through existing live, review, and detail UIs.
6. Gate app startup behind a full-screen body weight entry flow when missing.
7. Document that calorie values are estimates from body weight and GPS distance.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- The formula is intentionally transparent and stable, but not watch-grade.
- HR/elevation/body-composition formulas need more user and sensor inputs and
  should be added later without replacing local saved values unexpectedly.
