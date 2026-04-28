# Watch Integration Notes

## Summary

Document the platform decisions Runlini should use when adding Apple Watch or
Android / Galaxy Watch support. The document distinguishes historical Health
import from real-time watch recording and keeps the local DB source-of-truth
decision intact.

## Key Decisions

- Galaxy Watch records flow through Samsung Health on the phone, then Health
  Connect, then Runlini import.
- Apple Watch records flow through HealthKit, then Runlini import.
- Apple Watch and iPhone apps can exchange Runlini-owned data directly through
  WatchConnectivity; HealthKit is not the only communication path.
- HealthKit remains the boundary for health and fitness records, including
  workout samples, routes, heart rate, distance, and calories.
- Real-time watch recording requires native watch apps:
  - Wear OS app with Health Services for Android / Galaxy Watch-class devices
  - watchOS app with HealthKit workout sessions for Apple Watch
- Live Apple Watch workout mirroring should use HealthKit `HKWorkoutSession`
  mirroring, with WatchConnectivity reserved for app-owned companion messages
  and draft handoff.
- Health Connect / HealthKit remain backup and recovery sources, not the primary
  UI store.
- Runlini local DB remains the source of truth for history, ghost sessions,
  shoe mileage, deletion tombstones, and sync status.

## Progress

- [x] Clarify Apple Watch direct companion communication vs HealthKit records.
- [x] Add HealthKit workout mirroring as the preferred live workout session path.
- [x] Update permission notes so WatchConnectivity failures are not confused
  with Health permission failures.
- [x] Run validation commands.

## Changed Files

- `docs/platform/watch-integration.md`
- `docs/platform/permissions.md`
- `docs/exec-plans/active/watch-integration-notes.md`

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Assumptions

- This task is documentation only.
- Platform implementation is deferred.
- Future watch apps should reuse existing `RunSession` merge and persistence
  rules instead of creating separate watch-only record models.
