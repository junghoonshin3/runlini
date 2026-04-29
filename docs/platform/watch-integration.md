# Watch Integration Notes

This document captures the platform decisions Runlini should follow when adding
Apple Watch or Android / Galaxy Watch support.

## Current Baseline

- Runlini is a phone-first Flutter app.
- The local database is the app UI source of truth.
- Health Connect and HealthKit are external backup / recovery sources.
- Past workouts can be imported from the phone health store when the runner
  grants permission.
- Real-time watch capture requires a native watch app. A phone-only Runlini app
  cannot receive live heart rate, route, pause, or workout events directly from a
  watch unless the platform health store or a companion watch app provides them.

## Android And Galaxy Watch

### Import Path

Galaxy Watch workouts do not go directly into Runlini.

The expected import path is:

`Galaxy Watch -> Samsung Health on phone -> Health Connect -> Runlini local DB`

Samsung documents that Galaxy Watch health data is transferred to Samsung
Health on the phone, then synchronized to Health Connect when Samsung Health and
Health Connect are linked and permissions are granted. Health Connect itself is
available on Android mobile devices, not Wear OS devices.

Runlini should therefore treat Galaxy Watch workouts as Health Connect imports:

- Request Health Connect permission only from explicit runner actions in
  Settings > 연동 or the empty-history recovery CTA.
- Import Health Connect records into the local database.
- Preserve local enriched fields such as route detail, ghost metadata, shoes,
  and tombstones when merging.
- Never assume Samsung Health has already synced. The runner may need to open
  Samsung Health, grant Health Connect app permissions, or trigger Samsung
  account sync.

### Real-Time Watch Path

For live watch-supported runs, Runlini needs a Wear OS app.

Recommended architecture:

- Add a Wear OS module / app owned by the Android platform layer.
- Use Health Services on Wear OS for exercise sessions and metrics. Android
  Health Services can provide high-level workout metrics such as heart rate,
  distance, calories, elevation, speed, and pace without Runlini reading raw
  sensors directly.
- Use the Wear OS Data Layer or another explicit companion channel to send live
  session events to the phone app.
- Keep the phone local DB as the canonical saved-run store.
- Export or import through Health Connect after save, not as the real-time
  transport.
- Watch-origin completed workouts are sent to the phone as a Runlini watch draft
  and stored as normal local `RunSession` records with `captureSource = wearOs`.

Current Android native V1 implementation:

- The native module is `android/wear`, package-matched to the phone app with
  `applicationId = kr.sjh.runlini` and namespace `kr.sjh.runlini.wear`.
- The watch records independently with Health Services and keeps a local pending
  draft before attempting transfer.
- The Data Layer path prefix is `/runlini/wear/drafts/`.
- Completed `WatchRunDraft` JSON is sent as a Data Layer asset named
  `draftJson`; small metadata such as `draftId` stays in the `DataMap`.
- The Android phone receives drafts through `WearDraftListenerService`, stores
  them in an app-private pending queue, exposes `runlini/wear_drafts` to
  Flutter, and acknowledges only after Dart import succeeds.
- The watch keeps its pending draft after Data Layer enqueue. The phone sends an
  ack on `/runlini/phone/draft_acks/{draftId}` after Dart import succeeds, and
  only then does the watch delete its local pending copy.
- Settings > 연동 exposes a manual `워치 기록 동기화` action that drains the
  phone pending inbox; the watch ready screen shows pending draft count and
  offers `다시 보내기`.
- The phone also drains the same pending Wear inbox opportunistically on app
  launch, foreground resume, and History pull-to-refresh.
- Phone-selected Ghost Rider records are sent to the watch on
  `/runlini/phone/ghost_config` as a `ghostJson` asset. The watch caches the
  selected ghost route and can start an independent ghost run without a live
  phone connection.
- Wear ghost runs include optional `ghostSummary` metadata in the completed
  `WatchRunDraft`; phone import stores it as the normal `RunSession`
  ghost comparison result.
