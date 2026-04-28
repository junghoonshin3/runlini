# Health Save And Recovery Flow

## Purpose

Make the runner-facing health flow explicit: Runlini saves to local DB first,
then treats Health Connect / HealthKit as an external backup and recovery
source. A Health failure must never make a local save look like it failed.

## Decisions

- Local DB remains the only source of truth for History, Ghost selection, and
  Detail screens.
- `저장하기` means the run is saved locally. Health backup is a second step with
  its own visible status.
- `RunSessionSyncStatus` meanings are fixed:
  - `localOnly`: stored only in Runlini
  - `synced`: backed up to Health, or imported from Health
  - `syncSkipped`: Health is unavailable, unauthorized, or not started
  - `syncFailed`: Health backup was attempted and failed
- App reinstall or data clear removes the local DB. Recovery is explicit:
  History does not show a top-level Health CTA, but the empty-history recovery
  panel can start a user-initiated Health import so the OS permission prompt is
  shown from that recovery action. The empty-history CTA labels this as Health
  record import, disables itself while syncing, and shows separate feedback for
  success, permission-needed, unavailable, and failed states. Settings > 연동
  remains the full management surface for import, backup, and retry.
- Running `START` never asks for Health permissions. It starts local capture
  immediately; Health backup is a separate settings action.
- Health permission requests use one shared run-health scope for import and
  backup. A user-initiated Health action asks for workout/route/distance write
  access together with workout/route/distance/calorie/step/heart-rate read
  access, instead of asking read and write permissions in separate flows.
- Health import remains recent-30-days in v1. Full history access is deferred.

## Implementation Notes

- `HealthWorkoutRecorder.finishRunCapture()` returns a
  `HealthWorkoutExportResult` instead of `void`.
- `RunPlaybackController.saveFinishedRun()` saves local DB first and marks the
  record as app-only until the user backs it up from Settings.
- Records show a compact Health backup badge in History and Detail.
- Detail exposes `Health 백업 다시 시도` for `syncFailed` records.
- Settings > 연동 is the full Health management entry point. The empty-history
  recovery button may also request Health permission, but only as an explicit
  user restore action.
- `HealthSyncController.syncWithUserAction()` returns the final
  `HealthSyncStatus` so user-facing CTAs can show accurate permission,
  unavailable, and failure messages instead of always showing success.
- `HealthPluginRouteClient.importRecentSessions(requestAuthorization: true)`
  always calls the platform Health authorization request. This keeps explicit
  user actions wired to the OS permission/check screen instead of only relying
  on a prior `hasPermissions` result.
- `HealthRunPermissionScope` is the single source for Health permission types
  and access levels used by both import and backup code.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks Or Recovery

- The Flutter `health` plugin may not always return a stable workout UUID after
  write. In that case Runlini still marks the backup as Health-backed if the
  workout write succeeded, while leaving `externalId` null.
- Route backup can be less reliable than workout backup. A workout-only Health
  export is still treated as backed up, and route limitations are surfaced by
  import/recovery state rather than blocking local history.
