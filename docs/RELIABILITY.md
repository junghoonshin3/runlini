# Reliability

- Primary run capture uses app-side GPS sampling.
- Secondary sync uses health-route imports after the run.
- GPS spikes should be filtered before downstream pace or ghost math.
- GPS speed-derived pace ignores stationary noise: speeds at or below `0.7m/s`
  do not create live pace samples, and detail pace charts only render sane
  running paces from `2:00/km` through `30:00/km`.
- Detail pace chart averages use the session average pace from total time and
  distance, not the arithmetic mean of noisy per-point pace samples.
- Live GPS and accepted route points are separate: the map blue dot may follow
  the latest GPS fix, but distance, pace, calories, route polyline, and ghost
  comparison only use accepted recorded points.
- Recorded route points are also split into verified segments before distance,
  charts, and map polylines are calculated. A bridge is rejected when adjacent
  points imply an excessive speed, have invalid time order, or combine a
  `>30s` GPS gap with a `>100m` jump for live phone/watch GPS sources. The
  point after the gap may start a new segment, but Runlini does not draw or
  count the unknown bridge.
- New run points persist horizontal accuracy and speed accuracy so later detail
  screens and export paths can diagnose and filter poor GPS samples. Older
  records keep null accuracy fields and fall back to timestamp/distance rules.
- Stationary drift is filtered from recorded points with horizontal accuracy,
  speed, speed accuracy, minimum movement, max-speed, and acceleration gates.
- When the platform provides motion evidence, stationary-lock recovery also
  requires recent steps or cadence. Phone runs use Android step detector /
  iOS pedometer evidence, and Wear runs use Health Services cadence. If motion
  evidence is unavailable, Runlini falls back to the GPS-only rules above.
- Phone runs use active-running step evidence to save average cadence and
  recent cadence samples. Wear runs use Health Services cadence. Imported
  Health records may only expose average cadence when point-level cadence is
  unavailable.
- Auto pause is opt-in. When enabled, Runlini pauses elapsed time and recorded
  distance after a stable stationary window, then resumes only after repeated
  movement confirmation. Manual pauses are never auto-resumed.
- Auto pause settings apply to the current run immediately. Turning the setting
  off while Runlini is auto-paused resumes elapsed time from that moment, but
  the GPS drift filter remains active.
- Real-device field testing is required before trusting gap feedback.
