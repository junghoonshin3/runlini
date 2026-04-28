# History Calendar Progress

## Purpose

Add a history calendar that defaults to a compact weekly view and expands into
a monthly view. Each day shows a small circular distance progress marker so the
runner can see consistency without scrolling a long list first.

## Context And Orientation

- The history tab already reads local DB sessions through `runSessionListProvider`.
- The top history distance ring remains the primary period summary.
- Calendar progress should follow the existing display-unit and distance-goal
  settings. Stored run data stays in meters.

## Progress

- [x] Inspect current history tab, progress ring, formatters, and tests.
- [x] Add daily history summary model and calculator.
- [x] Add weekly-default/monthly-expanded calendar UI.
- [x] Wire calendar selection into the history list.
- [x] Update product docs.
- [x] Add/adjust tests.
- [x] Run guardrails, analyze, and tests.
- [x] Fix narrow-screen monthly calendar cell overflow.
- [x] Replace expand/collapse copy with week/month segmented control.
- [x] Add horizontal swipe navigation for weekly and monthly calendar views.

## Decisions

- Do not add a calendar package for v1. The needed UI is a small custom
  history-specific calendar, not a full scheduling engine.
- Default view is one week. The user can expand to the focused month.
- Month navigation stays inside the calendar panel.
- Daily ring target is `monthlyGoalM / daysInMonth(focusedMonth)`.
- Tapping a date filters the list below to that date; clearing the selection
  returns to recent records.
- Calendar day cells use compact, scale-down content so monthly expansion does
  not overflow on narrow mobile screens.
- Calendar view mode copy is `주간` / `월간`; switching uses a short
  size-and-fade animation instead of expand/collapse wording.
- Horizontal swipes follow the visible mode: weekly view moves by one week,
  monthly view moves by one month. Left swipe goes forward, right swipe goes
  backward.

## Implementation Steps

1. Add `RunHistoryDaySummary`.
2. Add `RunHistoryCalendarSummaryCalculator`.
3. Add `HistoryCalendarPanel` and a reusable day cell widget.
4. Mount the calendar below `HistoryDistanceProgressPanel`.
5. Filter the history list when a date is selected.
6. Update product docs and tests.

## Validation

- `dart run tool/guardrails.dart` passed.
- `flutter analyze` passed.
- `flutter test` passed.

## Risks Or Recovery

- If the calendar makes the history tab too tall, keep the weekly default and
  move detailed month navigation into a later full-screen calendar.
