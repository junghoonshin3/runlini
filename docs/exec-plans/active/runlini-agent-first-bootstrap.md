# Runlini Agent-First Bootstrap

## Purpose

Seed a Flutter repository that is easy for humans and agents to extend without
losing architecture, design intent, or validation discipline.

## Progress

- [x] Initialize Git and a Flutter iOS/Android app
- [x] Add agent-first repo docs and execution-plan guidance
- [x] Establish `app`, `core`, and layered `features` scaffolding
- [x] Seed fake GPS fixture data and domain interfaces
- [x] Add CI and local guardrails
- [x] Replace the single dashboard demo with a 2-tab history/running shell
- [x] Add fixture-backed running history and ghost settings selection flow
- [x] Migrate the running map surface to Google Maps on Android and Apple Maps on iOS
- [x] Stop rendering an idle runner marker from fixture coordinates when device GPS is unavailable
- [x] Use the platform-default runner marker instead of a custom PNG asset
- [x] Split async map fixture/ghost state from sync device recenter state so current-location refresh keeps the map mounted
- [x] Hold the first running-map mount until startup location bootstrap resolves so the initial center prefers the device position
- [x] Make startup location bootstrap failure non-blocking so the map can fall back instead of spinning forever
- [x] Start live GPS subscription explicitly after the startup bootstrap path settles
- [x] Recenter from in-memory or last-known device location first so the current-location button moves immediately
- [x] Keep the running tab subscribed to live GPS so the map follows the latest location before and during a run
- [x] Open the app on the history tab by default so saved runs are the first
      surface users see
- [ ] Implement live recording, map rendering, and persistent storage
- [ ] Implement ghost selection, interpolation UI, and haptics
- [ ] Implement Health Connect and HealthKit sync flows

## Decisions

- Use `docs/` as the source of truth, with short root guides for fast lookup.
- Seed one fake run asset so ghost logic can be tested before live GPS exists.
- Enforce architecture with a repo-local Dart script before adding heavier tooling.
- Keep early running UX fixture-driven until GPS and sqflite are wired for Phase 1.
- Keep widget tests on a fake map surface even after moving runtime maps to native SDKs.
- Use fixture coordinates as an idle map-center fallback only; never show them as the live runner marker.
- Use an oversized blue current-location marker on Android so the runner stays legible over the route line, and use Apple Maps annotations on iOS.
- Keep live GPS as the single source of truth for the current-location marker and map follow, and treat recorded run points as a separate filtered track.
- On first entry, try cached device location before a short current-location fetch and only then allow the fixture fallback center.
- Startup location fetch errors must never block the map; they degrade to the fixture fallback center with no live marker until GPS recovers.
- Do not start the live GPS stream from provider construction. First let the startup bootstrap settle, then sync the live subscription from the visible running tab or active-run state.
- Keep the running tab subscribed to live GPS while visible, and continue that subscription on other tabs only while an active run is in progress.
- The default app tab is `history`; running-map bootstrap work starts only
  after the user switches to the running tab.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Recovery

- If structure checks fail, fix imports or move files to the correct layer.
- If a plan goes stale, update this file before changing behavior further.
