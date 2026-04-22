# Platform Permissions

## Android

- Baseline Android API level: 26 (`health` plugin requirement)
- Compile and target SDK: 36
- Google Maps SDK key via `android/local.properties` as `GOOGLE_MAPS_API_KEY`
- `ACCESS_FINE_LOCATION` for live run capture
- `ACTIVITY_RECOGNITION` for workout context where needed
- Live location cadence:
  - Before start or paused on the running tab: `3s / 5m`
  - Actively running: `1s / 3m`
  - The foreground tracking notification is only attached to active running
- Health Connect workout export declarations:
  - `android.permission.health.READ_EXERCISE`
  - `android.permission.health.WRITE_EXERCISE`
  - `android.permission.health.WRITE_EXERCISE_ROUTE`
- Health Connect permission rationale entry points:
  - `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE` intent filter
  - `ViewPermissionUsageActivity` alias for Health permissions review

## iOS

- Baseline iOS deployment target: 14.0
- `io.flutter.embedded_views_preview = YES` for Apple Maps platform views
- `NSLocationWhenInUseUsageDescription`
- Live location distance filters:
  - Before start or paused on the running tab: `5m`
  - Actively running: `3m`
  - Background location indicators are only enabled while actively running
- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription`
- HealthKit entitlement via `Runner/Runner.entitlements`

## Policy

- Request health permissions only from an explicit runner action, currently
  `Start` on the running tab.
- If HealthKit or Health Connect is unavailable or denied, keep local run
  recording active and skip the export gracefully.
- Explain why each permission is needed in plain runner language.
- Android uses Google Maps; iOS uses Apple Maps.
