# Health Linking Source UI

## Summary

Settings > 연동 is being split into platform-aware Health, Wear, and backup
cards. Android uses Health Connect naming; iOS uses the user-facing 건강 앱
label while the implementation remains HealthKit-backed.

## Decisions

- Explicit Health actions request the shared run permission scope. Startup and
  pull-to-refresh only sync when permission is already available.
- Health-imported records keep `recordSource` as `healthConnect` or
  `healthKit`; app-created records keep `appLocal`.
- History and detail badges use `recordSource` to distinguish backup status from
  import provenance. App-local synced records show `Health 백업됨`; imported
  records show their source app when available, otherwise the platform fallback.
- Wear OS manual draft sync remains an Android-only Settings card.

## Status

- [x] Add Health connection status checks to the Health route client.
- [x] Rework Settings > 연동 into Health, Wear, and backup cards.
- [x] Show Health-imported record provenance in History and Detail.
- [x] Add focused widget/unit tests for platform labels and source badges.
- [x] Run full validation after formatting.

## References

- Android Health Connect permissions UI:
  <https://developer.android.com/health-and-fitness/health-connect/ui/permissions>
- Apple HealthKit authorization:
  <https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data>