- Live `WatchRunSnapshot` / `WatchRunEvent` streaming is not part of this slice.

### Android Testing Notes

- A Wear OS emulator can validate pairing, installation, app UI, and basic
  communication.
- A Wear OS emulator is not a full Samsung Health + Galaxy Watch sync test.
- Samsung Health sync behavior must be tested on real Galaxy Watch hardware
  paired with a Samsung Health phone app.
- Phone-only emulator GPS tests remain useful for Runlini route logic, but they
  do not validate watch heart rate or Health Services behavior.

## iOS And Apple Watch

### Communication Boundary

Apple Watch and iPhone apps are not limited to exchanging data through
HealthKit. Apple provides WatchConnectivity for direct communication between a
paired iOS app and watchOS app. Runlini can use it for app-owned payloads such
as live UI snapshots, ghost state, commands, file transfer, and post-run draft
handoff.

HealthKit is still the official boundary for health and fitness records. Workout
samples, route samples, heart rate, distance, calories, and Apple Health /
Fitness visibility should be read from or written to the HealthKit store with
runner permission.

Use this rule of thumb:

- App-owned state between Runlini phone and watch apps: WatchConnectivity.
- Active workout session state and metrics: HealthKit `HKWorkoutSession` /
  `HKLiveWorkoutBuilder`, with workout mirroring when the phone needs to follow
  the watch session.
- Completed workout backup, restore, and Apple Health visibility: HealthKit.

### Import Path

Apple Watch workouts are stored in Apple Health through HealthKit.

The expected import path is:

`Apple Watch Workout app or watchOS app -> HealthKit -> Runlini local DB`

Runlini's iPhone app can import historical workouts from HealthKit after the
runner grants permission. A Runlini watchOS app is not required for basic past
workout import.

Route data is represented by HealthKit workout route samples. Import code should
handle route availability as optional because the runner may deny route
permission, record an indoor workout, or use a source that did not save route
points.

### Real-Time Watch Path

For live Apple Watch-supported runs, Runlini needs a watchOS app.

Recommended architecture:

- Add a watchOS app / extension that starts an `HKWorkoutSession`.
- Use `HKLiveWorkoutBuilder` to collect live workout data.
- Use HealthKit workout mirroring when the phone app needs to follow the active
  workout session started on Apple Watch. The watch starts the primary session;
  the companion iPhone receives a mirrored `HKWorkoutSession`.
- Use WatchConnectivity for Runlini-owned companion messages when the payload is
  not itself a health record, such as live UI updates, ghost comparison, settings
  handoff, or post-run draft transfer.
- Save the workout to HealthKit, then upsert it into the Runlini local database
  on the phone.
- Keep the local DB as the UI source of truth after import / transfer.
- Watch-origin completed workouts are sent to the phone as a Runlini watch draft
  and stored as normal local `RunSession` records with `captureSource = watchOs`.
- Independent watchOS apps must not rely on WatchConnectivity as their only data
  source. If Runlini makes the watch app independent, the watch app must be able
  to start and finish the core run flow on its own, then sync opportunistically.

### iOS Testing Notes

- iPhone simulator tests can cover local persistence, HealthKit import adapters
  only where simulator support is available, and UI behavior.
- Apple Watch workout recording and HealthKit route behavior should be verified
  on a real paired Apple Watch and iPhone.
- WatchConnectivity background delivery should be treated as eventually
  delivered, not instant.

## Watch App V1 Product Shape

- The watch app has only pre-run, running, and finish review screens in v1.
- The watch can start an independent run, pause / resume, stop, and save or
  discard the completed draft.
- The Wear OS app uses a watch-native flow: ready launch hub, swipeable active
  run pages, a dedicated controls page, paused focus screen, and finish review.
- The finish review is a scrollable workout summary so small round screens can
  show richer metrics without clipping save/delete actions. Ghost result is
  shown only for ghost-started runs with a final ghost frame.
