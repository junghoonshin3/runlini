# History Distance Progress Ring

## Purpose

Redesign the top of the history tab so runners can switch between this week,
this month, and this year, then immediately see their total distance in a
circular progress ring.

## Context And Orientation

- The history tab reads `runSessionListProvider`, which is backed by the local
  DB and is the visible source of truth.
- The history tab already respects display-unit settings for list rows.
- Fitness apps commonly surface progress by timeframe: Strava supports weekly,
  monthly, and annual goals, while Garmin watch faces can show weekly distance
  progress toward a goal.

## Progress

- [x] Inspect the current history screen and display formatters.
- [x] Add period and summary model types.
- [x] Add a service calculator for current week/month/year distance totals.
- [x] Add a top history progress ring with week/month/year controls.
- [x] Add settings-backed weekly/monthly/yearly distance goals.
- [x] Add a history-tab goal change shortcut to the Settings tab.
- [x] Update the product spec.
- [x] Add/adjust tests.
- [x] Run guardrails, analyze, and tests.

## Decisions

- Keep local DB sessions as the only input.
- Use current-period buckets:
  - Week starts on Monday.
  - Month starts on the first day of the month.
  - Year starts on January 1.
- Use v1 default distance targets so the ring has a stable progress denominator:
  - Week: 20 km
  - Month: 80 km
  - Year: 1000 km
- Display units follow `RunDisplaySettings`; stored values remain meters.
- Users can edit the goals in Settings; inputs follow the current display unit
  but are saved to `app_settings` as meters.

## Implementation Steps

1. Add `RunHistoryPeriod` and `RunHistoryDistanceSummary`.
2. Add `RunHistoryDistanceSummaryCalculator`.
3. Add `HistoryDistanceProgressPanel`.
4. Mount the panel below the history header and above empty/list content.
5. Add `RunDistanceGoalSettings` and save/load it through the existing
   key/value settings store.
6. Add a Settings tab distance-goal section and a history shortcut.
7. Add service and widget tests.

## Validation

- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed.
- `flutter test` passed.

## Risks Or Recovery

- If goal editing feels too prominent in Settings, move the section under a
  collapsible "기록 표시" group without changing the underlying settings model.
