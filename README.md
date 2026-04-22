# Runlini

Runlini is a Flutter running app scaffolded with an agent-first workflow.
The repository is intentionally shaped for fast iteration with coding agents:
docs are the system of record, execution plans live in-repo, and structural
checks enforce architecture instead of relying on memory.

## Core Commands

```bash
flutter pub get
dart run tool/guardrails.dart
flutter analyze
flutter test
```

## Native Map Setup

- Android uses Google Maps. Add `GOOGLE_MAPS_API_KEY=your_key_here` to
  `android/local.properties`.
- iOS uses Apple Maps through `apple_maps_flutter`.
- Widget tests keep using a fake map surface, so native map SDKs are not needed
  for `flutter test`.

## Repo Guide

- `AGENTS.md`: short operating guide for future agents and humans.
- `PLANS.md`: rules for executable plans on multi-file or long-running work.
- `ARCHITECTURE.md`: the dependency model for `app`, `core`, and `features`.
- `docs/`: product, design, reliability, platform, and execution-plan source of truth.
- `tool/guardrails.dart`: structural checks for the layered feature layout.

## Current Status

This bootstrap includes:

- Flutter iOS/Android app shell
- Neo-brutalist dark theme tokens
- Seed domain interfaces for run tracking, ghost racing, and health sync
- Fake GPS fixture data for repeatable development
- CI and local guardrails for linting, structure, and tests
