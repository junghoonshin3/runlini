# Runlini

Runlini is a Flutter running app for live running, route history, record racing,
and health sync. Docs are the system of record, execution plans live in-repo,
and structural checks enforce architecture.

## Emulator Demo

<video src="docs/assets/runlini-emulator-demo.mov" controls width="360"></video>

[Watch the Android emulator demo](docs/assets/runlini-emulator-demo.mov)

Recorded from the Android emulator with the built-in macOS screen recorder.

## Core Commands

```bash
flutter pub get
dart run tool/guardrails.dart
flutter analyze
flutter test
```

See `docs/development/git-workflow.md` for branch, commit, validation, and push
rules.

## Native Map Setup

- Android uses Google Maps. Add `GOOGLE_MAPS_API_KEY=your_key_here` to
  `android/local.properties`.
- iOS uses Apple Maps through `apple_maps_flutter`.
- Widget tests keep using a fake map surface, so native map SDKs are not needed
  for `flutter test`.

## Repo Guide

- `ARCHITECTURE.md`: the dependency model for `app`, `core`, and `features`.
- `docs/development/git-workflow.md`: Git workflow for development.
- `docs/`: product, design, reliability, platform, and execution-plan source of truth.
- `tool/guardrails.dart`: structural checks for the layered feature layout.

## Current Status

This bootstrap includes:

- Flutter iOS/Android app shell
- Neo-brutalist dark theme tokens
- Seed domain interfaces for run tracking, record racing, and health sync
- Fake GPS fixture data for repeatable development
- CI and local guardrails for linting, structure, and tests
