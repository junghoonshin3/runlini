# History Refresh Wear Sync

## Summary

History pull-to-refresh now checks both Health and Wear draft sources before
reloading the local run list.

## Decisions

- Keep Health silent sync first, then drain pending Wear drafts, then reload
  `runSessionListProvider`.
- Wear refresh sync is quiet. Failures do not show a snackbar and do not block
  local DB refresh.
- Settings > 연동 keeps the explicit `워치 기록 동기화` action for manual feedback.

## Status

- [x] Add Wear pending draft sync to history refresh.
- [x] Add widget tests for Wear sync success and failure on refresh.
- [x] Run guardrails, analyze, and tests.
