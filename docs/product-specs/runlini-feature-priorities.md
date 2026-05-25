# Runlini Feature Priorities

Runlini should feel like a running app that answers one question instantly:
"Am I ahead or behind my previous record?"

## Near-Term Product Stack

### 1. Core Running Capture

- Live run screen with:
  - elapsed time
  - distance
  - average pace
  - average speed
  - active calories estimated from user body weight and accepted GPS distance
  - map
  - current location
  - configurable pre-start countdown from 3 to 10 seconds before recording
    begins
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
    available; touch selects a large ring point and tooltip without a guide line
  - optional record-race comparison summary when the run was recorded against a
    selected record race
  - active calories when body weight is set or Health data provides calories
- History list with:
  - local DB records as the single visible source of truth
  - top distance progress ring for this week, this month, and this year
  - configurable weekly, monthly, and yearly distance goals for the progress
    ring
  - weekly-default history calendar that expands into a monthly calendar
  - today's date selected by default, with the list filtered to runs from that
    date instead of a recent-records feed
  - day cells with small circular progress markers based on the monthly goal
    divided by days in the selected month
  - app-local saved runs visible even when health export is unavailable or
    skipped
  - clear backup badges: Health-backed, app-only, or backup failed
  - empty-state recovery CTA for restoring recent Health records after reinstall
    or data clearing
  - Health Connect / HealthKit records synced into local DB after connection
  - date
  - distance
  - total time
  - average pace
  - small route thumbnail
  - tap-through detail view with route, splits, speed, elevation, and heart-rate
    sections in Runlini's compact data-lab style
  - saved-run deletion with a confirmation step
  - Settings tab controls for display units, distance goals, local privacy
    display, running shoes, voice cues, and location tracking quality
  - no bundled local fixture records in the user-visible list
- HealthKit and Health Connect workout export
  - export begins on `START`
  - export finishes only after `저장하기`
  - local save succeeds first; Health backup success, skip, or failure is shown
    as a separate status
  - failed Health backup can be retried from run detail or Settings
  - export capture is canceled when the runner discards the draft
  - imported health workouts are upserted into the same local `RunSession`
    model as app-local runs
  - app startup may run a quiet health sync only when permission is already
    granted
- Architecture that accepts watch-driven sessions through shared watch draft /
  snapshot / event contracts
- Clear fallback handling when GPS or permissions are unavailable

### 2. Runlini Differentiation

- Record race against a previous run
- Pre-start record race selection chip above `START`
- Selected record-race route preview before the run starts
- Gradient-style pace-colored record-race route segments based on the selected run's baseline pace
- Start and finish flags on the selected record-race route, combined when endpoints are within 10m
- Live ahead/behind gap in seconds
- Live record race distance gap and off-route feedback while running
- Optional current-time record-race marker on the running map, off by default
- Clear pace-state feedback tied to the selected record
- Pace-colored route rendering
- Post-run replay against the selected record session

### 3. High-Value Enhancements

- Heart rate and heart-rate zones when available
- Cadence
- Elevation gain
- Auto laps and split review
- Audio cues for pace, distance, and record-race gap
- Pre-run readiness details such as weather, daylight, and GPS readiness
- Sensor and watch connection status
- Wear OS / watchOS apps with pre-run, running, and finish review screens

## Delivery Order

1. Stabilize run capture and route quality
2. Complete the record race experience
3. Strengthen post-run analysis
4. Add watch-driven recording flows
5. Add safety and social features
6. Add advanced coaching and training intelligence

## Not in Near-Term Scope

Items intentionally deferred belong in `later-features-backlog.md`.
That includes real-time location sharing.
