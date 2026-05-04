# History Pull To Refresh

## Purpose

Add pull-to-refresh to the history tab so runners can manually refresh local
records and silently check already-authorized Health records without leaving
the screen.

## Decisions

- The history tab remains the local DB source-of-truth view.
- Pull-to-refresh never requests Health permissions.
- Refresh performs a silent `syncIfAuthorized()` and then reloads
  `runSessionListProvider`.
- The empty history recovery CTA remains the explicit permission-request path.

## Progress

- [x] Add `RefreshIndicator` around the history scroll view.
- [x] Keep empty history refreshable with `AlwaysScrollableScrollPhysics`.
- [x] Add widget coverage for the silent refresh path.
- [x] Run guardrails, analyze, and tests.
