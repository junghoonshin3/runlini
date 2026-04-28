# Local DB Source Of Truth And Health Sync

## Purpose

Keep Runlini history fast and predictable by making the local database the only
source read by app UI. Health Connect and HealthKit are external inputs that
sync into local storage.

## Context And Orientation

- History, ghost selection, and run detail screens read `RunSessionRepository`.
- `RunSessionRepository` is backed by `sqflite`.
- Bundled fixture runs are development/test seed data and are hidden from the
  user-visible history list by default.
- Health boundaries belong in `core/health`.
- Health sync orchestration belongs in `features/health_sync`.

## Progress

- [x] Add sync metadata to `RunSession`.
- [x] Replace the default fixture/cache repository with a `sqflite`
      repository.
- [x] Make `runSessionListProvider` read only the local repository.
- [x] Change Health Connect/HealthKit import into repository upsert.
- [x] Add silent app-start sync that only runs when permission is already
      granted.
- [x] Keep health install/permission prompts behind explicit user actions.
- [x] Update history-tab sync CTA copy and state.
- [x] Add repository and sync tests.

## Decisions

- Local DB is the source of truth for all app UI.
- Health Connect and HealthKit are external backup/recovery sources, not the
  live source read by UI.
- App startup shows local records immediately and then attempts silent health
  sync without asking for permissions.
- If Health Connect is missing or unauthorized, startup sync skips quietly.
- The history CTA is the explicit user action for install, permission, or
  manual sync flows.
- When local history is empty, the History tab highlights a recovery CTA:
  `Health Connect에서 기록 복구하기`.
- Health sync dedupes by `externalSource + externalId` first, then by nearby
  start time, duration, and distance.
- When a Health record matches an app-local run, the app keeps the richer local
  route/detail points and merges Health metadata.
- App-local records that match Health imports keep their app-local identity and
  richer Runlini metadata while receiving Health `externalId`,
  `lastSyncedAt`, and `synced` status.
- Health route permissions follow the official Android names: route read is
  `android.permission.health.READ_EXERCISE_ROUTES`, while route write remains
  `android.permission.health.WRITE_EXERCISE_ROUTE`.

## Implementation Steps

1. Add `RunSession` source/sync metadata.
2. Add `RunliniDatabase` and `SqfliteRunSessionRepository`.
3. Wire `runSessionRepositoryProvider` to the local DB repository.
4. Update `HealthRouteClient` to report auth/unavailable/success states without
   forcing permission prompts.
5. Update `PlatformHealthSyncService` to upsert imported sessions into the
   repository.
6. Trigger `syncIfAuthorized()` once from app shell startup.
7. Keep history CTA for explicit manual sync.
8. Add focused persistence and sync tests.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks Or Recovery

- If Health Connect is unavailable or permissions are denied, local history
  remains visible and sync state reports that a connection is needed.
- If Health import returns sparse route data, matching app-local route detail is
  preserved.
- If DB migration needs grow beyond v1, add versioned migrations before shipping
  to real users.
