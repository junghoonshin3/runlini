# Running Tab Map Bootstrap

## Summary
- First-install running tab should mount the map immediately.
- Location bootstrap and static map data are background enhancements, not render blockers.
- The fallback center remains Seoul until live location, ghost route, or session data arrives.

## Decisions
- `runMapViewStateProvider` always returns a view state.
- Static map state loading/error falls back to an empty map state.
- Running tab no longer shows a full-screen spinner while waiting for initial location.
- Start/current-location actions still retry real location when the user asks for it.

## Status
- [x] Make map view state absence-safe with fallback center.
- [x] Remove initial location bootstrap render gate from running tab.
- [x] Update bootstrap/widget tests for immediate map rendering.
- [x] Run guardrails, analyze, and tests.
