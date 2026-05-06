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
- [x] Make phone auto pause more conservative so silent step sensors do not
      cause false pauses while walking.
- [x] Render detail route previews with segment-aware pace colors instead of a
      single runner color.
- [x] Add a saved-detail Route info popover that summarizes speed by route
      heatmap color bucket with visual color rows.
- [x] Keep the Route speed popover compact and clamp it inside the viewport so
      narrow phones do not crop the speed rows.
- [x] Run guardrails, analyze, and tests.

## Decisions

- Do not rewrite existing DB records.
- Hide/fix existing bad records at read/display calculation time.
- Treat live phone/watch GPS `gap > 30s && distance > 100m` as a route break.
- Treat segment implied speed above `7.0m/s` as a route break.
- Phone auto pause uses a conservative `15s` stationary window; recent
  step/cadence evidence blocks pause, while unavailable motion falls back to
  GPS-only behavior.
- Detail route previews use the existing pace heatmap color mapper on verified
  route fragments, so GPS breaks are still shown as separate polylines.
- Saved-run detail screens show Route color bucket summaries via an info
  popover; finish review keeps the lighter route-only presentation.
- Route speed popovers are custom overlays positioned inside the safe viewport;
  they may flip above the info icon when there is not enough room below.

## Implementation Steps

1. Add `RunRouteSegmenter` in the run tracking service layer.
2. Replace simple adjacent-point distance sums with segment-aware distance.
3. Add map state/renderer support for runner route segments.
4. Add DB migration for point accuracy fields.
5. Apply pace-colored detail route previews on top of verified segments.
6. Add route speed tooltip summaries for saved detail screens.
7. Cover recorded bad segments and legacy migration in tests.

## Validation

- `dart run tool/guardrails.dart`
- `flutter analyze`
- `flutter test`

## Risks or Recovery

- Route breaks may under-count distance when GPS was genuinely missing during
  movement. This is intentional for V1 because fake bridge distance is more
  damaging than under-counting unknown movement.
