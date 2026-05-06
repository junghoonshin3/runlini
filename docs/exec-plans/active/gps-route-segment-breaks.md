# GPS Route Segment Breaks

## Purpose

Prevent lost-GPS reacquisition jumps from being drawn or counted as real route
distance.

## Context and Orientation

- Recent device data showed long GPS gaps reconnecting as straight route lines.
- `RunPlaybackSampleFusion` can append a recorded point when raw sanitization
  accepts a sample, without validating the recorded route bridge itself.
- Detail maps and metric calculators currently sum adjacent saved points.

## Progress

- [x] Add a route segment verifier shared by live metrics, finish save, and
      detail calculations.
- [x] Store horizontal/speed accuracy on run points.
- [x] Render broken runner routes as separate polylines.
- [x] Add regression tests for long-gap GPS bridges.
- [x] Run guardrails, analyze, and tests.

## Decisions

- Do not rewrite existing DB records.
- Hide/fix existing bad records at read/display calculation time.
- Treat live phone/watch GPS `gap > 30s && distance > 100m` as a route break.
- Treat segment implied speed above `7.0m/s` as a route break.

## Implementation Steps

1. Add `RunRouteSegmenter` in the run tracking service layer.
2. Replace simple adjacent-point distance sums with segment-aware distance.
3. Add map state/renderer support for runner route segments.
4. Add DB migration for point accuracy fields.
5. Cover recorded bad segments and legacy migration in tests.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- Route breaks may under-count distance when GPS was genuinely missing during
  movement. This is intentional for V1 because fake bridge distance is more
  damaging than under-counting unknown movement.
