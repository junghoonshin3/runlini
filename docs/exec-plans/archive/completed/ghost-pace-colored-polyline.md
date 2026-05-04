# Ghost Pace-Colored Polyline

## Purpose

Color the selected ghost route with fine-grained gradient-style pace segments,
similar to Apple Health route coloring. Render it as a solid multi-color line,
not a dashed line.

## Progress

- [x] Add a colored map segment type for route rendering.
- [x] Build ghost route segments from selected `RunSession` points.
- [x] Resample ghost routes into short distance chunks for smoother gradients.
- [x] Render colored ghost segments on Google, Apple, and fake maps.
- [x] Update pace color tests and docs.
- [x] Validate with guardrails, analysis, and tests.

## Decisions

- Use median valid segment pace as the baseline, with session average pace as a
  fallback when route timing is too sparse or invalid.
- Resample route geometry into 20m chunks and color each chunk from a 60m
  rolling pace window centered on that chunk.
- Map relative pace as a quantized gradient:
  - `<= 85%` of baseline pace: volt green
  - `100%` of baseline pace: amber
  - `>= 115%` of baseline pace: electric red
  - intermediate values are lerped through the gradient and quantized to 32
    color steps to keep native map polyline counts manageable.
- Render ghost route segments as thick solid lines so adjacent segment colors
  blend into one continuous route.
- Merge adjacent same-color quantized segments and use round caps/joints to
  avoid visual gaps at bends.
- Keep the runner polyline unchanged.

## Validation

- `dart run tool/guardrails.dart` passes with existing file-length warnings.
- `flutter analyze` passes.
- `flutter test` passes.
