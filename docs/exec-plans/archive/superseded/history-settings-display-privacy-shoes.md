# History Settings, Privacy, and Shoes

## Purpose

Add a history-settings entry point for run display units, local privacy display
controls, and running-shoe management while keeping raw run data in meters,
seconds, and source-native samples.

## Context and Orientation

- History uses `RunSessionRepository` as the source of truth.
- `RunFinishReviewPanel` is shared by post-stop review and saved-run detail.
- Local persistence lives in `RunliniDatabase` and sqflite repositories.
- Dart files must stay at or below 300 lines.

## Progress

- [ ] Add settings, privacy, and shoe domain types.
- [ ] Add DB tables and `shoe_id` migration.
- [ ] Add sqflite settings/shoe repository and providers.
- [ ] Add history settings screen and entry point.
- [ ] Apply display/privacy settings to history and detail UI.
- [x] Align saved-run detail and post-stop review units for km/mi display.
- [x] Label pace displays as `min/km` or `min/mi` instead of bare distance
      units.
- [ ] Attach the default shoe to newly saved app-local runs.
- [x] Fix history-settings button layout crashes under `AppTheme.dark()`.
- [x] Move record settings into the app-level settings tab.
- [x] Apply display unit settings to the live running HUD.
- [ ] Update docs and tests.
- [ ] Run guardrails, analyze, and tests.

## Decisions

- Settings are local-only in v1.
- Unit changes affect presentation only; stored data remains metric raw data.
- `hideStartEndArea` shows a protection badge in v1 and does not mask points.
- Shoe mileage is derived from saved local sessions by `shoeId`.
- Running-shoe removal is labeled `삭제` in the UI, but v1 keeps it as a soft
  delete internally. This removes the shoe from active selection while
  preserving past run detail lookups and accumulated history.
- Running-shoe `은퇴` and `삭제` are separate states. Retired shoes remain visible
  but cannot be chosen as the default. Deleted shoes are hidden from settings
  but kept in storage so historical runs still resolve their shoe name.
- Saved-run detail and post-stop review use the same display settings.
- Live running metrics use the same display settings for distance, pace, and
  speed while keeping elapsed time and calories unchanged.
- Mile display uses one-mile split boundaries while stored data stays metric.
- Pace labels use `min/km` or `min/mi` because pace is time per distance, not
  a bare distance unit.
- Detail and review unit labels follow common running-app casing such as `km`,
  `mi`, `min/km`, `km/h`, `kcal`, `m`, and `bpm`.
- App settings live behind the `설정` bottom tab. History stays focused on
  records and Health sync.

## Implementation Steps

1. Add `RunDisplaySettings`, `RunPrivacySettings`, `RunSettingsState`, and
   `RunShoe`.
2. Bump `runlini.db` and create `app_settings` / `run_shoes`.
3. Persist settings as key-value strings and shoes as rows.
4. Add settings providers for display, privacy, shoe list, and default shoe.
5. Add a `기록 설정` button to the history tab header.
6. Create the history settings screen with units, privacy switches, and shoe
   add/default/delete controls.
7. Update saved-run detail and history list formatting to use settings.
8. Attach the selected default shoe during `saveFinishedRun()`.
9. Keep compact history-settings buttons off the global
   `OutlinedButton` / `FilledButton` themes so loose `Row`, `Wrap`, and dialog
   layouts never receive infinite-width button constraints.
10. Pass display/privacy settings into post-stop review and keep pace charts,
    ghost distance gaps, and split boundaries aligned with the selected unit.
11. Add a `settings` app tab and move display, privacy, and shoe controls into
    `features/settings`.
12. Pass display settings into the live running metrics panel and remove
    hardcoded `km`, `/km`, and `km/h` display strings from that HUD.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
- `flutter test test/features/run_tracking/history_settings_screen_test.dart`

## Risks or Recovery

- If migration fails on an old local DB, clear app data in development and
  inspect `RunliniDatabase._upgrade`.
- If detail UI grows past the file limit, split sections before adding more
  visual logic.
