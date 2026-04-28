# Reliability

- Primary run capture uses app-side GPS sampling.
- Secondary sync uses health-route imports after the run.
- GPS spikes should be filtered before downstream pace or ghost math.
- Live GPS and accepted route points are separate: the map blue dot may follow
  the latest GPS fix, but distance, pace, calories, route polyline, and ghost
  comparison only use accepted recorded points.
- Stationary drift is filtered from recorded points with horizontal accuracy,
  speed, speed accuracy, minimum movement, max-speed, and acceleration gates.
- Real-device field testing is required before trusting gap feedback.
