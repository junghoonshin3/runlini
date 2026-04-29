# Platform Permissions

## Android

- Baseline Android API level: 26 (`health` plugin requirement)
- Compile and target SDK: 36
- Google Maps SDK key via `android/local.properties` as `GOOGLE_MAPS_API_KEY`
- `ACCESS_FINE_LOCATION` for live run capture
- `ACTIVITY_RECOGNITION` for workout context where needed
- Live location cadence is controlled by the Settings tab tracking preset:
  - `절전`: before start or paused `5s / 10m`, actively running `2s / 5m`
  - `균형` default: before start or paused `3s / 5m`, actively running
    `1s / 3m`
  - `정확`: before start or paused `2s / 3m`, actively running `1s / 1m`
  - The foreground tracking notification is only attached to active running
- Health Connect run import/backup declarations:
  - `android.permission.health.READ_STEPS`
  - `android.permission.health.READ_HEART_RATE`
  - `android.permission.health.READ_TOTAL_CALORIES_BURNED`
  - `android.permission.health.READ_EXERCISE`
  - `android.permission.health.WRITE_EXERCISE`
  - `android.permission.health.READ_DISTANCE`
  - `android.permission.health.WRITE_DISTANCE`
  - `android.permission.health.READ_EXERCISE_ROUTES`
  - `android.permission.health.WRITE_EXERCISE_ROUTE`
  - `WRITE_DISTANCE` is required because Runlini exports the workout's total
    distance with the exercise record.
  - Android's official route permission names are intentionally asymmetric:
    read is plural `READ_EXERCISE_ROUTES`, write is singular
    `WRITE_EXERCISE_ROUTE`.
- Health Connect permission rationale entry points:
  - `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE` intent filter
  - `ViewPermissionUsageActivity` alias for Health permissions review
- Settings > 연동 exposes Health Connect as the Android Health connection
  entry point. The primary action opens the Health Connect permission request
  when access is missing and changes to a recent-record import action after
  connection. Manual app-record backup is hidden from the normal Settings flow;
  failed Health backups expose a small retry action in the Health entry.
- On Android 13 and lower, Health Connect is delivered as the separate
  `com.google.android.apps.healthdata` app. Runlini does not prompt for install
  during app startup; install or permission UI appears only from explicit user
  actions in Settings > 연동 or the empty-history recovery CTA.
- App deletion, app data clearing, or Health Connect permission revocation can
  remove local records or revoke access. After reinstall, Runlini does not
  auto-prompt; the runner restores recent records from the History recovery CTA.
- v1 Health import is scoped to recent 30 days. Full historical reads such as
  Android `READ_HEALTH_DATA_HISTORY` are deferred.
- Galaxy Watch workout data is treated as an indirect Health Connect import:
  Galaxy Watch data reaches Runlini through Samsung Health on the phone and
  Health Connect sync. Real-time Galaxy Watch support requires a separate Wear
  OS app. See `docs/platform/watch-integration.md`.
- Native Wear OS app permissions for independent run capture:
  - `ACTIVITY_RECOGNITION` for exercise session context.
  - `ACCESS_FINE_LOCATION` for GPS route and distance support.
  - `BODY_SENSORS` on API 35 and lower for heart-rate access.
  - `android.permission.health.READ_HEART_RATE` on API 36 and higher.
  - Wear OS V1 does not write directly to Health Connect; it sends completed
    Runlini watch drafts to the phone through Wear OS Data Layer.

## iOS

- Baseline iOS deployment target: 14.0
- `io.flutter.embedded_views_preview = YES` for Apple Maps platform views
- `NSLocationWhenInUseUsageDescription`
- Live location distance filters follow the same Settings tab preset:
  - `절전`: before start or paused `10m`, actively running `5m`
  - `균형` default: before start or paused `5m`, actively running `3m`
  - `정확`: before start or paused `3m`, actively running `1m`
  - Background location indicators are only enabled while actively running
- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription`
- HealthKit entitlement via `Runner/Runner.entitlements`
- Settings > 연동 labels the iOS Health integration as `건강 앱` for runners,
  while the implementation uses HealthKit authorization and queries.
- Apple Watch workout data is treated as a HealthKit import unless Runlini adds
  a native watchOS app. Real-time Apple Watch support requires a watchOS workout
  session and companion communication. See `docs/platform/watch-integration.md`.
- WatchConnectivity messages between a Runlini iPhone app and watchOS app are
  app-owned companion data, not HealthKit records. They do not replace HealthKit
  permission for workout, route, heart-rate, distance, or calorie data.

## Policy

- Request health permissions only from an explicit runner action in Settings >
  연동 or the empty-history recovery CTA.
- Ask for Runlini's run-health scope as one bundle: workout / route / distance
  write access together with workout / route / distance / calories / steps /
  heart-rate read access. Do not split read and write prompts into separate UX
  flows.
- App startup may check/sync Health data only when permission is already
  granted, and must skip quietly otherwise.
- If HealthKit or Health Connect is unavailable or denied, keep local run
  recording active and skip the export gracefully.
- If companion watch communication is unavailable, keep the phone-first run flow
  usable and queue or skip watch-only companion updates without implying Health
  permission failure.
- Health backup status is stored on the local run record, but user-facing copy
  should call it sending to Health Connect / 건강 앱. Skipped or failed export
  can be shown and retried without hiding the saved run.
- Settings should not show a standalone backup entry. Retry appears only when
  a local run has failed Health send.
- Health-imported records must show their import origin instead of the app-local
  send-status label: Health Connect records use the Health Connect/source app
  label, and HealthKit records use 건강 앱/source app labeling.
- Explain why each permission is needed in plain runner language.
- Android uses Google Maps; iOS uses Apple Maps.
