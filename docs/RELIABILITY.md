# Reliability

- Primary run capture uses app-side GPS sampling.
- Secondary sync uses health-route imports after the run.
- GPS spikes should be filtered before downstream pace or ghost math.
- Live GPS and accepted route points are separate: the map blue dot may follow
  the latest GPS fix, but distance, pace, calories, route polyline, and ghost
  comparison only use accepted recorded points.
- Stationary drift is filtered from recorded points with horizontal accuracy,
  speed, speed accuracy, minimum movement, max-speed, and acceleration gates.
- When the platform provides motion evidence, stationary-lock recovery also
  requires recent steps or cadence. Phone runs use Android step detector /
  iOS pedometer evidence, and Wear runs use Health Services cadence. If motion
  evidence is unavailable, Runlini falls back to the GPS-only rules above.
- Auto pause is opt-in. When enabled, Runlini pauses elapsed time and recorded
  distance after a stable stationary window, then resumes only after repeated
  movement confirmation. Manual pauses are never auto-resumed.
- Auto pause settings apply to the current run immediately. Turning the setting
  off while Runlini is auto-paused resumes elapsed time from that moment, but
  the GPS drift filter remains active.
- Real-device field testing is required before trusting gap feedback.
