# Wear Debug GPS Injection

## Purpose

Wear OS emulator Health Services can generate synthetic exercise location that
does not follow arbitrary `adb emu geo fix` routes. This debug-only path lets
Runlini inject route points directly into the Wear run state so ghost runs can
be tested against known fixtures.

## Decisions

- Debug entry action: `kr.sjh.runlini.wear.debug.GPS_SAMPLE`.
- External entry point lives only under `android/wear/src/debug`.
- Release builds do not expose the ADB broadcast receiver.
- Injection overrides location, distance, current pace, and speed only.
- Heart rate, calories, and cadence continue to come from Health Services.
- If no injected sample arrives for 10 seconds, the controller falls back to
  normal Health Services motion metrics.

## Usage

Run the existing Osaka fixture through the debug receiver:

```bash
dart run tool/emulator_gps_route_simulator.dart \
  --device emulator-5554 \
  --wear-debug-injection \
  --time-scale 6
```

Dry-run the broadcast payload:

```bash
dart run tool/emulator_gps_route_simulator.dart \
  --wear-debug-injection \
  --dry-run \
  --max-updates 3
```

## Validation

- [x] `./gradlew :wear:testDebugUnitTest`
- [x] `./gradlew :wear:assembleDebug`
- [x] release manifest check or release assemble confirms the debug receiver is
  not included.
- [x] `dart run tool/guardrails.dart`
- [x] `flutter analyze`
- [x] `flutter test`
