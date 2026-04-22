# Emulator GPS Route Simulator

## Purpose

Create a local tool that drives the Android emulator GPS along the Osaka ghost
route so Runlini's live capture and ghost race HUD can be tested like a real
run.

## Context and Orientation

- The default Osaka route is
  `assets/fixtures/osaka_namba_kanzakigawa_route.json` so emulator current
  location starts on the selected Kanzakigawa ghost route.
- The emulator accepts GPS updates through `adb emu geo fix <lng> <lat>`.
- The tool should be usable without changing app runtime code.

## Progress

- [x] Add a Dart CLI route simulator under `tool/`.
- [x] Support device id, adb path, interval, pace, time scale, dry run, and max
  update count.
- [x] Document the command in this plan.
- [x] Run guardrails, analyze, and tests.

## Decisions

- Default device is `emulator-5554`.
- Default pace is `420 sec/km` to match the Osaka Namba to Kanzakigawa ghost
  fixture.
- Default time scale is `6x` so a full route test finishes quickly.
- Coordinates are sent in ADB order: longitude, then latitude.
- Full default run:
  `dart run tool/emulator_gps_route_simulator.dart`
- Real-time 7:00/km run:
  `dart run tool/emulator_gps_route_simulator.dart --time-scale 1`
- Short smoke test:
  `dart run tool/emulator_gps_route_simulator.dart --max-updates 3 --interval-ms 200`

## Validation

- `dart run tool/emulator_gps_route_simulator.dart --dry-run --max-updates 3 --interval-ms 1` passes.
- `dart run tool/emulator_gps_route_simulator.dart --max-updates 3 --interval-ms 200 --time-scale 6` pushes emulator GPS successfully.
- `dart run tool/guardrails.dart` passes with existing file-length warnings.
- `flutter analyze` passes.
- `flutter test` passes.
