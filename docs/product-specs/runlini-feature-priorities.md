# Runlini Feature Priorities

Runlini should feel like a running app that answers one question instantly:
"Am I ahead or behind my ghost?"

## Near-Term Product Stack

### 1. Core Running Capture

- Live run screen with:
  - elapsed time
  - distance
  - average pace
  - average speed
  - calories placeholder until a real source lands
  - map
  - current location
  - pre-start 3-2-1 countdown before recording begins
  - start, pause, stop, then save/discard review controls in v1
- Post-run summary with:
  - total distance
  - total time
  - average pace
  - average speed
  - splits
  - route-only preview on the platform map SDK with interactive map controls
    disabled
  - touchable line charts for pace over time, speed, elevation when GPS
    altitude is available, and heart rate when watch or health data is
    available
  - optional ghost comparison summary when the run was recorded against a
    selected ghost
  - calories when available
- History list with:
  - date
  - distance
  - total time
  - average pace
  - small route thumbnail
  - tap-through detail view with route, splits, speed, elevation, and heart-rate
    sections in Runlini's compact data-lab style
  - saved-run deletion with a confirmation step
- HealthKit and Health Connect workout export
  - export begins on `START`
  - export finishes only after `저장하기`
  - export capture is canceled when the runner discards the draft
- Architecture that can later accept watch-driven sessions
- Clear fallback handling when GPS or permissions are unavailable

### 2. Runlini Differentiation

- Ghost race against a previous run
- Selected ghost route preview before the run starts
- Gradient-style pace-colored ghost route segments based on the selected run's baseline pace
- Live ahead/behind gap in seconds
- Live ghost distance gap and off-route feedback while running
- Current-time ghost marker on the running map
- Clear pace-state feedback tied to the ghost
- Pace-colored route rendering
- Post-run replay against the ghost session

### 3. High-Value Enhancements

- Heart rate and heart-rate zones when available
- Cadence
- Elevation gain
- Auto laps and split review
- Audio cues for pace, distance, and ghost gap
- Pre-run readiness details such as weather, daylight, and GPS readiness
- Sensor and watch connection status

## Delivery Order

1. Stabilize run capture and route quality
2. Complete the ghost race experience
3. Strengthen post-run analysis
4. Add watch-driven recording flows
5. Add safety and social features
6. Add advanced coaching and training intelligence

## Not in Near-Term Scope

Items intentionally deferred belong in `later-features-backlog.md`.
That includes real-time location sharing.
