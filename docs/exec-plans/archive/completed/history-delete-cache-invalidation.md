# History Delete Cache Invalidation

## Purpose

Make saved-run deletion remove the record from the repository and from every
Riverpod view of history immediately.

## Decision

- Deleting from the detail screen must invalidate:
  - `runSessionListProvider`
  - `runSessionByIdProvider(session.id)`
- Invalidation happens after the detail route pops, on the next frame. This
  avoids invalidating `runSessionListProvider` while paused `IndexedStack`
  dependents are changing subscription state.
- The history tab may still keep its local deleted-id guard for instant visual
  removal after the detail route pops.
- Repository deletion remains the source of truth; local UI hiding is only a
  short-lived guard against stale frames.
- Deleted sessions are also written to a local `deleted_run_sessions`
  tombstone table before the session row is removed.
- The delete dialog defaults to Runlini-only deletion. Users can explicitly
  check `Health에서도 영구 삭제` to also remove the matching Health workout.
- If Health deletion is requested and the record has an `externalId`, Runlini
  tries to remove the workout by UUID using the Flutter `health` plugin
  `deleteByUUID` API before removing the local row.
- If Health deletion fails or the original record cannot be identified, local
  deletion still succeeds and the tombstone still blocks reimport.
- Health Connect / HealthKit imports must check that tombstone table before
  upsert. This prevents a deleted Health-backed record from being restored on
  the next app launch sync.
- Tombstones match by `session_id`, `record_source + external_id`, and a
  conservative start-time / duration / distance heuristic so app-local records
  that were backed up to Health do not reappear after deletion.

## Validation

- Dashboard deletion widget tests assert that unchecked deletion stays local,
  checked deletion calls the Health deleter, and the backing repository is
  empty after confirmation.
- Health sync tests assert that deleted local or Health-backed records are not
  reimported.
- Sqflite repository tests assert that deleting a record leaves a tombstone.
- Health deleter tests assert that UUID-backed workouts call the platform
  delete API and records without UUIDs skip Health deletion safely.
- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`