- Active run pages are core metrics, optional ghost status, detail metrics, and
  controls. Pause / stop actions live on the controls page to reduce accidental
  taps.
- The watch shows pending sync count and can retry sending completed pending
  drafts.
- Android native V1 does not include phone-started run mirroring, ghost gap, or
  live companion snapshots.
- Ghost Rider on Wear OS starts from a phone-selected cached ghost route. The
  watch does not browse history; it shows `GHOST START` only when a runnable
  cached ghost exists.
- Watch displays elapsed time, distance, pace, heart rate, and active calories
  when Health Services provides them.
- Watch feedback is haptic plus large text. Phone-connected voice cues are
  played by the phone / paired earphones.
- Maps, history browsing, charts, shoe management, and detailed settings are
  phone-only in v1.

## Shared Contracts

- `WatchRunSnapshot` is the live state shown on the watch.
- `WatchRunEvent` represents start, pause, resume, stop, lap, ghost, and audio
  cue events.
- `WatchRunDraft` is the completed workout payload sent from a native watch app
  to the phone.
- Phone-side import maps watch drafts into normal `RunSession` records with
  `recordSource = appLocal` and a platform-specific `captureSource`.
- Android ack messages use `/runlini/phone/draft_acks/{draftId}` and carry only
  small import-confirmation metadata.

## Implementation Rules

- Do not build watch logic into Flutter UI files. Platform adapters belong in
  `core/`, while feature state continues to expose screen-ready state.
- Keep the layering rule: `types -> repo -> service -> state -> ui`.
- The phone app remains responsible for run history, ghost sessions, shoe
  mileage, deletion tombstones, and user-visible sync status.
- Health stores are not the UI source of truth. They are backup, restore, and
  external import sources.
- Watch-origin records must use the same `RunSession` merge policy as Health
  imports.
- If the watch app can record richer metrics than the phone app, add optional
  fields and graceful fallbacks instead of creating a separate "watch run" model.

## Testing Matrix

| Scenario | Android / Galaxy Watch | iOS / Apple Watch |
| --- | --- | --- |
| Past workout import | Health Connect import on phone | HealthKit import on iPhone |
| Real-time watch run | Wear OS app + Health Services + phone companion | watchOS app + HealthKit workout session |
| Route recovery | Health Connect route data when available | `HKWorkoutRoute` when available |
| Heart rate | Health Connect import or Wear OS live metric | HealthKit import or watchOS live metric |
| Emulator coverage | Pairing, app shell, Data Layer basics | Limited; use real watch for workout route confidence |
| Required real-device test | Samsung Health sync from Galaxy Watch | Apple Watch workout + route import |

## Source References

- Samsung Health Connect FAQ:
  <https://developer.samsung.com/health/health-connect-faq.html>
- Health Services on Wear OS:
  <https://developer.android.com/health-and-fitness/health-services>
- Wear OS phone / watch development:
  <https://developer.android.com/training/wearables/get-started/connect-phone>
- Apple HealthKit workouts:
  <https://developer.apple.com/documentation/healthkit/workouts-and-activity-rings>
- Apple `HKWorkout`:
  <https://developer.apple.com/documentation/healthkit/hkworkout>
- Apple `HKWorkoutSession`:
  <https://developer.apple.com/documentation/healthkit/hkworkoutsession>
- Apple multidevice workout sample:
  <https://developer.apple.com/documentation/HealthKit/building-a-multidevice-workout-app>
- Apple `HKWorkoutSession` mirroring:
  <https://developer.apple.com/documentation/healthkit/hkworkoutsession/startmirroringtocompaniondevice%28completion:%29>
- Apple `HKWorkoutRoute`:
  <https://developer.apple.com/documentation/healthkit/hkworkoutroute>
- Apple WatchConnectivity:
  <https://developer.apple.com/documentation/WatchConnectivity>
- Apple WatchConnectivity data transfer:
  <https://developer.apple.com/documentation/WatchConnectivity/transferring-data-with-watch-connectivity>
